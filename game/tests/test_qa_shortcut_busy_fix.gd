extends SceneTree
## QA(2026-11-07)重測:捷徑列「同一幀漏擋」修正(event_screen go_back / _on_shortcut、shop_screen _is_busy)。
## 補工程師測試沒涵蓋的同一幀情況:活動 B 頁返回鈕、活動首儲購買、商城 Google Play、商城金塊購買送出;
## 並確認不在處理中時捷徑 / 返回鈕照常可用(沒有被誤擋)。執行:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path game --script res://tests/test_qa_shortcut_busy_fix.gd
## 有任何失敗時結束碼為 1。

const HOME_SIM_PATH := "res://tests/home_sim.gd"
const S := preload("res://scripts/shop_service.gd")
const ES := preload("res://scripts/event_service.gd")
const L := preload("res://scripts/shop_logic.gd")
const DELAY := 0.05
const WAIT := 0.15
const SLOW := 0.4
const EVENT := 0
const SHOP := 1
const CHECKIN_BTN := Vector2(298, 158)

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


func _button(pos: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = pos
	e.global_position = pos
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	root.push_input(e, true)


func _tap(pos: Vector2) -> void:
	var m := InputEventMouseMotion.new()
	m.position = pos
	m.global_position = pos
	root.push_input(m, true)
	_button(pos, true)
	_button(pos, false)


func _frames(n := 2) -> void:
	for i in n:
		await process_frame


func _wait(sec := WAIT) -> void:
	await create_timer(sec).timeout


func _make_home() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(360, 640)
	await _frames()
	var node: Control = load("res://scenes/home.tscn").instantiate()
	node.set_script(load(HOME_SIM_PATH))
	node.sim_view = Vector2(360, 640)
	node.sim_safe = Vector2i(24, 16)
	root.add_child(node)
	home = node
	await _frames(3)
	await _wait()
	await _close_popups()


func _reset() -> void:
	ES.reset()
	ES.delay_sec = DELAY
	S.reset()
	S.delay_sec = DELAY
	FakeData.ads_removed = false


func _bar() -> PageShortcutBar:
	return home._event.shortcuts if home._event else home._shop.shortcuts


func _key(i: int) -> Vector2:
	return _bar().keys[i].get_global_rect().get_center()


func _back_btn() -> Vector2:
	return _bar().back.get_global_rect().get_center()


func _back_key() -> void:
	home.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await _frames()


func _close_popups() -> void:
	while home._popup.is_open():
		home._popup.close_current()
		await _frames()


func _open(i: int) -> void:
	_tap(home._bottom_buttons[i].get_global_rect().get_center())
	await _frames()
	await _wait()
	await _close_popups()


func _to_home() -> void:
	await _wait(SLOW * 2 + 0.2)
	await _close_popups()
	if home._event:
		home._event.show_page(EventLogic.Page.LIST)
	var guard := 0
	while (home._event or home._shop) and guard < 10:
		guard += 1
		await _back_key()
		await _close_popups()
	await _wait()


func _run() -> void:
	_reset()
	await _make_home()
	await _test_event_back_btn_same_frame()
	_reset()
	await _test_event_topup_same_frame()
	_reset()
	await _test_shop_iap_same_frame()
	_reset()
	await _test_shop_gold_same_frame()
	_reset()
	await _test_idle_not_blocked()
	if home:
		home.queue_free()
		await _frames()
	_reset()
	print("PASSED %d, FAILED %d" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


## 活動 B 頁:同一幀「簽到」+ 返回鈕(只點返回,不點捷徑):應留在 B,結果回來出「已獲得」
func _test_event_back_btn_same_frame() -> void:
	print("-- event B: checkin + back button same frame")
	await _open(EVENT)
	var ev = home._event
	ev.show_page(EventLogic.Page.CHECKIN)
	await _frames()
	ES.delay_sec = SLOW
	_tap(CHECKIN_BTN)
	_tap(_back_btn())
	await _frames()
	ES.delay_sec = DELAY
	_eq([ev.is_busy(), home._event == ev, ev.page], [true, true, EventLogic.Page.CHECKIN], "event B checkin + back same frame: stays on B")
	await _wait(SLOW + 0.1)
	_eq(home._popup.is_open(), true, "event B checkin + back: 已獲得 popup")
	await _to_home()


## 活動 C 頁:同一幀「首儲購買」+ 商城捷徑 / 返回鈕:應留在 C
func _test_event_topup_same_frame() -> void:
	print("-- event C: buy + shortcut same frame")
	await _open(EVENT)
	var ev = home._event
	ev.show_page(EventLogic.Page.TOPUP)
	await _frames()
	ES.delay_sec = SLOW
	ev._on_buy_pressed()
	_eq(ev.is_busy(), true, "event C buy: busy")
	_tap(_key(SHOP))
	_tap(_back_btn())
	await _frames()
	ES.delay_sec = DELAY
	var stayed: bool = is_instance_valid(ev) and home._event == ev
	_eq([stayed, ev.page if stayed else -1, home._shop], [true, EventLogic.Page.TOPUP, null], "event C buy + 商城 / back same frame: stays on C")
	await _wait(SLOW + 0.1)
	if stayed:
		_eq(ev.is_busy(), false, "event C buy: done")
	await _to_home()


## 商城:同一幀開始 Google Play 付款 + 活動捷徑 / 返回鈕:應留在商城
func _test_shop_iap_same_frame() -> void:
	print("-- shop iap same frame")
	await _open(SHOP)
	var shop = home._shop
	S.delay_sec = SLOW
	shop._on_tapped("iap", "gold:%d" % L.GOLD_PACKS[0][0])
	_eq(shop._iap_busy, true, "iap: busy")
	_tap(_key(EVENT))
	_tap(_back_btn())
	await _frames()
	var stayed: bool = is_instance_valid(shop) and home._shop == shop
	_eq([stayed, home._event], [true, null], "iap + 活動 / back same frame: stays on shop")
	S.delay_sec = DELAY
	await _wait(SLOW * 2 + 0.2)
	await _close_popups()
	if stayed:
		_eq(shop._iap_busy, false, "iap: done")
	await _to_home()


## 商城金塊購買送出(對話框 busy):同一幀點返回鈕、活動捷徑;另外直接送捷徑訊號、呼叫 handle_back(繞過框的遮擋,只測邏輯)
func _test_shop_gold_same_frame() -> void:
	print("-- shop gold same frame")
	await _open(SHOP)
	var shop = home._shop
	S.delay_sec = SLOW
	shop._start_gold_buy("item:0:1")
	shop._on_confirmed("item:0:1")
	_eq([shop._dialog.is_open(), shop._dialog.busy, shop._is_busy()], [true, true, true], "gold sent: dialog busy")
	_tap(_back_btn())
	_tap(_key(EVENT))
	shop.shortcuts.page_pressed.emit(PageShortcutBar.Page.EVENT)
	shop.shortcuts.back_pressed.emit()
	shop.handle_back()
	await _frames()
	var stayed: bool = is_instance_valid(shop) and home._shop == shop
	_eq([stayed, home._event], [true, null], "gold busy + back / 活動 same frame (tap + direct signals): stays on shop")
	if not stayed:
		await _to_home()
		return
	_eq([shop._dialog.is_open(), shop._dialog.busy], [true, true], "gold busy: dialog still open + busy")
	await _back_key()
	_eq([home._shop == shop, shop._dialog.is_open()], [true, true], "gold busy: back key ignored")
	S.delay_sec = DELAY
	await _wait(SLOW + 0.1)
	_eq([shop._dialog.busy, shop._is_busy()], [false, false], "gold done: not busy")
	await _close_popups()
	await _to_home()


## 不在處理中:捷徑、返回鈕照常可用;處理結束後第一個可點的幀起也可用
func _test_idle_not_blocked() -> void:
	print("-- idle not blocked")
	# 活動 A → 商城捷徑
	await _open(EVENT)
	_tap(_key(SHOP))
	await _frames()
	_eq([home._shop != null, home._event], [true, null], "idle event A: 商城 shortcut switches")
	await _wait()
	await _close_popups()
	# 商城 → 活動捷徑
	_tap(_key(EVENT))
	await _frames()
	_eq([home._event != null, home._shop], [true, null], "idle shop: 活動 shortcut switches")
	await _wait()
	await _close_popups()
	# 活動 B:返回鈕回 A、活動捷徑回 A、A 返回鈕回首頁
	home._event.show_page(EventLogic.Page.CHECKIN)
	await _frames()
	_tap(_back_btn())
	await _frames()
	_eq([home._event != null, home._event.page], [true, EventLogic.Page.LIST], "idle event B: back -> A")
	home._event.show_page(EventLogic.Page.TOPUP)
	await _frames()
	_tap(_key(EVENT))
	await _frames()
	_eq(home._event.page, EventLogic.Page.LIST, "idle event C: 活動 shortcut -> A")
	_tap(_back_btn())
	await _frames()
	_eq([home._event, home._shop, home._map.visible], [null, null, true], "idle event A: back -> home")
	await _wait()
	# 活動:簽到結束後可離開
	await _open(EVENT)
	var ev = home._event
	ev.show_page(EventLogic.Page.CHECKIN)
	await _frames()
	_tap(CHECKIN_BTN)
	await _wait(DELAY + 0.1)
	await _frames()
	await _close_popups()
	_eq(ev.is_busy(), false, "checkin done")
	_tap(_key(SHOP))
	await _frames()
	_eq([home._shop != null, home._event], [true, null], "after checkin done: 商城 shortcut works")
	await _wait()
	await _close_popups()
	# 商城:看廣告結束後捷徑、返回鈕可用
	var shop = home._shop
	shop._watch_ad(0)
	await _wait(DELAY + 0.1)
	await _frames()
	await _close_popups()
	_eq([shop._is_busy(), _bar().back.disabled], [false, false], "ad done: idle")
	_tap(_back_btn())
	await _frames()
	_eq([home._shop, home._map.visible], [null, true], "after ad done: back button -> home")
	await _wait()
	# 商城:金塊購買完成後捷徑可用
	await _open(SHOP)
	shop = home._shop
	shop._start_gold_buy("item:0:1")
	shop._on_confirmed("item:0:1")
	await _wait(DELAY + 0.1)
	await _frames()
	await _close_popups()
	_eq([shop._is_busy(), shop._dialog.is_open()], [false, false], "gold done: idle, dialog closed")
	_tap(_key(EVENT))
	await _frames()
	_eq([home._event != null, home._shop], [true, null], "after gold done: 活動 shortcut works")
	await _to_home()
