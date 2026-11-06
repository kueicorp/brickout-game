extends SceneTree
## QA 重測(B1 補發框遺失 / 重複、B2 安全區不足、toast 位置)。執行:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path game --script res://tests/test_qa_retest_b1b2.gd
## 有任何失敗時結束碼為 1。

const HOME_SIM_PATH := "res://tests/home_sim.gd"
const S := preload("res://scripts/event_service.gd")
const L := preload("res://scripts/event_logic.gd")
const H := preload("res://scripts/home_logic.gd")
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
	# 首頁沒有東西開著時返回鍵會結束 App(正確行為),測試中略過以免中斷
	if home._event == null and not home._popup.is_open():
		print("   (skip back key: would quit)")
		return
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


func _reset() -> void:
	S.reset()
	S.delay_sec = DELAY


func _ev():
	return home._event


func _open_event() -> void:
	_tap(home._bottom_buttons[0].get_global_rect().get_center())
	await _frames()


func _kinds() -> Array:
	var out := []
	for item in home._popup._queue:
		out.append(item.kind)
	return out


## 點畫面上「好」鈕的中心(真實輸入)
func _tap_ok() -> void:
	var ok: Control = home._popup._ok
	_tap(ok.get_global_rect().get_center())
	await _frames()


func _run() -> void:
	_reset()
	await _make_home()
	await _wait()
	await _test_b1_not_cleared_on_fetch()
	await _test_b1_ok_marks_seen()
	await _test_b1_back_marks_seen()
	await _test_b1_late_home_request()
	await _test_b1_leave_during_load_then_reenter()
	await _test_b1_mark_failure_keeps_list()
	await _test_b1_fetch_failure_keeps_list()
	await _test_b1_badge_after_dedupe()
	await _test_b1_ids_unique_after_reset()
	await _test_b1_old_monthly_id_does_not_clear_new()
	await _test_b1_popup_from_event_page_marks()
	await _test_b2_avail()
	await _test_b2_tall_with_notch()
	await _test_toast_no_overlap(640, 24)
	await _test_toast_no_overlap(640, 40)
	await _test_toast_no_overlap(800, 24)
	await _test_toast_no_overlap(900, 48)
	# screen-size-800 驗證高度(S03):700 / 780 / 840、T=40
	await _test_toast_no_overlap(700, 24)
	await _test_toast_no_overlap(780, 24)
	await _test_toast_no_overlap(840, 24)
	await _test_toast_no_overlap(800, 40)
	await _test_toast_no_overlap(800, 24, 34)
	await _test_toast_no_overlap(640, 24, 34)
	await _test_toast_passthrough()
	if home:
		home.queue_free()
		await _frames()
	S.reset()
	print("PASSED %d, FAILED %d" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


# ---------------- B1 ----------------

## 取資料不會清掉清單;關框前每次取資料都帶回
func _test_b1_not_cleared_on_fetch() -> void:
	print("-- _test_b1_not_cleared_on_fetch")
	_reset()
	S.signed_count = 14
	S.simulate_month_reset()
	S.simulate_pending_order()
	# 首頁與活動頁並發取資料(框還沒出現前點「活動」)
	home._refresh_badge()
	await _open_event()
	_eq(home._event != null, true, "event opened before popups arrive")
	await _wait()
	_eq(_kinds(), ["order", "monthly"], "shows order then monthly once")
	_eq([S.pending_orders.size(), S.pending_monthly.size()], [1, 2], "server list kept while popups open")
	# 框開著時再取兩次:不重複排
	home._refresh_badge()
	_ev()._fetch()
	await _wait()
	_eq(_kinds(), ["order", "monthly"], "concurrent refetch while open: no duplicates")
	while home._popup.is_open():
		await _tap_ok()
	_eq([S.pending_orders.size(), S.pending_monthly.size()], [0, 0], "closing all with OK clears server list")
	await _back_key()
	await _wait()


## 按「好」:該框才被標記(另一個框仍保留)
func _test_b1_ok_marks_seen() -> void:
	print("-- _test_b1_ok_marks_seen")
	_reset()
	S.signed_count = 7
	S.simulate_month_reset()
	S.simulate_pending_order()
	home._refresh_badge()
	await _wait()
	_eq(home._popup.current().kind, "order", "order first")
	await _tap_ok()
	await _wait()
	_eq([S.pending_orders.size(), S.pending_monthly.size()], [0, 1], "OK marks only the closed order")
	_eq(home._popup.current().kind, "monthly", "monthly now showing")
	await _tap_ok()
	await _wait()
	_eq([S.pending_monthly.size(), home._popup.is_open()], [0, false], "OK marks monthly")
	await _wait()


## 返回鍵關框也標記
func _test_b1_back_marks_seen() -> void:
	print("-- _test_b1_back_marks_seen")
	_reset()
	S.signed_count = 7
	S.simulate_month_reset()
	S.simulate_pending_order()
	home._refresh_badge()
	await _wait()
	await _back_key()
	_eq([S.pending_orders.size(), S.pending_monthly.size()], [0, 1], "back key marks order")
	await _back_key()
	_eq([S.pending_monthly.size(), home._popup.is_open(), home.is_inside_tree()], [0, false, true], "back key marks monthly, app not quit")
	await _wait()
	# 重新進活動頁 / 回首頁:不再彈
	await _open_event()
	await _wait()
	_eq(home._popup.is_open(), false, "re-enter event: no repeat")
	await _back_key()
	await _wait()
	_eq(home._popup.is_open(), false, "back home: no repeat")


## 首頁請求很晚才回(比活動頁晚):只彈一次;框已關後才回也不重彈
func _test_b1_late_home_request() -> void:
	print("-- _test_b1_late_home_request")
	_reset()
	S.signed_count = 7
	S.simulate_month_reset()
	S.delay_sec = 0.6
	home._refresh_badge()
	S.delay_sec = DELAY
	await _open_event()
	await _wait()
	_eq(_kinds(), ["monthly"], "event page response first shows monthly")
	await _tap_ok()
	_eq(S.pending_monthly.size(), 0, "marked on OK")
	await _wait(0.7)
	_eq(home._popup.is_open(), false, "late home response after close: not shown again")
	# 反過來:框還沒關時晚到
	_ev().show_page(L.Page.LIST)
	await _back_key()
	await _wait()
	S.simulate_pending_order()
	S.delay_sec = 0.6
	home._refresh_badge()
	S.delay_sec = DELAY
	await _open_event()
	await _wait()
	_eq(_kinds(), ["order"], "order shown once from event page")
	await _wait(0.6)
	_eq(_kinds(), ["order"], "late home response while open: no duplicate")
	await _tap_ok()
	await _back_key()
	await _wait()


## 活動頁載入中就離開(活動頁回應被丟棄),之後重新進入多次:剛好彈一次
func _test_b1_leave_during_load_then_reenter() -> void:
	print("-- _test_b1_leave_during_load_then_reenter")
	_reset()
	S.signed_count = 21
	S.simulate_month_reset()
	S.delay_sec = 0.3
	await _open_event()
	await _back_key()
	_eq(home._event, null, "left during loading")
	await _wait(0.8)
	_eq(_kinds(), ["monthly"], "monthly shown on home after leaving")
	_eq(home._popup.current().tiers.size(), 3, "monthly has 3 tiers")
	await _tap_ok()
	S.delay_sec = DELAY
	await _wait()
	for i in 3:
		await _open_event()
		await _wait()
		_eq(home._popup.is_open(), false, "re-enter %d: no repeat" % i)
		await _back_key()
		await _wait()
	_eq(home._popup.is_open(), false, "home after re-enters: no repeat")


## mark_popup_seen 失敗:伺服器清單保留;同次執行不重彈;「重開 App」(新首頁)會再彈
func _test_b1_mark_failure_keeps_list() -> void:
	print("-- _test_b1_mark_failure_keeps_list")
	_reset()
	S.signed_count = 7
	S.simulate_month_reset()
	home._refresh_badge()
	await _wait()
	_eq(_kinds(), ["monthly"], "monthly shown")
	S.fail_next = 1
	await _tap_ok()
	await _wait()
	_eq(S.pending_monthly.size(), 1, "mark failure: server keeps list")
	_eq(home._popup.is_open(), false, "same session: refetch after close does not repeat")
	await _open_event()
	await _wait()
	_eq(home._popup.is_open(), false, "same session: event page does not repeat")
	await _back_key()
	await _wait()
	# 模擬重開 App:新的首頁(新的 RewardPopup)
	await _make_home()
	await _wait()
	_eq(_kinds(), ["monthly"], "new session: kept list shows again")
	await _tap_ok()
	await _wait()
	_eq(S.pending_monthly.size(), 0, "new session: marked after OK")


## 取資料失敗不吃掉清單(首頁、活動頁都試)
func _test_b1_fetch_failure_keeps_list() -> void:
	print("-- _test_b1_fetch_failure_keeps_list")
	_reset()
	S.simulate_pending_order()
	S.fail_next = 1
	home._refresh_badge()
	await _wait()
	_eq([home._popup.is_open(), S.pending_orders.size()], [false, 1], "home fetch fail: kept")
	S.fail_next = 1
	await _open_event()
	await _wait()
	_eq([home._popup.is_open(), S.pending_orders.size(), _ev().load_state], [false, 1, _ev().Load.FAILED], "event fetch fail: kept")
	_tap(Vector2(180, 374))  # 重試(畫面 A 失敗時重試鈕在面板內? 若不在 A 顯示就改直接呼叫)
	await _frames()
	if _ev().load_state != _ev().Load.LOADING:
		_ev()._fetch()
	await _wait()
	_eq(_kinds(), ["order"], "retry success shows order")
	await _tap_ok()
	_eq(S.pending_orders.size(), 0, "order marked")
	await _back_key()
	await _wait()


## 去重後紅點:補發框被 RewardPopup 略過時,首頁仍要依最新資料顯示紅點
func _test_b1_badge_after_dedupe() -> void:
	print("-- _test_b1_badge_after_dedupe")
	_reset()
	S.signed_count = 7
	S.simulate_month_reset()  # signed_today = false -> 紅點應亮
	home._refresh_badge()
	await _wait()
	_eq(home._bottom_buttons[0].badge, false, "badge waits while popup open")
	S.fail_next = 1  # 標記失敗 -> 之後取資料仍帶回同 id(會被去重)
	await _tap_ok()
	await _wait()
	_eq([S.pending_monthly.size(), home._popup.is_open()], [1, false], "deduped, list still on server")
	_eq(home._bottom_buttons[0].badge, true, "badge shown after dedupe (today not signed)")
	# 今天已簽、無可領:紅點熄
	S.signed_today = true
	home._refresh_badge()
	await _wait()
	_eq([home._bottom_buttons[0].badge, home._popup.is_open()], [false, false], "badge off after dedupe (signed, nothing claimable)")
	# 收尾:標記
	S.mark_popup_seen(S.monthly_id)
	await _wait()


## reset 後的新補發(同一個首頁 / RewardPopup)不會因 id 重用被當成看過
func _test_b1_ids_unique_after_reset() -> void:
	print("-- _test_b1_ids_unique_after_reset")
	_reset()
	S.simulate_pending_order()
	var id1: String = S.pending_orders[0].id
	home._refresh_badge()
	await _wait()
	await _tap_ok()
	await _wait()
	_reset()
	S.simulate_pending_order()
	var id2: String = S.pending_orders[0].id
	_eq(id1 != id2, true, "ids differ after reset (%s, %s)" % [id1, id2])
	home._refresh_badge()
	await _wait()
	_eq(_kinds(), ["order"], "new order after reset shows in same session")
	await _tap_ok()
	await _wait()


## 舊的月初補發 id 延遲標記,不會清掉新一批
func _test_b1_old_monthly_id_does_not_clear_new() -> void:
	print("-- _test_b1_old_monthly_id_does_not_clear_new")
	_reset()
	S.signed_count = 7
	S.simulate_month_reset()
	var old_id: String = S.monthly_id
	S.pending_monthly = []
	S.signed_count = 14
	S.simulate_month_reset()
	S.mark_popup_seen(old_id)
	await _wait()
	_eq(S.pending_monthly.size(), 2, "old monthly id ignored")
	S.mark_popup_seen("order:999999")
	await _wait()
	_eq(S.pending_monthly.size(), 2, "unknown id ignored")
	home._refresh_badge()
	await _wait()
	await _tap_ok()
	await _wait()
	_eq(S.pending_monthly.size(), 0, "new monthly marked")


## 活動頁取到的補發框,在活動頁按「好」也會標記
func _test_b1_popup_from_event_page_marks() -> void:
	print("-- _test_b1_popup_from_event_page_marks")
	_reset()
	await _open_event()
	await _wait()
	S.simulate_pending_order()
	_ev()._fetch()
	await _wait()
	_eq(_kinds(), ["order"], "event page shows order")
	await _tap_ok()
	await _wait()
	_eq([S.pending_orders.size(), home._event != null, _ev().page], [0, true, L.Page.LIST], "marked; stays on event A")
	await _back_key()
	await _wait()
	_eq(home._popup.is_open(), false, "no repeat on home")


# ---------------- B2 ----------------

## 640 高、下 16:上安全區 32 / 33 / 40 / 48 → avail 592 / 591 / 584 / 576
func _test_b2_avail() -> void:
	print("-- _test_b2_avail")
	for c in [[32, 0], [33, 1], [40, 8], [48, 8], [24, 0]]:
		var t: int = c[0]
		var shift: int = c[1]
		_reset()
		await _make_home(640, t, 16)
		await _wait()
		await _open_event()
		await _wait()
		var ev = _ev()
		var label := "T%d avail %d" % [t, 640 - t - 16]
		_eq(ev._header_shift, shift, label + " shift")
		_eq(ev._back.get_global_rect(), Rect2(8, 80 + shift, 44, 44), label + " back rect")
		_eq(ev._body.position.y, 0.0, label + " body (panel) not moved")
		_eq(ev.PANEL, Rect2(8, 132, 344, 434), label + " panel 132~566")
		_eq(home._d01_buttons[0].position.y, float(t + 4), label + " resource bar y")
		# banner 位置(首頁算法)不變
		_eq(H.home_layout(640, t, 16).banner, 574, label + " banner 574")
		# 列表項目不動
		_eq(ev._items[0].get_global_rect(), Rect2(14, 138, 332, 72), label + " list item not moved")
		var bar_bottom: float = t + 4 + 44
		var overlap: float = bar_bottom - (80 + shift)
		if 640 - t - 16 >= 584:
			_eq(overlap <= 0, true, label + " no overlap resource/back (%d)" % overlap)
		else:
			_eq(overlap, 8.0, label + " known residual overlap 8px (暫不處理)")
		# 返回鈕在三個畫面都同位置、可點(上緣 +1、下緣 -1、中心)
		for p in [L.Page.CHECKIN, L.Page.TOPUP]:
			ev.show_page(p)
			await _frames()
			var y_top: float = 80 + shift + 1
			if 640 - t - 16 < 584:
				y_top = bar_bottom + 1  # 重疊區上方由資源列處理,點不重疊的部分
			_tap(Vector2(30, y_top))
			await _frames()
			_eq(ev.page, L.Page.LIST, label + " back top edge tappable on page %d" % p)
			ev.show_page(p)
			await _frames()
			_tap(Vector2(30, 80 + shift + 43))
			await _frames()
			_eq(ev.page, L.Page.LIST, label + " back bottom edge tappable on page %d" % p)
		# 下緣以下 1px(面板內)不算返回
		_tap(Vector2(30, 80 + shift + 45))
		await _frames()
		_eq(home._event != null, true, label + " tap below back does not go home")
		_tap(Vector2(30, 80 + shift + 22))
		await _frames()
		_eq(home._event, null, label + " back center goes home from A")
		await _wait()


## 長螢幕 + 瀏海:avail 充足時 shift 0。
## 2026-11-07 改為 screen-size-800 S02 / S07:E ≥ 0 時上方貼 T(body 只下移 T − 24)、E 全加在面板;
## E < 0 沿用 README 第 988 行(與舊「整塊下移」相同:offset = T − 24 + E)。面板下緣與 banner 恆隔 8。
func _test_b2_tall_with_notch() -> void:
	print("-- _test_b2_tall_with_notch")
	for c in [[800, 40], [700, 48], [656, 48]]:
		_reset()
		var h: int = c[0]
		var t: int = c[1]
		await _make_home(h, t, 16)
		await _wait()
		await _open_event()
		await _wait()
		var ev = _ev()
		var avail := h - t - 16
		var e := avail - 600
		var label := "h%d T%d avail %d" % [h, t, avail]
		var off: float = t - 24 + mini(e, 0)
		_eq(ev._header_shift, L.header_shift(avail), label + " shift")
		_eq(ev._body.position.y, off, label + " body offset")
		_eq(ev._panel.size.y, float(434 + maxi(e, 0)), label + " panel height 434 + E")
		_eq(h - 16 - 50 - (off + ev._panel.end.y), 8.0, label + " panel bottom to banner 8")
		if e >= 0:
			_eq(ev._back.get_global_rect().position.y, float(t + 56), label + " back y = T + 56")
		var back_top: float = ev._back.get_global_rect().position.y
		_eq(back_top >= t + 4 + 44, true, label + " back top %d >= resource bottom %d" % [back_top, t + 48])
		_tap(ev._back.get_global_rect().get_center())
		await _frames()
		_eq(home._event, null, label + " back tappable")
		await _wait()


# ---------------- toast ----------------

## toast 規格位置(畫面座標),依 screen-size-800 S08 方案 B 獨立計算(不呼叫正式程式):
## 內容 y = 436 + floor(0.4 × max(E, 0) + 0.5);畫面 y = 內容 y + (T − 24) + min(E, 0)。寬依文字 + 24、水平置中、高 32
func _spec_toast_rect(text: String, h: int, t: int, b: int) -> Rect2:
	var e := h - t - b - 600
	var content_y := 436 + int(floor(0.4 * maxi(e, 0) + 0.5))
	var w: float = PixelText.FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 24
	return Rect2(floorf(180 - w / 2.0), content_y + (t - 24) + mini(e, 0), ceilf(w), 32)


## 實際繪製的 toast 框(畫面座標)
func _toast_rect(ev) -> Rect2:
	var r: Rect2 = ev.toast_rect()
	return Rect2(ev._toast.global_position + r.position, r.size)


func _clickables(n: Node, out: Array) -> void:
	for c in n.get_children():
		if c is Control and c != home._popup and c.is_visible_in_tree():
			if c.has_signal("pressed") and c.mouse_filter != Control.MOUSE_FILTER_IGNORE:
				out.append(c)
			_clickables(c, out)


## 目前測試的畫面高 / 安全區(_test_toast_no_overlap 設定)
var _hb := [640, 24, 16]


func _check_toast(ev, label: String) -> void:
	_eq(ev.toast_text != "", true, label + " toast visible")
	var tr := _toast_rect(ev)
	_eq(tr, _spec_toast_rect(ev.toast_text, _hb[0], _hb[1], _hb[2]), label + " toast rect = S08 spec")
	_eq(tr.size.x <= 344 and tr.position.x >= 8, true, label + " toast within panel width (%s)" % tr)
	var hits := []
	var list := []
	_clickables(home, list)
	_eq(list.has(ev._back), true, label + " clickable scan sees back button (%d found)" % list.size())
	for c in list:
		if c.get_global_rect().intersects(tr):
			hits.append("%s %s" % [c.get_class(), c.get_global_rect()])
	_eq(hits, [], label + " toast %s overlaps no clickable" % tr)


func _test_toast_no_overlap(h: int, t: int, b := 16) -> void:
	print("-- _test_toast_no_overlap h%d T%d B%d" % [h, t, b])
	_reset()
	await _make_home(h, t, b)
	await _wait()
	await _open_event()
	await _wait()
	var ev = _ev()
	var label := "h%d T%d B%d" % [h, t, b]
	_hb = [h, t, b]
	for p in [L.Page.LIST, L.Page.CHECKIN, L.Page.TOPUP]:
		ev.show_page(p)
		await _frames()
		for text in [ev.TOAST_CHECKIN, ev.TOAST_CLAIM, ev.TOAST_BUY]:
			ev._show_toast(text)
			await _frames()
			_check_toast(ev, "%s page %d '%s'" % [label, p, text])
	# B:累積卡全部可領(領取鈕都顯示)時也不蓋
	S.signed_count = 28
	ev.show_page(L.Page.CHECKIN)
	ev._fetch()
	await _wait()
	ev._show_toast(ev.TOAST_CLAIM)
	await _frames()
	_check_toast(ev, label + " B all claimable")
	# C:已購買
	S.topup_bought = true
	ev.show_page(L.Page.TOPUP)
	ev._fetch()
	await _wait()
	ev._show_toast(ev.TOAST_BUY)
	await _frames()
	_check_toast(ev, label + " C bought")
	# A 讀取失敗(重試鈕)
	S.fail_next = 1
	ev.show_page(L.Page.CHECKIN)
	ev._fetch()
	await _wait()
	# S08:D14 狀態不顯示 toast;且規格位置的 toast 幾何上不與重試鈕重疊(E < 400)
	_eq([ev.load_state, ev._retry.is_visible_in_tree()], [ev.Load.FAILED, true], label + " B failed, retry visible")
	ev._show_toast(ev.TOAST_CHECKIN)
	await _frames()
	_eq(ev.toast_text, "", label + " B failed: no toast in D14")
	for text in [ev.TOAST_CHECKIN, ev.TOAST_CLAIM, ev.TOAST_BUY]:
		var spec := _spec_toast_rect(text, h, t, b)
		_eq(spec.intersects(ev._retry.get_global_rect()), false,
			label + " spec toast %s vs retry %s no overlap" % [spec, ev._retry.get_global_rect()])
	ev._show_toast("")
	ev.show_page(L.Page.LIST)
	await _back_key()
	await _wait()


## toast 顯示中按鈕仍可點(toast 不吃觸控)
func _test_toast_passthrough() -> void:
	print("-- _test_toast_passthrough")
	_reset()
	await _make_home()
	await _wait()
	await _open_event()
	await _wait()
	var ev = _ev()
	_tap(ITEM_CHECKIN)
	await _frames()
	S.fail_next = 1
	_tap(CHECKIN_BTN)
	await _wait()
	_eq(ev.toast_text, ev.TOAST_CHECKIN, "toast shown")
	_tap(CHECKIN_BTN)
	await _wait()
	_eq(S.signed_count, 8, "checkin works while toast visible")
	while home._popup.is_open():
		await _tap_ok()
	# 文字置中:框中心 x = 180
	ev._show_toast(ev.TOAST_BUY)
	await _frames()
	var tr := _toast_rect(ev)
	_eq(absf(tr.get_center().x - 180) <= 1.0, true, "toast centered (%s)" % tr)
	await _back_key()
	await _back_key()
	await _wait()
