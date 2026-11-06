extends Control
## 載入畫面(branding D09):背景載入首頁場景,金磚進度條依實際載入進度增加,
## 載完停留 HOLD_AT_FULL 秒後切到首頁。載入失敗時畫面停住並 push_error(本階段不做失敗畫面)。

const HOME_SCENE := "res://scenes/home.tscn"
const FILL_MAX_WIDTH := 216.0
const HOLD_AT_FULL := 0.3

@onready var _fill: TextureRect = $Fill


func _ready() -> void:
	_apply_layout()
	get_viewport().size_changed.connect(_apply_layout)
	_fill.size.x = 0
	var err := ResourceLoader.load_threaded_request(HOME_SCENE)
	if err != OK:
		push_error("載入首頁失敗:load_threaded_request 回傳 %s" % error_string(err))
		set_process(false)


func _process(_delta: float) -> void:
	var progress := []
	match ResourceLoader.load_threaded_get_status(HOME_SCENE, progress):
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			_set_progress(progress[0])
		ResourceLoader.THREAD_LOAD_LOADED:
			set_process(false)
			_set_progress(1.0)
			var scene: PackedScene = ResourceLoader.load_threaded_get(HOME_SCENE)
			await get_tree().create_timer(HOLD_AT_FULL).timeout
			get_tree().change_scene_to_packed(scene)
		_:
			set_process(false)
			push_error("載入首頁失敗:%s" % HOME_SCENE)


## 依畫面高排 Logo 與進度條(T04);內容維持 360 寬置中,底色鋪滿整個 viewport
func _apply_layout() -> void:
	var view := _view_size()
	var ys := HomeLogic.loading_layout(int(view.y))
	position = Vector2(floorf((view.x - 360) / 2), 0)
	size = Vector2(360, view.y)
	$Background.position = Vector2(-position.x, 0)
	$Background.size = view
	$Logo.position.y = ys[0]
	$Frame.position.y = ys[1]
	_fill.position.y = ys[2]


## headless(自動測試)沒有視窗,stretch expand 會算出 640×640 的怪尺寸,改用基準 360×640
func _view_size() -> Vector2:
	return Vector2(360, 640) if DisplayServer.get_name() == "headless" else get_viewport_rect().size


## 寬度 = 216 × 進度;填充是 TILE 模式,最後一塊自然被裁切
func _set_progress(ratio: float) -> void:
	_fill.size.x = roundf(FILL_MAX_WIDTH * clampf(ratio, 0.0, 1.0))
