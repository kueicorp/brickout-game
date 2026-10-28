## QA 視窗短測(非 headless):D34 HUD 圖示(art/hud32,32×32 1 倍)與擋板長度格(D35 起併入同一排,原 D33 第 2 欄取消)。
## 對每張截圖建「預期圖」= 背景截圖 + 依規格以 50% 透明疊上格子(圖示在格內 (6, 0)、線段條 44×8 在格內 y 36),
## 整個畫面逐像素比對(擋板那幾列除外,長度會變)。另檢查:只有長度格時無光暈、最後 1 秒閃爍、減少動態不閃。
## 執行:Godot --path game --script res://tests/qa_window_hud34_capture.gd -- <輸出資料夾>
## 跑完自動關閉;全部吻合時結束碼 0。
extends SceneTree

const MainScene := preload("res://scenes/main.tscn")
const MainScript := preload("res://scripts/main.gd")
const BALL := Vector2(180, 300)
const TOL := 3.0 / 255.0

var _m
var _frame := 0
var _out := ""
var _fail := 0
var _pass := 0
var _base: Image


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else OS.get_user_data_dir()
	_m = MainScene.instantiate()
	root.add_child(_m)


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
	var tex := load("res://art/hud32/d34_hud_icon_%s.png" % id) as Texture2D
	var i := tex.get_image()
	if i.is_compressed():
		i.decompress()
	i.convert(Image.FORMAT_RGBA8)
	return i


## 在 exp 上以 alpha a × 50% 疊一個像素
func _blend(exp: Image, p: Vector2i, c: Color, a := 1.0) -> void:
	var bg := exp.get_pixelv(p)
	var k := a * 0.5
	exp.set_pixelv(p, Color(bg.r + (c.r - bg.r) * k, bg.g + (c.g - bg.g) * k, bg.b + (c.b - bg.b) * k, 1.0))


## 線段條各內部欄的顏色(規格:時間條 = 填色欄數 W/G、其餘 v;分段條 = 各段灰階、段間 j、未填 v)
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
			cols.append(spec.get("color", Pal.W) if i < spec["fill"] else Pal.BOSS_V)
	return cols


## 在預期圖畫一格:o = 格左上角
func _exp_cell(exp: Image, o: Vector2i, icon: String, spec: Dictionary) -> void:
	var ic := _icon(icon)
	for y in 32:
		for x in 32:
			var c := ic.get_pixel(x, y)
			if c.a > 0.0:
				_blend(exp, o + Vector2i(6 + x, y), c, c.a)
	var b := o + Vector2i(0, 36)
	for x in 44:
		_blend(exp, b + Vector2i(x, 0), Pal.STEEL_J)
		_blend(exp, b + Vector2i(x, 1), Pal.STEEL_J)
		_blend(exp, b + Vector2i(x, 6), Pal.STEEL_J)
		_blend(exp, b + Vector2i(x, 7), Pal.STEEL_J)
	for y in range(2, 6):
		for x in [0, 1, 42, 43]:
			_blend(exp, b + Vector2i(x, y), Pal.STEEL_J)
	var cols := _bar_cols(spec)
	for i in cols.size():
		for y in range(2, 6):
			for dx in 2:
				_blend(exp, b + Vector2i(2 + 2 * i + dx, y), cols[i])


## 全畫面比對;skip 內的像素不比。回傳 [差異數, 第一個差異]
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


func _paddle_band() -> Rect2i:
	var py: int = _m._paddle_y()
	return Rect2i(0, py - 8, 360, 24)


func _halo_rect() -> Rect2i:
	return Rect2i(Vector2i(BALL) - Vector2i(14, 14), Vector2i(28, 28))


## 光暈區(球本體 16×16 以外)是否和背景不同
func _halo_drawn(shot: Image) -> bool:
	var r := _halo_rect()
	var body := Rect2i(Vector2i(BALL) - Vector2i(8, 8), Vector2i(16, 16))
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var p := Vector2i(x, y)
			if body.has_point(p):
				continue
			if not shot.get_pixelv(p).is_equal_approx(_base.get_pixelv(p)):
				return true
	return false


## D35 方案 C:第 i 格(0 起);每欄格數 = floor((H − 473) ÷ 52)。原 D33 第 2 欄已取消
func _slot(i: int) -> Vector2i:
	@warning_ignore("integer_division")
	var per_col: int = (_m.view_h - 473) / 52
	@warning_ignore("integer_division")
	return Vector2i(24 + 52 * (i / per_col), 424 + 52 * (i % per_col))


