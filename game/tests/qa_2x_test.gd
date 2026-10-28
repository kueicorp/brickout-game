## QA 獨立驗證:球、擋板原圖 2 倍;磚 40×20 以 1 倍(art/bricks40,D31)的尺寸、碰撞與邊界(headless)。
## 執行:Godot --headless --path game --script res://tests/qa_2x_test.gd
## 全部通過時結束碼 0;輸出不應出現 SCRIPT ERROR。
extends SceneTree

const MainScene := preload("res://scenes/main.tscn")
const MainScript := preload("res://scripts/main.gd")

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
	_run("art_sizes", _t_art_sizes)
	_run("grid_cells", _t_grid_cells)
	_run("walls", _t_walls)
	_run("brick_bounce", _t_brick_bounce)
	_run("paddle_bounce", _t_paddle_bounce)
	_run("leak", _t_leak)
	_run("gun_geometry", _t_gun_geometry)
	_run("bullet_columns", _t_bullet_columns)
	_run("drop_center_all", _t_drop_center_all)
	_run("edge_flame", _t_edge_flame)
	_run("edge_bomb", _t_edge_bomb)
	_run("edge_heal_area", _t_edge_heal_area)
	_run("edge_pierce", _t_edge_pierce)
	_run("start_balls", _t_start_balls)
	_run("brick_frames", _t_brick_frames)
	print("QA 2X RESULT: %d passed, %d failed" % [_passed, _failed])
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


func _fresh():
	var m = MainScene.instantiate()
	root.add_child(m)
	m.rng.seed = 4242
	for r in MainScript.MAX_ROWS:
		for c in MainScript.COLS:
			m.grid[r][c] = null
	m.breakable_left = 0
	m.items.clear()
	m.bullets.clear()
	m.score = 0
	m.balls.clear()
	m.paddle_x = 180.0
	m.target_x = 180.0
	m.view_h = 800
	_brick(m, 2, 0, 69)  # 哨兵
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


func _tex(name: String) -> Texture2D:
	return load("res://art/generated/%s.png" % name)


func _size(name: String) -> Vector2i:
	var t := _tex(name)
	return Vector2i(-1, -1) if t == null else Vector2i(t.get_width(), t.get_height())


# ---------- 原圖尺寸(畫的時候 × PX) ----------

## 40×20 規格(D31):art/bricks40 的 44 張都是 40×20,一張 = 一格(1 倍,不乘 PX)。
const BRICK_COLORS := ["red", "orange", "yellow", "green", "blue", "indigo", "purple"]


func _bricks40_names() -> Array:
	var out := []
	for c in BRICK_COLORS:
		out.append("d31_brick_" + c)
		for f in [1, 2, 3]:
			out.append("d31_brick_%s_f%d" % [c, f])
	for d in range(1, 10):
		out.append("d31_digit_%d" % d)
	out.append_array(["d31_brick_hit", "d31_brick_dust_f4", "d31_brick_unbreakable", "d31_brick_unbreakable_hit",
		"d31_invincible_frame", "d31_bomb_mark_f1", "d31_bomb_mark_f2"])
	return out


func _img40(name: String) -> Image:
	var t: Texture2D = load("res://art/bricks40/%s.png" % name)
	if t == null:
		return null
	var i := t.get_image()
	if i.is_compressed():
		i.decompress()
	return i


## 不透明像素(a > 0)的外框;沒有時回傳 size 0。
func _opaque_bbox(img: Image) -> Rect2i:
	var bb := Rect2i()
	var any := false
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.0:
				var p := Rect2i(x, y, 1, 1)
				bb = p if not any else bb.merge(p)
				any = true
	return bb


