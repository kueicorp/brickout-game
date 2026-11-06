class_name EventLogic
## 活動頁的純規則(不依賴畫面),供活動頁、首頁紅點、假活動服務與測試共用。
## 規格:docs/design/event/event-screen.md D01~D17、README「活動」。
## 狀態資料(status)的欄位:signed_count(本月已簽次數,無上限)、signed_today、claimed(已領的累積階)、topup_bought。

## 簽到格狀態(D09)
enum Cell { SIGNED, NEXT, TODAY, EMPTY }
## 累積卡狀態(D10);「處理中」「失敗」由畫面依請求狀態另外處理
enum Card { LOCKED, CLAIMABLE, CLAIMED }
## 活動頁目前畫面;NONE = 不在活動頁(首頁)
enum Page { NONE, LIST, CHECKIN, TOPUP }
## 返回鍵 / 返回鈕的結果(D01)
enum Back { CLOSE_POPUP, TO_LIST, TO_HOME, QUIT }

const GRID_SIZE := 28
const TIERS: Array[int] = [7, 14, 21, 28]
## 獎勵:[圖示 / 資源鍵, 數量];顯示順序先金幣後銀塊(D15、D10)。鍵同時是錢包欄位名稱
const DAILY_REWARD := [["coin", 1500], ["heart", 2]]
const TIER_REWARDS := {
	7: [["coin", 2000], ["silver", 1]],
	14: [["coin", 5000], ["silver", 2]],
	21: [["coin", 10000], ["silver", 5]],
	28: [["silver", 5]],
}
## 28 次階另有隨機商城道具 1 個
const ITEM_TIER := 28
const TOPUP_REWARD := [["gold", 300], ["silver", 150]]
## README「商城道具」的 10 種;隨機道具從中等機率抽(Q8),首儲禮包為各 1 個(Q4)
const SHOP_ITEMS: Array[String] = [
	"額外血量", "額外生命", "替換", "暗殺", "強化塗層",
	"衰弱", "颱風", "破甲", "貪婪", "技能大禮包",
]

const TITLE_REWARD := "已獲得"
const TITLE_MONTHLY := "上月未領取的累積獎勵已補發"
const TOPUP_ITEMS_LINE := "商城道具 各 1 個"

## 多個提示框依序跳出的優先順序(D17):補發訂單 → 月初補發 → 玩家操作
const POPUP_PRIORITY := {"order": 0, "monthly": 1, "action": 2}

# D17 / D15 提示框尺寸
const POPUP_REWARD_ROW := 40
const POPUP_TEXT_LINE := 22
const POPUP_TIER_BLOCK := 56
const POPUP_ITEM_TIER_BLOCK := 76
## 16 + 標題 28 + 12 = 內容區起點
const POPUP_CONTENT_TOP := 56
## 內容區下方 12 + 按鈕 44 + 16
const POPUP_BOTTOM := 72


## 第 n 格(1~28)的狀態。c = 本月已簽次數,s = 今天已簽(給工程師的需求「程式處理清單」)
static func cell_state(n: int, c: int, s: bool) -> Cell:
	# 簽滿 28 次(含剛簽第 28 次的當天)全是已簽、沒有金框(A14)
	if c >= GRID_SIZE:
		return Cell.SIGNED
	if s and n == c:
		return Cell.TODAY
	if n <= c:
		return Cell.SIGNED
	if not s and n == c + 1:
		return Cell.NEXT
	return Cell.EMPTY


## D07 摘要上行:≤ 28 次顯示分母,> 28 次拿掉
static func summary_text(c: int) -> String:
	if c <= GRID_SIZE:
		return "本月已簽 %d / %d 次" % [c, GRID_SIZE]
	return "本月已簽 %d 次" % c


static func card_state(tier: int, c: int, claimed: Array) -> Card:
	if tier in claimed:
		return Card.CLAIMED
	return Card.CLAIMABLE if c >= tier else Card.LOCKED


## D05「每日簽到」列紅點(D16 首頁活動按鈕目前同條件):今天未簽,或有已達成未領的累積獎勵
static func checkin_badge(c: int, s: bool, claimed: Array) -> bool:
	if not s:
		return true
	for tier in TIERS:
		if card_state(tier, c, claimed) == Card.CLAIMABLE:
			return true
	return false


## 返回鍵 / 返回手勢。popup_open = 有提示框開著;page = 活動頁目前畫面(不在活動頁為 NONE)
static func back_action(popup_open: bool, page: Page) -> Back:
	if popup_open:
		return Back.CLOSE_POPUP
	match page:
		Page.CHECKIN, Page.TOPUP:
			return Back.TO_LIST
		Page.LIST:
			return Back.TO_HOME
	return Back.QUIT


## 安全區不足時返回鈕與標題(D04)的下移量(README 活動頁版面第 9 點,方案 B)。
## avail = 畫面高 − 上安全區 − 下安全區;592 = 資源列下緣碰到返回鈕上緣的臨界值。
## shortcut: 最多只吃掉返回鈕與面板間的 8px 間距,avail < 584 時資源列仍會和返回鈕重疊;真的出現這種裝置時再請設計師定規格
static func header_shift(avail: int) -> int:
	return clampi(592 - avail, 0, 8)


