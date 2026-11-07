extends SceneTree
## QA 截圖與像素比對(非 headless):活動頁 D14 重試鈕(GreenButton)vs 商城重試鈕。
##   Godot_v4.7.2-stable_win64_console.exe --path game --script res://tests/qa_capture_event_retry.gd -- <輸出資料夾>
## 1. B / C × 640 / 800 讀取失敗截圖(一般 + 按住)
## 2. 活動頁重試鈕 vs 依九宮格規則拼出的預期圖(只比圖案不透明像素,跳過文字)
## 3. 活動頁重試鈕 vs 商城重試鈕逐像素(同遮罩,含文字)
## 4. 文字墨跡中心 vs 平面中心
## 不是自動測試(檔名不是 test_*),run_tests.ps1 不會執行。

const HOME_SIM_PATH := "res://tests/home_sim.gd"
const ES := preload("res://scripts/event_service.gd")
const SS := preload("res://scripts/shop_service.gd")
const G := preload("res://scripts/ui/green_button.gd")

var out_dir := ""
var home
var _normal: Image
var _pressed: Image


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


func _grab() -> Image:
	await _frames()
	var img := root.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	return img


func _shot(name: String) -> Image:
	var img := await _grab()
	img.save_png(out_dir.path_join(name + ".png"))
	print("SHOT %s %dx%d" % [name, img.get_width(), img.get_height()])
	return img


func _press(pos: Vector2, down: bool) -> void:
	var m := InputEventMouseMotion.new()
	m.position = pos
	m.global_position = pos
	root.push_input(m, true)
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = down
	e.position = pos
	e.global_position = pos
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	root.push_input(e, true)


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


func _close_popups() -> void:
	while home._popup.is_open():
		home._popup.close_current()
		await _frames()


func _run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	_normal = G.TEX_NORMAL.get_image()
	if _normal.is_compressed():
		_normal.decompress()
	_pressed = G._clean_pressed().get_image()
	var shop_imgs := await _shop_retry()
	for h in [640, 800]:
		await _event_shots(h, shop_imgs)
	print("DONE")
	quit(0)


## 商城重試鈕(640)一般 / 按住的 120×44 截取
func _shop_retry() -> Array:
	ES.reset()
	ES.delay_sec = 0.02
	SS.reset()
	SS.delay_sec = 0.02
	await _make_home(640)
	await _wait()
	await _close_popups()
	SS.fail_next = 1
	home._open_shop(0)
	await _wait()
	var r: Rect2i = Rect2i(home._shop._retry.get_global_rect())
	var n := await _shot("qa_shop_640_failed")
	_press(Vector2(r.get_center()), true)
	var p := await _shot("qa_shop_640_failed_retry_held")
	_press(Vector2(350, 5), false)
	await _frames()
	print("SHOP retry rect %s" % r)
	home._close_shop()
	await _frames()
	return [n.get_region(r), p.get_region(r)]


func _event_shots(h: int, shop_imgs: Array) -> void:
	ES.reset()
	ES.delay_sec = 0.02
	await _make_home(h)
	await _wait()
	await _close_popups()
	ES.fail_next = 1
	home._open_event()
	await _wait()
	var ev = home._event
	for pg in [EventLogic.Page.CHECKIN, EventLogic.Page.TOPUP]:
		ev.show_page(pg)
		var name := "qa_event_%d_%s_failed" % [h, "B" if pg == EventLogic.Page.CHECKIN else "C"]
		var r: Rect2i = Rect2i(ev._retry.get_global_rect())
		print("EVENT %s retry rect %s" % [name, r])
		var n := await _shot(name)
		_press(Vector2(r.get_center()), true)
		var p := await _shot(name + "_retry_held")
		_press(Vector2(350, 5), false)
		await _frames()
		_compare(n, _normal, Rect2i(G.SRC_NORMAL), r.position, r.size, "%s normal vs ninepatch" % name)
		_compare(p, _pressed, Rect2i(Vector2i.ZERO, _pressed.get_size()), r.position + Vector2i(1, 5), r.size - Vector2i(0, 6),
			"%s pressed vs ninepatch" % name)
		_vs_shop(n.get_region(r), shop_imgs[0], _normal, Rect2i(G.SRC_NORMAL), Vector2i.ZERO, r.size, "%s normal vs shop" % name)
		_vs_shop(p.get_region(r), shop_imgs[1], _pressed, Rect2i(Vector2i.ZERO, _pressed.get_size()), Vector2i(1, 5),
			r.size - Vector2i(0, 6), "%s pressed vs shop" % name)
		_ink(n, r, false, name)
		_ink(p, r, true, name)
		# 放大 4 倍的按鈕區域給人看
		var big := n.get_region(r.grow(8))
		big.resize(big.get_width() * 4, big.get_height() * 4, Image.INTERPOLATE_NEAREST)
		big.save_png(out_dir.path_join(name + "_retry_x4.png"))
		var bigp := p.get_region(r.grow(8))
		bigp.resize(bigp.get_width() * 4, bigp.get_height() * 4, Image.INTERPOLATE_NEAREST)
		bigp.save_png(out_dir.path_join(name + "_retry_held_x4.png"))
		print("SHOT %s_retry_x4 %dx%d" % [name, big.get_width(), big.get_height()])
	home._close_event()
	await _frames()


