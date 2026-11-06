extends SceneTree
## QA:screen-size-800 S08(方案 B)toast 與 D14 位置、D14 不出 toast、節點尺寸 獨立驗證。執行:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path game --script res://tests/test_qa_s08.gd
## 期望值抄自 S08 座標表或依 S08 文字公式另外計算,不呼叫 EventLogic.toast_y / state_shift 求期望值。
## 有任何失敗時結束碼為 1。

const HOME_SIM_PATH := "res://tests/home_sim.gd"
const S := preload("res://scripts/event_service.gd")
const L := preload("res://scripts/event_logic.gd")
const DELAY := 0.05
const WAIT := 0.15

## [H, T, B, toast 畫面 y, 重試鈕畫面 y]
## 前 7 筆抄自 S08 表 / 例;其餘依 S08 公式手算:
## 700:E 60 → 436 + 24、352 + 30;1000:E 360 → 436 + 144、352 + 180
## 640 T48:E −24、位移 (T−24)+E = 0;640 B34:E −18、位移 −18 → 418、334
## 641 / 642 / 643:E 1 / 2 / 3 的四捨五入(0.4、0.8、1.2 → 0、1、1;0.5、1、1.5 → 1、1、2)
const CASES := [
	[640, 24, 16, 436, 352],
	[780, 24, 16, 492, 422],
	[800, 24, 16, 500, 432],
	[840, 24, 16, 516, 452],
	[800, 40, 16, 510, 440],
	[800, 24, 34, 493, 423],
	[640, 40, 16, 436, 352],
	[700, 24, 16, 460, 382],
	[1000, 24, 16, 580, 532],
	[640, 48, 16, 436, 352],
	[640, 24, 34, 418, 334],
	[641, 24, 16, 436, 353],
	[642, 24, 16, 437, 353],
	[643, 24, 16, 437, 354],
]

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


func _resize(h: int, t := 24, b := 16) -> void:
	root.size = Vector2i(360, h)
	home.sim_view = Vector2(360, h)
	home.sim_safe = Vector2i(t, b)
	home._apply_layout()
	await _frames()


func _reset() -> void:
	S.reset()
	S.delay_sec = DELAY


func _close_popups() -> void:
	while home._popup.is_open():
		home.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
		await _frames()


## 實際繪製的 toast 框(畫面座標)
func _toast_screen(ev) -> Rect2:
	var r: Rect2 = ev.toast_rect()
	return Rect2(ev._toast.global_position + r.position, r.size)


## 首頁 + 活動頁上所有可見、會吃觸控的可點元素(排除提示框)
func _clickables(n: Node, out: Array) -> void:
	for c in n.get_children():
		if c is Control and c != home._popup and c.is_visible_in_tree():
			if c is BaseButton and c.mouse_filter != Control.MOUSE_FILTER_IGNORE:
				out.append(c)
			_clickables(c, out)


func _no_overlap(tr: Rect2, tag: String) -> void:
	var list := []
	_clickables(home, list)
	var hits := []
	for c in list:
		if c.get_global_rect().intersects(tr):
			hits.append(str(c.get_global_rect()))
	_eq(hits, [], tag + " toast %s overlaps no clickable (%d scanned)" % [tr, list.size()])


