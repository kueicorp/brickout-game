class_name ShopScreen
extends Control
## 商城(shop-screen D01~D18、shop-purchase-flows D19~D28):返回鈕、標題、面板、4 個分頁籤、捲動內容區、
## 載入 / 失敗、toast、購買流程。與活動頁一樣由首頁疊在自己上面顯示(背景、資源列、banner 共用首頁的)。
## 每次進入都是新節點、重新取資料(D06);提示框「已獲得」等排進首頁持有的 RewardPopup。
## 內容座標都是 360×640 基準;其他高度由 apply_layout 依 screen-size-800 S02 / S07 排:
## 上方貼安全區、多出的高度 E 全部加在面板與內容區(D05、D07)。

signal closed
## 購買失敗後重新取到的錢包(D23「資源列重新取資料」),由首頁更新資源列
signal wallet_refreshed(wallet: Dictionary)
## 伺服器回報已買移除廣告(購買成功或補發),由首頁關掉 banner
signal ads_removed
## 點了其他頁的捷徑(page-shortcuts P04),由首頁換頁
signal switch_requested(page: PageShortcutBar.Page)

enum Load { LOADING, LOADED, FAILED }

## 640 高(E = 0)時的面板;實際面板見 _panel
const PANEL := Rect2(8, 132, 344, 434)
const PANEL_COLOR := Color(0, 0, 0, 160.0 / 255.0)
const TAB_SELECTED := Color("#F4C430")
const TAB_BG := Color("#222B3A")
const TAB_BORDER := Color("#5D6D7E")
const TOAST_BG := Color("#222B3A")
const TOAST_BORDER := Color("#5D6D7E")
const TOAST_SEC := 2.0
const NO_OUTLINE := Color.TRANSPARENT
## D13 載入 / 失敗:內容區(640 高)中心 y 375;各元素相對中心的位置沿用活動頁 D14
## (活動頁面板中心 349:載入中基線 354、讀取失敗基線 340、重試鈕 y 352)
const STATE_CENTER := 375

## 由首頁注入
var popup: RewardPopup
## 進入時的分頁(首頁在加入前設定,D06 預設分頁)
var tab: int = ShopLogic.Tab.TOPUP
var load_state := Load.LOADING
var status := {}
var toast_text := ""
## D20 處理中最多等幾秒才轉 D22(Q18 = 30);測試改短
var verify_timeout_sec := 30.0

## 頁面捷徑列(返回鈕 + 4 個捷徑);首頁設定「活動」捷徑的紅點
var shortcuts: PageShortcutBar

var _body: Control
var _back: PageShortcutBar.ShortcutButton
var _tabs: Array[FlatButton] = []
var _page: ShopPage
var _state_view: Control
var _retry: GreenButton
var _toast: Control
var _toast_timer: Timer
var _dialog: ShopDialog
var _verify_timer: Timer
var _header_shift := 0
var _panel := PANEL
## 面板加高量 E(≥ 0)
var _extra := 0
## Google Play 付款進行中(付款畫面到驗證結束);一次只處理一筆,期間其他 Google Play 商品的點擊不理會
var _iap_busy := false
## 等待驗證的訂單與商品;逾時後清空,晚到的驗證結果就不顯示
var _verify_order := ""
var _verify_product := ""
## 正在載入 / 播放廣告的免費列(−1 = 沒有)
var _ad_busy := -1
var _request_seq := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(360, 640)
	_body = _add_layer(self)
	_body.draw.connect(_draw_body)

	shortcuts = PageShortcutBar.new(PageShortcutBar.Page.SHOP)
	shortcuts.back_pressed.connect(handle_back)
	# P03:目前頁「商城」沒反應(不切分頁、不重載、不捲動)。
	# 處理中不反應:停用外觀靠每幀同步,同一幀內「開始處理」後的點擊會比停用早到,所以點下時直接再檢查
	shortcuts.page_pressed.connect(func(p: PageShortcutBar.Page) -> void:
		if p != PageShortcutBar.Page.SHOP and not _is_busy():
			switch_requested.emit(p))
	_body.add_child(shortcuts)
	_back = shortcuts.back

	for i in ShopLogic.TAB_NAMES.size():
		var t := FlatButton.new()
		t.position = Vector2(14 + 84 * i, 138)
		t.size = Vector2(80, 44)
		t.pressed.connect(select_tab.bind(i))
		_body.add_child(t)
		_tabs.append(t)

	_page = ShopPage.new()
	_page.position = Vector2(14, 190)
	_page.size = Vector2(337, ShopLogic.VIEW_HEIGHT)
	_page.tapped.connect(_on_tapped)
	_body.add_child(_page)

	_state_view = _add_layer(_body)
	_state_view.draw.connect(_draw_state_view)
	_retry = GreenButton.new()
	_retry.position = Vector2(120, STATE_CENTER + 3)
	_retry.size = Vector2(120, 44)
	_retry.set_active("重試", true)
	_retry.pressed.connect(_fetch)
	_state_view.add_child(_retry)

	_toast = _add_layer(_body)
	_toast.draw.connect(_draw_toast)
	_toast_timer = Timer.new()
	_toast_timer.one_shot = true
	_toast_timer.timeout.connect(_show_toast.bind(""))
	add_child(_toast_timer)

	_verify_timer = Timer.new()
	_verify_timer.one_shot = true
	_verify_timer.timeout.connect(_on_verify_timeout)
	add_child(_verify_timer)

	_dialog = ShopDialog.new()
	_dialog.size = size
	_dialog.confirmed.connect(_on_confirmed)
	_dialog.go_topup.connect(select_tab.bind(ShopLogic.Tab.TOPUP))
	add_child(_dialog)

	_fetch()


