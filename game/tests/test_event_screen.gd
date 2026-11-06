extends SceneTree
## 活動頁互動測試:從首頁進活動頁,用 push_input 模擬點擊,驗證 A/B/C 切換、返回行為(含返回鍵)、
## 簽到 / 領取 / 購買、載入失敗與重試、toast、提示框依序跳出、紅點(D05、D16)、觸控範圍 ≥44。執行:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path game --script res://tests/test_event_screen.gd
## 有任何失敗時結束碼為 1。

const HOME_SIM_PATH := "res://tests/home_sim.gd"
const S := preload("res://scripts/event_service.gd")
const L := preload("res://scripts/event_logic.gd")
## 網路延遲設短,等待用 WAIT
const DELAY := 0.05
const WAIT := 0.15

const EVENT_BTN := Vector2(49, 528)
const BACK_BTN := Vector2(30, 102)
const ITEM_CHECKIN := Vector2(180, 174)
const ITEM_TOPUP := Vector2(180, 254)
const CHECKIN_BTN := Vector2(298, 158)
## 累積卡領取鈕中心:卡 x 14 + i×84 + 4 + 36,y 428 + 90 + 22
const CLAIM_Y := 540
const BUY_BTN := Vector2(180, 504)
const RETRY_BTN := Vector2(180, 374)

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


func _reset_service() -> void:
	S.reset()
	S.delay_sec = DELAY


func _ev():
	return home._event


func _open_event() -> void:
	_tap(EVENT_BTN)
	await _frames()