func _t_art_sizes() -> void:
	_eq(MainScript.PX, 2, "PX = 2 (ball / paddle only)")
	_eq([MainScript.BRICK_W, MainScript.BRICK_H], [40, 20], "brick cell 40x20 = art size x1")
	var names := _bricks40_names()
	_eq(names.size(), 44, "D31 list has 44 images")
	var bad := []
	for n in names:
		var img := _img40(n)
		if img == null or img.get_size() != Vector2i(40, 20):
			bad.append([n, img.get_size() if img != null else "missing"])
	_eq(bad, [], "all 44 art/bricks40 images exist and are 40x20")
	var files := Array(DirAccess.get_files_at("res://art/bricks40")).filter(func(f) -> bool: return f.ends_with(".png"))
	_eq(files.size(), 44, "art/bricks40 has exactly 44 png")
	# D31 疊加層的位置(欄、列從 0 起):數字 7×9 在第 16~22 欄、第 5~13 列;
	# 炸彈 F1 12×10 第 26~37 欄、第 6~15 列;F2 12×12 第 26~37 欄、第 4~15 列
	for d in range(1, 10):
		var bb := _opaque_bbox(_img40("d31_digit_%d" % d))
		_ok(bb.position.x >= 16 and bb.end.x <= 23 and bb.position.y >= 5 and bb.end.y <= 14, "digit %d inside cols 16-22 rows 5-13 (bbox %s)" % [d, bb])
	_eq(_opaque_bbox(_img40("d31_bomb_mark_f1")), Rect2i(26, 6, 12, 10), "bomb F1 bbox cols 26-37 rows 6-15")
	_eq(_opaque_bbox(_img40("d31_bomb_mark_f2")), Rect2i(27, 4, 11, 12), "bomb F2 bbox cols 27-37 rows 4-15")
	# 無敵外框:第 3~36 欄、第 3~16 列全透明,外框整張 40×20
	var inv := _img40("d31_invincible_frame")
	var inner_opaque := 0
	for y in range(3, 17):
		for x in range(3, 37):
			if inv.get_pixel(x, y).a > 0.0:
				inner_opaque += 1
	_eq(inner_opaque, 0, "invincible frame interior cols 3-36 rows 3-16 transparent")
	_eq(_opaque_bbox(inv), Rect2i(0, 0, 40, 20), "invincible frame covers full 40x20")
	# 球、擋板維持 2 倍
	_eq(_size("d15_ball_normal") * 2, Vector2i(16, 16), "ball 16x16")
	for n in ["d15_ball_opt_c_halo_f1", "d15_ball_opt_c_halo_f2", "d15_ball_vanish_f1", "d15_ball_vanish_f4"]:
		_eq(_size(n) * 2, Vector2i(28, 28), "%s 28x28 (drawn at center - 14)" % n)
	for k in ["normal", "sticky"]:
		_eq(_size("d13_paddle_%s_left" % k) * 2, Vector2i(16, 16), "%s left end 16x16" % k)
		_eq(_size("d13_paddle_%s_right" % k) * 2, Vector2i(16, 16), "%s right end 16x16" % k)
		_eq(_size("d13_paddle_%s_mid" % k) * 2, Vector2i(32, 16), "%s mid 32x16" % k)
	_eq(_size("d13_paddle_gun_left") * 2, Vector2i(16, 24), "gun left 16x24")
	_eq(_size("d13_paddle_gun_right") * 2, Vector2i(16, 24), "gun right 16x24")
	_eq(_size("d19_gun_muzzle_flash_f1") * 2, Vector2i(16, 8), "muzzle 16x8")
	_eq(_size("d19_bullet_laser_f1"), Vector2i(4, 8), "bullet stays 4x8")


# ---------- 格子 ----------

func _t_grid_cells() -> void:
	var m = _fresh()
	# 40×20 規格:8 欄 × 17 排,磚 40×20、無間隙,x 20~339、y 68~407
	_eq([m.grid.size(), m.grid[0].size()], [17, 8], "grid 17 rows x 8 cols")
	var wrong := 0
	for r in 17:
		for c in 8:
			var rc: Rect2 = m._cell_rect(Vector2i(c, r))
			if rc != Rect2(20 + 40 * c, 68 + 20 * r, 40, 20):
				wrong += 1
				_ok(false, "cell %d,%d = %s" % [c, r, rc])
	_eq(wrong, 0, "all 136 cells at (20 + 40c, 68 + 20r) 40x20")
	_eq(m._cell_rect(Vector2i(0, 0)), Rect2(20, 68, 40, 20), "first cell")
	_eq(m._cell_rect(Vector2i(7, 16)), Rect2(300, 388, 40, 20), "last cell (7,16) x 300..339 y 388..407")
	_ok(m._cell_rect(Vector2i(7, 16)).end.y <= MainScript.HUD_Y, "bricks end (408) above HUD row 1 (424)")
	# 實際關卡載入(level_test 為 8x17)
	var m2 = MainScene.instantiate()
	root.add_child(m2)
	_eq([m2.grid.size(), m2.grid[16].size()], [17, 8], "real level grid 17x8")
	m2.free()
	m.free()


# ---------- 牆 ----------

