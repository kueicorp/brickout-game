class_name ShopService
## 假商城服務:代替還沒做的後端、Google Play 計費與獎勵廣告,商城畫面與首頁商城紅點只透過這一層取資料。
## 日後接真後端時只換這個檔(對外的函式與回應欄位維持不變)。
## 所有請求都是非同步:經過 delay_sec 後呼叫 callback(result);呼叫端節點已被釋放時不呼叫。
## result 一律有 ok(bool);失敗時伺服器狀態不變。錢包與活動共用 EventService 的同一份(同一個帳號)。
## shortcut: 狀態只存在記憶體(static var),重開 App 就回到預設;每日次數不會自動在 00:00 重置。接後端時整檔替換。

## 補發框 id 的前綴:首頁依此把「已看過」轉給本服務(活動的補發 id 沒有這個前綴)
const ID_PREFIX := "shop:"

## 模擬網路延遲(秒)
static var delay_sec := 0.3
## true = 離線:所有請求回失敗(購買類 reason = "offline")
static var offline := false
## 接下來幾次請求要失敗(模擬伺服器錯誤);每次請求減 1
static var fail_next := 0
## 下一次 Google Play 付款的結果:"paid" / "canceled" / "failed" / "pending"(待處理,例如超商付款);用過即回到 "paid"
static var play_result := "paid"
## 下一次付款後向後端驗證的結果:"ok" / "fail"(驗證失敗)/ "hang"(一直沒回應,讓前端逾時);用過即回到 "ok"
static var verify_result := "ok"

## 免費分頁 4 列今天剩餘次數(順序同 ShopLogic.FREE_ROWS)
static var free_left: Array[int] = []
static var remove_ads_bought := false
## 付款完成但還沒發放的訂單 {id, product}
static var pending_orders: Array[Dictionary] = []
## 已補發、玩家還沒看過提示框的訂單 {id, product};玩家關框後由 mark_popup_seen 移除
static var granted_orders: Array[Dictionary] = []

static var _initialized := false
## 已付款、等待驗證的訂單:id → product
static var _paid := {}
## 處理過的金塊購買請求:request_id → 回應(重送同一個 id 不重複扣款)
static var _requests := {}
## 訂單 / 提示框 id 流水號;reset() 不歸零(用戶端會記住看過的 id,同 EventService)
static var _seq := 0


## 回到預設:免費次數全滿、沒買過移除廣告、沒有未發放訂單
static func reset() -> void:
	_initialized = true
	delay_sec = 0.3
	offline = false
	fail_next = 0
	play_result = "paid"
	verify_result = "ok"
	free_left.assign(ShopLogic.FREE_ROWS.map(func(r: Array) -> int: return r[2]))
	remove_ads_bought = false
	pending_orders = []
	granted_orders = []
	_paid = {}
	_requests = {}


## 進商城、首頁紅點用:錢包、金塊包價格(Google Play 回傳)、免費次數、移除廣告、未發放商品與待顯示的補發框
static func fetch_status(callback: Callable) -> void:
	_ensure_init()
	if offline or _consume_failure():
		_respond(callback, {"ok": false})
		return
	var popups := []
	for order in granted_orders:
		var p := ShopLogic.popup_purchase(ShopLogic.product(order.product), 0, _wallet().duplicate(), "order")
		p.id = order.id
		popups.append(p)
	var result := _status()
	result.popups = popups
	_respond(callback, result)


## D19 叫出 Google Play 付款(金塊包、移除廣告)。
## 付款完成:{ok: true, order_id},之後要呼叫 verify_iap;
## 否則 {ok: false, reason: "canceled" / "failed" / "offline" / "pending"};pending 時訂單記為未發放,帶回 pending_products
static func buy_iap(product_id: String, callback: Callable) -> void:
	_ensure_init()
	if offline:
		_respond(callback, {"ok": false, "reason": "offline"})
		return
	var r := play_result
	play_result = "paid"
	if r == "canceled" or r == "failed":
		_respond(callback, {"ok": false, "reason": r})
		return
	var order := {"id": _new_id("order"), "product": product_id}
	if r == "pending":
		pending_orders.append(order)
		_respond(callback, {"ok": false, "reason": "pending", "pending_products": _pending_products()})
		return
	_paid[order.id] = product_id
	_respond(callback, {"ok": true, "order_id": order.id})


## D20 付款完成後向後端驗證並發放。成功:最新狀態(_status 欄位);失敗:{ok: false, pending_products}。
## "hang" 時不回應(前端 30 秒逾時轉 D22),訂單記為未發放
static func verify_iap(order_id: String, callback: Callable) -> void:
	_ensure_init()
	if not _paid.has(order_id):
		_respond(callback, {"ok": false, "pending_products": _pending_products()})
		return
	var product_id: String = _paid[order_id]
	_paid.erase(order_id)
	var v := verify_result
	verify_result = "ok"
	if v != "ok" or offline or _consume_failure():
		pending_orders.append({"id": order_id, "product": product_id})
		if v != "hang":
			_respond(callback, {"ok": false, "pending_products": _pending_products()})
		return
	_fulfill(product_id)
	_respond(callback, _status())


