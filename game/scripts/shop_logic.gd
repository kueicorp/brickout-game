class_name ShopLogic
## 商城的純規則(不依賴畫面),供商城畫面、首頁紅點、假商城服務與測試共用。
## 規格:docs/design/shop/shop-screen.md D01~D18、shop-purchase-flows.md D19~D28、README「商城」。
## 商品 id:金塊包 "gold:N"(N = 金塊數)、"remove_ads"(以上走 Google Play);
## 用金塊買的 "item:I:N"(I = 道具序號 0~9,N = 1 或 11)、"bundle"、"heart:N"、"coin:N"。

enum Tab { TOPUP, ITEMS, HEART_COIN, FREE }
## 愛心卡狀態(D15、D25)
enum HeartCard { NORMAL, FULL, OVER_CAP }

const TAB_NAMES: Array[String] = ["儲值", "道具", "愛心金幣", "免費"]
const HEART_MAX := 99

## D08 金塊包 [金塊, 贈送銀塊];台幣價格 = 金塊數(README 匯率 1 NTD = 1 金塊)
const GOLD_PACKS := [[30, 0], [90, 9], [150, 30], [300, 60], [590, 177], [890, 312], [1490, 596], [2990, 1346]]
const REMOVE_ADS_TWD := 300
const REMOVE_ADS_SILVER := 100
const ITEM_PRICE := 30
const ITEM_PACK_COUNT := 11
const ITEM_PACK_PRICE := 300
const BUNDLE_PRICE := 540
const BUNDLE_EACH := 2
## D15、D16 [數量, 金塊價格]
const HEART_PACKS := [[1, 30], [5, 120], [10, 240], [20, 480]]
const COIN_PACKS := [[1000, 30], [5000, 120], [10000, 240], [20000, 480], [50000, 1350]]
## D12 免費分頁 [名稱, 獎勵說明, 每天次數];列序 = watch_ad 的 row
const FREE_ROWS := [
	["看廣告得愛心", "愛心 +1", 20],
	["免費金幣寶箱", "50 到 200 金幣", 5],
	["免費銀塊寶箱", "1 到 5 銀塊", 5],
	["免費商城道具寶箱", "隨機商城道具 1 個", 1],
]
const FREE_HEART := 0
const FREE_COIN := 1
const FREE_SILVER := 2
const FREE_ITEM := 3
## D28 道具說明行;順序同 EventLogic.SHOP_ITEMS(README 順序)
const ITEM_LINES := [
	["擋板血量增加 150", "進入關卡後立即生效"],
	["擋板血量歸 0 時發動,以最大血量的", "50% 復活,每關只能復活 1 次", "磚塊越過警戒線時不會發動"],
	["每次技能三選一,可刷新 3 次", "每次刷新,3 個技能會全部換掉"],
	["魔王扣除 30% 最大血量,最低剩 1", "不會觸發擊退、暈眩和經驗"],
	["抵擋 10 次敵方攻擊或負面效果", "塗層破裂時,對第一排磚塊造成", "當前血量 10% 的傷害"],
	["敵方最大生命 −30%,下降時間 13 秒", "敵方有 20% 機率不觸發磚塊效果", "或魔王技能(金幣、寶箱磚塊除外)"],
	["磚塊靠近警戒線 50 px 時自動發動,", "磚塊擊退到剩 3 排,魔王關剩 4 排", "碰到頂部的磚塊會破壞,不給經驗"],
	["敵方護盾無效", "進入關卡後立即生效"],
	["技能三選一改為五選二,", "寶箱磚塊的三選一也一樣"],
	["進入關卡後,可以直接進行", "5 次技能三選一"],
]
## D28 限制標籤:只有「暗殺」
const BOSS_ONLY_ITEM := 3
const BOSS_ONLY_TAG := "只有魔王關可用"

## D07 各分頁內容總高(依 Tab 順序)
const CONTENT_HEIGHT: Array[int] = [520, 800, 528, 360]
## D07 內容區在 640 高(E = 0)時的可見高
const VIEW_HEIGHT := 370

const TOAST_NO_NET := "目前沒有網路,請連線後再試"
const TOAST_BUY_FAIL := "購買失敗,請稍後再試"
const TOAST_AD_FAIL := "廣告暫時無法播放,請稍後再試"
const TITLE_UNPAID := "付款處理中"
const UNPAID_LINES := ["付款已完成,獎勵還在確認中。"]
const UNPAID_PENDING_LINES := ["付款還在處理中。", "完成後會自動發放,不必重買。"]
const BUNDLE_LINE := "商城道具 各 2 個"
const REMOVE_ADS_LINE := "廣告已移除"


