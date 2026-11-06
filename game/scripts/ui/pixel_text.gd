class_name PixelText
## Cubic 11 文字繪製。以「baseline」定位,方便依墨跡對齊設計稿。
## 實測(關閉反鋸齒):中文墨跡 = baseline −0.75×字級 ~ baseline +字級/12;12px 數字墨跡 = baseline −8 ~ baseline。
## Godot 的 outline_size 是總寬,2 = 外擴 1px,對應設計稿的「1px 外框」。

const FONT: Font = preload("res://assets/fonts/Cubic_11.ttf")
const OUTLINE_1PX := 2


## 畫一行字;outline 的 alpha 為 0 時不畫外框。width > 0 時依 align 在該寬度內對齊。
static func draw(ci: CanvasItem, baseline: Vector2, text: String, font_size: int, color: Color,
		outline := Color.BLACK, width := -1.0, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	if outline.a > 0.0:
		ci.draw_string_outline(FONT, baseline, text, align, width, font_size, OUTLINE_1PX, outline)
	ci.draw_string(FONT, baseline, text, align, width, font_size, color)