## 九宮格 TILE 規則下,按鈕內座標 (x, y) 對應的來源像素
func _src_px(src: Image, sr: Rect2i, sz: Vector2i, x: int, y: int) -> Color:
	var lm := 22
	var tm := 20
	var rm := 12
	var bm := 11
	var cw := sr.size.x - lm - rm
	var ch := sr.size.y - tm - bm
	var sy: int = y if y < tm else (sr.size.y - (sz.y - y) if y >= sz.y - bm else tm + (y - tm) % ch)
	var sx: int = x if x < lm else (sr.size.x - (sz.x - x) if x >= sz.x - rm else lm + (x - lm) % cw)
	return src.get_pixel(sr.position.x + sx, sr.position.y + sy)


func _compare(shot: Image, src: Image, sr: Rect2i, pos: Vector2i, sz: Vector2i, tag: String) -> void:
	var bad := 0
	var checked := 0
	var first := ""
	for y in sz.y:
		for x in sz.x:
			var e := _src_px(src, sr, sz, x, y)
			if e.a < 0.999:
				continue
			var a := shot.get_pixelv(pos + Vector2i(x, y))
			checked += 1
			if absf(a.r - e.r) > 0.02 or absf(a.g - e.g) > 0.02 or absf(a.b - e.b) > 0.02:
				var lum := a.r + a.g + a.b
				if lum < 0.5 or lum > 2.7:
					continue
				bad += 1
				if first == "":
					first = "(%d,%d) exp %s got %s" % [x, y, e.to_html(false), a.to_html(false)]
	print("NINE %-50s checked %5d mismatched %4d %s" % [tag, checked, bad, first])


## 兩張 120×44 截取逐像素比對(只看圖案不透明處,含文字)
func _vs_shop(ev: Image, shop: Image, src: Image, sr: Rect2i, off: Vector2i, sz: Vector2i, tag: String) -> void:
	var bad := 0
	var checked := 0
	var first := ""
	for y in sz.y:
		for x in sz.x:
			if _src_px(src, sr, sz, x, y).a < 0.999:
				continue
			var p := off + Vector2i(x, y)
			# 按下圖往右 1px,最右一欄超出 120×44 截取範圍,略過
			if p.x >= ev.get_width() or p.y >= ev.get_height():
				continue
			var a := ev.get_pixelv(p)
			var b := shop.get_pixelv(p)
			checked += 1
			if not a.is_equal_approx(b):
				bad += 1
				if first == "":
					first = "(%d,%d) event %s shop %s" % [p.x, p.y, a.to_html(false), b.to_html(false)]
	print("SAME %-50s checked %5d mismatched %4d %s" % [tag, checked, bad, first])


func _ink(shot: Image, r: Rect2i, pressed: bool, name: String) -> void:
	var miny := 9999
	var maxy := -1
	var minx := 9999
	var maxx := -1
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var c := shot.get_pixel(x, y)
			if c.r + c.g + c.b < 0.25:
				miny = mini(miny, y)
				maxy = maxi(maxy, y)
				minx = mini(minx, x)
				maxx = maxi(maxx, x)
	var plane_center := (r.size.y - 11) / 2.0 + (5 if pressed else 0)
	var ink_center := (miny + maxy + 1) / 2.0 - r.position.y
	var hc := r.size.x / 2.0 + (1 if pressed else 0)
	print("INK %-34s %s ink y %d..%d center %.1f plane %.1f dy %.1f | ink x center %.1f btn %.1f" % [
		name, "pressed" if pressed else "normal ", miny - r.position.y, maxy - r.position.y, ink_center,
		plane_center, ink_center - plane_center, (minx + maxx + 1) / 2.0 - r.position.x, hc])
