extends Control
## 首頁:組裝各區塊並串接狀態(目前主題、選取的關卡)。
## 會跳到尚未存在的畫面(商城、主題選擇、道具選擇、底部 4 個畫面、補愛心提示)時只 print 一行 log。
## 寬固定 360、高依手機延伸(T01~T05),排版見 _apply_layout。
## 圖層(下到上):背景頂端(補頂條 / 純色)→ 背景 → D15 → D06 → D01 → D02 → 底部列 → D14。D10 banner 區留白。

const BACKGROUNDS := [
	preload("res://assets/backgrounds/home/bg_theme01.png"),
	preload("res://assets/backgrounds/home/bg_theme02.png"),
	preload("res://assets/backgrounds/home/bg_theme03.png"),
	preload("res://assets/backgrounds/home/bg_theme04.png"),
	preload("res://assets/backgrounds/home/bg_theme05.png"),
	preload("res://assets/backgrounds/home/bg_theme06.png"),
	preload("res://assets/backgrounds/home/bg_theme07.png"),
	preload("res://assets/backgrounds/home/bg_theme08.png"),
	preload("res://assets/backgrounds/home/bg_theme09.png"),
	preload("res://assets/backgrounds/home/bg_theme10.png"),
]
const ARROW := preload("res://assets/ui/home/theme-arrow_right.png")
const BOTTOM_ITEMS := [
	["活動", preload("res://assets/ui/home/bottom-button/icon_event.png")],
	["商城", preload("res://assets/ui/home/bottom-button/icon_shop.png")],
	["成長", preload("res://assets/ui/home/bottom-button/icon_growth.png")],
	["設定", preload("res://assets/ui/home/bottom-button/icon_settings.png")],
]
const LOCKED_TITLE_COLOR := Color("#B0B0B0")
## D14「震動一下」的長度;設計稿沒寫,自訂 50 ms
const VIBRATE_MS := 50

var first_uncleared := FakeData.FIRST_UNCLEARED_LEVEL
var hearts := FakeData.HEARTS
var heart_seconds := FakeData.HEART_NEXT_SECONDS
var current_theme := 1
var selected_level := 1

var _bg: TextureRect
## 背景原圖上方(補頂條 + 純色),畫面高 640 時高度 0
var _bg_top: Control
var _top_strips := {}
var _row_colors := {}
var _resources: ResourceBar
var _d01_buttons: Array[Control] = []
var _bottom_buttons: Array[Control] = []
var _map: LevelMap
var _start: StartButton
var _left: ThemeBarButton
var _title: ThemeBarButton
var _right: ThemeBarButton
var _heart: PixelButton
var _tooltip: HeartTooltip
var _long_press: Timer
var _tooltip_shown_this_press := false


