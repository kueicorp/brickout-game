## D29 的單一選項(280×112,整塊都是觸控區)。底與外框依狀態用矩形繪製(D29 第九節:選項不用圖)。
## 用 Button 的原因:放開時才觸發、手指移出選項就取消、只認第一根手指、鍵盤焦點與讀屏標籤,引擎都已內建。
class_name ChoiceOption
extends Button

const FONT_SIZE := 22
const PICKUP := [
	preload("res://art/items40/d32_item_pickup_f1.png"),
	preload("res://art/items40/d32_item_pickup_f2.png"),
	preload("res://art/items40/d32_item_pickup_f3.png"),
]
## D29 修訂(選項內座標):D32 圖 1 倍顯示;圖示與閃光同中心 (28, 56)。
const ICON_RECT := Rect2(8, 36, 40, 40)
const PICKUP_RECT := Rect2(4, 32, 48, 48)
## 名稱與說明文字的左緣與可用寬度(右端 x 271,畫面上 x 311)。
const TEXT_X := 56
const TEXT_W := 216

var golden := true
var item_id := ""
var reduced_motion := false
## 選中瞬間整列閃白(底 W、文字 K)。
var flash := false
## 選中後的 2 px 白外框。
var border_white := false
## 拾取效果目前的幀(0~2),-1 = 不畫。
var pickup_frame := -1
## 只有用鍵盤或外接裝置操作時才畫焦點框(觸控點選後不顯示)。
var show_focus := false
var _icons: Array[Texture2D] = []


func setup(is_golden: bool, id: String, reduced: bool) -> void:
	golden = is_golden
	item_id = id
	reduced_motion = reduced
	flat = true
	focus_mode = Control.FOCUS_ALL
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	accessibility_name = "%s，%s，按兩下選擇" % [ItemDefs.item_name(id), "，".join(ItemDefs.desc_lines(id))]
	_icons = [load(ItemDefs.icon_path(id, false)), load(ItemDefs.icon_path(id, true))]


func _draw() -> void:
	var mode := get_draw_mode()
	var pressing := not disabled and (mode == DRAW_PRESSED or mode == DRAW_HOVER_PRESSED)
	var bg := Pal.W if flash else (Pal.K if pressing else (Pal.YEL_D if golden else Pal.DEB_FACE))
	draw_rect(Rect2(Vector2.ZERO, size), bg)
	if pressing:
		_frame(2, Pal.YEL_A if golden else Pal.VIO_M)
	elif border_white or (show_focus and has_focus()):
		_frame(2, Pal.W)
	else:
		_frame(1, Pal.K)
		var light := Pal.YEL_C if golden else Pal.DEB_LIGHT
		draw_rect(Rect2(1, 1, size.x - 2, 1), light)
		draw_rect(Rect2(1, 2, 1, size.y - 3), light)
		if not golden:
			draw_rect(Rect2(2, size.y - 2, size.x - 3, 1), Pal.DEB_DARK)
			draw_rect(Rect2(size.x - 2, 2, 1, size.y - 4), Pal.DEB_DARK)

	# 圖示呼吸用全域時鐘,與場上掉落道具同相位(D20)
	var f2 := not reduced_motion and fmod(Time.get_ticks_msec() / 1000.0, 0.8) >= 0.4
	draw_texture_rect(_icons[1 if f2 else 0], ICON_RECT, false)

	# shortcut: Cubic 11 尚未下載,暫用 Godot 預設字型(中文靠系統字型備援);下載後改用 Cubic 11 22 px 並實測行寬
	var font := get_theme_default_font()
	var ascent := font.get_ascent(FONT_SIZE)
	var color := Pal.K if flash else Pal.W
	draw_string(font, Vector2(TEXT_X, 8 + ascent), ItemDefs.item_name(item_id), HORIZONTAL_ALIGNMENT_LEFT, TEXT_W, FONT_SIZE, color)
	var lines := ItemDefs.desc_lines(item_id)
	for i in lines.size():
		draw_string(font, Vector2(TEXT_X, 34 + 24 * i + ascent), lines[i], HORIZONTAL_ALIGNMENT_LEFT, TEXT_W, FONT_SIZE, color)

	if pickup_frame >= 0:
		draw_texture_rect(PICKUP[pickup_frame], PICKUP_RECT, false)


## 沿選項內緣畫 width px 寬的外框。
func _frame(width: int, color: Color) -> void:
	draw_rect(Rect2(0, 0, size.x, width), color)
	draw_rect(Rect2(0, size.y - width, size.x, width), color)
	draw_rect(Rect2(0, width, width, size.y - 2 * width), color)
	draw_rect(Rect2(size.x - width, width, width, size.y - 2 * width), color)
