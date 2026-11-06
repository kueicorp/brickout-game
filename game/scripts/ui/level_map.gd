class_name LevelMap
extends Control
## D15 關卡地圖:半透明黑底(固定不動)+ 三頁(上一組 / 目前組 / 下一組)組成的滑動層,
## 裁切在 344×232、圓角 6px 的範圍內。處理點格選取、左右滑動換組(含跨主題)與邊界橡皮筋。
## 換組結果在換頁動畫結束瞬間以 group_changed / selection_changed 通知首頁。

signal selection_changed(level: int)
signal group_changed(group: int)

const PAGE_WIDTH := 344.0
const PAGE_ANIM := 0.2
const BOUNCE_ANIM := 0.15
const HOP_TIME := 0.15
const HOP_HEIGHT := 8.0
const BOB_INTERVAL := 0.5
## 放開前這麼久沒有移動,就當作手指已停住(速度 0),避免停住後放開還被判成快甩
const VELOCITY_STALE_MS := 100

var group := 1
var first_uncleared := 1
var selected_level := 1

var _strip: Control
var _pages: Array[MapPage] = []
var _layers: Array[Control] = []
var _anim_tween: Tween
var _hop_tween: Tween

# 手勢狀態(只追蹤第一根手指)
var _tracking := false
var _ignored := false
var _start := Vector2.ZERO
var _gesture := HomeLogic.Gesture.UNDECIDED
var _swipe_allowed := false
var _drag_dx := 0.0
var _last_velocity := 0.0
var _last_motion_ms := 0


func _ready() -> void:
	position = MapPage.ORIGIN
	size = MapPage.PAGE_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP

	# 黑底與裁切遮罩用同一個像素階梯圓角(Q77);遮罩本身不畫,只用來裁切路、格子、棋子
	_layers.append(_rounded_layer(Color(0, 0, 0, 120.0 / 255.0)))
	var clip := _rounded_layer(Color.WHITE)
	_layers.append(clip)
	clip.clip_children = CanvasItem.CLIP_CHILDREN_ONLY

	_strip = Control.new()
	_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.add_child(_strip)
	for i in 3:
		var page := MapPage.new()
		page.position.x = (i - 1) * PAGE_WIDTH
		_strip.add_child(page)
		_pages.append(page)

	var bob := Timer.new()
	bob.wait_time = BOB_INTERVAL
	bob.autostart = true
	bob.timeout.connect(_on_bob)
	add_child(bob)


## 直接顯示某組並選取某關(開啟首頁、D02 切主題時用;棋子直接出現,不跳)
func show_group(new_group: int, level: int) -> void:
	if _anim_tween:
		_anim_tween.kill()
	_cancel_gesture_state()
	group = new_group
	selected_level = level
	_strip.position.x = 0
	_refresh_pages()


## 扣高(D15 第 11 點):縮短排間距,外框高度跟著變矮(上下內距不變)
func set_row_cuts(cuts: Array) -> void:
	size.y = MapPage.PAGE_SIZE.y - cuts[0] - cuts[1]
	for layer in _layers:
		layer.size = size
		layer.queue_redraw()
	for page in _pages:
		page.row_cuts = cuts.duplicate()
		page.queue_redraw()


func is_animating() -> bool:
	return _anim_tween != null and _anim_tween.is_running()


func _refresh_pages() -> void:
	if _hop_tween:
		_hop_tween.kill()
	for i in 3:
		var page := _pages[i]
		var g := HomeLogic.neighbor_group(group, i - 1)
		page.visible = g != 0
		page.group = maxi(g, 1)
		page.first_uncleared = first_uncleared
		page.selected_level = selected_level if i == 1 else 0
		page.pressed_index = 0
		page.hop_pos = null
		page.queue_redraw()


func _on_bob() -> void:
	for page in _pages:
		page.bob_up = not page.bob_up
		page.queue_redraw()


# ---- 點格選取與棋子短跳(Q68) ----

func _set_pressed(index: int) -> void:
	if _pages[1].pressed_index != index:
		_pages[1].pressed_index = index
		_pages[1].queue_redraw()


func _select_index(index: int) -> void:
	var level := HomeLogic.level_of(group, index)
	if level == selected_level:
		return
	var page := _pages[1]
	var old_index := selected_level - HomeLogic.level_of(group, 0)
	# 跳到一半再點別格:從當時位置改跳新格
	var from: Vector2 = page.hop_pos if page.hop_pos != null \
		else page.pawn_anchor(old_index) + page.tile_shift(old_index)
	selected_level = level
	page.selected_level = level
	selection_changed.emit(level)

	if _hop_tween:
		_hop_tween.kill()
	_hop_tween = create_tween()
	_hop_tween.tween_method(_hop_step.bind(from, index), 0.0, 1.0, HOP_TIME)
	_hop_tween.finished.connect(func() -> void:
		page.hop_pos = null
		page.queue_redraw())


