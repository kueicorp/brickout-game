## QA 獨立驗證(headless):打磚加速、擋板 85 與各道具長度的邊界/拖曳/接取、奇數長度的畫面中心。
## 執行:Godot --headless --path game --script res://tests/qa_accel_paddle_test.gd
## 全部通過時結束碼 0;輸出不應出現 SCRIPT ERROR。
## 「重開一局」要等 reload_current_scene 的延遲處理,所以跨幾個 process 幀才結束。
extends SceneTree

const MainScene := preload("res://scenes/main.tscn")
const MainScript := preload("res://scripts/main.gd")
const FPS := 1.0 / 60.0

var cfg: GameConfig
var _passed := 0
var _failed := 0
var _section := ""
var _frame := 0
var _restart_old = null


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		cfg = load("res://data/game_config.tres") as GameConfig
		_run("accel_amounts", _t_accel_amounts)
		_run("accel_cap", _t_accel_cap)
		_run("accel_tiers", _t_accel_tiers)
		_run("accel_slow_keeps", _t_accel_slow_keeps)
		_run("accel_not_counted", _t_accel_not_counted)
		_run("accel_multi_ball", _t_accel_multi_ball)
		_run("accel_high_speed_bricks", _t_high_speed_bricks)
		_run("accel_high_speed_paddle", _t_high_speed_paddle)
		_run("accel_high_speed_multi_ball", _t_high_speed_multi_ball)
		_run("paddle_lengths", _t_paddle_lengths)
		_run("paddle_odd_center", _t_paddle_odd_center)
		_section = "accel_restart"
		_restart_begin()
	elif _frame == 3:
		_section = "accel_restart"
		_restart_press()
	elif _frame == 8:
		_section = "accel_restart"
		_restart_check()
		print("QA ACCEL/PADDLE RESULT: %d passed, %d failed" % [_passed, _failed])
		quit(1 if _failed > 0 else 0)
	return false


func _run(name: String, f: Callable) -> void:
	_section = name
	f.call()


func _eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual == expected:
		_passed += 1
	else:
		_failed += 1
		print("FAIL [%s] %s: expected %s, got %s" % [_section, label, expected, actual])


func _ok(cond: bool, label: String) -> void:
	_eq(cond, true, label)


func _near(a: float, b: float, label: String, eps := 0.0001) -> void:
	if absf(a - b) < eps:
		_passed += 1
	else:
		_failed += 1
		print("FAIL [%s] %s: expected %.6f, got %.6f" % [_section, label, b, a])


# ---------- 輔助 ----------

func _fresh():
	var m = MainScene.instantiate()
	root.add_child(m)
	m.rng.seed = 777
	for r in MainScript.MAX_ROWS:
		for c in MainScript.COLS:
			m.grid[r][c] = null
	m.breakable_left = 0
	m.items.clear()
	m.bullets.clear()
	m.anims.clear()
	m.score = 0
	m.balls.clear()
	m.paddle_x = 180.0
	m.target_x = 180.0
	m.view_h = 800
	_brick(m, 7, 0, 69)   # 哨兵,避免意外過關
	return m


func _brick(m, c: int, r: int, layers: int, unbreakable := false):
	var br = MainScript.Brick.new()
	br.layers = layers
	br.unbreakable = unbreakable
	m.grid[r][c] = br
	if not unbreakable:
		m.breakable_left += 1
	return br


func _layers(m, c: int, r: int) -> int:
	var br = m.grid[r][c]
	return -999 if br == null else br.layers


func _ball(m, pos: Vector2, dir: Vector2):
	var b = MainScript.Ball.new()
	b.pos = pos
	b.dir = dir.normalized()
	m.balls.append(b)
	return b


## 讓球從磚正下方 2 px 往上撞(真實碰撞路徑 _ball_bricks)。
func _hit_from_below(m, cell: Vector2i) -> void:
	var r: Rect2 = m._cell_rect(cell)
	var b = MainScript.Ball.new()
	b.pos = Vector2(r.get_center().x, r.end.y + 6.0)
	b.dir = Vector2.UP
	m._ball_bricks(b, m._pierce_on())


func _expire(m, id: String) -> void:
	m.effects.timed[id]["remaining"] = 0.001
	for e in m.effects.tick(0.01):
		m._on_expired(e)


## 在空曠處量一幀的實際位移(px/s)。
func _measured_speed(m) -> float:
	var saved: Array = m.balls.duplicate()
	m.balls.clear()
	var b = _ball(m, Vector2(180, 500), Vector2.UP)
	m._update_balls(0.01)
	var v: float = (Vector2(180, 500) - b.pos).length() / 0.01
	m.balls.assign(saved)
	return v


