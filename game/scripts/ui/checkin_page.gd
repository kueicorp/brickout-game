class_name CheckinPage
extends Control
## 畫面 B 每日簽到的內容:D07 摘要與簽到鈕、D09 28 格、D10 4 張累積卡。
## 只負責畫面;請求由活動頁(EventScreen)發出,結果透過 show_status 回來。
## 節點放在活動頁內容原點,以下座標都是 360×640 基準的畫面座標;面板加高時由 set_extra 把 E 分進四段留白
## (screen-size-800 S02 B)。

signal checkin_pressed
signal claim_pressed(tier: int)

const COIN := preload("res://assets/ui/resource/coin.png")
const SILVER := preload("res://assets/ui/resource/silver.png")
const SIGNED := preload("res://assets/ui/event/icon_signed.png")
const RANDOM_ITEM := preload("res://assets/ui/event/icon_random_item_36.png")

const SIGNED_BG := Color("#2E7D4F")
const EMPTY_BG := Color("#2A2F3A")
const GOLD := Color("#F4C430")
const EMPTY_NUMBER := Color("#999999")
const CARD_BG := Color("#222B3A")
const CARD_BORDER := Color("#5D6D7E")
const NO_OUTLINE := Color.TRANSPARENT
const CARD_Y := 428
const CARD_SIZE := Vector2(80, 137)

var signed_count := 0
var signed_today := false
var claimed: Array = []
## 處理中的請求:"checkin" 或累積階(7/14/21/28)
var busy := {}
## 三個區塊的上緣 y(D07 摘要、D09 28 格、D10 累積卡);640 高時為原值,set_extra 更新
var summary_y := 136
var grid_y := 194
var card_y := CARD_Y