func _run() -> void:
	for c in CASES:
		await _test_case(c)
	await _test_late_failure_in_d14()
	await _test_resize_sizes()
	if home:
		home.queue_free()
		await _frames()
	S.reset()
	print("PASSED %d, FAILED %d" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_case(c: Array) -> void:
	var h: int = c[0]
	var t: int = c[1]
	var b: int = c[2]
	var e := h - t - b - 600
	var tag := "H%d T%d B%d" % [h, t, b]
	print("-- ", tag)
	_reset()
	S.signed_count = 28  # 累積卡全可領:4 個領取鈕都顯示
	S.signed_today = false
	await _make_home(h, t, b)
	await _wait()
	_tap(home._bottom_buttons[0].get_global_rect().get_center())
	await _frames()
	await _wait()
	var ev = home._event
	var off: float = ev._body.position.y
	_eq(off, float(t - 24 + mini(e, 0)), tag + " content offset (T−24)+min(E,0)")
	# 節點尺寸 = 畫面高
	for n in [ev, ev._body, ev._checkin, ev._topup, ev._state_view, ev._toast]:
		_eq(n.size, Vector2(360, h), "%s %s size" % [tag, n.name])

	# ---- B:真的點「今日簽到」失敗 → toast ----
	_tap(ev._items[0].get_global_rect().get_center())
	await _frames()
	_eq(ev.page, L.Page.CHECKIN, tag + " A -> B")
	S.fail_next = 1
	_tap(ev._checkin._checkin.get_global_rect().get_center())
	await _wait()
	_eq(ev.toast_text, ev.TOAST_CHECKIN, tag + " B toast shown")
	var tr := _toast_screen(ev)
	_eq([tr.position.y, tr.end.y], [float(c[3]), float(c[3] + 32)], tag + " B toast y")
	_eq(absf(tr.get_center().x - 180) <= 1.0, true, tag + " B toast centered x (%s)" % tr)
	_no_overlap(tr, tag + " B")
	# 規格 B 表:E ≥ 115 時整個 toast 落在 28 格下緣與累積卡上緣之間
	var grid_bottom: float = off + ev._checkin.grid_y + 220
	var card_top: float = off + ev._checkin.card_y
	if e >= 115:
		_eq(tr.position.y >= grid_bottom and tr.end.y <= card_top, true,
			tag + " B toast within gap %d~%d (%s)" % [grid_bottom, card_top, tr])
	# toast 顯示中領取鈕都點得到(全部在活動頁範圍內)
	var got := []
	ev._checkin.claim_pressed.connect(func(tier: int) -> void: got.append(tier))
	for tier in L.TIERS:
		var r: Rect2 = ev._checkin._claims[tier].get_global_rect()
		_eq(ev.get_global_rect().encloses(r) and ev._checkin.get_global_rect().encloses(r), true,
			tag + " claim %d %s inside parents" % [tier, r])
		_tap(r.get_center())
		await _frames()
	_eq(got, [7, 14, 21, 28], tag + " all claim buttons tappable with toast")
	await _wait()
	await _close_popups()

	# ---- C:真的點購買失敗 → toast ----
	_tap(ev._back.get_global_rect().get_center())
	await _frames()
	_tap(ev._items[1].get_global_rect().get_center())
	await _frames()
	_eq(ev.page, L.Page.TOPUP, tag + " A -> C")
	_eq(ev.toast_text, "", tag + " switch hides toast")
	S.fail_next = 1
	_tap(ev._topup._buy.get_global_rect().get_center())
	await _wait()
	_eq(ev.toast_text, ev.TOAST_BUY, tag + " C toast shown")
	tr = _toast_screen(ev)
	_eq([tr.position.y, tr.end.y], [float(c[3]), float(c[3] + 32)], tag + " C toast y")
	_no_overlap(tr, tag + " C")
	_eq(ev.get_global_rect().encloses(ev._topup._buy.get_global_rect()), true, tag + " buy inside event page")

	# ---- D14:toast 顯示中重新載入失敗 ----
	_tap(ev._back.get_global_rect().get_center())
	await _frames()
	_tap(ev._items[0].get_global_rect().get_center())
	await _frames()
	ev._show_toast(ev.TOAST_CLAIM)
	S.fail_next = 1
	ev._fetch()
	await _frames()
	_eq([ev._state_view.visible, ev.toast_text, ev._toast_timer.is_stopped()], [true, "", true],
		tag + " entering D14 loading hides toast & stops timer")
	await _wait()
	_eq([ev.load_state, ev._retry.is_visible_in_tree(), ev.toast_text], [ev.Load.FAILED, true, ""], tag + " D14 failed")
	var rr: Rect2 = ev._retry.get_global_rect()
	_eq(rr, Rect2(120, c[4], 120, 44), tag + " retry rect")
	var panel := Rect2(ev._panel.position + Vector2(0, off), ev._panel.size)
	_eq(panel.encloses(rr), true, tag + " retry inside panel")
	# 面板中心 = 349 + E÷2 + 位移(E<0 以 0 計);重試鈕與 640 版相對面板中心的距離不變(352 − 349 = 3),允許四捨五入差 1
	var center := 349.0 + maxi(e, 0) / 2.0 + off
	_eq(absf(panel.get_center().y - center) <= 0.01, true, tag + " panel center %s (got %s)" % [center, panel.get_center().y])
	_eq(absf((rr.position.y - panel.get_center().y) - 3.0) <= 1.0, true, tag + " retry keeps 640 offset from panel center")
	# 左右置中於面板
	_eq(absf(rr.get_center().x - panel.get_center().x) <= 0.5, true, tag + " retry centered x")
	# D14 狀態下呼叫 toast 不顯示
	ev._show_toast(ev.TOAST_CHECKIN)
	await _frames()
	_eq(ev.toast_text, "", tag + " no toast in D14 failed")
	# 重試鈕(真的點)→ 再失敗:只更新「讀取失敗」,不出 toast
	S.fail_next = 1
	_tap(rr.get_center())
	await _frames()
	_eq(ev.load_state, ev.Load.LOADING, tag + " retry tappable")
	_eq(ev.toast_text, "", tag + " no toast while loading")
	await _wait()
	_eq([ev.load_state, ev.toast_text, ev._retry.visible], [ev.Load.FAILED, "", true], tag + " retry failed: text only, no toast")
	# 重試成功 → B 恢復
	_tap(ev._retry.get_global_rect().get_center())
	await _wait()
	_eq([ev.load_state, ev._checkin.visible, ev._state_view.visible], [ev.Load.LOADED, true, false], tag + " retry success shows B")
	await _close_popups()
	home._close_event()
	await _wait()


## D14 期間晚到的操作失敗不出 toast(重試前發出的簽到)
func _test_late_failure_in_d14() -> void:
	print("-- late failure in D14")
	for h in [640, 800]:
		_reset()
		await _make_home(h)
		await _wait()
		_tap(home._bottom_buttons[0].get_global_rect().get_center())
		await _frames()
		await _wait()
		var ev = home._event
		_tap(ev._items[0].get_global_rect().get_center())
		await _frames()
		S.delay_sec = 0.3
		S.fail_next = 1
		_tap(ev._checkin._checkin.get_global_rect().get_center())
		await _frames()
		S.fail_next = 1
		ev._fetch()  # 進入 D14 載入,之後也失敗
		await _frames()
		_eq(ev._state_view.visible, true, "H%d in D14" % h)
		await _wait(0.5)
		_eq([ev.load_state, ev.toast_text], [ev.Load.FAILED, ""], "H%d late checkin failure in D14: no toast" % h)
		S.delay_sec = DELAY
		home._close_event()
		await _wait()


## 活動頁開著時改畫面大小:各圖層尺寸跟著畫面高
func _test_resize_sizes() -> void:
	print("-- resize sizes")
	_reset()
	await _make_home(800)
	await _wait()
	_tap(home._bottom_buttons[0].get_global_rect().get_center())
	await _frames()
	await _wait()
	var ev = home._event
	for c in [[640, 24, 16], [840, 24, 16], [1000, 40, 34], [700, 24, 16], [800, 24, 16]]:
		await _resize(c[0], c[1], c[2])
		for n in [ev, ev._body, ev._checkin, ev._topup, ev._state_view, ev._toast]:
			_eq(n.size, Vector2(360, c[0]), "resize H%d %s size" % [c[0], n.name])
		ev.show_page(L.Page.CHECKIN)
		ev._show_toast(ev.TOAST_CLAIM)
		await _frames()
		var e: int = c[0] - c[1] - c[2] - 600
		var exp_y: int = 436 + int(floor(0.4 * maxi(e, 0) + 0.5)) + c[1] - 24 + mini(e, 0)
		_eq(_toast_screen(ev).position.y, float(exp_y), "resize H%d T%d B%d toast y" % c)
		ev.show_page(L.Page.LIST)
	home._close_event()
	await _wait()
