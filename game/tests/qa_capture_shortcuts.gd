extends SceneTree
## QA 截圖與像素檢查:頁面捷徑列(page-shortcuts P02、P06、P07)。非 headless,需要真的繪製:
##   Godot_v4.7.2-stable_win64_console.exe --path game --script res://tests/qa_capture_shortcuts.gd -- <輸出資料夾>
## 不是自動測試(檔名不是 test_*),run_tests.ps1 不會執行。結果印 "CHECK ok|FAIL ..."。

const HOME_SIM_PATH := "res://tests/home_sim.gd"
const S := preload("res://scripts/shop_service.gd")
const ES := preload("res://scripts/event_service.gd")
const GOLD := Color8(0xF4, 0xC4, 0x30)
const RED := Color8(0xE7, 0x4C, 0x3C)

var out_dir := ""
var home
var _ok := 0
var _bad := 0


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


func _crop_x4(img: Image, r: Rect2i, name: String) -> void:
	var c := img.get_region(r)
	c.resize(r.size.x * 4, r.size.y * 4, Image.INTERPOLATE_NEAREST)
	c.save_png(out_dir.path_join(name + ".png"))
	print("SHOT %s %dx%d (x4 of %dx%d)" % [name, c.get_width(), c.get_height(), r.size.x, r.size.y])


func _check(cond: bool, label: String, detail := "") -> void:
	if cond:
		_ok += 1
		print("CHECK ok   %s %s" % [label, detail])
	else:
		_bad += 1
		print("CHECK FAIL %s %s" % [label, detail])


func _near(a: Color, b: Color, tol := 3) -> bool:
	return absi(a.r8 - b.r8) <= tol and absi(a.g8 - b.g8) <= tol and absi(a.b8 - b.b8) <= tol


func _px(img: Image, p: Vector2) -> Color:
	return img.get_pixelv(Vector2i(p))


func _c(c: Color) -> String:
	return "(%d,%d,%d)" % [c.r8, c.g8, c.b8]


## 預期合成色:底色 bg 上蓋 color(alpha a)
func _over(bg: Color, color: Color, a: float) -> Color:
	return Color(lerpf(bg.r, color.r, a), lerpf(bg.g, color.g, a), lerpf(bg.b, color.b, a))


func _make_home(h: int, t: int) -> void:
	if home:
		home.queue_free()
		await _frames()
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(360, h)
	await _frames()
	var node: Control = load("res://scenes/home.tscn").instantiate()
	node.set_script(load(HOME_SIM_PATH))
	node.sim_view = Vector2(360, h)
	node.sim_safe = Vector2i(t, 16)
	root.add_child(node)
	home = node
	await _frames()
	await _wait()
	while home._popup.is_open():
		home._popup.close_current()
		await _frames()


func _reset() -> void:
	ES.reset()
	ES.delay_sec = 0.05
	S.reset()
	S.delay_sec = 0.05
	FakeData.ads_removed = false


func _run() -> void:
	_reset()
	await _pixel_checks()
	for c in [[640, 24], [800, 24], [640, 40], [800, 40]]:
		await _layout_shots(c[0], c[1])
	if home:
		home.queue_free()
		await _frames()
	_reset()
	print("CHECKS ok %d, FAIL %d" % [_ok, _bad])
	print("DONE")
	quit(0)


