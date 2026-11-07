class_name ShopPage
extends Control
## 商城捲動內容區(shop-screen D07~D12、D15、D16):畫目前分頁的全部卡片 / 列,自己處理點擊與上下拖動捲動。
## 卡片與按鈕不是獨立節點:整張卡和卡內價格鈕是同一個觸控(D08、D19),而且拖動超過 8px 要取消點擊,
## 所以跟 LevelMap 一樣由一個節點統一判斷(同首頁地圖的做法)。
## 節點放在內容區左上(畫面 x 14、y 190 + 位移),寬 337(含 x 347~351 的捲軸)、高 = 370 + E,裁切超出部分。
## 以下座標都是「內容座標」= 設計稿畫面座標 −(14, 190),捲動時整體往上移 scroll。

## 點了某個可點元素:action = "iap"(金塊包 / 移除廣告)、"buy"(用金塊買)、"detail"(道具詳情,arg = 道具序號字串)、"ad"(看廣告,arg = 列序字串)
signal tapped(action: String, arg: String)

const ICON_GOLD := preload("res://assets/ui/resource/gold.png")
const ICON_HEART := preload("res://assets/ui/resource/heart.png")
const ICON_COIN := preload("res://assets/ui/resource/coin.png")
const ICON_REMOVE_ADS := preload("res://assets/ui/shop/remove_ads.png")
const ICON_BUNDLE := preload("res://assets/ui/shop/bundle_all_items.png")
## 順序同 EventLogic.SHOP_ITEMS
const ITEM_ICONS := [
	preload("res://assets/ui/shop/item_extra_hp.png"),
	preload("res://assets/ui/shop/item_extra_life.png"),
	preload("res://assets/ui/shop/item_swap.png"),
	preload("res://assets/ui/shop/item_assassinate.png"),
	preload("res://assets/ui/shop/item_coating.png"),
	preload("res://assets/ui/shop/item_weaken.png"),
	preload("res://assets/ui/shop/item_typhoon.png"),
	preload("res://assets/ui/shop/item_armor_break.png"),
	preload("res://assets/ui/shop/item_greed.png"),
	preload("res://assets/ui/shop/item_skill_pack.png"),
]
## 順序同 ShopLogic.FREE_ROWS
const FREE_ICONS := [
	preload("res://assets/ui/shop/free_heart_ad.png"),
	preload("res://assets/ui/shop/chest_coin.png"),
	preload("res://assets/ui/shop/chest_silver.png"),
	preload("res://assets/ui/shop/chest_item.png"),
]

const BG := Color("#222B3A")
const BORDER := Color("#5D6D7E")
const GOLD := Color("#F4C430")
const SUB := Color("#B0B8C4")
const GRAY_BG := Color("#555D6B")
## 捲軸顏色:設計稿只寫位置與寬度,色碼取自預覽 SVG
const SCROLLBAR := Color("#888888")
const DIM := Color(PixelBox.DARKEN, PixelBox.DARKEN, PixelBox.DARKEN, 1.0)
const NO_OUTLINE := Color.TRANSPARENT
## 拖動超過 8px 視為捲動(D07)
const DRAG_SLOP := 8.0
## 36×36 圖示放在 48×48 圖示格中置中
const ICON_INSET := Vector2(6, 6)
const CONTENT_WIDTH := 332

var tab: int = ShopLogic.Tab.TOPUP
var scroll := 0
## 商城取得的狀態(ShopService.fetch_status 的欄位);只在已載入時顯示本節點
var status := {}
## 正在載入 / 播放廣告的免費列(−1 = 沒有)
var ad_busy := -1
## 面板加高量 E(≥ 0)
var extra := 0

## 可點元素:{key, rect(內容座標), action, arg},依目前分頁與狀態建立
var _targets: Array[Dictionary] = []
var _pressed_key := ""
var _tracking := false
var _dragging := false
var _start := Vector2.ZERO
var _start_scroll := 0


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP


## 換分頁 / 狀態後重建可點元素並重畫;reset_scroll = 回到頂端(切換分頁時,D06)
func refresh(reset_scroll := false) -> void:
	if reset_scroll:
		scroll = 0
	scroll = clampi(scroll, 0, ShopLogic.max_scroll(tab, extra))
	_targets = _build_targets()
	if not _targets.any(func(t: Dictionary) -> bool: return t.key == _pressed_key):
		_pressed_key = ""
	queue_redraw()


func target_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for t in _targets:
		out.append(t.rect)
	return out


# ---- 狀態判斷 ----

func _price(id: String) -> String:
	return status.prices.get(id, "")


## Google Play 商品可點:價格已到達,且沒有處理中 / 未發放的同商品(D19)
func _iap_enabled(id: String) -> bool:
	return _price(id) != "" and not status.pending_products.has(id)


