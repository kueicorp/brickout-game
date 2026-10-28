## QA 視窗短測(非 headless):D35 HUD 依獲得順序排列、補位、方案 C 換欄。
## 依序在不同幀獲得 炸彈 → 擋板長度 → 強化 → 減速 → 火焰 → 穿透(刻意不是固定順序),截圖逐像素比對;
## 再讓炸彈結束,截圖確認後面往上補位(矮螢幕含跨欄補位)。預期圖 = 背景截圖 + 依規格以 50% 透明疊上格子。
## 執行:Godot --path game --script res://tests/qa_window_hud_order_capture.gd -- <輸出資料夾> <視窗高,預設 800>
## 跑完自動關閉;全部吻合時結束碼 0。
extends SceneTree

const MainScene := preload("res://scenes/main.tscn")
const MainScript := preload("res://scripts/main.gd")
const BALL := Vector2(180, 300)
const TOL := 3.0 / 255.0

var _m
var _frame := 0
var _out := ""
var _h := 800
var _fail := 0
var _pass := 0
var _base: Image


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else OS.get_user_data_dir()
	_h = int(args[1]) if args.size() > 1 else 800
	DisplayServer.window_set_size(Vector2i(360, _h))


func _report(label: String, ok: bool, detail := "") -> void:
	if ok:
		_pass += 1
		print("OK   %-64s %s" % [label, detail])
	else:
		_fail += 1
		print("FAIL %-64s %s" % [label, detail])


func _shot(name: String) -> Image:
	var img := root.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	img.save_png(_out.path_join(name))
	return img


func _icon(id: String) -> Image:
	var i := (load("res://art/hud32/d34_hud_icon_%s.png" % id) as Texture2D).get_image()
	if i.is_compressed():
		i.decompress()
	i.convert(Image.FORMAT_RGBA8)
	return i


func _blend(exp: Image, p: Vector2i, c: Color, a := 1.0) -> void:
	var bg := exp.get_pixelv(p)
	var k := a * 0.5
	exp.set_pixelv(p, Color(bg.r + (c.r - bg.r) * k, bg.g + (c.g - bg.g) * k, bg.b + (c.b - bg.b) * k, 1.0))


func _bar_cols(spec: Dictionary) -> Array:
	var cols := []
	if spec.has("segments"):
		var n: int = spec["segments"]
		var widths := Rules.segment_widths(n)
		var grays := Rules.segment_gray_indices(n)
		for s in n:
			var color: Color = Pal.SEGMENT_GRAYS[grays[s]] if s < spec["filled"] else Pal.BOSS_V
			for i in widths[s]:
				cols.append(color)
			if s < n - 1:
				cols.append(Pal.STEEL_J)
	else:
		for i in Rules.BAR_INNER:
			cols.append(Pal.W if i < spec["fill"] else Pal.BOSS_V)
	return cols


func _exp_cell(exp: Image, o: Vector2i, icon: String, spec: Dictionary) -> void:
	var ic := _icon(icon)
	for y in 32:
		for x in 32:
			var c := ic.get_pixel(x, y)
			if c.a > 0.0:
				_blend(exp, o + Vector2i(6 + x, y), c, c.a)
	var b := o + Vector2i(0, 36)
	for x in 44:
		for y in [0, 1, 6, 7]:
			_blend(exp, b + Vector2i(x, y), Pal.STEEL_J)
	for y in range(2, 6):
		for x in [0, 1, 42, 43]:
			_blend(exp, b + Vector2i(x, y), Pal.STEEL_J)
	var cols := _bar_cols(spec)
	for i in cols.size():
		for y in range(2, 6):
			for dx in 2:
				_blend(exp, b + Vector2i(2 + 2 * i + dx, y), cols[i])


