## QA 視窗截圖(非 headless):D39~D44 在 level_test.json 的實際畫面 + 6 種魔王形狀的拼接,供對照 docs/design/preview/d39/。
## 執行:Godot --path game --script res://tests/qa_window_d39_capture.gd -- <輸出資料夾> [視窗高,預設 800]
## 每張存整張(遊戲座標 1 倍)與局部 3 倍放大(_zoom)。印出 CHECK 行為自動比對結果(OK / NG)。
extends SceneTree

const MainScene := preload("res://scenes/main.tscn")
const MainScript := preload("res://scripts/main.gd")

var _m
var _cfg: GameConfig
var _out := ""
var _h := 800
var _step := 0
var _t := 0.0
var _checks := 0
var _ng := 0
var _with_coins: Image


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else OS.get_user_data_dir()
	_h = int(args[1]) if args.size() > 1 else 800
	DisplayServer.window_set_size(Vector2i(360, _h))
	DirAccess.make_dir_recursive_absolute(_out)
	_cfg = load("res://data/game_config.tres") as GameConfig
	_cfg.level_path = "res://data/levels/level_test.json"
	_m = MainScene.instantiate()
	root.add_child(_m)


func _img() -> Image:
	var img := root.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	return img


func _shot(name: String, region: Rect2i) -> Image:
	var img := _img()
	img.save_png(_out.path_join(name + ".png"))
	var z := img.get_region(region)
	z.resize(region.size.x * 3, region.size.y * 3, Image.INTERPOLATE_NEAREST)
	z.save_png(_out.path_join(name + "_zoom.png"))
	print("SHOT %s viewport=%s" % [name, img.get_size()])
	return img


func _check(cond: bool, label: String) -> void:
	_checks += 1
	if not cond:
		_ng += 1
	print("CHECK %s %s" % ["OK" if cond else "NG", label])


func _hex(img: Image, x: int, y: int) -> String:
	return img.get_pixel(x, y).to_html(false)


## 兩張截圖在 area 內不同像素的外接矩形(都相同時回傳空矩形)。
func _diff_bbox(a: Image, b: Image, area: Rect2i) -> Rect2i:
	var box := Rect2i()
	var first := true
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			if a.get_pixel(x, y) != b.get_pixel(x, y):
				if first:
					box = Rect2i(x, y, 1, 1)
					first = false
				else:
					box = box.expand(Vector2i(x, y)).merge(Rect2i(x, y, 1, 1))
	return box


func _boss(cells: Array, hp: int) -> Object:
	var bs = MainScript.Boss.new()
	bs.cells.assign(cells)
	bs.size = cells.size()
	bs.max_layers = hp
	bs.layers = hp
	bs.bar_old = hp
	bs.thresholds = Rules.boss_thresholds(hp, cells.size())
	for c in cells:
		var br = MainScript.Brick.new()
		br.boss = bs
		_m.grid[c.y][c.x] = br
	return bs


func _shapes(drop: bool) -> void:
	for r in _m.grid.size():
		for c in _m.grid[r].size():
			_m.grid[r][c] = null
	var defs := [
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)],
		[Vector2i(5, 0), Vector2i(6, 0), Vector2i(5, 1), Vector2i(6, 1)],
		[Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3), Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4), Vector2i(0, 5), Vector2i(1, 5), Vector2i(2, 5)],
		[Vector2i(4, 3), Vector2i(4, 4), Vector2i(4, 5), Vector2i(5, 5)],
		[Vector2i(0, 7), Vector2i(1, 7), Vector2i(2, 7), Vector2i(1, 8)],
		[Vector2i(5, 7), Vector2i(4, 8), Vector2i(5, 8), Vector2i(6, 8)],
	]
	var drops := [Vector2i(1, 0), Vector2i(6, 1), Vector2i(1, 4), Vector2i(2, 5), Vector2i(4, 4), Vector2i(1, 7), Vector2i(4, 8)]
	var list := []
	for d in defs:
		var cells: Array = d.filter(func(c: Vector2i) -> bool: return not (drop and c in drops))
		list.append(_boss(cells, 50))
	_m.bosses.assign(list)
	_m.bar_fade = 99.0   # 6 隻只看拼接,血條淡出


