extends SceneTree
## AdManager(D10 banner)測試:桌面安全不做事、測試 ID 一致、原生座標換算落在 D10 內。執行:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path game --script res://tests/test_ad_manager.gd
## 有任何失敗時結束碼為 1。

const M := preload("res://scripts/ad_manager.gd")
const AdMobSettings := preload("res://addons/admob/internal/services/project_settings_service.gd")

var _passed := 0
var _failed := 0


func _initialize() -> void:
	_test_ids()
	_test_banner_position()
	# Autoload 在主腳本初始化之後才加進 root,桌面行為放到下一個 frame 測
	_test_desktop.call_deferred()


func _eq(actual, expected, label: String) -> void:
	if actual == expected:
		_passed += 1
	else:
		_failed += 1
		printerr("FAIL %s: expected %s, got %s" % [label, str(expected), str(actual)])


func _test_ids() -> void:
	# 匯出時寫進 AndroidManifest 的是 project 設定(沒設時用外掛預設值),必須與常數一致
	var app_id = ProjectSettings.get_setting("admob/general/android/app_id", AdMobSettings.ANDROID_DEFAULT_APP_ID)
	_eq(app_id, M.ANDROID_APP_ID, "app id matches project setting")
	_eq(M.ANDROID_APP_ID, "ca-app-pub-3940256099942544~3347511713", "google test app id")
	_eq(M.ANDROID_BANNER_UNIT_ID, "ca-app-pub-3940256099942544/6300978111", "google test banner id")


## 360 寬、高 640 / 780;寬 360 dp(density 3)與 411 dp(density 2.625)兩種手機,B = 16 與 48。
## 用外掛的換算(margin px = dp × density,取整數)把 banner 換回 viewport 座標檢查。
func _test_banner_position() -> void:
	for h in [640, 780]:
		for b in [16, 48]:
			for density in [3.0, 2.625]:
				var window := Vector2i(1080, roundi(h * 1080 / 360.0))
				_check_banner(h, b, window, density)
	# 360 dp 寬、640 高、B 16:剛好 (20, 574) dp,與 D10 viewport 座標一致
	_eq(M.banner_dp_position(Vector2(360, 640), Vector2i(1080, 1920), 3.0, 574), Vector2i(20, 574), "360dp exact")


func _check_banner(h: int, b: int, window: Vector2i, density: float) -> void:
	var view := Vector2(360, h)
	var lay := HomeLogic.home_layout(h, 24, b)
	var dp := M.banner_dp_position(view, window, density, lay.banner)
	var s := window.y / view.y
	var top_vp := int(dp.y * density) / s
	var bottom_vp := top_vp + 50 * density / s
	var left_vp := int(dp.x * density) / s
	var right_vp := left_vp + 320 * density / s
	var label := "h%d B%d d%.3f" % [h, b, density]
	# 允許 1 px(實體)誤差:dp 取整數造成
	_eq(top_vp >= lay.banner - 1.0 / s, true, label + " top inside D10 (%.2f >= %d)" % [top_vp, lay.banner])
	_eq(bottom_vp <= h - b + density / s, true, label + " bottom inside D10 (%.2f <= %d)" % [bottom_vp, h - b])
	_eq(top_vp > lay.bottom + 72, true, label + " below bottom buttons")
	_eq(absf((left_vp + right_vp) / 2.0 - 180) <= density / s, true, label + " centered")


func _test_desktop() -> void:
	var ads: Node = root.get_node_or_null(^"AdManager")
	_eq(ads != null, true, "autoload exists")
	_eq(FakeData.ads_removed, false, "ads_removed default")
	if ads:
		_eq(ads._available, false, "desktop not available")
		ads.show_banner()
		ads.hide_banner()
		FakeData.ads_removed = true
		ads.show_banner()
		FakeData.ads_removed = false
		_eq(ads._ad_view, null, "desktop never creates banner")
	await process_frame
	# 外掛在編輯器執行檔下會自動掛模擬廣告節點;管理器沒碰外掛就不該出現
	var mocks := root.get_children().filter(func(n: Node) -> bool:
		return n.get_script() != null and n.get_script().resource_path.begins_with("res://addons/admob"))
	_eq(mocks.size(), 0, "no admob mock nodes")
	print("PASSED %d, FAILED %d" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)