func _cmp(shot: Image, exp: Image, skip: Array) -> Array:
	var bad := 0
	var first := ""
	for y in shot.get_height():
		for x in shot.get_width():
			var p := Vector2i(x, y)
			var skipped := false
			for r in skip:
				if (r as Rect2i).has_point(p):
					skipped = true
					break
			if skipped:
				continue
			var g := shot.get_pixelv(p)
			var w := exp.get_pixelv(p)
			if absf(g.r - w.r) > TOL or absf(g.g - w.g) > TOL or absf(g.b - w.b) > TOL:
				bad += 1
				if first == "":
					first = "%s want %s got %s" % [p, w.to_html(false), g.to_html(false)]
	return [bad, first]


## 規格公式(D35 方案 C),獨立於實作
func _slot(i: int) -> Vector2i:
	@warning_ignore("integer_division")
	var per_col: int = (_m.view_h - 473) / 52
	@warning_ignore("integer_division")
	return Vector2i(24 + 52 * (i / per_col), 424 + 52 * (i % per_col))


func _skip() -> Array:
	var py: int = _m._paddle_y()
	return [Rect2i(0, py - 8, 360, 24), Rect2i(Vector2i(BALL) - Vector2i(14, 14), Vector2i(28, 28))]


const CELL := {
	"bomb": ["bomb", {"fill": 20}],
	"paddle_len": ["paddle_len_up1", {"fill": 20}],
	"reinforce": ["reinforce", {"segments": 7, "filled": 1}],
	"speed": ["slow", {"segments": 3, "filled": 1}],
	"flame": ["flame", {"fill": 20}],
	"pierce": ["pierce", {"fill": 20}],
}


func _check(name: String, order: Array, label: String) -> void:
	var shot := _shot(name)
	var exp := _base.duplicate() as Image
	for k in order.size():
		_exp_cell(exp, _slot(k), CELL[order[k]][0], CELL[order[k]][1])
	var r := _cmp(shot, exp, _skip())
	_report(label, r[0] == 0, "%d px differ %s" % r)


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 4:
		_m = MainScene.instantiate()
		root.add_child(_m)
	if _frame == 6:
		print("INFO window %s viewport %s view_h %d" % [DisplayServer.window_get_size(), root.get_visible_rect().size, _m.view_h])
		for r in _m.grid.size():
			for c in _m.grid[r].size():
				_m.grid[r][c] = null
		_m.breakable_left = 99
		_m.items.clear()
		_m.anims.clear()
		_m.bullets.clear()
		_m.balls.clear()
		var b = MainScript.Ball.new()
		b.pos = BALL
		_m.balls.append(b)
		_m.state = 1           # 凍結遊戲推進(計時不走),只為截圖
		_m.reduced_motion = true
		_m.effects = Effects.new()
	if _frame == 10:
		_report("view_h equals requested window height %d" % _h, _m.view_h == _h, str(_m.view_h))
		_base = _shot("qa_hud_order_h%d_base.png" % _h)
	# 依序、不同幀獲得
	var seq := {12: "bomb", 14: "paddle_len_1", 16: "reinforce", 18: "slow", 20: "flame", 22: "pierce"}
	if seq.has(_frame):
		_m._apply_item(seq[_frame])
	if _frame == 28:
		_check("qa_hud_order_h%d_a_order.png" % _h, ["bomb", "paddle_len", "reinforce", "speed", "flame", "pierce"],
			"H %d: acquisition order bomb, len, reinforce, slow, flame, pierce" % _h)
		# 炸彈結束(state 凍結,直接移除計時,模擬到期)
		_m.effects.timed.erase("bomb")
	if _frame == 34:
		_check("qa_hud_order_h%d_b_filled.png" % _h, ["paddle_len", "reinforce", "speed", "flame", "pierce"],
			"H %d: bomb ended -> rest move up (cross-column when per column < 6)" % _h)
		# 再撿炸彈 → 排最後
		_m._apply_item("bomb")
	if _frame == 40:
		_check("qa_hud_order_h%d_c_bomb_again.png" % _h, ["paddle_len", "reinforce", "speed", "flame", "pierce", "bomb"],
			"H %d: bomb again -> last" % _h)
		print("QA HUD ORDER CAPTURE RESULT: %d passed, %d failed" % [_pass, _fail])
		quit(1 if _fail > 0 else 0)
		return true
	return false
