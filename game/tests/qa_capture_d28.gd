extends SceneTree
## QA D28 截圖與量測(非 headless,需要真的繪製):
##   Godot_v4.7.2-stable_win64_console.exe --path game --script res://tests/qa_capture_d28.gd -- <輸出資料夾>
## 對 10 個道具開 D27 詳情框,截全畫面 + 框放大 4 倍;量:框高(邊框色像素)、每行白字墨跡最右 x(框內)。
## 不是自動測試(檔名不是 test_*),run_tests.ps1 不會執行。

const HOME_SIM_PATH := "res://tests/home_sim.gd"
const S := preload("res://scripts/shop_service.gd")
const ES := preload("res://scripts/event_service.gd")
const L := preload("res://scripts/shop_logic.gd")
const NAMES := ["extra_hp", "extra_life", "swap", "assassin", "coating", "weaken", "typhoon", "armor_break", "greed", "skill_pack"]

var out_dir := ""
var home


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else OS.get_user_data_dir()
	_run.call_deferred()


func _frames(n := 3) -> void:
	for i in n:
		await process_frame
	await RenderingServer.frame_post_draw


func _wait(sec := 0.15) -> void:
	await create_timer(sec).timeout


func _make_home(h: int) -> void:
	if home:
		home.queue_free()
		await _frames()
	root.size = Vector2i(360, h)
	await _frames()
	var node: Control = load("res://scenes/home.tscn").instantiate()
	node.set_script(load(HOME_SIM_PATH))
	node.sim_view = Vector2(360, h)
	node.sim_safe = Vector2i(24, 16)
	root.add_child(node)
	home = node
	await _frames()


func _run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var bad := 0
	for h in [800, 640]:
		ES.reset()
		ES.delay_sec = 0.02
		S.reset()
		S.delay_sec = 0.02
		await _make_home(h)
		await _wait()
		while home._popup.is_open():
			home._popup.close_current()
			await _frames()
		home._open_shop(L.Tab.ITEMS)
		await _wait()
		var shop = home._shop
		shop.select_tab(L.Tab.ITEMS)
		await _frames()
		for item in 10:
			shop._dialog.open_detail(item)
			await _frames()
			var img := root.get_texture().get_image()
			img.convert(Image.FORMAT_RGBA8)
			var name := "d28_%d_%02d_%s" % [h, item + 1, NAMES[item]]
			img.save_png(out_dir.path_join(name + ".png"))
			var fr: Rect2 = shop._dialog.frame_rect()
			var go: Vector2 = shop._dialog.global_position
			var fx := int(go.x + fr.position.x)
			var fy := int(go.y + fr.position.y)
			# 量邊框:x = fx 那一欄,往下找 #5D6D7E 連續段
			var border := Color("#5D6D7E")
			var top := -1
			var bottom := -1
			for y in img.get_height():
				var c := img.get_pixel(fx + 100, y)
				if absf(c.r - border.r) < 0.02 and absf(c.g - border.g) < 0.02 and absf(c.b - border.b) < 0.02:
					if top < 0:
						top = y
					bottom = y
			var measured_h := bottom - top + 1
			var lines: Array = L.ITEM_LINES[item]
			var n := lines.size()
			var exp_h := 174 + 22 * n
			var msg := "ITEM %d %s n=%d frame logic h=%d measured border span y %d..%d (h=%d) expect %d" % [
				item + 1, NAMES[item], n, int(fr.size.y), top, bottom, measured_h, exp_h]
			if int(fr.size.y) != exp_h or measured_h != exp_h:
				msg += "  <-- HEIGHT MISMATCH"
				bad += 1
			print(msg)
			for i in n:
				var base := fy + 92 + 22 * i
				var maxx := -1
				var minx := 99999
				for y in range(base - 17, base + 6):
					for x in range(fx + 1, fx + 295):
						var c := img.get_pixel(x, y)
						if c.r + c.g + c.b > 2.4:
							maxx = maxi(maxx, x)
							minx = mini(minx, x)
				var right := maxx - fx  # 框內 x
				var w := PixelText.FONT.get_string_size(lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
				var line_msg := "  line %d [%s] font width %d  ink x %d..%d (frame-local) ink width %d" % [
					i + 1, lines[i], w, minx - fx, right, maxx - minx + 1]
				if w > 252 or right > 16 + 252:
					line_msg += "  <-- OVER 252"
					bad += 1
				print(line_msg)
			# 框放大 4 倍
			var crop := img.get_region(Rect2i(fx - 4, fy - 4, 304, exp_h + 8))
			crop.resize(crop.get_width() * 4, crop.get_height() * 4, Image.INTERPOLATE_NEAREST)
			crop.save_png(out_dir.path_join(name + "_frame_x4.png"))
			print("SHOT %s %dx%d ; %s_frame_x4 %dx%d" % [name, img.get_width(), img.get_height(), name, crop.get_width(), crop.get_height()])
			shop._dialog.close()
			await _frames()
	print("BAD %d" % bad)
	print("DONE")
	quit(0)