func _push_drag(dx: float) -> void:
	var e := InputEventScreenDrag.new()
	e.index = 0
	e.position = Vector2(180, 500)
	e.relative = Vector2(dx, 0)
	root.push_input(e)


## rect_pos = 40×40 接取範圍左上角。D32 items40:_item_rect = pos − (12, 12),所以 pos = rect_pos + 12
## (原 32×32 時是 pos − 8)。
func _catch(m, rect_pos: Vector2) -> bool:
	m.items = [{"id": "slow", "pos": rect_pos + Vector2(12, 12)}]
	m._update_items(0.0)
	return m.items.is_empty()


# ---------- 打磚加速 ----------

func _t_accel_amounts() -> void:
	_eq([cfg.brick_accel_unbreakable, cfg.brick_accel_other, cfg.brick_accel_max], [0.01, 0.005, 1.0], "config 1% / 0.5% / 1.0")
	var cases := [
		# [說明, 啟用的道具, 不可破壞, 預期加速]
		["unbreakable bounce", [], true, 0.01],
		["multi-layer bounce", [], false, 0.005],
		["1-layer brick destroyed", [], false, 0.005],
		["invincible on breakable", ["invincible"], false, 0.005],
		["invincible on unbreakable", ["invincible"], true, 0.01],
		["bomb marking", ["bomb"], false, 0.005],
		["heal", ["heal"], false, 0.005],
		["heal_area", ["heal_area"], false, 0.005],
		["flame center", ["flame"], false, 0.005],
		["pierce on unbreakable (bounce)", ["pierce"], true, 0.01],
		["pierce + invincible on breakable (bounce)", ["pierce", "invincible"], false, 0.005],
	]
	for cs in cases:
		var m = _fresh()
		for id in cs[1]:
			m._apply_item(id)
		var layers := 1 if cs[0] == "1-layer brick destroyed" else 10
		_brick(m, 3, 8, layers, cs[2])
		_brick(m, 0, 16, 5)   # 讓 1 層磚被打掉時不會過關
		_hit_from_below(m, Vector2i(3, 8))
		_near(m.brick_accel, cs[3], "%s: +%.3f" % [cs[0], cs[3]])
		m.free()
	# 穿透:進入可破壞磚時算一次,停在磚內不重複算;離開再進另一塊再算一次
	var m2 = _fresh()
	m2._apply_item("pierce")
	_brick(m2, 3, 8, 10)
	_brick(m2, 3, 6, 10)
	var b = MainScript.Ball.new()
	b.pos = m2._cell_rect(Vector2i(3, 8)).get_center()
	b.dir = Vector2.UP
	m2._ball_bricks(b, true)
	m2._ball_bricks(b, true)
	m2._ball_bricks(b, true)
	_near(m2.brick_accel, 0.005, "pierce: enter once = +0.005, staying inside adds nothing")
	b.pos = m2._cell_rect(Vector2i(3, 6)).get_center()
	m2._ball_bricks(b, true)
	_near(m2.brick_accel, 0.01, "pierce: entering another brick +0.005 again")
	m2.free()
	# 相加不複利:3 次不可破壞 + 2 次其他 = 0.04
	var m3 = _fresh()
	_brick(m3, 1, 3, 1, true)
	_brick(m3, 2, 3, 60)
	for i in 3:
		_hit_from_below(m3, Vector2i(1, 3))
	for i in 2:
		_hit_from_below(m3, Vector2i(2, 3))
	_near(m3.brick_accel, 0.04, "additive: 3 x 1% + 2 x 0.5% = 4%")
	_near(m3._ball_speed(), 240.0 * 1.04, "speed 240 x 1.04")
	m3.free()


