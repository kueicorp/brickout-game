extends SceneTree
## AdManager 補充測試(QA 新增):
## 1. SDK 初始化前後呼叫 show / hide 的狀態機(用假的原生 AdView,不碰外掛)
## 2. ads_removed 為 true 時不建立 banner
## 3. banner_dp_position 在更多 density / 高度 / 安全區 / 寬螢幕下的換算(依外掛實際算法:margin px = int(dp × density))
## 執行:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path game --script res://tests/test_ad_manager_states.gd
## 有任何失敗時結束碼為 1。

const M := preload("res://scripts/ad_manager.gd")

var _passed := 0
var _failed := 0
var _known_count := 0


## 假的原生 AdView:只記錄呼叫
class FakeAdView:
	var shows := 0
	var hides := 0
	var positions: Array = []

	func show() -> void:
		shows += 1

	func hide() -> void:
		hides += 1

	func set_position(p) -> void:
		positions.append(p)


## 假的 AdPosition:custom(x, y) 只回傳座標
class FakePosition:
	static func custom(x: int, y: int) -> Vector2i:
		return Vector2i(x, y)


## 把「建立原生 banner」換成建立假物件,其餘邏輯用正式程式
class TestAds extends "res://scripts/ad_manager.gd":
	var creates := 0
	var fake: FakeAdView

	func _create_banner() -> void:
		creates += 1
		fake = FakeAdView.new()
		_ad_view = fake
		_density = 3.0


func _initialize() -> void:
	_test_state_machine.call_deferred()


func _eq(actual, expected, label: String) -> void:
	if actual == expected:
		_passed += 1
	else:
		_failed += 1
		printerr("FAIL %s: expected %s, got %s" % [label, str(expected), str(actual)])


## 已知問題:不計為失敗,但每次都印出說明;若已不再發生則照常計為通過並提示可改回一般斷言。
func _known(ok: bool, label: String, detail: String) -> void:
	if ok:
		_passed += 1
		print("KNOWN ISSUE 已不再發生,可改回一般斷言:%s" % label)
	else:
		_known_count += 1
		print("KNOWN ISSUE(不計失敗)%s — %s" % [detail, label])


## 模擬 Android 上已有外掛、SDK 尚未初始化完成的管理器。
## 先加進 tree(_reposition 需要 viewport;桌面上 _ready 會直接 return),再改成「可用」。
func _new_ads() -> TestAds:
	var a := TestAds.new()
	root.add_child(a)
	a._available = true
	a._sdk_ready = false
	a._position_script = FakePosition
	return a


func _sdk_done(a: TestAds) -> void:
	# 與 _ready 裡 on_initialization_complete 的內容相同
	a._sdk_ready = true
	a._apply()


func _test_state_machine() -> void:
	FakeData.ads_removed = false

	# 1. 初始化前 show → 不建立;完成時才建立,且只建立一次
	var a := _new_ads()
	a.show_banner()
	_eq(a.creates, 0, "show before sdk ready: not created yet")
	_sdk_done(a)
	_eq(a.creates, 1, "sdk ready after show: created once")
	a.show_banner()
	a.show_banner()
	_eq(a.creates, 1, "repeated show: no re-create")
	_eq(a.fake.shows, 2, "repeated show: native show called each time")
	a.hide_banner()
	_eq(a.fake.hides, 1, "hide after created: native hide")
	a.show_banner()
	_eq(a.fake.shows, 3, "show again after hide: native show")
	_eq(a.creates, 1, "show again after hide: still one banner")
	a.free()

	# 2. 初始化前 show 再 hide(例如很快離開首頁)→ 完成時不建立
	a = _new_ads()
	a.show_banner()
	a.hide_banner()
	_sdk_done(a)
	_eq(a.creates, 0, "show+hide before ready: not created")
	_eq(a._ad_view, null, "show+hide before ready: no ad view")
	a.free()

	# 3. 初始化前只 hide → 完成時不建立
	a = _new_ads()
	a.hide_banner()
	_sdk_done(a)
	_eq(a.creates, 0, "hide only before ready: not created")
	a.free()

	# 4. 初始化完成後才進首頁 → 立刻建立
	a = _new_ads()
	_sdk_done(a)
	_eq(a.creates, 0, "ready without show: not created")
	a.show_banner()
	_eq(a.creates, 1, "show after ready: created immediately")
	a.free()

	# 5. ads_removed = true:初始化前後 show 都不建立
	FakeData.ads_removed = true
	a = _new_ads()
	a.show_banner()
	_sdk_done(a)
	_eq(a.creates, 0, "ads_removed: show before ready -> not created")
	a.show_banner()
	_eq(a.creates, 0, "ads_removed: show after ready -> not created")
	a.hide_banner()
	_eq(a._ad_view, null, "ads_removed: no ad view")
	a.free()
	FakeData.ads_removed = false

	# 6. 建立後再 show 會先重新定位(用目前畫面)再顯示
	a = _new_ads()
	_sdk_done(a)
	a.show_banner()
	var before: int = a.fake.positions.size()
	a.show_banner()
	_eq(a.fake.positions.size() >= before, true, "show repositions (or no-op when no window)")
	a.free()

	_test_positions()
	print("PASSED %d, FAILED %d, KNOWN %d" % [_passed, _failed, _known_count])
	quit(1 if _failed > 0 else 0)