func _t_walls() -> void:
	var m = _fresh()
	var b = _ball(m, Vector2(27.9, 600), Vector2(-1, -1))
	m._ball_walls(b)
	_ok(b.pos.x == 28.0 and b.dir.x > 0.0, "left wall: center pushed to 28 (r 8), bounces")
	b = _ball(m, Vector2(28.0, 600), Vector2(-1, -1))
	var d0: Vector2 = b.dir
	m._ball_walls(b)
	_eq(b.dir, d0, "left wall: center 28 just touching, no bounce")
	b = _ball(m, Vector2(332.1, 600), Vector2(1, -1))
	m._ball_walls(b)
	_ok(b.pos.x == 332.0 and b.dir.x < 0.0, "right wall: center 332, bounces (ball px up to 339)")
	b = _ball(m, Vector2(180, 59.9), Vector2(0.3, -1))
	m._ball_walls(b)
	_ok(b.pos.y == 60.0 and b.dir.y > 0.0, "top wall: center 60 (52 + 8)")
	# 透過 _update_balls 實際跑:球從不穿出牆
	m.balls.clear()
	var b2 = _ball(m, Vector2(40, 300), Vector2(-1, -0.4))
	var minx := 999.0
	for i in 120:
		m._update_balls(1.0 / 60.0)
		minx = minf(minx, b2.pos.x)
	_ok(minx >= 28.0, "running: ball center never < 28 (min %.2f)" % minx)
	m.free()


# ---------- 磚反彈(半徑 8) ----------

func _t_brick_bounce() -> void:
	var m = _fresh()
	_brick(m, 1, 5, 10)
	var rc: Rect2 = m._cell_rect(Vector2i(1, 5))   # 40×20 規格:x 60..100, y 168..188
	# 下方
	var b = _ball(m, Vector2(rc.get_center().x, rc.end.y + 8.1), Vector2.UP)
	m._ball_bricks(b, false)
	_eq([_layers(m, 1, 5), b.dir], [10, Vector2.UP], "below 8.1 away: no hit")
	b.pos = Vector2(rc.get_center().x, rc.end.y + 7.9)
	m._ball_bricks(b, false)
	_ok(_layers(m, 1, 5) == 9 and b.dir.y > 0.0, "below 7.9 away: hit, bounce down")
	_ok(absf(b.pos.y - (rc.end.y + 8.0)) < 0.001, "pushed out to exactly r 8 (y %.3f)" % b.pos.y)
	# 上方
	b.pos = Vector2(rc.get_center().x, rc.position.y - 7.9)
	b.dir = Vector2.DOWN
	m._ball_bricks(b, false)
	_ok(_layers(m, 1, 5) == 8 and b.dir.y < 0.0, "above: hit, bounce up")
	# 左側
	b.pos = Vector2(rc.position.x - 7.9, rc.get_center().y)
	b.dir = Vector2(1, 0.3).normalized()
	m._ball_bricks(b, false)
	_ok(_layers(m, 1, 5) == 7 and b.dir.x < 0.0, "left side: hit, bounce left")
	# 右側
	b.pos = Vector2(rc.end.x + 7.9, rc.get_center().y)
	b.dir = Vector2(-1, 0.3).normalized()
	m._ball_bricks(b, false)
	_ok(_layers(m, 1, 5) == 6 and b.dir.x > 0.0, "right side: hit, bounce right")
	# 角落(對角距離 < 8 才碰到)
	b.pos = rc.end + Vector2(5.6, 5.6)   # 距離 7.92
	b.dir = Vector2(-1, -1).normalized()
	m._ball_bricks(b, false)
	_ok(_layers(m, 1, 5) == 5 and b.dir.x > 0.0 and b.dir.y > 0.0, "corner 7.92 away: hit, bounce back diagonally")
	b.pos = rc.end + Vector2(5.7, 5.7)   # 距離 8.06
	b.dir = Vector2(-1, -1).normalized()
	m._ball_bricks(b, false)
	_eq(_layers(m, 1, 5), 5, "corner 8.06 away: no hit")
	# 跑實際幀:球打最後一排磚後往下,不穿過
	m.balls.clear()
	# 40×20 規格:最後一排為第 16 排
	_brick(m, 3, 16, 50)
	var rl: Rect2 = m._cell_rect(Vector2i(3, 16))
	var b3 = _ball(m, Vector2(rl.get_center().x, rl.end.y + 30), Vector2.UP)
	var miny := 999.0
	for i in 30:
		m._update_balls(1.0 / 60.0)
		miny = minf(miny, b3.pos.y)
	_ok(_layers(m, 3, 16) == 49 and miny >= rl.end.y + 8.0 - 0.001, "running: ball stops at r 8 below bottom row (min y %.3f)" % miny)
	# 40×20 規格新增:兩塊相鄰磚的接縫(x 140)正下方打上去,一個子步只扣一塊、往下彈
	m.balls.clear()
	_brick(m, 2, 8, 10)
	_brick(m, 3, 8, 10)
	var seam: Rect2 = m._cell_rect(Vector2i(3, 8))
	var b4 = _ball(m, Vector2(seam.position.x, seam.end.y + 7.9), Vector2.UP)
	m._ball_bricks(b4, false)
	_ok(_layers(m, 2, 8) + _layers(m, 3, 8) == 19 and b4.dir.y > 0.0, "seam hit: exactly one brick -1, bounce down (%d, %d)" % [_layers(m, 2, 8), _layers(m, 3, 8)])
	m.free()