func _run() -> void:
	_reset_service()
	await _make_home()
	await _test_home_badge_and_enter()
	await _test_checkin_flow()
	await _test_back_behavior()
	await _test_load_failure()
	await _test_toasts()
	await _test_toast_page_switch()
	await _test_late_failure_toast()
	await _test_topup()
	await _test_popup_sequence()
	await _test_over_28()
	await _test_touch_sizes()
	await _test_tall()
	await _test_safe_top()
	for c in S08_CASES:
		await _check_s08(c)
	if home:
		home.queue_free()
		await _frames()
	S.reset()
	print("PASSED %d, FAILED %d" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


## D16:資料到達前不顯示,到達後依條件亮;進活動頁時首頁元件隱藏
func _test_home_badge_and_enter() -> void:
	var act = home._bottom_buttons[0]
	# 重新送出請求:資料到達前不顯示
	home._refresh_badge()
	_eq(act.badge, false, "home badge hidden before data")
	await _wait()
	_eq(act.badge, true, "home badge on: today not signed")
	for i in range(1, 4):
		_eq(home._bottom_buttons[i].badge, false, "other bottom buttons never badge %d" % i)
	await _open_event()
	_eq(_ev() != null, true, "tap 活動 opens event page")
	_eq(_ev().page, L.Page.LIST, "event opens on A")
	_eq(home._map.visible or home._start.visible or act.visible or home._bottom_bg.visible, false, "home-only nodes hidden")
	_eq(home._resources.visible, true, "resource bar shared")
	var item0 = _ev()._items[0]
	_eq(item0.badge, false, "A badge hidden before data")
	_eq([item0.subtitle, _ev()._items[1].subtitle], ["每日 1500 金幣 + 2 愛心", "限購 1 次"], "A list shown immediately")
	await _wait()
	_eq(item0.badge, true, "A badge on after data")
	_eq(_ev()._items[1].badge, false, "topup row never badge")


func _test_checkin_flow() -> void:
	var ev = _ev()
	_tap(ITEM_CHECKIN)
	await _frames()
	_eq(ev.page, L.Page.CHECKIN, "tap row 1 -> B")
	_eq(ev._checkin.visible, true, "B content visible (data loaded)")
	var btn = ev._checkin._checkin
	_eq([btn.text, btn.disabled], ["今日簽到", false], "checkin button ready")
	_tap(CHECKIN_BTN)
	await _frames()
	_eq([btn.text, btn.disabled], ["簽到中…", true], "checkin processing")
	await _wait()
	_eq([btn.text, btn.disabled], ["今日已簽", true], "checkin done")
	_eq(ev._checkin.signed_count, 8, "count 8 after checkin")
	_eq(L.cell_state(8, 8, true), L.Cell.TODAY, "cell 8 today")
	var popup = home._popup
	_eq(popup.is_open(), true, "D17 popup shown")
	_eq(popup.current().title, "已獲得", "D17 title")
	_eq(popup.frame_rect(), Rect2(32, 236, 296, 168), "D17 checkin frame rect")
	_eq(home._resources.values[1], 12345, "resource bar not updated before 好")
	# 遮罩擋住下層:點簽到鈕位置不會有反應(按鈕本來就停用,改點返回鈕驗證)
	_tap(BACK_BTN)
	await _frames()
	_eq(ev.page, L.Page.CHECKIN, "mask blocks back button")
	_tap(Vector2(180, 366))
	await _frames()
	_eq(popup.is_open(), false, "tap 好 closes popup")
	_eq(home._resources.values, [5, 13845, 50, 300], "resource bar updated after 好")
	# 領 7 次
	var claim7 = ev._checkin._claims[7]
	_eq([claim7.text, claim7.disabled], ["領取", false], "card 7 claimable")
	_eq([ev._checkin._claims[14].text, ev._checkin._claims[14].disabled], ["還差 6 次", true], "card 14 locked text")
	_tap(Vector2(54, CLAIM_Y))
	await _frames()
	_eq(claim7.text, "領取中…", "claim processing")
	await _wait()
	_eq([claim7.text, claim7.disabled], ["已領取", true], "claim done")
	_eq(popup.current().rewards, [["coin", 2000], ["silver", 1]], "claim popup rewards")
	# A10:提示框開著按返回鍵 = 按「好」,不離開畫面
	await _back_key()
	_eq([popup.is_open(), ev.page], [false, L.Page.CHECKIN], "back key closes popup only")
	_eq(home._resources.values[3], 301, "silver updated on close")
	_eq(ev._items[0].badge, false, "A badge off: signed and nothing claimable")


func _test_back_behavior() -> void:
	var ev = _ev()
	# 返回鍵:B → A → 首頁
	await _back_key()
	_eq(ev.page, L.Page.LIST, "back key B -> A")
	_tap(ITEM_TOPUP)
	await _frames()
	_eq(ev.page, L.Page.TOPUP, "tap row 2 -> C")
	# D04 返回鈕:C → A
	_tap(BACK_BTN)
	await _frames()
	_eq(ev.page, L.Page.LIST, "back button C -> A")
	await _back_key()
	_eq(home._event, null, "back key A -> home")
	_eq(home._map.visible and home._bottom_buttons[0].visible, true, "home restored")
	_eq(home._bottom_buttons[0].badge, false, "home badge hidden while refetching")
	await _wait()
	_eq(home._bottom_buttons[0].badge, false, "home badge off after refetch")
	# D04 返回鈕:A → 首頁
	await _open_event()
	_tap(BACK_BTN)
	await _frames()
	_eq(home._event, null, "back button A -> home")


## D14:A 讀取失敗 → 紅點不顯示、列表可點;進 B 顯示讀取失敗 + 重試
func _test_load_failure() -> void:
	S.signed_today = false
	await _wait()
	S.fail_next = 1
	await _open_event()
	var ev = _ev()
	_tap(ITEM_CHECKIN)
	await _frames()
	_eq([ev.load_state, ev._state_view.visible, ev._checkin.visible], [ev.Load.LOADING, true, false], "B loading view")
	_eq(ev._retry.visible, false, "no retry while loading")
	await _wait()
	_eq([ev.load_state, ev._retry.visible, ev._checkin.visible], [ev.Load.FAILED, true, false], "B failed view")
	_eq(ev._items[0].badge, false, "A badge hidden on failure")
	_tap(BACK_BTN)
	await _frames()
	_eq(ev.page, L.Page.LIST, "back works on failure")
	_tap(ITEM_TOPUP)
	await _frames()
	_eq([ev._state_view.visible, ev._topup.visible], [true, false], "C failed view")
	_tap(RETRY_BTN)
	await _frames()
	_eq(ev.load_state, ev.Load.LOADING, "retry -> loading")
	await _wait()
	_eq([ev.load_state, ev._topup.visible, ev._state_view.visible], [ev.Load.LOADED, true, false], "retry -> loaded")
	_eq(ev._items[0].badge, true, "A badge after retry (not signed today)")
	_tap(BACK_BTN)
	await _frames()


func _test_toasts() -> void:
	var ev = _ev()
	_tap(ITEM_CHECKIN)
	await _frames()
	S.fail_next = 1
	_tap(CHECKIN_BTN)
	await _wait()
	var btn = ev._checkin._checkin
	_eq([btn.text, btn.disabled], ["今日簽到", false], "checkin failure -> back to ready")
	_eq(ev.toast_text, "簽到失敗,請檢查網路後再試", "checkin failure toast")
	_eq(home._popup.is_open(), false, "no popup on failure")
	await _wait(2.1)
	_eq(ev.toast_text, "", "toast hides after 2 s")
	# 領取失敗
	S.signed_count = 14
	ev._fetch()
	await _wait()
	S.fail_next = 1
	_tap(Vector2(138, CLAIM_Y))
	await _wait()
	_eq(ev._checkin._claims[14].text, "領取", "claim failure -> claimable")
	_eq(ev.toast_text, "領取失敗,請檢查網路後再試", "claim failure toast")
	_tap(BACK_BTN)
	await _frames()


## 切換畫面時 toast 立即收起;同一畫面內 2 秒內仍顯示
func _test_toast_page_switch() -> void:
	var ev = _ev()
	const CLAIM_TOAST := "領取失敗,請檢查網路後再試"
	# B 領取失敗 → 同頁 2 秒內仍顯示 → 返回鈕回 A 立即收起
	_tap(ITEM_CHECKIN)
	await _frames()
	S.fail_next = 1
	_tap(Vector2(138, CLAIM_Y))
	await _wait()
	_eq(ev.toast_text, CLAIM_TOAST, "B toast shown")
	await _wait(1.0)
	_eq(ev.toast_text, CLAIM_TOAST, "same page toast still shown within 2 s")
	_tap(BACK_BTN)
	await _frames()
	_eq([ev.page, ev.toast_text, ev._toast_timer.is_stopped()], [L.Page.LIST, "", true], "B -> A (back button) hides toast")
	# A 上有 toast(直接設定,A 本身不產生 toast)→ 點列表進 C 立即收起
	ev._show_toast(CLAIM_TOAST)
	_tap(ITEM_TOPUP)
	await _frames()
	_eq([ev.page, ev.toast_text], [L.Page.TOPUP, ""], "A -> C hides toast")
	# B 失敗 → 返回鍵回 A 也收起
	_tap(BACK_BTN)
	await _frames()
	_tap(ITEM_CHECKIN)
	await _frames()
	S.fail_next = 1
	_tap(Vector2(138, CLAIM_Y))
	await _wait()
	_eq(ev.toast_text, CLAIM_TOAST, "B toast shown again")
	await _back_key()
	_eq([ev.page, ev.toast_text], [L.Page.LIST, ""], "B -> A (back key) hides toast")
	# A 上有 toast → 返回首頁:活動頁節點釋放,toast 跟著消失
	ev._show_toast(CLAIM_TOAST)
	await _back_key()
	await _frames()
	_eq([home._event, is_instance_valid(ev)], [null, false], "event -> home removes toast")
	# 回到活動頁 A,讓後續測試沿用原本的起點
	await _open_event()
	await _wait()
	_eq(_ev().toast_text, "", "reopened event has no toast")


## 失敗回應晚到:發出請求的那次畫面已切走(含切回同一頁)就不顯示 toast;按鈕狀態照常恢復
func _test_late_failure_toast() -> void:
	var ev = _ev()
	const SLOW := 0.3
	S.delay_sec = SLOW
	# B 領取 → 立刻回 A → 失敗回應到達:A 無 toast,B 的領取鈕照常恢復
	_tap(ITEM_CHECKIN)
	await _frames()
	S.fail_next = 1
	_tap(Vector2(138, CLAIM_Y))
	await _frames()
	_tap(BACK_BTN)
	await _frames()
	_eq(ev.page, L.Page.LIST, "late claim: switched to A before response")
	await _wait(SLOW + 0.1)
	_eq(ev.toast_text, "", "late claim failure: no toast on A")
	_eq(ev._checkin._claims[14].text, "領取", "late claim failure: button restored")
	# B 簽到 → 回 A → 再進 B → 失敗回應到達:B 也無 toast
	_tap(ITEM_CHECKIN)
	await _frames()
	S.fail_next = 1
	_tap(CHECKIN_BTN)
	await _frames()
	_tap(BACK_BTN)
	await _frames()
	_tap(ITEM_CHECKIN)
	await _frames()
	_eq(ev.page, L.Page.CHECKIN, "late checkin: back on B before response")
	await _wait(SLOW + 0.1)
	_eq(ev.toast_text, "", "late checkin failure: no toast after B -> A -> B")
	_eq(ev._checkin._checkin.text, "今日簽到", "late checkin failure: button restored")
	# 同一畫面:失敗 toast 照常顯示
	S.fail_next = 1
	_tap(CHECKIN_BTN)
	await _wait(SLOW + 0.1)
	_eq(ev.toast_text, "簽到失敗,請檢查網路後再試", "same page late failure: toast shown")
	_tap(BACK_BTN)
	await _frames()
	# C 購買 → 回 A → 失敗回應到達:A 無 toast,購買鈕照常恢復
	_tap(ITEM_TOPUP)
	await _frames()
	S.fail_next = 1
	_tap(BUY_BTN)
	await _frames()
	_tap(BACK_BTN)
	await _frames()
	_eq(ev.page, L.Page.LIST, "late buy: switched to A before response")
	await _wait(SLOW + 0.1)
	_eq(ev.toast_text, "", "late buy failure: no toast on A")
	_eq(ev._topup._buy.text, "TWD 300 購買", "late buy failure: button restored")
	S.delay_sec = DELAY


func _test_topup() -> void:
	var ev = _ev()
	_tap(ITEM_TOPUP)
	await _frames()
	var buy = ev._topup._buy
	_eq([buy.text, buy.disabled], ["TWD 300 購買", false], "buy ready")
	ev.toast_text = ""
	S.cancel_next = true
	_tap(BUY_BTN)
	await _frames()
	_eq([buy.text, buy.disabled], ["處理中…", true], "buy processing")
	await _wait()
	_eq([buy.text, ev.toast_text], ["TWD 300 購買", ""], "cancel -> ready, no toast")
	S.fail_next = 1
	_tap(BUY_BTN)
	await _wait()
	_eq([buy.text, ev.toast_text], ["TWD 300 購買", "購買失敗,請稍後再試"], "buy failure toast")
	_tap(BUY_BTN)
	await _wait()
	_eq([buy.text, buy.disabled, ev._topup.bought], ["已購買", true, true], "buy ok")
	var p = home._popup.current()
	_eq([p.rewards, p.lines], [[["gold", 300], ["silver", 150]], ["商城道具 各 1 個"]], "topup popup content")
	_tap(Vector2(180, 225 + 124 + 22))
	await _frames()
	_eq(home._popup.is_open(), false, "topup popup closed by 好 (frame y 225)")
	_eq(home._resources.values[2], 350, "gold updated")
	_tap(BACK_BTN)
	await _frames()
	_eq([ev._items[1].subtitle, ev._items[1].dimmed, ev._items[1].badge], ["已購買", true, false], "A topup row bought")
	_tap(BACK_BTN)
	await _frames()
	await _wait()


## D17 順序:補發訂單 → 月初補發 → 玩家操作;首頁先拿到就在首頁彈;按「好」後才更新紅點
func _test_popup_sequence() -> void:
	_eq(home._event, null, "on home")
	S.signed_count = 30
	S.claimed = [7]
	S.simulate_month_reset()
	S.simulate_pending_order()
	home._refresh_badge()
	await _wait()
	var popup = home._popup
	_eq(popup.current().kind, "order", "1st popup: repair order")
	_eq(popup.current().title, "已獲得", "order title")
	_eq(home._bottom_buttons[0].badge, false, "badge waits until popups closed")
	await _back_key()
	_eq(popup.current().kind, "monthly", "2nd popup: monthly reissue")
	_eq(popup.current().title, "上月未領取的累積獎勵已補發", "monthly title")
	# 14、21、28 次:56 + 56 + 76 = 188 → 框高 56 + 188 + 72 = 316,y = (640 − 316) / 2
	_eq(popup.frame_rect(), Rect2(32, 162, 296, 316), "D15 3 tiers frame")
	await _back_key()
	_eq(popup.is_open(), false, "all closed")
	await _wait()
	_eq(home._bottom_buttons[0].badge, true, "badge after refetch (new month, not signed)")
	# 補發只彈一次:再進活動頁不會再彈
	await _open_event()
	await _wait()
	_eq(popup.is_open(), false, "reissue shown only once")
	_eq(_ev()._items[0].badge, true, "A badge new month")


## 超過 28 次:摘要不顯示分母、28 格全已簽、簽到鈕照常
func _test_over_28() -> void:
	var ev = _ev()
	S.signed_count = 29
	S.signed_today = false
	ev._fetch()
	await _wait()
	_tap(ITEM_CHECKIN)
	await _frames()
	_eq(L.summary_text(ev._checkin.signed_count), "本月已簽 29 次", "summary > 28")
	_eq(ev._checkin._checkin.text, "今日簽到", "checkin still available after 28")
	_tap(CHECKIN_BTN)
	await _wait()
	_eq(ev._checkin.signed_count, 30, "count keeps increasing")
	await _back_key()


## 所有可點元素 ≥ 44×44(活動頁與提示框)
func _test_touch_sizes() -> void:
	var nodes: Array = _ev().find_children("*", "BaseButton", true, false)
	nodes.append_array(home._popup.find_children("*", "BaseButton", true, false))
	_eq(nodes.size() >= 10, true, "found event buttons (%d)" % nodes.size())
	for b in nodes:
		_eq(b.size.x >= 44 and b.size.y >= 44, true, "%s touch %s >= 44" % [b.name, b.size])


## screen-size-800 驗證高度:上方貼安全區、E 全加在面板;B 四段留白、C 5 等分。
## 期望值(畫面座標)抄自規格關鍵座標表;700、T=40、B=34 依規格公式手算。640 必須等於原 640 版。
## [h, T, B, 返回鈕 y, 面板 y, 面板高, banner y, B 摘要 y, B 28 格 y, B 累積卡 y, C 標題 y, C 獎勵列 1 y, C 限購 y, C 購買鈕 y]
const HEIGHT_CASES := [
	[640, 24, 16, 80, 132, 434, 574, 136, 194, 428, 138, 188, 400, 476],
	[700, 24, 16, 80, 132, 494, 634, 145, 221, 473, 150, 212, 436, 524],
	[780, 24, 16, 80, 132, 574, 714, 157, 257, 533, 166, 244, 484, 588],
	[800, 24, 16, 80, 132, 594, 734, 160, 266, 548, 170, 252, 496, 604],
	[840, 24, 16, 80, 132, 634, 774, 166, 284, 578, 178, 268, 520, 636],
	[800, 40, 16, 96, 148, 578, 734, 174, 275, 552, 183, 262, 502, 607],
	[800, 24, 34, 80, 132, 576, 716, 157, 258, 535, 166, 245, 485, 590],
]


func _test_tall() -> void:
	for c in HEIGHT_CASES:
		await _check_height(c)


func _check_height(c: Array) -> void:
	var h: int = c[0]
	var t: int = c[1]
	var b: int = c[2]
	var tag := "H%d T%d B%d" % [h, t, b]
	_reset_service()
	await _make_home(h, t, b)
	await _wait()
	_tap(home._bottom_buttons[0].get_global_rect().get_center())
	await _frames()
	await _wait()
	var ev = _ev()
	var off: float = ev._body.position.y
	# 外框:資源列、返回鈕貼上;面板 y / 高;banner 貼下,與面板間隔 8
	_eq(home._d01_buttons[0].position.y, float(t + 4), tag + " resource bar y")
	_eq(ev._back.get_global_rect(), Rect2(8, c[3], 44, 44), tag + " back rect")
	_eq([off + ev._panel.position.y, ev._panel.size.y], [float(c[4]), float(c[5])], tag + " panel y / height")
	_eq(HomeLogic.home_layout(h, t, b).banner, c[6], tag + " banner y")
	_eq(c[6] - (off + ev._panel.end.y), 8.0, tag + " panel to banner gap 8")
	# A:列表項目位置不變(跟著上緣)
	_eq(ev._items[1].get_global_rect(), Rect2(14, 218 + t - 24, 332, 72), tag + " A item 2 rect")
	# B
	var ck = ev._checkin
	_tap(ev._items[0].get_global_rect().get_center())
	await _frames()
	_eq(ev.page, L.Page.CHECKIN, tag + " A -> B")
	_eq(ck._checkin.get_global_rect(), Rect2(250, c[7], 96, 44), tag + " B summary / checkin button")
	_eq([off + ck.grid_y, off + ck.card_y], [float(c[8]), float(c[9])], tag + " B grid / card y")
	for i in 4:
		_eq(ck._claims[L.TIERS[i]].get_global_rect(), Rect2(14 + i * 84 + 4, c[9] + 90, 72, 44), tag + " B claim %d" % i)
	_tap(ck._checkin.get_global_rect().get_center())
	await _frames()
	_eq(ck._checkin.text, "簽到中…", tag + " B checkin button tappable")
	await _wait()
	while home._popup.is_open():
		await _back_key()
	_tap(ev._back.get_global_rect().get_center())
	await _frames()
	# C
	var tp = ev._topup
	_tap(ev._items[1].get_global_rect().get_center())
	await _frames()
	_eq(ev.page, L.Page.TOPUP, tag + " A -> C")
	_eq([off + tp.title_y, off + tp.rows_y, off + tp.note_y], [float(c[10]), float(c[11]), float(c[12])], tag + " C title / rows / note y")
	_eq(tp._buy.get_global_rect(), Rect2(72, c[13], 216, 56), tag + " C buy rect")
	S.cancel_next = true
	_tap(tp._buy.get_global_rect().get_center())
	await _frames()
	_eq(tp._buy.text, "處理中…", tag + " C buy tappable")
	await _wait()
	# 觸控範圍 ≥ 44×44
	for btn in ev.find_children("*", "BaseButton", true, false):
		_eq(btn.size.x >= 44 and btn.size.y >= 44, true, "%s %s touch %s >= 44" % [tag, btn.name, btn.size])
	# 返回鈕:C → A → 首頁
	_tap(ev._back.get_global_rect().get_center())
	await _frames()
	_tap(ev._back.get_global_rect().get_center())
	await _frames()
	_eq(home._event, null, tag + " back button C -> A -> home")


## 方案 B(README 活動頁版面第 9 點):640 高、下 16;上安全區 ≤32 版面不變,40 時只有返回鈕 / 標題下移 8
func _test_safe_top() -> void:
	for c in [[24, 80, 0], [32, 80, 0], [40, 88, 8]]:
		_reset_service()
		await _make_home(640, c[0])
		await _wait()
		await _open_event()
		var ev = _ev()
		_eq([ev._body.position.y, ev._back.position.y, ev._header_shift], [0.0, float(c[1]), c[2]], "T%d back y / title shift" % c[0])
		_eq([ev._back.size, home._d01_buttons[0].position.y], [Vector2(44, 44), float(c[0] + 4)], "T%d back size / resource bar y" % c[0])
		_tap(BACK_BTN + Vector2(0, c[2]))
		await _frames()
		_eq(home._event, null, "T%d back button tappable" % c[0])


## screen-size-800 S08(方案 B):toast y = 436 + round(0.4E) + (T − 24);D14 整組 y = 640 值 + round(E ÷ 2) + (T − 24)。
## 期望值(畫面座標)抄自 S08 各高度座標表;640 T=40(E < 0)以 E = 0 計、跟著內容一起移(與 640 版相同)。
## [h, T, B, toast y, 重試鈕 y]
const S08_CASES := [
	[640, 24, 16, 436, 352],
	[780, 24, 16, 492, 422],
	[800, 24, 16, 500, 432],
	[840, 24, 16, 516, 452],
	[800, 40, 16, 510, 440],
	[800, 24, 34, 493, 423],
	[640, 40, 16, 436, 352],
]


## 可見的可點元素(活動頁內)
func _visible_buttons(ev) -> Array:
	return ev.find_children("*", "BaseButton", true, false).filter(func(b) -> bool: return b.is_visible_in_tree())


func _check_s08(c: Array) -> void:
	var h: int = c[0]
	var tag := "S08 H%d T%d B%d" % [h, c[1], c[2]]
	_reset_service()
	S.signed_count = 28
	await _make_home(h, c[1], c[2])
	await _wait()
	_tap(home._bottom_buttons[0].get_global_rect().get_center())
	await _wait()
	var ev = _ev()
	# 品質備註:活動頁與各圖層高度 = 畫面高
	for n in [ev, ev._body, ev._checkin, ev._topup, ev._state_view, ev._toast]:
		_eq(n.size, Vector2(360, h), "%s %s size" % [tag, n.name])
	# toast:B(累積卡全可領)與 C 都不蓋可點元素
	for p in [L.Page.CHECKIN, L.Page.TOPUP]:
		ev.show_page(p)
		ev._show_toast(ev.TOAST_CLAIM)
		await _frames()
		var tr: Rect2 = ev.toast_rect()
		tr.position += ev._toast.global_position
		_eq([tr.position.y, tr.end.y], [float(c[3]), float(c[3] + 32)], "%s page %d toast y" % [tag, p])
		_eq(absf(tr.get_center().x - 180) <= 1.0, true, "%s page %d toast centered" % [tag, p])
		var hits := _visible_buttons(ev).filter(func(b) -> bool: return b.get_global_rect().intersects(tr))
		_eq(hits.size(), 0, "%s page %d toast %s overlaps no button %s" % [tag, p, tr, hits])
		# 所有可點元素都在活動頁範圍內(高螢幕往下移的按鈕也是)
		for b in _visible_buttons(ev):
			_eq(ev.get_global_rect().encloses(b.get_global_rect()), true, "%s %s inside event page" % [tag, b.get_global_rect()])
	# D14:toast 顯示中重新載入 → 立即收起;載入中、失敗都不顯示 toast
	ev.show_page(L.Page.CHECKIN)
	ev._show_toast(ev.TOAST_CLAIM)
	S.fail_next = 1
	ev._fetch()
	await _frames()
	_eq([ev._state_view.visible, ev.toast_text, ev._toast_timer.is_stopped()], [true, "", true], tag + " loading hides toast")
	ev._show_toast(ev.TOAST_CLAIM)
	_eq(ev.toast_text, "", tag + " no toast while loading")
	await _wait()
	_eq([ev.load_state, ev.toast_text], [ev.Load.FAILED, ""], tag + " failed, no toast")
	_eq(ev._retry.get_global_rect(), Rect2(120, c[4], 120, 44), tag + " retry rect")
	# 重試鈕在面板內、整組中心 = 面板中心(640 值 349 + E ÷ 2,允許四捨五入差 1)
	var panel := Rect2(ev._panel.position + Vector2(0, ev._body.position.y), ev._panel.size)
	_eq(panel.encloses(ev._retry.get_global_rect()), true, tag + " retry inside panel")
	_eq(absf(ev._body.position.y + 349 + EventLogic.state_shift(ev._extra) - panel.get_center().y) <= 1.0, true, tag + " D14 centered in panel")
	# 重試失敗:只更新「讀取失敗」,不出 toast
	S.fail_next = 1
	_tap(ev._retry.get_global_rect().get_center())
	await _frames()
	_eq(ev.load_state, ev.Load.LOADING, tag + " retry tappable")
	await _wait()
	_eq([ev.load_state, ev.toast_text, ev._retry.visible], [ev.Load.FAILED, "", true], tag + " retry failure: no toast")
	home._close_event()
	await _frames()
