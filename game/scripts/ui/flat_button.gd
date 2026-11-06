class_name FlatButton
extends PixelButton
## 活動頁的純色塊按鈕(簽到、領取、購買、重試、提示框「好」)與返回鈕(D04,無底板、只有 icon)。
## 按下時整顆變暗 40%;停用由 set_look 的 enabled 控制(灰色樣式由呼叫端給色)。

const GREEN := Color("#2ECC71")
const GRAY := Color("#555D6B")

## 透明 = 無底板
var fill := Color.TRANSPARENT
var text := ""
var text_color := Color.BLACK
var font_size := 14
## 文字 baseline(相對按鈕頂端)
var baseline := 27.0
var icon: Texture2D
var icon_size := Vector2.ZERO
var flip_icon := false


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
	if icon:
		var pos := ((size - icon_size) / 2.0).floor()
		# 負寬度 = 水平鏡像;起點不變(同 ThemeBarButton 的說明)
		var rect := Rect2(pos, Vector2(-icon_size.x, icon_size.y)) if flip_icon else Rect2(pos, icon_size)
		draw_texture_rect(icon, rect, false, PixelBox.darken(Color.WHITE, held))
	if text != "":
		PixelText.draw(self, Vector2(0, baseline), text, font_size, PixelBox.darken(text_color, held),
			Color.TRANSPARENT, size.x, HORIZONTAL_ALIGNMENT_CENTER)