# ---------- 擋板反彈 ----------

func _t_paddle_bounce() -> void:
	var m = _fresh()
	var len: int = m._paddle_len()
	var left: int = m._paddle_left(len)
	var py: int = m._paddle_y()
	# 新規格:擋板 85、paddle_x 180 → 左緣 round(137.5) = 138,畫在 x 138..222,畫出來的中心 180.5
	_eq([len, left, py], [85, 138, 755], "paddle 85 at x 138..222, y 755")
	var cx := left + len / 2.0
	_eq(cx, 180.5, "drawn center 180.5 (paddle_x 180 + 0.5 for odd length)")
	var b = _ball(m, Vector2(180, py - 8.1), Vector2.DOWN)
	_ok(not m._ball_paddle(b, left, len, py) and b.dir == Vector2.DOWN, "8.1 above paddle: no hit")
	b.pos = Vector2(180, py - 7.9)
	m._ball_paddle(b, left, len, py)
	_ok(b.dir.y < 0.0 and b.pos.y == py - 8.0, "7.9 above: bounce, placed at py - 8")
	# 偏角:以畫出來的中心為準,中心垂直、兩端(半長 42.5)±60°、半長的一半 30°、超出端點仍夾在 60°
	for case in [[0.0, 0.0], [42.5, 60.0], [-42.5, -60.0], [21.25, 30.0], [-21.25, -30.0], [49.0, 60.0]]:
		b.pos = Vector2(cx + case[0], py - 4)
		b.dir = Vector2.DOWN
		m._ball_paddle(b, left, len, py)
		var deg := rad_to_deg(Vector2.UP.angle_to(b.dir))
		_ok(absf(deg - case[1]) < 0.01, "offset %+.2f -> %.0f deg (got %.2f)" % [case[0], case[1], deg])
	# 擋板側邊:球心在擋板左緣外 7.9、高度在本體內 → 碰到
	b.pos = Vector2(left - 7.9, py + 8)
	b.dir = Vector2(1, 1).normalized()
	_ok(m._circle_rect(b.pos, Rect2(left, py, len, 16)).z > 0.0, "side contact within r 8")
	# 碰撞高度只算本體 16(槍管 8 不算):有槍時球在本體上方 8~16 px 仍不碰到
	m._apply_item("gun")
	b.pos = Vector2(left + 8, py - 12)   # 槍管所在高度(py-8..py),球下緣 py-4
	b.dir = Vector2.DOWN
	_ok(not m._ball_paddle(b, left, len, py), "gun barrel area is not collision")
	_ok(b.dir == Vector2.DOWN, "no bounce from barrel")
	# 擋板下方 16 px 內(本體高 16):球從下往上不碰(dir.y <= 0 忽略)
	b.pos = Vector2(180, py + 10)
	b.dir = Vector2.UP
	_ok(not m._ball_paddle(b, left, len, py), "ball moving up through paddle ignored")
	# 跑實際幀:球從上方落到擋板反彈
	m.balls.clear()
	var b2 = _ball(m, Vector2(180, py - 60), Vector2.DOWN)
	var maxy := 0.0
	for i in 30:
		m._update_balls(1.0 / 60.0)
		maxy = maxf(maxy, b2.pos.y)
	_ok(b2.dir.y < 0.0 and maxy <= py - 8.0 + 0.001, "running: ball rebounds at py - 8 (max y %.3f)" % maxy)
	m.free()


# ---------- 漏球 ----------