func _t_accel_cap() -> void:
	var m = _fresh()
	_brick(m, 1, 3, 1, true)
	_brick(m, 2, 3, 69)
	# 上限 1.0(+100%):99 次不可破壞 = 0.99,再 2 次其他磚剛好 1.0
	for i in 99:
		_hit_from_below(m, Vector2i(1, 3))
	_near(m.brick_accel, 0.99, "99 unbreakable hits = 0.99")
	_hit_from_below(m, Vector2i(2, 3))
	_hit_from_below(m, Vector2i(2, 3))
	_near(m.brick_accel, 1.0, "0.99 + 0.005 + 0.005 = 1.0")
	_hit_from_below(m, Vector2i(1, 3))
	_near(m.brick_accel, 1.0, "cap: +1% at 1.0 stays 1.0")
	for i in 200:
		_hit_from_below(m, Vector2i(1, 3))
	_ok(m.brick_accel <= 1.0 + 1e-9, "cap: never above 1.0 after 200 more hits (%.6f)" % m.brick_accel)
	_near(1.0 + m.brick_accel, 2.0, "multiplier capped at 2.0")
	_near(_measured_speed(m), 480.0, "measured movement 240 x 2.0 = 480 px/s", 0.01)
	m.free()
	# 只打其他磚到上限:200 次 × 0.5%(打 240 次,浮點累加後仍夾在 1.0)
	var m2 = _fresh()
	_brick(m2, 2, 3, 69)
	for i in 240:
		_hit_from_below(m2, Vector2i(2, 3))
		m2.grid[3][2].layers = 69   # 補回層數,讓同一塊磚一直被打
	_ok(m2.brick_accel <= 1.0 + 1e-9 and m2.brick_accel > 1.0 - 1e-9, "240 other hits capped at 1.0 (%.9f)" % m2.brick_accel)
	m2.free()


func _t_accel_tiers() -> void:
	var m = _fresh()
	m.brick_accel = 1.0
	for i in 10:
		m._apply_item("fast")
	_eq(m.effects.ball_tier, 4, "fast capped at +4")
	_near(m._ball_speed(), 240.0 * 1.6 * 2.0, "+4 tier x 2.0 = 768")
	_near(_measured_speed(m), 768.0, "measured +4 x 2.0 = 768 px/s (3.2x)", 0.01)
	for i in 20:
		m._apply_item("slow")
	_eq(m.effects.ball_tier, -3, "slow capped at -3")
	_near(m._ball_speed(), 240.0 * 0.55 * 2.0, "-3 tier x 2.0 = 264")
	_near(_measured_speed(m), 264.0, "measured -3 x 2.0 = 264 px/s", 0.01)
	_near(m.brick_accel, 1.0, "accel untouched by tier changes")
	m.free()


func _t_accel_slow_keeps() -> void:
	var m = _fresh()
	_brick(m, 1, 3, 1, true)
	for i in 20:
		_hit_from_below(m, Vector2i(1, 3))
	_near(m.brick_accel, 0.2, "20 hits = 0.2")
	m._apply_item("fast")
	m._apply_item("fast")
	m._pickup("slow", Vector2(100, 400))   # 經由撿道具的路徑
	_eq(m.effects.ball_tier, 1, "slow: only -1 tier (2 -> 1)")
	_near(m.brick_accel, 0.2, "slow: accel kept")
	m._pickup("slow", Vector2(100, 400))
	m._pickup("slow", Vector2(100, 400))
	_eq(m.effects.ball_tier, -1, "slow below 0 tier")
	_near(m.brick_accel, 0.2, "slow below 0: accel kept")
	_near(_measured_speed(m), 240.0 * 0.85 * 1.2, "measured -1 tier x 1.2", 0.01)
	# 3 選 1 選到減速也只降階
	m._on_menu_picked("slow")
	_eq(m.effects.ball_tier, -2, "menu slow: -1 tier")
	_near(m.brick_accel, 0.2, "menu slow: accel kept")
	m.free()


