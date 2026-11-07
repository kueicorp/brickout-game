extends SceneTree
## QA(2026-11-07):頁面捷徑列邊界情況(page-shortcuts P03~P06、README 活動第 7 點)。
## 連點捷徑、提示框開著時點捷徑 / 返回鈕、處理中跳出補發框、B / C 切商城再回來、商城其他分頁切活動、
## 商城處理中返回鍵、同一幀內「開始處理」與「點捷徑」的競態、切頁後晚到的紅點回應。執行:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path game --script res://tests/test_qa_shortcut_edges.gd
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
const GROWTH := 2
const SETTINGS := 3
const CHECKIN_BTN := Vector2(298, 158)
const BUY_BTN := Vector2(180, 504)

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
	if home:
		home.queue_free()
		await _frames()
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


func _pages() -> int:
	return home.get_children().filter(func(n) -> bool: return n is EventScreen or n is ShopScreen).size()


func _to_home() -> void:
	await _wait(SLOW + 0.1)
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
	await _test_rapid_taps()
	await _test_popup_open()
	await _test_busy_with_popup()
	await _test_sub_page_round_trip()
	await _test_shop_tab_to_event()
	await _test_shop_busy_back_key()
	await _test_late_badge_after_switch()
	await _test_a11y()
	await _test_same_frame_race()
	if home:
		home.queue_free()
		await _frames()
	_reset()
	print("PASSED %d, FAILED %d" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


## 連點:同一幀內點兩次「商城」、點「商城」後同一幀再點同位置(新頁的「商城」= 目前頁)、來回快速切
func _test_rapid_taps() -> void:
	print("-- rapid taps")
	await _open(EVENT)
	_tap(_key(SHOP))
	_tap(Vector2(169, 102))
	await _frames()
	_eq([_pages(), home._shop != null, home._event], [1, true, null], "double tap 商城 same frame: one shop")
	await _wait()
	# 同一幀:商城頁點「活動」再點「商城」(位置不變)
	_tap(_key(EVENT))
	_tap(Vector2(169, 102))
	await _frames()
	_eq(_pages(), 1, "活動 then 商城 same frame: one page")
	await _wait()
	# 每幀切一次,10 次
	for i in 10:
		_tap(Vector2(95, 102) if i % 2 == 0 else Vector2(169, 102))
		await _frames(1)
	await _wait()
	_eq(_pages(), 1, "10 switches one per frame: one page")
	_eq(home._map.visible or home._bottom_buttons[0].visible, false, "home nodes stay hidden")
	# 連點成長 / 設定
	var cur = home._event if home._event else home._shop
	for i in 5:
		_tap(_key(GROWTH))
		_tap(_key(SETTINGS))
	await _frames()
	_eq([_pages(), is_instance_valid(cur), (home._event if home._event else home._shop) == cur], [1, true, true], "spam 成長 / 設定: nothing")
	await _to_home()
	_eq([_pages(), home._map.visible], [0, true], "back home after rapid")


## 提示框開著:點捷徑、點返回鈕都被遮住;返回鍵先關框
func _test_popup_open() -> void:
	print("-- popup open")
	for which in [EVENT, SHOP]:
		await _open(which)
		var cur = home._event if which == EVENT else home._shop
		var k := _key(SHOP if which == EVENT else EVENT)
		var b := _back_btn()
		home._popup.enqueue(EventLogic.popup_checkin(ES.shared_wallet().duplicate()))
		await _frames()
		_tap(k)
		await _frames()
		_tap(b)
		await _frames()
		_tap(_key(GROWTH))
		await _frames()
		_eq([_pages(), is_instance_valid(cur), (home._event if which == EVENT else home._shop) == cur, home._popup.is_open()], [1, true, true, true],
			"%d: popup blocks shortcut + back button" % which)
		await _back_key()
		_eq([home._popup.is_open(), (home._event if which == EVENT else home._shop) == cur], [false, true], "%d: back key closes popup only" % which)
		await _to_home()
	# 商城自己的購買確認框開著(尚未送出):捷徑、返回鈕被框遮住;返回鍵先關框
	await _open(SHOP)
	var shop = home._shop
	shop._start_gold_buy("item:0:1")
	await _frames()
	_eq(shop._dialog.is_open(), true, "confirm dialog open")
	_tap(_key(EVENT))
	await _frames()
	_tap(_back_btn())
	await _frames()
	_eq([is_instance_valid(shop), home._shop == shop, home._event, shop._dialog.is_open()], [true, true, null, true], "confirm dialog blocks shortcut + back button")
	await _back_key()
	_eq([home._shop == shop, shop._dialog.is_open()], [true, false], "back key closes confirm dialog only")
	await _to_home()


## 處理中剛好跳出補發框:返回鍵先關框,關完仍在處理中則返回鍵無效;結果回來後才能離開
func _test_busy_with_popup() -> void:
	print("-- busy + popup")
	await _open(EVENT)
	var ev = home._event
	ev.show_page(EventLogic.Page.CHECKIN)
	await _frames()
	ES.delay_sec = SLOW
	_tap(CHECKIN_BTN)
	await _frames()
	ES.delay_sec = DELAY
	_eq(ev.is_busy(), true, "event busy")
	home._popup.enqueue(EventLogic.popup_topup("order", ES.shared_wallet().duplicate()))
	await _frames()
	await _back_key()
	_eq([home._popup.is_open(), is_instance_valid(ev) and home._event == ev, ev.page], [false, true, EventLogic.Page.CHECKIN], "busy+popup: back key closes popup only")
	await _back_key()
	_eq([home._event == ev, ev.page, _bar().back.disabled], [true, EventLogic.Page.CHECKIN, true], "busy after popup closed: back key ignored, still disabled")
	await _wait(SLOW)
	_eq([ev.is_busy(), _bar().back.disabled, home._popup.is_open()], [false, false, true], "result: enabled, 已獲得 popup")
	await _close_popups()
	await _to_home()
	# 商城看廣告中 + 補發框
	await _open(SHOP)
	var shop = home._shop
	S.delay_sec = SLOW
	shop._watch_ad(0)
	await _frames()
	S.delay_sec = DELAY
	home._popup.enqueue(EventLogic.popup_topup("order", ES.shared_wallet().duplicate()))
	await _frames()
	await _back_key()
	_eq([home._popup.is_open(), home._shop == shop], [false, true], "ad busy+popup: back key closes popup only")
	await _back_key()
	_eq([home._shop == shop, _bar().back.disabled], [true, true], "ad busy: back key ignored")
	await _wait(SLOW)
	_eq([shop._ad_busy, _bar().back.disabled, home._popup.is_open()], [-1, false, true], "ad result: enabled, popup")
	await _to_home()


## 活動 B / C → 商城 → 活動:回到 A、已重新載入;返回回首頁
func _test_sub_page_round_trip() -> void:
	print("-- B/C -> shop -> event")
	for p in [EventLogic.Page.CHECKIN, EventLogic.Page.TOPUP]:
		await _open(EVENT)
		home._event.show_page(p)
		await _frames()
		_tap(_key(SHOP))
		await _frames()
		await _wait()
		_eq([home._shop != null, home._shop.tab], [true, L.Tab.TOPUP], "%d -> shop at 儲值" % p)
		_tap(_key(EVENT))
		await _frames()
		_eq([home._event != null, home._event.page, home._event.load_state], [true, EventLogic.Page.LIST, EventScreen.Load.LOADING], "%d -> shop -> event: A, reloading" % p)
		await _wait()
		_eq(home._event.load_state, EventScreen.Load.LOADED, "%d: event loaded" % p)
		_tap(_back_btn())
		await _frames()
		_eq([_pages(), home._map.visible], [0, true], "%d: back -> home" % p)
		await _wait()


## 商城其他分頁(道具 / 愛心金幣 / 免費、捲到一半)→ 活動 → 商城:回儲值、捲動歸零
func _test_shop_tab_to_event() -> void:
	print("-- shop tab -> event")
	for t in [L.Tab.ITEMS, L.Tab.HEART_COIN, L.Tab.FREE]:
		await _open(SHOP)
		home._shop.select_tab(t)
		home._shop._page.scroll = 80
		await _frames()
		_tap(_key(EVENT))
		await _frames()
		_eq([home._shop, home._event != null, home._event.page], [null, true, EventLogic.Page.LIST], "tab %d -> event A" % t)
		await _wait()
		_tap(_key(SHOP))
		await _frames()
		await _wait()
		_eq([home._shop.tab, home._shop._page.scroll], [L.Tab.TOPUP, 0], "tab %d -> event -> shop: 儲值, top" % t)
		await _to_home()


## 商城處理中返回鍵無效(看廣告、Google Play、金塊購買送出);結果回來後返回鍵回首頁
func _test_shop_busy_back_key() -> void:
	print("-- shop busy back key")
	await _open(SHOP)
	var shop = home._shop
	S.delay_sec = SLOW
	shop._watch_ad(0)
	await _frames()
	await _back_key()
	_eq(home._shop == shop, true, "ad busy: back key ignored")
	await _wait(SLOW + 0.1)
	await _close_popups()
	shop._start_iap("gold:%d" % L.GOLD_PACKS[0][0])
	await _frames()
	await _back_key()
	_eq([home._shop == shop, _bar().back.disabled], [true, true], "iap busy: back key ignored")
	await _wait(SLOW * 2 + 0.2)
	await _close_popups()
	shop._start_gold_buy("item:0:1")
	shop._on_confirmed("item:0:1")
	await _frames()
	await _back_key()
	_eq([home._shop == shop, shop._dialog.is_open(), _bar().back.disabled], [true, true, true], "gold busy: back key ignored")
	S.delay_sec = DELAY
	await _wait(SLOW + 0.1)
	await _close_popups()
	_eq(_bar().back.disabled, false, "shop idle again")
	await _back_key()
	_eq(home._shop, null, "shop idle: back key -> home")
	await _wait()


## 活動頁發出的商城紅點請求晚到時已切到商城:不影響商城頁(商城捷徑不亮)、首頁底部紅點不被改
func _test_late_badge_after_switch() -> void:
	print("-- late badge after switch")
	_reset()
	S.delay_sec = SLOW
	_tap(home._bottom_buttons[EVENT].get_global_rect().get_center())
	await _frames()
	_tap(_key(SHOP))
	await _frames()
	S.delay_sec = DELAY
	await _wait(SLOW + 0.1)
	await _close_popups()
	_eq(home._shop != null, true, "on shop")
	_eq(_bar().keys.map(func(k) -> bool: return k.badge), [true, false, false, false], "late shop badge: only 活動 lit on shop page")
	_eq(home._bottom_buttons[SHOP].badge, false, "bottom shop badge untouched while on page")
	await _to_home()
	await _wait()
	_eq([home._bottom_buttons[EVENT].badge, home._bottom_buttons[SHOP].badge], [true, true], "home badges after return (unsigned, free left)")


## P09:可朗讀標籤(返回、頁名、目前頁面、有新項目)
func _test_a11y() -> void:
	print("-- a11y")
	_reset()
	await _open(EVENT)
	var bar := _bar()
	_eq(bar.back.accessibility_name, "返回", "a11y back")
	_eq(bar.keys.map(func(k) -> String: return k.accessibility_name), ["活動", "商城", "成長", "設定"], "a11y names")
	_eq(bar.keys.map(func(k) -> String: return k.accessibility_description), ["目前頁面", "有新項目", "", ""], "a11y event page: current + badge")
	S.free_left.assign([0, 0, 0, 0])
	home.propagate_notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	await _wait()
	_eq(bar.keys[SHOP].accessibility_description, "", "a11y badge off -> label cleared")
	await _to_home()
	_reset()


## 同一幀內先按「開始處理」的按鈕、再點捷徑 / 返回鈕:捷徑應已停用(P04「處理中停用」),不可離開。
## 停用是每幀 _process 同步,同一幀內的第二下可能漏擋;漏擋的後果是結果回呼找不到節點(已獲得框不出現)
func _test_same_frame_race() -> void:
	print("-- same frame race")
	await _open(EVENT)
	var ev = home._event
	ev.show_page(EventLogic.Page.CHECKIN)
	await _frames()
	ES.delay_sec = SLOW
	var coin_before: int = ES.wallet.coin
	_tap(CHECKIN_BTN)
	_tap(_key(SHOP))
	await _frames()
	ES.delay_sec = DELAY
	_eq([is_instance_valid(ev), home._event == ev, home._shop], [true, true, null], "race event: checkin + 商城 same frame -> stays on event")
	await _wait(SLOW + 0.1)
	_eq([ES.wallet.coin > coin_before, home._popup.is_open()], [true, true], "race event: server granted -> 已獲得 popup shown")
	await _to_home()
	# 商城:看廣告 + 活動捷徑同一幀(直接呼叫 _on_tapped 代替點廣告鈕)
	await _open(SHOP)
	var shop = home._shop
	S.delay_sec = SLOW
	shop._on_tapped("ad", "0")
	_tap(_key(EVENT))
	await _frames()
	S.delay_sec = DELAY
	_eq([is_instance_valid(shop), home._shop == shop, home._event], [true, true, null], "race shop: ad + 活動 same frame -> stays on shop")
	await _wait(SLOW + 0.1)
	_eq(home._popup.is_open(), true, "race shop: 已獲得 popup shown")
	await _to_home()