func _t_leak() -> void:
	for h in [800, 640]:
		var m = _fresh()
		m.view_h = h
		m.paddle_x = 60.0
		var b = _ball(m, Vector2(300, h + 7.0), Vector2.DOWN)
		m._update_balls(0.004)   # 移動 0.96 → 7.96,上緣仍在畫面內
		_eq(m.balls.size(), 1, "h%d: top edge still on screen -> kept" % h)
		m._update_balls(0.004)   # 8.92 → 上緣 h + 0.92
		_eq(m.balls.size(), 0, "h%d: top edge below view_h -> removed" % h)
		var v: Array = m.anims.filter(func(a) -> bool: return a["kind"] == "vanish")
		_ok(v.size() == 1 and v[0]["pos"].y == h - 14, "h%d: vanish anim center at view_h - 14 (bottom at view_h)" % h)
		# 擋板正下方漏過去(沒碰到):在擋板外側掉下
		m._step(0.016)
		_eq(m.state, 1, "h%d: no balls -> lose" % h)
		m.free()
	# 擋板邊緣接球:球心在擋板右端外 7.9 仍接到
	var m2 = _fresh()
	var len: int = m2._paddle_len()
	var left: int = m2._paddle_left(len)
	var py: int = m2._paddle_y()
	var b2 = _ball(m2, Vector2(left + len + 7.0, py - 2), Vector2.DOWN)
	_ok(not m2._ball_paddle(b2, left, len, py) and b2.dir.y < 0.0, "edge catch: center 7 px right of paddle end -> bounce")
	b2.pos = Vector2(left + len + 8.5, py + 4)
	b2.dir = Vector2.DOWN
	m2._ball_paddle(b2, left, len, py)
	_eq(b2.dir, Vector2.DOWN, "8.5 px right of paddle: miss")
	m2.free()


# ---------- 槍 ----------

## 從槍端原圖找砲管欄位(上方 4 列中不透明的欄),乘 2 得到放大後的砲管範圍。
func _barrel_cols(name: String) -> Vector2i:
	var img := _tex(name).get_image()
	if img.is_compressed():
		img.decompress()
	var lo := 99
	var hi := -1
	for y in 4:
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.0:
				lo = mini(lo, x)
				hi = maxi(hi, x)
	return Vector2i(lo, hi)


func _t_gun_geometry() -> void:
	var lc := _barrel_cols("d13_paddle_gun_left")
	var rc := _barrel_cols("d13_paddle_gun_right")
	print("INFO gun barrel source cols: left %s, right %s" % [lc, rc])
	# 2026-10-28:「擋板最大化」已移除;"max" = 大幅增加 ×4(85 × 1.6^4 → 夾到 320)
	for length_item in ["", "paddle_len_min", "paddle_len_down_2", "paddle_len_2", "max"]:
		var m = _fresh()
		m._apply_item("gun")
		if length_item == "max":
			for i in 4:
				m._apply_item("paddle_len_2")
			_eq(m._paddle_len(), 320, "max: 4 x paddle_len_2 -> 320")
		elif length_item != "":
			m._apply_item(length_item)
		var len: int = m._paddle_len()
		m.paddle_x = 20.0 + len / 2.0 if len == 320 else 180.0
		var left: int = m._paddle_left(len)
		var py: int = m._paddle_y()
		m._fire_gun()
		_eq(m.bullets.size(), 2, "len %d: 2 bullets" % len)
		if m.bullets.size() != 2:
			m.free()
			continue
		var ends := [[left, lc], [left + len - 16, rc]]
		for k in 2:
			var gun_left: int = ends[k][0]
			var cols: Vector2i = ends[k][1]
			var barrel_center := gun_left + (cols.x * 2 + (cols.y + 1) * 2) / 2.0
			var bl: Vector2 = m.bullets[k]
			_ok(is_equal_approx(bl.x + 2.0, barrel_center), "len %d gun %d: bullet center x %.1f = barrel center %.1f" % [len, k, bl.x + 2.0, barrel_center])
			_eq(bl.y, float(py - 16), "len %d gun %d: bullet top = py - 16 (above 8 px barrel)" % [len, k])
			_ok(bl.x >= gun_left + cols.x * 2 and bl.x + 4 <= gun_left + (cols.y + 1) * 2, "len %d gun %d: bullet inside barrel width" % [len, k])
		var mz: Array = m.anims.filter(func(a) -> bool: return a["kind"] == "muzzle")
		_eq(mz.size(), 2, "len %d: 2 muzzle flashes" % len)
		if mz.size() == 2:
			_eq([mz[0]["pos"], mz[1]["pos"]], [Vector2(left, py - 16), Vector2(left + len - 16, py - 16)], "len %d: muzzle 16x8 right above barrel (y py-16..py-9)" % len)
		_ok(left >= 20 and left + len <= 340, "len %d: paddle inside field" % len)
		m.free()