## h = 畫面高,top / bottom = 安全區 T、B;外框算法同活動頁(EventLogic.event_layout)
func apply_layout(h: int, top: int, bottom: int) -> void:
	var lay := EventLogic.event_layout(h, top, bottom)
	_body.position.y = lay.offset
	_header_shift = lay.header_shift
	shortcuts.set_shift(_header_shift)
	_extra = lay.extra
	_panel = Rect2(PANEL.position, PANEL.size + Vector2(0, _extra))
	_page.size.y = ShopLogic.VIEW_HEIGHT + _extra
	_page.extra = _extra
	_page.refresh()
	_retry.position.y = STATE_CENTER + 3 + EventLogic.state_shift(_extra)
	for c: Control in [self, _body, shortcuts, _state_view, _toast, _dialog]:
		c.size = Vector2(360, h)
	_body.queue_redraw()
	_state_view.queue_redraw()
	_toast.queue_redraw()


## 切分頁(分頁籤、資源列 icon、D24「去儲值」):內容區回到頂端、不做轉場;已在該分頁則不動作(D02、D06)
func select_tab(t: int) -> void:
	if t == tab:
		return
	tab = t
	_hide_toast()
	_refresh(true)


## 返回鍵 / 返回手勢 / 左上返回鈕(首頁的 RewardPopup 開著時由首頁先關它):商城自己的框開著先交給框,否則回首頁。
## 看廣告或 Google Play 付款 / 驗證進行中不反應(比照 D20「返回鍵無效」):
## 商城一關,結果回呼就找不到節點,「已獲得」框不會出現、已付款訂單也不會送去驗證
func handle_back() -> void:
	if _dialog.is_open():
		_dialog.back()
	elif _ad_busy < 0 and not _iap_busy:
		closed.emit()


## page-shortcuts P04:看廣告、Google Play 付款 / 驗證、金塊購買送出後,返回鈕與捷徑停用;
## 前兩者與 handle_back 的返回鍵保護同一組狀態,捷徑不能繞過。每幀同步,避免在各流程起訖處逐一呼叫而漏掉
func _process(_delta: float) -> void:
	shortcuts.set_disabled(_is_busy())


## 看廣告、Google Play 付款 / 驗證、金塊購買是否處理中(捷徑停用與點擊當下的檢查共用)
func _is_busy() -> bool:
	return _ad_busy >= 0 or _iap_busy or _dialog.busy


func _add_layer(parent: Control) -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.size = Vector2(360, 640)
	parent.add_child(c)
	return c


func _notification(what: int) -> void:
	# D18:App 回到前景時以最新資料更新(不顯示載入中)
	if what == NOTIFICATION_APPLICATION_RESUMED and load_state == Load.LOADED:
		_refetch()


# ---- 資料 ----

func _fetch() -> void:
	load_state = Load.LOADING
	_refresh()
	ShopService.fetch_status(_on_status)


