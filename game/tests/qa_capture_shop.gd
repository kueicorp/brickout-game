extends SceneTree
## QA 截圖與像素比對(非 headless,需要真的繪製):
##   Godot_v4.7.2-stable_win64_console.exe --path game --script res://tests/qa_capture_shop.gd -- <輸出資料夾>
## 1. 綠色按鈕九宮格:各尺寸 normal / pressed / disabled 與「依九宮格規則用 CPU 拼出的預期圖」逐像素比對(驗證沒有縮放)
## 2. 文字墨跡中心 vs 平面中心
## 3. 商城各分頁、提示框在 640 / 800 的截圖
## 不是自動測試(檔名不是 test_*),run_tests.ps1 不會執行。

const HOME_SIM_PATH := "res://tests/home_sim.gd"
const S := preload("res://scripts/shop_service.gd")
const ES := preload("res://scripts/event_service.gd")
const L := preload("res://scripts/shop_logic.gd")
const G := preload("res://scripts/ui/green_button.gd")

const SIZES := [Vector2(216, 56), Vector2(216, 44), Vector2(148, 44), Vector2(128, 44), Vector2(120, 44),
	Vector2(96, 44), Vector2(80, 48), Vector2(72, 44)]

var out_dir := ""
var home
var _sheet: Control


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


func _shot(name: String) -> Image:
	await _frames()
	var img := root.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	img.save_png(out_dir.path_join(name + ".png"))
	print("SHOT %s %dx%d" % [name, img.get_width(), img.get_height()])
	return img


func _run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _button_sheet()
	for h in [640, 800]:
		await _shop_shots(h)
	await _event_shots()
	print("DONE")
	quit(0)


# ---------------- 1. 九宮格 ----------------

func _button_sheet() -> void:
	root.size = Vector2i(680, 530)
	_sheet = Control.new()
	_sheet.size = Vector2(680, 530)
	_sheet.draw.connect(_draw_sheet)
	root.add_child(_sheet)
	var img := await _shot("buttons_sheet")
	var clear := RenderingServer.get_default_clear_color()
	var normal := G.TEX_NORMAL.get_image()
	normal.decompress()
	var disabled := G.TEX_DISABLED.get_image()
	disabled.decompress()
	var pressed := G._clean_pressed().get_image()
	for i in SIZES.size():
		var sz: Vector2 = SIZES[i]
		var y := 8 + i * 64
		_compare(img, normal, Rect2i(G.SRC_NORMAL), Vector2i(4, y), Vector2i(sz), clear, "normal %s" % sz)
		_compare(img, pressed, Rect2i(Vector2i.ZERO, pressed.get_size()), Vector2i(4 + int(sz.x) + 8 + 1, y + 5), Vector2i(int(sz.x), int(sz.y) - 6), clear, "pressed %s" % sz)
		_compare(img, disabled, Rect2i(G.SRC_NORMAL), Vector2i(4 + (int(sz.x) + 8) * 2, y), Vector2i(sz), clear, "disabled %s" % sz)
	# 文字墨跡中心(只看黑字;normal 與 pressed)
	for i in SIZES.size():
		var sz: Vector2 = SIZES[i]
		var y := 8 + i * 64
		_ink(img, Rect2i(4, y, int(sz.x), int(sz.y)), sz, false)
		_ink(img, Rect2i(4 + int(sz.x) + 8, y, int(sz.x), int(sz.y)), sz, true)
	# 放大 4 倍給人看
	var big := img.duplicate()
	big.resize(img.get_width() * 4, img.get_height() * 4, Image.INTERPOLATE_NEAREST)
	big.save_png(out_dir.path_join("buttons_sheet_x4.png"))
	print("SHOT buttons_sheet_x4 %dx%d" % [big.get_width(), big.get_height()])
	# pressed 拼接後的來源圖本身
	var p4 := pressed.duplicate()
	p4.resize(pressed.get_width() * 4, pressed.get_height() * 4, Image.INTERPOLATE_NEAREST)
	p4.save_png(out_dir.path_join("pressed_clean_source_x4.png"))
	print("SHOT pressed_clean_source_x4 %dx%d" % [p4.get_width(), p4.get_height()])
	_sheet.queue_free()
	await _frames()