func _t_accel_not_counted() -> void:
	# 子彈:打可破壞磚、不可破壞磚、無敵中的磚都不加速(走真實 _update_bullets 掃掠)
	var m = _fresh()
	_brick(m, 1, 5, 10)
	_brick(m, 2, 5, 1, true)
	m.bullets = [Vector2(m._cell_rect(Vector2i(1, 5)).position.x + 10, 400), Vector2(m._cell_rect(Vector2i(2, 5)).position.x + 10, 400)]
	for i in 60:
		m._update_bullets(FPS)
	_eq(_layers(m, 1, 5), 9, "bullet hit the breakable brick")
	_near(m.brick_accel, 0.0, "bullets do not accelerate")
	m._apply_item("invincible")
	m.bullets = [Vector2(m._cell_rect(Vector2i(1, 5)).position.x + 10, 400)]
	for i in 60:
		m._update_bullets(FPS)
	_near(m.brick_accel, 0.0, "bullet blocked by invincible: no accel")
	m.free()
	# 槍經由 _fire_gun + _step 實際跑幀
	var mg = _fresh()
	mg._apply_item("gun")
	for c in 8:
		if c != 7:
			_brick(mg, c, 16, 50)
	mg._fire_gun()
	for i in 60:
		mg._step(FPS)
	_ok(mg.bullets.is_empty(), "gun bullets consumed via _step")
	_near(mg.brick_accel, 0.0, "gun via _step: no accel")
	mg.free()
	# 火焰擴散:中心算一次 +0.5%,8 個鄰磚被擴散扣層不算
	var m2 = _fresh()
	m2._apply_item("flame")
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			_brick(m2, 3 + dx, 8 + dy, 5)
	_hit_from_below(m2, Vector2i(3, 9))   # 撞最下排中間 (3, 9),它的鄰居含 (2..4, 8)
	_eq(_layers(m2, 3, 9), 3, "flame center -2")
	_eq(_layers(m2, 3, 8), 4, "flame splash hit neighbor")
	_near(m2.brick_accel, 0.005, "flame: only the hit brick counts (splash does not)")
	m2.free()
	# 炸彈爆炸:標記時每次算(3 次 = 1.5%),爆炸破壞與 3×3 扣層不算
	var m3 = _fresh()
	m3._apply_item("bomb")
	_brick(m3, 1, 5, 5)
	_brick(m3, 3, 5, 5)
	_brick(m3, 5, 5, 5)
	_brick(m3, 2, 6, 9)
	_brick(m3, 4, 6, 9)
	_hit_from_below(m3, Vector2i(1, 5))
	_hit_from_below(m3, Vector2i(3, 5))
	_hit_from_below(m3, Vector2i(5, 5))
	_near(m3.brick_accel, 0.015, "bomb marking 3 x 0.5%")
	_expire(m3, "bomb")
	_eq([_layers(m3, 1, 5), _layers(m3, 3, 5), _layers(m3, 5, 5), _layers(m3, 2, 6), _layers(m3, 4, 6)], [-999, -999, -999, 5, 5], "bomb exploded (marked destroyed, splash -2 x2 overlapping)")
	_near(m3.brick_accel, 0.015, "bomb explosion: no accel")
	m3.free()
	# 穿透結束時球下的磚被破壞:不算(進入時那一次 +0.5% 照算)
	var m4 = _fresh()
	m4._apply_item("pierce")
	_brick(m4, 3, 8, 30)
	var b = _ball(m4, m4._cell_rect(Vector2i(3, 8)).get_center(), Vector2.UP)
	m4._ball_bricks(b, true)
	_near(m4.brick_accel, 0.005, "pierce entry +0.5%")
	_expire(m4, "pierce")
	_eq(_layers(m4, 3, 8), -999, "pierce end destroyed brick under ball")
	_near(m4.brick_accel, 0.005, "pierce end destruction: no accel")
	m4.free()
	# 範圍回血的周圍加層不算(只算被撞的那塊)
	var m5 = _fresh()
	m5._apply_item("heal_area")
	for dx in range(-1, 2):
		_brick(m5, 3 + dx, 8, 5)
	_hit_from_below(m5, Vector2i(3, 8))
	_eq([_layers(m5, 2, 8), _layers(m5, 3, 8), _layers(m5, 4, 8)], [6, 7, 6], "heal_area applied")
	_near(m5.brick_accel, 0.005, "heal_area: only the hit brick counts")
	m5.free()


func _t_accel_multi_ball() -> void:
	var m = _fresh()
	_brick(m, 4, 10, 1, true)   # x 180~220、y 268~288
	var a = _ball(m, Vector2(200, 296.5), Vector2.UP)   # 往上 0.5 px 就碰到
	var dirs := [Vector2(0.6, -0.8), Vector2(-0.28, 0.96), Vector2(-0.8, -0.6)]
	var starts := [Vector2(80, 500), Vector2(280, 450), Vector2(250, 600)]
	var others := []
	for k in 3:
		others.append(_ball(m, starts[k], dirs[k]))
	m._update_balls(FPS)
	_near(m.brick_accel, 0.01, "one bounce in the frame: +1%")
	_ok(a.dir.y > 0.0, "hitting ball bounced")
	var v1 := 240.0 * 1.01
	for k in 3:
		var o = others[k]
		_ok(o.dir.is_equal_approx(dirs[k].normalized()), "ball %d keeps direction" % k)
		_near((o.pos - starts[k]).length(), v1 * FPS, "ball %d moved at new speed in the same frame" % k)
	# 下一幀:所有球(含反彈的那顆)都以 1.01 倍移動,方向不變
	var prev := []
	var pdir := []
	for b in m.balls:
		prev.append(b.pos)
		pdir.append(b.dir)
	m._update_balls(FPS)
	for k in m.balls.size():
		var b = m.balls[k]
		_near((b.pos - prev[k]).length(), v1 * FPS, "next frame ball %d speed 1.01x" % k)
		_ok(b.dir.is_equal_approx(pdir[k]), "next frame ball %d direction unchanged" % k)
	# 20 顆球同時:速度階 +4、加速 1.0 → 全部 768 px/s
	m.balls.clear()
	m.brick_accel = 1.0
	m.effects.ball_tier = 4
	for i in 20:
		_ball(m, Vector2(40 + 14 * i, 520), Vector2.UP.rotated(deg_to_rad(-40 + 4 * i)))
	var p0 := []
	for b in m.balls:
		p0.append(b.pos)
	m._update_balls(FPS)
	var all_ok := true
	for k in m.balls.size():
		all_ok = all_ok and absf((m.balls[k].pos - p0[k]).length() - 768.0 * FPS) < 0.001
	_ok(all_ok, "20 balls all move at 768 px/s")
	m.free()


