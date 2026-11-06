class_name ThemeBarButton
extends PixelButton
## D02 的一塊:左 / 右箭頭(48×48)或中間主題名稱(240×48)。
## 底框黑 alpha 160 + 1px #F4C430、直角;按下疊白 alpha 40,圖 / 字下移 1px;
## 停用時整塊色乘 #808080、alpha 0.6(Q30)。

const ARROW_SIZE := Vector2(24, 24)
## 36px 主題名稱的 baseline(相對本塊頂端):墨跡 y 88~120 → baseline 115(畫面)− 80
const TITLE_BASELINE := 35.0
const TITLE_SIZE := 36
const DIM := Color(0.5, 0.5, 0.5, 0.6)

static var _frame_style: StyleBoxFlat

var arrow: Texture2D
var flip_arrow := false
var title := ""
var title_color := Color.WHITE


func _ready() -> void:
	if _frame_style == null:
		_frame_style = StyleBoxFlat.new()
		_frame_style.bg_color = Color(0, 0, 0, 160.0 / 255.0)
		_frame_style.border_color = Color("#F4C430")
		_frame_style.set_border_width_all(1)
		_frame_style.anti_aliasing = false


func set_dimmed(value: bool) -> void:
	disabled = value
	modulate = DIM if value else Color.WHITE


func set_title(text: String, color: Color) -> void:
	title = text
	title_color = color
	queue_redraw()


func _draw() -> void:
	draw_style_box(_frame_style, Rect2(Vector2.ZERO, size))
	var offset_y := 0.0
	if is_held():
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 40.0 / 255.0))
		offset_y = 1.0
	if arrow:
		var pos := ((size - ARROW_SIZE) / 2.0).floor() + Vector2(0, offset_y)
		# 負寬度 = 水平鏡像(左箭頭共用右箭頭圖,Q29)。Godot 只翻轉貼圖、取絕對值寬度,
		# 起點不變,所以 position 不能再加寬度,否則會右移 24px
		var rect := Rect2(pos, Vector2(-ARROW_SIZE.x, ARROW_SIZE.y)) if flip_arrow else Rect2(pos, ARROW_SIZE)
		draw_texture_rect(arrow, rect, false)
	if title != "":
		PixelText.draw(self, Vector2(0, TITLE_BASELINE + offset_y), title, TITLE_SIZE, title_color,
			Color.BLACK, size.x, HORIZONTAL_ALIGNMENT_CENTER)