func _draw_sheet() -> void:
	for i in SIZES.size():
		var sz: Vector2 = SIZES[i]
		var y := 8 + i * 64
		var label := "單買\n30 金塊" if sz == Vector2(80, 48) else "購買"
		var px := 12 if sz == Vector2(80, 48) or sz == Vector2(72, 44) else (18 if sz.y == 56 else 14)
		G.draw_button(_sheet, Rect2(Vector2(4, y), sz), true, false, label, px, Color.BLACK)
		G.draw_button(_sheet, Rect2(Vector2(4 + sz.x + 8, y), sz), true, true, label, px, Color.BLACK)
		G.draw_button(_sheet, Rect2(Vector2(4 + (sz.x + 8) * 2, y), sz), false, false, "", px, Color.WHITE)


## 依 Godot 九宮格 TILE 規則用 CPU 拼出預期像素,和實際畫面比對(只比來源 alpha = 255 的像素)
func _compare(shot: Image, src: Image, sr: Rect2i, pos: Vector2i, sz: Vector2i, _clear: Color, tag: String) -> void:
	var lm := 22
	var tm := 20
	var rm := 12
	var bm := 11
	var cw := sr.size.x - lm - rm
	var ch := sr.size.y - tm - bm
	var bad := 0
	var checked := 0
	var first := ""
	for y in sz.y:
		var sy: int
		if y < tm:
			sy = y
		elif y >= sz.y - bm:
			sy = sr.size.y - (sz.y - y)
		else:
			sy = tm + (y - tm) % ch
		for x in sz.x:
			var sx: int
			if x < lm:
				sx = x
			elif x >= sz.x - rm:
				sx = sr.size.x - (sz.x - x)
			else:
				sx = lm + (x - lm) % cw
			var e := src.get_pixel(sr.position.x + sx, sr.position.y + sy)
			if e.a < 0.999:
				continue
			var px := pos + Vector2i(x, y)
			if px.x >= shot.get_width() or px.y >= shot.get_height():
				continue
			var a := shot.get_pixelv(px)
			checked += 1
			if absf(a.r - e.r) > 0.02 or absf(a.g - e.g) > 0.02 or absf(a.b - e.b) > 0.02:
				# 文字像素會不同:黑字 / 白字略過(亮度極低或極高)
				var lum := a.r + a.g + a.b
				if lum < 0.5 or lum > 2.7:
					continue
				bad += 1
				if first == "":
					first = "(%d,%d) exp %s got %s" % [x, y, e.to_html(false), a.to_html(false)]
	print("NINE %-22s checked %5d mismatched %4d %s" % [tag, checked, bad, first])


func _ink(shot: Image, r: Rect2i, sz: Vector2, pressed: bool) -> void:
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
	var plane_center := r.position.y + (sz.y - 11) / 2.0 + (5 if pressed else 0)
	var ink_center := (miny + maxy + 1) / 2.0
	var hc := r.position.x + sz.x / 2.0 + (1 if pressed else 0)
	print("INK %-12s %s ink y %d..%d center %.1f plane center %.1f dy %.1f | ink x center %.1f btn center %.1f" % [
		str(sz), "pressed" if pressed else "normal ", miny - r.position.y, maxy - r.position.y, ink_center - r.position.y,
		plane_center - r.position.y, ink_center - plane_center, (minx + maxx + 1) / 2.0 - r.position.x, hc - r.position.x])


