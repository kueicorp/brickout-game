## QA 獨立驗證:D29 修訂(40×40 圖示、48×48 閃光,1 倍)— headless 部分。
## - H = 800、640 金球/黑球所有座標(標題圖示、標題/副標、選項、選項圖示、選項文字、閃光)
## - 標題圖示 = golden_ball / black_ball;選項圖示對應抽到的道具(含 main._open_menu 實際抽選)
## - 閃光 3 幀各 60 ms;減少動態不播閃光
## - 每種道具名稱與說明在 216 寬內(實際字型量測);標題/副標在 232 內
## - 互動:真實輸入事件(滑鼠 push_input、觸控 Input.parse_input_event)— 放開才選、500 ms 鎖定、420 / 240 ms 關閉
## 執行:Godot --headless --path game --script res://tests/qa_menu_items40_test.gd
## 全部通過時結束碼 0。
extends SceneTree

const MainScene := preload("res://scenes/main.tscn")

var _passed := 0
var _failed := 0
var _section := ""
var _frame := 0
# 觸控(非同步)階段
var _tm: ChoiceMenu
var _tpicks := []


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_run("coords", _t_coords)
		_run("title_icon", _t_title_icon)
		_run("option_icons", _t_option_icons)
		_run("option_icons_main_draw", _t_option_icons_main)
		_run("pickup_timing", _t_pickup_timing)
		_run("text_width", _t_text_width)
		_run("input_lock_release", _t_input_lock_release)
		_run("close_timing", _t_close_timing)
		_section = "touch"
		_touch_setup()
	elif _frame == 3:
		_touch(_center(_tm, 0), true)
	elif _frame == 5:
		_eq(_tpicks.size(), 0, "touch press alone does not pick")
		_touch(_center(_tm, 0), false)
	elif _frame == 7:
		_eq(_tpicks, [_tm.ids[0]], "touch release on option 0 picks it (real ScreenTouch via Input)")
	elif _frame == 8:
		if is_instance_valid(_tm):
			_tm.free()
		print("QA MENU ITEMS40 RESULT: %d passed, %d failed" % [_passed, _failed])
		quit(1 if _failed > 0 else 0)
		return true
	return false


func _run(name: String, f: Callable) -> void:
	_section = name
	f.call()


func _eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual == expected:
		_passed += 1
	else:
		_failed += 1
		print("FAIL [%s] %s: expected %s, got %s" % [_section, label, expected, actual])


func _ok(cond: bool, label: String) -> void:
	_eq(cond, true, label)


func _menu(golden: bool, ids: Array, h: int, reduced: bool) -> ChoiceMenu:
	var m := ChoiceMenu.new()
	m.setup(golden, ids, h, reduced)
	root.add_child(m)
	m._apply_entry(1.0)
	return m


func _title_icon(m: ChoiceMenu) -> TextureRect:
	for c in m._panel.get_children():
		if c is TextureRect:
			return c
	return null


func _labels(m: ChoiceMenu) -> Array:
	var out := []
	for c in m._panel.get_children():
		if c is Label:
			out.append(c)
	return out


func _center(m: ChoiceMenu, k: int) -> Vector2:
	return m._options[k].get_global_rect().get_center()


# ---------- 座標 ----------

func _t_coords() -> void:
	for h in [800, 640]:
		for golden in [true, false]:
			var ids := ["slow", "gun", "flame"] if golden else ["fast", "heal_area", "thief"]
			var m := _menu(golden, ids, h, false)
			var py := 52 + floori((h - 52 - 432) / 2.0)
			var dy := py - 210   # 相對 H = 800 的位移
			var tag := "H%d %s" % [h, "gold" if golden else "black"]
			_eq(m._panel.global_position, Vector2(28, py), "%s panel pos" % tag)
			var ti := _title_icon(m)
			_eq(ti.get_global_rect(), Rect2(40, 225 + dy, 40, 40), "%s title icon 40x40 at (40, %d)" % [tag, 225 + dy])
			_eq([ti.stretch_mode, ti.expand_mode], [TextureRect.STRETCH_SCALE, TextureRect.EXPAND_IGNORE_SIZE], "%s title icon stretch/expand" % tag)
			var labels := _labels(m)
			_eq(labels.size(), 2, "%s 2 labels" % tag)
			for i in labels.size():
				var l: Label = labels[i]
				_eq(l.global_position, Vector2(88, 222 + 24 * i + dy), "%s label %d pos" % [tag, i])
				_eq(l.size.x, 232.0, "%s label %d width 232 (right end 319)" % [tag, i])
				_ok(l.get_minimum_size().x <= 232.0, "%s label %d text fits 232 (min %.1f) '%s'" % [tag, i, l.get_minimum_size().x, l.text])
			for k in 3:
				var o: ChoiceOption = m._options[k]
				var g := o.get_global_rect()
				var top := 278 + 120 * k + dy
				_eq(g, Rect2(40, top, 280, 112), "%s option %d rect 280x112" % [tag, k])
				var icon := Rect2(g.position + ChoiceOption.ICON_RECT.position, ChoiceOption.ICON_RECT.size)
				_eq(icon, Rect2(48, 314 + 120 * k + dy, 40, 40), "%s option %d icon 40x40" % [tag, k])
				_eq(g.position.x + ChoiceOption.TEXT_X, 96.0, "%s option %d text x 96" % [tag, k])
				_eq(g.position.x + ChoiceOption.TEXT_X + ChoiceOption.TEXT_W - 1, 311.0, "%s option %d text right end 311 (w 216)" % [tag, k])
				var fl := Rect2(g.position + ChoiceOption.PICKUP_RECT.position, ChoiceOption.PICKUP_RECT.size)
				_eq(fl, Rect2(44, 310 + 120 * k + dy, 48, 48), "%s option %d flash 48x48" % [tag, k])
				_eq(fl.get_center(), Vector2(68, top + 56), "%s option %d flash center (68, top+56)" % [tag, k])
				_eq(fl.get_center(), icon.get_center(), "%s option %d flash center == icon center" % [tag, k])
				_ok(fl.end.x <= 96.0, "%s option %d flash does not reach text column" % [tag, k])
				_ok(g.encloses(fl), "%s option %d flash inside option" % [tag, k])
			m.free()