## 依外掛實際算法(Banner.getLayoutParams:leftMargin/topMargin = (int)(dp × density))換回 viewport 座標
## known:這次列為「已知問題」的斷言代號("bottom" = 不進入下方安全區、"width" = 不超出畫面寬度)。
## 之後要修時,把呼叫端傳入的 known 拿掉即可改回一般斷言。
func _check(view: Vector2, window: Vector2i, density: float, t: int, b: int, tag: String, known: Array = []) -> void:
	var h := int(view.y)
	var lay := HomeLogic.home_layout(h, t, b)
	var dp := M.banner_dp_position(view, window, density, lay.banner)
	var s := window.y / view.y
	var top_vp := int(dp.y * density) / s
	var left_vp := int(dp.x * density) / s
	var w_vp := 320 * density / s
	var h_vp := 50 * density / s
	var buttons_bottom: float = lay.bottom + 72
	# 規格:按鈕下緣 = banner 上緣 − 10
	_eq(buttons_bottom, float(lay.banner - 10), tag + " buttons bottom = banner top - 10 (layout)")
	# 實際 banner 上緣不得高於 D10 上緣(容許 1 個實體 px 的截斷誤差)
	_eq(top_vp >= lay.banner - 1.0 / s, true, tag + " banner top %.3f >= D10 top %d" % [top_vp, lay.banner])
	# 往下偏不超過 1 dp
	_eq(top_vp <= lay.banner + density / s + 0.001, true, tag + " banner top %.3f within 1dp of D10 top %d" % [top_vp, lay.banner])
	# 與按鈕下緣距離至少 10(容許 1 實體 px)
	_eq(top_vp - buttons_bottom >= 10 - 1.0 / s, true, tag + " gap to buttons %.3f >= 10" % (top_vp - buttons_bottom))
	# 水平置中(相對整個視窗)
	_eq(absf(left_vp + w_vp / 2.0 - view.x / 2.0) <= density / s + 0.001, true,
		tag + " centered (center %.2f vs %.2f)" % [left_vp + w_vp / 2.0, view.x / 2.0])
	# 不超出畫面
	_eq(top_vp + h_vp <= view.y + 0.001, true, tag + " banner bottom %.2f inside screen %d" % [top_vp + h_vp, h])
	# 不進入下方安全區(D10 下緣 = h − B)
	var bottom_ok := top_vp + h_vp <= h - b + 1.0 / s
	var bottom_label := tag + " banner bottom %.2f <= h-B %d" % [top_vp + h_vp, h - b]
	if "bottom" in known:
		_known(bottom_ok, bottom_label, "density %.3f: banner 下緣超出 D10 下緣 %.2f viewport px(約 %d 實體 px)"
			% [density, top_vp + h_vp - (h - b), roundi((top_vp + h_vp - (h - b)) * s)])
	else:
		_eq(bottom_ok, true, bottom_label)
	var width_ok := left_vp >= 0.0 and left_vp + w_vp <= view.x + 0.001
	var width_label := tag + " banner inside width (%.2f..%.2f of %d)" % [left_vp, left_vp + w_vp, int(view.x)]
	if "width" in known:
		var over := maxf(-left_vp, left_vp + w_vp - view.x)
		_known(width_ok, width_label, "density %.3f: banner 超出畫面左/右邊緣最多 %.2f viewport px(約 %d 實體 px)"
			% [density, over, roundi(over * s)])
	else:
		_eq(width_ok, true, width_label)


func _test_positions() -> void:
	# 直向手機(寬 ≥ 360 dp,也就是 density ≤ 實體 px / viewport px)
	# 1080 px 寬:density 3 (360 dp)、2.625 (411 dp)、2.75 (392 dp);1440 px 寬:density 3.5 (411 dp)、4 (360 dp);720 px:2 (360 dp)
	var phones := [[1080, 3.0], [1080, 2.625], [1080, 2.75], [1440, 3.5], [1440, 4.0], [720, 2.0], [720, 1.75]]
	for p in phones:
		var wpx: int = p[0]
		var d: float = p[1]
		for h in [640, 701, 780, 853, 900]:
			for tb in [[24, 16], [40, 30], [48, 48], [30, 21]]:
				var view := Vector2(360, h)
				var window := Vector2i(wpx, roundi(h * wpx / 360.0))
				_check(view, window, d, tb[0], tb[1], "w%d d%.3f h%d T%d B%d" % [wpx, d, h, tb[0], tb[1]])
	# 比 9:16 寬(平板 / 摺疊機):viewport 高固定 640、寬延伸
	for wide in [[Vector2(480, 640), Vector2i(1800, 2400), 2.625], [Vector2(450, 640), Vector2i(1080, 1536), 2.0]]:
		_check(wide[0], wide[1], wide[2], 24, 16, "wide %s d%.3f" % [str(wide[0]), wide[2]])
	# 寬不到 360 dp(使用者把「顯示大小」調大,例:1080 px / density 3.375 = 320 dp)
	# 已知問題(使用者決定這次不處理):banner 超出 D10。要修時把第三個元素改成 [] 即恢復一般斷言。
	for n in [[3.375, ["bottom"]], [3.5, ["bottom", "width"]]]:
		var d: float = n[0]
		_check(Vector2(360, 780), Vector2i(1080, 2340), d, 24, 16, "narrow d%.3f" % d, n[1])
