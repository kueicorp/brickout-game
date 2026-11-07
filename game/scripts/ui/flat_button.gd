class_name FlatButton
extends PixelButton
## 純色塊按鈕(商城分頁籤、提示框的取消 / 關閉)。返回鈕已改由 PageShortcutBar 畫(page-shortcuts P07)。
## 綠色按鈕改用 GreenButton(九宮格圖)。
## 按下時整顆變暗 40%;停用由 set_look 的 enabled 控制(灰色樣式由呼叫端給色)。

const GREEN := Color("#2ECC71")
const GRAY := Color("#555D6B")

## 透明 = 無底板
var fill := Color.TRANSPARENT
## 1px 外框(畫在內側);透明 = 無框。商城分頁籤、提示框的次要鈕(取消、關閉)用
var border := Color.TRANSPARENT
## 右上角 12×12 紅點(商城 D18 免費分頁籤),按下時跟著變暗
var badge := false
var text := ""
var text_color := Color.BLACK
var font_size := 14
## 文字 baseline(相對按鈕頂端)
var baseline := 27.0


## 一次換掉外觀與可否點擊
func set_look(label: String, color: Color, label_color: Color, enabled: bool) -> void:
	text = label
	fill = color
	text_color = label_color
	disabled = not enabled
	queue_redraw()


## 綠底黑字可點 / 灰底白字不可點(活動頁按鈕只有這兩種外觀)
func set_active(label: String, active: bool) -> void:
	set_look(label, GREEN if active else GRAY, Color.BLACK if active else Color.WHITE, active)


func _draw() -> void:
	var held := is_held()
	if fill.a > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), PixelBox.darken(fill, held))
	if border.a > 0.0:
		PixelBox.draw_frame(self, Rect2(Vector2.ZERO, size), PixelBox.darken(border, held))
	if text != "":
		PixelText.draw(self, Vector2(0, baseline), text, font_size, PixelBox.darken(text_color, held),
			Color.TRANSPARENT, size.x, HORIZONTAL_ALIGNMENT_CENTER)
	if badge:
		PixelBox.draw_badge(self, Vector2(size.x - PixelBox.BADGE_SIZE, 0), held)