func _hearts() -> int:
	return status.wallet.heart


# ---- 可點元素 ----

func _build_targets() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if status.is_empty():
		return out
	match tab:
		ShopLogic.Tab.TOPUP:
			for i in ShopLogic.GOLD_PACKS.size():
				var id := "gold:%d" % ShopLogic.GOLD_PACKS[i][0]
				if _iap_enabled(id):
					out.append(_target(id, _gold_card_rect(i), "iap", id))
			if not status.remove_ads_bought and _iap_enabled("remove_ads"):
				out.append(_target("remove_ads", Rect2(0, 448, 332, 72), "iap", "remove_ads"))
		ShopLogic.Tab.ITEMS:
			out.append(_target("bundle", Rect2(0, 0, 332, 80), "buy", "bundle"))
			for i in ITEM_ICONS.size():
				var y := _item_row_y(i)
				out.append(_target("detail:%d" % i, Rect2(0, y, 148, 64), "detail", str(i)))
				out.append(_target("item:%d:1" % i, Rect2(156, y + 8, 80, 48), "buy", "item:%d:1" % i))
				out.append(_target("item:%d:11" % i, Rect2(240, y + 8, 80, 48), "buy", "item:%d:11" % i))
		ShopLogic.Tab.HEART_COIN:
			for i in ShopLogic.HEART_PACKS.size():
				var n: int = ShopLogic.HEART_PACKS[i][0]
				if ShopLogic.heart_card_state(_hearts(), n) == ShopLogic.HeartCard.NORMAL:
					out.append(_target("heart:%d" % n, _small_card_rect(i, 28), "buy", "heart:%d" % n))
			for i in ShopLogic.COIN_PACKS.size():
				var id := "coin:%d" % ShopLogic.COIN_PACKS[i][0]
				out.append(_target(id, _small_card_rect(i, 248), "buy", id))
		ShopLogic.Tab.FREE:
			for i in ShopLogic.FREE_ROWS.size():
				if ad_busy != i and status.free_left[i] > 0:
					out.append(_target("ad:%d" % i, Rect2(228, 92 * i + 20, 96, 44), "ad", str(i)))
	return out


func _target(key: String, rect: Rect2, action: String, arg: String) -> Dictionary:
	return {"key": key, "rect": rect, "action": action, "arg": arg}


## D08:2 欄 × 4 列,162×104,欄 x 0 / 170、列間距 112
func _gold_card_rect(i: int) -> Rect2:
	return Rect2((i % 2) * 170, floori(i / 2.0) * 112, 162, 104)


## D15、D16:2 欄,162×88,列間距 96;top = 該區第 1 列 y
func _small_card_rect(i: int, top: int) -> Rect2:
	return Rect2((i % 2) * 170, top + floori(i / 2.0) * 96, 162, 88)


## D11:第 i 列 y(綜合禮包 80 + 間隔 8 之後,每列 72)
func _item_row_y(i: int) -> int:
	return 88 + 72 * i


# ---- 觸控:點擊與上下拖動 ----

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_tracking = true
			_dragging = false
			_start = event.position
			_start_scroll = scroll
			_set_pressed(_key_at(event.position))
		elif _tracking:
			_tracking = false
			var key := _pressed_key
			_set_pressed("")
			if not _dragging and not event.canceled and key != "" and _key_at(event.position) == key:
				for t in _targets:
					if t.key == key:
						tapped.emit(t.action, t.arg)
		accept_event()
	elif event is InputEventMouseMotion and _tracking:
		var delta: Vector2 = event.position - _start
		if not _dragging and delta.length() > DRAG_SLOP:
			_dragging = true
			_set_pressed("")
		if _dragging:
			# shortcut: 內容直接跟手指、放開即停,沒有慣性甩動與邊界回彈;實機試玩覺得卡頓時再加
			scroll = clampi(_start_scroll - roundi(delta.y), 0, ShopLogic.max_scroll(tab, extra))
			queue_redraw()
		elif _key_at(event.position) != _pressed_key:
			# 手指移出按下的元素:按下外觀消失(放開也不觸發),同 BaseButton
			_set_pressed("")
		accept_event()


func _notification(what: int) -> void:
	# 系統中斷(來電、切 App):取消目前觸控
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and _tracking:
		_tracking = false
		_set_pressed("")


func _key_at(pos: Vector2) -> String:
	var p := pos + Vector2(0, scroll)
	for t in _targets:
		if t.rect.has_point(p):
			return t.key
	return ""


func _set_pressed(key: String) -> void:
	if key != _pressed_key:
		_pressed_key = key
		queue_redraw()


func _held(key: String) -> bool:
	return _pressed_key == key


# ---- 繪製 ----

