## D29 金球/黑球 3 選 1 畫面。開啟期間遊戲暫停(由主程式負責),沒有倒數、沒有自動選擇。
## 動畫用本畫面自己的計時,不受遊戲暫停影響:入場 300 ms、前 500 ms 不接受觸控;
## 選中立即送出 picked(效果當下生效),420 ms 後送出 closed 並移除自己。
class_name ChoiceMenu
extends Control

signal picked(id: String)
signal closed

const FRAME := 0.06
const LOCK_TIME := 0.5
const CLOSE_TIME := 0.42
const CLOSE_TIME_REDUCED := 0.24
const PANEL_SIZE := Vector2(304, 432)
const FONT_SIZE := 22

## D29 第九節 9 宮格外框網格(12×12,邊距 4)。
# shortcut: 轉檔工具還不讀 ui-menus.md,沒有 menu_panel_*.png,先在執行時由網格產生;工具支援後改讀 PNG
const PANEL_GRID := {
	true: [
		"KKKKKKKKKKKK", "KAAAAAAAAAYK", "KABBBBBBBYDK", "KABYYYYYYCDK",
		"KABYKKKKYCDK", "KABYKKKKYCDK", "KABYKKKKYCDK", "KABYKKKKYCDK",
		"KABYYYYYYCDK", "KAYCCCCCCCDK", "KYDDDDDDDDDK", "KKKKKKKKKKKK",
	],
	false: [
		"KKKKKKKKKKKK", "K_________<K", "K________<,K", "K__<<<<<<>,K",
		"K__<KKKK<>,K", "K__<KKKK<>,K", "K__<KKKK<>,K", "K__<KKKK<>,K",
		"K__<<<<<<>,K", "K_<>>>>>>>,K", "K<,,,,,,,,,K", "KKKKKKKKKKKK",
	],
}

var golden := true
var ids: Array = []
var view_h := 800
var reduced_motion := false
var _t := 0.0
var _pick_t := 0.0
var _picked := -1
var _closing := false
var _mask_alpha := 0.0
var _panel: Control
var _options: Array[ChoiceOption] = []


func setup(is_golden: bool, choice_ids: Array, h: int, reduced: bool) -> void:
	golden = is_golden
	ids = choice_ids
	view_h = h
	reduced_motion = reduced


func _ready() -> void:
	size = Vector2(360, view_h)
	mouse_filter = Control.MOUSE_FILTER_STOP
	accessibility_name = "金球，請從三個增益道具中選一個" if golden else "黑球，請從三個減益道具中選一個"

	_panel = Control.new()
	_panel.position = Vector2(28, 52 + floori((view_h - 52 - PANEL_SIZE.y) / 2.0))
	_panel.size = PANEL_SIZE
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)

	var frame := NinePatchRect.new()
	frame.texture = _panel_texture()
	frame.patch_margin_left = 4
	frame.patch_margin_top = 4
	frame.patch_margin_right = 4
	frame.patch_margin_bottom = 4
	frame.size = PANEL_SIZE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(frame)

	var icon := TextureRect.new()
	icon.texture = load(ItemDefs.icon_path("golden_ball" if golden else "black_ball", false))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	# D29 修訂:D32 的 40×40 圖以 1 倍顯示,和標題加副標(y 12~57)垂直置中
	icon.position = Vector2(12, 15)
	icon.size = Vector2(40, 40)
	_panel.add_child(icon)

	_panel.add_child(_label("金球！選一個增益" if golden else "黑球！選一個減益", Vector2(60, 12), Pal.YEL_Y if golden else Pal.VIO_M))
	_panel.add_child(_label("三選一，點了就生效" if golden else "三選一，挑最能忍的", Vector2(60, 36), Pal.G))

	# 選項從右側滑入時被面板內緣裁切(D29 第五節)
	var clip := Control.new()
	clip.position = Vector2(4, 4)
	clip.size = PANEL_SIZE - Vector2(8, 8)
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(clip)
	for k in ids.size():
		var o := ChoiceOption.new()
		o.setup(golden, ids[k], reduced_motion)
		o.size = Vector2(280, 112)
		o.position = Vector2(8, 64 + 120 * k)
		o.disabled = true
		o.pressed.connect(_on_pressed.bind(k))
		clip.add_child(o)
		_options.append(o)
	_apply_entry(0.0)


