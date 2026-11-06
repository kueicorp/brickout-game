extends SceneTree
## 首頁互動測試(QA 新增):直接開首頁場景,用 push_input 模擬手指(滑鼠模擬觸控)操作。執行:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path game --script res://tests/test_home_interaction.gd
## 有任何失敗時結束碼為 1。直接開 home.tscn(不經過載入畫面的背景載入)。

const MAP_ORIGIN := Vector2(8, 140)
## 組內序號 → 格子中心(畫面座標,設計稿 D15 第 2 點)
const C := {
	1: Vector2(91, 199), 2: Vector2(180, 199), 3: Vector2(269, 199),
	4: Vector2(314, 266), 5: Vector2(224, 266), 6: Vector2(136, 266), 7: Vector2(46, 266),
	8: Vector2(91, 332), 9: Vector2(180, 332), 10: Vector2(269, 332),
}
const D06 := Vector2(180, 428)
## StartButton.Look 的值;測試腳本不直接引用 class_name,避免結束時誤報 ObjectDB 洩漏
const LOOK_NORMAL := 0
const LOOK_BOSS := 1
const LOOK_DISABLED := 2
const HEART := Vector2(30, 50)
const LEFT := Vector2(32, 104)
const TITLE := Vector2(180, 104)
const RIGHT := Vector2(328, 104)

var _passed := 0
var _failed := 0
var home
var map
var counts := {}


func _initialize() -> void:
	change_scene_to_file("res://scenes/home.tscn")
	_run.call_deferred()


func _eq(actual, expected, label: String) -> void:
	if actual == expected:
		_passed += 1
	else:
		_failed += 1
		printerr("FAIL %s: expected %s, got %s" % [label, str(expected), str(actual)])


# ---- 輸入 ----

func _button(pos: Vector2, pressed: bool, canceled := false) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.canceled = canceled
	e.position = pos
	e.global_position = pos
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	root.push_input(e, true)


func _move(pos: Vector2, vel := Vector2.ZERO) -> void:
	var e := InputEventMouseMotion.new()
	e.position = pos
	e.global_position = pos
	e.velocity = vel
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(e, true)