# ---- 版面(docs/design/layout/screen-size-800.md S02、S03、S07) ----

## 活動頁外框。h = 畫面高,top / bottom = 安全區 T、B;E = h − T − B − 600(與首頁同算法)。
## 回傳:offset = 內容(以 640 高、T=24 的座標排)整塊下移量;extra = 面板加高量;
## header_shift = 返回鈕與標題再下移量;banner = banner 上緣。
## E ≥ 0:上方貼 T、E 全部加在面板(S02、S07)。
## E < 0:沿用 README 活動頁版面第 9 點(面板 434 高貼齊 banner、返回鈕下移),兩種排法在 E = 0 時相同。
static func event_layout(h: int, top: int, bottom: int) -> Dictionary:
	var avail := h - top - bottom
	var e := avail - HomeLogic.CONTENT_HEIGHT
	return {
		"offset": top - HomeLogic.SAFE_TOP_MIN + mini(e, 0),
		"extra": maxi(e, 0),
		"header_shift": header_shift(avail),
		"banner": h - bottom - 50,
	}


## B 每日簽到四段留白的增量 [a1, a2, a3, a4](15% / 30% / 30% / 餘數);e = 面板加高量(≥ 0)
static func checkin_gaps(e: int) -> Array[int]:
	var a1 := _round_div(15 * e, 100)
	var a2 := _round_div(30 * e, 100)
	return [a1, a2, a2, e - a1 - 2 * a2]


## C 首次儲值 5 等分的累計切點 [c1, c2, c3, c4] = round(k × e ÷ 5);用累計值避免誤差累積
static func topup_cuts(e: int) -> Array[int]:
	var out: Array[int] = []
	for k in range(1, 5):
		out.append(_round_div(k * e, 5))
	return out


## S08 方案 B:toast 上緣(活動頁內容座標,T=24 基準)= 436 + round(0.4E);e = 面板加高量(≥ 0)
static func toast_y(e: int) -> int:
	return 436 + _round_div(2 * e, 5)


## S08:D14 載入 / 失敗整組相對 640 版的下移量 = round(E ÷ 2),讓整組維持在加高面板的中央
static func state_shift(e: int) -> int:
	return _round_div(e, 2)


## n ÷ d 四捨五入、.5 進位(= floor(n / d + 0.5));n ≥ 0、d > 0,用整數算避免浮點誤差
static func _round_div(n: int, d: int) -> int:
	@warning_ignore("integer_division")
	return (2 * n + d) / (2 * d)


## 在等待中的提示框佇列插入一個新框,回傳插入位置。
## 第 0 個是畫面上正在顯示的框,不會被插隊;同優先順序依先後排隊。
static func popup_insert_index(queue: Array, kind: String) -> int:
	var p: int = POPUP_PRIORITY[kind]
	for i in range(1, queue.size()):
		if POPUP_PRIORITY[queue[i].kind] > p:
			return i
	return queue.size()


# ---- 提示框內容(D17 / D15) ----
# 一般框:{kind, title, rewards: [[鍵, 數量]...], lines: [文字...], wallet}
# 月初補發框:{kind: "monthly", title, tiers: [{tier, item_name}...], wallet}
# wallet = 該回應的最新資源值,關閉該框時才套用到資源列(D17)

static func popup_checkin(wallet: Dictionary) -> Dictionary:
	return {"kind": "action", "title": TITLE_REWARD, "rewards": DAILY_REWARD, "lines": [], "wallet": wallet}


static func popup_tier(tier: int, item_name: String, wallet: Dictionary) -> Dictionary:
	var lines := [item_line(item_name)] if tier == ITEM_TIER else []
	return {"kind": "action", "title": TITLE_REWARD, "rewards": TIER_REWARDS[tier], "lines": lines, "wallet": wallet}


## kind:"action" = 購買成功;"order" = 補發訂單(內容同購買成功)
static func popup_topup(kind: String, wallet: Dictionary) -> Dictionary:
	return {"kind": kind, "title": TITLE_REWARD, "rewards": TOPUP_REWARD, "lines": [TOPUP_ITEMS_LINE], "wallet": wallet}


## tiers 需由小到大排列(由服務保證)
static func popup_monthly(tiers: Array, wallet: Dictionary) -> Dictionary:
	return {"kind": "monthly", "title": TITLE_MONTHLY, "tiers": tiers, "wallet": wallet}


static func item_line(item_name: String) -> String:
	return "隨機道具:%s ×1" % item_name


## 提示框內容區高度:一般框每列最多 2 個獎勵(40 高)+ 文字行(22 高);月初補發每階 56,28 次階 76
static func popup_content_height(item: Dictionary) -> int:
	if item.has("tiers"):
		var h := 0
		for t in item.tiers:
			h += POPUP_ITEM_TIER_BLOCK if t.tier == ITEM_TIER else POPUP_TIER_BLOCK
		return h
	return ceili(item.rewards.size() / 2.0) * POPUP_REWARD_ROW + item.lines.size() * POPUP_TEXT_LINE


static func popup_frame_height(item: Dictionary) -> int:
	return POPUP_CONTENT_TOP + popup_content_height(item) + POPUP_BOTTOM