func _process(delta: float) -> bool:
	_t += delta
	match _step:
		0:
			# 滑入中(約 0.1 秒)
			if _m.warn_left > 0.0 and _m.warn_left <= 1.5:
				_shot("01_warning_slide_in", Rect2i(0, 360, 360, 80))
				_step = 1
		1:
			# 停住期間(約 0.6 秒)
			if _m.warn_left > 0.0 and _m.warn_left <= 1.0:
				var img := _shot("02_warning_hold", Rect2i(0, 360, 360, 80))
				# 條紋 y 368~375 / 424~431、底板 y 376~423;血條還沒出現(y 54 那一列是空白帶背景)
				_check(_hex(img, 180, 400) != "", "warning band drawn")
				_check(_m.bar_t == 0.0, "bars hidden during warning")
				_check(_m.time_left == _cfg.game_time, "time frozen during warning")
				_step = 2
		2:
			# 警告剛結束、血條滑入中
			if _m.warn_left <= 0.0 and _m.bar_t >= 0.12 and _m.bar_t < 0.25:
				_shot("03_bars_sliding", Rect2i(0, 30, 360, 50))
				_step = 3
		3:
			if _m.bar_t >= 0.6:
				var img := _shot("04_bars_specials", Rect2i(0, 40, 360, 340))
				# 雙血條:左條 x 24~175、右條 x 184~335、y 54~65(1 px K 外框)
				_check(_hex(img, 24, 60) == "1b1a2e" and _hex(img, 175, 60) == "1b1a2e", "left bar K ends at x 24 / 175")
				_check(_hex(img, 184, 60) == "1b1a2e" and _hex(img, 335, 60) == "1b1a2e", "right bar K ends at x 184 / 335")
				_check(_hex(img, 100, 54) == "1b1a2e" and _hex(img, 100, 65) == "1b1a2e", "bar top y 54 / bottom y 65 are K")
				_check(_hex(img, 100, 53) != "1b1a2e" and _hex(img, 100, 66) != "1b1a2e", "bar 12 px tall (y 53 / 66 not K)")
				# 凍結遊戲,再扣血:B1 −13(跨 38 掉 1 格)、B2 −30(跨 38、25 掉 2 格)
				_m.balls.clear()
				_m._boss_damage(_m.bosses[0], 13)
				_m._boss_damage(_m.bosses[1], 30)
				_m.state = 1
				_t = 0.0
				_step = 4
		4:
			if _t >= 0.6:
				_m.state = 0
				_m._update_events(1.0)
				_m._update_anims(1.0)
				_m.state = 1
				_t = 0.0
				_step = 5
		5:
			if _t >= 0.1:
				_shot("05_boss_dropped_bars", Rect2i(0, 40, 360, 340))
				print("BOSS layers=%s cells=%s" % [_m.bosses.map(func(b) -> int: return b.layers), _m.bosses.map(func(b) -> int: return b.cells.size())])
				# 狀態:無敵(特殊磚外框;魔王不畫)、炸彈標記(圓形偏移、寶箱、魔王)、三種金幣 F1、魔王 1 格閃白、血條尾端閃白
				_m.effects.add_timed("invincible", 999.0)
				_m.grid[9][7].marked = true   # 圓形
				_m.grid[9][5].marked = true   # 寶箱
				_m.bosses[1].marked = true
				_m.coins.append_array([{"value": 10, "pos": Vector2(250, 470)}, {"value": 50, "pos": Vector2(280, 470)},
					{"value": 100, "pos": Vector2(310, 470)}])
				# 掉格位置隨機:閃白挑 B2 還在的第一格
				var fc: Vector2i = _m.bosses[1].cells[0]
				_m.grid[fc.y][fc.x].hit_t = 99.0
				_m.bosses[0].bar_old = 50
				_m.bosses[0].bar_t = 99.0
				_m.reduced_motion = true
				_t = 0.0
				_step = 6
		6:
			if _t >= 0.1:
				_with_coins = _shot("06_invincible_marks_coins_flash", Rect2i(0, 40, 360, 460))
				# 拿掉金幣再截一次,兩張差異範圍 = 實際畫出的金幣(遊戲已凍結,其他畫面不變)
				_m.coins.clear()
				_t = 0.0
				_step = 60
		60:
			if _t >= 0.1:
				var without := _img()
				# 尺寸(使用者決定):10 = 16×16、50 = 18×18、100 = 20×20,中心 (250/280/310, 470)
				for c in [[10, 250, 16], [50, 280, 18], [100, 310, 20]]:
					var s: int = c[2]
					var pos := Vector2i(c[1] - s / 2, 470 - s / 2)
					var tex: Texture2D = _m._t("d41_coin_%d_f1" % c[0])
					var used := tex.get_image().get_used_rect()
					var want := Rect2i(pos + used.position, used.size)
					var got := _diff_bbox(_with_coins, without, Rect2i(c[1] - 14, 470 - 14, 28, 28))
					_check(tex.get_size() == Vector2(s, s), "coin %d texture %dx%d (got %s)" % [c[0], s, s, tex.get_size()])
					_check(got == want, "coin %d drawn bbox %s == expected %s (F1 used %s at center - %d)" % [c[0], got, want, used, s / 2])
				_m.effects.timed.erase("invincible")
				_m.reduced_motion = false
				_shapes(false)
				_t = 0.0
				_step = 7
		7:
			if _t >= 0.1:
				_shot("07_shapes_full", Rect2i(0, 60, 360, 200))
				_shapes(true)
				_t = 0.0
				_step = 8
		8:
			if _t >= 0.1:
				_shot("08_shapes_dropped", Rect2i(0, 60, 360, 200))
				print("CHECK SUMMARY %d checks, %d NG (h=%d)" % [_checks, _ng, _h])
				return true
	return false