## 640 T24:活動頁 A,逐像素檢查底板、金框、紅點、文字、按下、停用、焦點
func _pixel_checks() -> void:
	await _make_home(640, 24)
	home._open_event()
	await _wait()
	var ev = home._event
	var bar: PageShortcutBar = ev.shortcuts
	var img := await _shot("sc_event_A_640")
	# 背景(捷徑列藏起來)
	bar.visible = false
	var bg := await _shot("sc_event_A_640_nobar")
	bar.visible = true
	var ev_r := Rect2i(bar.keys[0].get_global_rect())
	var sh_r := Rect2i(bar.keys[1].get_global_rect())
	var bk_r := Rect2i(bar.back.get_global_rect())
	_check(ev_r == Rect2i(60, 80, 70, 44) and sh_r == Rect2i(134, 80, 70, 44) and bk_r == Rect2i(8, 80, 44, 44), "rects 640", "%s %s %s" % [ev_r, sh_r, bk_r])
	var a := 160.0 / 255.0
	# 底板:商城捷徑 (10,40)、返回鈕 (4,4)
	for p in [Vector2(sh_r.position) + Vector2(10, 40), Vector2(bk_r.position) + Vector2(4, 4), Vector2(bk_r.position) + Vector2(40, 22)]:
		var exp := _over(_px(bg, p), Color.BLACK, a)
		_check(_near(_px(img, p), exp), "plate a160 at %s" % p, "got %s exp %s" % [_c(_px(img, p)), _c(exp)])
	# 圓角:四角 (0,0) 是背景
	for r in [ev_r, sh_r, bk_r]:
		for p in [Vector2(r.position), Vector2(r.end.x - 1, r.position.y), Vector2(r.position.x, r.end.y - 1)]:
			_check(_near(_px(img, p), _px(bg, p), 1), "rounded corner %s = bg" % p, _c(_px(img, p)))
	# 金框:目前頁「活動」內側 2px
	var o := Vector2(ev_r.position)
	_check(_near(_px(img, o + Vector2(0, 22)), GOLD, 2) and _near(_px(img, o + Vector2(1, 22)), GOLD, 2), "gold frame left 2px", _c(_px(img, o + Vector2(0, 22))))
	_check(not _near(_px(img, o + Vector2(2, 22)), GOLD, 30), "gold frame only 2px (x=2 not gold)", _c(_px(img, o + Vector2(2, 22))))
	_check(_near(_px(img, o + Vector2(35, 0)), GOLD, 2) and _near(_px(img, o + Vector2(35, 43)), GOLD, 2), "gold frame top/bottom", "")
	_check(_near(_px(img, o + Vector2(69, 22)), GOLD, 2), "gold frame right", "")
	_check(not _near(_px(img, Vector2(sh_r.position) + Vector2(0, 22)), GOLD, 30), "商城 no gold frame on event page", "")
	# 紅點:商城捷徑內 (56,2) 12×12
	var bo := Vector2(sh_r.position) + Vector2(56, 2)
	_check(bar.keys[1].badge, "event page: 商城 badge on (default free left)", "")
	_check(_near(_px(img, bo + Vector2(0, 5)), Color.WHITE, 2), "badge white edge at local (56,7)", _c(_px(img, bo + Vector2(0, 5))))
	_check(_near(_px(img, bo + Vector2(5, 5)), RED, 2), "badge red at local (61,7)", _c(_px(img, bo + Vector2(5, 5))))
	_check(_near(_px(img, bo + Vector2(4, 0)), Color.WHITE, 2) and not _near(_px(img, bo + Vector2(3, 0)), Color.WHITE, 30), "badge top row inset 4", "")
	_check(not _near(_px(img, bo + Vector2(-1, 5)), Color.WHITE, 30) and not _near(_px(img, bo + Vector2(12, 5)), Color.WHITE, 30), "badge 12 wide (x 56~67)", "")
	# 文字墨跡(白色)範圍
	for i in 4:
		var r := Rect2i(bar.keys[i].get_global_rect())
		var ink := _ink_rect(img, Rect2i(r.position + Vector2i(3, 3), Vector2i(50, 38)))
		var local := Rect2i(ink.position - r.position, ink.size)
		_check(local.position.x >= 19 and local.end.x <= 51 and local.position.y >= 13 and local.end.y <= 31 and absf(local.get_center().x - 35) <= 1.5 and absf(local.get_center().y - 22) <= 1.5,
			"key %d text ink centered (spec x21~49 y15~29)" % i, "local ink %s center %s" % [local, local.get_center()])
	# 返回鈕箭頭:白色墨跡置中、向左(左半較尖:最左白點所在列只有少數像素)
	var bink := _ink_rect(img, bk_r.grow(-2))
	_check(absf(bink.get_center().x - bk_r.get_center().x) <= 2 and absf(bink.get_center().y - bk_r.get_center().y) <= 2, "back arrow centered", "ink %s" % bink)
	_crop_x4(img, Rect2i(0, 76, 360, 52), "sc_event_bar_640_x4")

	# 按下(商城捷徑):按住不放開
	var press_at := Vector2(sh_r.get_center())
	_mouse(press_at, false)
	_button(press_at, true)
	var held := await _shot("sc_event_A_640_hold_shop")
	_check(bar.keys[1].is_held(), "商城 held", "")
	var tmax := _max_white(held, Rect2i(sh_r.position + Vector2i(15, 10), Vector2i(40, 24)))
	_check(absi(tmax - 153) <= 3, "held text darkened 40% (white*0.6=153)", "max %d" % tmax)
	_check(_near(_px(held, bo + Vector2(5, 5)), Color(RED.r * 0.6, RED.g * 0.6, RED.b * 0.6), 2), "held badge darkened 40%", _c(_px(held, bo + Vector2(5, 5))))
	_check(Rect2i(bar.keys[1].get_global_rect()) == sh_r, "held: position unchanged", "")
	_crop_x4(held, Rect2i(0, 76, 360, 52), "sc_event_bar_hold_shop_x4")
	# 拖出放開:不觸發
	_mouse(Vector2(180, 400), true)
	_button(Vector2(180, 400), false)
	await _frames()
	_check(home._event == ev, "drag out release: no switch", "")

	# 鍵盤焦點:2px 白框在外側
	bar.keys[2].grab_focus()
	var foc := await _shot("sc_event_A_640_focus_growth")
	var g := Vector2(bar.keys[2].get_global_rect().position)
	_check(_near(_px(foc, g + Vector2(-1, 22)), Color.WHITE, 2) and _near(_px(foc, g + Vector2(-2, 22)), Color.WHITE, 2), "focus white 2px outside", "")
	_check(not _near(_px(foc, g + Vector2(-3, 22)), Color.WHITE, 30), "focus frame only 2px", _c(_px(foc, g + Vector2(-3, 22))))
	_crop_x4(foc, Rect2i(0, 76, 360, 52), "sc_event_bar_focus_growth_x4")
	bar.keys[2].release_focus()

	# 停用:簽到處理中
	ES.delay_sec = 3.0
	ev.show_page(EventLogic.Page.CHECKIN)
	await _frames()
	var b_img := await _shot("sc_event_B_640")
	ev._on_checkin_pressed()
	var dis := await _shot("sc_event_B_640_busy_disabled")
	_check(bar.back.disabled and bar.keys[1].disabled, "busy: disabled", "")
	var p2 := Vector2(sh_r.position) + Vector2(10, 40)
	var exp2 := _over(_px(bg, p2), Color.BLACK, a * 0.5)
	_check(_near(_px(dis, p2), exp2, 3), "disabled plate alpha 50% (80/255)", "got %s exp %s" % [_c(_px(dis, p2)), _c(exp2)])
	# 金框畫在(同樣 50% 的)底板上
	var expg := _over(_over(_px(bg, o + Vector2(0, 22)), Color.BLACK, a * 0.5), GOLD, 0.5)
	_check(_near(_px(dis, o + Vector2(0, 22)), expg, 3), "disabled gold frame 50%", "got %s exp %s" % [_c(_px(dis, o + Vector2(0, 22))), _c(expg)])
	_crop_x4(dis, Rect2i(0, 76, 360, 52), "sc_event_bar_disabled_x4")
	_crop_x4(b_img, Rect2i(0, 76, 360, 52), "sc_event_B_bar_x4")
	ES.delay_sec = 0.05
	await _wait(3.2)
	while home._popup.is_open():
		home._popup.close_current()
		await _frames()
	ev.show_page(EventLogic.Page.LIST)
	home._close_event()
	await _wait()

	# 商城:目前頁金框在商城、紅點在活動
	home._open_shop(0)
	await _wait()
	var shop = home._shop
	var simg := await _shot("sc_shop_640")
	var sb: PageShortcutBar = shop.shortcuts
	var er := Rect2i(sb.keys[0].get_global_rect())
	var sr := Rect2i(sb.keys[1].get_global_rect())
	_check(_near(_px(simg, Vector2(sr.position) + Vector2(0, 22)), GOLD, 2), "shop: 商城 gold frame", "")
	_check(not _near(_px(simg, Vector2(er.position) + Vector2(0, 22)), GOLD, 30), "shop: 活動 no frame", "")
	_check(sb.keys[0].badge and _near(_px(simg, Vector2(er.position) + Vector2(61, 7)), RED, 2), "shop: 活動 badge at (56,2)", _c(_px(simg, Vector2(er.position) + Vector2(61, 7))))
	_check(not sb.keys[1].badge, "shop: 商城 no badge", "")
	_crop_x4(simg, Rect2i(0, 76, 360, 52), "sc_shop_bar_640_x4")
	# 看廣告載入中
	S.delay_sec = 3.0
	shop.select_tab(ShopLogic.Tab.FREE)
	shop._watch_ad(0)
	var sdis := await _shot("sc_shop_640_ad_loading_disabled")
	_crop_x4(sdis, Rect2i(0, 76, 360, 52), "sc_shop_bar_ad_loading_x4")
	S.delay_sec = 0.05
	await _wait(3.2)
	while home._popup.is_open():
		home._popup.close_current()
		await _frames()
	home._close_shop()
	await _wait()


