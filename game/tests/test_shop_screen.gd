extends SceneTree
## 商城互動測試:從首頁進商城,用 push_input 模擬點擊 / 拖動,驗證 D01~D28:
## 進入與分頁、資源列捷徑、版面座標(640 / 800 / 840 / T=40 / B=34)、捲動、Google Play 流程(成功、取消、失敗、離線、
## 處理中、逾時、待處理、驗證失敗、補發)、金塊購買(確認、處理中、不足、去儲值、愛心上限、失敗)、道具詳情、看廣告、紅點、返回鍵。執行:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path game --script res://tests/test_shop_screen.gd
## 有任何失敗時結束碼為 1。

const HOME_SIM_PATH := "res://tests/home_sim.gd"
const S := preload("res://scripts/shop_service.gd")
const ES := preload("res://scripts/event_service.gd")
const L := preload("res://scripts/shop_logic.gd")
const DELAY := 0.05
const WAIT := 0.15

const SHOP_BTN := Vector2(136, 528)
const BACK_BTN := Vector2(30, 102)
const HEART_ICON := Vector2(30, 50)
const COIN_ICON := Vector2(98, 50)
const GOLD_ICON := Vector2(194, 50)
## 分頁籤中心(y 138~182)
const TAB_CENTERS := [Vector2(54, 160), Vector2(138, 160), Vector2(222, 160), Vector2(306, 160)]
## 內容區原點(640、T=24)
const CONTENT := Vector2(14, 190)

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


func _drag(from: Vector2, to: Vector2) -> void:
	_move(from, false)
	_button(from, true)
	for i in range(1, 5):
		_move(from.lerp(to, i / 4.0))
	_button(to, false)


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


func _popup():
	return home._popup


## 內容座標 → 畫面座標(未捲動、640、T=24)
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


