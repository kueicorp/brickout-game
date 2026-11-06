extends SceneTree
## 冒煙測試:開主場景(載入畫面),等它自動切到首頁,再跑幾秒。執行:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path game --script res://tests/smoke_main_scene.gd
## 3 秒內沒進首頁或首頁結構不對時結束碼為 1;錯誤訊息請看輸出中的 ERROR。

const TIMEOUT_SEC := 3.0
const RUN_ON_HOME_SEC := 2.0


func _initialize() -> void:
	change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))
	_run.call_deferred()


func _run() -> void:
	var waited := 0.0
	while (current_scene == null or current_scene.name != "Home") and waited < TIMEOUT_SEC:
		await create_timer(0.1).timeout
		waited += 0.1
	if current_scene == null or current_scene.name != "Home":
		printerr("FAIL: %.1f 秒內沒有進入首頁" % TIMEOUT_SEC)
		quit(1)
		return
	print("entered Home after ~%.1f s" % waited)
	await create_timer(RUN_ON_HOME_SEC).timeout
	var map: LevelMap = current_scene.find_children("*", "LevelMap", true, false)[0]
	var ok := map.group == 2 and map.selected_level == 15
	print("map group %d, selected %d" % [map.group, map.selected_level])
	quit(0 if ok else 1)