## 子彈的判定點跨欄(40×20 規格:40 寬)時,打到正確的欄;最後一排是第 16 排。
func _t_bullet_columns() -> void:
	var m = _fresh()
	for c in 8:
		_brick(m, c, 16, 5)
	var bottom := 68 + 17 * 20   # 408
	# 判定點 x+1、x+2;x = 58 → 59/60,左右分屬第 0 / 1 欄的邊界(第 1 欄從 60 起)
	for case in [[20.0, [0]], [57.0, [0]], [58.0, [0, 1]], [59.0, [1]], [178.0, [3, 4]], [298.0, [6, 7]], [334.0, [7]]]:
		var hit: Vector3i = m._bullet_trace(case[0], bottom + 2, bottom - 8)
		_ok(hit.x in case[1] and hit.y == 16 and hit.z == bottom, "bullet x %.0f -> col %s (got %s)" % [case[0], case[1], hit])
	var miss: Vector3i = m._bullet_trace(340.0, bottom + 2, bottom - 8)
	_eq(miss.x, -1, "x 340 (outside field) -> no column")
	# 實際從擋板發射:每一欄的最後一排都打得到(只扣 1 層)
	for c in 8:
		var m2 = _fresh()
		_brick(m2, c, 16, 5)
		m2.bullets.append(Vector2(20 + 40 * c + 18, 700))
		for i in 60:
			m2._update_bullets(1.0 / 60.0)
		_eq([_layers(m2, c, 16), m2.bullets.size()], [4, 0], "bullet from y 700 hits last row col %d" % c)
		m2.free()
	m.free()


# ---------- 道具掉落起點 ----------

func _t_drop_center_all() -> void:
	cfg.debug_force_item = "slow"
	var m = _fresh()
	var bad := []
	# 40×20 規格:8 × 17 = 136 格,扣掉哨兵 (2, 0) = 135 格
	for r in 17:
		for c in 8:
			if c == 2 and r == 0:
				continue
			m.items.clear()
			_brick(m, c, r, 1)
			m._ball_hit_brick(Vector2i(c, r))
			if m.items.size() != 1:
				bad.append([c, r, "no drop"])
				continue
			var ir: Rect2 = m._item_rect(m.items[0]["pos"])
			# D32 items40:道具改 40×40 1 倍(原 16×16 2 倍 = 32×32);中心仍須 = 磚中心
			if ir.get_center() != m._cell_rect(Vector2i(c, r)).get_center() or ir.size != Vector2(40, 40):
				bad.append([c, r, ir])
	_eq(bad, [], "all 135 cells: 40x40 item centered on brick")
	cfg.debug_force_item = ""
	m.free()


# ---------- 8 欄 × 17 排邊界(40×20 規格) ----------

func _fill(m, layers: int) -> void:
	for r in 17:
		for c in 8:
			m.grid[r][c] = null
	m.breakable_left = 0
	for r in 17:
		for c in 8:
			_brick(m, c, r, layers)


func _count_changed(m, layers: int) -> Array:
	var out := []
	for r in 17:
		for c in 8:
			if _layers(m, c, r) != layers:
				out.append(Vector2i(c, r))
	return out


func _expect_cells(center: Vector2i) -> Array:
	var out := []
	for r in 17:
		for c in 8:
			if absi(c - center.x) <= 1 and absi(r - center.y) <= 1:
				out.append(Vector2i(c, r))
	return out


## 第 0 欄、第 7 欄、第 16 排(含四角)與第 0 排、中間
const EDGES := [Vector2i(0, 0), Vector2i(7, 0), Vector2i(0, 16), Vector2i(7, 16), Vector2i(0, 8), Vector2i(7, 8), Vector2i(3, 16), Vector2i(4, 0)]


func _t_edge_flame() -> void:
	for cell in EDGES:
		var m = _fresh()
		_fill(m, 10)
		m._apply_item("flame")
		m._ball_hit_brick(cell)
		var changed := _count_changed(m, 10)
		_eq(changed, _expect_cells(cell), "flame at %s: exactly in-range 3x3 changed" % cell)
		_eq(_layers(m, cell.x, cell.y), 8, "flame at %s: center -2" % cell)
		for n in m._neighbors(cell):
			if _layers(m, n.x, n.y) != 9:
				_ok(false, "flame at %s neighbor %s = %d" % [cell, n, _layers(m, n.x, n.y)])
		m.free()