func _reset_effects() -> void:
	_m.effects = Effects.new()


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 3:
		print("INFO viewport %s view_h %d" % [root.get_visible_rect().size, _m.view_h])
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
		_reset_effects()
	if _frame == 8:
		_base = _shot("qa_hud34_base.png")
		_report("view_h 800 -> slot 0 (24, 424), slot 6 (76, 424)", _slot(0) == Vector2i(24, 424) and _slot(6) == Vector2i(76, 424), "%s %s" % [_slot(0), _slot(6)])
		# A:只有擋板長度(小增 102)
		_m.effects.add_paddle_len("paddle_len_1", _m.cfg)
	if _frame == 14:
		var shot := _shot("qa_hud34_a_len_only.png")
		var exp := _base.duplicate() as Image
		_exp_cell(exp, _slot(0), "paddle_len_up1", {"fill": 20})
		var r := _cmp(shot, exp, [_paddle_band()])
		_report("A: only '+' cell, in slot 0 (24, 424) (D35), full bar, 50% alpha", r[0] == 0, "%d px differ %s" % r)
		_report("A: no ball halo when the only cell is length", not _halo_drawn(shot))
		# B:長度先獲得(slot 0,剩 15 秒 → 10 欄),之後同一幀 5 種 → 依 R10 固定順序接在後面
		_m.effects.timed[Effects.PADDLE_LEN]["remaining"] = 15.0
		_m.effects.reinforce = 2
		_m.effects.ball_tier = -1
		_m._apply_item("pierce")
		_m.effects.timed["pierce"]["remaining"] = 5.0     # 5 / 20 → 5 欄
		_m._apply_item("flame")
		_m._apply_item("bomb")
	if _frame == 20:
		var shot := _shot("qa_hud34_b_both_columns.png")
		var exp := _base.duplicate() as Image
		var cells := [["reinforce", {"segments": 7, "filled": 2}], ["slow", {"segments": 3, "filled": 1}],
			["pierce", {"fill": 5}], ["flame", {"fill": 20}], ["bomb", {"fill": 20}]]
		_exp_cell(exp, _slot(0), "paddle_len_up1", {"fill": 10})
		for k in cells.size():
			_exp_cell(exp, _slot(k + 1), cells[k][0], cells[k][1])
		var r := _cmp(shot, exp, [_paddle_band(), _halo_rect()])
		_report("B: length (bar 10/20) slot 0, then reinforce/slow/pierce/flame/bomb slots 1..5", r[0] == 0, "%d px differ %s" % r)
		_report("B: ball halo shown when list has non-length cells", _halo_drawn(shot))
		# C:只留長度;最短化後再撿 3 個大增(> 85 仍顯示 −);剩 0.95 秒、動態開 → 閃爍 G
		_reset_effects()
		_m.effects.add_paddle_len("paddle_len_min", _m.cfg)
		for i in 3:
			_m.effects.add_paddle_len("paddle_len_2", _m.cfg)
		_m.effects.timed[Effects.PADDLE_LEN]["remaining"] = 0.95
		_m.reduced_motion = false
	if _frame == 26:
		var shot := _shot("qa_hud34_c_min_blink.png")
		_report("C: length > 85 after min (%d)" % _m._paddle_len(), _m._paddle_len() > 85)
		var exp := _base.duplicate() as Image
		_exp_cell(exp, _slot(0), "paddle_len_down1", {"fill": 1, "color": Pal.G})
		var r := _cmp(shot, exp, [_paddle_band(), _halo_rect()])
		_report("C: '-' icon after min, last-second bar 1 col blinking G, others gone", r[0] == 0, "%d px differ %s" % r)
		_report("C: still no halo with motion on (only length cell)", not _halo_drawn(shot))
		_m.reduced_motion = true
	if _frame == 32:
		var shot := _shot("qa_hud34_d_reduced.png")
		var exp := _base.duplicate() as Image
		_exp_cell(exp, _slot(0), "paddle_len_down1", {"fill": 1, "color": Pal.W})
		var r := _cmp(shot, exp, [_paddle_band()])
		_report("D: reduced motion -> last-second bar stays W", r[0] == 0, "%d px differ %s" % r)
		# E:長度剛好 85(小增 1.25 × 小減 0.8)→ 不顯示,但計時在
		_reset_effects()
		var old: float = _m.cfg.len_small_up
		_m.cfg.len_small_up = 1.25
		_m.effects.add_paddle_len("paddle_len_1", _m.cfg)
		_m.effects.add_paddle_len("paddle_len_down_1", _m.cfg)
		_m.cfg.len_small_up = old
	if _frame == 38:
		var shot := _shot("qa_hud34_e_len85.png")
		var r := _cmp(shot, _base, [])
		_report("E: length exactly 85 with timer running -> nothing drawn (paddle 85 too)", r[0] == 0 and _m.effects.is_active(Effects.PADDLE_LEN), "%d px differ %s" % r)
		# F:到期那一幀:剩 0.01 秒,走與 _step 相同的計時路徑 tick(0.01) → 長度與格子同時消失
		_reset_effects()
		_m.effects.add_paddle_len("paddle_len_down_2", _m.cfg)
		_m.effects.timed[Effects.PADDLE_LEN]["remaining"] = 0.01
		for id in _m.effects.tick(0.01):
			_m._on_expired(id)
	if _frame == 44:
		var shot := _shot("qa_hud34_f_expired.png")
		var r := _cmp(shot, _base, [_halo_rect(), Rect2i(0, 0, 360, 32)])
		_report("F: expiry frame -> cell gone, paddle back to 85", r[0] == 0 and _m._paddle_len() == 85, "%d px differ %s" % r)
		print("QA HUD34 CAPTURE RESULT: %d passed, %d failed" % [_pass, _fail])
		quit(1 if _fail > 0 else 0)
		return true
	return false
