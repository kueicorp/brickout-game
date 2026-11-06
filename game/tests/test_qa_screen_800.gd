extends SceneTree
## QA:基準 360×800 版面(docs/design/layout/screen-size-800.md S01、S02、S03、S06、S07)獨立驗證。執行:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path game --script res://tests/test_qa_screen_800.gd
## 期望值以規格公式 / 座標表另外計算,不呼叫被測函式求期望值。有任何失敗時結束碼為 1。

const HOME_SIM_PATH := "res://tests/home_sim.gd"
const S := preload("res://scripts/event_service.gd")
const L := preload("res://scripts/event_logic.gd")
const HL := preload("res://scripts/home_logic.gd")
const DELAY := 0.05
const WAIT := 0.15

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


## 不重建首頁,只換畫面大小 / 安全區(模擬旋轉、分割畫面、視窗縮放)
func _resize(h: int, t := 24, b := 16) -> void:
	root.size = Vector2i(360, h)
	home.sim_view = Vector2(360, h)
	home.sim_safe = Vector2i(t, b)
	home._apply_layout()
	await _frames()


func _reset() -> void:
	S.reset()
	S.delay_sec = DELAY


## 規格的四捨五入(.5 進位),以商 / 餘數實作,與被測的 _round_div 不同寫法
func _round_pct(num: int, den: int) -> int:
	@warning_ignore("integer_division")
	var q := num / den
	var r := num % den
	return q + (1 if r * 2 >= den else 0)


