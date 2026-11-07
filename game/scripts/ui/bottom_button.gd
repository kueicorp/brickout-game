class_name BottomButton
extends PixelButton
## 底部功能列的一格(83×72,bottom-buttons-confirmed D19):icon 64×64 貼上緣、x 9;
## 文字區 y 56~72 置中,15px 白字 + 1px 黑框。按下:icon RGB 乘 0.6、文字縮成 12px,位置不動。

const ICON_POS := Vector2(9, 0)
## 文字區 y 56~72 內墨跡置中:15px 中文墨跡 14 列(baseline −11~+2)→ baseline 68;
## 12px 墨跡 11 列(baseline −9~+1)→ baseline 67
const BASELINE_NORMAL := 68.0
const BASELINE_PRESSED := 67.0

var icon: Texture2D
## 紅點位置(格內):活動 D16 對齊 icon 右上角 (61, 0);商城 D17 貼購物袋圖案右上角 (52, 2)。
## 不吃觸控,按下時跟 icon 一起變暗
var badge_pos := Vector2(61, 0)
var label := ""
var badge := false


func set_badge(value: bool) -> void:
	if value != badge:
		badge = value
		queue_redraw()


func _draw() -> void:
	var held := is_held()
	draw_texture(icon, ICON_POS, Color(0.6, 0.6, 0.6, 1.0) if held else Color.WHITE)
	if badge:
		PixelBox.draw_badge(self, badge_pos, held)
	var font_size := 12 if held else 15
	var baseline := Vector2(0, BASELINE_PRESSED if held else BASELINE_NORMAL)
	PixelText.draw(self, baseline, label, font_size, Color.WHITE, Color.BLACK, size.x, HORIZONTAL_ALIGNMENT_CENTER)
