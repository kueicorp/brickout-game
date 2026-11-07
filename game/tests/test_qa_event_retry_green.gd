extends SceneTree
## QA(2026-11-07):活動頁 D14「重試」鈕改用 GreenButton(九宮格綠色按鈕,與商城一致)。
## 驗證:類別 / 外觀屬性與商城重試鈕一致;B、C × 640、800 位置尺寸;按住 = pressed(is_held);
## 移出放開不觸發;點擊重新取資料、失敗仍顯示、成功後隱藏;活動頁內已無綠色 FlatButton。
## 2026-11-07 依 page-shortcuts P07 更新:返回鈕改為捷徑列的返回鈕(加底板)。執行:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path game --script res://tests/test_qa_event_retry_green.gd

const HOME_SIM_PATH := "res://tests/home_sim.gd"
const ES := preload("res://scripts/event_service.gd")
const SS := preload("res://scripts/shop_service.gd")
const L := preload("res://scripts/event_logic.gd")
const DELAY := 0.05
const WAIT := 0.15
## [畫面高, 預期重試鈕 y](640 原規格 352;800 T24 B16 = 352 + round(E/2) = 432,見 test_event_screen S08_CASES)
const CASES := [[640, 352], [800, 432]]

var _passed := 0
var _failed := 0
var home


func _initialize() -> void:
	_run.call_deferred()


func _eq(actual, expected, label: String) -> void:
	if actual == expected:
		_passed += 1
	else:
		_failed += 1
		printerr("FAIL %s: expected %s, got %s" % [label, str(expected), str(actual)])


func _mouse(pos: Vector2, down: bool) -> void:
	var m := InputEventMouseMotion.new()
	m.position = pos
	m.global_position = pos
	m.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	root.push_input(m, true)


