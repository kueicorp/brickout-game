extends SceneTree
## QA 商城返回行為重測(B1 廣告載入中返回、B2 付款中返回 + 回歸)。執行:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path game --script res://tests/test_qa_shop_back.gd
## 有任何失敗時結束碼為 1。

const HOME_SIM_PATH := "res://tests/home_sim.gd"
const S := preload("res://scripts/shop_service.gd")
const ES := preload("res://scripts/event_service.gd")
const L := preload("res://scripts/shop_logic.gd")
const DELAY := 0.05
const WAIT := 0.15
const SLOW := 0.3
const SHOP_BTN := Vector2(136, 528)
const BACK_BTN := Vector2(30, 102)

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


func _move(pos: Vector2, held := true) -> void:
	var m := InputEventMouseMotion.new()
	m.position = pos
	m.global_position = pos
	m.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	root.push_input(m, true)


func _tap(pos: Vector2) -> void:
	_move(pos, false)
	_button(pos, true)
	_button(pos, false)


func _frames(n := 2) -> void:
	for i in n:
		await process_frame


func _wait(sec := WAIT) -> void:
	await create_timer(sec).timeout


func _back_key() -> void:
	home.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await _frames()


func _back_btn() -> void:
	_tap(BACK_BTN)
	await _frames()


func _make_home() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(360, 640)
	await _frames()
	var node: Control = load("res://scenes/home.tscn").instantiate()
	node.set_script(load(HOME_SIM_PATH))
	root.add_child(node)
	home = node
	await _frames(3)


func _reset() -> void:
	ES.reset()
	ES.delay_sec = DELAY
	S.reset()
	S.delay_sec = DELAY
	FakeData.ads_removed = false


func _shop():
	return home._shop


func _page():
	return home._shop._page


func _dialog():
	return home._shop._dialog



## 商城仍是同一個、且沒被釋放(被釋放的物件與 null 比較會相等,不能直接 _eq(home._shop, shop))
func _kept(shop) -> bool:
	return is_instance_valid(shop) and home._shop == shop


func _popup():
	return home._popup


func _target_center(key: String) -> Vector2:
	for t in _page()._targets:
		if t.key == key:
			return _page().global_position + t.rect.get_center() - Vector2(0, _page().scroll)
	return Vector2(-100, -100)


func _open_shop() -> void:
	_tap(SHOP_BTN)
	await _frames()
	await _wait()


func _close_all_popups() -> void:
	var guard := 0
	while _popup().is_open() and guard < 20:
		guard += 1
		await _back_key()


func _leave_shop() -> void:
	S.delay_sec = DELAY
	await _wait(0.4)
	await _close_all_popups()
	if home._shop:
		if _dialog().is_open():
			_dialog().close()
		home._close_shop()
	await _wait()
	await _close_all_popups()