## 3.2 倍速(768 px/s)實際逐幀跑:整排不可破壞磚,任何角度都不能穿過去。
func _t_high_speed_bricks() -> void:
	for dt in [FPS, MainScript.MAX_DT]:
		var m = _fresh()
		m.grid[0][7] = null
		m.breakable_left = 0
		m.effects.ball_tier = 4
		m.brick_accel = 1.0
		for c in 8:
			_brick(m, c, 10, 1, true)   # y 268~288
		_brick(m, 0, 16, 69)           # 遠處可破壞磚,避免過關
		var row_bottom := 288.0
		var worst := 9999.0
		var not_bounced := 0
		var crossed := 0
		for deg in range(-74, 75, 4):
			for x0 in [33.0, 100.0, 179.5, 220.0, 301.3]:
				m.balls.clear()
				var b = _ball(m, Vector2(x0, 420.0), Vector2.UP.rotated(deg_to_rad(deg)))
				var bounced := false
				for f in 200:
					m._update_balls(dt)
					if b.pos.y < row_bottom:
						crossed += 1
						break
					worst = minf(worst, b.pos.y - MainScript.BALL_R)
					if b.dir.y > 0.0:
						bounced = true
						break
				if not bounced:
					not_bounced += 1
		_eq(crossed, 0, "dt %.3f: ball center never passes into/through the brick row" % dt)
		_eq(not_bounced, 0, "dt %.3f: every ball bounces off the row" % dt)
		# 推出後球上緣應在磚下緣(容許不到 1 個子步的穿入)
		_ok(worst >= row_bottom - 3.0, "dt %.3f: max penetration < 3 px (ball top min %.3f)" % [dt, worst])
		_eq(m.brick_accel, 1.0, "dt %.3f: accel stays at cap" % dt)
		m.free()
	# 單塊磚、垂直對準:最高速時仍反彈,不會從磚另一側出來
	var m2 = _fresh()
	m2.effects.ball_tier = 4
	m2.brick_accel = 1.0
	_brick(m2, 3, 8, 69)   # x 140~180、y 228~248
	var b2 = _ball(m2, Vector2(160, 400), Vector2.UP)
	var min_y := 9999.0
	for f in 60:
		m2._step(MainScript.MAX_DT)
		min_y = minf(min_y, b2.pos.y)
		if b2.dir.y > 0.0:
			break
	_ok(b2.dir.y > 0.0 and min_y > 248.0, "single brick at 3.2x: bounced, center never inside (min y %.3f)" % min_y)
	_eq(_layers(m2, 3, 8), 68, "single brick took exactly 1 hit")
	m2.free()


## 3.2 倍速往下撞擋板(各長度、各角度、各位置),每顆都要被接住反彈,不能穿過擋板。
func _t_high_speed_paddle() -> void:
	for item in ["", "paddle_len_min", "paddle_len_down_2", "paddle_len_1", "paddle_len_max"]:
		for dt in [FPS, MainScript.MAX_DT]:
			var m = _fresh()
			if item != "":
				# 測試會跑很多秒的模擬時間,長度道具給足時間,避免中途到期變回 85
				m.effects.add_timed(item, 99999.0)
			m.time_left = 99999.0
			m.effects.ball_tier = 4
			m.brick_accel = 1.0
			var len: int = m._paddle_len()
			m.paddle_x = 180.0
			m.target_x = 180.0
			m._update_paddle(0.0)
			var left: int = m._paddle_left(len)
			var py: int = m._paddle_y()
			var missed := 0
			var deepest := 0.0
			var n := 0
			for deg in range(-60, 61, 10):
				for k in 9:
					# 預計落點在擋板範圍內(兩端內縮 1 px)
					var land := left + 1 + (len - 2) * k / 8.0
					var dir := Vector2.DOWN.rotated(deg_to_rad(deg))
					var start := Vector2(land, py - 8.0) - dir * 150.0
					if start.x < 28.0 or start.x > 332.0:
						continue
					n += 1
					m.balls.clear()
					var b = _ball(m, start, dir)
					var ok := false
					for f in 40:
						m._step(dt)
						if m.state != 0 or m.balls.is_empty():
							break
						deepest = maxf(deepest, b.pos.y - (py - 8.0))
						if b.dir.y < 0.0:
							ok = true
							break
					if not ok:
						missed += 1
						print("INFO missed: len %d dt %.3f deg %d land %.1f" % [len, dt, deg, land])
					if m.state != 0:
						break
			_ok(n > 0, "len %d dt %.3f: %d drops tested" % [len, dt, n])
			_eq(missed, 0, "len %d dt %.3f: all balls caught at 3.2x" % [len, dt])
			_ok(deepest <= 0.001, "len %d dt %.3f: ball never sinks below py - 8 (max %.3f)" % [len, dt, deepest])
			m.free()


