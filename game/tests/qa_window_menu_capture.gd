## QA 視窗短測(非 headless):D29 修訂 — 3 選 1 選單的 40×40 圖示與 48×48 閃光(1 倍)。
## - 金球/黑球、H = 800 / 640:標題圖示與 3 個選項圖示逐像素對照原圖(1 倍),其餘畫面不多畫
## - 呼吸:F1/F2 各 400 ms 共用時鐘(對照繪圖當下 ticks);減少動態固定 F1
## - 閃光 F1~F3:用真實滑鼠事件選取後,逐幀對照原圖與位置(中心 = 圖示中心);實際時間序列
## - 實機字型量測名稱/說明 ≤ 216、標題/副標 ≤ 232
## - 截圖存到輸出資料夾
## 執行:Godot --path game --script res://tests/qa_window_menu_capture.gd -- <輸出資料夾>
## 跑完自動關閉;全部吻合時結束碼 0。
extends SceneTree

const MainScene := preload("res://scenes/main.tscn")


class TickProbe:
	extends Node2D
	var last_ms := -1
	func _process(_d: float) -> void:
		queue_redraw()
	func _draw() -> void:
		last_ms = Time.get_ticks_msec()


var _out := ""
var _pass := 0
var _fail := 0
var _blank: ImageTexture


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else OS.get_user_data_dir()
	_blank = ImageTexture.create_from_image(Image.create(40, 40, false, Image.FORMAT_RGBA8))
	_main()


func _report(label: String, ok: bool, detail := "") -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("%s %-64s %s" % ["OK  " if ok else "FAIL", label, detail])


func _wait(n := 2) -> void:
	for i in n:
		await RenderingServer.frame_post_draw


func _shot() -> Image:
	var i := root.get_texture().get_image()
	i.convert(Image.FORMAT_RGBA8)
	return i


func _src(path: String) -> Image:
	var i: Image = (load(path) as Texture2D).get_image()
	if i.is_compressed():
		i.decompress()
	i.convert(Image.FORMAT_RGBA8)
	return i


## src 以 1 倍畫在 dest、底圖 base:不透明須完全相同;透明 = 底;半透明依底混色。回傳 [bad, opaque, partial, first]
func _cmp(shot: Image, base: Image, src: Image, dest: Vector2i) -> Array:
	var bad := 0
	var opaque := 0
	var partial := 0
	var first := ""
	for y in src.get_height():
		for x in src.get_width():
			var p := dest + Vector2i(x, y)
			var c := src.get_pixel(x, y)
			var bg := base.get_pixelv(p)
			var want := c
			if c.a == 0.0:
				want = bg
			elif c.a < 0.999:
				partial += 1
				want = bg.lerp(Color(c.r, c.g, c.b, 1.0), c.a)
			else:
				opaque += 1
			var g := shot.get_pixelv(p)
			var tol := 0.004 if c.a >= 0.999 or c.a == 0.0 else 0.008
			if absf(g.r - want.r) > tol or absf(g.g - want.g) > tol or absf(g.b - want.b) > tol:
				bad += 1
				if first == "":
					first = "%s want %s got %s (a %.2f)" % [p, want.to_html(false), g.to_html(false), c.a]
	return [bad, opaque, partial, first]


func _outside_diff(shot: Image, base: Image, rects: Array) -> Array:
	var bad := 0
	var first := ""
	for y in shot.get_height():
		for x in shot.get_width():
			var inside := false
			for r in rects:
				if (r as Rect2i).has_point(Vector2i(x, y)):
					inside = true
					break
			if inside:
				continue
			if not shot.get_pixel(x, y).is_equal_approx(base.get_pixel(x, y)):
				bad += 1
				if first == "":
					first = "(%d, %d)" % [x, y]
	return [bad, first]


func _title_icon(m: ChoiceMenu) -> TextureRect:
	for c in m._panel.get_children():
		if c is TextureRect:
			return c
	return null


func _icon_dest(m: ChoiceMenu, k: int) -> Vector2i:
	return Vector2i(m._options[k].global_position + ChoiceOption.ICON_RECT.position)


func _set_blank(m: ChoiceMenu, on: bool, saved: Array) -> void:
	var ti := _title_icon(m)
	if on:
		saved.clear()
		saved.append(ti.texture)
		ti.texture = _blank
		for o in m._options:
			saved.append(o._icons.duplicate())
			o._icons = [_blank, _blank]
	else:
		ti.texture = saved[0]
		for k in m._options.size():
			m._options[k]._icons.assign(saved[k + 1])
	for o in m._options:
		o.queue_redraw()


