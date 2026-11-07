extends SceneTree
## QA 商城邊界測試(連點、流程中切分頁 / 返回、回前景、紅點即時更新、餘額邊界、遮罩擋操作)。執行:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path game --script res://tests/test_qa_shop_edges.gd
## 有任何失敗時結束碼為 1。

const HOME_SIM_PATH := "res://tests/home_sim.gd"
const S := preload("res://scripts/shop_service.gd")
const ES := preload("res://scripts/event_service.gd")
const L := preload("res://scripts/shop_logic.gd")
const DELAY := 0.05
const WAIT := 0.15
const SHOP_BTN := Vector2(136, 528)
const BACK_BTN := Vector2(30, 102)
const GOLD_ICON := Vector2(194, 50)
const TAB_CENTERS := [Vector2(54, 160), Vector2(138, 160), Vector2(222, 160), Vector2(306, 160)]

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


func _at(content_pos: Vector2) -> Vector2:
	return _page().global_position + content_pos - Vector2(0, _page().scroll)


func _target_center(key: String) -> Vector2:
	for t in _page()._targets:
		if t.key == key:
			return _at(t.rect.get_center())
	return Vector2(-100, -100)


func _has_target(key: String) -> bool:
	return _page()._targets.any(func(t: Dictionary) -> bool: return t.key == key)


func _open_shop() -> void:
	_tap(SHOP_BTN)
	await _frames()
	await _wait()


func _close_all_popups() -> void:
	while _popup().is_open():
		await _back_key()