# ---------- 圖示 ----------

func _t_title_icon() -> void:
	for golden in [true, false]:
		var m := _menu(golden, ["slow", "split", "gun"] if golden else ["fast", "merge", "heal"], 800, false)
		var ti := _title_icon(m)
		var want := "res://art/items40/d32_item_%s_f1.png" % ("golden_ball" if golden else "black_ball")
		_eq(ti.texture.resource_path, want, "title icon golden=%s" % golden)
		_eq(Vector2i(ti.texture.get_size()), Vector2i(40, 40), "title tex 40x40 golden=%s" % golden)
		m.free()


func _t_option_icons() -> void:
	for golden in [true, false]:
		var pool := ItemDefs.choice_pool(golden, true)
		var i := 0
		while i < pool.size():
			var ids := []
			for k in 3:
				ids.append(pool[(i + k) % pool.size()])
			var m := _menu(golden, ids, 800, false)
			for k in 3:
				var o: ChoiceOption = m._options[k]
				_eq(o.item_id, ids[k], "option %d id" % k)
				_eq([o._icons[0].resource_path, o._icons[1].resource_path],
					["res://art/items40/d32_item_%s_f1.png" % ids[k], "res://art/items40/d32_item_%s_f2.png" % ids[k]],
					"option %d icons for %s" % [k, ids[k]])
				_eq(Vector2i(o._icons[0].get_size()), Vector2i(40, 40), "icon size %s" % ids[k])
			m.free()
			i += 3


## 走 main._open_menu 的實際抽選:選項圖示 = 抽到的 id
func _t_option_icons_main() -> void:
	# 固定測試關卡(無魔王):不依賴 game_config.tres 目前的 level_path(魔王關進場有 1.6 秒 BOSS 警告)
	var cfg := load("res://data/game_config.tres") as GameConfig
	cfg.level_path = "res://data/levels/level_func_test.json"
	for seed in [1, 2, 3, 4, 5]:
		for golden in [true, false]:
			var mm = MainScene.instantiate()
			root.add_child(mm)
			mm.rng.seed = seed
			mm._open_menu(golden)
			var menu: ChoiceMenu = mm.menu
			_eq(menu.ids.size(), 3, "3 ids seed %d" % seed)
			for k in 3:
				var o: ChoiceOption = menu._options[k]
				_eq(o.item_id, menu.ids[k], "seed %d golden %s option %d id" % [seed, golden, k])
				_ok(o._icons[0].resource_path.ends_with("d32_item_%s_f1.png" % menu.ids[k]), "seed %d option %d icon matches %s" % [seed, k, menu.ids[k]])
				_eq(ItemDefs.is_buff(menu.ids[k]), golden, "seed %d option %d pool type" % [seed, k])
			mm.free()


# ---------- 閃光時間 ----------

