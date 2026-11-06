extends SceneTree
## D20 底部共用黑底補充測試(QA 新增):補 test_home_tall 沒涵蓋的部分。
##   - D20 外框 = 4 格外緣左右齊平、上下各外擴 4px(由按鈕實際位置推算,不依賴 HomeLogic)
##   - 4 格觸控各 83×72、間距不變
##   - 圖層在背景、D15、D06、D01 之上;沒有 z_index / top_level / modulate 等會改變外觀或圖層的設定
##   - 視窗大小改變後 D20 跟著底部列移動
##   - 按住底部按鈕時 D20 不變(按下回饋只在按鈕本身)
## 執行:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path game --script res://tests/test_home_d20.gd
## 有任何失敗時結束碼為 1。

const HOME_SIM_PATH := "res://tests/home_sim.gd"

var _passed := 0
var _failed := 0
var home


func _initialize() -> void:
	_run.call_deferred()


func _eq(actual, expected, label: String) -> void:
	if actual == expected:
		_passed += 1
	else:
		_failed += 1
		printerr("FAIL %s: expected %s, got %s" % [label, str(expected), str(actual)])


func _frames(n := 2) -> void:
	for i in n:
		await process_frame


func _button(pos: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = pos
	e.global_position = pos
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	root.push_input(e, true)


func _make_home(h: int, t: int, b: int) -> void:
	if home:
		home.queue_free()
		await _frames()
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(360, h)
	await _frames()
	var node: Control = load("res://scenes/home.tscn").instantiate()
	node.set_script(load(HOME_SIM_PATH))
	node.sim_view = Vector2(360, h)
	node.sim_safe = Vector2i(t, b)
	root.add_child(node)
	home = node
	await _frames(3)


func _run() -> void:
	for c in [[640, 24, 16], [780, 24, 16], [800, 40, 30], [900, 24, 16], [640, 48, 24]]:
		await _make_home(c[0], c[1], c[2])
		_check_static("H%d T%d B%d" % c)
	await _test_resize()
	await _test_press_keeps_bg()
	if home:
		home.queue_free()
		await _frames()
	print("PASSED %d, FAILED %d" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _check_static(tag: String) -> void:
	var bg: Control = home._bottom_bg
	var btns: Array = home._bottom_buttons
	_eq(btns.size(), 4, tag + " 4 bottom buttons")
	for i in btns.size():
		var r := Rect2(btns[i].position, btns[i].size)
		_eq(r.size, Vector2(83, 72), "%s button %d touch 83x72" % [tag, i])
		_eq(r.position.x, 8.0 + i * 87, "%s button %d x" % [tag, i])
		_eq(r.position.y, btns[0].position.y, "%s button %d same row" % [tag, i])
	# 外框 = 4 格外緣左右齊平、上下各 +4
	var row := Rect2(btns[0].position, Vector2(btns[3].position.x + btns[3].size.x - btns[0].position.x, btns[0].size.y))
	_eq(bg.position.x, row.position.x, tag + " D20 left = row left")
	_eq(bg.position.x + bg.size.x, row.end.x, tag + " D20 right = row right")
	_eq(bg.position.y, row.position.y - 4, tag + " D20 top = row top - 4")
	_eq(bg.position.y + bg.size.y, row.end.y + 4, tag + " D20 bottom = row bottom + 4")
	# 外觀不被其他設定改掉
	_eq(bg.visible, true, tag + " D20 visible")
	_eq(bg.modulate, Color.WHITE, tag + " D20 modulate white")
	_eq(bg.self_modulate, Color.WHITE, tag + " D20 self_modulate white")
	_eq(bg.z_index, 0, tag + " D20 z_index 0")
	_eq(bg.top_level, false, tag + " D20 not top_level")
	_eq(bg.get_parent(), home, tag + " D20 parent is home")
	_eq(bg.get_child_count(), 0, tag + " D20 no children (no frame / divider)")
	_eq(bg.draw.get_connections().size(), 1, tag + " D20 has one draw callback")
	# 圖層:背景、D15、D06、D01 之下 → D20 → 按鈕
	var idx := bg.get_index()
	for pair in [["bg", home._bg], ["bg_top", home._bg_top], ["D15", home._map], ["D06", home._start], ["D01", home._resources]]:
		_eq(idx > pair[1].get_index(), true, "%s D20 above %s" % [tag, pair[0]])
	for b in btns:
		_eq(b.z_index, 0, tag + " bottom button z_index 0")
	_eq(home._tooltip.z_index >= 0, true, tag + " D14 z_index not below")


func _test_resize() -> void:
	await _make_home(640, 24, 16)
	_eq(home._bottom_bg.position.y, 488.0, "resize start D20 y 488")
	home.sim_view = Vector2(360, 840)
	root.size_changed.emit()
	await _frames()
	_eq(home._bottom_bg.position.y, 688.0, "resize 640->840 D20 y")
	_eq(home._bottom_bg.position.y, home._bottom_buttons[0].position.y - 4, "resize D20 follows row")
	home.sim_safe = Vector2i(24, 40)
	root.size_changed.emit()
	await _frames()
	# 840 − 40 − 132 − 4 = 664
	_eq(home._bottom_bg.position.y, 664.0, "resize B40 D20 y")
	_eq(home._bottom_bg.size, Vector2(344, 80), "resize D20 size fixed")


func _test_press_keeps_bg() -> void:
	await _make_home(640, 24, 16)
	var bg: Control = home._bottom_bg
	var before := [Rect2(bg.position, bg.size), bg.modulate, bg.self_modulate, bg.visible, bg.get_index()]
	_button(Vector2(49, 528), true)
	await _frames()
	_eq(home._bottom_buttons[0].is_held(), true, "press reached button 0 (held)")
	var during := [Rect2(bg.position, bg.size), bg.modulate, bg.self_modulate, bg.visible, bg.get_index()]
	_eq(during, before, "D20 unchanged while button held")
	_button(Vector2(49, 528), false)
	await _frames()