func _ready() -> void:
	_bg_top = Control.new()
	_bg_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_top.draw.connect(_draw_bg_top)
	add_child(_bg_top)

	_bg = TextureRect.new()
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	_map = LevelMap.new()
	_map.first_uncleared = first_uncleared
	_map.selection_changed.connect(_apply_selection)
	_map.group_changed.connect(func(g: int) -> void: _apply_theme(HomeLogic.theme_of_group(g)))
	add_child(_map)

	_start = _add_button(StartButton.new(), Rect2(72, 388, 216, 80))
	_start.pressed.connect(_on_start_pressed)

	_resources = ResourceBar.new()
	_resources.set_values(hearts, FakeData.COINS, FakeData.GOLD, FakeData.SILVER)
	add_child(_resources)
	# D01 觸控:愛心、金幣、金塊 icon 的 44×44(貼格左緣、佔滿格高);外觀由 ResourceBar 畫
	_heart = _add_button(PixelButton.new(), Rect2(8, 28, 44, 44))
	_heart.button_down.connect(_on_heart_down)
	_heart.button_up.connect(_hide_tooltip)
	_heart.pressed.connect(_on_heart_pressed)
	_d01_buttons.append(_heart)
	_d01_buttons.append(_add_button(PixelButton.new(), Rect2(76, 28, 44, 44)))
	_d01_buttons[1].pressed.connect(_log.bind("前往商城(金幣)"))
	_d01_buttons.append(_add_button(PixelButton.new(), Rect2(172, 28, 44, 44)))
	_d01_buttons[2].pressed.connect(_log.bind("前往商城(金塊)"))

	_left = _add_button(ThemeBarButton.new(), Rect2(8, 80, 48, 48))
	_left.arrow = ARROW
	_left.flip_arrow = true
	_left.pressed.connect(_on_arrow.bind(-1))
	_title = _add_button(ThemeBarButton.new(), Rect2(60, 80, 240, 48))
	_title.pressed.connect(_log.bind("前往主題選擇畫面"))
	_right = _add_button(ThemeBarButton.new(), Rect2(304, 80, 48, 48))
	_right.arrow = ARROW
	_right.pressed.connect(_on_arrow.bind(1))

	for i in BOTTOM_ITEMS.size():
		var item: Array = BOTTOM_ITEMS[i]
		var button: BottomButton = _add_button(BottomButton.new(), Rect2(8 + i * 87, 492, 83, 72))
		button.label = item[0]
		button.icon = item[1]
		button.pressed.connect(_log.bind("前往%s畫面" % item[0]))
		_bottom_buttons.append(button)

	_tooltip = HeartTooltip.new()
	_tooltip.position = Vector2(8, 72)
	_tooltip.size = Vector2(88, 28)
	_tooltip.visible = false
	add_child(_tooltip)

	_long_press = Timer.new()
	_long_press.one_shot = true
	_long_press.wait_time = HomeLogic.LONG_PRESS_MS / 1000.0
	_long_press.timeout.connect(_on_long_press)
	add_child(_long_press)

	var countdown := Timer.new()
	countdown.wait_time = 1.0
	countdown.autostart = true
	countdown.timeout.connect(_on_countdown_tick)
	add_child(countdown)
	_update_tooltip_text()

	# 開啟首頁:第一個未通關所在的組並選該關(Q43)
	selected_level = HomeLogic.default_selection(first_uncleared)
	var group := HomeLogic.group_of_level(selected_level)
	_map.show_group(group, selected_level)
	_apply_theme(HomeLogic.theme_of_group(group))
	_apply_selection(selected_level)

	_apply_layout()
	get_viewport().size_changed.connect(_apply_layout)


## 依畫面大小與安全區排版(T01~T03、T05)。上面建立節點時用的是 640 高的座標,這裡只改 y。
## 畫面比 9:16 寬時版面維持 360 寬置中,左右露出的是預設清除色 #192331(project.godot)。
func _apply_layout() -> void:
	var view := _view_size()
	var h := int(view.y)
	var safe := _safe_margins(view)
	var lay := HomeLogic.home_layout(h, safe.x, safe.y)
	position = Vector2(floorf((view.x - 360) / 2), 0)
	size = Vector2(360, h)

	# 背景貼下對齊:原圖在最下面 640 列,上面是補頂條 / 純色
	_bg.position = Vector2(0, h - 640)
	_bg_top.size = Vector2(360, h - 640)
	_bg_top.queue_redraw()

	_resources.position.y = lay.d01 - 28
	for b in _d01_buttons:
		b.position.y = lay.d01
	_tooltip.position.y = lay.d14 - 4
	for b in [_left, _title, _right]:
		b.position.y = lay.d02
	_map.position = Vector2(8, lay.d15)
	_map.set_row_cuts(lay.row_cuts)
	_start.position.y = lay.d06
	for b in _bottom_buttons:
		b.position.y = lay.bottom


## headless(自動測試)沒有視窗,stretch expand 會算出 640×640 的怪尺寸,改用基準 360×640
func _view_size() -> Vector2:
	return Vector2(360, 640) if DisplayServer.get_name() == "headless" else get_viewport_rect().size


## 安全區 T、B(viewport px)。只在手機上讀系統 safe area;
## 桌機的 safe area 是「螢幕扣掉工作列」,跟視窗無關,所以一律用保底值。
func _safe_margins(view: Vector2) -> Vector2i:
	if not OS.has_feature("mobile"):
		return HomeLogic.safe_margins(0, 0, 1)
	var win_pos := DisplayServer.window_get_position()
	var win_size := DisplayServer.window_get_size()
	var safe := DisplayServer.get_display_safe_area()
	var top_px := maxi(0, safe.position.y - win_pos.y)
	var bottom_px := maxi(0, win_pos.y + win_size.y - safe.end.y)
	return HomeLogic.safe_margins(top_px, bottom_px, win_size.y / view.y)


## 背景頂端:有補頂條就貼在原圖正上方,再往上(或沒有補頂條時)用最上面那張圖第 0 列的平均色補滿
func _draw_bg_top() -> void:
	var h := _bg_top.size.y
	if h <= 0:
		return
	var top: Texture2D = _top_strip(current_theme)
	var fill_h := h - (top.get_height() if top else 0)
	if fill_h > 0:
		var source: Texture2D = top if top else BACKGROUNDS[current_theme - 1]
		_bg_top.draw_rect(Rect2(0, 0, 360, fill_h), _first_row_color(source))
	if top:
		_bg_top.draw_texture(top, Vector2(0, fill_h))