func _process(delta: float) -> void:
	if _closing:
		return
	if _picked < 0:
		_t += delta
		_apply_entry(_t)
		if _t >= LOCK_TIME and _options[0].disabled:
			for o in _options:
				o.disabled = false
			_options[0].grab_focus()
	else:
		_pick_t += delta
		_apply_pick(_pick_t)
	queue_redraw()
	for o in _options:
		o.queue_redraw()


func _draw() -> void:
	# 遮罩蓋住關卡區與邊框,不蓋 UI 區(y 0~31)
	draw_rect(Rect2(0, 32, 360, view_h - 32), Color(Pal.K if golden else Pal.DEB_DARK, _mask_alpha))


func _input(event: InputEvent) -> void:
	# 焦點框只在鍵盤/外接裝置操作時出現
	var keyboard := -1
	if event is InputEventKey or event is InputEventJoypadButton:
		keyboard = 1
	elif event is InputEventMouseButton or event is InputEventScreenTouch:
		keyboard = 0
	if keyboard >= 0:
		for o in _options:
			o.show_focus = keyboard == 1


## 入場動畫(D29 第五節 E1~E5);減少動態時直接完整顯示,鎖定 500 ms 保留。
func _apply_entry(t: float) -> void:
	if reduced_motion:
		_mask_alpha = 0.6
		return
	_mask_alpha = 0.3 if t < FRAME else 0.6
	_panel.visible = t >= FRAME
	for k in _options.size():
		_options[k].visible = t >= FRAME * (k + 1)
		_options[k].position.x = 8 + (24 if t < FRAME * (k + 2) else 0)


func _on_pressed(k: int) -> void:
	if _picked >= 0:
		return
	_picked = k
	_pick_t = 0.0
	# 選定後立刻忽略所有輸入
	for o in _options:
		o.disabled = true
	_options[k].position.x = 8
	picked.emit(ids[k])


## 選擇回饋與退場(D29 第五節);減少動態時只加白框,停留 240 ms 後關閉。
func _apply_pick(pt: float) -> void:
	var sel := _options[_picked]
	if reduced_motion:
		sel.border_white = true
		if pt >= CLOSE_TIME_REDUCED:
			_close()
		return
	sel.flash = pt < FRAME
	sel.border_white = pt >= FRAME
	sel.pickup_frame = int(pt / FRAME) if pt < FRAME * 3 else -1
	for k in _options.size():
		if k != _picked:
			_options[k].modulate.a = 0.6 if pt < FRAME else 0.3
			_options[k].visible = pt < FRAME * 2
	_panel.modulate.a = 1.0 if pt < 0.3 else (0.66 if pt < 0.36 else 0.33)
	_mask_alpha = 0.6 if pt < 0.3 else (0.4 if pt < 0.36 else 0.2)
	if pt >= CLOSE_TIME:
		_close()


func _close() -> void:
	_closing = true
	closed.emit()
	queue_free()


func _label(text: String, pos: Vector2, color: Color) -> Label:
	# shortcut: Cubic 11 尚未下載,暫用 Godot 預設字型;下載後改用 Cubic 11 22 px
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = Vector2(232, 22)
	l.add_theme_font_size_override("font_size", FONT_SIZE)
	l.add_theme_color_override("font_color", color)
	return l


func _panel_texture() -> Texture2D:
	var grid: Array = PANEL_GRID[golden]
	var img := Image.create(12, 12, false, Image.FORMAT_RGBA8)
	for y in 12:
		for x in 12:
			img.set_pixel(x, y, Pal.GRID_CODES[grid[y][x]])
	return ImageTexture.create_from_image(img)