var _checkin: GreenButton
var _claims := {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_checkin = _add_button(Rect2(250, 136, 96, 44))
	_checkin.pressed.connect(func() -> void: checkin_pressed.emit())
	for i in EventLogic.TIERS.size():
		var tier := EventLogic.TIERS[i]
		var b := _add_button(Rect2(_card_x(i) + 4, CARD_Y + 90, 72, 44))
		b.font_size = 12
		b.pressed.connect(func() -> void: claim_pressed.emit(tier))
		_claims[tier] = b
	_refresh()


func show_status(status: Dictionary) -> void:
	signed_count = status.signed_count
	signed_today = status.signed_today
	claimed = status.claimed
	_refresh()


## e = 面板加高量(≥ 0):前三段留白的增量累加到三個區塊的 y,第四段(餘數)留在累積卡下方
func set_extra(e: int) -> void:
	var a := EventLogic.checkin_gaps(e)
	summary_y = 136 + a[0]
	grid_y = 194 + a[0] + a[1]
	card_y = CARD_Y + a[0] + a[1] + a[2]
	_checkin.position.y = summary_y
	for tier in _claims:
		_claims[tier].position.y = card_y + 90
	queue_redraw()


func set_busy(key, on: bool) -> void:
	if on:
		busy[key] = true
	else:
		busy.erase(key)
	_refresh()


func _add_button(rect: Rect2) -> GreenButton:
	var b := GreenButton.new()
	b.position = rect.position
	b.size = rect.size
	add_child(b)
	return b


func _card_x(i: int) -> int:
	return 14 + i * 84


## 依狀態換按鈕外觀(D07、D10 狀態表)
func _refresh() -> void:
	if _checkin == null:
		return
	if busy.has("checkin"):
		_checkin.set_active("簽到中…", false)
	elif signed_today:
		_checkin.set_active("今日已簽", false)
	else:
		_checkin.set_active("今日簽到", true)
	for tier in _claims:
		var b: GreenButton = _claims[tier]
		match EventLogic.card_state(tier, signed_count, claimed):
			EventLogic.Card.CLAIMED:
				b.set_active("已領取", false)
			EventLogic.Card.LOCKED:
				b.set_active("還差 %d 次" % (tier - signed_count), false)
			_:
				if busy.has(tier):
					b.set_active("領取中…", false)
				else:
					b.set_active("領取", true)
	queue_redraw()


func _draw() -> void:
	# D07 摘要(兩行)
	PixelText.draw(self, Vector2(14, summary_y + 18), EventLogic.summary_text(signed_count), 14, Color.WHITE, NO_OUTLINE)
	PixelText.draw(self, Vector2(14, summary_y + 36), "每日 1500 金幣 + 2 愛心", 12, Color.WHITE, NO_OUTLINE)
	for n in range(1, EventLogic.GRID_SIZE + 1):
		_draw_cell(n)
	for i in EventLogic.TIERS.size():
		_draw_card(i)


## D09:第 n 次 → 列 (n−1)/7、欄 (n−1)%7
func _draw_cell(n: int) -> void:
	var pos := Vector2(14 + ((n - 1) % 7) * 48, grid_y + floori((n - 1) / 7.0) * 56)
	var rect := Rect2(pos, Vector2(44, 52))
	var state := EventLogic.cell_state(n, signed_count, signed_today)
	var signed := state == EventLogic.Cell.SIGNED or state == EventLogic.Cell.TODAY
	draw_rect(rect, SIGNED_BG if signed else EMPTY_BG)
	if state == EventLogic.Cell.NEXT or state == EventLogic.Cell.TODAY:
		PixelBox.draw_frame(self, rect, GOLD, 2)
	var number_color := EMPTY_NUMBER if state == EventLogic.Cell.EMPTY else Color.WHITE
	PixelText.draw(self, pos + Vector2(4, 14), str(n), 12, number_color, NO_OUTLINE)
	draw_texture(SIGNED if signed else COIN, pos + Vector2(10, 22))


## D10 卡片:未達成 / 已領取 1px 灰框;可領取 / 處理中 2px 金框;已領取時獎勵 icon 變暗 40%
func _draw_card(i: int) -> void:
	var tier := EventLogic.TIERS[i]
	var o := Vector2(_card_x(i), card_y)
	var rect := Rect2(o, CARD_SIZE)
	var state := EventLogic.card_state(tier, signed_count, claimed)
	draw_rect(rect, CARD_BG)
	if state == EventLogic.Card.CLAIMABLE:
		PixelBox.draw_frame(self, rect, GOLD, 2)
	else:
		PixelBox.draw_frame(self, rect, CARD_BORDER, 1)
	var dim := state == EventLogic.Card.CLAIMED
	var tint := PixelBox.darken(Color.WHITE, dim)
	PixelText.draw(self, o + Vector2(0, 13), "累積 %d 次" % tier, 12, Color.WHITE, NO_OUTLINE, 80, HORIZONTAL_ALIGNMENT_CENTER)
	var rewards: Array = EventLogic.TIER_REWARDS[tier]
	# 列 1:7、14、21 次為金幣;28 次為銀塊
	draw_texture(_icon(rewards[0][0]), o + Vector2(4, 18), tint)
	PixelText.draw(self, o + Vector2(33, 35), str(rewards[0][1]), 11, Color.WHITE, NO_OUTLINE)
	if tier == EventLogic.ITEM_TIER:
		# 列 2:隨機道具 36×36 放 (4, 50),「×1」放 x 44
		draw_texture(RANDOM_ITEM, o + Vector2(4, 50), tint)
		PixelText.draw(self, o + Vector2(44, 72), "×1", 11, Color.WHITE, NO_OUTLINE)
	else:
		draw_texture(_icon(rewards[1][0]), o + Vector2(4, 55), tint)
		PixelText.draw(self, o + Vector2(33, 72), str(rewards[1][1]), 11, Color.WHITE, NO_OUTLINE)


func _icon(key: String) -> Texture2D:
	return COIN if key == "coin" else SILVER
