class_name EventScreen
extends Control
## 活動頁(event-screen D01~D14):畫面 A 列表、B 每日簽到、C 首次儲值,與載入 / 失敗 / toast。
## 由首頁疊在自己上面顯示(首頁的背景、D03 資源列、banner 留在下面共用;首頁其他元件先隱藏)。
## 每次進入都是新節點、重新取資料(D01);B、C 共用進入時取得的資料,操作成功後以回應更新。
## 提示框排進首頁持有的 popup(RewardPopup),所以離開活動頁也不會漏掉排隊中的框。
## 內容座標都是 360×640 基準;其他高度由 apply_layout 依 screen-size-800 S02 / S07 排:
## 上方貼安全區、多出的高度全部加在面板(B、C 再分進面板內留白)。

signal closed
## 點了其他頁的捷徑(page-shortcuts P04),由首頁換頁
signal switch_requested(page: PageShortcutBar.Page)

enum Load { LOADING, LOADED, FAILED }

const ICON_CHECKIN := preload("res://assets/ui/event/icon_checkin.png")
const ICON_TOPUP := preload("res://assets/ui/event/icon_first_topup.png")
## 640 高(E = 0)時的面板;實際面板見 _panel
const PANEL := Rect2(8, 132, 344, 434)
const PANEL_COLOR := Color(0, 0, 0, 160.0 / 255.0)
const TOAST_BG := Color("#222B3A")
const TOAST_BORDER := Color("#5D6D7E")
const TOAST_SEC := 2.0
const NO_OUTLINE := Color.TRANSPARENT
const SUB_CHECKIN := "每日 1500 金幣 + 2 愛心"
const SUB_TOPUP := "限購 1 次"
const SUB_BOUGHT := "已購買"
const TOAST_CHECKIN := "簽到失敗,請檢查網路後再試"
const TOAST_CLAIM := "領取失敗,請檢查網路後再試"
const TOAST_BUY := "購買失敗,請稍後再試"

## 由首頁注入
var popup: RewardPopup
var page := EventLogic.Page.LIST
var load_state := Load.LOADING
var status := {}
var toast_text := ""

## 頁面捷徑列(返回鈕 + 4 個捷徑);首頁設定「商城」捷徑的紅點
var shortcuts: PageShortcutBar

var _body: Control
var _back: PageShortcutBar.ShortcutButton
## 返回鈕與捷徑列的下移量(apply_layout 設定)
var _header_shift := 0
## 目前的面板(_body 座標;高 = 434 + 面板加高量,apply_layout 設定)
var _panel := PANEL
## 面板加高量 E(≥ 0;apply_layout 設定),toast 與 D14 依此下移(S08)
var _extra := 0
var _items: Array[EventListItem] = []
var _checkin: CheckinPage
var _topup: TopupPage
var _state_view: Control
var _retry: GreenButton
var _toast: Control
var _toast_timer: Timer
## 畫面造訪序號:每次 show_page 加 1。請求發出時記下,回應晚到且序號已變(切走過,含切回同一頁)就不顯示失敗 toast
var _visit := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(360, 640)
	_body = _add_layer(self)
	_body.draw.connect(_draw_body)

	shortcuts = PageShortcutBar.new(PageShortcutBar.Page.EVENT)
	shortcuts.back_pressed.connect(go_back)
	shortcuts.page_pressed.connect(_on_shortcut)
	_body.add_child(shortcuts)
	_back = shortcuts.back

	# shortcut: 只有 2 個活動,D05「超過完整顯示項數才捲動、4px 捲軸」沒有做(完整顯示項數 = floor((430 + E) ÷ 80),
	# 640 高為 5);新增到第 6 個活動時改成可捲動的列表
	for i in 2:
		var item := EventListItem.new()
		item.position = Vector2(14, 138 + i * 80)
		item.size = Vector2(332, 72)
		item.icon = ICON_CHECKIN if i == 0 else ICON_TOPUP
		item.title = "每日簽到" if i == 0 else "首次儲值"
		item.pressed.connect(show_page.bind(EventLogic.Page.CHECKIN if i == 0 else EventLogic.Page.TOPUP))
		_body.add_child(item)
		_items.append(item)

	_checkin = CheckinPage.new()
	_checkin.size = size
	_checkin.checkin_pressed.connect(_on_checkin_pressed)
	_checkin.claim_pressed.connect(_on_claim_pressed)
	_body.add_child(_checkin)
	_topup = TopupPage.new()
	_topup.size = size
	_topup.buy_pressed.connect(_on_buy_pressed)
	_body.add_child(_topup)

	_state_view = _add_layer(_body)
	_state_view.draw.connect(_draw_state_view)
	_retry = GreenButton.new()
	_retry.position = Vector2(120, 352)
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

	_fetch()