func _event_shots() -> void:
	ES.reset()
	ES.delay_sec = 0.02
	ES.signed_count = 14
	await _make_home(640)
	await _wait()
	await _close_popups()
	home._open_event()
	await _wait()
	home._event.show_page(EventLogic.Page.CHECKIN)
	await _wait()
	await _shot("event_640_checkin")
	var b = home._event._checkin._checkin
	_press(b.get_global_rect().get_center(), true)
	await _shot("event_640_checkin_held")
	_press(Vector2(350, 5), false)
	await _frames()
	home._event.show_page(EventLogic.Page.TOPUP)
	await _wait()
	await _shot("event_640_topup")
	home._popup.enqueue(EventLogic.popup_checkin(ES.wallet.duplicate()))
	await _shot("event_640_popup")
	home._popup.close_current()


func _close_popups() -> void:
	while home._popup.is_open():
		home._popup.close_current()
		await _frames()


# ---------------- 2. 商城截圖 ----------------

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


func _shop_shots(h: int) -> void:
	ES.reset()
	ES.delay_sec = 0.02
	S.reset()
	S.delay_sec = 0.02
	FakeData.ads_removed = false
	await _make_home(h)
	await _wait()
	await _shot("home_%d" % h)
	home._open_shop(L.Tab.TOPUP)
	await _frames()
	await _shot("shop_%d_loading" % h)
	await _wait()
	var shop = home._shop
	await _shot("shop_%d_topup" % h)
	# 按住金塊卡 90
	var page = shop._page
	_press(page.global_position + Vector2(250, 50), true)
	await _shot("shop_%d_topup_card_held" % h)
	_press(Vector2(350, 5), false)  # 移出再放開,不觸發
	await _frames()
	shop.select_tab(L.Tab.ITEMS)
	await _shot("shop_%d_items" % h)
	_press(page.global_position + Vector2(196, 88 + 32), true)
	await _shot("shop_%d_items_single_held" % h)
	_press(Vector2(350, 5), false)
	await _frames()
	page.scroll = L.max_scroll(L.Tab.ITEMS, page.extra)
	page.queue_redraw()
	await _shot("shop_%d_items_bottom" % h)
	ES.wallet.heart = 92
	shop._fetch()
	await _wait()
	shop.select_tab(L.Tab.HEART_COIN)
	await _shot("shop_%d_heartcoin_92" % h)
	ES.wallet.heart = 99
	shop._fetch()
	await _wait()
	await _shot("shop_%d_heartcoin_99" % h)
	ES.wallet.heart = 10
	S.free_left.assign([20, 0, 5, 1])
	shop._fetch()
	await _wait()
	shop.select_tab(L.Tab.FREE)
	await _shot("shop_%d_free" % h)
	# 對話框
	ES.wallet.silver = 10
	ES.wallet.gold = 1000
	shop._fetch()
	await _wait()
	shop._start_gold_buy("bundle")
	await _shot("shop_%d_dialog_confirm2" % h)
	shop._dialog.set_busy(true)
	await _shot("shop_%d_dialog_confirm_busy" % h)
	shop._dialog.close()
	ES.wallet.gold = 100
	shop._fetch()
	await _wait()
	shop._start_gold_buy("bundle")
	await _shot("shop_%d_dialog_short" % h)
	shop._dialog.close()
	shop._dialog.open_detail(3)
	await _shot("shop_%d_dialog_detail_assassin" % h)
	shop._dialog.open_detail(5)
	await _shot("shop_%d_dialog_detail_weaken" % h)
	shop._dialog.open_processing()
	await _shot("shop_%d_dialog_processing" % h)
	shop._dialog.close()
	home._popup.enqueue(L.popup_unpaid(false, ES.wallet.duplicate()))
	await _shot("shop_%d_popup_unpaid" % h)
	home._popup.close_current()
	home._popup.enqueue(L.popup_heart_cap(92, 10, ES.wallet.duplicate()))
	await _shot("shop_%d_popup_heartcap" % h)
	home._popup.close_current()
	# 讀取失敗
	S.fail_next = 1
	shop._fetch()
	await _wait()
	await _shot("shop_%d_failed" % h)
	home._close_shop()
	await _frames()
