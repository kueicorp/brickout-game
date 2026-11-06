extends SceneTree
## EventLogic 純規則與假活動服務測試。執行:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path game --script res://tests/test_event_logic.gd
## 有任何失敗時結束碼為 1。

const L := preload("res://scripts/event_logic.gd")
const S := preload("res://scripts/event_service.gd")

var _passed := 0
var _failed := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_cells()
	_test_summary()
	_test_cards_and_badge()
	_test_back()
	_test_header_shift()
	_test_event_layout()
	_test_popup_order()
	_test_popup_height()
	_test_items()
	_test_month_reset()
	await _test_service_requests()
	print("PASSED %d, FAILED %d" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _eq(actual, expected, label: String) -> void:
	if actual == expected:
		_passed += 1
	else:
		_failed += 1
		printerr("FAIL %s: expected %s, got %s" % [label, str(expected), str(actual)])


## 方案 B:avail ≥ 592 不動;584~591 下移 592 − avail;< 584 最多 8
func _test_header_shift() -> void:
	_eq(L.header_shift(600), 0, "shift avail 600")
	_eq(L.header_shift(592), 0, "shift avail 592")
	_eq(L.header_shift(591), 1, "shift avail 591")
	_eq(L.header_shift(584), 8, "shift avail 584")
	_eq(L.header_shift(560), 8, "shift avail 560 capped")


## screen-size-800 S02 外框 / B 四段 / C 5 等分;期望值抄自規格關鍵座標表
func _test_event_layout() -> void:
	# [h, T, B, offset, extra, header_shift, banner]
	for c in [
		[640, 24, 16, 0, 0, 0, 574], [700, 24, 16, 0, 60, 0, 634], [780, 24, 16, 0, 140, 0, 714],
		[800, 24, 16, 0, 160, 0, 734], [840, 24, 16, 0, 200, 0, 774],
		# 瀏海 T=40:上方元件 +16,E 變 144;手勢列 B=34:E 變 142
		[800, 40, 16, 16, 144, 0, 734], [800, 24, 34, 0, 142, 0, 716],
		# E < 0:沿用 README 活動頁第 9 點(面板 434 貼 banner、返回鈕下移),E = 0 時兩種排法相同
		[640, 40, 16, 0, 0, 8, 574], [640, 24, 34, -18, 0, 8, 556], [656, 48, 16, 16, 0, 0, 590],
	]:
		var lay := L.event_layout(c[0], c[1], c[2])
		var tag := "H%d T%d B%d" % [c[0], c[1], c[2]]
		_eq([lay.offset, lay.extra, lay.header_shift, lay.banner], c.slice(3), tag + " event layout")
		# 面板下緣與 banner 恆間隔 8
		_eq(lay.banner - (lay.offset + 132 + 434 + lay.extra), 8, tag + " panel to banner 8")
	_eq(L.checkin_gaps(0), [0, 0, 0, 0] as Array[int], "B gaps E0")
	_eq(L.checkin_gaps(60), [9, 18, 18, 15] as Array[int], "B gaps E60")
	_eq(L.checkin_gaps(140), [21, 42, 42, 35] as Array[int], "B gaps E140")
	_eq(L.checkin_gaps(142), [21, 43, 43, 35] as Array[int], "B gaps E142")
	_eq(L.checkin_gaps(144), [22, 43, 43, 36] as Array[int], "B gaps E144")
	_eq(L.checkin_gaps(160), [24, 48, 48, 40] as Array[int], "B gaps E160")
	_eq(L.checkin_gaps(180), [27, 54, 54, 45] as Array[int], "B gaps E180")
	_eq(L.checkin_gaps(200), [30, 60, 60, 50] as Array[int], "B gaps E200")
	# .5 進位:E=10 → 1.5 → 2、3 → 3
	_eq(L.checkin_gaps(10), [2, 3, 3, 2] as Array[int], "B gaps E10 half up")
	_eq(L.topup_cuts(0), [0, 0, 0, 0] as Array[int], "C cuts E0")
	_eq(L.topup_cuts(140), [28, 56, 84, 112] as Array[int], "C cuts E140")
	_eq(L.topup_cuts(144), [29, 58, 86, 115] as Array[int], "C cuts E144")
	_eq(L.topup_cuts(160), [32, 64, 96, 128] as Array[int], "C cuts E160")
	_eq(L.topup_cuts(200), [40, 80, 120, 160] as Array[int], "C cuts E200")
	_eq(L.topup_cuts(12), [2, 5, 7, 10] as Array[int], "C cuts E12 (2.4/4.8/7.2/9.6)")
	_eq(L.topup_cuts(7), [1, 3, 4, 6] as Array[int], "C cuts E7 (1.4/2.8/4.2/5.6)")
	# S08:toast 436 + round(0.4E)、D14 下移 round(E ÷ 2);E = 0 / 140 / 142 / 144 / 160 / 200
	for c in [[0, 436, 0], [140, 492, 70], [142, 493, 71], [144, 494, 72], [160, 500, 80], [200, 516, 100], [3, 437, 2]]:
		_eq([L.toast_y(c[0]), L.state_shift(c[0])], [c[1], c[2]], "S08 toast y / D14 shift E%d" % c[0])
	_eq(L.state_shift(1), 1, "D14 shift E1 half up")


## 1~28 格的狀態列表
func _cells(c: int, s: bool) -> Array:
	var out := []
	for n in range(1, 29):
		out.append(L.cell_state(n, c, s))
	return out


func _test_cells() -> void:
	var SG := L.Cell.SIGNED
	var NX := L.Cell.NEXT
	var TD := L.Cell.TODAY
	var EM := L.Cell.EMPTY
	# 預覽:已簽 7 次、今天未簽 → 1~7 已簽、8 下一格、9~28 未簽
	var c7 := _cells(7, false)
	_eq(c7.slice(0, 7), [SG, SG, SG, SG, SG, SG, SG], "c7 1~7 signed")
	_eq(c7[7], NX, "c7 cell 8 next")
	_eq(c7.slice(8).count(EM), 20, "c7 9~28 empty")
	# 今天剛簽第 8 次 → 第 8 格今天已簽
	var c8 := _cells(8, true)
	_eq(c8[6], SG, "c8s cell 7 signed")
	_eq(c8[7], TD, "c8s cell 8 today")
	_eq(c8[8], EM, "c8s cell 9 empty")
	_eq(_cells(0, false)[0], NX, "c0 cell 1 next")
	_eq(_cells(1, true)[0], TD, "c1s cell 1 today")
	_eq(_cells(27, false)[27], NX, "c27 cell 28 next")
	_eq(_cells(27, true)[26], TD, "c27s cell 27 today")
	_eq(_cells(27, true)[27], EM, "c27s cell 28 empty")
	# ≥ 28(含剛簽第 28 次的當天):全是已簽、沒有金框
	for c in [28, 29, 30, 45]:
		for s in [false, true]:
			_eq(_cells(c, s).count(SG), 28, "c%d s%s all signed" % [c, s])
	# 全畫面最多一格金框
	for c in range(0, 40):
		for s in [false, true]:
			if c == 0 and s:
				continue
			var cells := _cells(c, s)
			_eq(cells.count(NX) + cells.count(TD) <= 1, true, "c%d s%s at most one gold frame" % [c, s])


func _test_summary() -> void:
	_eq(L.summary_text(0), "本月已簽 0 / 28 次", "summary 0")
	_eq(L.summary_text(7), "本月已簽 7 / 28 次", "summary 7")
	_eq(L.summary_text(28), "本月已簽 28 / 28 次", "summary 28 keeps denominator")
	_eq(L.summary_text(29), "本月已簽 29 次", "summary 29 no denominator")
	_eq(L.summary_text(30), "本月已簽 30 次", "summary 30")


func _test_cards_and_badge() -> void:
	_eq(L.card_state(7, 6, []), L.Card.LOCKED, "card 7 at 6 locked")
	_eq(L.card_state(7, 7, []), L.Card.CLAIMABLE, "card 7 at 7 claimable")
	_eq(L.card_state(7, 7, [7]), L.Card.CLAIMED, "card 7 claimed")
	_eq(L.card_state(28, 40, []), L.Card.CLAIMABLE, "card 28 at 40 claimable")
	_eq(L.card_state(28, 27, []), L.Card.LOCKED, "card 28 at 27 locked")
	_eq(L.checkin_badge(0, false, []), true, "badge: not signed today")
	_eq(L.checkin_badge(6, true, []), false, "badge: signed, nothing reached")
	_eq(L.checkin_badge(7, true, []), true, "badge: signed, tier 7 claimable")
	_eq(L.checkin_badge(7, true, [7]), false, "badge: signed, tier 7 claimed")
	_eq(L.checkin_badge(30, true, [7, 14, 21]), true, "badge: tier 28 claimable")
	_eq(L.checkin_badge(30, true, [7, 14, 21, 28]), false, "badge: all claimed")
	_eq(L.checkin_badge(30, false, [7, 14, 21, 28]), true, "badge: all claimed but not signed today")


func _test_back() -> void:
	_eq(L.back_action(true, L.Page.CHECKIN), L.Back.CLOSE_POPUP, "back popup on B -> close popup")
	_eq(L.back_action(true, L.Page.LIST), L.Back.CLOSE_POPUP, "back popup on A -> close popup")
	_eq(L.back_action(true, L.Page.NONE), L.Back.CLOSE_POPUP, "back popup on home -> close popup")
	_eq(L.back_action(false, L.Page.CHECKIN), L.Back.TO_LIST, "back B -> A")
	_eq(L.back_action(false, L.Page.TOPUP), L.Back.TO_LIST, "back C -> A")
	_eq(L.back_action(false, L.Page.LIST), L.Back.TO_HOME, "back A -> home")
	_eq(L.back_action(false, L.Page.NONE), L.Back.QUIT, "back home -> quit (original behavior)")


func _q(kinds: Array) -> Array:
	var out := []
	for k in kinds:
		out.append({"kind": k})
	return out


func _test_popup_order() -> void:
	_eq(L.popup_insert_index([], "action"), 0, "empty queue")
	# 正在顯示的第 0 個不會被插隊
	_eq(L.popup_insert_index(_q(["action"]), "order"), 1, "order after showing action")
	_eq(L.popup_insert_index(_q(["action", "action"]), "order"), 1, "order before waiting action")
	_eq(L.popup_insert_index(_q(["order", "action"]), "monthly"), 1, "monthly before action")
	_eq(L.popup_insert_index(_q(["order", "monthly", "action"]), "monthly"), 2, "monthly after monthly")
	_eq(L.popup_insert_index(_q(["order", "monthly"]), "action"), 2, "action last")
	_eq(L.popup_insert_index(_q(["monthly", "action"]), "action"), 2, "actions in order of operation")
	_eq(L.popup_insert_index(_q(["action", "monthly"]), "order"), 1, "order before monthly")


func _test_popup_height() -> void:
	var w := {}
	_eq(L.popup_frame_height(L.popup_checkin(w)), 168, "D17 checkin 168")
	_eq(L.popup_frame_height(L.popup_tier(7, "", w)), 168, "D17 tier 7 168")
	_eq(L.popup_frame_height(L.popup_tier(21, "", w)), 168, "D17 tier 21 168")
	_eq(L.popup_frame_height(L.popup_tier(28, "颱風", w)), 190, "D17 tier 28 190")
	_eq(L.popup_tier(28, "颱風", w).lines, ["隨機道具:颱風 ×1"], "D17 tier 28 item line")
	_eq(L.popup_frame_height(L.popup_topup("action", w)), 190, "D17 topup 190")
	_eq(L.popup_topup("order", w).kind, "order", "repair order kind")
	var all := [{"tier": 7}, {"tier": 14}, {"tier": 21}, {"tier": 28, "item_name": "x"}]
	_eq(L.popup_frame_height(L.popup_monthly(all, w)), 372, "D15 4 tiers 372")
	_eq(L.popup_frame_height(L.popup_monthly([{"tier": 7}], w)), 184, "D15 1 tier 184")
	_eq(L.popup_frame_height(L.popup_monthly([{"tier": 28, "item_name": "x"}], w)), 204, "D15 tier 28 only 204")


func _test_items() -> void:
	_eq(L.SHOP_ITEMS.size(), 10, "10 shop items")
	var seen := {}
	for i in 2000:
		seen[S.draw_item()] = true
	_eq(seen.size(), 10, "random item covers all 10 kinds")
	for k in seen:
		_eq(k in L.SHOP_ITEMS, true, "drawn item %s in pool" % k)


func _test_month_reset() -> void:
	S.reset()
	S.signed_count = 30
	S.signed_today = true
	S.claimed = [7]
	var silver0: int = S.wallet.silver
	var coin0: int = S.wallet.coin
	S.simulate_month_reset()
	var tiers := []
	for t in S.pending_monthly:
		tiers.append(t.tier)
	_eq(tiers, [14, 21, 28], "month reset reissues reached unclaimed tiers ascending")
	_eq(S.pending_monthly[2].item_name in L.SHOP_ITEMS, true, "tier 28 reissue has item name")
	_eq(S.pending_monthly[0].item_name, "", "tier 14 reissue no item")
	_eq(S.wallet.silver, silver0 + 2 + 5 + 5, "reissue credits silver")
	_eq(S.wallet.coin, coin0 + 5000 + 10000, "reissue credits coins")
	_eq([S.signed_count, S.signed_today, S.claimed], [0, false, []], "month reset zeroes count")
	S.reset()
	S.signed_count = 3
	S.simulate_month_reset()
	_eq(S.pending_monthly.size(), 0, "nothing reached -> no reissue")


var _last := {}


func _req(f: Callable) -> Dictionary:
	_last = {}
	f.call(func(r: Dictionary) -> void: _last = r)
	while _last.is_empty():
		await process_frame
	return _last


func _test_service_requests() -> void:
	S.reset()
	S.delay_sec = 0.01
	var r := await _req(S.fetch_status)
	_eq([r.ok, r.signed_count, r.signed_today, r.claimed, r.topup_bought, r.popups], [true, 7, false, [], false, []], "fetch default")
	r = await _req(S.check_in)
	_eq([r.ok, r.signed_count, r.signed_today, r.wallet.coin, r.wallet.heart], [true, 8, true, 12345 + 1500, 3 + 2], "check in")
	r = await _req(S.check_in)
	_eq(r.ok, false, "second check in same day rejected")
	r = await _req(func(cb: Callable) -> void: S.claim(14, cb))
	_eq(r.ok, false, "claim locked tier rejected")
	S.fail_next = 1
	r = await _req(func(cb: Callable) -> void: S.claim(7, cb))
	_eq([r.ok, S.claimed], [false, []], "failed claim changes nothing")
	r = await _req(func(cb: Callable) -> void: S.claim(7, cb))
	_eq([r.ok, r.claimed, r.item_name, r.wallet.silver], [true, [7], "", 300 + 1], "claim 7")
	S.signed_count = 28
	r = await _req(func(cb: Callable) -> void: S.claim(28, cb))
	_eq(r.item_name in L.SHOP_ITEMS, true, "claim 28 returns item name")
	# 愛心上限 99
	S.wallet.heart = 98
	S.signed_today = false
	r = await _req(S.check_in)
	_eq(r.wallet.heart, 99, "hearts capped at 99")
	# 首儲:取消 / 失敗 / 成功 / 重複
	S.cancel_next = true
	r = await _req(S.buy_first_topup)
	_eq([r.ok, r.canceled, S.topup_bought], [false, true, false], "buy canceled")
	S.fail_next = 1
	r = await _req(S.buy_first_topup)
	_eq([r.ok, r.canceled, S.topup_bought], [false, false, false], "buy failed")
	var gold0: int = S.wallet.gold
	r = await _req(S.buy_first_topup)
	_eq([r.ok, r.topup_bought, r.wallet.gold], [true, true, gold0 + 300], "buy ok")
	r = await _req(S.buy_first_topup)
	_eq(r.ok, false, "buy twice rejected (limit 1)")
	# 補發清單只回傳一次;順序:補發訂單 → 月初補發
	S.reset()
	S.delay_sec = 0.01
	S.simulate_month_reset()
	S.signed_count = 0
	S.simulate_pending_order()
	S.pending_monthly = [{"tier": 7, "item_name": ""}]
	r = await _req(S.fetch_status)
	var kinds := []
	for p in r.popups:
		kinds.append(p.kind)
	_eq(kinds, ["order", "monthly"], "popups order first then monthly")
	var ids := [r.popups[0].id, r.popups[1].id]
	# 玩家關框前每次取資料都帶回同一批(同 id);標記失敗時保留
	r = await _req(S.fetch_status)
	_eq([r.popups.size(), r.popups[0].id, r.popups[1].id], [2, ids[0], ids[1]], "popups kept until seen")
	S.fail_next = 1
	r = await _req(func(cb: Callable) -> void: S.mark_popup_seen(ids[1], cb))
	_eq([r.ok, S.pending_monthly.size()], [false, 1], "mark seen failure keeps monthly")
	r = await _req(func(cb: Callable) -> void: S.mark_popup_seen(ids[1], cb))
	_eq(r.ok, true, "mark monthly seen")
	r = await _req(S.fetch_status)
	_eq([r.popups.size(), r.popups[0].kind], [1, "order"], "monthly gone, order remains")
	r = await _req(func(cb: Callable) -> void: S.mark_popup_seen(ids[0], cb))
	r = await _req(S.fetch_status)
	_eq(r.popups, [], "all seen -> no popups")
	S.fail_next = 1
	r = await _req(S.fetch_status)
	_eq(r.ok, false, "fetch failure")
	S.reset()