## 上限 1.0 新增:3.2 倍速多顆球「同時」飛行。
## 磚列(不可破壞 / 可破壞 69 層)與擋板(32 / 85 / 320)各自檢查每一顆球都反彈、沒有穿過。
func _t_high_speed_multi_ball() -> void:
	var dirs := []
	for deg in range(-70, 71, 10):
		dirs.append(deg)
	for unb in [true, false]:
		for dt in [FPS, MainScript.MAX_DT]:
			var m = _fresh()
			m.grid[0][7] = null
			m.breakable_left = 0
			m.time_left = 99999.0
			m.effects.ball_tier = 4
			m.brick_accel = 1.0
			for c in 8:
				_brick(m, c, 10, 69, unb)   # y 268~288
			_brick(m, 0, 16, 69)
			var row_bottom := 288.0
			var bs := []
			for i in dirs.size():
				var x0 := 30.0 + 300.0 * i / (dirs.size() - 1)
				bs.append(_ball(m, Vector2(x0, 420.0), Vector2.UP.rotated(deg_to_rad(dirs[i]))))
			var bounced := []
			bounced.resize(bs.size())
			bounced.fill(false)
			var crossed := 0
			for f in 300:
				m._update_balls(dt)
				for k in bs.size():
					var b = bs[k]
					if bounced[k]:
						continue
					if b.pos.y < row_bottom:
						crossed += 1
						bounced[k] = true   # 記一次就好
						print("INFO crossed: unb %s dt %.3f ball %d deg %d" % [unb, dt, k, dirs[k]])
					elif b.dir.y > 0.0:
						bounced[k] = true
				if not bounced.has(false):
					break
			var tag := "%s dt %.3f %d balls" % ["unbreakable" if unb else "breakable", dt, bs.size()]
			_eq(crossed, 0, "%s: no ball center passes the brick row" % tag)
			_eq(bounced.count(false), 0, "%s: every ball bounced off the row" % tag)
			_eq(m.brick_accel, 1.0, "%s: accel stays at cap" % tag)
			m.free()
	# 擋板:所有球同一幀抵達擋板(距離相同),各長度
	for item in ["paddle_len_min", "", "paddle_len_max"]:
		for dt in [FPS, MainScript.MAX_DT]:
			var m = _fresh()
			if item != "":
				m.effects.add_timed(item, 99999.0)
			m.time_left = 99999.0
			m.effects.ball_tier = 4
			m.brick_accel = 1.0
			var len: int = m._paddle_len()
			m._update_paddle(0.0)
			var left: int = m._paddle_left(len)
			var py: int = m._paddle_y()
			var bs := []
			# 13 個落點 × 13 種角度,挑起點在場內的組合;每個落點最多 1 顆,所有球同時抵達
			for i in 13:
				var land := left + 1 + (len - 2) * i / 12.0
				for j in 13:
					var deg: int = [0, 10, -10, 20, -20, 30, -30, 40, -40, 50, -50, 60, -60][(i + j) % 13]
					var dir := Vector2.DOWN.rotated(deg_to_rad(deg))
					var start := Vector2(land, py - 8.0) - dir * 150.0
					if start.x >= 28.0 and start.x <= 332.0:
						bs.append(_ball(m, start, dir))
						break
			var up := []
			up.resize(bs.size())
			up.fill(false)
			var deepest := 0.0
			for f in 60:
				m._step(dt)
				if m.state != 0:
					break
				for k in bs.size():
					if up[k]:
						continue
					var b = bs[k]
					deepest = maxf(deepest, b.pos.y - (py - 8.0))
					if b.dir.y < 0.0:
						up[k] = true
				if not up.has(false):
					break
			var tag := "len %d dt %.3f %d balls" % [len, dt, bs.size()]
			_ok(bs.size() == 13, "%s: 13 simultaneous balls placed" % tag)
			_eq(m.state, 0, "%s: still playing" % tag)
			_eq(up.count(false), 0, "%s: every ball bounced off the paddle" % tag)
			_ok(deepest <= 0.001, "%s: no ball sinks below py - 8 (max %.3f)" % [tag, deepest])
			_eq(m.brick_accel, 1.0, "%s: accel stays at cap" % tag)
			m.free()


