extends SceneTree
## QA:首頁沒有提示框、沒有活動頁時按返回鍵(Android 返回鍵 / 返回手勢)→ 照原本行為結束 App。
## 首頁會呼叫 get_tree().quit(),所以本測試「被結束」才是通過;下一個 frame 還活著就是失敗。執行:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path game --script res://tests/test_qa_back_quit.gd
## 通過:最後一行 PASSED 1, FAILED 0、結束碼 0;失敗:結束碼 1。

const S := preload("res://scripts/event_service.gd")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	S.reset()
	S.delay_sec = 0.05
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(360, 640)
	var node: Control = load("res://scenes/home.tscn").instantiate()
	node.set_script(load("res://tests/home_sim.gd"))
	root.add_child(node)
	await create_timer(0.2).timeout
	if node._popup.is_open() or node._event != null:
		printerr("FAIL precondition: popup or event open")
		print("PASSED 0, FAILED 1")
		quit(1)
		return
	node.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	# 正確時 quit() 已在上一行被呼叫,這一 frame 結束就離開,不會跑到 await 之後
	print("PASSED 1, FAILED 0")
	await process_frame
	await process_frame
	printerr("FAIL back key on bare home did not quit the app")
	print("PASSED 0, FAILED 1")
	quit(1)
