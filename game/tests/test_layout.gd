extends SceneTree
## 直向延伸版面的純函式測試(HomeLogic.home_layout / safe_margins / loading_layout)。執行:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path game --script res://tests/test_layout.gd
## 有任何失敗時結束碼為 1。

const L := preload("res://scripts/home_logic.gd")
const KEYS := ["add_top", "add_bottom", "d01", "d02", "d15", "d06", "bottom", "banner"]

var _passed := 0
var _failed := 0


func _initialize() -> void:
	_test_table()
	_test_deficit()
	_test_big_insets_tall()
	_test_safe_margins()
	_test_loading()
	_test_map_row_cuts()
	print("PASSED %d, FAILED %d" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _eq(actual, expected, label: String) -> void:
	if actual == expected:
		_passed += 1
	else:
		_failed += 1
		printerr("FAIL %s: expected %s, got %s" % [label, str(expected), str(actual)])


## 逐欄比對 KEYS 的值
func _check(h: int, t: int, b: int, expected: Array, label: String) -> Dictionary:
	var lay := L.home_layout(h, t, b)
	for i in KEYS.size():
		_eq(lay[KEYS[i]], expected[i], "%s %s" % [label, KEYS[i]])
	return lay


## T03 對照表(T=24、B=16)
func _test_table() -> void:
	var lay := _check(640, 24, 16, [0, 0, 28, 80, 140, 388, 492, 574], "640")
	_eq(lay.d14, 76, "640 d14")
	_eq(lay.d15_height, 232, "640 d15 height")
	_eq(lay.row_cuts, [0, 0], "640 no row cut")
	# screen-size-800 驗證高度 700(E = 60 → 36 / 24)
	_check(700, 24, 16, [36, 24, 28, 116, 176, 424, 552, 634], "700")
	_check(780, 24, 16, [84, 56, 28, 164, 224, 472, 632, 714], "780")
	_check(800, 24, 16, [96, 64, 28, 176, 236, 484, 652, 734], "800")
	_check(840, 24, 16, [120, 80, 28, 200, 260, 508, 692, 774], "840")
	# 超過 840 不夾住
	_check(900, 24, 16, [156, 104, 28, 236, 296, 544, 752, 834], "900")


## S < 0:640 高且 T 或 B 超過保底,依 D15 第 11 點扣高
func _test_deficit() -> void:
	# E = 4:只吃 D02~D15 留白,D15 與 D06 不動
	_check(640, 28, 16, [0, 0, 32, 84, 140, 388, 492, 574], "cut4")
	# E = 12:D15 下移 4,D15~D06 留白吃 4,D06 仍在 388
	_check(640, 36, 16, [0, 0, 40, 92, 144, 388, 492, 574], "cut12")
	# B 變大也一樣扣:cut 20 → 兩處留白各 8、排間共 4
	var lay := _check(640, 24, 36, [0, 0, 28, 80, 132, 368, 472, 554], "cut20")
	_eq(lay.d15_height, 228, "cut20 d15 height")
	_eq(lay.row_cuts, [2, 2], "cut20 rows split evenly")
	# 奇數:排間縮 1,放在第 2→3 排
	_eq(L.home_layout(640, 24, 33).row_cuts, [0, 1], "cut17 odd split")
	# E = 32:剛好吸收完,D06 與底部列仍間隔 24
	lay = _check(640, 48, 24, [0, 0, 52, 104, 156, 380, 484, 566], "cut32")
	_eq(lay.d15_height, 216, "cut32 d15 height")
	_eq(lay.row_cuts, [8, 8], "cut32 rows")
	_eq(lay.bottom - (lay.d06 + 80), 24, "cut32 gap D06 -> bottom row")
	# E = 35:超過 32 的 3px 由 D06 與底部列的間隔吃掉,排間不再縮
	lay = _check(640, 51, 24, [0, 0, 55, 107, 159, 383, 484, 566], "cut35")
	_eq(lay.row_cuts, [8, 8], "cut35 rows capped")
	_eq(lay.bottom - (lay.d06 + 80), 21, "cut35 gap shrinks")


## 高畫面、T/B 大於保底
func _test_big_insets_tall() -> void:
	# S = 800 − 40 − 30 − 600 = 130 → addTop 78
	_check(800, 40, 30, [78, 52, 44, 174, 234, 482, 638, 720], "800 T40 B30")
	# screen-size-800 S07:瀏海 T=40(E = 144 → 86 / 58)、手勢列 B=34(E = 142 → 85 / 57)
	_check(800, 40, 16, [86, 58, 44, 182, 242, 490, 652, 734], "800 T40")
	_check(800, 24, 34, [85, 57, 28, 165, 225, 473, 634, 716], "800 B34")
	# S = 0 剛好放滿
	_check(660, 30, 30, [0, 0, 34, 86, 146, 394, 498, 580], "S0")
	# S = 33:round(19.8) = 20
	_eq(L.home_layout(673, 24, 16).add_top, 20, "S33 add_top 20")
	_eq(L.home_layout(672, 24, 16).add_top, 19, "S32 add_top 19")


func _test_safe_margins() -> void:
	_eq(L.safe_margins(0, 0, 3), Vector2i(24, 16), "no inset -> floor")
	_eq(L.safe_margins(60, 30, 3), Vector2i(24, 16), "small inset -> floor")
	_eq(L.safe_margins(120, 72, 3), Vector2i(40, 24), "exact conversion")
	_eq(L.safe_margins(100, 50, 3), Vector2i(34, 17), "fraction rounds up")
	_eq(L.safe_margins(100, 50, 0), Vector2i(24, 16), "bad scale -> floor")


## D15 扣高:第 2、3 排往上移,點擊判定跟著格子走
func _test_map_row_cuts() -> void:
	var page: Control = load("res://scripts/ui/map_page.gd").new()
	_eq(page.center(1), Vector2(83, 59), "no cut row1")
	_eq(page.center(10), Vector2(261, 192), "no cut row3")
	page.row_cuts = [3, 5]
	_eq(page.center(1), Vector2(83, 59), "cut row1 fixed")
	_eq(page.center(4), Vector2(306, 123), "cut row2 up 3")
	_eq(page.center(10), Vector2(261, 184), "cut row3 up 8")
	# 第 3 排格子下緣到外框底(232 − 8)的內距維持 12 + 38 − 38 = 原值
	_eq((232 - 8) - page.center(10).y, 232 - 192.0, "bottom padding kept")
	_eq(page.index_at(Vector2(261, 184 + 32)), 10, "touch follows moved tile")
	_eq(page.index_at(Vector2(306, 123 - 32)), 4, "touch row2 top edge")
	page.free()


func _test_loading() -> void:
	_eq(L.loading_layout(640), [200, 520, 527] as Array[int], "loading 640")
	_eq(L.loading_layout(780), [253, 660, 667] as Array[int], "loading 780")
	_eq(L.loading_layout(800), [260, 680, 687] as Array[int], "loading 800")
	_eq(L.loading_layout(840), [275, 720, 727] as Array[int], "loading 840")