# ---------- 擋板 ----------

## 85 與各種道具長度:左右邊界、往回拖立刻動、像素不超出 x 20~339、道具 1 px 重疊接到。
func _t_paddle_lengths() -> void:
	var table := [[[], 85], [["paddle_len_1"], 102], [["paddle_len_2"], 136], [["paddle_len_down_1"], 68],
		[["paddle_len_down_2"], 34], [["paddle_len_max"], 320], [["paddle_len_min"], 32],
		[["paddle_len_1", "paddle_len_2"], 163], [["paddle_len_down_1", "paddle_len_down_2"], 32],
		[["paddle_len_2", "paddle_len_down_2"], 54], [["paddle_len_1", "paddle_len_down_1"], 82],
		[["paddle_len_max", "paddle_len_min"], 120]]
	for row in table:
		var m = _fresh()
		for id in row[0]:
			m._apply_item(id)
		var len: int = m._paddle_len()
		var tag := "len %d %s" % [len, row[0]]
		_eq(len, row[1], "%s: length" % tag)
		var half := len / 2.0
		# 右邊界
		_push_drag(1000)
		m._update_paddle(2.0)
		_near(m.paddle_x, 340.0 - half, "%s: right edge center" % tag)
		_eq(m._paddle_left(len) + len, 340, "%s: right end = 340" % tag)
		if len < 320:
			_push_drag(-3)
			m._update_paddle(FPS)
			_near(m.paddle_x, 337.0 - half, "%s: drag back 3 from right edge moves at once" % tag)
		# 左邊界
		_push_drag(-1000)
		m._update_paddle(2.0)
		_near(m.paddle_x, 20.0 + half, "%s: left edge center" % tag)
		_eq(m._paddle_left(len), 20, "%s: left end = 20" % tag)
		if len < 320:
			_push_drag(5)
			m._update_paddle(FPS)
			_near(m.paddle_x, 25.0 + half, "%s: drag back 5 from left edge moves at once" % tag)
		# 掃過全部可能位置(含小數):像素永遠在 x 20~339 內,寬度不變
		var inside := true
		var x := 0.0
		while x <= 360.0:
			m.target_x = x
			m.paddle_x = x
			m._update_paddle(0.0)
			var l: int = m._paddle_left(len)
			inside = inside and l >= 20 and l + len <= 340
			x += 0.25
		_ok(inside, "%s: paddle pixels always within 20..339 for any target" % tag)
		# 接道具:置中後左右 1 px 重疊接到、相鄰接不到
		m.paddle_x = 180.0
		m.target_x = 180.0
		m._update_paddle(0.0)
		var pl: int = m._paddle_left(len)
		var pr: int = pl + len
		var py: int = m._paddle_y()
		var ym := float(py - 12)
		_ok(_catch(m, Vector2(pr - 1, ym)), "%s: item right 1 px overlap caught" % tag)
		_ok(not _catch(m, Vector2(pr, ym)), "%s: item right adjacent missed" % tag)
		# 40×40:最右像素 = 左上 + 39,重疊 1 px 的左上 = pl − 39;相鄰 = pl − 40
		_ok(_catch(m, Vector2(pl - 39, ym)), "%s: item left 1 px overlap caught" % tag)
		_ok(not _catch(m, Vector2(pl - 40, ym)), "%s: item left adjacent missed" % tag)
		# 逐幀掉落:落在擋板左端、右端最外 1 px 也接得到(edge = 40×40 左上角 x,pos = edge + 12)
		for edge in [pl - 39, pr - 1]:
			m.items = [{"id": "slow", "pos": Vector2(edge + 12, py - 120.0)}]
			var caught := false
			for f in 200:
				m._update_items(FPS)
				if m.items.is_empty():
					caught = true
					break
			_ok(caught, "%s: falling item at x %d caught" % [tag, edge])
		m.free()