## 主題 n 的補頂條(art 出圖後才會有);沒有時回傳 null
func _top_strip(n: int) -> Texture2D:
	if not _top_strips.has(n):
		var path := "res://assets/backgrounds/home/top/bg_theme%02d_top.png" % n
		_top_strips[n] = load(path) if ResourceLoader.exists(path) else null
	return _top_strips[n]


## 圖片第 0 列的平均色(每張圖只算一次)
func _first_row_color(tex: Texture2D) -> Color:
	if not _row_colors.has(tex):
		var img := tex.get_image()
		if img.is_compressed():
			img.decompress()
		var sum := Color(0, 0, 0, 0)
		for x in img.get_width():
			sum += img.get_pixel(x, 0)
		var avg := sum / float(img.get_width())
		avg.a = 1.0
		_row_colors[tex] = avg
	return _row_colors[tex]


func _add_button(button: Control, rect: Rect2):
	button.position = rect.position
	button.size = rect.size
	add_child(button)
	return button


## 換主題:名稱(未解鎖變灰)、背景、箭頭停用狀態當下換,不做動畫
func _apply_theme(new_theme: int) -> void:
	current_theme = new_theme
	_bg.texture = BACKGROUNDS[current_theme - 1]
	_bg_top.queue_redraw()
	var locked := HomeLogic.is_theme_locked(current_theme, first_uncleared)
	_title.set_title(HomeLogic.THEME_NAMES[current_theme - 1], LOCKED_TITLE_COLOR if locked else Color.WHITE)
	_left.set_dimmed(HomeLogic.is_left_arrow_disabled(current_theme))
	_right.set_dimmed(HomeLogic.is_right_arrow_disabled(current_theme))


func _apply_selection(level: int) -> void:
	selected_level = level
	if HomeLogic.level_state(level, first_uncleared) == HomeLogic.LevelState.LOCKED:
		_start.set_look(StartButton.Look.DISABLED)
	elif HomeLogic.is_boss(level):
		_start.set_look(StartButton.Look.BOSS)
	else:
		_start.set_look(StartButton.Look.NORMAL)


## D02 箭頭:切主題後一律第 1 組、選第 1 關(Q57);地圖換頁動畫期間不接受
func _on_arrow(direction: int) -> void:
	if _map.is_animating():
		return
	var new_theme := clampi(current_theme + direction, 1, HomeLogic.THEME_COUNT)
	var level := HomeLogic.selection_for_theme(new_theme)
	_map.show_group(HomeLogic.first_group_of_theme(new_theme), level)
	_apply_theme(new_theme)
	_apply_selection(level)


func _on_start_pressed() -> void:
	if hearts <= 0:
		_log("愛心不足,提示補愛心")
	else:
		_log("前往道具選擇:第 %d 關" % selected_level)


# ---- D01 愛心:短按去商城、長按 500 ms 顯示 D14 ----

func _on_heart_down() -> void:
	_tooltip_shown_this_press = false
	_long_press.start()


func _on_long_press() -> void:
	# 手指已移出觸控範圍就不顯示
	if not _heart.is_held():
		return
	_tooltip_shown_this_press = true
	_update_tooltip_text()
	_tooltip.visible = true
	Input.vibrate_handheld(VIBRATE_MS)


func _on_heart_pressed() -> void:
	if HomeLogic.heart_release_goes_to_shop(_tooltip_shown_this_press, true):
		_log("前往商城(愛心)")


func _hide_tooltip() -> void:
	_long_press.stop()
	_tooltip.visible = false


func _on_countdown_tick() -> void:
	# shortcut: 假倒數,歸零後回到 20:00 重來、不會真的加愛心;接上存檔 / 伺服器時間後改成依回復時間計算
	heart_seconds -= 1
	if heart_seconds < 0:
		heart_seconds = HomeLogic.HEART_REGEN_SECONDS
	_update_tooltip_text()


func _update_tooltip_text() -> void:
	_tooltip.set_text(HomeLogic.heart_countdown_text(heart_seconds, hearts))


func _notification(what: int) -> void:
	# 系統中斷(來電、切 App)時關閉 D14
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and _tooltip:
		_hide_tooltip()


func _log(message: String) -> void:
	print("[home] ", message)
