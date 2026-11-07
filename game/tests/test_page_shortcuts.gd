extends SceneTree
## 頁面捷徑列測試(docs/design/layout/page-shortcuts.md P01~P09):從首頁進活動頁 / 商城,用 push_input 模擬點擊,驗證
## 位置尺寸(640 / 800 / T=40)、目前頁金框、切頁取代與返回回首頁、B / C 點活動回 A、成長 / 設定沒反應、
## 停用時機(簽到、領取、首儲購買、看廣告、Google Play、金塊購買;含同一幀內先處理再點)、提示框遮住、紅點條件、焦點順序。執行:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path game --script res://tests/test_page_shortcuts.gd
## 有任何失敗時結束碼為 1。

const HOME_SIM_PATH := "res://tests/home_sim.gd"
const S := preload("res://scripts/shop_service.gd")
const ES := preload("res://scripts/event_service.gd")
const L := preload("res://scripts/shop_logic.gd")
const DELAY := 0.05
const WAIT := 0.15
const EVENT := 0
const SHOP := 1
const GROWTH := 2
const SETTINGS := 3

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


func _make_home(h := 640, t := 24, b := 16) -> void:
	if home:
		home.queue_free()
		await _frames()
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(360, h)
	await _frames()
	var node: Control = load("res://scenes/home.tscn").instantiate()
	node.set_script(load(HOME_SIM_PATH))
	node.sim_view = Vector2(360, h)
	node.sim_safe = Vector2i(t, b)
	root.add_child(node)
	home = node
	await _frames(3)
	await _wait()


func _reset_service() -> void:
	ES.reset()
	ES.delay_sec = DELAY
	S.reset()
	S.delay_sec = DELAY
	FakeData.ads_removed = false


## 目前開著的頁(活動頁或商城)的捷徑列
func _bar() -> PageShortcutBar:
	return home._event.shortcuts if home._event else home._shop.shortcuts


func _key_center(i: int) -> Vector2:
	return _bar().keys[i].get_global_rect().get_center()


func _tap_key(i: int) -> void:
	_tap(_key_center(i))
	await _frames()


func _tap_back() -> void:
	_tap(_bar().back.get_global_rect().get_center())
	await _frames()


func _back_key() -> void:
	home.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await _frames()


## 點首頁底部列第 i 格(0 活動、1 商城)
func _bottom(i: int) -> Vector2:
	return home._bottom_buttons[i].get_global_rect().get_center()


func _open(i: int) -> void:
	_tap(_bottom(i))
	await _frames()
	await _wait()


func _close_popups() -> void:
	while home._popup.is_open():
		await _back_key()


## 回到首頁(關提示框、關頁)
func _to_home() -> void:
	await _close_popups()
	if home._event:
		home._event.show_page(EventLogic.Page.LIST)
	while home._event or home._shop:
		await _back_key()
	await _wait()