func _new_menu(golden: bool, ids: Array, h: int, reduced: bool) -> ChoiceMenu:
	var m := ChoiceMenu.new()
	m.setup(golden, ids, h, reduced)
	root.add_child(m)
	return m


func _mouse(pos: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = pos
	e.global_position = pos
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	root.push_input(e)


func _main() -> void:
	await _wait(3)
	print("INFO viewport %s" % root.get_visible_rect().size)
	await _static_cases()
	await _breathing()
	await _flash(800)
	await _flash(640)
	await _realtime_close()
	await _real_screens()
	print("QA MENU WINDOW RESULT: %d passed, %d failed" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)


## 1. 靜態(減少動態):所有可抽到的道具都出現一次,標題 + 3 個圖示逐像素
func _static_cases() -> void:
	var case_n := 0
	for golden in [true, false]:
		var pool := ItemDefs.choice_pool(golden, true)
		var i := 0
		while i < pool.size():
			var ids := []
			for k in 3:
				ids.append(pool[(i + k) % pool.size()])
			var h := 800 if case_n % 2 == 0 else 640
			var m := _new_menu(golden, ids, h, true)
			var saved := []
			await _wait(3)
			_set_blank(m, true, saved)
			await _wait(3)
			var base := _shot()
			_set_blank(m, false, saved)
			await _wait(3)
			var shot := _shot()
			var tag := "%s H%d %s" % ["gold" if golden else "black", h, ids]
			if case_n < 2:
				shot.save_png(_out.path_join("qa_menu_static_%s_h%d.png" % ["gold" if golden else "black", h]))
			var ti := _title_icon(m)
			var tdest := Vector2i(ti.global_position)
			var r := _cmp(shot, base, _src("res://art/items40/d32_item_%s_f1.png" % ("golden_ball" if golden else "black_ball")), tdest)
			if i == 0:
				_report("%s title icon 1x at %s" % ["gold" if golden else "black", tdest], r[0] == 0 and r[1] > 0, "%d opaque %d partial; %d differ %s" % [r[1], r[2], r[0], r[3]])
			elif r[0] != 0:
				_report("%s title icon" % tag, false, r[3])
			var rects := [Rect2i(tdest, Vector2i(40, 40))]
			for k in 3:
				var d := _icon_dest(m, k)
				rects.append(Rect2i(d, Vector2i(40, 40)))
				var rr := _cmp(shot, base, _src(ItemDefs.icon_path(ids[k], false)), d)
				_report("%s opt%d %s F1 1x at %s" % ["gold" if golden else "black", k, ids[k], d], rr[0] == 0 and rr[1] > 0, "H%d; %d opaque %d partial; %d differ %s" % [h, rr[1], rr[2], rr[0], rr[3]])
			var od := _outside_diff(shot, base, rects)
			_report("%s nothing drawn outside icon rects" % tag, od[0] == 0, "%d px %s" % od)
			m.queue_free()
			await _wait(2)
			i += 3
			case_n += 1


## 2. 呼吸:F1/F2 跟共用 400 ms 時鐘;減少動態固定 F1
func _breathing() -> void:
	var ids := ["gun", "flame", "sticky"]
	var m := _new_menu(true, ids, 800, false)
	var probe := TickProbe.new()
	root.add_child(probe)
	await _wait(30)   # 入場 300 ms 跑完
	var saved := []
	_set_blank(m, true, saved)
	await _wait(3)
	var base := _shot()
	_set_blank(m, false, saved)
	await _wait(2)
	var src := {}
	for id in ids:
		src[id] = [_src(ItemDefs.icon_path(id, false)), _src(ItemDefs.icon_path(id, true))]
	var title_src := _src("res://art/items40/d32_item_golden_ball_f1.png")
	var seen := {}
	var ok_n := 0
	var edge := 0
	var bad := 0
	var first_bad := ""
	var title_bad := 0
	var saved_f2 := false
	for n in 120:
		await RenderingServer.frame_post_draw
		var ms := probe.last_ms
		var shot := _shot()
		var ks := []
		for k in 3:
			var d := _icon_dest(m, k)
			if _cmp(shot, base, src[ids[k]][0], d)[0] == 0:
				ks.append("f1")
			elif _cmp(shot, base, src[ids[k]][1], d)[0] == 0:
				ks.append("f2")
			else:
				ks.append("none")
		if _cmp(shot, base, title_src, Vector2i(_title_icon(m).global_position))[0] != 0:
			title_bad += 1
		var k0: String = ks[0] if ks.count(ks[0]) == 3 else "mixed"
		seen[k0] = seen.get(k0, 0) + 1
		var ph := fmod(ms / 1000.0, 0.8)
		var want := "f2" if ph >= 0.4 else "f1"
		var near := absf(ph - 0.4) * 1000.0 <= 5.0 or ph * 1000.0 <= 5.0 or (0.8 - ph) * 1000.0 <= 5.0
		if k0 == want:
			ok_n += 1
		elif near and (k0 == "f1" or k0 == "f2"):
			edge += 1
		else:
			bad += 1
			if first_bad == "":
				first_bad = "ms %d ph %.3f want %s got %s" % [ms, ph, want, ks]
		if k0 == "f2" and not saved_f2:
			saved_f2 = true
			shot.save_png(_out.path_join("qa_menu_breath_f2.png"))
	print("INFO breathing frames %s; match %d, boundary %d, mismatch %d %s" % [seen, ok_n, edge, bad, first_bad])
	_report("breathing F1/F2 follow shared 400 ms clock, 3 options in phase", bad == 0 and seen.has("f1") and seen.has("f2"), str(seen))
	_report("title icon stays F1 (static) during breathing", title_bad == 0, "%d frames differ" % title_bad)
	for o in m._options:
		o.reduced_motion = true
	var rm := {}
	for n in 60:
		await RenderingServer.frame_post_draw
		var shot := _shot()
		var k := "f1" if _cmp(shot, base, src[ids[0]][0], _icon_dest(m, 0))[0] == 0 else "other"
		rm[k] = rm.get(k, 0) + 1
	_report("reduced motion: option icons fixed F1 over 60 frames (~1 s)", rm.keys() == ["f1"], str(rm))
	m.queue_free()
	probe.queue_free()
	await _wait(2)


## 3. 閃光:真實滑鼠選取後凍結時間,逐幀比對
func _flash(h: int) -> void:
	var golden := h == 800
	var ids := ["slow", "split", "gun"] if golden else ["fast", "merge", "heal_area"]
	var m := _new_menu(golden, ids, h, false)
	await _wait(45)   # > 500 ms 鎖定
	var k := 1 if golden else 2
	var c := m._options[k].get_global_rect().get_center()
	_mouse(c, true)
	_mouse(c, false)
	_report("H%d real mouse release picks option %d" % [h, k], m._picked == k, "picked %d" % m._picked)
	if m._picked != k:
		m.queue_free()
		return
	m.set_process(false)
	var sel: ChoiceOption = m._options[k]
	# 閃光下方的圖示會呼吸;兩張截圖之間若換幀會誤判,比對期間固定圖示 F1(只影響圖示,閃光由 _apply_pick 控制)
	sel.reduced_motion = true
	var icon_center := Vector2(_icon_dest(m, k)) + Vector2(20, 20)
	for f in 3:
		m._apply_pick(0.03 + 0.06 * f)
		for o in m._options:
			o.queue_redraw()
		await _wait(3)
		var shot := _shot()
		shot.save_png(_out.path_join("qa_menu_flash_h%d_f%d.png" % [h, f + 1]))
		sel.pickup_frame = -1
		sel.queue_redraw()
		await _wait(3)
		var base := _shot()
		var dest := Vector2i(sel.global_position + ChoiceOption.PICKUP_RECT.position)
		var r := _cmp(shot, base, _src("res://art/items40/d32_item_pickup_f%d.png" % (f + 1)), dest)
		_report("H%d flash F%d 1x at %s" % [h, f + 1, dest], r[0] == 0 and r[1] > 0, "%d opaque %d partial; %d differ %s" % [r[1], r[2], r[0], r[3]])
		var center := Vector2(dest) + Vector2(24, 24)
		_report("H%d flash F%d center %s == icon center %s" % [h, f + 1, center, icon_center], center == icon_center)
		var want_dest := Vector2i(44, 310 + 120 * k + (52 + floori((h - 484) / 2.0) - 210))
		_report("H%d flash F%d top-left == spec %s" % [h, f + 1, want_dest], dest == want_dest)
		var od := _outside_diff(shot, base, [Rect2i(dest, Vector2i(48, 48))])
		_report("H%d flash F%d nothing else drawn" % [h, f + 1], od[0] == 0, "%d px %s" % od)
	m.queue_free()
	await _wait(2)


## 4. 實際時間:選取到 closed 的時間、閃光每幀時間
func _realtime_close() -> void:
	for reduced in [false, true]:
		var m := _new_menu(true, ["slow", "split", "gun"], 800, reduced)
		var t_open := Time.get_ticks_msec()
		var res := {"closed": -1}
		m.closed.connect(func() -> void: res["closed"] = Time.get_ticks_msec())
		# 鎖定期間點擊無效
		await _wait(10)
		var c := m._options[0].get_global_rect().get_center()
		_mouse(c, true)
		_mouse(c, false)
		var early := Time.get_ticks_msec() - t_open
		_report("reduced=%s tap at ~%d ms (in lock) ignored" % [reduced, early], m._picked == -1 and early < 500)
		while m._t < 0.5:
			await RenderingServer.frame_post_draw
		_mouse(c, true)
		_mouse(c, false)
		var t_pick := Time.get_ticks_msec()
		_report("reduced=%s tap after unlock (t %.3f) picks" % [reduced, m._t], m._picked == 0)
		var frames := []
		while res["closed"] < 0 and Time.get_ticks_msec() - t_pick < 1500:
			await RenderingServer.frame_post_draw
			if is_instance_valid(m) and not m._closing:
				frames.append("%d:%d" % [int(m._pick_t * 1000), m._options[0].pickup_frame])
		var dt: int = res["closed"] - t_pick
		var want := 240 if reduced else 420
		print("INFO reduced=%s pick->closed %d ms; (pick_t ms:frame) %s" % [reduced, dt, frames])
		# 選單用每幀 delta 計時;選取後第一個 delta 含選取前的時間,所以牆鐘可能早到最多 1 幀(~17 ms)
		_report("reduced=%s closed ~%d ms after pick (real time %d ms, +-1 frame at 60 fps)" % [reduced, want, dt], dt >= want - 17 and dt <= want + 34)
		await _wait(2)


## 5. 真實畫面截圖(主場景開啟選單),並量測實機字型
func _real_screens() -> void:
	# 固定測試關卡(無魔王):不依賴 game_config.tres 目前的 level_path(魔王關進場有 1.6 秒 BOSS 警告)
	var cfg := load("res://data/game_config.tres") as GameConfig
	cfg.level_path = "res://data/levels/level_func_test.json"
	var mm = MainScene.instantiate()
	root.add_child(mm)
	await _wait(3)
	mm.rng.seed = 3
	mm.state = 1
	mm._open_menu(true)
	var menu: ChoiceMenu = mm.menu
	await _wait(40)
	_root_shot("qa_menu_real_gold_h%d.png" % mm.view_h)
	var font: Font = menu._options[0].get_theme_default_font()
	var worst := 0.0
	var worst_s := ""
	var over := []
	for id in ItemDefs.BUFF + ItemDefs.DEBUFF:
		for l in [ItemDefs.item_name(id)] + ItemDefs.desc_lines(id):
			var w := font.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, ChoiceOption.FONT_SIZE).x
			if w > worst:
				worst = w
				worst_s = l
			if w > ChoiceOption.TEXT_W:
				over.append("%s %.0f" % [l, w])
	_report("window font: all names/descs <= 216 px (widest '%s' %.1f)" % [worst_s, worst], over.is_empty(), str(over))
	# 2026-10-28 道具秒數修訂:文字欄寬 216、每條最多 3 行,且 3 行的剛好 4 條(火焰、吸附、槍、範圍回血)
	_report("ChoiceOption.TEXT_W == 216", ChoiceOption.TEXT_W == 216, str(ChoiceOption.TEXT_W))
	var three := []
	var too_many := []
	for id in ItemDefs.BUFF + ItemDefs.DEBUFF:
		var n: int = ItemDefs.desc_lines(id).size()
		if n == 3:
			three.append(id)
		if n > 3:
			too_many.append(id)
	three.sort()
	_report("every item desc <= 3 lines", too_many.is_empty(), str(too_many))
	_report("3-line items = flame, gun, heal_area, sticky", three == ["flame", "gun", "heal_area", "sticky"], str(three))
	for golden in [true, false]:
		var tm := ChoiceMenu.new()
		tm.setup(golden, ["slow"], 800, true)
		root.add_child(tm)
		for c in tm._panel.get_children():
			if c is Label:
				var w: float = (c as Label).get_minimum_size().x
				_report("window font: title/sub '%s' %.1f <= 232" % [c.text, w], w <= 232.0)
		tm.free()
	mm.free()
	await _wait(2)
	# 黑球,H = 640 獨立選單(畫在預設背景上)
	var bm := _new_menu(false, ["fast", "heal_area", "invincible"], 640, false)
	await _wait(40)
	_root_shot("qa_menu_black_h640.png")
	bm.queue_free()
	await _wait(2)


func _root_shot(name: String) -> void:
	_shot().save_png(_out.path_join(name))
	print("INFO saved %s" % _out.path_join(name))