func _mouse(pos: Vector2, down: bool) -> void:
	var m := InputEventMouseMotion.new()
	m.position = pos
	m.global_position = pos
	m.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	root.push_input(m, true)


func _button(pos: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = pos
	e.global_position = pos
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	root.push_input(e, true)


## 近白像素(三通道 > 200)的範圍
func _ink_rect(img: Image, r: Rect2i) -> Rect2i:
	var mn := Vector2i(99999, 99999)
	var mx := Vector2i(-1, -1)
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var c := img.get_pixel(x, y)
			if c.r8 > 200 and c.g8 > 200 and c.b8 > 200:
				mn = Vector2i(mini(mn.x, x), mini(mn.y, y))
				mx = Vector2i(maxi(mx.x, x), maxi(mx.y, y))
	if mx.x < 0:
		return Rect2i()
	return Rect2i(mn, mx - mn + Vector2i.ONE)


## 區域內最亮的灰白像素(三通道相近)
func _max_white(img: Image, r: Rect2i) -> int:
	var best := 0
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var c := img.get_pixel(x, y)
			if absi(c.r8 - c.g8) <= 4 and absi(c.g8 - c.b8) <= 4:
				best = maxi(best, c.r8)
	return best


func _layout_shots(h: int, t: int) -> void:
	_reset()
	await _make_home(h, t)
	home._open_event()
	await _wait()
	await _shot("sc_event_A_%d_T%d" % [h, t])
	home._event.show_page(EventLogic.Page.TOPUP)
	await _shot("sc_event_C_%d_T%d" % [h, t])
	home._event.show_page(EventLogic.Page.LIST)
	home._close_event()
	await _wait()
	home._open_shop(0)
	await _wait()
	await _shot("sc_shop_%d_T%d" % [h, t])
	home._close_shop()
	await _wait()
