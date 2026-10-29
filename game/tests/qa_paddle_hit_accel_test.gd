## QA 獨立驗證(headless):擋板撞擊加速(brick_accel +brick_accel_paddle)與擋板速度 450。
## 執行:Godot --headless --path game --script res://tests/qa_paddle_hit_accel_test.gd
## 全部通過時結束碼 0;輸出不應出現 SCRIPT ERROR。
extends SceneTree

const MainScene := preload("res://scenes/main.tscn")
const MainScript := preload("res://scripts/main.gd")
const FPS := 1.0 / 60.0
const PADDLE_V := 450.0
const HIT := 0.005
## 固定測試關卡(無魔王):不依賴 game_config.tres 目前的 level_path(魔王關進場有 1.6 秒 BOSS 警告)
const LEVEL := "res://data/levels/level_func_test.json"

var cfg: GameConfig
var _passed := 0
var _failed := 0
var _section := ""
var _started := false


func _process(_delta: float) -> bool:
	if _started:
		return false
	_started = true
	cfg = load("res://data/game_config.tres") as GameConfig
	cfg.level_path = LEVEL
	_run("config", _t_config)
	_run("bounce_once", _t_bounce_once)
	_run("sticky", _t_sticky)
	_run("start_stuck", _t_start_stuck)
	_run("blackhole", _t_blackhole)
	_run("gun", _t_gun)
	_run("shared_cap", _t_shared_cap)
	_run("multi_same_frame", _t_multi_same_frame)
	_run("rally_base", _t_rally_base)
	_run("rally_to_cap", _t_rally_to_cap)
	_run("high_speed_paddle", _t_high_speed_paddle)
	_run("paddle_speed_step", _t_paddle_speed_step)
	_run("paddle_leftover", _t_paddle_leftover)
	print("QA PADDLE-HIT ACCEL RESULT: %d passed, %d failed" % [_passed, _failed])
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

## 空場地:沒有任何磚(breakable_left = 1 避免過關),只留指定的球。
func _fresh():
	var m = MainScene.instantiate()
	root.add_child(m)
	m.rng.seed = 4242
	for r in MainScript.MAX_ROWS:
		for c in MainScript.COLS:
			m.grid[r][c] = null
	m.breakable_left = 1
	m.items.clear()
	m.bullets.clear()
	m.anims.clear()
	m.balls.clear()
	m.paddle_x = 180.0
	m.target_x = 180.0
	m.view_h = 800
	m.time_left = 99999.0
	return m


func _brick(m, c: int, r: int, layers: int, unbreakable := false):
	var br = MainScript.Brick.new()
	br.layers = layers
	br.unbreakable = unbreakable
	m.grid[r][c] = br
	if not unbreakable:
		m.breakable_left += 1
	return br


func _ball(m, pos: Vector2, dir: Vector2):
	var b = MainScript.Ball.new()
	b.pos = pos
	b.dir = dir.normalized()
	m.balls.append(b)
	return b


## 黏在擋板上的球(模擬開局)
func _stuck_ball(m, offset := 0.0):
	var b = MainScript.Ball.new()
	b.stuck = true
	b.offset = offset
	b.pos = Vector2(m._paddle_center(m._paddle_len()) + offset, m._paddle_y() - MainScript.BALL_R)
	m.balls.append(b)
	return b


## 讓球往下飛,直到方向向上、黏住或消失(最多 frames 幀,走 _update_balls)。
func _fall(m, b, frames := 120, dt := FPS) -> void:
	for i in frames:
		m._update_balls(dt)
		if b.dir.y < 0.0 or b.stuck or not m.balls.has(b):
			return


func _push_drag(dx: float) -> void:
	var e := InputEventScreenDrag.new()
	e.index = 0
	e.position = Vector2(180, 500)
	e.relative = Vector2(dx, 0)
	root.push_input(e)


