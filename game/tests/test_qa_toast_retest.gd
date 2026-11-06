extends SceneTree
## QA 重測:toast 切頁收起、失敗回應晚到不顯示 toast、成功回應晚到不退步、快速連續操作。執行:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path game --script res://tests/test_qa_toast_retest.gd
## 有任何失敗時結束碼為 1。

const HOME_SIM_PATH := "res://tests/home_sim.gd"
const S := preload("res://scripts/event_service.gd")
const L := preload("res://scripts/event_logic.gd")
const DELAY := 0.05
const WAIT := 0.15
const SLOW := 0.4

const BACK_BTN := Vector2(30, 102)
const ITEM_CHECKIN := Vector2(180, 174)
const ITEM_TOPUP := Vector2(180, 254)
const CHECKIN_BTN := Vector2(298, 158)
const CLAIM_Y := 540
const CLAIM7 := Vector2(54, CLAIM_Y)
const CLAIM14 := Vector2(138, CLAIM_Y)
const BUY_BTN := Vector2(180, 504)

const T_CHECKIN := "簽到失敗,請檢查網路後再試"
const T_CLAIM := "領取失敗,請檢查網路後再試"
const T_BUY := "購買失敗,請稍後再試"

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


func _tapf(pos: Vector2) -> void:
	_tap(pos)
	await _frames()


func _frames(n := 2) -> void:
	for i in n:
		await process_frame


func _wait(sec := WAIT) -> void:
	await create_timer(sec).timeout


func _back_key() -> void:
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


func _ev():
	return home._event


func _open_event() -> void:
	_tap(home._bottom_buttons[0].get_global_rect().get_center())
	await _frames()
	await _wait()


## 每個情境從乾淨的首頁 + 活動頁 A 開始
func _fresh(count := 7, today := false, claimed: Array[int] = []) -> void:
	S.reset()
	S.delay_sec = DELAY
	S.signed_count = count
	S.signed_today = today
	S.claimed = claimed
	await _make_home()
	await _wait()
	await _open_event()


## toast 實際繪製區(event_screen.toast_rect,_draw_toast 用同一個),以活動頁 body 為基準。
## 2026-11-07 改用正式程式的實際值:舊版自己寫死 y 436,等於沒有驗證實際位置
func _toast_rect(ev) -> Rect2:
	return ev.toast_rect()