func _draw() -> void:
	if status.is_empty():
		return
	draw_set_transform(Vector2(0, -scroll))
	match tab:
		ShopLogic.Tab.TOPUP:
			_draw_topup()
		ShopLogic.Tab.ITEMS:
			_draw_items()
		ShopLogic.Tab.HEART_COIN:
			_draw_heart_coin()
		ShopLogic.Tab.FREE:
			_draw_free()
	draw_set_transform(Vector2.ZERO)
	_draw_scrollbar()


## D07 捲軸:x 347(本節點 x 333)、寬 4;內容 > 可見高才出現
func _draw_scrollbar() -> void:
	var content: int = ShopLogic.CONTENT_HEIGHT[tab]
	var view := size.y
	if content <= view:
		return
	var h := roundf(view * view / content)
	var y := roundf(scroll * view / content)
	draw_rect(Rect2(CONTENT_WIDTH + 1, y, 4, h), SCROLLBAR)


func _draw_box(rect: Rect2, bg: Color, border: Color, tint: Color, border_width := 1) -> void:
	draw_rect(rect, bg * tint)
	PixelBox.draw_frame(self, rect, border * tint, border_width)


## 文字(以 baseline 定位),tint 乘上顏色
func _text(pos: Vector2, text: String, px: int, color: Color, tint := Color.WHITE) -> void:
	PixelText.draw(self, pos, text, px, color * tint, NO_OUTLINE)


## 卡片 / 列整張變暗 40%:按下時;按鈕仍顯示按下圖(取代變暗)
func _tint(dim: bool) -> Color:
	return DIM if dim else Color.WHITE


## D08 金塊包 8 張、D09 移除廣告
func _draw_topup() -> void:
	for i in ShopLogic.GOLD_PACKS.size():
		var pack: Array = ShopLogic.GOLD_PACKS[i]
		var id := "gold:%d" % pack[0]
		var o := _gold_card_rect(i).position
		var held := _held(id)
		var tint := _tint(held)
		_draw_box(Rect2(o, Vector2(162, 104)), BG, BORDER, tint)
		draw_texture(ICON_GOLD, o + Vector2(8, 10), tint)
		_text(o + Vector2(40, 28), "%d 金塊" % pack[0], 16, Color.WHITE, tint)
		if pack[1] > 0:
			_text(o + Vector2(8, 47), "贈 %d 銀塊" % pack[1], 12, SUB, tint)
		_draw_price(Rect2(o + Vector2(7, 52), Vector2(148, 44)), _iap_enabled(id), held, _price(id))
	var o := Vector2(0, 448)
	var bought: bool = status.remove_ads_bought
	var held := _held("remove_ads")
	var tint := _tint(held or bought)
	_draw_box(Rect2(o, Vector2(332, 72)), BG, BORDER, tint)
	draw_texture(ICON_REMOVE_ADS, o + Vector2(12, 12) + ICON_INSET, tint)
	_text(o + Vector2(72, 26), "移除廣告", 16, Color.WHITE, tint)
	_text(o + Vector2(72, 44), "贈 %d 銀塊" % ShopLogic.REMOVE_ADS_SILVER, 12, SUB, tint)
	var button := Rect2(o + Vector2(228, 14), Vector2(96, 44))
	if bought:
		GreenButton.draw_button(self, button, false, false, "已購買", 14, Color.WHITE)
	else:
		_draw_price(button, _iap_enabled("remove_ads"), held, _price("remove_ads"))


## Google Play 價格鈕:價格未到或同商品處理中 → 停用圖、文字「—」(D08、D19)
func _draw_price(rect: Rect2, enabled: bool, held: bool, price: String) -> void:
	if enabled:
		GreenButton.draw_button(self, rect, true, held, price, 14, Color.BLACK)
	else:
		GreenButton.draw_button(self, rect, false, false, "—", 14, Color.WHITE)