func _push_touch(pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = 0
	e.pressed = pressed
	e.position = Vector2(180, 500)
	root.push_input(e)


func _hit_from_below(m, cell: Vector2i) -> void:
	var r: Rect2 = m._cell_rect(cell)
	var b = MainScript.Ball.new()
	b.pos = Vector2(r.get_center().x, r.end.y + 6.0)
	b.dir = Vector2.UP
	m._ball_bricks(b, m._pierce_on())


# ---------- 擋板撞擊加速 ----------

func _t_config() -> void:
	_eq(cfg.brick_accel_paddle, 0.005, "brick_accel_paddle = 0.005")
	_eq(cfg.brick_accel_max, 1.0, "shared cap 1.0")
	_eq(cfg.paddle_speed, 450.0, "paddle_speed = 450")
	var m = _fresh()
	_eq(m.brick_accel, 0.0, "new game accel 0")
	m.free()


func _t_bounce_once() -> void:
	# 垂直落下撞擋板中央
	var m = _fresh()
	var b = _ball(m, Vector2(180, 700), Vector2.DOWN)
	_fall(m, b)
	_ok(b.dir.y < 0.0, "ball bounced up")
	_near(m.brick_accel, HIT, "one bounce = +0.005")
	_ok(m.paddle_flash > 0.0, "paddle flash on bounce")
	# 反彈後再跑 30 幀(球往上、仍在擋板附近的前幾幀)都不再加
	for i in 30:
		m._update_balls(FPS)
	_near(m.brick_accel, HIT, "after bounce, 30 more frames: still +0.005")
	# 反彈後的速度 = 240 × 1.005
	var p0: Vector2 = b.pos
	m._update_balls(FPS)
	_near((b.pos - p0).length(), 240.0 * 1.005 * FPS, "speed after bounce 241.2 px/s", 0.001)
	m.free()

	# 極小 dt 慢慢壓進擋板(多個子步/多幀重疊)也只加一次
	var m2 = _fresh()
	var b2 = _ball(m2, Vector2(180, 746.9), Vector2.DOWN)
	for i in 400:
		m2._update_balls(0.0005)
	_ok(b2.dir.y < 0.0, "tiny dt: bounced")
	_near(m2.brick_accel, HIT, "tiny dt 400 frames: +0.005 once")
	m2.free()

	# 已在擋板內、方向向上的球不加
	var m3 = _fresh()
	_ball(m3, Vector2(180, 752), Vector2.UP)
	for i in 10:
		m3._update_balls(FPS)
	_near(m3.brick_accel, 0.0, "overlapping but moving up: no accel")
	m3.free()

	# 各位置、各角度(擋板兩端、斜向)每次都只 +0.005
	var bad := 0
	var cnt := 0
	for x in [139.0, 150.0, 180.0, 210.0, 222.0]:
		for deg in [-50, -20, 0, 20, 50]:
			var mm = _fresh()
			var dir := Vector2.DOWN.rotated(deg_to_rad(deg))
			# 從擋板上方 60 px 沿反方向退回起點,讓落點落在 x
			var start: Vector2 = Vector2(x, 747.0) - dir * 60.0
			var bb = _ball(mm, start, dir)
			_fall(mm, bb)
			for i in 20:
				mm._update_balls(FPS)
			cnt += 1
			if not is_equal_approx(mm.brick_accel, HIT):
				bad += 1
				print("  bounce x=%.1f deg=%d accel=%.6f" % [x, deg, mm.brick_accel])
			mm.free()
	_eq(bad, 0, "%d positions/angles each +0.005 exactly" % cnt)

	# 球在擋板側邊(擋板橫移撞上往下的球)也只算 1 次
	var m4 = _fresh()
	m4.paddle_x = 100.0
	m4.target_x = 100.0
	var b4 = _ball(m4, Vector2(150.0, 758.0), Vector2.DOWN.rotated(deg_to_rad(10)))   # 擋板右緣 142.5 右邊
	m4.target_x = 200.0
	for i in 10:
		m4._step(FPS)
	_near(m4.brick_accel, HIT if b4.dir.y < 0.0 else 0.0, "side hit by moving paddle: at most once (dir.y %.3f)" % b4.dir.y)
	m4.free()


func _t_sticky() -> void:
	var m = _fresh()
	m._apply_item("sticky")
	var b = _ball(m, Vector2(180, 700), Vector2.DOWN)
	_fall(m, b)
	_ok(b.stuck, "sticky: ball stuck")
	_near(m.brick_accel, HIT, "sticky: sticking counts +0.005")
	# 黏住後擋板來回移動 600 幀(真實 _step,含拖曳輸入)
	for i in 600:
		_push_drag(60.0 if (i / 40) % 2 == 0 else -60.0)
		m._step(FPS)
	_ok(b.stuck, "still stuck after 600 frames of moving")
	_near(b.pos.x, m._paddle_center(m._paddle_len()) + b.offset, "stuck ball follows paddle")
	_near(m.brick_accel, HIT, "following paddle 600 frames: no extra accel")
	# 放開 → 飛走不加;飛回來再黏住 = 第 2 次碰撞 +0.005
	_push_touch(false)
	_ok(not b.stuck and b.dir.y < 0.0, "released upward")
	_near(m.brick_accel, HIT, "launch itself adds nothing")
	var caught := false
	for i in 1200:
		m.paddle_x = clampf(b.pos.x, 62.5, 297.5)
		m.target_x = m.paddle_x
		m._step(FPS)
		if b.stuck:
			caught = true
			break
	_ok(caught, "ball came back and stuck again")
	_near(m.brick_accel, HIT * 2, "second stick +0.005 (total 0.010)")
	m.free()


func _t_start_stuck() -> void:
	# 真實開局:場景自己生成的開局球(不清 balls)
	var m = MainScene.instantiate()
	root.add_child(m)
	m.time_left = 99999.0
	_eq(m.balls.size(), 1, "one start ball")
	var b = m.balls[0]
	_ok(b.stuck, "start ball stuck")
	for i in 600:
		_push_drag(80.0 if (i / 30) % 2 == 0 else -80.0)
		m._step(FPS)
	_ok(b.stuck, "start ball still stuck after 600 frames")
	_near(m.brick_accel, 0.0, "start stuck ball + paddle moving: no accel")
	# 多顆開局黏球(再生成 4 顆)也不加
	for i in 4:
		m._spawn_start_balls()
	for i in 120:
		_push_drag(-50.0 if (i / 20) % 2 == 0 else 50.0)
		m._step(FPS)
	_near(m.brick_accel, 0.0, "5 start stuck balls: no accel")
	# 開局有黏球、同時有吸附效果,也不加
	m._apply_item("sticky")
	for i in 60:
		m._step(FPS)
	_near(m.brick_accel, 0.0, "start stuck + sticky active: no accel")
	m.free()


func _t_blackhole() -> void:
	var m = _fresh()
	m.effects.add_timed("blackhole", 99999.0)
	var keep = _ball(m, Vector2(60, 300), Vector2(0.6, -0.8))   # 另一顆在場上,避免局結束
	var b = _ball(m, Vector2(180, 700), Vector2.DOWN)
	_fall(m, b)
	_ok(not m.balls.has(b), "blackhole: ball removed")
	_near(m.brick_accel, 0.0, "blackhole: no accel")
	# 黑洞 + 吸附同時:球被吸走,不加
	m._apply_item("sticky")
	var b2 = _ball(m, Vector2(200, 700), Vector2.DOWN)
	_fall(m, b2)
	_ok(not m.balls.has(b2), "blackhole + sticky: ball removed")
	_near(m.brick_accel, 0.0, "blackhole + sticky: no accel")
	# 多顆同幀被黑洞吸走
	for x in [145.0, 165.0, 185.0, 205.0]:   # 都落在擋板 138~223 內
		_ball(m, Vector2(x, 744), Vector2.DOWN)
	m._update_balls(FPS)
	_eq(m.balls.size(), 1, "4 balls swallowed in one frame")
	_near(m.brick_accel, 0.0, "4 balls blackhole same frame: no accel")
	m.free()
	# 黑洞到期後恢復計算
	var m2 = _fresh()
	m2._apply_item("blackhole")
	m2.effects.timed["blackhole"]["remaining"] = 0.001
	for e in m2.effects.tick(0.01):
		m2._on_expired(e)
	_ok(not m2.effects.is_active("blackhole"), "blackhole expired")
	var b3 = _ball(m2, Vector2(180, 700), Vector2.DOWN)
	_fall(m2, b3)
	_near(m2.brick_accel, HIT, "after blackhole expires: bounce +0.005")
	m2.free()


func _t_gun() -> void:
	# 開局黏球 + 槍:連射 3 秒(觸控按下開火,真實 _step)
	var m = _fresh()
	_stuck_ball(m)
	m._apply_item("gun")
	_brick(m, 3, 10, 69)
	_brick(m, 4, 10, 1, true)
	for i in 180:
		_push_touch(true)
		m._step(FPS)
	_ok(m.grid[10][3].layers < 69, "bullets hit breakable brick")
	_near(m.brick_accel, 0.0, "gun firing 3 s: no accel")
	m.free()
	# 有槍時球從槍管位置(擋板兩端)落下:只算擋板那 1 次
	for side in [0, 1]:
		var m2 = _fresh()
		m2._apply_item("gun")
		var length: int = m2._paddle_len()
		var left: int = m2._paddle_left(length)
		var gx: float = left + 8.0 if side == 0 else left + length - 8.0
		# 球心在槍管正上方、球底剛好進入槍管高度(py − 8 ~ py)
		var b = _ball(m2, Vector2(gx, m2._paddle_y() - 8.0 - MainScript.BALL_R + 2.0), Vector2.DOWN)
		_fall(m2, b)
		for i in 20:
			m2._update_balls(FPS)
		_near(m2.brick_accel, HIT, "gun barrel side %d: exactly one +0.005" % side)
		m2.free()


func _t_shared_cap() -> void:
	# 上限 1.0:99 次不可破壞磚(0.99)+ 擋板 3 次 → 0.995、1.0、1.0
	var m = _fresh()
	_brick(m, 3, 8, 1, true)
	for i in 99:
		_hit_from_below(m, Vector2i(3, 8))
	_near(m.brick_accel, 0.99, "99 unbreakable = 0.99")
	var exps := [0.995, 1.0, 1.0]
	for k in 3:
		var b = _ball(m, Vector2(180, 700), Vector2.DOWN)
		_fall(m, b)
		m.balls.erase(b)
		_near(m.brick_accel, exps[k], "paddle hit %d after bricks" % (k + 1))
	_ok(m.brick_accel <= 1.0, "never above 1.0")
	# 上限時再打磚也不超過
	_hit_from_below(m, Vector2i(3, 8))
	_eq(m.brick_accel, 1.0, "brick hit at cap stays 1.0")
	m.free()
	# 擋板 199 次 + 打磚 1 次(1%) → 1.0;再擋板 → 1.0
	var m2 = _fresh()
	_brick(m2, 3, 8, 1, true)
	for i in 199:
		var b = _ball(m2, Vector2(180, 740), Vector2.DOWN)
		_fall(m2, b)
		m2.balls.erase(b)
	_near(m2.brick_accel, 0.995, "199 paddle hits = 0.995", 1e-6)
	_hit_from_below(m2, Vector2i(3, 8))
	_eq(m2.brick_accel, 1.0, "+1% brick capped at 1.0")
	var b2 = _ball(m2, Vector2(180, 740), Vector2.DOWN)
	_fall(m2, b2)
	_eq(m2.brick_accel, 1.0, "paddle hit at cap stays 1.0")
	# 上限時球速 240 × 2.0 = 480
	var p0: Vector2 = b2.pos
	m2._update_balls(FPS)
	_near((b2.pos - p0).length(), 480.0 * FPS, "speed at cap 480 px/s", 0.001)
	m2.free()
	# 只靠擋板 400 次(到上限要 200 次):停在 1.0
	var m3 = _fresh()
	for i in 400:
		var b = _ball(m3, Vector2(180, 740), Vector2.DOWN)
		_fall(m3, b)
		m3.balls.erase(b)
	_ok(m3.brick_accel <= 1.0 and m3.brick_accel > 1.0 - 1e-9, "400 paddle hits capped at 1.0 (%.9f)" % m3.brick_accel)
	m3.free()


func _t_multi_same_frame() -> void:
	# 3 顆球同一幀撞擋板 → +0.015
	var m = _fresh()
	var xs := [150.0, 180.0, 210.0]
	var bs := []
	for x in xs:
		bs.append(_ball(m, Vector2(x, 744.0), Vector2.DOWN))
	m._update_balls(FPS)
	var up := 0
	for b in bs:
		if b.dir.y < 0.0:
			up += 1
	_eq(up, 3, "all 3 bounced in the same frame")
	_near(m.brick_accel, HIT * 3, "3 balls same frame: +0.015")
	m.free()
	# 20 顆同一幀 → +0.1
	var m2 = _fresh()
	m2.paddle_x = 180.0
	m2.target_x = 180.0
	# 2026-10-28:「擋板最大化」已移除;大幅增加 ×4 = 85 × 1.6^4 → 夾到 320 寬,放得下 20 顆
	for i in 4:
		m2._apply_item("paddle_len_2")
	_eq(m2._paddle_len(), 320, "paddle 320 wide for 20 balls")
	m2._update_paddle(0.0)
	var left: int = m2._paddle_left(m2._paddle_len())
	for i in 20:
		_ball(m2, Vector2(left + 8 + i * 15.0, 744.0), Vector2.DOWN)
	m2._update_balls(FPS)
	_near(m2.brick_accel, HIT * 20, "20 balls same frame: +0.1")
	m2.free()
	# 吸附中 3 顆同一幀黏住 → +0.015
	var m3 = _fresh()
	m3._apply_item("sticky")
	var cs := []
	for x in xs:
		cs.append(_ball(m3, Vector2(x, 744.0), Vector2.DOWN))
	m3._update_balls(FPS)
	_ok(cs[0].stuck and cs[1].stuck and cs[2].stuck, "3 balls stuck in same frame")
	_near(m3.brick_accel, HIT * 3, "3 sticks same frame: +0.015")
	for i in 120:
		_push_drag(30.0 if (i / 20) % 2 == 0 else -30.0)
		m3._step(FPS)
	_near(m3.brick_accel, HIT * 3, "3 stuck balls following paddle: still 0.015")
	m3.free()
	# 接近上限時同一幀 3 顆:0.99 → 1.0(不超過)
	var m4 = _fresh()
	m4.brick_accel = 0.99
	for x in xs:
		_ball(m4, Vector2(x, 744.0), Vector2.DOWN)
	m4._update_balls(FPS)
	_eq(m4.brick_accel, 1.0, "0.99 + 3 same frame capped at 1.0")
	m4.free()


## 逐幀來回打球:球 ↔ 頂牆(沒有磚),擋板每幀對準球(偏 +6 px 讓球斜飛會碰側牆)。
## 每次擋板碰撞後 accel = min(n × 0.005, 1.0);沒換方向的幀位移 = 速度 × dt。
func _rally(m, b, hits_wanted: int, tier: int) -> Dictionary:
	m.effects.ball_tier = tier
	var mult := 1.0 + 0.15 * tier
	var n := 0
	var bad_accel := 0
	var bad_speed := 0
	var frames := 0
	var lost := false
	while n < hits_wanted and frames < 200000:
		var pos0: Vector2 = b.pos
		var dir0: Vector2 = b.dir
		var acc0: float = m.brick_accel
		m.paddle_x = clampf(b.pos.x + 6.0, 62.5, 297.5)
		m.target_x = m.paddle_x
		m._step(FPS)
		frames += 1
		if not m.balls.has(b) or m.state != MainScript.State.PLAYING:
			lost = true
			break
		if dir0.y > 0.0 and b.dir.y < 0.0 and b.pos.y > 600.0:
			n += 1
			if not is_equal_approx(m.brick_accel, minf(n * HIT, 1.0)):
				bad_accel += 1
				if bad_accel <= 3:
					print("  rally hit %d accel %.6f" % [n, m.brick_accel])
		elif b.dir == dir0:
			# 沒碰撞的幀:accel 不變、位移 = 240 × 速度階 × (1 + accel) × dt
			var want := 240.0 * mult * (1.0 + acc0) * FPS
			if not is_equal_approx(m.brick_accel, acc0) or absf((b.pos - pos0).length() - want) > 0.001:
				bad_speed += 1
				if bad_speed <= 3:
					print("  rally frame %d moved %.5f want %.5f accel %.6f→%.6f" % [frames, (b.pos - pos0).length(), want, acc0, m.brick_accel])
	return {"n": n, "bad_accel": bad_accel, "bad_speed": bad_speed, "lost": lost, "frames": frames}


func _t_rally_base() -> void:
	var m = _fresh()
	var b = _ball(m, Vector2(180, 600), Vector2.DOWN)
	var r := _rally(m, b, 10, 0)
	_ok(not r.lost, "ball never lost (%d frames)" % r.frames)
	_eq(r.n, 10, "10 paddle hits")
	_eq(r.bad_accel, 0, "accel after each hit = n × 0.005")
	_eq(r.bad_speed, 0, "every free frame moves 240 × (1 + accel) × dt")
	_near(m.brick_accel, 0.05, "10 hits = 0.05")
	_near(m._ball_speed(), 252.0, "ball speed 252 px/s")
	m.free()


func _t_rally_to_cap() -> void:
	# 3.2 倍:速度階 +4(1.6)× 加速上限(2.0);打 210 次擋板,第 200 次到上限
	var m = _fresh()
	var b = _ball(m, Vector2(180, 600), Vector2.DOWN)
	var r := _rally(m, b, 210, 4)
	_ok(not r.lost, "ball never lost at up to 3.2x (%d frames)" % r.frames)
	_eq(r.n, 210, "210 paddle hits")
	_eq(r.bad_accel, 0, "accel after each hit = min(n × 0.005, 1.0)")
	_eq(r.bad_speed, 0, "every free frame moves 384 × (1 + accel) × dt")
	_eq(m.brick_accel, 1.0, "capped at 1.0")
	_near(m._ball_speed(), 768.0, "ball speed 768 px/s (3.2x)")
	m.free()


## 3.2 倍附近(起始 accel 0 / 0.995 / 1.0,速度階 +4)往下撞擋板:各角度各位置都接住,不穿過。
func _t_high_speed_paddle() -> void:
	for acc in [0.0, 0.995, 1.0]:
		for dt in [FPS, MainScript.MAX_DT]:
			for item in ["", "paddle_len_min"]:
				var missed := 0
				var deepest := 0.0
				var bad_acc := 0
				var total := 0
				for deg in range(-60, 61, 10):
					for k in 9:
						var m = _fresh()
						if item != "":
							# 2026-10-28:長度改走 add_paddle_len(共用計時),給足時間避免中途到期
							m.effects.add_paddle_len(item, m.cfg)
							m.effects.timed[Effects.PADDLE_LEN]["remaining"] = 99999.0
						m._update_paddle(0.0)
						m.effects.ball_tier = 4
						m.brick_accel = acc
						var len: int = m._paddle_len()
						var left: int = m._paddle_left(len)
						var py: int = m._paddle_y()
						var land_x := left + 1.0 + (len - 2.0) * k / 8.0
						var dir := Vector2.DOWN.rotated(deg_to_rad(deg))
						var start: Vector2 = Vector2(land_x, py - MainScript.BALL_R) - dir * 300.0
						if start.x < 28.0 or start.x > 332.0:
							m.free()
							continue
						var b = _ball(m, start, dir)
						total += 1
						var ok := false
						for f in 200:
							m._update_balls(dt)
							deepest = maxf(deepest, b.pos.y + MainScript.BALL_R - py)
							if b.dir.y < 0.0:
								ok = true
								break
							if b.pos.y > py + MainScript.PADDLE_H:
								break
						if not ok:
							missed += 1
						if not is_equal_approx(m.brick_accel, minf(acc + HIT, 1.0)):
							bad_acc += 1
						m.free()
				var tag := "acc %.3f dt %.3f %s" % [acc, dt, item if item != "" else "len85"]
				_eq(missed, 0, "%s: all %d balls bounced (none passed through)" % [tag, total])
				_ok(deepest < MainScript.PADDLE_H, "%s: max penetration %.3f < paddle height" % [tag, deepest])
				_eq(bad_acc, 0, "%s: each hit +0.005 (capped)" % tag)


# ---------- 擋板速度 450 ----------

func _t_paddle_speed_step() -> void:
	for t in range(-3, 5):
		var want := PADDLE_V * (1.0 + 0.15 * t)
		var m = _fresh()
		_stuck_ball(m)
		m.effects.paddle_tier = t
		# 往右:從左邊界出發,目標遠在右邊界,跑 6 幀(0.1 s)真實 _step
		m.paddle_x = 62.5
		m.target_x = 62.5
		_push_drag(1000)
		var per_frame_ok := true
		for i in 6:
			var x0: float = m.paddle_x
			m._step(FPS)
			per_frame_ok = per_frame_ok and absf((m.paddle_x - x0) - want * FPS) < 0.0001
		_ok(per_frame_ok, "tier %d right: each frame %.4f px" % [t, want * FPS])
		_near(m.paddle_x - 62.5, want * 0.1, "tier %d right: %.2f px/s measured over 0.1 s" % [t, want])
		# 往左
		m.paddle_x = 297.5
		m.target_x = 297.5
		_push_drag(-1000)
		for i in 6:
			m._step(FPS)
		_near(297.5 - m.paddle_x, want * 0.1, "tier %d left: %.2f px/s" % [t, want])
		m.free()
	# 道具改階後實際速度:+1 階 517.5
	var m2 = _fresh()
	_stuck_ball(m2)
	m2._apply_item("paddle_speed")
	m2.paddle_x = 62.5
	m2.target_x = 62.5
	_push_drag(1000)
	for i in 60:
		m2._step(FPS / 4.0)
	_near(m2.paddle_x - 62.5, 517.5 * 0.25, "item +1 tier: 517.5 px/s (0.25 s)")
	m2.free()


func _t_paddle_leftover() -> void:
	# 最慢 −3 階(247.5 px/s):手指一次滑 200 px,擋板逐幀追,剩下的位移保留到追上為止
	var m = _fresh()
	_stuck_ball(m)
	m.effects.paddle_tier = -3
	m.paddle_x = 80.0
	m.target_x = 80.0
	_push_drag(200)
	_near(m.target_x, 280.0, "target = 80 + 200")
	m._step(0.1)
	_near(m.paddle_x, 80.0 + 24.75, "after 0.1 s moved 24.75")
	_near(m.target_x, 280.0, "leftover kept in target")
	var frames := 0
	while m.paddle_x < 280.0 - 1e-6 and frames < 1000:
		m._step(FPS)
		frames += 1
	_near(m.paddle_x, 280.0, "eventually reached 280 (no loss)")
	# 200 − 24.75 = 175.25 px ÷ (247.5/60) = 42.49 → 43 幀
	_eq(frames, 43, "chase took 43 frames at 247.5 px/s")
	# 追的途中連續多次滑動:位移累加
	m.paddle_x = 100.0
	m.target_x = 100.0
	for i in 5:
		_push_drag(30)
		m._step(FPS)
	_near(m.target_x, 250.0, "5 drags of 30 accumulate to target 250")
	_near(m.paddle_x, 100.0 + 5 * 247.5 * FPS, "paddle moved 5 frames at 247.5")
	m.free()
	# 450 基本速度:滑 150 px,每幀 7.5 px,20 幀追上
	var m2 = _fresh()
	_stuck_ball(m2)
	m2.paddle_x = 100.0
	m2.target_x = 100.0
	_push_drag(150)
	var xs := []
	for i in 21:
		m2._step(FPS)
		xs.append(snappedf(m2.paddle_x, 0.0001))
	_near(xs[0], 107.5, "frame 1: 107.5")
	_near(xs[9], 175.0, "frame 10: 175")
	_near(xs[19], 250.0, "frame 20: reached 250")
	_near(xs[20], 250.0, "frame 21: stays 250")
	m2.free()
