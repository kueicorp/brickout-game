extends Node
## 廣告管理器(Autoload「AdManager」):持有全遊戲共用的單一 D10 banner(320×50)。
## 首頁、活動、商城、成長、設定進入時呼叫 show_banner()、離開時 hide_banner();關卡內不顯示。
## 已移除廣告(FakeData.ads_removed)時兩者都不做事,也不會建立 / 載入 banner,D10 區塊留白。
## 桌面與測試沒有 Android 原生外掛:整個管理器什麼都不做、不報錯。
##
## 注意:AdMob 外掛的類別(AdView、MobileAds…)只在 Android 上用 load() 動態載入。
## 直接寫類別名稱會在編譯本檔時就載入它們,而外掛在桌面編輯器執行檔下會自動建立模擬廣告節點,干擾測試。

## Google 官方 Android 測試 ID。上架前換成正式 ID(App ID 也要同步改 project.godot 的 admob/general/android/app_id)。
## App ID 實際寫進 AndroidManifest 的是 project.godot 那個設定(匯出時讀取),這裡的常數供對照,test_ad_manager 會檢查兩者一致。
const ANDROID_APP_ID := "ca-app-pub-3940256099942544~3347511713"
const ANDROID_BANNER_UNIT_ID := "ca-app-pub-3940256099942544/6300978111"

const BANNER_SIZE := Vector2i(320, 50)
const NATIVE_PLUGIN := "PoingGodotAdMobAdView"
const API := "res://addons/admob/gdscript/src/api/"

var _available := false
var _sdk_ready := false
var _want_shown := false
## 原生 AdView(GDScript 包裝);第一次 show_banner() 且 SDK 初始化完成後才建立
var _ad_view = null
## 每 dp 的實體像素,建立 banner 後由 SDK 算出的寬度反推
var _density := 0.0
var _position_script: Script


func _ready() -> void:
	_available = OS.get_name() == "Android" and Engine.has_singleton(NATIVE_PLUGIN)
	if not _available:
		return
	_position_script = load(API + "core/AdPosition.gd")
	var listener = load(API + "listeners/OnInitializationCompleteListener.gd").new()
	listener.on_initialization_complete = func(_status) -> void:
		_sdk_ready = true
		_apply()
	load(API + "MobileAds.gd").initialize(listener)
	get_viewport().size_changed.connect(_reposition)


## 顯示 D10 banner(第一次會建立並載入)
func show_banner() -> void:
	if not _available or FakeData.ads_removed:
		return
	_want_shown = true
	_apply()


## 隱藏 D10 banner(保留原生物件,下次顯示不必重新載入)
func hide_banner() -> void:
	if not _available or FakeData.ads_removed:
		return
	_want_shown = false
	_apply()


## 讓原生 banner 符合 _want_shown。SDK 還沒初始化完成就先記著,完成時會再呼叫一次。
func _apply() -> void:
	if not _sdk_ready:
		return
	if _ad_view == null:
		if _want_shown:
			_create_banner()
		return
	if _want_shown:
		_reposition()
		_ad_view.show()
	else:
		_ad_view.hide()


func _create_banner() -> void:
	var size = load(API + "core/AdSize.gd").BANNER
	# 先放 (0, 0),拿到 SDK 算的像素寬度(= 320 dp × density)後再移到 D10
	_ad_view = load(API + "AdView.gd").new(ANDROID_BANNER_UNIT_ID, size, _position_script.custom(0, 0))
	_density = _ad_view.get_width_in_pixels() / float(BANNER_SIZE.x)
	_ad_view.ad_listener.on_ad_failed_to_load = func(error) -> void:
		# shortcut: 載入失敗只記 log、不重試(D10 維持留白);之後若填充率太低再加重試間隔
		print("[ads] banner 載入失敗:", error.message)
	_reposition()
	_ad_view.load_ad(load(API + "core/AdRequest.gd").new())


## 依目前畫面把 banner 移到 D10(上緣 = h − B − 50,水平置中)
func _reposition() -> void:
	if _ad_view == null or _density <= 0.0:
		return
	var view := get_viewport().get_visible_rect().size
	var safe := HomeLogic.device_safe_margins(view)
	var top: int = HomeLogic.home_layout(int(view.y), safe.x, safe.y).banner
	var dp := banner_dp_position(view, DisplayServer.window_get_size(), _density, top)
	_ad_view.set_position(_position_script.custom(dp.x, dp.y))


## D10 banner 的原生自訂座標(dp,相對於視窗左上角;外掛會乘上 density 換成像素當 margin)。
## view = viewport 大小、window_px = 視窗實體像素、density = 每 dp 的像素、banner_top = D10 上緣(viewport y)。
## y 無條件進位:寧可往下偏不到 1 dp,也不要往上蓋到底部按鈕(按鈕與 D10 之間只有 10px);減 0.01 是吸收浮點誤差。
static func banner_dp_position(view: Vector2, window_px: Vector2i, density: float, banner_top: int) -> Vector2i:
	var px_per_unit := window_px.y / view.y
	var x := roundi((window_px.x / density - BANNER_SIZE.x) / 2.0)
	var y := ceili(banner_top * px_per_unit / density - 0.01)
	return Vector2i(x, y)