func _t_edge_bomb() -> void:
	for cell in EDGES:
		var m = _fresh()
		_fill(m, 10)
		m._apply_item("bomb")
		m._ball_hit_brick(cell)
		_expire_all(m)
		_eq(_count_changed(m, 10), _expect_cells(cell), "bomb at %s: exactly in-range 3x3 changed" % cell)
		_eq(_layers(m, cell.x, cell.y), -999, "bomb at %s: marked destroyed" % cell)
		var nb_ok := true
		for n in m._neighbors(cell):
			nb_ok = nb_ok and _layers(m, n.x, n.y) == 8
		_ok(nb_ok, "bomb at %s: neighbors -2" % cell)
		m.free()
	# 兩個標記在最左與最右欄同時爆炸
	var m2 = _fresh()
	_fill(m2, 10)
	m2._apply_item("bomb")
	m2._ball_hit_brick(Vector2i(0, 3))
	m2._ball_hit_brick(Vector2i(7, 3))
	_expire_all(m2)
	_eq([_layers(m2, 0, 3), _layers(m2, 7, 3), _layers(m2, 1, 3), _layers(m2, 6, 3), _layers(m2, 2, 3), _layers(m2, 5, 3)], [-999, -999, 8, 8, 10, 10], "bombs at col 0 & 7 together (40x20: 8 cols)")
	# 炸彈標記期間被標記的磚用同色第 0 輪底圖(無數字)
	var m3 = _fresh()
	_brick(m3, 7, 16, 30)
	m3._apply_item("bomb")
	m3._ball_hit_brick(Vector2i(7, 16))
	var br = m3.grid[16][7]
	_ok(br.marked and Rules.brick_art(Rules.sheet_row(br.layers, br.marked)) == ["d31_brick_orange", ""], "marked 30-layer brick draws orange round-0 without digit")
	_eq(Rules.brick_art(br.hit_row), ["d31_brick_orange", "d31_digit_4"], "marking hit frame shows pre-mark digit 4")
	m3.free()
	m2.free()


func _t_edge_heal_area() -> void:
	for cell in EDGES:
		var m = _fresh()
		_fill(m, 10)
		m._apply_item("heal_area")
		m._ball_hit_brick(cell)
		_eq(_count_changed(m, 10), _expect_cells(cell), "heal_area at %s: exactly in-range 3x3 changed" % cell)
		_eq(_layers(m, cell.x, cell.y), 12, "heal_area at %s: center +2" % cell)
		m.free()


func _t_edge_pierce() -> void:
	# 球在最右欄/最左欄、貼著牆,穿透進入與結束都不越界
	# 40×20 規格:四角 (0,0)、(7,0)、(0,16)、(7,16);球心貼牆時圓(x 20..36 / 324..340、高 16)只落在這一格(40×20)內
	for cell in [Vector2i(0, 0), Vector2i(7, 0), Vector2i(0, 16), Vector2i(7, 16)]:
		var m = _fresh()
		_fill(m, 10)
		var rc: Rect2 = m._cell_rect(cell)
		# 球心貼牆(28 / 332)、在格子垂直中央:圓只落在這一格內
		var x := 28.0 if cell.x == 0 else 332.0
		var b = _ball(m, Vector2(x, rc.get_center().y), Vector2(0.3, -1))
		m._apply_item("pierce")
		m._ball_bricks(b, m._pierce_on())
		_eq(_count_changed(m, 10), [cell], "pierce enter at %s: only that brick -1" % cell)
		_expire_all(m)
		_eq(_layers(m, cell.x, cell.y), -999, "pierce end at %s: brick under ball destroyed" % cell)
		_eq(_count_changed(m, 10), [cell], "pierce end at %s: nothing else touched" % cell)
		m.free()
	# 實際跑幀:穿透球貼右牆往上穿過整欄
	var m2 = _fresh()
	_fill(m2, 1)
	m2.grid[0][2] = null
	m2.breakable_left -= 1
	_brick(m2, 2, 0, 69)
	m2._apply_item("pierce")
	var b2 = _ball(m2, Vector2(332, 440), Vector2(0.05, -1))
	for i in 120:
		m2._update_balls(1.0 / 60.0)
		# 40×20 規格:欄只有 40 寬,碰頂往回後球會慢慢往左偏,碰頂就停(只驗往上這一趟)
		if m2.state != 0 or b2.dir.y > 0.0:
			break
	# 40×20 規格:最右欄是第 7 欄、17 排;第 6 欄不應被碰到
	var col7 := []
	var col6 := []
	for r in 17:
		col7.append(_layers(m2, 7, r))
		col6.append(_layers(m2, 6, r))
	_ok(col7.all(func(v) -> bool: return v == -999), "running pierce along right wall clears col 7: %s" % [col7])
	_ok(col6.all(func(v) -> bool: return v == 1), "running pierce along right wall leaves col 6: %s" % [col6])
	m2.free()


