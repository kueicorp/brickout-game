extends SceneTree
## QA 補充測試(活動頁邊界情況):重複點擊、載入中操作、返回鍵時機、提示框順序與只彈一次、
## 紅點各情境、首頁版面不被破壞、觸控尺寸對照設計稿、安全區較大時的重疊。執行:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path game --script res://tests/test_qa_event_edges.gd
## 有任何失敗時結束碼為 1。

const HOME_SIM_PATH := "res://tests/home_sim.gd"
const S := preload("res://scripts/event_service.gd")
const L := preload("res://scripts/event_logic.gd")
const DELAY := 0.05
const WAIT := 0.15

const EVENT_BTN := Vector2(49, 528)
const BACK_BTN := Vector2(30, 102)
const ITEM_CHECKIN := Vector2(180, 174)
const ITEM_TOPUP := Vector2(180, 254)
const CHECKIN_BTN := Vector2(298, 158)
const CLAIM_Y := 540
const BUY_BTN := Vector2(180, 504)

var _passed := 0
var _failed := 0
var home
var _heart_presses := 0


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


func _back_key() -> void:
	home.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await _frames()


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
	_heart_presses = 0
	home._heart.pressed.connect(func() -> void: _heart_presses += 1)


func _reset() -> void:
	S.reset()
	S.delay_sec = DELAY


func _ev():
	return home._event


func _open_event() -> void:
	_tap(EVENT_BTN)
	await _frames()


func _kinds(popup) -> Array:
	var out := []
	for item in popup._queue:
		out.append(item.kind)
	return out


func _close_all_popups() -> void:
	while home._popup.is_open():
		home._popup.close_current()
	await _frames()