func _hop_step(t: float, from: Vector2, to_index: int) -> void:
	var page := _pages[1]
	var e := 1.0 - (1.0 - t) * (1.0 - t)  # ease-out
	var target := page.pawn_anchor(to_index) + page.tile_shift(to_index)
	var arc := HOP_HEIGHT * 4.0 * e * (1.0 - e)
	page.hop_pos = (from.lerp(target, e) - Vector2(0, arc)).round()
	page.queue_redraw()


# ---- 滑動換組(D15 第 4 點) ----

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_on_down(event.position)
		else:
			_on_up(event.position, event.canceled)
		accept_event()
	elif event is InputEventMouseMotion and _tracking:
		_on_move(event.position, event.velocity.x)
		accept_event()


func _input(event: InputEvent) -> void:
	# 觸控時第一根手指會被模擬成滑鼠;第二根手指落下 → 取消目前手勢,地圖回原位
	if event is InputEventScreenTouch and event.pressed and event.index > 0 and _tracking and not _ignored:
		_cancel_gesture()


func _notification(what: int) -> void:
	# 系統中斷(來電、切 App)→ 一律回彈
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and _tracking and not _ignored:
		_cancel_gesture()


func _on_down(pos: Vector2) -> void:
	_tracking = true
	# 換頁 / 回彈動畫期間不接受新手勢
	_ignored = is_animating()
	_start = pos
	_gesture = HomeLogic.Gesture.UNDECIDED
	_drag_dx = 0.0
	_last_velocity = 0.0
	_swipe_allowed = HomeLogic.can_start_swipe(pos + MapPage.ORIGIN)
	if not _ignored:
		_set_pressed(_pages[1].index_at(pos))


func _on_move(pos: Vector2, velocity_x: float) -> void:
	_last_velocity = velocity_x
	_last_motion_ms = Time.get_ticks_msec()
	if _ignored:
		return
	var delta := pos - _start
	if _gesture == HomeLogic.Gesture.UNDECIDED:
		_gesture = HomeLogic.classify_motion(delta)
		if _gesture == HomeLogic.Gesture.UNDECIDED:
			return
		_set_pressed(0)
		# 垂直手勢、或起手點在邊緣 32px 內的水平滑動:整個手勢作廢(不翻頁、不選取)
		if _gesture == HomeLogic.Gesture.VERTICAL or not _swipe_allowed:
			_ignored = true
			return
	_drag_dx = delta.x
	_strip.position.x = roundf(_drag_offset(delta.x))


## 手指往左(dx < 0)要有下一組、往右要有上一組,否則是邊界橡皮筋
func _drag_offset(dx: float) -> float:
	var direction := 1 if dx < 0 else -1
	if HomeLogic.neighbor_group(group, direction) == 0:
		return HomeLogic.rubber_band(dx)
	return clampf(dx, -PAGE_WIDTH, PAGE_WIDTH)


## canceled:系統取消了這次觸控(來電、系統手勢攔截)→ 一律回彈,不換頁、不選取
func _on_up(pos: Vector2, canceled := false) -> void:
	if not _tracking:
		return
	_tracking = false
	if _ignored:
		return
	if canceled:
		_cancel_gesture()
		return
	if _gesture == HomeLogic.Gesture.SWIPE:
		var fresh := Time.get_ticks_msec() - _last_motion_ms <= VELOCITY_STALE_MS
		var direction := HomeLogic.page_change_direction(_drag_dx, _last_velocity if fresh else 0.0)
		if direction != 0 and HomeLogic.neighbor_group(group, direction) != 0:
			_animate_to_page(direction)
		else:
			_bounce()
		return
	var index := _pages[1].pressed_index
	_set_pressed(0)
	if index != 0 and HomeLogic.is_tap(pos - _start) and _pages[1].index_at(pos) == index:
		_select_index(index)


func _cancel_gesture() -> void:
	var was_swiping := _gesture == HomeLogic.Gesture.SWIPE
	_ignored = true
	_set_pressed(0)
	if was_swiping:
		_bounce()


func _cancel_gesture_state() -> void:
	_tracking = false
	_ignored = false
	_gesture = HomeLogic.Gesture.UNDECIDED


func _animate_to_page(direction: int) -> void:
	_anim_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_anim_tween.tween_property(_strip, "position:x", -direction * PAGE_WIDTH, PAGE_ANIM)
	_anim_tween.finished.connect(_finish_page.bind(direction))


func _finish_page(direction: int) -> void:
	var from_group := group
	group = HomeLogic.neighbor_group(group, direction)
	selected_level = HomeLogic.selection_after_swipe(from_group, group, first_uncleared)
	_strip.position.x = 0
	_refresh_pages()
	group_changed.emit(group)
	selection_changed.emit(selected_level)


func _bounce() -> void:
	_anim_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_anim_tween.tween_property(_strip, "position:x", 0.0, BOUNCE_ANIM)


## 加一層滿版、不吃滑鼠、畫像素階梯圓角矩形的子節點(黑底與裁切共用)
func _rounded_layer(color: Color) -> Control:
	var layer := Control.new()
	layer.size = size
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.draw.connect(func() -> void: PixelBox.draw_rounded(layer, Rect2(Vector2.ZERO, layer.size), color))
	add_child(layer)
	return layer
