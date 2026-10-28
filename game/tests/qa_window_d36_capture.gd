## QA 視窗短測(非 headless):D36 14 格全部同時生效。
## A:14 種同一幀出現(+ 版:加速、擋板長度 +、擋板速度 +);B:換成 − 版(減速、擋板長度 −、擋板速度 −)。
## 截圖逐像素比對;預期圖 = 背景截圖 + 依規格(D35 公式、R10 固定順序、D34/D36 圖檔)以 50% 透明疊上格子。
## 執行:Godot --path game --script res://tests/qa_window_d36_capture.gd -- <輸出資料夾> <視窗高,預設 800>
## 跑完自動關閉;全部吻合時結束碼 0。
extends SceneTree

const MainScene := preload("res://scenes/main.tscn")
const MainScript := preload("res://scripts/main.gd")
const BALL := Vector2(300, 300)
const TOL := 3.0 / 255.0

## R10 固定順序(D36 第六節,fever 不存在)
const ORDER := ["reinforce", "speed", "pierce", "flame", "bomb", "paddle_len", "paddle_speed", "sticky", "gun",
	"heal", "heal_area", "blackhole", "invincible", "invisible"]
const ITEMS_PLUS := ["invisible", "invincible", "blackhole", "heal_area", "heal", "gun", "sticky", "paddle_speed",
	"paddle_len_1", "bomb", "flame", "pierce", "fast", "reinforce"]
const ITEMS_MINUS := ["invisible", "invincible", "blackhole", "heal_area", "heal", "gun", "sticky", "paddle_speed_down",
	"paddle_len_down_1", "bomb", "flame", "pierce", "slow", "reinforce"]
const FULL := {"fill": 20}
const CELL_PLUS := {
	"reinforce": ["reinforce", {"segments": 7, "filled": 1}],
	"speed": ["fast", {"segments": 4, "filled": 1}],
	"pierce": ["pierce", FULL], "flame": ["flame", FULL], "bomb": ["bomb", FULL],
	"paddle_len": ["paddle_len_up1", FULL],
	"paddle_speed": ["paddle_speed_up", {"segments": 4, "filled": 1}],
	"sticky": ["sticky", FULL], "gun": ["gun", FULL], "heal": ["heal", FULL], "heal_area": ["heal_area", FULL],
	"blackhole": ["blackhole", FULL], "invincible": ["invincible", FULL], "invisible": ["invisible", FULL],
}

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
	var per_col: int = (_h - 473) / 52
	@warning_ignore("integer_division")
	return Vector2i(24 + 52 * (i / per_col), 424 + 52 * (i % per_col))


func _skip() -> Array:
	var py: int = _m._paddle_y()
	return [Rect2i(0, py - 10, 360, 26), Rect2i(Vector2i(BALL) - Vector2i(16, 16), Vector2i(32, 32))]


func _check(name: String, cells: Dictionary, label: String) -> void:
	var shot := _shot(name)
	var exp := _base.duplicate() as Image
	for k in ORDER.size():
		_exp_cell(exp, _slot(k), cells[ORDER[k]][0], cells[ORDER[k]][1])
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
		_base = _shot("qa_d36_h%d_base.png" % _h)
	if _frame == 12:
		for id in ITEMS_PLUS:
			_m._apply_item(id)
	if _frame == 18:
		_report("H %d: 14 kinds in fixed order" % _h, _m.hud_order == ORDER, str(_m.hud_order))
		_check("qa_d36_h%d_a_all14_plus.png" % _h, CELL_PLUS, "H %d: 14 cells (+ variants) pixel match" % _h)
		# 換成 − 版(同一幀全換,清單種類不變 → 位置不變)
		_m.effects = Effects.new()
		for id in ITEMS_MINUS:
			_m._apply_item(id)
	if _frame == 24:
		var cells := CELL_PLUS.duplicate()
		cells["speed"] = ["slow", {"segments": 3, "filled": 1}]
		cells["paddle_len"] = ["paddle_len_down1", FULL]
		cells["paddle_speed"] = ["paddle_speed_down", {"segments": 3, "filled": 1}]
		_report("H %d: order unchanged after +/- swap" % _h, _m.hud_order == ORDER, str(_m.hud_order))
		_check("qa_d36_h%d_b_all14_minus.png" % _h, cells, "H %d: 14 cells (- variants) pixel match" % _h)
		print("QA D36 CAPTURE RESULT: %d passed, %d failed" % [_pass, _fail])
		quit(1 if _fail > 0 else 0)
		return true
	return false