func _run() -> void:
	_reset()
	await _make_home()
	await _wait()
	await _test_double_tap_checkin()
	await _test_double_tap_buy()
	await _test_tap_during_loading()
	await _test_back_during_loading()
	await _test_popup_once_concurrent()
	await _test_popup_failed_fetch_keeps_pending()
	await _test_popup_order_with_action_showing()
	await _test_home_popup_back_key()
	await _test_mask_blocks_resource_bar()
	await _test_badges()
	await _test_badge_not_eating_touch()
	await _test_checkin_27_to_28()
	await _test_failure_hides_bought()
	await _test_home_layout_unchanged(640)
	await _test_home_layout_unchanged(800)
	await _test_touch_sizes_exact()
	await _test_large_safe_top_overlap()
	if home:
		home.queue_free()
		await _frames()
	S.reset()
	print("PASSED %d, FAILED %d" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


## 同一畫面快速連點兩次「今日簽到」:只送一次請求、只彈一個框
func _test_double_tap_checkin() -> void:
	print("-- _test_double_tap_checkin")
	_reset()
	await _open_event()
	await _wait()
	_tap(ITEM_CHECKIN)
	await _frames()
	_tap(CHECKIN_BTN)
	_tap(CHECKIN_BTN)
	await _frames()
	_tap(CHECKIN_BTN)
	await _wait()
	_eq(S.signed_count, 8, "double tap checkin: only +1")
	_eq(_kinds(home._popup), ["action"], "double tap checkin: one popup")
	await _close_all_popups()


## 快速連點兩次購買:只買一次、只彈一個框(限購 1 次)
func _test_double_tap_buy() -> void:
	print("-- _test_double_tap_buy")
	var ev = _ev()
	ev.show_page(L.Page.TOPUP)
	await _frames()
	var gold0: int = S.wallet.gold
	_tap(BUY_BTN)
	_tap(BUY_BTN)
	await _frames()
	_tap(BUY_BTN)
	await _wait()
	_eq(S.wallet.gold, gold0 + 300, "double tap buy: granted once")
	_eq(_kinds(home._popup), ["action"], "double tap buy: one popup")
	await _close_all_popups()
	ev.show_page(L.Page.LIST)
	await _back_key()
	_eq(home._event, null, "back to home")
	await _wait()


## D14:B 載入中,簽到鈕、領取鈕不可點(點了不送請求)
func _test_tap_during_loading() -> void:
	print("-- _test_tap_during_loading")
	_reset()
	S.delay_sec = 0.5
	await _open_event()
	_tap(ITEM_CHECKIN)
	await _frames()
	_eq(_ev().load_state, _ev().Load.LOADING, "B still loading")
	_tap(CHECKIN_BTN)
	_tap(Vector2(54, CLAIM_Y))
	await _wait(0.7)
	_eq([S.signed_count, S.claimed], [7, []], "taps during loading send nothing")
	_eq(home._popup.is_open(), false, "no popup from taps during loading")
	S.delay_sec = DELAY
	await _back_key()
	await _back_key()
	await _wait()


## 載入中按返回:B → A,資料到了停在 A、紅點出現;A 載入中按返回回首頁不當機、不彈框
func _test_back_during_loading() -> void:
	print("-- _test_back_during_loading")
	_reset()
	S.delay_sec = 0.3
	await _open_event()
	_tap(ITEM_CHECKIN)
	await _frames()
	await _back_key()
	_eq(_ev().page, L.Page.LIST, "back during B loading -> A")
	await _wait(0.4)
	_eq([_ev().page, _ev()._items[0].badge], [L.Page.LIST, true], "data arrives while on A")
	# 首頁:月初補發待彈,活動頁載入中就離開
	S.simulate_month_reset()
	_ev()._fetch()
	await _back_key()
	_eq(home._event, null, "back during A loading -> home")
	await _wait(0.8)
	# 活動頁的回應已丟棄;首頁重新取資料時拿到補發框(只回傳一次,不能被吃掉)
	_eq(_kinds(home._popup), ["monthly"], "monthly popup not lost when leaving during load")
	S.delay_sec = DELAY
	await _close_all_popups()
	await _wait()


## 首頁與活動頁幾乎同時取資料:補發框只出現一次
func _test_popup_once_concurrent() -> void:
	print("-- _test_popup_once_concurrent")
	_reset()
	S.signed_count = 10
	S.simulate_month_reset()
	S.simulate_pending_order()
	home._refresh_badge()
	await _open_event()
	await _wait()
	_eq(_kinds(home._popup), ["order", "monthly"], "concurrent fetch: each popup once, order first")
	await _close_all_popups()
	_ev()._fetch()
	await _wait()
	_eq(home._popup.is_open(), false, "no repeat after refetch")
	await _back_key()
	await _wait()
	_eq(home._popup.is_open(), false, "no repeat on home")


## 取資料失敗時補發清單不被消耗,下次成功才彈
func _test_popup_failed_fetch_keeps_pending() -> void:
	print("-- _test_popup_failed_fetch_keeps_pending")
	_reset()
	S.signed_count = 7
	S.simulate_month_reset()
	S.fail_next = 1
	home._refresh_badge()
	await _wait()
	_eq(home._popup.is_open(), false, "failed fetch: no popup")
	_eq(home._bottom_buttons[0].badge, false, "failed fetch: badge hidden")
	home._refresh_badge()
	await _wait()
	_eq(_kinds(home._popup), ["monthly"], "next successful fetch shows monthly")
	await _close_all_popups()
	await _wait()


## 玩家操作的框正在顯示時,載入帶回補發:不插隊換掉目前的框,接在後面且訂單在月初之前
func _test_popup_order_with_action_showing() -> void:
	print("-- _test_popup_order_with_action_showing")
	_reset()
	await _open_event()
	await _wait()
	_tap(ITEM_CHECKIN)
	await _frames()
	_tap(CHECKIN_BTN)
	await _wait()
	_eq(_kinds(home._popup), ["action"], "checkin popup showing")
	S.signed_count = 20
	S.simulate_month_reset()
	S.simulate_pending_order()
	_ev()._fetch()
	await _wait()
	_eq(_kinds(home._popup), ["action", "order", "monthly"], "D17 order kept; current not replaced")
	await _back_key()
	_eq([home._popup.current().kind, _ev().page], ["order", L.Page.CHECKIN], "back closes one popup at a time")
	await _close_all_popups()
	await _back_key()
	await _back_key()
	await _wait()


## 首頁有提示框時按返回鍵:只關框,不結束 App、不開關活動頁
func _test_home_popup_back_key() -> void:
	print("-- _test_home_popup_back_key")
	_reset()
	S.signed_count = 7
	S.simulate_month_reset()
	home._refresh_badge()
	await _wait()
	_eq(home._popup.is_open(), true, "monthly popup on home")
	await _back_key()
	_eq([home._popup.is_open(), home._event, home.is_inside_tree()], [false, null, true], "back on home closes popup only")
	await _wait()


## 提示框遮罩擋住資源列(愛心 icon 去商城)
func _test_mask_blocks_resource_bar() -> void:
	print("-- _test_mask_blocks_resource_bar")
	home._popup.enqueue(L.popup_checkin(S.wallet.duplicate()))
	await _frames()
	var n0 := _heart_presses
	_tap(Vector2(30, 50))
	await _frames()
	_eq(_heart_presses, n0, "popup mask blocks heart button")
	await _close_all_popups()
	_tap(Vector2(30, 50))
	await _frames()
	_eq(_heart_presses, n0 + 1, "heart works after popup closed")


func _set_and_refetch(c: int, s: bool, claimed: Array) -> void:
	S.signed_count = c
	S.signed_today = s
	S.claimed.assign(claimed)
	_ev()._fetch()
	_eq(_ev()._items[0].badge, false, "A badge hidden while refetching c%d s%s" % [c, s])
	await _wait()


## D05 / D16 紅點各情境
func _test_badges() -> void:
	print("-- _test_badges")
	_reset()
	await _open_event()
	await _wait()
	var item = _ev()._items[0]
	await _set_and_refetch(0, false, [])
	_eq(item.badge, true, "D05 c0 not signed -> on")
	await _set_and_refetch(6, true, [])
	_eq(item.badge, false, "D05 c6 signed, nothing reached -> off")
	await _set_and_refetch(14, true, [7])
	_eq(item.badge, true, "D05 signed, tier 14 claimable -> on")
	await _set_and_refetch(28, true, [7, 14, 21, 28])
	_eq(item.badge, false, "D05 all claimed signed -> off")
	_eq(_ev()._items[1].badge, false, "topup never badge")
	# 簽到 / 領取後的列表紅點與首頁紅點
	await _set_and_refetch(6, false, [])
	_tap(ITEM_CHECKIN)
	await _frames()
	_tap(CHECKIN_BTN)
	await _wait()
	await _close_all_popups()
	_eq(item.badge, true, "after checkin to 7: tier 7 claimable -> still on")
	_tap(Vector2(54, CLAIM_Y))
	await _wait()
	await _close_all_popups()
	_eq(item.badge, false, "after claim 7 -> off")
	await _back_key()
	await _back_key()
	_eq(home._bottom_buttons[0].badge, false, "home badge hidden until refetch")
	await _wait()
	_eq(home._bottom_buttons[0].badge, false, "D16 home badge off after returning")
	# 回首頁時讀取失敗:不沿用舊值
	S.signed_today = false
	home._refresh_badge()
	await _wait()
	_eq(home._bottom_buttons[0].badge, true, "D16 home on: not signed")
	S.fail_next = 1
	home._refresh_badge()
	await _wait()
	_eq(home._bottom_buttons[0].badge, false, "D16 fetch failure -> off (no stale value)")
	# App 回前景
	home.propagate_notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	await _wait()
	_eq(home._bottom_buttons[0].badge, true, "D16 resume refetches")


## 紅點不吃觸控:點紅點位置仍觸發整列 / 整格
func _test_badge_not_eating_touch() -> void:
	print("-- _test_badge_not_eating_touch")
	_tap(Vector2(75, 498))
	await _frames()
	_eq(home._event != null, true, "tap on home badge opens event")
	await _wait()
	_tap(Vector2(72, 148))
	await _frames()
	_eq(_ev().page, L.Page.CHECKIN, "tap on A badge opens B")
	await _back_key()
	await _back_key()
	await _wait()


## 第 27 次 → 簽到成為第 28 次:28 格全已簽、無金框(A14);摘要 28 / 28;7~28 可領
func _test_checkin_27_to_28() -> void:
	print("-- _test_checkin_27_to_28")
	_reset()
	S.signed_count = 27
	await _open_event()
	await _wait()
	_tap(ITEM_CHECKIN)
	await _frames()
	_tap(CHECKIN_BTN)
	await _wait()
	await _close_all_popups()
	var cp = _ev()._checkin
	var cells := []
	for n in range(1, 29):
		cells.append(L.cell_state(n, cp.signed_count, cp.signed_today))
	_eq(cells.count(L.Cell.SIGNED), 28, "c28 today: all signed, no gold frame")
	_eq(L.summary_text(cp.signed_count), "本月已簽 28 / 28 次", "summary 28/28")
	_eq(cp._claims[28].text, "領取", "card 28 claimable")
	_eq([cp._checkin.text, cp._checkin.disabled], ["今日已簽", true], "button signed")
	# 領 28:框內有道具名、在 10 種內
	_tap(Vector2(14 + 3 * 84 + 40, CLAIM_Y))
	await _wait()
	var p = home._popup.current()
	_eq(p.rewards, [["silver", 5]], "tier 28 popup rewards")
	var line: String = p.lines[0] if p.lines.size() > 0 else ""
	var named := false
	for it in L.SHOP_ITEMS:
		if line == "隨機道具:%s ×1" % it:
			named = true
	_eq(named, true, "tier 28 popup shows a shop item name (%s)" % line)
	await _close_all_popups()
	await _back_key()
	await _back_key()
	await _wait()


## D14:A 讀取失敗 → 首儲維持未購買樣式(就算伺服器其實已購買)
func _test_failure_hides_bought() -> void:
	print("-- _test_failure_hides_bought")
	_reset()
	S.topup_bought = true
	S.fail_next = 1
	await _open_event()
	await _wait()
	_eq([_ev()._items[1].subtitle, _ev()._items[1].dimmed], ["限購 1 次", false], "failure: topup unbought style")
	# 進入活動頁每次都重新載入(D01)
	await _back_key()
	await _wait()
	await _open_event()
	_eq(_ev().load_state, _ev().Load.LOADING, "re-enter: reloads")
	await _wait()
	_eq([_ev()._items[1].subtitle, _ev()._items[1].dimmed], ["已購買", true], "re-enter: bought shown")
	await _back_key()
	await _wait()


func _snapshot() -> Dictionary:
	var out := {}
	for c in home.get_children():
		if c is Control:
			out[c.get_index()] = [c.get_class(), c.position, c.size, c.visible]
	return out


## 首頁既有版面:開關活動頁後所有首頁元件位置 / 大小 / 可見性不變
func _test_home_layout_unchanged(h: int) -> void:
	print("-- _test_home_layout_unchanged")
	_reset()
	await _make_home(h)
	await _wait()
	var before := _snapshot()
	_tap(Vector2(49, h - 16 - 132 + 36))
	await _frames()
	await _wait()
	_tap(ITEM_TOPUP + Vector2(0, _ev()._body.position.y))
	await _frames()
	_eq(_ev().page, L.Page.TOPUP, "h%d tap topup row" % h)
	await _back_key()
	await _back_key()
	await _wait()
	_eq(_snapshot(), before, "h%d home layout unchanged after event" % h)


## 設計稿指定的觸控尺寸
func _test_touch_sizes_exact() -> void:
	print("-- _test_touch_sizes_exact")
	_reset()
	await _make_home()
	await _open_event()
	await _wait()
	var ev = _ev()
	_eq([ev._back.position, ev._back.size], [Vector2(8, 80), Vector2(44, 44)], "D04 back 44x44")
	_eq([ev._items[0].position, ev._items[0].size], [Vector2(14, 138), Vector2(332, 72)], "D05 item 1")
	_eq([ev._items[1].position, ev._items[1].size], [Vector2(14, 218), Vector2(332, 72)], "D05 item 2")
	_eq(ev._checkin._checkin.get_rect(), Rect2(250, 136, 96, 44), "D07 checkin button")
	for i in 4:
		var b = ev._checkin._claims[L.TIERS[i]]
		_eq(b.get_rect(), Rect2(14 + i * 84 + 4, 518, 72, 44), "D10 claim button %d" % L.TIERS[i])
	_eq(ev._topup._buy.get_rect(), Rect2(72, 476, 216, 56), "D11 buy button")
	_eq(ev._retry.size, Vector2(120, 44), "D14 retry 120x44")
	home._popup.enqueue(L.popup_checkin({"heart": 1, "coin": 1, "gold": 1, "silver": 1}))
	await _frames()
	_eq([home._popup._ok.position, home._popup._ok.size], [Vector2(72, 236 + 168 - 60), Vector2(216, 44)], "D17 ok button")
	await _close_all_popups()
	await _back_key()
	await _wait()


## 640 高、上安全區 40(瀏海):資源列(D03)不能和返回鈕 / 標題(D04)重疊
func _test_large_safe_top_overlap() -> void:
	print("-- _test_large_safe_top_overlap")
	_reset()
	await _make_home(640, 40, 16)
	await _wait()
	await _open_event()
	await _wait()
	var bar_bottom: float = home._d01_buttons[0].position.y + 44
	var back_top: float = _ev()._back.global_position.y - home.global_position.y
	_eq(bar_bottom <= back_top, true, "h640 T40: resource bar bottom %d <= back top %d" % [bar_bottom, back_top])
	await _back_key()
	await _wait()