## 奇數長度(85、163):正中央反彈 0 度;吸附球與開局球在畫出來的中心;兩端 ±60 度對稱。
func _t_paddle_odd_center() -> void:
	for items in [[], ["paddle_len_1", "paddle_len_2"]]:
		for px in [180.0, 100.25, 150.5, 200.75, 62.5, 297.5]:
			var m = _fresh()
			for id in items:
				m._apply_item(id)
			var len: int = m._paddle_len()
			var half := len / 2.0
			m.paddle_x = clampf(px, 20.0 + half, 340.0 - half)
			m.target_x = m.paddle_x
			var left: int = m._paddle_left(len)
			var py: int = m._paddle_y()
			var cx := left + half   # 畫面上實際畫出的中心(左緣整數 + 長度/2)
			var tag := "len %d paddle_x %.2f (left %d, drawn center %.2f)" % [len, m.paddle_x, left, cx]
			_eq(len % 2, 1, "%s: odd length" % tag)
			# 正中央:真實逐幀落下
			m.balls.clear()
			var b = _ball(m, Vector2(cx, py - 60.0), Vector2.DOWN)
			for f in 30:
				m._step(FPS)
				if b.dir.y < 0.0:
					break
			_ok(b.dir.is_equal_approx(Vector2.UP), "%s: center hit -> 0 deg (got %.3f)" % [tag, rad_to_deg(Vector2.UP.angle_to(b.dir))])
			# 兩端對稱 ±60
			for side in [-1.0, 1.0]:
				b.pos = Vector2(cx + side * half, py - 4.0)
				b.dir = Vector2.DOWN
				m._ball_paddle(b, left, len, py)
				_near(rad_to_deg(Vector2.UP.angle_to(b.dir)), side * 60.0, "%s: end %+d -> %+d deg" % [tag, int(side), int(side) * 60], 0.001)
			# 吸附:打在畫出來的中心 → 黏住後圓心 = 中心,拖動後仍在新的畫出中心
			m._apply_item("sticky")
			m.balls.clear()
			var s = _ball(m, Vector2(cx, py - 4.0), Vector2.DOWN)
			m._ball_paddle(s, left, len, py)
			_ok(s.stuck and is_equal_approx(s.offset, 0.0), "%s: sticky at drawn center -> offset 0" % tag)
			m._update_balls(FPS)
			_near(s.pos.x, cx, "%s: stuck ball x = drawn center" % tag)
			m.paddle_x = clampf(m.paddle_x + 13.3, 20.0 + half, 340.0 - half)
			m.target_x = m.paddle_x
			m._update_balls(FPS)
			var cx2: float = m._paddle_left(len) + half
			_near(s.pos.x, cx2, "%s: stuck ball follows to new drawn center %.2f" % [tag, cx2])
			m.free()
	# 開局球(實際開場流程):擋板 85,單顆在畫出來的中心;發射角至少 10 度
	for x in [180.0, 120.3]:
		cfg.debug_start_balls = 1
		var m2 = MainScene.instantiate()
		root.add_child(m2)
		m2.paddle_x = x
		m2.target_x = x
		m2._update_balls(FPS)
		var len2: int = m2._paddle_len()
		var cx3: float = m2._paddle_left(len2) + len2 / 2.0
		_near(m2.balls[0].pos.x, cx3, "start ball at drawn center (paddle_x %.1f -> %.1f)" % [x, cx3])
		m2._launch_stuck()
		var deg := rad_to_deg(Vector2.UP.angle_to(m2.balls[0].dir))
		_ok(absf(absf(deg) - cfg.launch_min_deg) < 0.001, "center launch uses min angle ±%.0f (got %.3f)" % [cfg.launch_min_deg, deg])
		m2.free()
	cfg.debug_start_balls = 1


# ---------- 重開一局 ----------

func _restart_begin() -> void:
	var m = MainScene.instantiate()
	root.add_child(m)
	current_scene = m
	m.brick_accel = 0.37
	m.effects.ball_tier = 3
	m._end(false, "qa restart")
	_restart_old = m


## 結束畫面出現後的下一幀才按「重玩」(與玩家實際操作一致)。
func _restart_press() -> void:
	var btn: Button = null
	for ui in _restart_old.get_children():
		if ui is Control:
			for ch in ui.get_children():
				if ch is Button:
					btn = ch
	_ok(btn != null, "end screen has restart button")
	if btn != null:
		btn.pressed.emit()


func _restart_check() -> void:
	var n = current_scene
	_ok(n != null and is_instance_valid(n) and n != _restart_old, "restart created a new main scene")
	if n == null or not is_instance_valid(n) or n == _restart_old:
		return
	_near(n.brick_accel, 0.0, "restart: accel reset to 0")
	_eq(n.effects.ball_tier, 0, "restart: tier reset to 0")
	_near(n._ball_speed(), 240.0, "restart: speed back to 240")