func _run() -> void:
	_test_rounding_brute()
	_test_layout_invariants()
	_reset()
	await _make_home()
	await _wait()
	await _test_home_nodes()
	await _test_event_640_baseline()
	await _test_resize_while_open()
	await _test_claim_tappable_tall()
	await _test_state_view_tall()
	if home:
		home.queue_free()
		await _frames()
	S.reset()
	print("PASSED %d, FAILED %d" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


## E = 0~1200:B 15/30/30/餘數、C 累計切點 round(kE/5)、首頁 round(0.6E) 都是 .5 進位;a4 ≥ 0
func _test_rounding_brute() -> void:
	var bad := []
	for e in range(0, 1201):
		var a := L.checkin_gaps(e)
		var a1 := _round_pct(15 * e, 100)
		var a2 := _round_pct(30 * e, 100)
		if a != ([a1, a2, a2, e - a1 - 2 * a2] as Array[int]) or a[3] < 0:
			bad.append("B E%d %s" % [e, a])
		var c := L.topup_cuts(e)
		for k in range(1, 5):
			if c[k - 1] != _round_pct(k * e, 5):
				bad.append("C E%d k%d %d" % [e, k, c[k - 1]])
		if c[3] > e:
			bad.append("C E%d c4 > E" % e)
		var lay := HL.home_layout(640 + e, 24, 16)
		if lay.add_top != _round_pct(6 * e, 10) or lay.add_bottom != e - lay.add_top:
			bad.append("home E%d %d/%d" % [e, lay.add_top, lay.add_bottom])
	_eq(bad.slice(0, 10), [], "rounding brute force E 0..1200 (%d bad)" % bad.size())


## h 560~1100 × T {24,32,40,48,60} × B {16,24,34,48}:S02 / S07 外框與 B、C 內部不變量
func _test_layout_invariants() -> void:
	var bad := []
	for h in range(560, 1101):
		for t in [24, 32, 40, 48, 60]:
			for b in [16, 24, 34, 48]:
				var avail: int = h - t - b
				var e := avail - 600
				var lay := L.event_layout(h, t, b)
				var tag := "h%d T%d B%d" % [h, t, b]
				var banner: int = h - b - 50
				if lay.banner != banner:
					bad.append(tag + " banner")
				var panel_y: int = lay.offset + 132
				var panel_h: int = 434 + lay.extra
				if banner - (panel_y + panel_h) != 8:
					bad.append(tag + " panel-banner gap")
				if e >= 0:
					# S02 / S07:上方貼 T,E 全加在面板
					if panel_y != t + 108 or panel_h != 434 + e or lay.offset + 80 + lay.header_shift != t + 56:
						bad.append(tag + " E>=0 frame")
				else:
					# README 第 988 行(舊規則):面板 434 貼 banner;等同舊 offset = h − B − 624
					if panel_h != 434 or lay.offset != h - b - 624:
						bad.append(tag + " E<0 frame")
					if lay.header_shift != clampi(592 - avail, 0, 8):
						bad.append(tag + " E<0 shift")
				# B:累積卡下緣 + g4 = 面板下緣;四段 ≥ 640 基準
				var ex: int = lay.extra
				var g := L.checkin_gaps(ex)
				var card_bottom: int = lay.offset + 428 + g[0] + g[1] + g[2] + 137
				if card_bottom + 1 + g[3] != panel_y + panel_h:
					bad.append(tag + " B card bottom + g4")
				# C:購買鈕下緣 + 34 + (E − c4) = 面板下緣
				var c := L.topup_cuts(ex)
				var buy_bottom: int = lay.offset + 476 + c[3] + 56
				if buy_bottom + 34 + (ex - c[3]) != panel_y + panel_h:
					bad.append(tag + " C buy bottom")
	_eq(bad.slice(0, 10), [], "layout invariants (%d bad)" % bad.size())


## S01 / S07:首頁實際節點位置(含 T=40、B=34、700、1000)
func _test_home_nodes() -> void:
	# [h, T, B, D02, D15, D06, 4 按鈕, banner];T24/B16 抄規格首頁關鍵座標表,其餘依公式手算
	for c in [
		[640, 24, 16, 80, 140, 388, 492, 574], [700, 24, 16, 116, 176, 424, 552, 634],
		[780, 24, 16, 164, 224, 472, 632, 714], [800, 24, 16, 176, 236, 484, 652, 734],
		[840, 24, 16, 200, 260, 508, 692, 774], [800, 40, 16, 182, 242, 490, 652, 734],
		[800, 24, 34, 165, 225, 473, 634, 716], [1000, 24, 16, 296, 356, 604, 852, 934],
	]:
		_reset()
		await _make_home(c[0], c[1], c[2])
		var tag := "home H%d T%d B%d" % [c[0], c[1], c[2]]
		_eq(home._d01_buttons[0].position.y, float(c[1] + 4), tag + " D01")
		_eq([home._title.position.y, home._map.position.y, home._start.position.y],
			[float(c[3]), float(c[4]), float(c[5])], tag + " D02 / D15 / D06")
		_eq(home._bottom_buttons[0].position.y, float(c[6]), tag + " bottom buttons")
		_eq(home._bottom_bg.position.y, float(c[6] - 4), tag + " bottom bg")
		_eq(HL.home_layout(c[0], c[1], c[2]).banner, c[7], tag + " banner")
		# 底部列 80 高下緣與 banner 間隔 6(640 版 568→574)
		_eq(c[7] - (c[6] - 4 + 80), 6, tag + " bottom bar to banner")
		# 開始鈕可點
		_eq(home._start.get_global_rect().size.y >= 44.0, true, tag + " start size")


## 640(E = 0)時活動頁每個元件都等於原 640 版的常數(event-screen.md 座標)
func _test_event_640_baseline() -> void:
	_reset()
	await _make_home(640)
	await _wait()
	home._open_event()
	await _wait()
	var ev = home._event
	_eq(ev._body.position.y, 0.0, "640 body offset 0")
	_eq(ev._panel, Rect2(8, 132, 344, 434), "640 panel")
	_eq(ev._back.get_global_rect(), Rect2(8, 80, 44, 44), "640 back")
	_eq(ev._items[0].get_global_rect(), Rect2(14, 138, 332, 72), "640 item 1")
	var ck = ev._checkin
	_eq([ck.summary_y, ck.grid_y, ck.card_y], [136, 194, 428], "640 B blocks")
	_eq(ck._checkin.get_global_rect(), Rect2(250, 136, 96, 44), "640 B checkin btn")
	for i in 4:
		_eq(ck._claims[L.TIERS[i]].get_global_rect(), Rect2(18 + i * 84, 518, 72, 44), "640 B claim %d" % i)
	var tp = ev._topup
	_eq([tp.title_y, tp.rows_y, tp.note_y], [138, 188, 400], "640 C blocks")
	_eq(tp._buy.get_global_rect(), Rect2(72, 476, 216, 56), "640 C buy")
	_eq(ev._retry.get_global_rect(), Rect2(120, 352, 120, 44), "640 retry")
	home._close_event()
	await _wait()


## 活動頁開著(B 頁)時改畫面大小:版面重新計算、不累加;回到 640 等於原值
func _test_resize_while_open() -> void:
	_reset()
	await _make_home(800)
	await _wait()
	home._open_event()
	await _wait()
	var ev = home._event
	ev.show_page(L.Page.CHECKIN)
	await _frames()
	for c in [[800, 24, 16, 548, 604], [640, 24, 16, 428, 476], [840, 24, 16, 578, 636],
			[800, 40, 16, 552, 607], [800, 24, 16, 548, 604], [800, 24, 16, 548, 604]]:
		await _resize(c[0], c[1], c[2])
		var tag := "resize H%d T%d B%d" % [c[0], c[1], c[2]]
		_eq(ev._body.position.y + ev._checkin.card_y, float(c[3]), tag + " B card y")
		_eq(ev._topup._buy.get_global_rect().position.y, float(c[4]), tag + " C buy y")
		_eq(ev._panel.size.y, float(434 + c[0] - c[1] - c[2] - 600), tag + " panel h")
		_eq(ev._back.get_global_rect().position.y, float(c[1] + 56), tag + " back y")
	home._close_event()
	await _wait()


## 父節點(活動頁 / B 頁)尺寸仍是 360×640;640 以下的領取鈕、購買鈕要真的點得到
func _test_claim_tappable_tall() -> void:
	for h in [840, 1000]:
		_reset()
		S.signed_count = 28
		S.signed_today = true
		await _make_home(h)
		await _wait()
		home._open_event()
		await _wait()
		var ev = home._event
		ev.show_page(L.Page.CHECKIN)
		await _frames()
		var got := []
		ev._checkin.claim_pressed.connect(func(tier: int) -> void: got.append(tier))
		for i in 4:
			var r: Rect2 = ev._checkin._claims[L.TIERS[i]].get_global_rect()
			_eq(r.position.y > 640.0, true, "H%d claim %d below 640 (%s)" % [h, i, r])
			_tap(r.get_center())
			await _frames()
		_eq(got, [7, 14, 21, 28], "H%d all claim buttons tappable" % h)
		await _wait()
		while home._popup.is_open():
			home.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
			await _frames()
		ev.show_page(L.Page.TOPUP)
		await _frames()
		var buy: Rect2 = ev._topup._buy.get_global_rect()
		S.cancel_next = true
		_tap(buy.get_center())
		await _frames()
		_eq(ev._topup._buy.text, "處理中…", "H%d buy tappable at %s" % [h, buy])
		await _wait()
		# 面板下緣 + 8 = banner(Q4 不設上限)
		_eq(h - 16 - 50 - (ev._body.position.y + ev._panel.end.y), 8.0, "H%d panel to banner" % h)
		home._close_event()
		await _wait()


## D14 載入失敗:重試鈕在加高面板內、可點(位置未重新置中為已知 shortcut,只記錄實際值)
func _test_state_view_tall() -> void:
	_reset()
	await _make_home(800)
	await _wait()
	S.fail_next = 1
	home._open_event()
	await _wait()
	var ev = home._event
	ev.show_page(L.Page.CHECKIN)
	await _frames()
	_eq(ev.load_state, ev.Load.FAILED, "800 load failed")
	var r: Rect2 = ev._retry.get_global_rect()
	var panel := Rect2(ev._panel.position + Vector2(0, ev._body.position.y), ev._panel.size)
	print("   800 retry rect %s, panel %s, panel center y %d" % [r, panel, panel.get_center().y])
	_eq(panel.encloses(r), true, "800 retry inside panel")
	_tap(r.get_center())
	await _frames()
	_eq(ev.load_state, ev.Load.LOADING, "800 retry tappable")
	await _wait()
	home._close_event()
	await _wait()