func _expire_all(m) -> void:
	for id in m.effects.tick(9999.0):
		m._on_expired(id)


# ---------- D31 幀時間(40×20 規格新增) ----------

## 被擊中幀 60 ms;破壞 = 被擊中 1 幀 + F1~F4 各 60 ms(共 300 ms),顏色取破壞當下;不可破壞磚被擊中 60 ms。
func _t_brick_frames() -> void:
	var m = _fresh()
	_brick(m, 7, 16, 20)
	m._ball_hit_brick(Vector2i(7, 16))
	var br = m.grid[16][7]
	_ok(is_equal_approx(br.hit_t, 0.06) and br.hit_row == 19, "hit: 60 ms, pre-damage row 19 (hit_t %.3f)" % br.hit_t)
	m._update_anims(0.059)
	_ok(br.hit_t > 0.0, "hit frame still shown at 59 ms")
	m._update_anims(0.002)
	_ok(br.hit_t <= 0.0, "hit frame gone after 61 ms")
	# 破壞:3 層黃磚被強化 +7 一次打掉
	m.anims.clear()
	_brick(m, 0, 16, 3)
	m.effects.reinforce = 7
	m._ball_hit_brick(Vector2i(0, 16))
	var a: Array = m.anims.filter(func(x) -> bool: return x["kind"] == "break")
	_eq(a.size(), 1, "one break anim")
	if a.size() == 1:
		_eq([a[0]["pos"], a[0]["hit_row"], a[0]["color"]], [Vector2(20, 388), 2, 2], "break anim at cell (0,16), hit row = 3 layers, color yellow")
		_ok(is_equal_approx(a[0]["dur"], 0.3), "break total 5 x 60 ms = 300 ms (dur %.3f)" % a[0]["dur"])
		var frames := []
		for t in [0.0, 0.059, 0.061, 0.119, 0.121, 0.179, 0.181, 0.239, 0.241, 0.299]:
			frames.append(int(t / MainScript.FRAME))
		_eq(frames, [0, 0, 1, 1, 2, 2, 3, 3, 4, 4], "frame index by time: hit, F1, F2, F3, F4 (60 ms each)")
		m._update_anims(0.299)
		_eq(m.anims.filter(func(x) -> bool: return x["kind"] == "break").size(), 1, "break still playing at 299 ms")
		m._update_anims(0.002)
		_eq(m.anims.filter(func(x) -> bool: return x["kind"] == "break").size(), 0, "break removed after 300 ms")
	m.effects.reinforce = 0
	# 不可破壞磚被擊中:換火花圖 60 ms,層數不變
	var ub = _brick(m, 3, 16, 1, true)
	m._ball_hit_brick(Vector2i(3, 16))
	_ok(is_equal_approx(ub.hit_t, 0.06) and m.grid[16][3] == ub, "unbreakable hit: 60 ms spark frame, brick stays")
	m.free()


# ---------- 開局球 ----------

func _t_start_balls() -> void:
	for n in [1, 7]:
		cfg.debug_start_balls = n
		var m = MainScene.instantiate()
		root.add_child(m)
		var len: int = m._paddle_len()
		var left: int = m._paddle_left(len)
		var ok := true
		for b in m.balls:
			ok = ok and b.pos.y == m._paddle_y() - 8 and b.pos.x - 8 >= left and b.pos.x + 8 <= left + len
		_ok(ok, "%d start balls sit on paddle (bottom = paddle top, inside length)" % n)
		# 新規格:開局球以畫出來的中心為準(85 為奇數,中心 = 左緣 + 42.5),多顆時左右對稱
		var cx := left + len / 2.0
		var sum := 0.0
		for b in m.balls:
			sum += b.pos.x
		_ok(is_equal_approx(sum / m.balls.size(), cx), "%d start balls centered on drawn center %.1f (mean x %.2f)" % [n, cx, sum / m.balls.size()])
		m._update_balls(1.0 / 60.0)
		sum = 0.0
		for b in m.balls:
			sum += b.pos.x
		_ok(is_equal_approx(sum / m.balls.size(), cx), "%d start balls still centered after a frame" % n)
		m.free()
	cfg.debug_start_balls = 1