func _leave_shop() -> void:
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
	await _test_double_tap_iap()
	await _test_double_tap_ad()
	await _test_double_tap_buy()
	await _test_ad_tab_switch()
	await _test_heart_card_updates()
	await _test_badge_immediate()
	await _test_resume_refetch()
	await _test_afford_boundary()
	await _test_mask_blocks_tabs_and_bar()
	await _test_drag_slop()
	await _test_back_during_ad()
	await _test_back_during_iap()
	home.queue_free()
	await _frames()
	_reset()
	print("PASSED %d, FAILED %d" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


## 連點金塊包:只叫一次 Google Play
func _test_double_tap_iap() -> void:
	print("-- double tap iap")
	await _open_shop()
	var seq0: int = S._seq
	var gold0: int = ES.wallet.gold
	var p := _target_center("gold:30")
	_tap(p)
	_tap(p)
	await _frames()
	_tap(p)
	await _wait(0.3)
	_eq(S._seq - seq0, 1, "double tap -> one Google Play order")
	await _close_all_popups()
	_eq(ES.wallet.gold - gold0, 30, "gold +30 once")
	await _leave_shop()


## 連點看廣告:只扣一次次數
func _test_double_tap_ad() -> void:
	print("-- double tap ad")
	await _open_shop()
	_shop().select_tab(L.Tab.FREE)
	await _frames()
	var p := _target_center("ad:1")
	_tap(p)
	_tap(p)
	await _frames()
	_tap(p)
	await _wait()
	_eq(S.free_left[1], 4, "double tap ad -> one use")
	await _leave_shop()


## 連點確認框「購買」:只扣一次款
func _test_double_tap_buy() -> void:
	print("-- double tap buy")
	ES.wallet.silver = 0
	ES.wallet.gold = 1000
	await _open_shop()
	_shop().select_tab(L.Tab.HEART_COIN)
	await _frames()
	_tap(_target_center("coin:1000"))
	await _frames()
	var b: Vector2 = _dialog()._primary.get_global_rect().get_center()
	_tap(b)
	_tap(b)
	await _frames()
	_tap(b)
	await _wait()
	_eq(ES.wallet.gold, 970, "double tap 購買 -> charged once")
	await _leave_shop()


## 廣告載入中切分頁再切回:仍顯示載入中、完成後照常跳框
func _test_ad_tab_switch() -> void:
	print("-- ad + tab switch")
	await _open_shop()
	S.delay_sec = 0.3
	_shop().select_tab(L.Tab.FREE)
	await _frames()
	_tap(_target_center("ad:2"))
	await _frames()
	_tap(TAB_CENTERS[1])
	await _frames()
	_eq(_shop().tab, L.Tab.ITEMS, "tab switch during ad loading")
	_tap(TAB_CENTERS[3])
	await _frames()
	_eq([_shop()._ad_busy, _has_target("ad:2")], [2, false], "still loading after coming back")
	await _wait(0.4)
	_eq([_popup().is_open(), S.free_left[2]], [true, 4], "ad result popup after tab switch")
	S.delay_sec = DELAY
	await _leave_shop()


## 買愛心成功後,卡片狀態依新持有量即時更新(D15「持有量變動後即時更新」)
func _test_heart_card_updates() -> void:
	print("-- heart card update")
	ES.wallet.heart = 92
	ES.wallet.gold = 1000
	await _open_shop()
	_shop().select_tab(L.Tab.HEART_COIN)
	await _frames()
	_eq([_has_target("heart:1"), _has_target("heart:5")], [true, true], "92: 1/5 ok")
	_tap(_target_center("heart:5"))
	await _frames()
	_tap(_dialog()._primary.get_global_rect().get_center())
	await _wait()
	_eq(_popup().current().get("rewards", []), [["heart", 5]], "heart popup x5")
	_eq([_has_target("heart:1"), _has_target("heart:5")], [true, false], "97: 5 now over cap (before 好)")
	await _close_all_popups()
	_eq(home._resources.values[0], 97, "resource bar 97")
	await _leave_shop()
	ES.wallet.heart = 3


## D18:最後一次免費次數看完,分頁籤紅點立即消失;回首頁 D17 也消失
func _test_badge_immediate() -> void:
	print("-- badge immediate")
	S.free_left.assign([0, 0, 0, 1])
	await _open_shop()
	_eq(_shop()._tabs[L.Tab.FREE].badge, true, "D18 on with 1 left")
	_shop().select_tab(L.Tab.FREE)
	await _frames()
	_tap(_target_center("ad:3"))
	await _wait()
	_eq(_shop()._tabs[L.Tab.FREE].badge, false, "D18 off right after last ad")
	await _close_all_popups()
	_tap(BACK_BTN)
	await _frames()
	await _wait()
	await _close_all_popups()
	_eq(home._bottom_buttons[1].badge, false, "D17 off after return")
	S.free_left.assign([20, 5, 5, 1])
	home._refresh_badge()
	await _wait()
	_eq(home._bottom_buttons[1].badge, true, "D17 back on")


## App 回前景:商城重新取資料(紅點、錢包)
func _test_resume_refetch() -> void:
	print("-- resume")
	await _open_shop()
	S.free_left.assign([0, 0, 0, 0])
	ES.wallet.gold = 4321
	_shop().propagate_notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	await _wait()
	_eq(_shop()._tabs[L.Tab.FREE].badge, false, "resume -> D18 updated")
	_eq(home._resources.values[2], 4321, "resume -> resource bar updated")
	S.free_left.assign([20, 5, 5, 1])
	await _leave_shop()


## 銀塊 + 金塊剛好等於價格:開確認框;差 1:金塊不足。D24 文字
func _test_afford_boundary() -> void:
	print("-- afford boundary")
	ES.wallet.silver = 10
	ES.wallet.gold = 20
	await _open_shop()
	_shop().select_tab(L.Tab.ITEMS)
	await _frames()
	_tap(_target_center("item:0:1"))
	await _frames()
	_eq(_dialog().mode, _dialog().Mode.CONFIRM, "exactly 30 -> confirm")
	_eq(_dialog()._split(), [10, 20], "split 10 + 20")
	_tap(_dialog()._primary.get_global_rect().get_center())
	await _wait()
	_eq([ES.wallet.silver, ES.wallet.gold], [0, 0], "paid all")
	await _close_all_popups()
	ES.wallet.gold = 29
	_shop()._fetch()
	await _wait()
	_tap(_target_center("item:0:1"))
	await _frames()
	_eq(_dialog().mode, _dialog().Mode.SHORT, "29 -> short")
	_eq(_dialog()._price - _dialog()._wallet.silver - _dialog()._wallet.gold, 1, "還差 1")
	_dialog().close()
	ES.wallet.gold = 1000
	await _leave_shop()


## 對話框開著時:分頁籤、資源列、返回鈕都被遮罩擋住
func _test_mask_blocks_tabs_and_bar() -> void:
	print("-- mask blocks")
	await _open_shop()
	_shop().select_tab(L.Tab.ITEMS)
	await _frames()
	_tap(_target_center("item:2:1"))
	await _frames()
	_tap(TAB_CENTERS[0])
	await _frames()
	_tap(GOLD_ICON)
	await _frames()
	_tap(BACK_BTN)
	await _frames()
	_eq([home._shop != null, _shop().tab, _dialog().is_open()], [true, L.Tab.ITEMS, true], "dialog masks tabs/bar/back")
	await _back_key()
	_eq([_dialog().is_open(), home._shop != null], [false, true], "back key closes D23 only")
	await _leave_shop()


## 拖動剛好 8px 仍算點擊;9px 不算(D07「超過 8px」)
func _test_drag_slop() -> void:
	print("-- drag slop")
	await _open_shop()
	_shop().select_tab(L.Tab.HEART_COIN)
	await _frames()
	var p := _target_center("coin:1000")
	_move(p, false)
	_button(p, true)
	_move(p + Vector2(0, 8))
	_button(p + Vector2(0, 8), false)
	await _frames()
	_eq(_dialog().is_open(), true, "8px move still a tap")
	_dialog().close()
	await _frames()
	_move(p, false)
	_button(p, true)
	_move(p + Vector2(0, -9))
	_button(p + Vector2(0, -9), false)
	await _frames()
	_eq(_dialog().is_open(), false, "9px move is a drag")
	await _leave_shop()


## 廣告載入中按返回鍵 / 左上返回鈕:商城不關(B1 修法,比照 D20);結果回來照常跳「已獲得」,之後可離開
func _test_back_during_ad() -> void:
	print("-- back during ad")
	ES.wallet.coin = 0
	await _open_shop()
	S.delay_sec = 0.3
	_shop().select_tab(L.Tab.FREE)
	await _frames()
	var shop = _shop()
	_tap(_target_center("ad:1"))
	await _frames()
	await _back_key()
	_eq(_kept(shop), true, "back key during ad loading keeps shop open")
	_tap(BACK_BTN)
	await _frames()
	_eq(_kept(shop), true, "back button during ad loading keeps shop open")
	await _wait(0.5)
	var coin_popup := false
	for i in 5:
		if _popup().is_open() and _popup().current().get("rewards", []).size() > 0 \
				and _popup().current().rewards[0][0] == "coin":
			coin_popup = true
		if _popup().is_open():
			await _back_key()
	print("   free_left[1] = %d, wallet.coin = %d, popup shown = %s" % [S.free_left[1], ES.wallet.coin, coin_popup])
	_eq(S.free_left[1] == 4 and ES.wallet.coin > 0, true, "reward granted on server")
	_eq(coin_popup, true, "player is told about the reward (已獲得)")
	_eq(_kept(shop), true, "shop still open after ad result popup closed")
	_tap(BACK_BTN)
	await _frames()
	_eq(home._shop, null, "back button leaves shop after ad result")
	S.delay_sec = DELAY
	await _leave_shop()


## Google Play 付款中、驗證中(D20)按返回鍵 / 左上返回鈕:商城不關(B2 修法);訂單不卡在 _paid,直接入帳
func _test_back_during_iap() -> void:
	print("-- back during iap")
	var gold0: int = ES.wallet.gold
	await _open_shop()
	S.delay_sec = 0.3
	var shop = _shop()
	_tap(_target_center("gold:90"))
	await _frames()
	await _back_key()
	_eq(_kept(shop), true, "back key during payment keeps shop open")
	_tap(BACK_BTN)
	await _frames()
	_eq(_kept(shop), true, "back button during payment keeps shop open")
	# 付款結果 0.3s 回來 → D20 處理中,驗證再 0.3s
	await _wait(0.4)
	_eq(_dialog().mode, ShopDialog.Mode.PROCESSING, "D20 processing during verify")
	await _back_key()
	_tap(BACK_BTN)
	await _frames()
	_eq([_kept(shop), _dialog().mode], [true, ShopDialog.Mode.PROCESSING], "back ignored during verify")
	await _wait(0.4)
	_eq(_popup().is_open(), true, "purchase popup after verify")
	await _close_all_popups()
	S.delay_sec = DELAY
	print("   paid-not-verified = %d, pending = %d, gold delta = %d" % [S._paid.size(), S.pending_orders.size(), ES.wallet.gold - gold0])
	_eq([S._paid.size(), S.pending_orders.size()], [0, 0], "order not stuck in _paid / pending")
	_eq(ES.wallet.gold - gold0, 90, "paid order granted without simulate_grant_pending")
	_eq(_kept(shop), true, "shop still open after purchase popup closed")
	await _back_key()
	_eq(home._shop, null, "back key leaves shop after payment result")
	await _leave_shop()
