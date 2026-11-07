class_name PageShortcutBar
extends Control
## 頁面捷徑列(docs/design/layout/page-shortcuts.md P01~P09):返回鈕 + 「活動 / 商城 / 成長 / 設定」4 個文字捷徑。
## 活動頁、商城共用;建立時傳入目前頁(PageShortcutBar.new(Page.SHOP)),日後成長、設定頁照樣套用。
## 本節點放在頁面內容原點(不吃觸控),以下座標是 360×640 基準的頁面座標;安全區不足時由 set_shift 整列下移。
## 只負責外觀與發出點擊;切頁、停用時機、紅點資料由頁面與首頁決定。

signal back_pressed
## 點了非目前頁的捷徑;目前頁的捷徑交給頁面自己處理(P03),也走這個訊號
signal page_pressed(page: Page)

## 順序同首頁底部功能列
enum Page { EVENT, SHOP, GROWTH, SETTINGS }

const LABELS: Array[String] = ["活動", "商城", "成長", "設定"]
const ARROW := preload("res://assets/ui/home/theme-arrow_right.png")
const Y := 80
const BACK_X := 8
const KEY_X := 60
const KEY_STEP := 74
const KEY_SIZE := Vector2(70, 44)

var current: Page
var back: ShortcutButton
## 依 Page 順序
var keys: Array[ShortcutButton] = []


func _init(page: Page) -> void:
	current = page
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(360, 640)
	back = _add_key(Rect2(BACK_X, Y, 44, 44))
	back.icon = ARROW
	back.accessibility_name = "返回"
	back.pressed.connect(func() -> void: back_pressed.emit())
	for i in LABELS.size():
		var k := _add_key(Rect2(KEY_X + KEY_STEP * i, Y, KEY_SIZE.x, KEY_SIZE.y))
		k.label = LABELS[i]
		k.selected = i == page
		k.accessibility_name = LABELS[i]
		k.accessibility_description = "目前頁面" if k.selected else ""
		k.pressed.connect(func() -> void: page_pressed.emit(i))
		keys.append(k)


## 安全區不足時(EventLogic.header_shift)返回鈕與捷徑一起下移
func set_shift(shift: int) -> void:
	for k: ShortcutButton in [back] + keys:
		k.position.y = Y + shift


## P04:購買 / 領取請求處理中、看廣告載入中,返回鈕與 4 個捷徑一起停用(透明度 50%、不可點)
func set_disabled(on: bool) -> void:
	if on == back.disabled:
		return
	for k: ShortcutButton in [back] + keys:
		k.disabled = on
		k.modulate.a = 0.5 if on else 1.0


## P06:只有「其他頁」的活動、商城捷徑會亮;目前頁、成長、設定一律不顯示
func set_badge(page: Page, on: bool) -> void:
	var k := keys[page]
	var lit := on and page != current and (page == Page.EVENT or page == Page.SHOP)
	if lit != k.badge:
		k.badge = lit
		k.accessibility_description = "有新項目" if lit else ""
		k.queue_redraw()


func _add_key(rect: Rect2) -> ShortcutButton:
	var k := ShortcutButton.new()
	k.position = rect.position
	k.size = rect.size
	add_child(k)
	return k


## 單一捷徑 / 返回鈕(P02、P07):黑底 alpha 160 圓角 6px,白字 14px 或箭頭 icon 置中。
## 按下整顆變暗 40%(黑底乘 0.6 仍是黑,看起來是文字、金框、紅點變暗)。
class ShortcutButton extends PixelButton:
	const BG := Color(0, 0, 0, 160.0 / 255.0)
	const GOLD := Color("#F4C430")
	const BADGE_POS := Vector2(56, 2)
	const ICON_SIZE := Vector2(24, 24)
	## 14px 中文墨跡 baseline −10.5 ~ +1.2,baseline 27 時墨跡置中於 44 高
	const BASELINE := 27.0

	var label := ""
	var icon: Texture2D
	## 目前頁:內側 2px 金框
	var selected := false
	var badge := false

	func _init() -> void:
		# P09:這列例外開放鍵盤 / 手把焦點(其他 PixelButton 維持 FOCUS_NONE)。
		# 觸控點擊取得的焦點是「隱藏焦點」,has_focus(true) 為 false,不會畫白框
		focus_mode = Control.FOCUS_ALL
		focus_entered.connect(queue_redraw)
		focus_exited.connect(queue_redraw)

	func _draw() -> void:
		var held := is_held()
		var rect := Rect2(Vector2.ZERO, size)
		PixelBox.draw_rounded(self, rect, PixelBox.darken(BG, held))
		if selected:
			PixelBox.draw_rounded_frame(self, rect, PixelBox.darken(GOLD, held), 2)
		if icon:
			# 負寬度 = 水平鏡像(返回箭頭);起點不變,同 ThemeBarButton
			var pos := ((size - ICON_SIZE) / 2.0).floor()
			draw_texture_rect(icon, Rect2(pos, Vector2(-ICON_SIZE.x, ICON_SIZE.y)), false, PixelBox.darken(Color.WHITE, held))
		if label != "":
			PixelText.draw(self, Vector2(0, BASELINE), label, 14, PixelBox.darken(Color.WHITE, held), Color.TRANSPARENT,
				size.x, HORIZONTAL_ALIGNMENT_CENTER)
		if badge:
			PixelBox.draw_badge(self, BADGE_POS, held)
		if has_focus(true):
			PixelBox.draw_rounded_frame(self, rect.grow(2), Color.WHITE, 2)
