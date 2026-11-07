class_name TopupPage
extends Control
## 畫面 C 首次儲值的內容(event-screen D11)。只負責畫面;購買請求由活動頁發出。
## 座標都是 360×640 基準的畫面座標;面板加高時由 set_extra 把 E 5 等分進留白(screen-size-800 S02 C)。

signal buy_pressed

const ROWS := [
	[preload("res://assets/ui/resource/gold_x2.png"), "300 金塊"],
	[preload("res://assets/ui/resource/silver_x2.png"), "150 銀塊"],
	[preload("res://assets/ui/event/icon_random_item_36.png"), EventLogic.TOPUP_ITEMS_LINE],
]
const ROW_BG := Color("#222B3A")
const ROW_BORDER := Color("#5D6D7E")
const TITLE_COLOR := Color("#F4C430")
const NO_OUTLINE := Color.TRANSPARENT

var bought := false
var busy := false
## 標題、獎勵列 1、「限購 1 次」的上緣 y;640 高時為原值,set_extra 更新(購買鈕直接移節點)
var title_y := 138
var rows_y := 188
var note_y := 400

var _buy: GreenButton


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_buy = GreenButton.new()
	_buy.position = Vector2(72, 476)
	_buy.size = Vector2(216, 56)
	_buy.font_size = 18
	_buy.pressed.connect(func() -> void: buy_pressed.emit())
	add_child(_buy)
	_refresh()


func show_status(status: Dictionary) -> void:
	bought = status.topup_bought
	_refresh()


## e = 面板加高量(≥ 0);第 5 段(e − c4)留在購買鈕下方
func set_extra(e: int) -> void:
	var c := EventLogic.topup_cuts(e)
	title_y = 138 + c[0]
	rows_y = 188 + c[1]
	note_y = 400 + c[2]
	_buy.position.y = 476 + c[3]
	queue_redraw()


func set_busy(on: bool) -> void:
	busy = on
	_refresh()


func _refresh() -> void:
	if _buy == null:
		return
	if bought:
		_buy.set_active("已購買", false)
	elif busy:
		_buy.set_active("處理中…", false)
	else:
		_buy.set_active("TWD 300 購買", true)
	queue_redraw()


func _draw() -> void:
	PixelText.draw(self, Vector2(14, title_y + 20), "首次儲值禮包", 18, TITLE_COLOR, NO_OUTLINE, 332, HORIZONTAL_ALIGNMENT_CENTER)
	# 已購買:3 列獎勵(圖示與文字)變暗 40%
	var tint := PixelBox.darken(Color.WHITE, bought)
	for i in ROWS.size():
		var y := rows_y + i * 68
		var rect := Rect2(14, y, 332, 60)
		draw_rect(rect, ROW_BORDER)
		draw_rect(rect.grow(-1), ROW_BG)
		draw_texture(ROWS[i][0], Vector2(32, y + 12), tint)
		PixelText.draw(self, Vector2(86, y + 36), ROWS[i][1], 16, tint, NO_OUTLINE)
	PixelText.draw(self, Vector2(14, note_y + 14), "限購 1 次", 12, Color.WHITE, NO_OUTLINE, 332, HORIZONTAL_ALIGNMENT_CENTER)
