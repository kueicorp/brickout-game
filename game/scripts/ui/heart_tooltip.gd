class_name HeartTooltip
extends Control
## D14 愛心回復倒數懸浮視窗。節點放在 (8, 72)、88×28:上方 4px 是小三角,下方 24px 是本體(畫面 y 76~100)。
## 本體 #1E2430 + 1px #F4C430、圓角 0;白字 12px + 1px 黑框,內距左 8、上 6。

const BODY := Rect2(0, 4, 88, 24)
const BODY_COLOR := Color("#1E2430")
const BORDER_COLOR := Color("#F4C430")
## 小三角:中心 x 31(畫面)→ 本節點 x 23;照示意圖 d14_tooltip_theme01.png 的像素:
## 三列寬 1 / 3 / 5,以外框色畫,與本體上緣外框相接
const TRIANGLE_CENTER_X := 23
## 文字墨跡 y 82~92 → baseline 91(畫面)− 72;x 15 讓墨跡從 x 16 開始(與示意圖一致)
const TEXT_BASELINE := Vector2(7, 19)

var text := ""


func _init() -> void:
	# 擋住下面 D02 的點擊(長按期間 D02 不可點,Q28)
	mouse_filter = Control.MOUSE_FILTER_STOP


func set_text(value: String) -> void:
	if value != text:
		text = value
		queue_redraw()


func _draw() -> void:
	# 先畫外框色整塊,再內縮 1px 畫本體色,確保外框剛好 1px 實心像素
	draw_rect(BODY, BORDER_COLOR)
	draw_rect(BODY.grow(-1), BODY_COLOR)
	for row in 3:
		var half := row
		draw_rect(Rect2(TRIANGLE_CENTER_X - half, 1 + row, half * 2 + 1, 1), BORDER_COLOR)
	PixelText.draw(self, TEXT_BASELINE, text, 12, Color.WHITE)