func _run() -> void:
	_reset()
	await _make_home()
	await _wait()
	await _close_all_popups()
	await _test_normal_back()
	await _test_dialogs_close_only()
	await _test_ad_busy()
	await _test_ad_fail_then_leave()
	await _test_iap_paying_and_verify()
	await _test_iap_canceled_then_leave()
	await _test_iap_pending_then_leave()
	await _test_iap_verify_fail()
	await _test_event_back()
	print("PASSED %d, FAILED %d" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


## 一般狀態:返回鍵、左上返回鈕都離開商城
func _test_normal_back() -> void:
	print("-- normal back")
	await _open_shop()
	_eq(home._shop != null, true, "shop opened")
	await _back_key()
	_eq(home._shop, null, "back key leaves shop")
	await _wait()
	await _open_shop()
	await _back_btn()
	_eq(home._shop, null, "back button leaves shop")
	await _wait()


## D23 確認框、D24 金塊不足框、D27 詳情框:返回鍵只關框;D23 送出後(處理中…)返回無效
func _test_dialogs_close_only() -> void:
	print("-- dialogs close only")
	var w: Dictionary = ES.wallet
	w.silver = 300
	w.gold = 50
	await _open_shop()
	var shop = _shop()
	var d = _dialog()
	shop.select_tab(L.Tab.ITEMS)
	await _frames()
	_tap(_target_center("item:0:1"))
	await _frames()
	_eq(d.mode, d.Mode.CONFIRM, "D23 open")
	await _back_key()
	_eq([d.is_open(), _kept(shop)], [false, true], "D23 back key closes dialog only")
	_tap(_target_center("item:0:1"))
	await _frames()
	await _back_btn()
	_eq(_kept(shop), true, "D23 back button does not leave shop")
	d.close()
	await _frames()
	# D24
	w.silver = 0
	w.gold = 0
	shop._fetch()
	await _wait()
	shop.select_tab(L.Tab.ITEMS)
	await _frames()
	_tap(_target_center("bundle"))
	await _frames()
	_eq(d.mode, d.Mode.SHORT, "D24 open")
	await _back_key()
	_eq([d.is_open(), _kept(shop)], [false, true], "D24 back key closes dialog only")
	# D27
	_tap(_target_center("detail:0"))
	await _frames()
	_eq(d.mode, d.Mode.DETAIL, "D27 open")
	await _back_key()
	_eq([d.is_open(), _kept(shop)], [false, true], "D27 back key closes dialog only")
	# D23 處理中
	w.silver = 300
	w.gold = 50
	shop._fetch()
	await _wait()
	shop.select_tab(L.Tab.ITEMS)
	await _frames()
	S.delay_sec = SLOW
	_tap(_target_center("item:0:1"))
	await _frames()
	_tap(d._primary.get_global_rect().get_center())
	await _frames()
	_eq(d.busy, true, "D23 busy")
	await _back_key()
	await _back_btn()
	_eq([d.is_open(), _kept(shop)], [true, true], "D23 busy: back ignored")
	await _wait(0.4)
	await _close_all_popups()
	S.delay_sec = DELAY
	await _back_key()
	_eq(home._shop, null, "leaves after D23 done")
	await _wait()


## B1:廣告載入中連按返回鍵 / 返回鈕,商城不關、只發一次獎、框數字正確,之後可離開
func _test_ad_busy() -> void:
	print("-- ad busy")
	_reset()
	await _open_shop()
	var shop = _shop()
	shop.select_tab(L.Tab.FREE)
	await _frames()
	var coin0: int = ES.wallet.coin
	var left0: int = S.free_left[1]
	S.delay_sec = SLOW
	_tap(_target_center("ad:1"))
	await _frames()
	_eq(shop._ad_busy, 1, "ad busy state when back pressed")
	for i in 3:
		await _back_key()
		await _back_btn()
	_eq([_kept(shop), shop._ad_busy], [true, 1], "ad loading: repeated back ignored")
	await _wait(0.4)
	_eq(shop._ad_busy, -1, "ad busy cleared")
	_eq(_popup().is_open(), true, "ad result popup shown")
	var p: Dictionary = _popup().current()
	var gained: int = ES.wallet.coin - coin0
	_eq(p.get("title", ""), "已獲得", "popup title")
	_eq(p.get("rewards", []), [["coin", gained]], "popup amount == wallet delta")
	_eq([S.free_left[1], gained > 0], [left0 - 1, true], "free_left -1 exactly, coin granted")
	await _close_all_popups()
	_eq(_kept(shop), true, "shop still open after popup closed")
	await _back_btn()
	_eq(home._shop, null, "back button leaves after ad")
	S.delay_sec = DELAY
	await _wait()


## 廣告失敗:忙碌解除,toast,之後可離開
func _test_ad_fail_then_leave() -> void:
	print("-- ad fail")
	await _open_shop()
	var shop = _shop()
	shop.select_tab(L.Tab.FREE)
	await _frames()
	S.delay_sec = SLOW
	S.fail_next = 1
	_tap(_target_center("ad:1"))
	await _frames()
	await _back_key()
	_eq(_kept(shop), true, "ad (will fail) loading: back ignored")
	await _wait(0.4)
	_eq([shop._ad_busy, shop.toast_text], [-1, L.TOAST_AD_FAIL], "ad fail toast, busy cleared")
	await _back_key()
	_eq(home._shop, null, "back leaves after ad fail")
	S.delay_sec = DELAY
	await _wait()


## B2:Google Play 付款中、D20 驗證中返回鍵 / 返回鈕無效;結果回來跳框、金塊正確、訂單不卡 _paid
func _test_iap_paying_and_verify() -> void:
	print("-- iap paying / verify")
	_reset()
	await _open_shop()
	var shop = _shop()
	var gold0: int = ES.wallet.gold
	shop.select_tab(L.Tab.TOPUP)
	await _frames()
	S.delay_sec = SLOW
	_tap(_target_center("gold:30"))
	await _frames()
	_eq([shop._iap_busy, _dialog().is_open()], [true, false], "paying state (before D20) when back pressed")
	for i in 3:
		await _back_key()
		await _back_btn()
	_eq(_kept(shop), true, "paying: repeated back ignored")
	# 服務端已記為已付款(_paid),前端尚未收到結果:正是 B2 的情境
	_eq([S._paid.size(), _dialog().is_open()], [1, false], "paid server-side, result not yet delivered")
	var t := 0
	while _dialog().mode != _dialog().Mode.PROCESSING and t < 60:
		t += 1
		await _wait(0.01)
	# verify_iap 已送出(假服務同步把訂單移出 _paid)
	_eq([_dialog().mode, shop._iap_busy, S._paid.size()], [_dialog().Mode.PROCESSING, true, 0], "D20 processing, verify sent")
	for i in 3:
		await _back_key()
		await _back_btn()
	_eq([_kept(shop), _dialog().mode], [true, _dialog().Mode.PROCESSING], "verify: repeated back ignored")
	await _wait(0.4)
	_eq([_dialog().is_open(), _popup().is_open(), shop._iap_busy], [false, true, false], "popup after verify")
	_eq([S._paid.size(), S.pending_orders.size()], [0, 0], "order not stuck")
	_eq(ES.wallet.gold - gold0, 30, "gold +30 exactly")
	await _close_all_popups()
	_eq(_kept(shop), true, "shop open after popup")
	await _back_key()
	_eq(home._shop, null, "back leaves after payment")
	S.delay_sec = DELAY
	await _wait()


## 付款取消 / 失敗:忙碌解除,之後可離開
func _test_iap_canceled_then_leave() -> void:
	print("-- iap canceled")
	await _open_shop()
	var shop = _shop()
	S.delay_sec = SLOW
	S.play_result = "canceled"
	_tap(_target_center("gold:30"))
	await _frames()
	await _back_key()
	_eq(_kept(shop), true, "paying (will cancel): back ignored")
	await _wait(0.4)
	_eq([shop._iap_busy, _popup().is_open(), _dialog().is_open()], [false, false, false], "canceled: no popup, busy cleared")
	await _back_btn()
	_eq(home._shop, null, "back button leaves after cancel")
	S.delay_sec = DELAY
	await _wait()


func _test_iap_pending_then_leave() -> void:
	print("-- iap pending")
	await _open_shop()
	var shop = _shop()
	S.delay_sec = SLOW
	S.play_result = "pending"
	_tap(_target_center("gold:30"))
	await _frames()
	await _back_key()
	_eq(_kept(shop), true, "paying (pending): back ignored")
	await _wait(0.4)
	_eq([shop._iap_busy, _popup().is_open()], [false, true], "pending popup shown")
	await _close_all_popups()
	await _back_key()
	_eq(home._shop, null, "back leaves after pending")
	S.delay_sec = DELAY
	S.reset()
	S.delay_sec = DELAY
	await _wait()


func _test_iap_verify_fail() -> void:
	print("-- iap verify fail")
	await _open_shop()
	var shop = _shop()
	S.delay_sec = SLOW
	S.verify_result = "fail"
	_tap(_target_center("gold:30"))
	await _frames()
	await _wait(0.4)
	await _back_key()
	_eq([_kept(shop), _dialog().mode], [true, _dialog().Mode.PROCESSING], "verify (will fail): back ignored")
	await _wait(0.4)
	_eq([shop._iap_busy, _popup().is_open(), S._paid.size()], [false, true, 0], "verify fail: popup, not stuck in _paid")
	await _close_all_popups()
	await _back_key()
	_eq(home._shop, null, "back leaves after verify fail")
	S.delay_sec = DELAY
	S.reset()
	S.delay_sec = DELAY
	await _wait()


## 活動頁返回不受影響:活動頁開著按返回鍵回首頁
func _test_event_back() -> void:
	print("-- event back")
	_eq(home._shop, null, "shop closed before event test")
	home._open_event()
	await _frames()
	await _wait()
	await _close_all_popups()
	_eq(home._event != null, true, "event opened")
	var guard := 0
	while home._event and guard < 5:
		guard += 1
		await _back_key()
		await _close_all_popups()
	_eq([home._event, home._shop], [null, null], "event back returns home")