func _button(pos: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = pos
	e.global_position = pos
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	root.push_input(e, true)


func _tap(pos: Vector2) -> void:
	_mouse(pos, false)
	_button(pos, true)
	_button(pos, false)


func _frames(n := 2) -> void:
	for i in n:
		await process_frame


func _wait(sec := WAIT) -> void:
	await create_timer(sec).timeout


func _make_home(h: int) -> void:
	if home:
		home.queue_free()
		await _frames()
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(360, h)
	await _frames()
	var node: Control = load("res://scenes/home.tscn").instantiate()
	node.set_script(load(HOME_SIM_PATH))
	node.sim_view = Vector2(360, h)
	node.sim_safe = Vector2i(24, 16)
	root.add_child(node)
	home = node
	await _frames(3)


func _close_popups() -> void:
	while home._popup.is_open():
		home._popup.close_current()
		await _frames()


func _reset() -> void:
	ES.reset()
	ES.delay_sec = DELAY
	SS.reset()
	SS.delay_sec = DELAY


func _run() -> void:
	for c in CASES:
		await _check_event(c[0], c[1])
	await _check_same_as_shop()
	if home:
		home.queue_free()
		await _frames()
	ES.reset()
	SS.reset()
	print("PASSED %d, FAILED %d" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


## 外觀屬性(與商城重試鈕相同的組合)
func _check_look(b, tag: String) -> void:
	_eq(b is GreenButton, true, tag + " is GreenButton")
	_eq(b is FlatButton, false, tag + " not FlatButton")
	_eq([b.text, b.disabled, b.text_color, b.font_size], ["重試", false, Color.BLACK, 14], tag + " text / enabled / color / size")
	_eq(b.size, Vector2(120, 44), tag + " size 120x44")
	# 文字 baseline = GreenButton 平面置中算法(44 高 14px → 21)
	_eq(GreenButton.label_baseline(b.size.y, b.font_size, 1), 21.0, tag + " label baseline 21")


func _check_event(h: int, y: int) -> void:
	var tag := "H%d" % h
	_reset()
	await _make_home(h)
	await _wait()
	await _close_popups()
	ES.fail_next = 1
	home._open_event()
	await _wait()
	var ev = home._event
	_eq(ev.load_state, ev.Load.FAILED, tag + " open failed")
	# ---- B ----
	ev.show_page(L.Page.CHECKIN)
	await _frames()
	var r: Rect2 = ev._retry.get_global_rect()
	_check_look(ev._retry, tag + " B")
	_eq(r, Rect2(120, y, 120, 44), tag + " B retry rect")
	_eq(ev._retry.is_visible_in_tree(), true, tag + " B retry visible")
	# 按住 → pressed;移出後放開不觸發
	_mouse(r.get_center(), false)
	_button(r.get_center(), true)
	await _frames()
	_eq(ev._retry.is_held(), true, tag + " B held while pressed")
	_mouse(Vector2(350, 5), true)
	await _frames()
	_eq(ev._retry.is_held(), false, tag + " B not held after drag out")
	_button(Vector2(350, 5), false)
	await _frames()
	_eq(ev.load_state, ev.Load.FAILED, tag + " B release outside: no fetch")
	# 點擊 → 重新取資料;再失敗 → 仍顯示重試
	ES.fail_next = 1
	_tap(r.get_center())
	await _frames()
	_eq([ev.load_state, ev._retry.visible], [ev.Load.LOADING, false], tag + " B retry -> loading, retry hidden")
	await _wait()
	_eq([ev.load_state, ev._retry.is_visible_in_tree(), ev.toast_text], [ev.Load.FAILED, true, ""], tag + " B retry failed again")
	# ---- C ----
	ev.show_page(L.Page.TOPUP)
	await _frames()
	r = ev._retry.get_global_rect()
	_check_look(ev._retry, tag + " C")
	_eq(r, Rect2(120, y, 120, 44), tag + " C retry rect")
	_mouse(r.get_center(), false)
	_button(r.get_center(), true)
	await _frames()
	_eq(ev._retry.is_held(), true, tag + " C held while pressed")
	_button(r.get_center(), false)
	await _frames()
	_eq(ev._retry.is_held(), false, tag + " C released")
	_eq(ev.load_state, ev.Load.LOADING, tag + " C retry -> loading")
	await _wait()
	await _close_popups()
	_eq([ev.load_state, ev._retry.visible, ev._retry.is_visible_in_tree(), ev._state_view.visible, ev._topup.visible],
		[ev.Load.LOADED, false, false, false, true], tag + " C retry success: retry hidden, page shown")
	ev.show_page(L.Page.CHECKIN)
	await _frames()
	_eq([ev._retry.is_visible_in_tree(), ev._checkin.visible], [false, true], tag + " B after success: retry hidden")
	# 回歸:活動頁內不再有綠色 FlatButton
	var flats: Array = ev.find_children("*", "FlatButton", true, false)
	var greens := flats.filter(func(b) -> bool: return b.fill == FlatButton.GREEN)
	_eq(greens.size(), 0, tag + " no green FlatButton in event screen")
	# 2026-11-07 page-shortcuts P07:返回鈕改由捷徑列畫(44×44、加黑底 alpha 160 底板、箭頭 icon),不再是無底板 FlatButton
	_eq([ev._back is PageShortcutBar.ShortcutButton, ev._back is FlatButton, ev._back == ev.shortcuts.back],
		[true, false, true], tag + " back button is shortcut-bar back")
	_eq([ev._back.icon != null, ev._back.size, ev._back.label, ev._back.selected], [true, Vector2(44, 44), "", false],
		tag + " back button: icon, 44x44, no label / frame")
	_eq(PageShortcutBar.ShortcutButton.BG, Color(0, 0, 0, 160.0 / 255.0), tag + " back button plate black a160")
	# 重試鈕在面板內,不與捷徑列重疊
	_eq(ev._retry.get_global_rect().intersects(ev._back.get_global_rect()), false, tag + " retry not overlapping back")
	home._close_event()
	await _wait()


## 商城重試鈕:同類別、同外觀屬性(與活動頁一致)
func _check_same_as_shop() -> void:
	_reset()
	await _make_home(640)
	await _wait()
	await _close_popups()
	SS.fail_next = 1
	home._open_shop(0)
	await _wait()
	var shop = home._shop
	_eq(shop.load_state, shop.Load.FAILED, "shop failed")
	_check_look(shop._retry, "shop")
	_eq(shop._retry.get_global_rect(), Rect2(120, 378, 120, 44), "shop retry rect 640 unchanged")
	_eq(shop._retry.is_visible_in_tree(), true, "shop retry visible")
	_tap(shop._retry.get_global_rect().get_center())
	await _frames()
	_eq(shop.load_state, shop.Load.LOADING, "shop retry -> loading")
	await _wait()
	_eq([shop.load_state, shop._retry.visible], [shop.Load.LOADED, false], "shop retry -> loaded, hidden")
	home._close_shop()
	await _frames()