func _t_pickup_timing() -> void:
	var m := _menu(true, ["slow", "split", "gun"], 800, false)
	m._t = 0.6
	m._process(0.0)
	m._on_pressed(1)
	var sel: ChoiceOption = m._options[1]
	# 各點:pt → 預期 [pickup_frame, flash, border_white]
	var pts := [[0.0, 0, true, false], [0.03, 0, true, false], [0.059, 0, true, false], [0.061, 1, false, true],
		[0.09, 1, false, true], [0.119, 1, false, true], [0.121, 2, false, true], [0.15, 2, false, true],
		[0.179, 2, false, true], [0.181, -1, false, true], [0.3, -1, false, true]]
	for p in pts:
		m._apply_pick(p[0])
		_eq([sel.pickup_frame, sel.flash, sel.border_white], [p[1], p[2], p[3]], "pt %.3f frame/flash/border" % p[0])
	# 實際以 _process 推進(約 60 fps)
	var m2 := _menu(false, ["fast", "merge", "heal"], 640, false)
	m2._t = 0.6
	m2._process(0.0)
	m2._on_pressed(2)
	var seq := []
	for i in 12:
		m2._process(1.0 / 60.0)
		seq.append(m2._options[2].pickup_frame)
	print("INFO pickup_frame per 60fps step: %s" % [seq])
	# pt = 1/60 … 12/60:0~0.06 → F1、0.06~0.12 → F2、0.12~0.18 → F3、之後不畫
	_eq(seq, [0, 0, 0, 1, 1, 1, 1, 2, 2, 2, -1, -1], "60 fps sequence F1 x3, F2 x4, F3 x3, then off")
	m.free()
	m2.free()
	# 減少動態:不播閃光、不閃白,直接白框
	var r := _menu(true, ["slow", "split", "gun"], 800, true)
	r._t = 0.6
	r._process(0.0)
	r._on_pressed(0)
	var rs: ChoiceOption = r._options[0]
	var any := false
	for i in 14:
		r._process(1.0 / 60.0)
		if not is_instance_valid(rs) or r.is_queued_for_deletion():
			break
		if rs.pickup_frame != -1 or rs.flash:
			any = true
	_ok(not any, "reduced motion: no pickup flash, no white flash")
	if is_instance_valid(r):
		_ok(rs.border_white, "reduced motion: 2 px white border")
		r.free()


# ---------- 文字寬 ----------

func _t_text_width() -> void:
	var m := _menu(true, ["slow", "split", "gun"], 800, false)
	var font: Font = m._options[0].get_theme_default_font()
	print("INFO option font: %s (fallbacks %d)" % [font.resource_path if font.resource_path != "" else font.get_class(), font.fallbacks.size()])
	var worst := ""
	var worst_w := 0.0
	for id in ItemDefs.BUFF + ItemDefs.DEBUFF:
		var lines: Array = [ItemDefs.item_name(id)] + ItemDefs.desc_lines(id)
		for l in lines:
			var w := font.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, ChoiceOption.FONT_SIZE).x
			_ok(w <= ChoiceOption.TEXT_W, "%s '%s' width %.1f <= 216" % [id, l, w])
			if w > worst_w:
				worst_w = w
				worst = "%s '%s'" % [id, l]
	print("INFO widest option line: %s = %.1f px (limit 216)" % [worst, worst_w])
	m.free()


# ---------- 互動(真實事件) ----------

func _mouse(pos: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = pos
	e.global_position = pos
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	root.push_input(e)


func _motion(pos: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = pos
	e.global_position = pos
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(e)


func _t_input_lock_release() -> void:
	for h in [800, 640]:
		var m := ChoiceMenu.new()
		m.setup(true, ["slow", "split", "gun"], h, false)
		root.add_child(m)
		var picks := []
		m.picked.connect(func(id: String) -> void: picks.append(id))
		var c0 := _center(m, 0)
		m._process(0.499)
		_mouse(c0, true)
		_mouse(c0, false)
		_eq(picks.size(), 0, "H%d tap at 499 ms ignored" % h)
		m._process(0.002)
		_ok(not m._options[0].disabled, "H%d unlocked at 501 ms" % h)
		var c2 := _center(m, 2)
		_mouse(c2, true)
		_eq(picks.size(), 0, "H%d press alone does not pick" % h)
		_motion(_center(m, 1))
		_mouse(_center(m, 1), false)
		_eq(picks.size(), 0, "H%d press on 2, release on 1 -> no pick" % h)
		_mouse(c2, true)
		_mouse(c2, false)
		_eq(picks, ["gun"], "H%d release on option 2 picks gun" % h)
		_mouse(c0, true)
		_mouse(c0, false)
		_eq(picks.size(), 1, "H%d input after pick ignored" % h)
		m.free()


func _t_close_timing() -> void:
	for reduced in [false, true]:
		var close_t := 0.24 if reduced else 0.42
		var m := ChoiceMenu.new()
		m.setup(false, ["fast", "merge", "heal"], 800, reduced)
		root.add_child(m)
		var closed := [false]
		m.closed.connect(func() -> void: closed[0] = true)
		m._process(0.51)
		_mouse(_center(m, 1), true)
		_mouse(_center(m, 1), false)
		_eq(m._picked, 1, "reduced=%s picked via real mouse" % reduced)
		m._process(close_t - 0.005)
		_ok(not closed[0], "reduced=%s still open at %.3f s" % [reduced, close_t - 0.005])
		m._process(0.01)
		_ok(closed[0], "reduced=%s closed at %.3f s" % [reduced, close_t + 0.005])
		if is_instance_valid(m):
			m.free()


## 觸控:Input.parse_input_event(ScreenTouch)→ 引擎依設定轉成滑鼠事件(下一幀處理)
func _touch_setup() -> void:
	print("INFO emulate_mouse_from_touch=%s" % ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch"))
	_tm = ChoiceMenu.new()
	_tm.setup(true, ["slow", "split", "gun"], 800, true)
	root.add_child(_tm)
	_tm._t = 1.0
	_tm.picked.connect(func(id: String) -> void: _tpicks.append(id))


func _touch(pos: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = 0
	e.pressed = pressed
	e.position = pos
	Input.parse_input_event(e)
