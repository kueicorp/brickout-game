extends SceneTree
## 直向延伸版面的互動測試(QA 新增):用子類別覆寫 _view_size / _safe_margins 模擬不同畫面高與安全區,
## 再用 push_input 點擊、滑動,確認觸控範圍跟著畫面位移。執行:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path game --script res://tests/test_home_tall.gd
## 有任何失敗時結束碼為 1。

## 模擬用的首頁在 home_sim.gd(說明見該檔)
const HOME_SIM_PATH := "res://tests/home_sim.gd"

## 640 高、T=24、B=16 時的格子中心(畫面座標,設計稿 D15 第 2 點)
const C := [
	Vector2(91, 199), Vector2(180, 199), Vector2(269, 199),
	Vector2(314, 266), Vector2(224, 266), Vector2(136, 266), Vector2(46, 266),
	Vector2(91, 332), Vector2(180, 332), Vector2(269, 332),
]

var _passed := 0
var _failed := 0
var home
var map
var counts := {}


func _initialize() -> void:
	_run.call_deferred()


func _eq(actual, expected, label: String) -> void:
	if actual == expected:
		_passed += 1
	else:
		_failed += 1
		printerr("FAIL %s: expected %s, got %s" % [label, str(expected), str(actual)])


# ---- 輸入(與 test_home_interaction 相同做法) ----

