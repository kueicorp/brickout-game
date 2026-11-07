class_name GreenButton
extends PixelButton
## 商城與活動頁共用的綠色按鈕(README 商城畫面第 14 點,2026-11-07):
## 用首頁開始按鈕的 start_normal / start_pressed / start_disabled 做九宮格,中間平面重複貼上(不縮放像素)。
## 按下改用 pressed 圖(高 = 按鈕高 − 6,往下 5px、往右 1px);停用(原本灰 #555D6B 的狀態)用 disabled 圖。
## 文字由程式疊上,置中在按鈕平面(按鈕高 − 11,扣掉下緣立體厚邊),按下時跟著圖案一起位移。
## 商城卡片內的價格鈕不是獨立節點(整張卡一起點),用靜態函式 draw_button 畫同一個外觀。

const TEX_NORMAL := preload("res://assets/ui/home/start-button/start_normal.png")
const TEX_PRESSED := preload("res://assets/ui/home/start-button/start_pressed.png")
const TEX_DISABLED := preload("res://assets/ui/home/start-button/start_disabled.png")
## 圖案範圍(圖檔座標);normal 與 disabled 相同
const SRC_NORMAL := Rect2(5, 9, 206, 61)
const SRC_PRESSED := Rect2(6, 14, 206, 55)
## 九宮格邊界:左、上、右、下
const MARGIN_TL := Vector2(22, 20)
const MARGIN_BR := Vector2(12, 11)
const PRESSED_OFFSET := Vector2(1, 5)
const PRESSED_SHRINK := 6
## 平面高 = 按鈕高 − 下緣厚邊
const PLANE_CUT := 11
## pressed 圖中間 x 65~90 有一塊淺色斑點、x 170~174 平面下緣(y 62)有一條深色短線 #0C482E,重複貼上會很明顯;
## 中間的重複來源改用兩段乾淨範圍接起來:x 92~169 + x 175~199(到右邊界前)。每段為 [起, 迄) 圖檔 x 座標
const PRESSED_CLEAN_SPANS: Array[Vector2i] = [Vector2i(92, 170), Vector2i(175, 200)]
## 多行文字的行距 = 字級 + 5(設計稿道具列「單買 / 30 金塊」12px 兩行,基線相差 17)
const LINE_GAP := 5

## 左邊界 + 乾淨中段 + 右邊界拼成的 pressed 圖(第一次用到時才建)
static var _pressed_clean: Texture2D

var text := ""
var text_color := Color.BLACK
var font_size := 14


## 一次換掉文字、可否點擊與文字顏色
func set_look(label: String, enabled: bool, label_color: Color) -> void:
	text = label
	disabled = not enabled
	text_color = label_color
	queue_redraw()


## 可點 = 綠圖黑字;不可點 = disabled 圖白字(沿用原本灰色狀態的文字顏色)
func set_active(label: String, active: bool) -> void:
	set_look(label, active, Color.BLACK if active else Color.WHITE)


func _draw() -> void:
	draw_button(self, Rect2(Vector2.ZERO, size), not disabled, is_held(), text, font_size, text_color)


## 在 ci 上畫一顆按鈕。label 用 "\n" 分行;tint 給整張卡一起變暗時用(圖與字都乘上)
static func draw_button(ci: CanvasItem, rect: Rect2, enabled: bool, held: bool, label: String, px: int,
		color: Color, tint := Color.WHITE) -> void:
	var pressed := enabled and held
	var plate := rect
	var tex: Texture2D = TEX_NORMAL if enabled else TEX_DISABLED
	var src := SRC_NORMAL
	if pressed:
		plate = Rect2(rect.position + PRESSED_OFFSET, rect.size - Vector2(0, PRESSED_SHRINK))
		tex = _clean_pressed()
		src = Rect2(Vector2.ZERO, tex.get_size())
	RenderingServer.canvas_item_add_nine_patch(ci.get_canvas_item(), plate, src, tex.get_rid(), MARGIN_TL, MARGIN_BR,
		RenderingServer.NINE_PATCH_TILE, RenderingServer.NINE_PATCH_TILE, true, tint)
	if label == "":
		return
	var lines := label.split("\n")
	var origin := rect.position + (PRESSED_OFFSET if pressed else Vector2.ZERO)
	var first := label_baseline(rect.size.y, px, lines.size())
	for i in lines.size():
		PixelText.draw(ci, origin + Vector2(0, first + i * (px + LINE_GAP)), lines[i], px, color * tint,
			Color.TRANSPARENT, rect.size.x, HORIZONTAL_ALIGNMENT_CENTER)


## 第一行文字的 baseline(相對按鈕頂端,未按下):整段墨跡中心對齊平面中心。
## 中文墨跡 = baseline −0.75×字級 ~ +字級/12(PixelText),中心 ≈ baseline − 字級/3
static func label_baseline(height: float, px: int, line_count: int) -> float:
	var center := (height - PLANE_CUT) / 2.0
	return floorf(center + px / 3.0 - (line_count - 1) * (px + LINE_GAP) / 2.0 + 0.5)


static func _clean_pressed() -> Texture2D:
	if _pressed_clean == null:
		var src := TEX_PRESSED.get_image()
		if src.is_compressed():
			src.decompress()
		var left := int(MARGIN_TL.x)
		var right := int(MARGIN_BR.x)
		var mid := 0
		for s in PRESSED_CLEAN_SPANS:
			mid += s.y - s.x
		var y := int(SRC_PRESSED.position.y)
		var h := int(SRC_PRESSED.size.y)
		var img := Image.create(left + mid + right, h, false, src.get_format())
		img.blit_rect(src, Rect2i(int(SRC_PRESSED.position.x), y, left, h), Vector2i.ZERO)
		var x := left
		for s in PRESSED_CLEAN_SPANS:
			img.blit_rect(src, Rect2i(s.x, y, s.y - s.x, h), Vector2i(x, 0))
			x += s.y - s.x
		img.blit_rect(src, Rect2i(int(SRC_PRESSED.end.x) - right, y, right, h), Vector2i(x, 0))
		_pressed_clean = ImageTexture.create_from_image(img)
	return _pressed_clean
