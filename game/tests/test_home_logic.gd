extends SceneTree
## HomeLogic 純邏輯測試。執行:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path game --script res://tests/test_home_logic.gd
## 有任何失敗時結束碼為 1。

const L := preload("res://scripts/home_logic.gd")

var _passed := 0
var _failed := 0


func _initialize() -> void:
	_test_group_theme()
	_test_level_state()
	_test_default_selection()
	_test_theme_selection()
	_test_swipe_selection()
	_test_neighbors_and_arrows()
	_test_gesture()
	_test_page_change()
	_test_roads()
	_test_heart()
	_test_qa_extra()
	print("PASSED %d, FAILED %d" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _eq(actual, expected, label: String) -> void:
	if actual == expected:
		_passed += 1
	else:
		_failed += 1
		printerr("FAIL %s: expected %s, got %s" % [label, str(expected), str(actual)])


func _test_group_theme() -> void:
	_eq(L.group_of_level(1), 1, "group of 1")
	_eq(L.group_of_level(10), 1, "group of 10")
	_eq(L.group_of_level(11), 2, "group of 11")
	_eq(L.group_of_level(200), 20, "group of 200")
	_eq(L.theme_of_group(1), 1, "theme of g1")
	_eq(L.theme_of_group(2), 1, "theme of g2")
	_eq(L.theme_of_group(3), 2, "theme of g3")
	_eq(L.theme_of_group(20), 10, "theme of g20")
	_eq(L.first_group_of_theme(10), 19, "first group of t10")
	_eq(L.level_of(2, 5), 15, "level_of(2,5)")
	_eq(L.level_of(20, 10), 200, "level_of(20,10)")
	_eq(L.is_boss(20), true, "20 is boss")
	_eq(L.is_boss(15), false, "15 not boss")
	_eq(L.THEME_NAMES.size(), 10, "10 theme names")


func _test_level_state() -> void:
	_eq(L.level_state(14, 15), L.LevelState.CLEARED, "14 cleared")
	_eq(L.level_state(15, 15), L.LevelState.PLAYABLE, "15 playable")
	_eq(L.level_state(16, 15), L.LevelState.LOCKED, "16 locked")
	_eq(L.level_state(200, 201), L.LevelState.CLEARED, "all cleared")
	_eq(L.is_theme_locked(1, 15), false, "t1 unlocked")
	_eq(L.is_theme_locked(2, 15), true, "t2 locked at 15")
	_eq(L.is_theme_locked(2, 21), false, "t2 unlocked when 21 playable")
	_eq(L.is_theme_locked(2, 25), false, "t2 second group locked still unlocked theme")


func _test_default_selection() -> void:
	# Q43:第一個未通關所在組、選該關;新玩家第 1 關;全通關第 200 關
	_eq(L.default_selection(15), 15, "default 15")
	_eq(L.group_of_level(L.default_selection(15)), 2, "default group 2")
	_eq(L.default_selection(1), 1, "new player")
	_eq(L.default_selection(201), 200, "all cleared -> 200")
	_eq(L.group_of_level(L.default_selection(201)), 20, "all cleared group 20")


func _test_theme_selection() -> void:
	# Q57:一律該主題第 1 關
	_eq(L.selection_for_theme(1), 1, "theme1 -> 1")
	_eq(L.selection_for_theme(2), 21, "theme2 -> 21")
	_eq(L.selection_for_theme(10), 181, "theme10 -> 181")


func _test_swipe_selection() -> void:
	# Q67 同主題依進度
	_eq(L.selection_after_swipe(1, 2, 15), 15, "same theme with playable")
	_eq(L.selection_after_swipe(2, 1, 15), 10, "same theme all cleared -> boss")
	_eq(L.selection_after_swipe(3, 4, 15), 31, "same theme all locked -> first")
	_eq(L.selection_after_swipe(4, 3, 25), 25, "same theme back with playable")
	# Q61 跨主題
	_eq(L.selection_after_swipe(2, 3, 15), 21, "cross forward -> first")
	_eq(L.selection_after_swipe(3, 2, 15), 20, "cross backward -> theme last (20)")
	_eq(L.selection_after_swipe(3, 2, 201), 20, "cross backward ignores progress")
	_eq(L.selection_after_swipe(4, 5, 45), 41, "cross forward ignores progress")


func _test_neighbors_and_arrows() -> void:
	_eq(L.neighbor_group(1, -1), 0, "g1 prev none")
	_eq(L.neighbor_group(1, 1), 2, "g1 next")
	_eq(L.neighbor_group(20, 1), 0, "g20 next none")
	_eq(L.neighbor_group(2, 1), 3, "g2 next crosses theme")
	_eq(L.is_left_arrow_disabled(1), true, "t1 left disabled")
	_eq(L.is_left_arrow_disabled(2), false, "t2 left enabled")
	_eq(L.is_right_arrow_disabled(10), true, "t10 right disabled")
	_eq(L.is_right_arrow_disabled(9), false, "t9 right enabled")


func _test_gesture() -> void:
	_eq(L.can_start_swipe(Vector2(40, 200)), true, "x40 allowed")
	_eq(L.can_start_swipe(Vector2(39, 200)), false, "x39 not allowed")
	_eq(L.can_start_swipe(Vector2(320, 372)), true, "x320 y372 allowed")
	_eq(L.can_start_swipe(Vector2(321, 200)), false, "x321 not allowed")
	_eq(L.can_start_swipe(Vector2(100, 139)), false, "y139 not allowed")
	_eq(L.classify_motion(Vector2(12, 0)), L.Gesture.UNDECIDED, "12px undecided")
	_eq(L.classify_motion(Vector2(13, 0)), L.Gesture.SWIPE, "13px swipe")
	_eq(L.classify_motion(Vector2(-13, 13)), L.Gesture.SWIPE, "equal -> swipe")
	_eq(L.classify_motion(Vector2(5, -13)), L.Gesture.VERTICAL, "vertical")
	_eq(L.classify_motion(Vector2(10, 10)), L.Gesture.UNDECIDED, "diagonal small undecided")
	_eq(L.is_tap(Vector2(12, 0)), true, "12px tap")
	_eq(L.is_tap(Vector2(9, 9)), false, "diag 12.7 not tap")


func _test_page_change() -> void:
	_eq(L.page_change_direction(-86, 0), 1, "86 left -> next")
	_eq(L.page_change_direction(86, 0), -1, "86 right -> prev")
	_eq(L.page_change_direction(-85, 0), 0, "85 bounce")
	_eq(L.page_change_direction(-24, -600), 1, "fling left")
	_eq(L.page_change_direction(-23, -900), 0, "fling too short")
	_eq(L.page_change_direction(-30, -599), 0, "fling too slow")
	_eq(L.page_change_direction(-30, 700), 0, "fling opposite direction")
	_eq(L.rubber_band(50), 15.0, "rubber 50*0.3")
	_eq(L.rubber_band(200), 24.0, "rubber max")
	_eq(L.rubber_band(-200), -24.0, "rubber min")


func _test_roads() -> void:
	_eq(L.is_road_walked(14, 15), true, "14->15 walked")
	_eq(L.is_road_walked(15, 15), false, "from playable not walked")
	_eq(L.is_road_walked(16, 15), false, "locked not walked")


func _test_heart() -> void:
	_eq(L.heart_countdown_text(754, 3), "下一顆 12:34", "12:34")
	_eq(L.heart_countdown_text(5, 3), "下一顆 00:05", "00:05")
	_eq(L.heart_countdown_text(1200, 3), "下一顆 20:00", "20:00")
	_eq(L.heart_countdown_text(754, 20), "下一顆 00:00", ">=20 -> 00:00")
	_eq(L.is_long_press(499), false, "499 short")
	_eq(L.is_long_press(500), true, "500 long")
	_eq(L.heart_release_goes_to_shop(false, true), true, "short inside -> shop")
	_eq(L.heart_release_goes_to_shop(true, true), false, "after tooltip no shop")
	_eq(L.heart_release_goes_to_shop(false, false), false, "moved out no shop")


## QA 補充:邊界值與另一方向
func _test_qa_extra() -> void:
	# 往右快甩(上一組)與正好門檻
	_eq(L.page_change_direction(24, 600), -1, "fling right -> prev")
	_eq(L.page_change_direction(30, -700), 0, "right drag + left fling -> bounce")
	_eq(L.page_change_direction(0, 0), 0, "no move -> bounce")
	_eq(L.page_change_direction(-344, 0), 1, "full page drag -> next")
	# 手勢判定:負方向
	_eq(L.classify_motion(Vector2(-13, -12)), L.Gesture.SWIPE, "left 13 up 12 -> swipe")
	_eq(L.classify_motion(Vector2(12, -13)), L.Gesture.VERTICAL, "up 13 right 12 -> vertical")
	_eq(L.classify_motion(Vector2(0, 0)), L.Gesture.UNDECIDED, "zero undecided")
	_eq(L.can_start_swipe(Vector2(100, 373)), false, "y373 not allowed")
	_eq(L.can_start_swipe(Vector2(100, 140)), true, "y140 allowed")
	_eq(L.rubber_band(-50), -15.0, "rubber -50*0.3")
	_eq(L.rubber_band(0), 0.0, "rubber 0")
	# 主題 10 解鎖邊界、最後一組選取
	_eq(L.is_theme_locked(10, 180), true, "t10 locked at 180")
	_eq(L.is_theme_locked(10, 181), false, "t10 unlocked at 181")
	_eq(L.is_theme_locked(1, 1), false, "t1 never locked")
	_eq(L.selection_after_swipe(19, 20, 201), 200, "all cleared g19->g20 -> 200")
	_eq(L.selection_after_swipe(20, 19, 195), 190, "g20->g19 when g19 all cleared -> boss 190")
	_eq(L.selection_after_swipe(1, 2, 11), 11, "g2 playable at its first level")
	_eq(L.selection_after_swipe(1, 2, 20), 20, "g2 playable boss")
	_eq(L.selection_after_swipe(18, 19, 1), 181, "cross forward locked -> first")
	_eq(L.selection_for_theme(5), 81, "theme5 -> 81")
	_eq(L.is_boss(200), true, "200 boss")
	_eq(L.is_boss(1), false, "1 not boss")
	_eq(L.level_state(1, 1), L.LevelState.PLAYABLE, "new player 1 playable")
	_eq(L.neighbor_group(19, 1), 20, "g19 next 20")
	_eq(L.neighbor_group(3, -1), 2, "g3 prev crosses theme back")
	# 倒數字串的夾限
	_eq(L.heart_countdown_text(-5, 3), "下一顆 00:00", "negative clamps to 0")
	_eq(L.heart_countdown_text(5000, 3), "下一顆 20:00", "over 20:00 clamps")
	_eq(L.heart_countdown_text(59, 19), "下一顆 00:59", "19 hearts still counts")
	_eq(L.heart_countdown_text(59, 25), "下一顆 00:00", "over cap -> 00:00")
	_eq(L.is_long_press(0), false, "0ms short")