func _button(pos: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = pos
	e.global_position = pos
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	root.push_input(e, true)


func _move(pos: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = pos
	e.global_position = pos
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(e, true)


func _hover(pos: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = pos
	e.global_position = pos
	root.push_input(e, true)


func _tap(pos: Vector2) -> void:
	_hover(pos)
	_button(pos, true)
	_button(pos, false)


func _drag(from: Vector2, delta: Vector2) -> void:
	_hover(from)
	_button(from, true)
	for i in range(1, 5):
		_move(from + delta * (i / 4.0))
	_button(from + delta, false)


func _frames(n := 2) -> void:
	for i in n:
		await process_frame


func _wait(sec: float) -> void:
	await create_timer(sec).timeout


func _count(key: String) -> Callable:
	return func() -> void: counts[key] = counts.get(key, 0) + 1


func _c(key: String) -> int:
	return counts.get(key, 0)


## 依規格(使用者確認版)獨立算出的期望值,不呼叫 HomeLogic,避免同一份錯誤兩邊都對
func _spec(h: int, t: int, b: int) -> Dictionary:
	var s := h - t - b - 600
	var add_top := 0
	var cut := 0
	if s >= 0:
		add_top = int(floor(0.6 * s + 0.5 + 1e-9))
	else:
		cut = -s
	var d01 := t + 4
	var d02 := t + 56 + add_top
	var cut_top := clampi(cut, 0, 8)
	var cut_bottom := clampi(cut - 8, 0, 8)
	var rows := clampi(cut - 16, 0, 16)
	var d15 := d02 + 60 - cut_top
	var d15_h := 232 - rows
	return {"d01": d01, "d02": d02, "d15": d15, "d15_h": d15_h, "d06": d15 + d15_h + 16 - cut_bottom,
		"bottom": h - b - 132, "rows": rows}


func _make_home(h: int, t: int, b: int, w := 360) -> void:
	if home:
		home.queue_free()
		await _frames()
	counts.clear()
	# headless 的 root 預設不是 360 寬 × h 高,超出 root 範圍的點擊會被丟掉;改成與模擬畫面同大
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(w, h)
	await _frames()
	var node: Control = load("res://scenes/home.tscn").instantiate()
	node.set_script(load(HOME_SIM_PATH))
	node.sim_view = Vector2(w, h)
	node.sim_safe = Vector2i(t, b)
	root.add_child(node)
	home = node
	await _frames(3)
	map = home._map
	home._heart.pressed.connect(_count("heart"))
	home._start.pressed.connect(_count("start"))
	home._title.pressed.connect(_count("title"))
	home._right.pressed.connect(_count("right"))
	for i in home._bottom_buttons.size():
		home._bottom_buttons[i].pressed.connect(_count("bottom%d" % i))


func _run() -> void:
	# 普通高度(T=24、B=16)
	for h in [640, 673, 780, 800, 840, 900]:
		await _case(h, 24, 16)
	# 高畫面 + 安全區大於保底
	await _case(800, 40, 30)
	# 扣高(S < 0)
	for tb in [[28, 16], [36, 16], [24, 36], [24, 33], [48, 24], [51, 24]]:
		await _case(640, tb[0], tb[1])
	# 比 9:16 寬:版面置中
	await _case(640, 24, 16, 480)
	await _test_d20_examples()
	await _test_old_positions_dead()
	await _test_d14_overlap()
	await _test_resize()
	if home:
		home.queue_free()
		await _frames()
	print("PASSED %d, FAILED %d" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _case(h: int, t: int, b: int, w := 360) -> void:
	await _make_home(h, t, b, w)
	var e := _spec(h, t, b)
	var ox := floorf((w - 360) / 2.0)
	var o := Vector2(ox, 0)
	var tag := "%dx%d T%d B%d" % [w, h, t, b]
	_eq(home.position.x, ox, tag + " centered x")
	_eq(map.position.y, float(e.d15), tag + " D15 y")
	_eq(map.size.y, float(e.d15_h), tag + " D15 height")
	_eq(home._start.position.y, float(e.d06), tag + " D06 y")
	_eq(home._bottom_buttons[0].position.y, float(e.bottom), tag + " bottom y")
	_eq(home._title.position.y, float(e.d02), tag + " D02 y")
	_eq(home._heart.position.y, float(e.d01), tag + " D01 heart y")

	# 每一格點中心都要選到;第 1、2、3 排依扣高往上移
	var dy: int = e.d15 - 140
	var cut1: int = map._pages[1].row_cuts[0]
	var cut2: int = map._pages[1].row_cuts[1]
	_eq(cut1 + cut2, e.rows, tag + " row cuts total")
	for i in 10:
		var row := 0 if i < 3 else (1 if i < 7 else 2)
		var shift := 0 if row == 0 else (cut1 if row == 1 else cut1 + cut2)
		var p: Vector2 = C[i] + o + Vector2(0, dy - shift)
		map.show_group(2, 11 if i != 0 else 12)
		home._apply_selection(map.selected_level)
		await _frames()
		_tap(p)
		await _wait(0.2)
		_eq(home.selected_level, 11 + i, "%s tap tile %d at %s" % [tag, i + 1, p])
	_eq(root.get_visible_rect().size, Vector2(w, h), tag + " root size for input")
	# 觸控 66×66 = 中心 −33 ~ +32:第 10 格 +32 可選;第 1 格 −34 不可選
	map.show_group(2, 15)
	home._apply_selection(15)
	await _frames()
	var c10: Vector2 = C[9] + o + Vector2(0, dy - cut1 - cut2)
	_tap(c10 + Vector2(0, 32))
	await _wait(0.2)
	_eq(home.selected_level, 20, tag + " tile10 bottom touch edge +32")
	map.show_group(2, 15)
	home._apply_selection(15)
	await _frames()
	var c1: Vector2 = C[0] + o + Vector2(0, dy)
	_tap(c1 + Vector2(0, -34))
	await _wait(0.2)
	_eq(home.selected_level, 15, tag + " tile1 above touch -34 no select")
	_tap(c1 + Vector2(0, -33))
	await _wait(0.2)
	_eq(home.selected_level, 11, tag + " tile1 touch top edge -33 selects")

	# 滑動起手區:地圖內 x 40 起手可翻頁、x 39 不行;y 用地圖中段
	var mid_y: float = e.d15 + e.d15_h / 2.0
	map.show_group(2, 15)
	await _frames()
	_drag(Vector2(40, mid_y) + o, Vector2(100, 0))
	await _wait(0.35)
	_eq(map.group, 1, tag + " swipe from x40 pages")
	map.show_group(2, 15)
	await _frames()
	_drag(Vector2(39, mid_y) + o, Vector2(100, 0))
	await _wait(0.35)
	_eq(map.group, 2, tag + " swipe from x39 ignored")
	# 起手在地圖上緣第一列 / 下緣最後一列都可以翻頁
	map.show_group(2, 15)
	await _frames()
	_drag(Vector2(200, e.d15) + o, Vector2(-100, 0))
	await _wait(0.35)
	_eq(map.group, 3, tag + " swipe from map top row pages")
	map.show_group(2, 15)
	await _frames()
	_drag(Vector2(200, e.d15 + e.d15_h - 1) + o, Vector2(-100, 0))
	await _wait(0.35)
	_eq(map.group, 3, tag + " swipe from map bottom row pages")
	# 地圖上方 1px(地圖外)起手 → 不動
	map.show_group(2, 15)
	await _frames()
	_drag(Vector2(200, e.d15 - 1) + o, Vector2(-100, 0))
	await _wait(0.35)
	_eq(map.group, 2, tag + " swipe from 1px above map ignored")
	map.show_group(2, 15)
	home._apply_theme(1)
	home._apply_selection(15)
	await _frames()

	# D06:中心與上下緣
	var s0 := _c("start")
	_tap(Vector2(180, e.d06 + 40) + o)
	await _frames()
	_tap(Vector2(180, e.d06) + o)
	await _frames()
	_tap(Vector2(180, e.d06 + 79) + o)
	await _frames()
	_eq(_c("start"), s0 + 3, tag + " D06 center / top / bottom row")
	_tap(Vector2(180, e.d06 + 80) + o)
	await _frames()
	_eq(_c("start"), s0 + 3, tag + " D06 +80 outside")

	# 底部列 4 顆
	for i in 4:
		_tap(Vector2(49 + i * 87, e.bottom + 36) + o)
		await _frames()
		_eq(_c("bottom%d" % i), 1, "%s bottom %d" % [tag, i])
	_tap(Vector2(49, e.bottom + 72) + o)
	await _frames()
	_eq(_c("bottom0"), 1, tag + " bottom row +72 outside")
	await _check_d20(e, h, b, o, tag)

	# D02 中間文字
	_tap(Vector2(180, e.d02 + 24) + o)
	await _frames()
	_eq(_c("title"), 1, tag + " D02 title")

	# D01 愛心:長按出 D14,位置 D01+44(節點)、本體 D01+48
	_hover(Vector2(30, e.d01 + 22) + o)
	_button(Vector2(30, e.d01 + 22) + o, true)
	await _wait(0.6)
	_eq(home._tooltip.visible, true, tag + " D14 shown")
	_eq(home._tooltip.position.y, float(e.d01 + 44), tag + " D14 node y = D01+44")
	_button(Vector2(30, e.d01 + 22) + o, false)
	await _frames()
	_eq(home._tooltip.visible, false, tag + " D14 hidden on release")
	# 短按愛心 → 商城
	var h0 := _c("heart")
	_tap(Vector2(30, e.d01 + 22) + o)
	await _frames()
	_eq(_c("heart"), h0 + 1, tag + " heart short tap")


## D20 底部共用黑底:位置跟著底部列(上緣 = 底部列 − 4、344×80)、與 banner 間隔 6、
## alpha 160、不吃觸控、圖層在 D02 之上 / 4 顆按鈕之下;同時檢查 D15 黑底 alpha 160
func _check_d20(e: Dictionary, h: int, b: int, o: Vector2, tag: String) -> void:
	var bg: Control = home._bottom_bg
	_eq(Rect2(bg.position, bg.size), Rect2(8, e.bottom - 4, 344, 80), tag + " D20 rect")
	# banner 上緣 = h − B − 50(底部列下緣 + 10),與 D20 下緣差 6
	_eq(h - b - 50 - int(bg.position.y + bg.size.y), 6, tag + " D20 gap to banner 6")
	_eq(home.BOTTOM_BG_COLOR, Color(0, 0, 0, 160.0 / 255.0), tag + " D20 color alpha 160")
	_eq(map.BG_COLOR, Color(0, 0, 0, 160.0 / 255.0), tag + " D15 color alpha 160")
	_eq(bg.mouse_filter, Control.MOUSE_FILTER_IGNORE, tag + " D20 ignores mouse")
	var idx := bg.get_index()
	_eq(idx > home._right.get_index(), true, tag + " D20 above D02")
	for btn in home._bottom_buttons:
		_eq(idx < btn.get_index(), true, tag + " D20 below bottom button")
	_eq(idx < home._tooltip.get_index(), true, tag + " D20 below D14")
	# 點 D20 上方 4px 留白與按鈕間縫隙:底不吃觸控,也不觸發任何按鈕
	var before := 0
	for i in 4:
		before += _c("bottom%d" % i)
	_tap(Vector2(49, e.bottom - 2) + o)
	await _frames()
	_tap(Vector2(92, e.bottom + 36) + o)
	await _frames()
	var after := 0
	for i in 4:
		after += _c("bottom%d" % i)
	_eq(after, before, tag + " D20 margin / gap no trigger")


## D20 設計稿上的具體數字(640、780、較大下安全區)
func _test_d20_examples() -> void:
	for c in [[640, 24, 16, 488, 568], [780, 24, 16, 628, 708], [800, 40, 30, 634, 714]]:
		await _make_home(c[0], c[1], c[2])
		var bg: Control = home._bottom_bg
		_eq([bg.position.y, bg.position.y + bg.size.y], [float(c[3]), float(c[4])], "H%d B%d D20 y range" % [c[0], c[2]])
		_eq(preload("res://scripts/home_logic.gd").home_layout(c[0], c[1], c[2]).banner, c[4] + 6, "H%d B%d banner top = D20 bottom + 6" % [c[0], c[2]])


## 900 高時,640 版的舊座標不應再觸發(確認觸控真的跟著移,不是兩邊都有)
func _test_old_positions_dead() -> void:
	await _make_home(900, 24, 16)
	_tap(Vector2(180, 428))  # 640 的 D06 中心,900 時落在地圖第 3 排與 D06 之間?
	await _frames()
	_eq(_c("start"), 0, "900 old D06 pos no start")
	_tap(Vector2(49, 528))
	await _frames()
	_eq(_c("bottom0"), 0, "900 old bottom pos no trigger")
	_tap(Vector2(180, 104))
	await _frames()
	_eq(_c("title"), 0, "900 old D02 pos no trigger")


## D14 與 D02 重疊:S ≥ 33 不重疊(D02 可點),S ≤ 32 重疊
func _test_d14_overlap() -> void:
	for h in [672, 673]:
		await _make_home(h, 24, 16)
		var tip := Rect2(home._tooltip.position, home._tooltip.size)
		var d02 := Rect2(home._left.position, Vector2(292, 48))
		_eq(tip.intersects(d02), h == 672, "H%d D14 overlaps D02 = %s" % [h, h == 672])


## 視窗大小改變時重排(size_changed)
func _test_resize() -> void:
	await _make_home(640, 24, 16)
	home.sim_view = Vector2(360, 840)
	root.size_changed.emit()
	await _frames()
	_eq(map.position.y, 260.0, "resize 640->840 D15")
	_eq(home._bottom_buttons[0].position.y, 692.0, "resize 640->840 bottom")
	_eq(home._bg.position.y, 200.0, "resize 640->840 bg bottom aligned")
	_eq(home._bg_top.size.y, 200.0, "resize 640->840 bg top height")
	home.sim_view = Vector2(480, 640)
	root.size_changed.emit()
	await _frames()
	_eq(home.position.x, 60.0, "resize -> 480 wide centered")
	_eq(map.position.y, 140.0, "resize back 640 D15")
	_eq(home._bg_top.size.y, 0.0, "resize back bg top 0")
	# 扣高後再放大:地圖高度要恢復
	home.sim_safe = Vector2i(48, 24)
	home.sim_view = Vector2(360, 640)
	root.size_changed.emit()
	await _frames()
	_eq(map.size.y, 216.0, "cut32 map height")
	home.sim_safe = Vector2i(24, 16)
	home.sim_view = Vector2(360, 800)
	root.size_changed.emit()
	await _frames()
	_eq(map.size.y, 232.0, "map height restored after cut")
	_eq(map._pages[1].row_cuts, [0, 0], "row cuts restored")
	# 恢復後點第 10 格仍正確
	map.show_group(2, 15)
	await _frames()
	_tap(C[9] + Vector2(0, 236 - 140))
	await _wait(0.2)
	_eq(home.selected_level, 20, "tile10 tap after restore")
