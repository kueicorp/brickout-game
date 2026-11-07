class_name ShopDialog
extends Control
## 商城自己的置中提示框(shop-purchase-flows.md):D20 處理中、D23 確認購買、D24 金塊不足、D27 道具詳情。
## 「已獲得」「付款處理中」「愛心會超過上限」只有文字與「好」,沿用首頁持有的 RewardPopup,不在這裡。
## 框體同活動頁 D17:遮罩 #000000 alpha 160、框寬 296、x 32、垂直置中於整個螢幕;以下座標為框內座標。
## 節點放在商城原點、大小 360×畫面高(擋住下層所有操作);遮罩畫滿整個 viewport。

signal confirmed(product_id: String)
signal go_topup

enum Mode { NONE, PROCESSING, CONFIRM, SHORT, DETAIL }

const MASK := Color(0, 0, 0, 160.0 / 255.0)
const BG := Color("#222B3A")
const BORDER := Color("#5D6D7E")
const SUB := Color("#B0B8C4")
const GOLD := Color("#F4C430")
const CLOSE_BG := Color("#3A4556")
const CANCEL_DISABLED := Color("#7B8494")
const FRAME_X := 32
const FRAME_W := 296
const NO_OUTLINE := Color.TRANSPARENT
const RESOURCE_ICONS := {
	"silver": preload("res://assets/ui/resource/silver.png"),
	"gold": preload("res://assets/ui/resource/gold.png"),
	"heart": preload("res://assets/ui/resource/heart.png"),
	"coin": preload("res://assets/ui/resource/coin.png"),
}

var mode := Mode.NONE
## D23 購買請求送出後:按鈕停用、返回鍵無效
var busy := false

var _product := {}
var _wallet := {}
var _price := 0
var _item := 0
var _primary: GreenButton
var _secondary: FlatButton


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_primary = GreenButton.new()
	_primary.pressed.connect(_on_primary)
	add_child(_primary)
	_secondary = FlatButton.new()
	_secondary.border = BORDER
	_secondary.pressed.connect(close)
	add_child(_secondary)
	resized.connect(_relayout)


func is_open() -> bool:
	return mode != Mode.NONE


## D20:付款完成、等後端驗證
func open_processing() -> void:
	_open(Mode.PROCESSING)


## D23:p = ShopLogic.product(...);wallet = 目前錢包(算扣款列與餘額)
func open_confirm(p: Dictionary, wallet: Dictionary) -> void:
	_product = p
	_wallet = wallet
	busy = false
	_open(Mode.CONFIRM)


## D24:price = 需要的金塊;wallet = 目前錢包
func open_short(price: int, wallet: Dictionary) -> void:
	_price = price
	_wallet = wallet
	_open(Mode.SHORT)


## D27:item = 道具序號(EventLogic.SHOP_ITEMS)
func open_detail(item: int) -> void:
	_item = item
	_open(Mode.DETAIL)


func close() -> void:
	mode = Mode.NONE
	busy = false
	visible = false


## D23 送出購買後:購買鈕「處理中…」、取消鈕文字變灰,都不可點
func set_busy(on: bool) -> void:
	busy = on
	_relayout()


## 返回鍵 / 返回手勢:處理中無效,其他視同取消 / 關閉
func back() -> void:
	if mode == Mode.PROCESSING or busy:
		return
	close()


func frame_rect() -> Rect2:
	var h := 0
	match mode:
		Mode.PROCESSING:
			h = 88
		Mode.CONFIRM:
			h = ShopLogic.confirm_height(_split())
		Mode.SHORT:
			h = 194
		Mode.DETAIL:
			h = ShopLogic.detail_height(_item)
	return Rect2(FRAME_X, floorf((size.y - h) / 2.0), FRAME_W, h)


func _open(m: Mode) -> void:
	mode = m
	visible = true
	_relayout()


func _split() -> Array[int]:
	return ShopLogic.split_cost(_product.price, _wallet.silver)


func _on_primary() -> void:
	if mode == Mode.CONFIRM and not busy:
		confirmed.emit(_product.id)
	elif mode == Mode.SHORT:
		close()
		go_topup.emit()


## 依模式擺放按鈕:雙鈕各 128×44(框內 x 16 取消、x 152 主要);D27 單鈕 216×44(x 40)
func _relayout() -> void:
	if not is_open():
		return
	var fr := frame_rect()
	var button_y := fr.end.y - 16 - 44
	_primary.visible = mode == Mode.CONFIRM or mode == Mode.SHORT
	_secondary.visible = mode != Mode.PROCESSING
	_primary.position = Vector2(fr.position.x + 152, button_y)
	_primary.size = Vector2(128, 44)
	_secondary.position = Vector2(fr.position.x + 16, button_y)
	_secondary.size = Vector2(128, 44)
	match mode:
		Mode.CONFIRM:
			_primary.set_active("處理中…" if busy else "購買", not busy)
			_secondary.set_look("取消", BG, CANCEL_DISABLED if busy else Color.WHITE, not busy)
		Mode.SHORT:
			_primary.set_active("去儲值", true)
			_secondary.set_look("取消", BG, Color.WHITE, true)
		Mode.DETAIL:
			_secondary.position.x = fr.position.x + 40
			_secondary.size.x = 216
			_secondary.set_look("關閉", CLOSE_BG, Color.WHITE, true)
	queue_redraw()