func _run() -> void:
	await _test_switch_hides_all_paths()
	await _test_same_page_duration_and_style()
	await _test_old_timer_does_not_cut_new_toast()
	await _test_late_failure_paths()
	await _test_late_failure_does_not_override_new_toast()
	await _test_late_failure_after_close()
	await _test_late_success()
	await _test_rapid()
	if home:
		home.queue_free()
		await _frames()
	S.reset()
	print("PASSED %d, FAILED %d" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


## 重測 2:所有切頁路徑都立即收起 toast,timer 停止
func _test_switch_hides_all_paths() -> void:
	print("-- switch hides")
	await _fresh()
	var ev = _ev()
	# B -> A 返回鈕
	await _tapf(ITEM_CHECKIN)
	S.fail_next = 1
	_tap(CHECKIN_BTN)
	await _wait()
	_eq(ev.toast_text, T_CHECKIN, "B toast shown")
	await _tapf(BACK_BTN)
	_eq([ev.page, ev.toast_text, ev._toast_timer.is_stopped()], [L.Page.LIST, "", true], "B->A back button hides")
	# B -> A 返回鍵
	await _tapf(ITEM_CHECKIN)
	S.fail_next = 1
	_tap(CHECKIN_BTN)
	await _wait()
	_eq(ev.toast_text, T_CHECKIN, "B toast shown (2)")
	await _back_key()
	_eq([ev.page, ev.toast_text, ev._toast_timer.is_stopped()], [L.Page.LIST, "", true], "B->A back key hides")
	# C -> A 返回鈕 / 返回鍵
	await _tapf(ITEM_TOPUP)
	S.fail_next = 1
	_tap(BUY_BTN)
	await _wait()
	_eq(ev.toast_text, T_BUY, "C toast shown")
	await _tapf(BACK_BTN)
	_eq([ev.page, ev.toast_text], [L.Page.LIST, ""], "C->A back button hides")
	await _tapf(ITEM_TOPUP)
	S.fail_next = 1
	_tap(BUY_BTN)
	await _wait()
	_eq(ev.toast_text, T_BUY, "C toast shown (2)")
	await _back_key()
	_eq([ev.page, ev.toast_text], [L.Page.LIST, ""], "C->A back key hides")
	# A -> B / A -> C(A 本身不產生 toast,直接設)
	ev._show_toast(T_CLAIM)
	await _tapf(ITEM_CHECKIN)
	_eq([ev.page, ev.toast_text, ev._toast_timer.is_stopped()], [L.Page.CHECKIN, "", true], "A->B hides")
	await _tapf(BACK_BTN)
	ev._show_toast(T_CLAIM)
	await _tapf(ITEM_TOPUP)
	_eq([ev.page, ev.toast_text, ev._toast_timer.is_stopped()], [L.Page.TOPUP, "", true], "A->C hides")
	# C -> A -> 首頁(toast 顯示中連按返回鍵兩次)
	S.fail_next = 1
	_tap(BUY_BTN)
	await _wait()
	await _back_key()
	await _back_key()
	await _frames()
	_eq([home._event, is_instance_valid(ev)], [null, false], "C->A->home frees event page")
	# B toast 顯示中 -> 返回鈕兩次回首頁
	await _open_event()
	ev = _ev()
	await _tapf(ITEM_CHECKIN)
	S.fail_next = 1
	_tap(CHECKIN_BTN)
	await _wait()
	_eq(ev.toast_text, T_CHECKIN, "B toast before going home")
	await _tapf(BACK_BTN)
	await _tapf(BACK_BTN)
	await _frames()
	_eq([home._event, is_instance_valid(ev)], [null, false], "B->A->home via button frees event page")
	await _open_event()
	_eq(_ev().toast_text, "", "reopened: no toast")


## 同頁 toast 仍 2 秒、位置 y 436~468、樣式不變
func _test_same_page_duration_and_style() -> void:
	print("-- same page duration")
	await _fresh()
	var ev = _ev()
	await _tapf(ITEM_CHECKIN)
	S.fail_next = 1
	_tap(CHECKIN_BTN)
	await _wait(DELAY + 0.03)
	_eq(ev.toast_text, T_CHECKIN, "toast appears")
	_eq(is_equal_approx(ev._toast_timer.wait_time, 2.0), true, "timer 2 s")
	var r := _toast_rect(ev)
	_eq([r.position.y, r.end.y], [436.0, 468.0], "toast y 436~468")
	_eq([ev.TOAST_BG, ev.TOAST_BORDER], [Color("#222B3A"), Color("#5D6D7E")], "toast colors unchanged")
	_eq(ev._toast.get_parent() == ev._body, true, "toast layer in body (moves with tall offset)")
	await _wait(1.8)
	_eq(ev.toast_text, T_CHECKIN, "still shown at ~1.9 s")
	await _wait(0.3)
	_eq(ev.toast_text, "", "hidden after 2 s")
	_eq(ev.page, L.Page.CHECKIN, "still on B")


## 切頁時舊 timer 已停,不會提早收掉新頁的 toast
func _test_old_timer_does_not_cut_new_toast() -> void:
	print("-- old timer")
	await _fresh(14)
	var ev = _ev()
	await _tapf(ITEM_CHECKIN)
	S.fail_next = 1
	_tap(CHECKIN_BTN)
	await _wait()
	_eq(ev.toast_text, T_CHECKIN, "first toast")
	await _wait(1.2)
	await _tapf(BACK_BTN)
	await _tapf(ITEM_CHECKIN)
	S.fail_next = 1
	_tap(CLAIM14)
	await _wait()
	_eq(ev.toast_text, T_CLAIM, "new toast after switch")
	# 若舊 timer 還在跑,會在第一個 toast 起算 2 秒(約再 0.6 秒)收掉
	await _wait(1.0)
	_eq(ev.toast_text, T_CLAIM, "new toast survives past old timer end")
	await _wait(1.0)
	_eq(ev.toast_text, "", "new toast hidden after its own 2 s")


## 重測 3:三種操作的失敗回應晚到
func _late_case(label: String, enter: Vector2, act: Vector2, after_switch: Array, expect_page) -> void:
	await _fresh(14)
	var ev = _ev()
	var before := S.wallet.duplicate()
	var before_count := S.signed_count
	await _tapf(enter)
	S.delay_sec = SLOW
	S.fail_next = 1
	_tap(act)
	await _frames()
	S.delay_sec = DELAY
	for p in after_switch:
		if p is String and p == "back":
			await _tapf(BACK_BTN)
		elif p is String and p == "key":
			await _back_key()
		else:
			await _tapf(p)
	_eq(ev.page, expect_page, label + ": page before response")
	await _wait(SLOW + 0.1)
	_eq(ev.toast_text, "", label + ": no toast")
	_eq([S.wallet, S.signed_count], [before, before_count], label + ": server unchanged")
	_eq(home._resources.values, [before.heart, before.coin, before.gold, before.silver], label + ": resource bar unchanged")
	_eq(home._popup.is_open(), false, label + ": no popup")
	# 按鈕恢復可按
	var c = ev._checkin
	_eq([c._checkin.text, c._checkin.disabled], ["今日簽到", false], label + ": checkin btn ready")
	_eq([c._claims[7].text, c._claims[7].disabled], ["領取", false], label + ": claim7 ready")
	_eq([c._claims[14].text, c._claims[14].disabled], ["領取", false], label + ": claim14 ready")
	_eq([ev._topup._buy.text, ev._topup._buy.disabled], ["TWD 300 購買", false], label + ": buy btn ready")
	# 回到該頁再操作(成功)仍正常
	if ev.page != L.Page.LIST:
		await _tapf(BACK_BTN)
	await _tapf(enter)
	_tap(act)
	await _wait()
	_eq([ev.toast_text, home._popup.is_open()], ["", true], label + ": retry succeeds with popup")


func _test_late_failure_paths() -> void:
	print("-- late failure")
	await _late_case("B checkin->A btn", ITEM_CHECKIN, CHECKIN_BTN, ["back"], L.Page.LIST)
	await _late_case("B checkin->A key", ITEM_CHECKIN, CHECKIN_BTN, ["key"], L.Page.LIST)
	await _late_case("B checkin->A->C", ITEM_CHECKIN, CHECKIN_BTN, ["back", ITEM_TOPUP], L.Page.TOPUP)
	await _late_case("B checkin->A->B", ITEM_CHECKIN, CHECKIN_BTN, ["back", ITEM_CHECKIN], L.Page.CHECKIN)
	await _late_case("B claim->A", ITEM_CHECKIN, CLAIM14, ["back"], L.Page.LIST)
	await _late_case("B claim->A->C", ITEM_CHECKIN, CLAIM7, ["back", ITEM_TOPUP], L.Page.TOPUP)
	await _late_case("B claim->A->B", ITEM_CHECKIN, CLAIM14, ["back", ITEM_CHECKIN], L.Page.CHECKIN)
	await _late_case("C buy->A", ITEM_TOPUP, BUY_BTN, ["back"], L.Page.LIST)
	await _late_case("C buy->A key", ITEM_TOPUP, BUY_BTN, ["key"], L.Page.LIST)
	await _late_case("C buy->A->B", ITEM_TOPUP, BUY_BTN, ["back", ITEM_CHECKIN], L.Page.CHECKIN)
	await _late_case("C buy->A->C", ITEM_TOPUP, BUY_BTN, ["back", ITEM_TOPUP], L.Page.TOPUP)
	# 同頁慢回應失敗:照常顯示
	await _fresh(14)
	var ev = _ev()
	for c in [[ITEM_CHECKIN, CHECKIN_BTN, T_CHECKIN], [ITEM_CHECKIN, CLAIM14, T_CLAIM], [ITEM_TOPUP, BUY_BTN, T_BUY]]:
		await _tapf(c[0])
		S.delay_sec = SLOW
		S.fail_next = 1
		_tap(c[1])
		await _wait(SLOW + 0.1)
		_eq(ev.toast_text, c[2], "same page slow failure shows '%s'" % c[2])
		await _tapf(BACK_BTN)
	S.delay_sec = DELAY


## 舊畫面的失敗晚到,不會蓋掉 / 重新計時新畫面自己的 toast
func _test_late_failure_does_not_override_new_toast() -> void:
	print("-- late does not override")
	await _fresh(14)
	var ev = _ev()
	await _tapf(ITEM_CHECKIN)
	S.delay_sec = 0.8
	S.fail_next = 1
	_tap(CLAIM14)
	await _frames()
	S.delay_sec = DELAY
	await _tapf(BACK_BTN)
	await _tapf(ITEM_TOPUP)
	S.fail_next = 1
	_tap(BUY_BTN)
	await _wait()
	_eq(ev.toast_text, T_BUY, "new page own toast")
	await _wait(0.7)  # 舊領取失敗此時到達
	_eq(ev.toast_text, T_BUY, "old late failure does not replace new toast")
	await _wait(1.3)  # 新 toast 起算約 2.15 s
	_eq(ev.toast_text, "", "new toast timer not restarted by old failure")


## 回首頁後回應才到:節點已釋放,不報錯
func _test_late_failure_after_close() -> void:
	print("-- late after close")
	await _fresh(14)
	await _tapf(ITEM_CHECKIN)
	S.delay_sec = SLOW
	S.fail_next = 1
	_tap(CHECKIN_BTN)
	await _frames()
	S.delay_sec = DELAY
	await _back_key()
	await _back_key()
	_eq(home._event, null, "closed before response")
	await _wait(SLOW + 0.1)
	_eq(home._popup.is_open(), false, "no popup after late failure on home")
	await _open_event()
	_eq(_ev().toast_text, "", "reopen no toast")


## 重測 4:切走後成功回應:提示框照跳、資料更新、資源列按「好」後才更新、無 toast
func _test_late_success() -> void:
	print("-- late success")
	var cases := [
		["checkin", ITEM_CHECKIN, CHECKIN_BTN, ["back"]],
		["claim14", ITEM_CHECKIN, CLAIM14, ["back", ITEM_TOPUP]],
		["buy", ITEM_TOPUP, BUY_BTN, ["back"]],
	]
	for c in cases:
		await _fresh(14)
		var ev = _ev()
		var before: Array = home._resources.values.duplicate()
		await _tapf(c[1])
		S.delay_sec = SLOW
		_tap(c[2])
		await _frames()
		S.delay_sec = DELAY
		for p in c[3]:
			if p is String:
				await _tapf(BACK_BTN)
			else:
				await _tapf(p)
		await _wait(SLOW + 0.1)
		_eq(ev.toast_text, "", c[0] + " late success: no toast")
		_eq(home._popup.is_open(), true, c[0] + " late success: popup shown")
		_eq(home._popup.current().title, "已獲得", c[0] + " late success: title")
		_eq(home._resources.values, before, c[0] + " late success: bar not updated before 好")
		_eq(ev.status.wallet, S.wallet, c[0] + " late success: status updated")
		match c[0]:
			"checkin":
				_eq([ev._checkin._checkin.text, ev._checkin.signed_count], ["今日已簽", 15], "checkin late success: B updated")
			"claim14":
				_eq(ev._checkin._claims[14].text, "已領取", "claim late success: B updated")
			"buy":
				_eq([ev._items[1].subtitle, ev._topup._buy.text], ["已購買", "已購買"], "buy late success: A row / C updated")
		var ok: Control = home._popup._ok
		_tap(ok.get_global_rect().get_center())
		await _frames()
		_eq(home._popup.is_open(), false, c[0] + " late success: 好 closes")
		_eq(home._resources.values, [S.wallet.heart, S.wallet.coin, S.wallet.gold, S.wallet.silver], c[0] + " late success: bar updated after 好")


## 重測 5:快速連續操作
func _test_rapid() -> void:
	print("-- rapid")
	await _fresh(14)
	var ev = _ev()
	await _tapf(ITEM_CHECKIN)
	# 同頁連續失敗兩次:第二次重新計時
	S.fail_next = 1
	_tap(CHECKIN_BTN)
	await _wait()
	_eq(ev.toast_text, T_CHECKIN, "fail 1")
	await _wait(1.2)
	S.fail_next = 1
	_tap(CLAIM14)
	await _wait()
	_eq(ev.toast_text, T_CLAIM, "fail 2 replaces text")
	await _wait(1.0)  # 距第一次約 2.5 s
	_eq(ev.toast_text, T_CLAIM, "fail 2 restarts 2 s timer")
	await _wait(1.0)
	_eq(ev.toast_text, "", "fail 2 hidden after its 2 s")
	# 同頁同時兩個請求都失敗
	S.fail_next = 2
	_tap(CHECKIN_BTN)
	_tap(CLAIM14)
	await _wait()
	_eq(ev.toast_text != "", true, "two concurrent failures: a toast shown")
	_eq([ev._checkin._checkin.disabled, ev._checkin._claims[14].disabled], [false, false], "two concurrent failures: both ready")
	# 失敗 toast 顯示中切頁 → 新頁再失敗
	await _tapf(BACK_BTN)
	_eq(ev.toast_text, "", "switch during toast hides")
	await _tapf(ITEM_TOPUP)
	S.fail_next = 1
	_tap(BUY_BTN)
	await _wait()
	_eq(ev.toast_text, T_BUY, "new page failure shows")
	await _wait(1.7)
	_eq(ev.toast_text, T_BUY, "new page toast ~1.85 s still shown")
	await _wait(0.4)
	_eq(ev.toast_text, "", "new page toast hidden after 2 s")
	# 快速來回切頁多次後同頁失敗仍正常
	for i in 5:
		await _tapf(BACK_BTN)
		await _tapf(ITEM_TOPUP)
	S.fail_next = 1
	_tap(BUY_BTN)
	await _wait()
	_eq(ev.toast_text, T_BUY, "after rapid switching, same page failure shows")