func _on_status(r: Dictionary) -> void:
	if not r.ok:
		# D13、D18:失敗時不沿用舊值、紅點不顯示
		load_state = Load.FAILED
		status = {}
		_refresh()
		return
	load_state = Load.LOADED
	_apply(r)
	for p in r.popups:
		popup.enqueue(p)


## 背景重新取資料(購買失敗後、回前景):成功才更新,失敗維持現狀
func _refetch() -> void:
	ShopService.fetch_status(func(r: Dictionary) -> void:
		if r.ok and load_state == Load.LOADED:
			_apply(r)
			for p in r.popups:
				popup.enqueue(p)
			wallet_refreshed.emit(r.wallet))


## 回應帶有最新狀態的欄位就覆蓋(錢包、免費次數、未發放商品…)
func _apply(r: Dictionary) -> void:
	for key in ["wallet", "prices", "free_left", "remove_ads_bought", "pending_products"]:
		if r.has(key):
			status[key] = r[key]
	if status.get("remove_ads_bought", false):
		ads_removed.emit()
	_refresh()


## 依分頁與資料狀態更新所有元件
func _refresh(reset_scroll := false) -> void:
	var loaded := load_state == Load.LOADED
	for i in _tabs.size():
		var t := _tabs[i]
		var selected := i == tab
		t.set_look(ShopLogic.TAB_NAMES[i], TAB_SELECTED if selected else TAB_BG, Color.BLACK if selected else Color.WHITE, true)
		t.border = Color.TRANSPARENT if selected else TAB_BORDER
		t.badge = false
	# D18:資料到達後、免費分頁任一項今天還有次數
	_tabs[ShopLogic.Tab.FREE].badge = loaded and ShopLogic.free_badge(status.free_left)
	_page.visible = loaded
	_page.tab = tab
	_page.status = status if loaded else {}
	_page.ad_busy = _ad_busy
	_page.refresh(reset_scroll)
	_state_view.visible = not loaded
	_retry.visible = load_state == Load.FAILED
	if _state_view.visible:
		_hide_toast()
	_body.queue_redraw()
	_state_view.queue_redraw()


# ---- 操作 ----

func _on_tapped(action: String, arg: String) -> void:
	match action:
		"iap":
			if not _iap_busy:
				_start_iap(arg)
		"buy":
			_start_gold_buy(arg)
		"detail":
			_dialog.open_detail(int(arg))
		"ad":
			if _ad_busy < 0:
				_watch_ad(int(arg))


## D19:直接叫出 Google Play(不先跳遊戲自己的確認框)
func _start_iap(id: String) -> void:
	_iap_busy = true
	ShopService.buy_iap(id, _on_play_result.bind(id))


func _on_play_result(r: Dictionary, id: String) -> void:
	if r.ok:
		# D20:付款完成 → 處理中,等後端驗證;超過 verify_timeout_sec 轉 D22
		_dialog.open_processing()
		_verify_order = r.order_id
		_verify_product = id
		_verify_timer.start(verify_timeout_sec)
		ShopService.verify_iap(r.order_id, _on_verify.bind(r.order_id))
		return
	_iap_busy = false
	match r.reason:
		"canceled":
			pass  # 玩家取消:回商城原樣,不顯示任何訊息
		"offline":
			_show_toast(ShopLogic.TOAST_NO_NET)
		"pending":
			_apply(r)
			popup.enqueue(ShopLogic.popup_unpaid(true, status.wallet))
		_:
			_show_toast(ShopLogic.TOAST_BUY_FAIL)


func _on_verify(r: Dictionary, order_id: String) -> void:
	if order_id != _verify_order:
		return  # 已逾時並顯示過 D22
	var id := _verify_product
	_end_verify()
	_apply(r)
	if r.ok:
		popup.enqueue(ShopLogic.popup_purchase(ShopLogic.product(id), 0, r.wallet))
	else:
		popup.enqueue(ShopLogic.popup_unpaid(false, status.wallet))


## D20 逾時(D22 (b)):該商品維持不可再點,直到補發
func _on_verify_timeout() -> void:
	var id := _verify_product
	_end_verify()
	if not status.pending_products.has(id):
		status.pending_products.append(id)
	_refresh()
	popup.enqueue(ShopLogic.popup_unpaid(false, status.wallet))


func _end_verify() -> void:
	_verify_timer.stop()
	_verify_order = ""
	_verify_product = ""
	_iap_busy = false
	_dialog.close()