## D27:點遮罩空白處關閉(純說明,可點外面關);其他框點遮罩不關閉(防誤觸)
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed \
			and mode == Mode.DETAIL and not frame_rect().has_point(event.position):
		close()
	accept_event()


func _draw() -> void:
	if not is_open():
		return
	draw_rect(Rect2(-global_position, get_viewport_rect().size), MASK)
	var fr := frame_rect()
	draw_rect(fr, BORDER)
	draw_rect(fr.grow(-1), BG)
	var o := fr.position
	match mode:
		Mode.PROCESSING:
			_center(o, 38, "處理中…", 18, Color.WHITE)
			_center(o, 62, "請稍候,不要關閉遊戲", 12, SUB)
		Mode.CONFIRM:
			_draw_confirm(o)
		Mode.SHORT:
			_draw_short(o)
		Mode.DETAIL:
			_draw_detail(o)


func _text(o: Vector2, pos: Vector2, text: String, px: int, color: Color) -> void:
	PixelText.draw(self, o + pos, text, px, color, NO_OUTLINE)


func _center(o: Vector2, baseline: float, text: String, px: int, color: Color) -> void:
	PixelText.draw(self, o + Vector2(16, baseline), text, px, color, NO_OUTLINE, 264, HORIZONTAL_ALIGNMENT_CENTER)


## 右對齊到框內 x right
func _right(o: Vector2, right: float, baseline: float, text: String, px: int, color: Color) -> void:
	PixelText.draw(self, o + Vector2(16, baseline), text, px, color, NO_OUTLINE, right - 16, HORIZONTAL_ALIGNMENT_RIGHT)


## D23 確認購買
func _draw_confirm(o: Vector2) -> void:
	var p := _product
	_center(o, 37, "確認購買", 18, Color.WHITE)
	match p.kind:
		"item":
			draw_texture(ShopPage.ITEM_ICONS[p.item], o + Vector2(22, 62))
		"bundle":
			draw_texture(ShopPage.ICON_BUNDLE, o + Vector2(22, 62))
		_:
			# 愛心、金幣:25×25 置中於 48×48 格(框內 x 27、y 68)
			draw_texture(RESOURCE_ICONS[p.kind], o + Vector2(27, 68))
	_text(o, Vector2(76, 78), p.name, 16, Color.WHITE)
	var desc: String = p.desc
	if p.kind == "heart":
		var h: int = _wallet.heart
		desc = "×%d  愛心 %d → %d" % [p.count, h, h + p.count]
	_text(o, Vector2(76, 98), desc, 12, SUB)
	draw_rect(Rect2(o + Vector2(16, 116), Vector2(264, 1)), BORDER)
	_text(o, Vector2(16, 140), "價格", 14, SUB)
	_right(o, 280, 140, "%d 金塊" % p.price, 14, Color.WHITE)
	_text(o, Vector2(16, 162), "扣款:先扣銀塊,不足再扣金塊", 12, SUB)
	var split := _split()
	var y := 170
	for i in 2:
		if split[i] <= 0:
			continue
		var key := "silver" if i == 0 else "gold"
		draw_texture(RESOURCE_ICONS[key], o + Vector2(16, y + 2))
		_text(o, Vector2(49, y + 19), "銀塊" if i == 0 else "金塊", 14, Color.WHITE)
		_right(o, 190, y + 19, "−%d" % split[i], 14, Color.WHITE)
		_right(o, 280, y + 19, "剩 %d" % (_wallet[key] - split[i]), 12, SUB)
		y += 28


## D24 金塊不足
func _draw_short(o: Vector2) -> void:
	var silver: int = _wallet.silver
	var gold: int = _wallet.gold
	_center(o, 37, "金塊不足", 18, Color.WHITE)
	_text(o, Vector2(16, 72), "需要", 14, SUB)
	_right(o, 280, 72, "%d 金塊" % _price, 14, Color.WHITE)
	_text(o, Vector2(16, 94), "你有", 14, SUB)
	var have := "銀塊 %d + 金塊 %d" % [silver, gold] if silver > 0 else "金塊 %d" % gold
	_right(o, 280, 94, have, 14, Color.WHITE)
	_text(o, Vector2(16, 116), "還差", 14, SUB)
	_right(o, 280, 116, "%d 金塊" % (_price - silver - gold), 14, GOLD)


## D27 道具詳情
func _draw_detail(o: Vector2) -> void:
	draw_texture(ShopPage.ITEM_ICONS[_item], o + Vector2(22, 22))
	_text(o, Vector2(76, 38), EventLogic.SHOP_ITEMS[_item], 18, Color.WHITE)
	if _item == ShopLogic.BOSS_ONLY_ITEM:
		draw_rect(Rect2(o + Vector2(76, 44), Vector2(100, 20)), GOLD)
		PixelText.draw(self, o + Vector2(76, 58), ShopLogic.BOSS_ONLY_TAG, 12, Color.BLACK, NO_OUTLINE, 100,
			HORIZONTAL_ALIGNMENT_CENTER)
	var lines: Array = ShopLogic.ITEM_LINES[_item]
	for i in lines.size():
		_text(o, Vector2(16, 92 + 22 * i), lines[i], 14, Color.WHITE)
	_text(o, Vector2(16, 97 + 22 * lines.size()), "只在本關有效", 12, SUB)
