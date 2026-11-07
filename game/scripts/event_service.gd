class_name EventService
## 假活動服務:代替還沒做的後端與 Google Play 計費,活動頁與首頁紅點只透過這一層取資料。
## 日後接真後端時只換這個檔(對外的函式與回應欄位維持不變)。
## 所有請求都是非同步:經過 delay_sec 後呼叫 callback(result);呼叫端節點已被釋放時不呼叫。
## result 一律有 ok(bool);失敗時伺服器狀態不變。成功時帶最新 wallet({heart, coin, gold, silver})。
## shortcut: 狀態只存在記憶體(static var),重開 App 就回到預設;不判斷日期、不會自動跨日 / 跨月。接後端時整檔替換。

const HEART_MAX := 99

## 模擬網路延遲(秒)
static var delay_sec := 0.3
## 接下來幾次請求要失敗(模擬離線 / 伺服器錯誤);每次請求減 1
static var fail_next := 0
## 下一次購買視為玩家取消(Google Play 計費視窗按取消)
static var cancel_next := false

static var signed_count := 0
static var signed_today := false
static var claimed: Array[int] = []
static var topup_bought := false
static var wallet := {}
## 尚未讓玩家看過的補發;玩家關框後由 mark_popup_seen 移除(見 fetch_status)
## pending_orders 每筆 {product, id}
static var pending_orders: Array[Dictionary] = []
static var pending_monthly: Array[Dictionary] = []
## 目前這批月初補發的提示框 id(pending_monthly 為空時無意義)
static var monthly_id := ""

static var _initialized := false
## 提示框 id 流水號。reset() 不歸零:用戶端會記住看過的 id,重用會讓新的補發框被當成看過
static var _popup_seq := 0


## 回到預設假資料:本月已簽 7 次、今天未簽、沒領過、首儲未購買(同預覽圖畫面 B)
static func reset() -> void:
	_initialized = true
	delay_sec = 0.3
	fail_next = 0
	cancel_next = false
	signed_count = 7
	signed_today = false
	claimed = []
	topup_bought = false
	wallet = {"heart": FakeData.HEARTS, "coin": FakeData.COINS, "gold": FakeData.GOLD, "silver": FakeData.SILVER}
	pending_orders = []
	pending_monthly = []
	monthly_id = ""


## 取得簽到 / 首儲狀態與待顯示的補發提示框。
## popups 依 D17 順序:補發訂單在前、月初補發在後。
## 每個框帶 id;玩家按「好」或返回鍵關框後,呼叫端以 mark_popup_seen(id) 告知已看過才移除(D15、D17),
## 之前每次取資料都會帶回。同一 id 只彈一次由用戶端(RewardPopup)負責去重。
static func fetch_status(callback: Callable) -> void:
	_ensure_init()
	if _consume_failure():
		_respond(callback, {"ok": false})
		return
	var popups := []
	for order in pending_orders:
		var p := EventLogic.popup_topup("order", wallet.duplicate())
		p.id = order.id
		popups.append(p)
	if not pending_monthly.is_empty():
		var p := EventLogic.popup_monthly(pending_monthly.duplicate(true), wallet.duplicate())
		p.id = monthly_id
		popups.append(p)
	var result := _status()
	result.popups = popups
	_respond(callback, result)


## 今日簽到:成功時已簽次數 +1、發 1500 金幣 + 2 愛心
static func check_in(callback: Callable) -> void:
	_ensure_init()
	if signed_today or _consume_failure():
		_respond(callback, {"ok": false})
		return
	signed_count += 1
	signed_today = true
	_grant(EventLogic.DAILY_REWARD)
	_respond(callback, _status())


## 領取累積獎勵;28 次階另回傳 item_name(後端抽的道具名)
static func claim(tier: int, callback: Callable) -> void:
	_ensure_init()
	if EventLogic.card_state(tier, signed_count, claimed) != EventLogic.Card.CLAIMABLE or _consume_failure():
		_respond(callback, {"ok": false})
		return
	var result := _claim_tier(tier)
	result.merge(_status())
	_respond(callback, result)