func _hover(pos: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = pos
	e.global_position = pos
	root.push_input(e, true)


func _tap(pos: Vector2) -> void:
	_hover(pos)
	_button(pos, true)
	_button(pos, false)


## 從 from 拖 dx/dy,分 4 段移動,放開時水平速度 vel_x
func _drag(from: Vector2, delta: Vector2, vel_x := 0.0, canceled := false) -> void:
	_hover(from)
	_button(from, true)
	for i in range(1, 5):
		_move(from + delta * (i / 4.0), Vector2(vel_x, 0))
	_button(from + delta, false, canceled)


func _wait(sec: float) -> void:
	await create_timer(sec).timeout


func _frames(n := 2) -> void:
	for i in n:
		await process_frame


func _settle() -> void:
	await _wait(0.35)


func _count(key: String) -> Callable:
	return func() -> void: counts[key] = counts.get(key, 0) + 1


func _c(key: String) -> int:
	return counts.get(key, 0)


## 回到指定組(用 show_group 直接設,避免測試互相影響)
func _reset(group: int, level: int) -> void:
	map.show_group(group, level)
	home._apply_theme(ceili(group / 2.0))
	home._apply_selection(level)
	await _frames()


func _run() -> void:
	while current_scene == null or current_scene.name != "Home":
		await process_frame
	home = current_scene
	await _frames(3)
	map = home._map
	home._heart.pressed.connect(_count("heart_pressed"))
	home._start.pressed.connect(_count("start_pressed"))
	home._title.pressed.connect(_count("title_pressed"))
	home._right.pressed.connect(_count("right_pressed"))
	home._left.pressed.connect(_count("left_pressed"))
	for b in home.get_children():
		if "label" in b and b is BaseButton:
			b.pressed.connect(_count("bottom_" + b.label))

	await _test_initial()
	await _test_tap_select()
	await _test_swipe_threshold()
	await _test_fling()
	await _test_vertical_and_start_zone()
	await _test_cross_theme_and_edges()
	await _test_animation_lock()
	await _test_arrows()
	await _test_d06()
	await _test_heart()
	await _test_bottom_and_title()
	await _test_cancel()
	await _test_cancel_release_extra()
	print("PASSED %d, FAILED %d" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_initial() -> void:
	_eq(map.group, 2, "init group 2")
	_eq(home.selected_level, 15, "init selected 15")
	_eq(home.current_theme, 1, "init theme 1")
	_eq(home._left.disabled, true, "init left disabled")
	_eq(home._right.disabled, false, "init right enabled")
	_eq(home._title.title_color, Color.WHITE, "init title white")
	_eq(home._start.look, LOOK_NORMAL, "init D06 normal")
	_eq(home._tooltip.visible, false, "init tooltip hidden")


func _test_tap_select() -> void:
	await _reset(2, 15)
	_tap(C[3])
	await _frames()
	_eq(home.selected_level, 13, "tap tile 3 -> 13")
	_eq(map._pages[1].hop_pos != null, true, "hop in progress right after tap")
	await _wait(0.25)
	_eq(map._pages[1].hop_pos, null, "hop finished after 150ms")
	# 再點同一格無動作
	_tap(C[3])
	await _frames()
	_eq(map._pages[1].hop_pos, null, "tap same tile -> no hop")
	# 移動剛好 12px 仍算點擊
	_hover(C[2])
	_button(C[2], true)
	_move(C[2] + Vector2(0, 12))
	_button(C[2] + Vector2(0, 12), false)
	await _frames()
	_eq(home.selected_level, 12, "move 12px vertical still tap")
	# 斜移 9,9 (12.7px) 不算點擊
	_hover(C[1])
	_button(C[1], true)
	_move(C[1] + Vector2(9, 9))
	_button(C[1] + Vector2(9, 9), false)
	await _frames()
	_eq(home.selected_level, 12, "diag 12.7px not tap")
	# 水平 13px → 滑動,不選取
	_drag(C[1], Vector2(-13, 0))
	await _settle()
	_eq(home.selected_level, 12, "13px horizontal -> swipe, no select")
	_eq(map.group, 2, "13px swipe -> bounce")
	_eq(map._strip.position.x, 0.0, "strip back to 0")
	# 按下狀態:按住時 pressed_index,放開清除
	_hover(C[9])
	_button(C[9], true)
	await _frames()
	_eq(map._pages[1].pressed_index, 9, "pressed index while held")
	_move(C[9] + Vector2(13, 0))
	await _frames()
	_eq(map._pages[1].pressed_index, 0, "pressed cleared when swipe starts")
	_button(C[9] + Vector2(13, 0), false)
	await _settle()
	# 點未解鎖格 → 選取,D06 停用
	_tap(C[9])
	await _frames()
	_eq(home.selected_level, 19, "tap locked 19 selects")
	_eq(home._start.look, LOOK_DISABLED, "locked -> D06 disabled")
	_tap(C[10])
	await _frames()
	_eq(home._start.look, LOOK_DISABLED, "locked boss 20 -> D06 disabled (Q76)")
	# 跳到一半點別格:從當時位置改跳
	_tap(C[1])
	await _wait(0.07)
	var mid: Vector2 = map._pages[1].hop_pos
	_tap(C[8])
	await _frames(1)
	var after: Vector2 = map._pages[1].hop_pos
	_eq(home.selected_level, 18, "tap during hop selects new")
	_eq(after.distance_to(mid) < 20.0, true, "re-hop starts from current pos (dist %.1f)" % after.distance_to(mid))
	await _wait(0.25)


func _test_swipe_threshold() -> void:
	await _reset(1, 10)
	_drag(Vector2(200, 250), Vector2(-85, 0))
	await _settle()
	_eq(map.group, 1, "85px -> bounce")
	_drag(Vector2(200, 250), Vector2(-86, 0))
	await _wait(0.05)
	_eq(map.group, 1, "group unchanged during page animation (Q64)")
	await _settle()
	_eq(map.group, 2, "86px left -> next group")
	_eq(home.selected_level, 15, "same theme 1->2 with playable -> 15 (Q43/Q67)")
	_drag(Vector2(150, 250), Vector2(86, 0))
	await _settle()
	_eq(map.group, 1, "86px right -> prev group")
	_eq(home.selected_level, 10, "same theme 2->1 all cleared -> boss 10")
	# 跟手 1:1
	_hover(Vector2(200, 250))
	_button(Vector2(200, 250), true)
	_move(Vector2(160, 250))
	_move(Vector2(150, 250))
	await _frames()
	_eq(map._strip.position.x, -50.0, "drag follows finger 1:1")
	_button(Vector2(150, 250), false)
	await _settle()
	# 一次最多一組
	_drag(Vector2(300, 250), Vector2(-250, 0), -3000)
	await _settle()
	_eq(map.group, 2, "huge fling only 1 group")


func _test_fling() -> void:
	await _reset(2, 15)
	_drag(Vector2(200, 250), Vector2(-24, 0), -600)
	await _settle()
	_eq(map.group, 3, "fling 24px@600 -> next")
	await _reset(2, 15)
	_drag(Vector2(200, 250), Vector2(-23, 0), -900)
	await _settle()
	_eq(map.group, 2, "fling 23px -> bounce")
	_drag(Vector2(200, 250), Vector2(-30, 0), -599)
	await _settle()
	_eq(map.group, 2, "fling 599px/s -> bounce")
	_drag(Vector2(200, 250), Vector2(-30, 0), 700)
	await _settle()
	_eq(map.group, 2, "opposite fling -> bounce")
	# 甩完停住 150ms 再放開 → 速度視為 0
	_hover(Vector2(200, 250))
	_button(Vector2(200, 250), true)
	_move(Vector2(185, 250), Vector2(-900, 0))
	_move(Vector2(170, 250), Vector2(-900, 0))
	await _wait(0.15)
	_button(Vector2(170, 250), false)
	await _settle()
	_eq(map.group, 2, "stale velocity -> bounce")


func _test_vertical_and_start_zone() -> void:
	await _reset(2, 15)
	_hover(C[5])
	_button(C[5], true)
	_move(C[5] + Vector2(0, 20))
	_move(C[5] + Vector2(-120, 20))
	await _frames()
	_eq(map._strip.position.x, 0.0, "vertical first -> horizontal ignored")
	_button(C[5] + Vector2(-120, 20), false)
	await _settle()
	_eq(map.group, 2, "vertical gesture no page")
	_eq(home.selected_level, 15, "vertical gesture no select")
	# 起手 x 39(範圍外)水平滑 → 不翻頁、不選取
	var p := Vector2(39, 266)
	_drag(p, Vector2(150, 0))
	await _settle()
	_eq(map.group, 2, "start x39 -> no page")
	_eq(home.selected_level, 15, "start x39 swipe -> no select")
	_drag(Vector2(321, 266), Vector2(-150, 0))
	await _settle()
	_eq(map.group, 2, "start x321 -> no page")
	# 範圍外仍可點擊(點 7 左緣)
	_tap(Vector2(20, 266))
	await _frames()
	_eq(home.selected_level, 17, "tap x20 selects tile 7")
	await _wait(0.2)
	# x 40 起手可以翻頁
	_drag(Vector2(40, 300), Vector2(100, 0))
	await _settle()
	_eq(map.group, 1, "start x40 -> page")
	await _reset(2, 15)
	_drag(Vector2(320, 300), Vector2(-100, 0))
	await _settle()
	_eq(map.group, 3, "start x320 -> page")


func _test_cross_theme_and_edges() -> void:
	await _reset(2, 15)
	_drag(Vector2(250, 250), Vector2(-100, 0))
	await _wait(0.05)
	_eq(home.current_theme, 1, "theme not changed during anim (Q64)")
	await _settle()
	_eq(map.group, 3, "cross forward -> group 3")
	_eq(home.selected_level, 21, "cross forward -> 21 (Q61)")
	_eq(home.current_theme, 2, "theme 2 after cross")
	_eq(home._title.title_color, Color("#B0B0B0"), "locked theme title grey")
	_eq(home._start.look, LOOK_DISABLED, "locked theme D06 disabled (Q63)")
	_eq(home._left.disabled, false, "theme 2 left enabled")
	_drag(Vector2(250, 250), Vector2(-100, 0))
	await _settle()
	_eq(map.group, 4, "group 3 -> 4")
	_eq(home.selected_level, 31, "same theme all locked -> first (31)")
	_drag(Vector2(100, 250), Vector2(100, 0))
	await _settle()
	_drag(Vector2(100, 250), Vector2(100, 0))
	await _settle()
	_eq(map.group, 2, "cross backward -> group 2")
	_eq(home.selected_level, 20, "cross backward -> theme last 20 (Q61)")
	_eq(home.current_theme, 1, "back to theme 1")
	_eq(home._start.look, LOOK_DISABLED, "20 locked -> disabled")
	# 最前端橡皮筋
	await _reset(1, 10)
	_hover(Vector2(100, 250))
	_button(Vector2(100, 250), true)
	_move(Vector2(115, 250))
	_move(Vector2(150, 250))
	await _frames()
	_eq(map._strip.position.x, 15.0, "rubber 50*0.3 = 15")
	_move(Vector2(300, 250))
	await _frames()
	_eq(map._strip.position.x, 24.0, "rubber max 24")
	_button(Vector2(300, 250), false)
	await _wait(0.1)
	_eq(map._strip.position.x > 0.0, true, "bounce animating (150ms)")
	await _settle()
	_eq(map._strip.position.x, 0.0, "rubber bounced back")
	_eq(map.group, 1, "edge stays group 1")
	# 組 1 往左仍正常(不是橡皮筋)
	_hover(Vector2(200, 250))
	_button(Vector2(200, 250), true)
	_move(Vector2(185, 250))
	_move(Vector2(150, 250))
	await _frames()
	_eq(map._strip.position.x, -50.0, "group1 left drag not rubber")
	_button(Vector2(150, 250), false)
	await _settle()
	# 最後端
	await _reset(20, 191)
	_drag(Vector2(250, 250), Vector2(-200, 0), -2000)
	await _settle()
	_eq(map.group, 20, "group 20 left -> edge bounce")
	_eq(home.current_theme, 10, "theme 10 stays")


func _test_animation_lock() -> void:
	await _reset(2, 15)
	_drag(Vector2(250, 250), Vector2(-100, 0))
	await _frames(1)
	_eq(map.is_animating(), true, "page anim running")
	# 動畫中再滑 → 忽略
	_drag(Vector2(250, 250), Vector2(-100, 0))
	# 動畫中按箭頭 → 忽略
	_tap(RIGHT)
	await _settle()
	_eq(map.group, 3, "second swipe during anim ignored")
	_eq(home.current_theme, 2, "arrow during anim ignored")


func _test_arrows() -> void:
	await _reset(2, 15)
	_tap(LEFT)
	await _frames()
	_eq(home.current_theme, 1, "left disabled at theme 1")
	_eq(_c("left_pressed"), 0, "disabled left no pressed")
	_tap(RIGHT)
	await _frames()
	_eq(home.current_theme, 2, "right -> theme 2")
	_eq(map.group, 3, "arrow -> theme first group (Q57)")
	_eq(home.selected_level, 21, "arrow -> theme first level (Q57)")
	_eq(home._bg.texture.resource_path.ends_with("bg_theme02.png"), true, "background switched")
	for i in 8:
		_tap(RIGHT)
		await _frames()
	_eq(home.current_theme, 10, "reach theme 10")
	_eq(home._right.disabled, true, "right disabled at 10")
	_tap(RIGHT)
	await _frames()
	_eq(home.current_theme, 10, "disabled right no change")
	_tap(LEFT)
	await _frames()
	_eq(home.current_theme, 9, "left -> 9")
	_eq(home.selected_level, 161, "theme 9 -> 161")
	# 移出箭頭再放開不切換
	_hover(LEFT)
	_button(LEFT, true)
	_move(Vector2(32, 200))
	_button(Vector2(32, 200), false)
	await _frames()
	_eq(home.current_theme, 9, "arrow released outside -> no switch")
	# 回主題 1(已解鎖)名稱白色
	for i in 8:
		_tap(LEFT)
		await _frames()
	_eq(home.current_theme, 1, "back to theme 1")
	_eq(home.selected_level, 1, "theme 1 via arrow -> level 1 (Q57, not progress)")
	_eq(map.group, 1, "theme 1 via arrow -> group 1")
	_eq(home._title.title_color, Color.WHITE, "unlocked theme title white")


func _test_d06() -> void:
	await _reset(1, 10)
	_eq(home._start.look, LOOK_BOSS, "cleared boss 10 -> boss look")
	var before := _c("start_pressed")
	_tap(D06)
	await _frames()
	_eq(_c("start_pressed"), before + 1, "boss start pressable")
	await _reset(2, 19)
	_tap(D06)
	await _frames()
	_eq(_c("start_pressed"), before + 1, "disabled start not pressable")
	await _reset(2, 15)
	_eq(home._start.look, LOOK_NORMAL, "playable -> normal")
	_hover(D06)
	_button(D06, true)
	await _frames()
	_eq(home._start.is_held(), true, "D06 held while pressed")
	_move(Vector2(180, 600))
	await _frames()
	_eq(home._start.is_held(), false, "D06 not held after moving out")
	_button(Vector2(180, 600), false)
	await _frames()
	_eq(_c("start_pressed"), before + 1, "D06 released outside -> no start")


func _test_heart() -> void:
	await _reset(2, 15)
	var shop0 := _c("heart_pressed")
	# 短按 → 去商城
	_hover(HEART)
	_button(HEART, true)
	await _wait(0.2)
	_button(HEART, false)
	await _frames()
	_eq(home._tooltip.visible, false, "short press no tooltip")
	_eq(_c("heart_pressed") == shop0 + 1 and not home._tooltip_shown_this_press, true, "short press -> shop")
	# 長按 → D14,放開不去商城
	_hover(HEART)
	_button(HEART, true)
	await _wait(0.45)
	_eq(home._tooltip.visible, false, "450ms no tooltip yet")
	await _wait(0.15)
	_eq(home._tooltip.visible, true, "600ms tooltip shown")
	var text0: String = home._tooltip.text
	await _wait(1.05)
	_eq(home._tooltip.text != text0, true, "tooltip updates every second")
	_button(HEART, false)
	await _frames()
	_eq(home._tooltip.visible, false, "release closes tooltip")
	_eq(home._tooltip_shown_this_press, true, "long press release -> no shop (tooltip shown flag)")
	# 移出後到 500ms 不顯示,放開不去商城
	var c1 := _c("heart_pressed")
	_hover(HEART)
	_button(HEART, true)
	_move(Vector2(30, 300))
	await _wait(0.6)
	_eq(home._tooltip.visible, false, "moved out -> no tooltip")
	_button(Vector2(30, 300), false)
	await _frames()
	_eq(_c("heart_pressed"), c1, "moved out release -> no shop")
	# 系統中斷關閉 D14
	_hover(HEART)
	_button(HEART, true)
	await _wait(0.6)
	_eq(home._tooltip.visible, true, "tooltip before focus out")
	home.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	await _frames()
	_eq(home._tooltip.visible, false, "focus out closes tooltip")
	_button(HEART, false)
	await _frames()


func _test_bottom_and_title() -> void:
	for label in ["活動", "商城", "成長", "設定"]:
		counts["bottom_" + label] = 0
	var xs := [49, 136, 223, 310]
	var labels := ["活動", "商城", "成長", "設定"]
	for i in 4:
		_tap(Vector2(xs[i], 528))
		await _frames()
		_eq(_c("bottom_" + labels[i]), 1, "bottom %s tap" % labels[i])
	# 按住 → is_held;移出 → 放開不觸發
	var btn = null
	for b in home.get_children():
		if "label" in b and b is BaseButton and b.label == "商城":
			btn = b
	_hover(Vector2(136, 528))
	_button(Vector2(136, 528), true)
	await _frames()
	_eq(btn.is_held(), true, "bottom held")
	_move(Vector2(136, 300))
	await _frames()
	_eq(btn.is_held(), false, "bottom moved out not held")
	_button(Vector2(136, 300), false)
	await _frames()
	_eq(_c("bottom_商城"), 1, "bottom moved out -> no trigger")
	# 邊界:x 91~94 是格與格的空隙,不觸發
	_tap(Vector2(92, 528))
	await _frames()
	var total := 0
	for l in labels:
		total += _c("bottom_" + l)
	_eq(total, 4, "gap x92 no trigger")
	var t0 := _c("title_pressed")
	_tap(TITLE)
	await _frames()
	_eq(_c("title_pressed"), t0 + 1, "title tap -> theme select log")


## 手勢被系統取消:設計稿 D15 第 4 點「手勢被取消(來電、系統手勢攔截) → 一律回彈」
func _test_cancel() -> void:
	await _reset(2, 15)
	# 第二根手指落下 → 回原位、放開不換頁
	_hover(Vector2(250, 250))
	_button(Vector2(250, 250), true)
	_move(Vector2(230, 250))
	_move(Vector2(150, 250))
	var t := InputEventScreenTouch.new()
	t.index = 1
	t.pressed = true
	t.position = Vector2(100, 300)
	root.push_input(t, true)
	await _wait(0.3)
	_eq(map._strip.position.x, 0.0, "second finger -> back to origin")
	_button(Vector2(150, 250), false)
	await _settle()
	_eq(map.group, 2, "second finger -> no page change")
	# 拖曳中失去焦點 → 回彈
	_hover(Vector2(250, 250))
	_button(Vector2(250, 250), true)
	_move(Vector2(230, 250))
	_move(Vector2(150, 250))
	map.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	await _wait(0.3)
	_button(Vector2(150, 250), false)
	await _settle()
	_eq(map.group, 2, "focus out during drag -> no page change")
	# 放開事件帶 canceled(系統取消觸控)→ 應回彈、不換頁
	_drag(Vector2(250, 250), Vector2(-100, 0), 0.0, true)
	await _settle()
	_eq(map.group, 2, "canceled release -> bounce, no page change")
	# 點格子但觸控被取消 → 不選取
	await _reset(2, 15)
	_hover(C[1])
	_button(C[1], true)
	_button(C[1], false, true)
	await _frames()
	_eq(home.selected_level, 15, "canceled tap -> no select")
	await _wait(0.2)
	# D06 觸控被取消 → 不觸發
	var s0 := _c("start_pressed")
	_hover(D06)
	_button(D06, true)
	_button(D06, false, true)
	await _frames()
	_eq(_c("start_pressed"), s0, "canceled D06 release -> no start")


## QA round2(B2 重測):canceled 放開的更多情境 + 取消後下一個手勢恢復正常
func _test_cancel_release_extra() -> void:
	# 1. 快甩門檻內(24px@600)但被取消 → 回彈
	await _reset(2, 15)
	_drag(Vector2(200, 250), Vector2(-24, 0), -600, true)
	await _settle()
	_eq(map.group, 2, "r2 canceled fling -> no page")
	_eq(map._strip.position.x, 0.0, "r2 canceled fling -> strip 0")
	# 2. 大距離、大速度被取消 → 回彈(回彈動畫中段 strip 仍在路上,結束後 0)
	_drag(Vector2(300, 250), Vector2(-200, 0), -3000, true)
	await _wait(0.05)
	_eq(map.group, 2, "r2 canceled big swipe -> group unchanged mid-anim")
	await _settle()
	_eq(map.group, 2, "r2 canceled big swipe -> no page")
	_eq(map._strip.position.x, 0.0, "r2 canceled big swipe -> strip 0")
	_eq(home.selected_level, 15, "r2 canceled big swipe -> selection kept")
	# 3. 橡皮筋中被取消 → 回原位
	await _reset(1, 10)
	_drag(Vector2(100, 250), Vector2(200, 0), 0.0, true)
	await _settle()
	_eq(map._strip.position.x, 0.0, "r2 canceled rubber -> strip 0")
	_eq(map.group, 1, "r2 canceled rubber -> group 1")
	# 4. 小移動(未判定)放開被取消 → 不選取、按下狀態清除
	await _reset(2, 15)
	_hover(C[3])
	_button(C[3], true)
	_move(C[3] + Vector2(5, 3))
	_button(C[3] + Vector2(5, 3), false, true)
	await _frames()
	_eq(home.selected_level, 15, "r2 canceled small move -> no select")
	_eq(map._pages[1].pressed_index, 0, "r2 canceled -> pressed cleared")
	# 5. 垂直手勢被取消 → 不選取、不換頁
	_hover(C[5])
	_button(C[5], true)
	_move(C[5] + Vector2(0, 20))
	_button(C[5] + Vector2(0, 20), false, true)
	await _settle()
	_eq(home.selected_level, 15, "r2 canceled vertical -> no select")
	_eq(map.group, 2, "r2 canceled vertical -> no page")
	# 6. 取消後下一個手勢恢復正常(不可殘留 _ignored)
	_tap(C[3])
	await _wait(0.25)
	_eq(home.selected_level, 13, "r2 tap after cancel works")
	_drag(Vector2(200, 250), Vector2(-86, 0))
	await _settle()
	_eq(map.group, 3, "r2 swipe after cancel works")
	# 7. D02 箭頭 / 中間文字被取消 → 不觸發(設計稿 D02:移出或被取消不切換)
	await _reset(2, 15)
	var r0 := _c("right_pressed")
	_hover(RIGHT)
	_button(RIGHT, true)
	_button(RIGHT, false, true)
	await _frames()
	_eq(home.current_theme, 1, "r2 canceled right arrow -> no switch")
	_eq(_c("right_pressed"), r0, "r2 canceled right arrow -> no pressed")
	var t0 := _c("title_pressed")
	_hover(TITLE)
	_button(TITLE, true)
	_button(TITLE, false, true)
	await _frames()
	_eq(_c("title_pressed"), t0, "r2 canceled title -> no trigger")
	# 8. 愛心短按被取消 → 不去商城(D01 確認稿)
	var h0 := _c("heart_pressed")
	_hover(HEART)
	_button(HEART, true)
	await _wait(0.1)
	_button(HEART, false, true)
	await _frames()
	_eq(_c("heart_pressed"), h0, "r2 canceled heart -> no shop")
