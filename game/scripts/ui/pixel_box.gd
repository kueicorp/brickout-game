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
