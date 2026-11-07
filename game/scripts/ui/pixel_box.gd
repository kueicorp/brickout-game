class_name PixelBox
## 像素階梯圓角矩形(Q77:圓角 6px、不抗鋸齒)。
## 不用 StyleBoxFlat:關掉反鋸齒後它把圓角畫成約 3px 深的 45° 斜角,不是階梯。

## 半徑 6px 的四分之一圓,由外往內每列的內縮像素(像素中心落在圓內才填);第 5 列起不內縮
const CORNER_INSETS: Array[int] = [4, 2, 1, 1]


## 以整數像素逐列畫填滿的圓角矩形;各列互不重疊,半透明色不會疊深。rect 需為整數座標。
static func draw_rounded(ci: CanvasItem, rect: Rect2, color: Color) -> void:
	var rows := CORNER_INSETS.size()
	for i in rows:
		var inset := CORNER_INSETS[i]
		var w := rect.size.x - inset * 2
		ci.draw_rect(Rect2(rect.position.x + inset, rect.position.y + i, w, 1), color)
		ci.draw_rect(Rect2(rect.position.x + inset, rect.end.y - 1 - i, w, 1), color)
	ci.draw_rect(Rect2(rect.position.x, rect.position.y + rows, rect.size.x, rect.size.y - rows * 2), color)


## 沿圓角形狀的外框(page-shortcuts P02 目前頁金框、焦點外框):rect 的圓角矩形扣掉 rect.grow(-width) 的圓角矩形,
## 逐列畫左右兩段;外框才會貼著圓角,不會在四角露出直角。rect 需為整數座標。
static func draw_rounded_frame(ci: CanvasItem, rect: Rect2, color: Color, width: int) -> void:
	var h := int(rect.size.y)
	var inner_h := h - width * 2
	for r in h:
		var o := _row_inset(r, h)
		var y := rect.position.y + r
		var ir := r - width
		if ir < 0 or ir >= inner_h:
			ci.draw_rect(Rect2(rect.position.x + o, y, rect.size.x - o * 2, 1), color)
			continue
		var i := _row_inset(ir, inner_h) + width
		ci.draw_rect(Rect2(rect.position.x + o, y, i - o, 1), color)
		ci.draw_rect(Rect2(rect.end.x - i, y, i - o, 1), color)


## 圓角矩形第 r 列(共 h 列)的左右內縮
static func _row_inset(r: int, h: int) -> int:
	var edge := mini(r, h - 1 - r)
	return CORNER_INSETS[edge] if edge < CORNER_INSETS.size() else 0


# ---- 活動頁共用的小工具(event-screen D05、D16 紅點;按下 / 已領取「變暗 40%」) ----

const BADGE_FILL := Color("#E74C3C")
const BADGE_SIZE := 12
## 12×12 圓點每列的左右內縮(白框外緣);紅色填色是外緣再內縮 1px 的範圍,-1 = 該列沒有紅色
const BADGE_OUTER: Array[int] = [4, 2, 1, 1, 0, 0, 0, 0, 1, 1, 2, 4]
const BADGE_INNER: Array[int] = [-1, 5, 3, 2, 2, 1, 1, 2, 2, 3, 5, -1]
## 「變暗 40%」= RGB 乘 0.6(同首頁底部按鈕按下)
const DARKEN := 0.6


## RGB 變暗 40%(alpha 不變);on = false 時原色
static func darken(color: Color, on: bool) -> Color:
	if not on:
		return color
	return Color(color.r * DARKEN, color.g * DARKEN, color.b * DARKEN, color.a)


## 紅點:12×12、1px 白框、像素階梯;pos = 左上角。dim = 跟著按鈕一起變暗
static func draw_badge(ci: CanvasItem, pos: Vector2, dim := false) -> void:
	for row in BADGE_SIZE:
		var o := BADGE_OUTER[row]
		ci.draw_rect(Rect2(pos.x + o, pos.y + row, BADGE_SIZE - o * 2, 1), darken(Color.WHITE, dim))
		var i := BADGE_INNER[row]
		if i >= 0:
			ci.draw_rect(Rect2(pos.x + i, pos.y + row, BADGE_SIZE - i * 2, 1), darken(BADGE_FILL, dim))


## 實心矩形外框(畫在 rect 內側);width = 框寬 px
static func draw_frame(ci: CanvasItem, rect: Rect2, color: Color, width := 1) -> void:
	ci.draw_rect(Rect2(rect.position, Vector2(rect.size.x, width)), color)
	ci.draw_rect(Rect2(rect.position.x, rect.end.y - width, rect.size.x, width), color)
	ci.draw_rect(Rect2(rect.position.x, rect.position.y + width, width, rect.size.y - width * 2), color)
	ci.draw_rect(Rect2(rect.end.x - width, rect.position.y + width, width, rect.size.y - width * 2), color)