## D10 綜合禮包、D11 10 種道具
func _draw_items() -> void:
	var held := _held("bundle")
	var tint := _tint(held)
	_draw_box(Rect2(0, 0, 332, 80), BG, GOLD, tint, 2)
	draw_texture(ICON_BUNDLE, Vector2(12, 16) + ICON_INSET, tint)
	_text(Vector2(72, 34), "道具綜合禮包", 16, Color.WHITE, tint)
	_text(Vector2(72, 56), "全部 10 種道具各 2 個", 12, SUB, tint)
	GreenButton.draw_button(self, Rect2(228, 18, 96, 44), true, held, "%d 金塊" % ShopLogic.BUNDLE_PRICE, 14, Color.BLACK)
	for i in ITEM_ICONS.size():
		var y := _item_row_y(i)
		_draw_box(Rect2(0, y, 332, 64), BG, BORDER, Color.WHITE)
		# 圖示 / 名稱區(列內 x 0~148)按下時該區變暗 40%
		var info_tint := _tint(_held("detail:%d" % i))
		if _held("detail:%d" % i):
			_draw_box(Rect2(0, y, 148, 64), BG, BORDER, info_tint)
		draw_texture(ITEM_ICONS[i], Vector2(12, y + 8) + ICON_INSET, info_tint)
		_text(Vector2(68, y + 30), EventLogic.SHOP_ITEMS[i], 14, Color.WHITE, info_tint)
		var single := "item:%d:1" % i
		var pack := "item:%d:11" % i
		GreenButton.draw_button(self, Rect2(156, y + 8, 80, 48), true, _held(single),
			"單買\n%d 金塊" % ShopLogic.ITEM_PRICE, 12, Color.BLACK)
		GreenButton.draw_button(self, Rect2(240, y + 8, 80, 48), true, _held(pack),
			"%d 個\n%d 金塊" % [ShopLogic.ITEM_PACK_COUNT, ShopLogic.ITEM_PACK_PRICE], 12, Color.BLACK)


## D15 愛心區、D16 金幣區
func _draw_heart_coin() -> void:
	_draw_section(0, "愛心")
	for i in ShopLogic.HEART_PACKS.size():
		var pack: Array = ShopLogic.HEART_PACKS[i]
		var state := ShopLogic.heart_card_state(_hearts(), pack[0])
		var gray := ""
		if state == ShopLogic.HeartCard.FULL:
			gray = "愛心已滿"
		elif state == ShopLogic.HeartCard.OVER_CAP:
			gray = "超過上限"
		_draw_small_card(_small_card_rect(i, 28).position, ICON_HEART, "%d 愛心" % pack[0], pack[1],
			"heart:%d" % pack[0], gray)
	_draw_section(220, "金幣")
	for i in ShopLogic.COIN_PACKS.size():
		var pack: Array = ShopLogic.COIN_PACKS[i]
		_draw_small_card(_small_card_rect(i, 248).position, ICON_COIN, "%d 金幣" % pack[0], pack[1],
			"coin:%d" % pack[0], "")


## 區標題 332×24:文字 14px 金(基線 +15)、底線 1px(+23)
func _draw_section(y: int, title: String) -> void:
	_text(Vector2(0, y + 15), title, 14, GOLD)
	draw_rect(Rect2(0, y + 23, 332, 1), BORDER)


## 162×88 卡;gray 非空 = 灰卡(D15 愛心已滿 / 超過上限):卡底 #555D6B、內容變暗 40%、停用鈕顯示 gray 文字
func _draw_small_card(o: Vector2, icon: Texture2D, title: String, price: int, key: String, gray: String) -> void:
	var held := _held(key)
	var tint := _tint(held or gray != "")
	_draw_box(Rect2(o, Vector2(162, 88)), GRAY_BG if gray != "" else BG, BORDER, Color.WHITE if gray != "" else tint)
	draw_texture(icon, o + Vector2(8, 6), tint)
	_text(o + Vector2(40, 26), title, 16, Color.WHITE, tint)
	var button := Rect2(o + Vector2(7, 36), Vector2(148, 44))
	if gray != "":
		GreenButton.draw_button(self, button, false, false, gray, 14, Color.WHITE)
	else:
		GreenButton.draw_button(self, button, true, held, "%d 金塊" % price, 14, Color.BLACK)


## D12 免費 4 列
func _draw_free() -> void:
	for i in ShopLogic.FREE_ROWS.size():
		var row: Array = ShopLogic.FREE_ROWS[i]
		var o := Vector2(0, 92 * i)
		var left: int = status.free_left[i]
		# 今天次數用完:整列文字變暗 40%
		var tint := _tint(left <= 0)
		_draw_box(Rect2(o, Vector2(332, 84)), BG, BORDER, Color.WHITE)
		draw_texture(FREE_ICONS[i], o + Vector2(12, 18) + ICON_INSET)
		_text(o + Vector2(72, 28), row[0], 16, Color.WHITE, tint)
		_text(o + Vector2(72, 48), row[1], 12, SUB, tint)
		_text(o + Vector2(72, 66), "今天剩 %d / %d 次" % [left, row[2]], 12, SUB, tint)
		var button := Rect2(o + Vector2(228, 20), Vector2(96, 44))
		if ad_busy == i:
			GreenButton.draw_button(self, button, false, false, "載入中…", 14, Color.WHITE)
		elif left <= 0:
			GreenButton.draw_button(self, button, false, false, "明天再來", 14, Color.WHITE)
		else:
			GreenButton.draw_button(self, button, true, _held("ad:%d" % i), "看廣告", 14, Color.BLACK)