## D23 用金塊買(道具、綜合禮包、愛心、金幣):先扣銀塊再扣金塊。
## 成功:最新狀態 + granted(實際獲得量);失敗:{ok: false, reason: "short" / "heart_cap"(帶 wallet)/ "offline" / "failed"}。
## request_id 每次購買唯一;同一個 id 重送直接回上次結果,不重複扣款
static func buy_with_gold(product_id: String, request_id: String, callback: Callable) -> void:
	_ensure_init()
	if _requests.has(request_id):
		_respond(callback, _requests[request_id])
		return
	if offline:
		_respond(callback, {"ok": false, "reason": "offline"})
		return
	if _consume_failure():
		_respond(callback, {"ok": false, "reason": "failed"})
		return
	var p := ShopLogic.product(product_id)
	var w := _wallet()
	var result: Dictionary
	if p.is_empty() or ShopLogic.is_iap(product_id):
		result = {"ok": false, "reason": "failed"}
	elif p.kind == "heart" and w.heart + p.count > ShopLogic.HEART_MAX:
		result = {"ok": false, "reason": "heart_cap", "wallet": w.duplicate()}
	elif not ShopLogic.can_afford(p.price, w):
		result = {"ok": false, "reason": "short", "wallet": w.duplicate()}
	else:
		var split := ShopLogic.split_cost(p.price, w.silver)
		w.silver -= split[0]
		w.gold -= split[1]
		# shortcut: 商城道具沒有庫存系統(同活動頁),道具、禮包只扣款不入帳;做道具庫存時補上
		if p.kind == "heart" or p.kind == "coin":
			w[p.kind] += p.count
		result = _status()
		result.granted = p.count
	_requests[request_id] = result
	_respond(callback, result)


## D12 看完獎勵廣告領獎(代替 AdMob 獎勵廣告 + 後端驗證)。
## 成功:最新狀態 + granted(實際獲得量;愛心 99 顆時為 0)+ item_name(道具寶箱);失敗(廣告載入失敗、離線):{ok: false}
static func watch_ad(row: int, callback: Callable) -> void:
	_ensure_init()
	if offline or _consume_failure() or free_left[row] <= 0:
		_respond(callback, {"ok": false})
		return
	free_left[row] -= 1
	var w := _wallet()
	var granted := 1
	var item_name := ""
	match row:
		ShopLogic.FREE_HEART:
			# Q06:愛心 99 顆照常可看、照常扣次數,超過的部分不計
			granted = mini(1, ShopLogic.HEART_MAX - w.heart)
			w.heart += granted
		ShopLogic.FREE_COIN:
			granted = randi_range(50, 200)
			w.coin += granted
		ShopLogic.FREE_SILVER:
			granted = randi_range(1, 5)
			w.silver += granted
		_:
			# shortcut: 同上,道具沒有庫存可入帳,只回傳抽到的道具名
			item_name = EventService.draw_item()
	var result := _status()
	result.granted = granted
	result.item_name = item_name
	_respond(callback, result)


## 告知後端玩家已看過某個補發框;不認得的 id 直接忽略
static func mark_popup_seen(id: String, callback := Callable()) -> void:
	_ensure_init()
	if offline or _consume_failure():
		_respond(callback, {"ok": false})
		return
	granted_orders.assign(granted_orders.filter(func(o: Dictionary) -> bool: return o.id != id))
	_respond(callback, {"ok": true})


# ---- 模擬後端事件(只給測試 / 手動試玩用) ----

## 模擬「下次連線時後端向 Google Play 查到未發放訂單並補發」(D22):全部入帳,下次 fetch_status 帶出補發框
static func simulate_grant_pending() -> void:
	_ensure_init()
	for order in pending_orders:
		_fulfill(order.product)
		granted_orders.append(order)
	pending_orders = []


# ---- 內部 ----

static func _ensure_init() -> void:
	if not _initialized:
		reset()


static func _wallet() -> Dictionary:
	return EventService.shared_wallet()


static func _new_id(prefix: String) -> String:
	_seq += 1
	return "%s%s:%d" % [ID_PREFIX, prefix, _seq]


static func _consume_failure() -> bool:
	if fail_next <= 0:
		return false
	fail_next -= 1
	return true


static func _pending_products() -> Array:
	return pending_orders.map(func(o: Dictionary) -> String: return o.product)


static func _status() -> Dictionary:
	var prices := {"remove_ads": "TWD %d" % ShopLogic.REMOVE_ADS_TWD}
	for pack in ShopLogic.GOLD_PACKS:
		prices["gold:%d" % pack[0]] = "TWD %d" % pack[0]
	return {
		"ok": true,
		"wallet": _wallet().duplicate(),
		"prices": prices,
		"free_left": free_left.duplicate(),
		"remove_ads_bought": remove_ads_bought,
		"pending_products": _pending_products(),
	}


## 金塊包、移除廣告入帳
static func _fulfill(product_id: String) -> void:
	var p := ShopLogic.product(product_id)
	var w := _wallet()
	w.gold += p.get("gold", 0)
	w.silver += p.silver
	if p.kind == "remove_ads":
		remove_ads_bought = true


static func _respond(callback: Callable, result: Dictionary) -> void:
	var deliver := func() -> void:
		if callback.is_valid():
			callback.call(result)
	Engine.get_main_loop().create_timer(delay_sec).timeout.connect(deliver)