## 首儲購買(代替 Google Play 計費 + 後端驗單)。玩家取消時 ok = false、canceled = true
static func buy_first_topup(callback: Callable) -> void:
	_ensure_init()
	if cancel_next:
		cancel_next = false
		_respond(callback, {"ok": false, "canceled": true})
		return
	if topup_bought or _consume_failure():
		_respond(callback, {"ok": false, "canceled": false})
		return
	_grant_topup()
	_respond(callback, _status())


## 告知後端玩家已看過某個補發框(id 來自 fetch_status 的 popups)。不認得的 id 直接忽略。
## 失敗時清單保留,下次取資料會再帶回(同一次執行內由用戶端去重,不會重彈)。
static func mark_popup_seen(id: String, callback := Callable()) -> void:
	_ensure_init()
	if _consume_failure():
		_respond(callback, {"ok": false})
		return
	pending_orders.assign(pending_orders.filter(func(o: Dictionary) -> bool: return o.id != id))
	if id == monthly_id:
		pending_monthly = []
	_respond(callback, {"ok": true})


# ---- 模擬後端事件(只給測試 / 手動試玩用) ----

## 模擬每月 1 日歸零:上月已達成未領的累積獎勵直接入帳,下次 fetch_status 帶出補發清單
static func simulate_month_reset() -> void:
	_ensure_init()
	var tiers: Array[Dictionary] = []
	for tier in EventLogic.TIERS:
		if EventLogic.card_state(tier, signed_count, claimed) == EventLogic.Card.CLAIMABLE:
			tiers.append({"tier": tier, "item_name": _claim_tier(tier).item_name})
	pending_monthly = tiers
	monthly_id = _new_popup_id("monthly")
	signed_count = 0
	signed_today = false
	claimed = []


## 模擬「付款成功但獎勵沒發出去」的首儲訂單,由後端補發(Q5)
static func simulate_pending_order() -> void:
	_ensure_init()
	_grant_topup()
	pending_orders.append({"product": "first_topup", "id": _new_popup_id("order")})


## 假商城服務(ShopService)與活動共用同一個錢包(模擬同一個後端帳號)
static func shared_wallet() -> Dictionary:
	_ensure_init()
	return wallet


## 等機率抽 1 種商城道具(Q8)
static func draw_item() -> String:
	return EventLogic.SHOP_ITEMS.pick_random()


# ---- 內部 ----

static func _ensure_init() -> void:
	if not _initialized:
		reset()


static func _new_popup_id(prefix: String) -> String:
	_popup_seq += 1
	return "%s:%d" % [prefix, _popup_seq]


static func _consume_failure() -> bool:
	if fail_next <= 0:
		return false
	fail_next -= 1
	return true


static func _status() -> Dictionary:
	return {
		"ok": true,
		"signed_count": signed_count,
		"signed_today": signed_today,
		"claimed": claimed.duplicate(),
		"topup_bought": topup_bought,
		"wallet": wallet.duplicate(),
	}


## 記為已領並入帳,回傳 {item_name}(非 28 次階為空字串)
static func _claim_tier(tier: int) -> Dictionary:
	claimed.append(tier)
	_grant(EventLogic.TIER_REWARDS[tier])
	# shortcut: 商城道具沒有庫存系統,只回傳道具名不入帳;做商城道具庫存時補上
	return {"item_name": draw_item() if tier == EventLogic.ITEM_TIER else ""}


static func _grant_topup() -> void:
	topup_bought = true
	# shortcut: 首儲的 10 種商城道具同樣沒有庫存可入帳,只發金塊、銀塊
	_grant(EventLogic.TOPUP_REWARD)


static func _grant(rewards: Array) -> void:
	for r in rewards:
		wallet[r[0]] += r[1]
	# README「愛心」:最多 99 顆,超過不計
	wallet.heart = mini(wallet.heart, HEART_MAX)


static func _respond(callback: Callable, result: Dictionary) -> void:
	var deliver := func() -> void:
		if callback.is_valid():
			callback.call(result)
	Engine.get_main_loop().create_timer(delay_sec).timeout.connect(deliver)