## h = 畫面高,top / bottom = 安全區 T、B;算法見 EventLogic.event_layout。
## A 列表項目位置不變,面板加高只露出更多空白(Q3 面板維持填滿)。
func apply_layout(h: int, top: int, bottom: int) -> void:
	var lay := EventLogic.event_layout(h, top, bottom)
	_body.position.y = lay.offset
	_header_shift = lay.header_shift
	shortcuts.set_shift(_header_shift)
	_panel = Rect2(PANEL.position, PANEL.size + Vector2(0, lay.extra))
	_extra = lay.extra
	_checkin.set_extra(lay.extra)
	_topup.set_extra(lay.extra)
	# 各圖層跟著畫面高,高螢幕往下移的按鈕才在父節點範圍內
	for c: Control in [self, _body, shortcuts, _checkin, _topup, _state_view, _toast]:
		c.size = Vector2(360, h)
	_retry.position.y = 352 + EventLogic.state_shift(_extra)
	_body.queue_redraw()
	_state_view.queue_redraw()
	_toast.queue_redraw()


## 切換 A / B / C(列表點擊、返回鈕、返回鍵都走這裡);toast 屬於原畫面,切換時立即收起
func show_page(p: EventLogic.Page) -> void:
	page = p
	_visit += 1
	_hide_toast()
	_refresh()


## D04 返回鈕(返回鍵由首頁處理,結果相同):B、C 回 A;A 回首頁。
## 處理中不反應:停用外觀靠每幀同步,同一幀內「開始處理」後的點擊會比停用早到,所以點下時直接再檢查
func go_back() -> void:
	if is_busy():
		return
	if page == EventLogic.Page.LIST:
		closed.emit()
	else:
		show_page(EventLogic.Page.LIST)


## page-shortcuts P03:目前頁「活動」在 A 沒反應、在 B / C 回 A;其他頁交給首頁換頁。處理中不反應(理由同 go_back)
func _on_shortcut(p: PageShortcutBar.Page) -> void:
	if is_busy():
		return
	if p != PageShortcutBar.Page.EVENT:
		switch_requested.emit(p)
	elif page != EventLogic.Page.LIST:
		show_page(EventLogic.Page.LIST)


## 簽到、領取、首儲購買的請求是否處理中;捷徑列停用與首頁的返回鍵保護(README 活動第 7 點)共用此條件
func is_busy() -> bool:
	return not _checkin.busy.is_empty() or _topup.busy


## P04:請求處理中,返回鈕與捷徑停用。
## 用每幀同步而不是在各請求起訖處設定:請求狀態分散在 B、C 兩個子頁,逐處呼叫容易漏
func _process(_delta: float) -> void:
	shortcuts.set_disabled(is_busy())


func _add_layer(parent: Control) -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.size = Vector2(360, 640)
	parent.add_child(c)
	return c


func _fetch() -> void:
	load_state = Load.LOADING
	_refresh()
	EventService.fetch_status(_on_status)


func _on_status(r: Dictionary) -> void:
	if not r.ok:
		# D14:失敗時不沿用舊值、紅點不顯示、首儲維持未購買樣式
		load_state = Load.FAILED
		status = {}
		_refresh()
		return
	status = r
	load_state = Load.LOADED
	_refresh()
	# D15、D17:資料載入完成後才彈出
	for p in r.popups:
		popup.enqueue(p)


## 依目前畫面與資料狀態更新所有元件(D05、D14)
func _refresh() -> void:
	var loaded := load_state == Load.LOADED
	var badge: bool = loaded and EventLogic.checkin_badge(status.signed_count, status.signed_today, status.claimed)
	var bought: bool = loaded and status.topup_bought
	_items[0].set_state(SUB_CHECKIN, badge, false)
	_items[1].set_state(SUB_BOUGHT if bought else SUB_TOPUP, false, bought)
	for item in _items:
		item.visible = page == EventLogic.Page.LIST
	_checkin.visible = loaded and page == EventLogic.Page.CHECKIN
	_topup.visible = loaded and page == EventLogic.Page.TOPUP
	_state_view.visible = not loaded and page != EventLogic.Page.LIST
	_retry.visible = load_state == Load.FAILED
	# S08:進入 D14 載入 / 失敗狀態時 toast 立即收起
	if _state_view.visible:
		_hide_toast()
	if loaded:
		_checkin.show_status(status)
		_topup.show_status(status)
	_body.queue_redraw()
	_state_view.queue_redraw()