## 商品資料:{id, kind, price(金塊;Google Play 商品為台幣), name, desc, count(獲得數量)};
## kind = "gold" / "remove_ads"(Google Play)、"item" / "bundle" / "heart" / "coin"(用金塊買)。
## 金塊包另有 gold、silver;道具另有 item(序號)。不認得的 id 回傳空字典。
static func product(id: String) -> Dictionary:
	var p := id.split(":")
	match p[0]:
		"gold":
			for pack in GOLD_PACKS:
				if pack[0] == int(p[1]):
					return {"id": id, "kind": "gold", "price": pack[0], "gold": pack[0], "silver": pack[1], "count": pack[0]}
		"remove_ads":
			return {"id": id, "kind": "remove_ads", "price": REMOVE_ADS_TWD, "silver": REMOVE_ADS_SILVER, "count": 1}
		"item":
			var n := int(p[2])
			return {"id": id, "kind": "item", "item": int(p[1]), "count": n, "name": EventLogic.SHOP_ITEMS[int(p[1])],
				"desc": "×%d" % n, "price": ITEM_PRICE if n == 1 else ITEM_PACK_PRICE}
		"bundle":
			return {"id": id, "kind": "bundle", "count": BUNDLE_EACH, "name": "道具綜合禮包",
				"desc": "全部 10 種道具各 2 個", "price": BUNDLE_PRICE}
		"heart", "coin":
			var packs: Array = HEART_PACKS if p[0] == "heart" else COIN_PACKS
			for pack in packs:
				if pack[0] == int(p[1]):
					return {"id": id, "kind": p[0], "count": pack[0], "name": "愛心" if p[0] == "heart" else "金幣",
						"desc": "×%d" % pack[0], "price": pack[1]}
	return {}


## 是否走 Google Play(D19);否則是用金塊買(D23)
static func is_iap(id: String) -> bool:
	return id == "remove_ads" or id.begins_with("gold:")


## D23 扣款:先扣銀塊再扣金塊(1:1,Q14)。回傳 [銀塊扣, 金塊扣]
static func split_cost(price: int, silver: int) -> Array[int]:
	var s := mini(maxi(silver, 0), price)
	return [s, price - s]


## 銀塊 + 金塊夠不夠付(D24)
static func can_afford(price: int, wallet: Dictionary) -> bool:
	return wallet.silver + wallet.gold >= price


## D15 / D25:持有 99 →「愛心已滿」(優先);持有 + 購買量 > 99 →「超過上限」
static func heart_card_state(hearts: int, count: int) -> HeartCard:
	if hearts >= HEART_MAX:
		return HeartCard.FULL
	if hearts + count > HEART_MAX:
		return HeartCard.OVER_CAP
	return HeartCard.NORMAL


## D17、D18 紅點:免費分頁任一項今天還有次數
static func free_badge(free_left: Array) -> bool:
	return free_left.any(func(n: int) -> bool: return n > 0)


## D07 最多能捲多少;e = 面板加高量(≥ 0)
static func max_scroll(tab: int, e: int) -> int:
	return maxi(0, CONTENT_HEIGHT[tab] - (VIEW_HEIGHT + e))


# ---- 提示框內容(沿用活動頁 RewardPopup 的格式:{kind, title, rewards, lines, wallet}) ----

## D21 / D26 購買成功;granted = 後端回傳的實際獲得量(愛心、金幣用);kind = "order" 為補發訂單
static func popup_purchase(p: Dictionary, granted: int, wallet: Dictionary, kind := "action") -> Dictionary:
	var rewards := []
	var lines := []
	match p.kind:
		"gold":
			rewards.append(["gold", p.gold])
			if p.silver > 0:
				rewards.append(["silver", p.silver])
		"remove_ads":
			rewards.append(["silver", p.silver])
			lines.append(REMOVE_ADS_LINE)
		"item":
			lines.append("%s ×%d" % [p.name, p.count])
		"bundle":
			lines.append(BUNDLE_LINE)
		"heart", "coin":
			rewards.append([p.kind, granted])
	return {"kind": kind, "title": EventLogic.TITLE_REWARD, "rewards": rewards, "lines": lines, "wallet": wallet}


## D22:pending = Google Play 回「待處理」的 (c) 版;否則 (a)(b) 版
static func popup_unpaid(pending: bool, wallet: Dictionary) -> Dictionary:
	return {"kind": "action", "title": TITLE_UNPAID, "rewards": [],
		"lines": UNPAID_PENDING_LINES if pending else UNPAID_LINES, "wallet": wallet}


## D25 安全網:愛心會超過上限
static func popup_heart_cap(hearts: int, count: int, wallet: Dictionary) -> Dictionary:
	return {"kind": "action", "title": "愛心會超過上限", "rewards": [],
		"lines": ["愛心最多 99 顆。", "你有 %d 顆,買 %d 顆會超過上限。" % [hearts, count]], "wallet": wallet}


## D12 看完廣告的「已獲得」;item_name 只有道具寶箱用
static func popup_free(row: int, granted: int, item_name: String, wallet: Dictionary) -> Dictionary:
	var rewards := []
	var lines := []
	match row:
		FREE_HEART:
			rewards.append(["heart", granted])
		FREE_COIN:
			rewards.append(["coin", granted])
		FREE_SILVER:
			rewards.append(["silver", granted])
		_:
			lines.append(EventLogic.item_line(item_name))
	return {"kind": "action", "title": EventLogic.TITLE_REWARD, "rewards": rewards, "lines": lines, "wallet": wallet}


# ---- 商城自己的提示框尺寸(框內座標,shop-purchase-flows.md) ----

## D23 確認框高:扣款列 1 列 270、2 列 298
static func confirm_height(split: Array) -> int:
	return 170 + 28 * deduct_rows(split) + 12 + 44 + 16


## 扣款量為 0 的列不顯示
static func deduct_rows(split: Array) -> int:
	return split.filter(func(n: int) -> bool: return n > 0).size()


## D27 詳情框高 = 174 + 22 × 說明行數
static func detail_height(item: int) -> int:
	return 174 + 22 * ITEM_LINES[item].size()
