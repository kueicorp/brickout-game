class_name EventListItem
extends PixelButton
## 活動列表的一列(event-screen D05,332×72,整列可點)。
## 按下整列變暗 40%(紅點跟著變暗);dimmed(首儲已購買)時圖示與名稱變暗 40%。

const BG := Color("#222B3A")
const BORDER := Color("#5D6D7E")
const SUBTITLE_COLOR := Color("#B0B8C4")
const ICON_POS := Vector2(12, 12)
const BADGE_POS := Vector2(52, 4)

var icon: Texture2D
var title := ""
var subtitle := ""
var badge := false
var dimmed := false


func set_state(sub: String, show_badge: bool, dim: bool) -> void:
	subtitle = sub
	badge = show_badge
	dimmed = dim
	queue_redraw()


func _draw() -> void:
	var held := is_held()
	draw_rect(Rect2(Vector2.ZERO, size), PixelBox.darken(BORDER, held))
	draw_rect(Rect2(Vector2.ONE, size - Vector2(2, 2)), PixelBox.darken(BG, held))
	# 已購買變暗與按下變暗會疊加(兩個條件都成立時更暗)
	var dim_icon := PixelBox.darken(PixelBox.darken(Color.WHITE, dimmed), held)
	draw_texture(icon, ICON_POS, dim_icon)
	if badge:
		PixelBox.draw_badge(self, BADGE_POS, held)
	PixelText.draw(self, Vector2(72, 32), title, 16, dim_icon, Color.TRANSPARENT)
	PixelText.draw(self, Vector2(72, 54), subtitle, 12, PixelBox.darken(SUBTITLE_COLOR, held), Color.TRANSPARENT)
	# 「>」置中於項內 x 312
	PixelText.draw(self, Vector2(292, 43), ">", 18, PixelBox.darken(Color.WHITE, held), Color.TRANSPARENT,
		40, HORIZONTAL_ALIGNMENT_CENTER)