func _run() -> void:
	_reset_service()
	await _make_home()
	await _test_home_badge()
	await _test_enter_and_tabs()
	await _test_layout_640()
	await _test_scroll()
	await _test_iap()
	await _test_gold_buy()
	await _test_detail()
	await _test_free()
	await _test_load_failure()
	await _test_back()
	for c in HEIGHT_CASES:
		await _check_height(c)
	if home:
		home.queue_free()
		await _frames()
	_reset_service()
	print("PASSED %d, FAILED %d" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


## D17:資料到達前不顯示;免費任一項有次數才亮;讀取失敗不顯示
func _test_home_badge() -> void:
	var shop_btn = home._bottom_buttons[1]
	_eq(shop_btn.badge_pos, Vector2(52, 2), "D17 badge position in cell")
	home._refresh_badge()
	_eq(shop_btn.badge, false, "D17 hidden before data")
	await _wait()
	_eq(shop_btn.badge, true, "D17 on: free left")
	S.free_left.assign([0, 0, 0, 0])
	home._refresh_badge()
	await _wait()
	_eq(shop_btn.badge, false, "D17 off: all used")
	S.free_left.assign([0, 0, 0, 1])
	home._refresh_badge()
	await _wait()
	_eq(shop_btn.badge, true, "D17 on: item chest left")
	S.fail_next = 1
	home._refresh_badge()
	await _wait()
	_eq(shop_btn.badge, false, "D17 fetch failure -> off")
	S.reset()
	S.delay_sec = DELAY
	home._refresh_badge()
	await _wait()


## D01、D02、D06、D13、D18
func _test_enter_and_tabs() -> void:
	_tap(SHOP_BTN)
	await _frames()
	var shop = _shop()
	_eq(shop != null, true, "商城 button opens shop")
	_eq(shop.tab, L.Tab.TOPUP, "default tab TOPUP")
	_eq([shop.load_state, shop._state_view.visible, _page().visible], [shop.Load.LOADING, true, false], "D13 loading")
	_eq(shop._tabs[L.Tab.FREE].badge, false, "D18 hidden before data")
	_eq(home._map.visible or home._start.visible or home._bottom_buttons[1].visible, false, "home-only nodes hidden")
	_eq(home._resources.visible, true, "resource bar shared")
	await _wait()
	_eq([shop.load_state, _page().visible, shop._state_view.visible], [shop.Load.LOADED, true, false], "loaded")
	_eq(shop._tabs[L.Tab.FREE].badge, true, "D18 on")
	# 分頁籤外觀:選中金底黑字、未選深底白字 + 框
	var t0 = shop._tabs[0]
	var t1 = shop._tabs[1]
	_eq([t0.fill, t0.text_color, t0.border.a], [Color("#F4C430"), Color.BLACK, 0.0], "selected tab look")
	_eq([t1.fill, t1.text_color, t1.border], [Color("#222B3A"), Color.WHITE, Color("#5D6D7E")], "unselected tab look")
	_eq([t0.text, t1.text, shop._tabs[2].text, shop._tabs[3].text], ["儲值", "道具", "愛心金幣", "免費"], "tab labels")
	for i in 4:
		_eq(shop._tabs[i].get_global_rect(), Rect2(14 + 84 * i, 138, 80, 44), "D06 tab %d rect" % i)
	for i in [1, 2, 3, 0]:
		_tap(TAB_CENTERS[i])
		await _frames()
		_eq(shop.tab, i, "tap tab %d" % i)
	# D02 資源列:愛心 / 金幣 → 愛心金幣;金塊 → 儲值;不重開商城
	_tap(HEART_ICON)
	await _frames()
	_eq([home._shop == shop, shop.tab], [true, L.Tab.HEART_COIN], "heart icon -> 愛心金幣")
	_tap(GOLD_ICON)
	await _frames()
	_eq(shop.tab, L.Tab.TOPUP, "gold icon -> 儲值")
	_tap(COIN_ICON)
	await _frames()
	_eq([home._shop == shop, shop.tab], [true, L.Tab.HEART_COIN], "coin icon -> 愛心金幣")
	_tap(TAB_CENTERS[0])
	await _frames()


## D03~D12、D15、D16 座標(640、T=24,畫面座標 = 內容座標 + (14, 190))
func _test_layout_640() -> void:
	var shop = _shop()
	_eq(shop._back.get_global_rect(), Rect2(8, 80, 44, 44), "D03 back")
	_eq(shop._panel, Rect2(8, 132, 344, 434), "D05 panel")
	_eq(_page().get_global_rect(), Rect2(14, 190, 337, 370), "D07 content area (incl. scrollbar)")
	var rects: Array = _page().target_rects()
	_eq(rects[0], Rect2(0, 0, 162, 104), "D08 card 0")
	_eq(rects[7], Rect2(170, 336, 162, 104), "D08 card 7")
	_eq(rects[8], Rect2(0, 448, 332, 72), "D09 remove ads")
	shop.select_tab(L.Tab.ITEMS)
	rects = _page().target_rects()
	_eq(rects[0], Rect2(0, 0, 332, 80), "D10 bundle")
	_eq([rects[1], rects[2], rects[3]], [Rect2(0, 88, 148, 64), Rect2(156, 96, 80, 48), Rect2(240, 96, 80, 48)], "D11 row 0")
	_eq(rects[28], Rect2(0, 736, 148, 64), "D11 row 9 info (y 926 screen)")
	shop.select_tab(L.Tab.HEART_COIN)
	rects = _page().target_rects()
	_eq([rects[0], rects[3]], [Rect2(0, 28, 162, 88), Rect2(170, 124, 162, 88)], "D15 heart cards")
	_eq([rects[4], rects[8]], [Rect2(0, 248, 162, 88), Rect2(0, 440, 162, 88)], "D16 coin cards (5th left)")
	shop.select_tab(L.Tab.FREE)
	rects = _page().target_rects()
	for i in 4:
		_eq(rects[i], Rect2(228, 92 * i + 20, 96, 44), "D12 button %d" % i)
	# 觸控範圍 ≥ 44×44
	for t in 4:
		shop.select_tab(t)
		for r: Rect2 in _page().target_rects():
			_eq(r.size.x >= 44 and r.size.y >= 44, true, "tab %d target %s >= 44" % [t, r])
	shop.select_tab(L.Tab.TOPUP)


## D07:拖動 > 8px 捲動且不觸發點擊;切分頁回頂端;不能捲的分頁不動
func _test_scroll() -> void:
	var shop = _shop()
	shop.select_tab(L.Tab.ITEMS)
	await _frames()
	_drag(Vector2(100, 500), Vector2(100, 300))
	await _frames()
	_eq(_page().scroll, 200, "drag up 200 -> scroll 200")
	_eq(_dialog().is_open(), false, "drag does not tap")
	_drag(Vector2(100, 500), Vector2(100, 100))
	await _frames()
	_eq(_page().scroll, 430, "scroll clamps to 800 − 370")
	# 捲動後點第 10 列的單買
	_tap(_target_center("item:9:1"))
	await _frames()
	_eq([_dialog().mode, _dialog()._product.id], [_dialog().Mode.CONFIRM, "item:9:1"], "tap after scroll hits row 10")
	await _back_key()
	# 起點在資訊區與單買鈕之間的空隙(內容 x 152),不會變成點擊
	_drag(Vector2(166, 300), Vector2(166, 305))
	await _frames()
	_eq([_page().scroll, _dialog().is_open()], [430, false], "5px move is not a scroll")
	shop.select_tab(L.Tab.FREE)
	_eq(_page().scroll, 0, "switch tab -> top")
	_drag(Vector2(100, 500), Vector2(100, 300))
	await _frames()
	_eq(_page().scroll, 0, "free tab does not scroll")
	shop.select_tab(L.Tab.HEART_COIN)
	await _frames()
	_drag(Vector2(100, 500), Vector2(100, 100))
	await _frames()
	_eq(_page().scroll, 158, "heart/coin max scroll 158 at 640 (tracking %s)" % _page()._tracking)
	shop.select_tab(L.Tab.TOPUP)


## D19~D22
func _test_iap() -> void:
	var shop = _shop()
	var gold0: int = ES.wallet.gold
	# 成功:處理中 → 已獲得;關框後資源列更新(延遲拉長,確保驗證回應前檢查得到處理中)
	S.delay_sec = 0.1
	_tap(_target_center("gold:90"))
	await _wait(0.12)
	_eq(_dialog().mode, _dialog().Mode.PROCESSING, "D20 processing after payment")
	_eq(_dialog().frame_rect(), Rect2(32, 276, 296, 88), "D20 frame (640)")
	await _back_key()
	_eq(_dialog().mode, _dialog().Mode.PROCESSING, "D20 back key ignored")
	_tap(BACK_BTN)
	await _frames()
	_eq(home._shop, shop, "D20 mask blocks back button")
	await _wait()
	S.delay_sec = DELAY
	_eq(_dialog().is_open(), false, "D20 closed after verify")
	_eq([_popup().current().title, _popup().current().rewards], ["已獲得", [["gold", 90], ["silver", 9]]], "D21 popup")
	_eq(_popup().frame_rect().size.y, 168.0, "D21 frame 168")
	await _back_key()
	_eq(home._resources.values[2], gold0 + 90, "D21 gold updated on close")
	# 取消:不顯示任何東西
	S.play_result = "canceled"
	_tap(_target_center("gold:30"))
	await _wait()
	_eq([_dialog().is_open(), _popup().is_open(), shop.toast_text], [false, false, ""], "D19 cancel silent")
	# 付款失敗 / 離線:toast
	S.play_result = "failed"
	_tap(_target_center("gold:30"))
	await _wait()
	_eq(shop.toast_text, L.TOAST_BUY_FAIL, "D19 payment failed toast")
	_eq(shop.toast_rect().position.y, 436.0, "toast y 436 at 640")
	S.offline = true
	_tap(_target_center("gold:30"))
	await _wait()
	_eq(shop.toast_text, L.TOAST_NO_NET, "D19 offline toast")
	S.offline = false
	# 驗證失敗 → D22 (a);該商品不可再點
	S.verify_result = "fail"
	_tap(_target_center("gold:150"))
	await _wait(0.25)
	_eq([_popup().current().title, _popup().current().lines], ["付款處理中", ["付款已完成,獎勵還在確認中。"]], "D22 (a)")
	_eq(_popup().frame_rect().size.y, 150.0, "D22 (a) frame 150")
	await _back_key()
	_eq(_has_target("gold:150"), false, "D22 product disabled")
	# Google Play 待處理 → D22 (c)
	S.play_result = "pending"
	_tap(_target_center("gold:300"))
	await _wait()
	_eq([_popup().current().lines.size(), _popup().frame_rect().size.y], [2, 172.0], "D22 (c)")
	await _back_key()
	_eq(_has_target("gold:300"), false, "D22 (c) product disabled")
	# 逾時 → D22 (b)
	shop.verify_timeout_sec = 0.2
	S.verify_result = "hang"
	_tap(_target_center("gold:590"))
	await _wait(0.1)
	_eq(_dialog().mode, _dialog().Mode.PROCESSING, "hang: still processing")
	await _wait(0.25)
	_eq([_dialog().is_open(), _popup().current().title], [false, "付款處理中"], "D20 timeout -> D22 (b)")
	await _back_key()
	_eq(_has_target("gold:590"), false, "timeout product disabled")
	# 補發:回首頁再進商城 → 已獲得(補發訂單),卡片恢復
	S.simulate_grant_pending()
	await _back_key()
	_eq(home._shop, null, "back key closes shop")
	await _wait()
	await _close_all_popups()
	await _open_shop()
	await _close_all_popups()
	_eq([_has_target("gold:150"), _has_target("gold:300"), _has_target("gold:590")], [true, true, true], "reissued products enabled again")
	# 移除廣告(640 高時在可見範圍下方,先捲到底)
	_drag(Vector2(100, 500), Vector2(100, 300))
	await _frames()
	_eq(_page().scroll, 150, "topup max scroll 150 at 640")
	_tap(_target_center("remove_ads"))
	await _wait(0.25)
	_eq([_popup().current().rewards, _popup().current().lines], [[["silver", 100]], ["廣告已移除"]], "D21 remove ads")
	_eq(_popup().frame_rect().size.y, 190.0, "D21 remove ads frame 190")
	_eq(FakeData.ads_removed, true, "ads removed flag")
	await _back_key()
	_eq(_has_target("remove_ads"), false, "D09 bought: not tappable")


## D23~D26
func _test_gold_buy() -> void:
	var shop = _shop()
	var w: Dictionary = ES.wallet
	w.silver = 300
	w.gold = 50
	w.heart = 92
	shop._fetch()
	await _wait()
	shop.select_tab(L.Tab.ITEMS)
	await _frames()
	_tap(_target_center("item:0:1"))
	await _frames()
	var d = _dialog()
	_eq(d.mode, d.Mode.CONFIRM, "D23 confirm opens")
	_eq(d.frame_rect(), Rect2(32, 185, 296, 270), "D23 1 row frame (640)")
	_eq([d._secondary.get_global_rect(), d._primary.get_global_rect()], [Rect2(48, 395, 128, 44), Rect2(184, 395, 128, 44)], "D23 buttons")
	# 取消 / 返回鍵 / 點遮罩
	_tap(Vector2(180, 100))
	await _frames()
	_eq(d.is_open(), true, "D23 mask tap does not close")
	_tap(d._secondary.get_global_rect().get_center())
	await _frames()
	_eq(d.is_open(), false, "D23 cancel closes")
	_tap(_target_center("item:0:1"))
	await _frames()
	_tap(d._primary.get_global_rect().get_center())
	await _frames()
	_eq([d.busy, d._primary.text, d._primary.disabled, d._secondary.disabled], [true, "處理中…", true, true], "D23 processing")
	await _back_key()
	_eq(d.is_open(), true, "D23 processing: back key ignored")
	await _wait()
	_eq([d.is_open(), _popup().current().lines, _popup().frame_rect().size.y], [false, ["額外血量 ×1"], 150.0], "D26 item popup")
	await _back_key()
	_eq(home._resources.values[3], 270, "silver charged first, bar updated")
	# 混扣 2 列:銀塊 270 + 金塊 30 = 300
	_tap(_target_center("item:0:11"))
	await _frames()
	_eq([d._split(), d.frame_rect().size.y], [[270, 30], 298.0], "D23 2 rows")
	await _back_key()
	# D24:銀塊 + 金塊不足 → 不先開確認框;去儲值切分頁
	_tap(_target_center("bundle"))
	await _frames()
	_eq([d.mode, d.frame_rect()], [d.Mode.SHORT, Rect2(32, 223, 296, 194)], "D24 short opens directly")
	_tap(d._primary.get_global_rect().get_center())
	await _frames()
	_eq([d.is_open(), shop.tab, _page().scroll], [false, L.Tab.TOPUP, 0], "D24 去儲值 -> TOPUP")
	# 後端回金塊不足(本機餘額過期)→ D24
	shop.select_tab(L.Tab.ITEMS)
	await _frames()
	_tap(_target_center("item:1:11"))
	await _frames()
	w.silver = 0
	w.gold = 0
	_tap(d._primary.get_global_rect().get_center())
	await _wait()
	_eq(d.mode, d.Mode.SHORT, "server short -> D24")
	_tap(d._secondary.get_global_rect().get_center())
	await _frames()
	_eq([d.is_open(), shop.tab], [false, L.Tab.ITEMS], "D24 cancel stays")
	# D15 灰卡:持有 92 → 10、20 不可點
	w.gold = 2000
	shop._fetch()
	await _wait()
	shop.select_tab(L.Tab.HEART_COIN)
	await _frames()
	_eq([_has_target("heart:1"), _has_target("heart:5"), _has_target("heart:10"), _has_target("heart:20")], [true, true, false, false], "D15 over cap at 92")
	_tap(_at(Vector2(251, 168)))
	await _frames()
	_eq([d.is_open(), _popup().is_open()], [false, false], "gray card: no reaction")
	# 確認框愛心說明;後端回超過上限 → D25
	_tap(_target_center("heart:5"))
	await _frames()
	_eq(d._product.id, "heart:5", "D23 heart")
	w.heart = 99
	_tap(d._primary.get_global_rect().get_center())
	await _wait()
	_eq([d.is_open(), _popup().current().title], [false, "愛心會超過上限"], "server heart cap -> D25")
	await _back_key()
	_eq([_has_target("heart:1"), _has_target("coin:1000")], [false, true], "D15 full at 99, coins unaffected")
	# 金幣購買成功
	_tap(_target_center("coin:5000"))
	await _frames()
	_tap(d._primary.get_global_rect().get_center())
	await _wait()
	_eq(_popup().current().rewards, [["coin", 5000]], "D26 coin popup")
	await _back_key()
	# 失敗 / 離線 toast
	S.fail_next = 1
	_tap(_target_center("coin:1000"))
	await _frames()
	_tap(d._primary.get_global_rect().get_center())
	await _wait()
	_eq([d.is_open(), shop.toast_text], [false, L.TOAST_BUY_FAIL], "D23 failure toast")
	S.offline = true
	_tap(_target_center("coin:1000"))
	await _frames()
	_tap(d._primary.get_global_rect().get_center())
	await _wait()
	_eq(shop.toast_text, L.TOAST_NO_NET, "D23 offline toast")
	S.offline = false
	w.heart = 92
	shop._fetch()
	await _wait()


## D27、D28
func _test_detail() -> void:
	var shop = _shop()
	var d = _dialog()
	shop.select_tab(L.Tab.ITEMS)
	await _frames()
	_tap(_target_center("detail:3"))
	await _frames()
	_eq([d.mode, d._item, d.frame_rect()], [d.Mode.DETAIL, 3, Rect2(32, 211, 296, 218)], "D27 暗殺 (2 lines)")
	_eq(d._secondary.get_global_rect(), Rect2(72, 211 + 158, 216, 44), "D27 close button")
	_eq(d._primary.visible, false, "D27 no buy button")
	_tap(Vector2(180, 100))
	await _frames()
	_eq(d.is_open(), false, "D27 mask tap closes")
	_tap(_target_center("detail:1"))
	await _frames()
	_eq(d.frame_rect().size.y, 240.0, "D27 3 lines")
	_tap(d._secondary.get_global_rect().get_center())
	await _frames()
	_eq(d.is_open(), false, "D27 close button")
	_tap(_target_center("detail:0"))
	await _frames()
	await _back_key()
	_eq([d.is_open(), home._shop != null], [false, true], "D27 back key closes only the dialog")


## D12、D18
func _test_free() -> void:
	var shop = _shop()
	shop.select_tab(L.Tab.FREE)
	await _frames()
	_tap(_target_center("ad:1"))
	await _frames()
	_eq([shop._ad_busy, _has_target("ad:1")], [1, false], "D12 loading: not tappable")
	await _wait()
	_eq([_popup().current().rewards[0][0], shop.status.free_left[1]], ["coin", 4], "D12 coin chest")
	await _back_key()
	S.fail_next = 1
	_tap(_target_center("ad:2"))
	await _wait()
	_eq([shop._ad_busy, shop.toast_text, shop.status.free_left[2]], [-1, L.TOAST_AD_FAIL, 5], "D12 ad failure")
	# 愛心 99 照常可看
	ES.wallet.heart = 99
	_tap(_target_center("ad:0"))
	await _wait()
	_eq(_popup().current().rewards, [["heart", 0]], "D12 heart at 99 -> actual 0")
	await _back_key()
	_tap(_target_center("ad:3"))
	await _wait()
	await _back_key()
	_eq(_has_target("ad:3"), false, "D12 used up: 明天再來")
	_eq(shop._tabs[L.Tab.FREE].badge, true, "D18 still on")
	S.free_left.assign([0, 0, 0, 0])
	shop._fetch()
	await _wait()
	_eq(shop._tabs[L.Tab.FREE].badge, false, "D18 off when all used")
	await _back_key()
	await _wait()
	_eq(home._bottom_buttons[1].badge, false, "D17 synced off after return")
	S.free_left.assign([20, 5, 5, 1])
	ES.wallet.heart = 92
	await _open_shop()


## D13:讀取失敗 → 讀取失敗 + 重試;返回鈕、分頁籤仍可用;紅點不顯示
func _test_load_failure() -> void:
	await _back_key()
	await _wait()
	S.fail_next = 1
	await _open_shop()
	var shop = _shop()
	_eq([shop.load_state, shop._retry.visible, _page().visible, shop._tabs[3].badge], [shop.Load.FAILED, true, false, false], "D13 failed")
	_tap(TAB_CENTERS[1])
	await _frames()
	_eq(shop.tab, L.Tab.ITEMS, "tabs work on failure")
	_eq(shop._retry.get_global_rect(), Rect2(120, 378, 120, 44), "retry rect 640")
	_tap(shop._retry.get_global_rect().get_center())
	await _frames()
	_eq(shop.load_state, shop.Load.LOADING, "retry -> loading")
	await _wait()
	_eq(shop.load_state, shop.Load.LOADED, "retry -> loaded")


## 返回鈕、返回鍵
func _test_back() -> void:
	_tap(BACK_BTN)
	await _frames()
	_eq(home._shop, null, "D03 back button -> home")
	_eq(home._map.visible and home._bottom_buttons[1].visible, true, "home restored")
	await _open_shop()
	await _back_key()
	_eq(home._shop, null, "back key -> home")
	await _wait()
	# 看廣告載入中、Google Play 付款中:返回鍵與返回鈕都不反應;結果回來照常跳框,之後可離開
	await _open_shop()
	var shop = _shop()
	shop.select_tab(L.Tab.FREE)
	await _frames()
	_tap(_target_center("ad:1"))
	await _frames()
	# 先確認按返回的當下真的在廣告載入中,否則「沒關」可能只是時機不對
	_eq(shop._ad_busy, 1, "ad loading: busy before back key")
	await _back_key()
	# 返回鍵若誤關商城,shop 已被釋放,先檢查有效再讀欄位,讓測試以斷言失敗呈現而不是中斷
	_eq(is_instance_valid(shop) and shop._ad_busy == 1, true, "ad loading: busy before back button")
	_tap(BACK_BTN)
	await _frames()
	# 被釋放的物件與 null 比較會相等,要另外確認 shop 仍有效
	_eq(is_instance_valid(shop) and home._shop == shop, true, "ad loading: back ignored")
	await _wait()
	_eq(_popup().current().get("title", ""), "已獲得", "ad loading: popup after result")
	await _close_all_popups()
	shop.select_tab(L.Tab.TOPUP)
	await _frames()
	_tap(_target_center("gold:30"))
	await _frames()
	# 付款結果 DELAY 秒後回來就會進 D20,要確認按返回的當下還在「付款中」、D20 尚未開
	_eq([shop._iap_busy, _dialog().is_open()], [true, false], "Google Play paying: paying before back key")
	await _back_key()
	_eq(is_instance_valid(shop) and shop._iap_busy and not shop._dialog.is_open(), true, "Google Play paying: paying before back button")
	_tap(BACK_BTN)
	await _frames()
	_eq(is_instance_valid(shop) and home._shop == shop, true, "Google Play paying: back ignored")
	await _wait()
	await _close_all_popups()
	_eq([S._paid.size(), S.pending_orders.size()], [0, 0], "paid order verified, not stuck")
	await _back_key()
	_eq(home._shop, null, "back works after results")
	await _wait()


## [h, T, B, 內容區 y, 內容區高, 面板下緣, toast y, 重試鈕 y]
const HEIGHT_CASES := [
	[640, 24, 16, 190, 370, 566, 436, 378],
	[800, 24, 16, 190, 530, 726, 500, 458],
	[840, 24, 16, 190, 570, 766, 516, 478],
	[800, 40, 16, 206, 514, 726, 510, 466],
	[800, 24, 34, 190, 512, 708, 493, 449],
	[640, 40, 16, 190, 370, 566, 436, 378],
]


func _check_height(c: Array) -> void:
	var tag := "H%d T%d B%d" % [c[0], c[1], c[2]]
	_reset_service()
	await _make_home(c[0], c[1], c[2])
	await _wait()
	_tap(home._bottom_buttons[1].get_global_rect().get_center())
	await _frames()
	var shop = _shop()
	_eq(shop._retry.get_global_rect().position.y, float(c[7]), tag + " D13 retry / loading center")
	await _wait()
	var off: float = shop._body.position.y
	_eq(_page().get_global_rect(), Rect2(14, c[3], 337, c[4]), tag + " D07 content area")
	_eq(off + shop._panel.end.y, float(c[5]), tag + " D05 panel bottom")
	_eq(HomeLogic.home_layout(c[0], c[1], c[2]).banner - (off + shop._panel.end.y), 8.0, tag + " panel to banner 8")
	_eq(shop._tabs[0].get_global_rect().position.y, float(c[3] - 52), tag + " D06 tabs fixed above content")
	shop._show_toast(L.TOAST_BUY_FAIL)
	_eq(shop.toast_rect().position.y + off, float(c[6]), tag + " toast y")
	# 道具分頁捲到底:最後一列下緣 = 內容區下緣
	shop.select_tab(L.Tab.ITEMS)
	_drag(Vector2(100, c[3] + 300), Vector2(100, c[3] - 400))
	await _frames()
	_eq(_page().scroll, 800 - c[4], tag + " items max scroll")
	# 愛心金幣:800 以上不捲
	shop.select_tab(L.Tab.HEART_COIN)
	_eq(L.max_scroll(L.Tab.HEART_COIN, _page().extra), maxi(0, 528 - c[4]), tag + " heart/coin scroll")
	# 提示框垂直置中於整個螢幕
	_tap(_target_center("coin:1000"))
	await _frames()
	_eq(_dialog().frame_rect().position.y, floorf((c[0] - 270) / 2.0), tag + " D23 centered")
	_eq(_dialog().size, Vector2(360, c[0]), tag + " dialog covers screen")
	await _back_key()
	await _back_key()
	_eq(home._shop, null, tag + " closed")
