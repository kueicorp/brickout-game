## QA 視窗短測(非 headless):截圖確認道具畫成 40×40(D32 items40,原 32×32);放大視窗時拖曳位移換算。跑完自動關閉。
## 執行:Godot --path game --script res://tests/qa_window_capture.gd -- <輸出資料夾>
extends SceneTree

const MainScene := preload("res://scenes/main.tscn")

var _m
var _frame := 0
var _out := ""
var _base: Image


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else OS.get_user_data_dir()
	_m = MainScene.instantiate()
	root.add_child(_m)


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 2:
		# 40×20 規格:格子 8 欄 × 17 排
		for r in _m.grid.size():
			for c in _m.grid[r].size():
				_m.grid[r][c] = null
		_m.breakable_left = 99
		_m.items.clear()
	if _frame == 10:
		_base = root.get_texture().get_image()
		_m.state = 1  # 暫停遊戲推進,讓道具停在原地(只為截圖)
		# 40×20 規格:磚格 (2, 5) 左上 (100, 168)、中心 (120, 178);道具 pos = 中心 − 8(由 _cell_rect 算,不寫死)
		var center: Vector2 = _m._cell_rect(Vector2i(2, 5)).get_center()
		_m.items = [{"id": "slow", "pos": center - Vector2(8, 8)}]
	if _frame == 14:
		var img := root.get_texture().get_image()
		img.save_png(_out.path_join("qa_item_capture.png"))
		var bb := Rect2i()
		var any := false
		# 40×20 規格:整個磚區 y 52~419 都掃(新格子的道具在 y 162~193,舊範圍 200~420 掃不到)
		for y in range(52, 420):
			for x in range(20, 340):
				if not img.get_pixel(x, y).is_equal_approx(_base.get_pixel(x, y)):
					var p := Rect2i(x, y, 1, 1)
					bb = p if not any else bb.merge(p)
					any = true
		# D32 items40:道具改 40×40 1 倍(原 32×32),以磚中心為中心 → 中心 − 20
		var expect := Rect2i(Vector2i(_m._cell_rect(Vector2i(2, 5)).get_center()) - Vector2i(20, 20), Vector2i(40, 40))
		var inside := any and expect.encloses(bb)
		print("CAPTURE viewport=%s item diff bbox=%s (expected within %s) %s" % [img.get_size(), bb, expect, "OK" if inside else "FAIL"])
		_m.state = 0
		_m.items.clear()
		# 放大視窗:確認拖曳位移換算成遊戲像素
		root.size = Vector2i(720, 1280)
	if _frame == 20:
		print("WINDOW size=%s final_transform=%s" % [root.size, root.get_final_transform()])
		var t0: float = _m.target_x
		var e := InputEventScreenDrag.new()
		e.index = 0
		e.position = Vector2(400, 900)
		e.relative = Vector2(40, 0)
		Input.parse_input_event(e)
		Input.flush_buffered_events()
		print("DRAG window relative 40 -> target_x delta %.2f" % (_m.target_x - t0))
	if _frame == 24:
		return true
	return false