# ---- 操作(D07、D10、D11) ----

func _on_checkin_pressed() -> void:
	_checkin.set_busy("checkin", true)
	EventService.check_in(_on_checkin_done.bind(_visit))


## visit:請求發出時的畫面造訪序號;以下 _on_claim_done、_on_buy_done 同
func _on_checkin_done(r: Dictionary, visit: int) -> void:
	_checkin.set_busy("checkin", false)
	if not r.ok:
		_fail_toast(TOAST_CHECKIN, visit)
		return
	_apply(r)
	popup.enqueue(EventLogic.popup_checkin(r.wallet))


func _on_claim_pressed(tier: int) -> void:
	_checkin.set_busy(tier, true)
	EventService.claim(tier, _on_claim_done.bind(tier, _visit))


func _on_claim_done(r: Dictionary, tier: int, visit: int) -> void:
	_checkin.set_busy(tier, false)
	if not r.ok:
		_fail_toast(TOAST_CLAIM, visit)
		return
	_apply(r)
	popup.enqueue(EventLogic.popup_tier(tier, r.item_name, r.wallet))


func _on_buy_pressed() -> void:
	_topup.set_busy(true)
	EventService.buy_first_topup(_on_buy_done.bind(_visit))


func _on_buy_done(r: Dictionary, visit: int) -> void:
	_topup.set_busy(false)
	if not r.ok:
		# 玩家取消不顯示訊息(D11)
		if not r.canceled:
			_fail_toast(TOAST_BUY, visit)
		return
	_apply(r)
	popup.enqueue(EventLogic.popup_topup("action", r.wallet))


## 操作成功的回應帶有最新狀態,直接取代(列表紅點、首儲標示跟著更新)
func _apply(r: Dictionary) -> void:
	status = r
	_refresh()


## 失敗 toast 只在發出請求的那次畫面顯示;切走過(含切回同一頁)就不顯示
func _fail_toast(text: String, visit: int) -> void:
	if visit == _visit:
		_show_toast(text)


## 畫面下方 toast 2 秒;text 為空字串 = 收起。D14 狀態下不顯示(S08;例如重試前發出的操作晚到失敗)
func _show_toast(text: String) -> void:
	toast_text = "" if _state_view.visible else text
	if toast_text != "":
		_toast_timer.start(TOAST_SEC)
	_toast.queue_redraw()


## 立即收起並停掉計時(切頁、進入 D14 時用;舊計時若沒停會提早收掉之後的 toast)
func _hide_toast() -> void:
	_toast_timer.stop()
	_show_toast("")


# ---- 繪製 ----

func _draw_body() -> void:
	PixelBox.draw_rounded(_body, _panel, PANEL_COLOR)


## D14:面板內置中「載入中…」;失敗時「讀取失敗」+ 重試鈕。面板加高時整組下移 round(E ÷ 2)(S08),重試鈕在 apply_layout 移
func _draw_state_view() -> void:
	var text := "讀取失敗" if load_state == Load.FAILED else "載入中…"
	var baseline := (340.0 if load_state == Load.FAILED else 354.0) + EventLogic.state_shift(_extra)
	PixelText.draw(_state_view, Vector2(PANEL.position.x, baseline), text, 14, Color.WHITE, NO_OUTLINE,
		PANEL.size.x, HORIZONTAL_ALIGNMENT_CENTER)


## 目前 toast 文字的框(_toast 座標):寬依文字 + 24、水平置中、高 32
func toast_rect() -> Rect2:
	var w := PixelText.FONT.get_string_size(toast_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 24
	return Rect2(floorf(180 - w / 2.0), EventLogic.toast_y(_extra), ceilf(w), 32)


## shortcut: 設計稿只寫「畫面下方 toast 2 秒」,樣式自訂(提示框同色框);設計師補樣式規格後照改
## 位置依 S08 方案 B:y = 436 + round(0.4E)(_body 座標;_body 已含 T − 24 下移)。
## 增量 0.4E 小於領取鈕(0.75E,640 時 518 起)與購買鈕(0.8E,640 時 476 起)的增量,所以不會蓋到可點元素
func _draw_toast() -> void:
	if toast_text == "":
		return
	var rect := toast_rect()
	_toast.draw_rect(rect, TOAST_BORDER)
	_toast.draw_rect(rect.grow(-1), TOAST_BG)
	PixelText.draw(_toast, Vector2(rect.position.x, rect.position.y + 21), toast_text, 14, Color.WHITE, NO_OUTLINE,
		rect.size.x, HORIZONTAL_ALIGNMENT_CENTER)