## D23 觸發:先檢查再開框 —— 愛心超量(安全網 D25)→ 銀塊 + 金塊不足(D24)→ 確認框
func _start_gold_buy(id: String) -> void:
	var p := ShopLogic.product(id)
	var w: Dictionary = status.wallet
	if p.kind == "heart" and ShopLogic.heart_card_state(w.heart, p.count) != ShopLogic.HeartCard.NORMAL:
		popup.enqueue(ShopLogic.popup_heart_cap(w.heart, p.count, w))
	elif not ShopLogic.can_afford(p.price, w):
		_dialog.open_short(p.price, w)
	else:
		_dialog.open_confirm(p, w)


func _on_confirmed(id: String) -> void:
	_dialog.set_busy(true)
	_request_seq += 1
	var request_id := "%d-%d" % [Time.get_ticks_usec(), _request_seq]
	ShopService.buy_with_gold(id, request_id, _on_gold_done.bind(id))


func _on_gold_done(r: Dictionary, id: String) -> void:
	_dialog.close()
	var p := ShopLogic.product(id)
	if r.ok:
		_apply(r)
		popup.enqueue(ShopLogic.popup_purchase(p, r.granted, r.wallet))
		return
	match r.reason:
		"short":
			_apply(r)
			_dialog.open_short(p.price, status.wallet)
		"heart_cap":
			_apply(r)
			popup.enqueue(ShopLogic.popup_heart_cap(status.wallet.heart, p.count, status.wallet))
		"offline":
			_show_toast(ShopLogic.TOAST_NO_NET)
			_refetch()
		_:
			_show_toast(ShopLogic.TOAST_BUY_FAIL)
			_refetch()


## D12:看廣告 → 發獎 → 「已獲得」;失敗回到「可看」並出 toast
func _watch_ad(row: int) -> void:
	_ad_busy = row
	_refresh()
	ShopService.watch_ad(row, _on_ad_done.bind(row))


func _on_ad_done(r: Dictionary, row: int) -> void:
	_ad_busy = -1
	if not r.ok:
		_refresh()
		_show_toast(ShopLogic.TOAST_AD_FAIL)
		return
	_apply(r)
	popup.enqueue(ShopLogic.popup_free(row, r.granted, r.item_name, r.wallet))


# ---- toast(同活動頁 S08 方案 B) ----

## text 為空字串 = 收起;載入 / 失敗狀態下不顯示
func _show_toast(text: String) -> void:
	toast_text = "" if _state_view.visible else text
	if toast_text != "":
		_toast_timer.start(TOAST_SEC)
	_toast.queue_redraw()


func _hide_toast() -> void:
	_toast_timer.stop()
	_show_toast("")


## 目前 toast 的框(_toast 座標):寬依文字 + 24、水平置中、高 32;y = 436 + round(0.4E)
func toast_rect() -> Rect2:
	var w := PixelText.FONT.get_string_size(toast_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 24
	return Rect2(floorf(180 - w / 2.0), EventLogic.toast_y(_extra), ceilf(w), 32)


# ---- 繪製 ----

func _draw_body() -> void:
	PixelBox.draw_rounded(_body, _panel, PANEL_COLOR)
	# D06 分頁籤列下方 2px 分隔線
	_body.draw_rect(Rect2(14, 186, 332, 2), TAB_BORDER)


## D13:內容區置中「載入中…」;失敗時「讀取失敗」+ 重試鈕。內容區加高時整組下移 round(E ÷ 2)
func _draw_state_view() -> void:
	var failed := load_state == Load.FAILED
	var baseline := STATE_CENTER + (-9 if failed else 5) + EventLogic.state_shift(_extra)
	PixelText.draw(_state_view, Vector2(14, baseline), "讀取失敗" if failed else "載入中…", 14, Color.WHITE, NO_OUTLINE,
		332, HORIZONTAL_ALIGNMENT_CENTER)


## shortcut: toast 樣式同活動頁(提示框同色框),活動頁設計稿補樣式規格後兩邊一起改
func _draw_toast() -> void:
	if toast_text == "":
		return
	var rect := toast_rect()
	_toast.draw_rect(rect, TOAST_BORDER)
	_toast.draw_rect(rect.grow(-1), TOAST_BG)
	PixelText.draw(_toast, Vector2(rect.position.x, rect.position.y + 21), toast_text, 14, Color.WHITE, NO_OUTLINE,
		rect.size.x, HORIZONTAL_ALIGNMENT_CENTER)