func _run() -> void:
	_reset_service()
	for c in [[640, 24, 16], [800, 24, 16], [640, 40, 16], [800, 40, 16]]:
		await _make_home(c[0], c[1], c[2])
		await _test_layout(c[0], c[1], c[2])
	await _make_home()
	await _test_look()
	await _test_switch()
	await _test_event_sub_pages()
	await _test_current_and_unopened()
	await _test_popup_blocks()
	await _test_disabled_event()
	await _test_disabled_shop()
	await _test_same_frame()
	await _test_badges()
	if home:
		home.queue_free()
		await _frames()
	_reset_service()
	print("PASSED %d, FAILED %d" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


## P01、P08:活動頁與商城的返回鈕、4 個捷徑位置尺寸;與資源列、面板間距;右緣不超過 352
func _test_layout(h: int, t: int, b: int) -> void:
	var tag := "%d T%d" % [h, t]
	var lay := EventLogic.event_layout(h, t, b)
	var y: float = 80 + lay.offset + lay.header_shift
	for pos in [EVENT, SHOP]:
		await _open(pos)
		var screen = home._event if home._event else home._shop
		var name := "event" if home._event else "shop"
		var bar := _bar()
		_eq(bar.back.get_global_rect(), Rect2(8, y, 44, 44), "%s %s back rect" % [tag, name])
		for i in 4:
			_eq(bar.keys[i].get_global_rect(), Rect2(60 + 74 * i, y, 70, 44), "%s %s key %d rect" % [tag, name, i])
		_eq(bar.keys[3].get_global_rect().end.x, 352.0, tag + " right edge 352")
		var res_bottom: float = home._resources.position.y + 72
		var panel_top: float = screen._body.global_position.y + screen._panel.position.y
		# E ≥ 0:上下都間隔 8;E < 0(640、T=40):沿用返回鈕規則最多下移 8,上下都貼齊(間隔 0)但不重疊
		var short := h - t - b < 600
		_eq(y - res_bottom, 0.0 if short else 8.0, "%s %s gap resource -> keys" % [tag, name])
		_eq(panel_top - (y + 44), 0.0 if short else 8.0, "%s %s gap keys -> panel" % [tag, name])
		# 目前頁標題已拿掉、捷徑列取代:返回鈕就是捷徑列的返回鈕
		_eq(screen._back == bar.back, true, "%s %s back is bar back" % [tag, name])
		await _to_home()


## P02、P07、P09:目前頁金框、文字、焦點順序、返回鈕底板
func _test_look() -> void:
	await _open(EVENT)
	var bar := _bar()
	_eq(bar.keys.map(func(k) -> bool: return k.selected), [true, false, false, false], "event: 活動 selected")
	_eq(bar.keys.map(func(k) -> String: return k.label), ["活動", "商城", "成長", "設定"], "labels")
	_eq([bar.back.icon != null, bar.back.selected, bar.back.label], [true, false, ""], "back: icon on plate, no frame")
	_eq(bar.back.find_next_valid_focus(), bar.keys[0], "focus back -> 活動")
	for i in 3:
		_eq(bar.keys[i].find_next_valid_focus(), bar.keys[i + 1], "focus key %d -> %d" % [i, i + 1])
	# 觸控取得的焦點是隱藏焦點,不畫白框;鍵盤取得才畫
	_tap(_key_center(GROWTH))
	await _frames()
	_eq(bar.keys[GROWTH].has_focus(true), false, "tap focus hidden")
	bar.keys[GROWTH].grab_focus()
	_eq(bar.keys[GROWTH].has_focus(true), true, "keyboard focus visible")
	bar.keys[GROWTH].release_focus()
	await _to_home()
	await _open(SHOP)
	_eq(_bar().keys.map(func(k) -> bool: return k.selected), [false, true, false, false], "shop: 商城 selected")
	await _to_home()


## P04:切頁取代、返回 / 返回鍵回首頁、新頁重新載入(商城回儲值)
func _test_switch() -> void:
	await _open(EVENT)
	await _tap_key(SHOP)
	_eq([home._event == null, home._shop != null], [true, true], "event -> shop replaces")
	_eq([home._shop.tab, home._shop.load_state], [L.Tab.TOPUP, ShopScreen.Load.LOADING], "shop reloads at 儲值")
	_eq(home._map.visible or home._bottom_buttons[0].visible, false, "home nodes stay hidden")
	await _wait()
	home._shop.select_tab(L.Tab.FREE)
	await _tap_back()
	_eq([home._event, home._shop, home._map.visible], [null, null, true], "back after switch -> home")
	await _wait()

	await _open(SHOP)
	await _tap_key(EVENT)
	_eq([home._shop == null, home._event != null], [true, true], "shop -> event replaces")
	_eq([home._event.page, home._event.load_state], [EventLogic.Page.LIST, EventScreen.Load.LOADING], "event reloads at A")
	await _wait()
	await _back_key()
	_eq([home._event, home._shop, home._map.visible], [null, null, true], "android back after switch -> home")
	await _wait()

	# 來回切多次,節點不會疊起來
	await _open(EVENT)
	for i in 3:
		await _tap_key(SHOP)
		await _tap_key(EVENT)
	await _wait()
	var count: int = home.get_children().filter(func(n) -> bool: return n is EventScreen or n is ShopScreen).size()
	_eq(count, 1, "only one page node after switching")
	await _to_home()


## P03、P04:B、C 點「活動」回 A;B、C 點「商城」直接到商城,之後再進活動是 A;B、C 返回仍回 A
func _test_event_sub_pages() -> void:
	for p in [EventLogic.Page.CHECKIN, EventLogic.Page.TOPUP]:
		await _open(EVENT)
		var ev = home._event
		ev.show_page(p)
		await _tap_key(EVENT)
		_eq([home._event == ev, ev.page, ev.load_state], [true, EventLogic.Page.LIST, EventScreen.Load.LOADED], "%d: 活動 -> A (no reload)" % p)
		ev.show_page(p)
		await _tap_back()
		_eq([home._event == ev, ev.page], [true, EventLogic.Page.LIST], "%d: back -> A" % p)
		ev.show_page(p)
		await _tap_key(SHOP)
		_eq([home._event, home._shop != null], [null, true], "%d: 商城 -> shop" % p)
		await _wait()
		await _tap_key(EVENT)
		_eq(home._event.page, EventLogic.Page.LIST, "%d: re-enter event at A" % p)
		await _to_home()


## P03、P05:目前頁捷徑沒反應(A 列表、商城不切分頁 / 不重載 / 不捲動);成長、設定沒反應
func _test_current_and_unopened() -> void:
	await _open(EVENT)
	var ev = home._event
	await _tap_key(EVENT)
	_eq([home._event == ev, ev.page, ev.load_state], [true, EventLogic.Page.LIST, EventScreen.Load.LOADED], "A: 活動 no-op")
	for i in [GROWTH, SETTINGS]:
		await _tap_key(i)
		_eq([home._event == ev, home._shop, ev.page], [true, null, EventLogic.Page.LIST], "event: key %d no-op" % i)
	await _to_home()

	await _open(SHOP)
	var shop = home._shop
	shop.select_tab(L.Tab.ITEMS)
	shop._page.scroll = 100
	await _tap_key(SHOP)
	_eq([home._shop == shop, shop.tab, shop._page.scroll, shop.load_state], [true, L.Tab.ITEMS, 100, ShopScreen.Load.LOADED], "shop: 商城 no-op")
	for i in [GROWTH, SETTINGS]:
		await _tap_key(i)
		_eq([home._shop == shop, home._event], [true, null], "shop: key %d no-op" % i)
	await _to_home()


## P04:提示框開著時捷徑被遮住;返回鍵先關提示框
func _test_popup_blocks() -> void:
	await _open(EVENT)
	var ev = home._event
	home._popup.enqueue(EventLogic.popup_checkin(ES.shared_wallet().duplicate()))
	await _frames()
	await _tap_key(SHOP)
	_eq([home._event == ev, home._shop], [true, null], "popup blocks shortcut")
	await _back_key()
	_eq([home._popup.is_open(), home._event == ev], [false, true], "back key closes popup first")
	await _to_home()


func _disabled(bar: PageShortcutBar) -> Array:
	var out := [bar.back.disabled, bar.back.modulate.a]
	for k in bar.keys:
		out.append_array([k.disabled, k.modulate.a])
	return out


func _all(on: bool) -> Array:
	var out := []
	for i in 5:
		out.append_array([on, 0.5 if on else 1.0])
	return out


## P04:活動頁簽到、領取、首儲購買處理中 → 返回鈕與捷徑停用,結束後恢復
func _test_disabled_event() -> void:
	await _open(EVENT)
	var ev = home._event
	var bar := _bar()
	_eq(_disabled(bar), _all(false), "event idle: enabled")
	var starts := [
		["checkin", func() -> void: ev._on_checkin_pressed()],
		["claim", func() -> void: ev._on_claim_pressed(7)],
		["topup", func() -> void: ev._on_buy_pressed()],
	]
	for s in starts:
		ev.show_page(EventLogic.Page.CHECKIN if s[0] != "topup" else EventLogic.Page.TOPUP)
		s[1].call()
		await _frames()
		_eq(_disabled(bar), _all(true), s[0] + " busy: disabled")
		await _tap_key(SHOP)
		await _tap_back()
		_eq([home._event == ev, home._shop], [true, null], s[0] + " busy: taps ignored")
		await _wait()
		await _frames()
		_eq(_disabled(bar), _all(false), s[0] + " done: enabled")
		await _close_popups()
	await _to_home()


## P04:同一幀內先開始處理、再點捷徑 / 返回鈕(停用外觀要到下一幀才同步)→ 仍不離開,結果回來照常跳「已獲得」
func _test_same_frame() -> void:
	# 前面的測試已簽到過,重設才會成功發獎
	_reset_service()
	await _open(EVENT)
	var ev = home._event
	ev.show_page(EventLogic.Page.CHECKIN)
	await _frames()
	ev._on_checkin_pressed()
	_tap(_key_center(SHOP))
	_tap(_bar().back.get_global_rect().get_center())
	await _frames()
	var stayed: bool = is_instance_valid(ev) and home._event == ev and ev.page == EventLogic.Page.CHECKIN
	_eq([stayed, home._shop], [true, null], "event same frame: checkin + 商城 / back ignored")
	await _wait()
	_eq(home._popup.is_open(), true, "event same frame: 已獲得 popup")
	await _to_home()

	await _open(SHOP)
	var shop = home._shop
	shop._watch_ad(0)
	_tap(_key_center(EVENT))
	_tap(_bar().back.get_global_rect().get_center())
	await _frames()
	_eq([is_instance_valid(shop) and home._shop == shop, home._event], [true, null], "shop same frame: ad + 活動 / back ignored")
	await _wait()
	_eq(home._popup.is_open(), true, "shop same frame: 已獲得 popup")
	await _to_home()


## P04:商城看廣告、Google Play 付款 / 驗證、金塊購買處理中 → 停用;結果回來(成功、失敗、取消)就恢復
func _test_disabled_shop() -> void:
	await _open(SHOP)
	var shop = home._shop
	var bar := _bar()
	_eq(_disabled(bar), _all(false), "shop idle: enabled")
	# 看廣告:成功 / 失敗
	for fail in [false, true]:
		S.fail_next = 1 if fail else 0
		shop._watch_ad(0)
		await _frames()
		_eq(_disabled(bar), _all(true), "ad loading (fail=%s): disabled" % fail)
		await _tap_key(EVENT)
		_eq([home._shop == shop, home._event], [true, null], "ad loading: 活動 ignored")
		await _wait()
		await _frames()
		_eq(_disabled(bar), _all(false), "ad result (fail=%s): enabled" % fail)
		await _close_popups()
	# Google Play:付款 → 驗證中(處理中框)→ 成功;取消
	var id := "gold:%d" % L.GOLD_PACKS[0][0]
	for result in ["paid", "canceled"]:
		S.play_result = result
		shop._start_iap(id)
		await _frames()
		_eq(_disabled(bar), _all(true), "iap %s: disabled while paying" % result)
		await _wait(DELAY + 0.02)
		await _frames()
		if result == "paid":
			_eq([shop._iap_busy, _disabled(bar)], [true, _all(true)], "iap verifying: still disabled")
			await _wait()
			await _frames()
		_eq(_disabled(bar), _all(false), "iap %s done: enabled" % result)
		await _close_popups()
	# 金塊購買送出後
	shop._start_gold_buy("item:0:1")
	shop._on_confirmed("item:0:1")
	await _frames()
	_eq(_disabled(bar), _all(true), "gold buy busy: disabled")
	await _wait()
	await _frames()
	_eq(_disabled(bar), _all(false), "gold buy done: enabled")
	await _close_popups()
	await _to_home()


## P06:只在其他頁捷徑亮;條件同首頁 D16 / D17;資料到達前、失敗不顯示;回前景重取
func _test_badges() -> void:
	_reset_service()
	# 活動頁:商城捷徑跟 D17(免費次數)
	_tap(_bottom(EVENT))
	await _frames()
	_eq(_bar().keys[SHOP].badge, false, "event: shop badge hidden before data")
	await _wait()
	var bar := _bar()
	_eq(bar.keys.map(func(k) -> bool: return k.badge), [false, true, false, false], "event: only 商城 badge (free left)")
	bar.set_badge(EVENT, true)
	bar.set_badge(GROWTH, true)
	_eq([bar.keys[EVENT].badge, bar.keys[GROWTH].badge], [false, false], "current page / growth never badge")
	S.free_left.assign([0, 0, 0, 0])
	home.propagate_notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	_eq(bar.keys[SHOP].badge, false, "resume: cleared while refetching")
	await _wait()
	_eq(bar.keys[SHOP].badge, false, "event: shop badge off when all used")
	await _to_home()
	S.free_left.assign([0, 0, 0, 1])
	S.fail_next = 1
	await _open(EVENT)
	_eq(_bar().keys[SHOP].badge, false, "event: shop badge off on fetch failure")
	await _to_home()
	S.offline = true
	await _open(EVENT)
	_eq(_bar().keys[SHOP].badge, false, "event: shop badge off when offline")
	S.offline = false
	await _to_home()

	# 商城:活動捷徑跟 D16(今天未簽 / 有可領累積獎勵)
	_tap(_bottom(SHOP))
	await _frames()
	_eq(_bar().keys[EVENT].badge, false, "shop: event badge hidden before data")
	await _wait()
	bar = _bar()
	_eq(bar.keys.map(func(k) -> bool: return k.badge), [true, false, false, false], "shop: only 活動 badge (not signed)")
	ES.signed_today = true
	ES.claimed.assign([7])
	home.propagate_notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	await _wait()
	_eq(bar.keys[EVENT].badge, false, "shop: event badge off (signed, nothing claimable)")
	await _to_home()
	ES.fail_next = 1
	await _open(SHOP)
	_eq(_bar().keys[EVENT].badge, false, "shop: event badge off on fetch failure")
	await _to_home()
	# 切頁時紅點跟著新頁重新取
	_reset_service()
	await _open(EVENT)
	await _tap_key(SHOP)
	await _wait()
	_eq(_bar().keys.map(func(k) -> bool: return k.badge), [true, false, false, false], "switch -> shop: 活動 badge fetched")
	await _to_home()
