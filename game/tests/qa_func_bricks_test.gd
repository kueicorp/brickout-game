## QA 獨立驗證:6 種功能型磚(雷射 H/V/X、閃電、死神、爆炸、彩虹、傳送)。
## 規格以 PM 轉達的「使用者確認的規則」與 brick-size.md D38「給工程師的需求」為準。
## 執行:Godot --headless --path game --script res://tests/qa_func_bricks_test.gd
## 全部通過時結束碼 0,有失敗時結束碼 1。以 INFO 開頭的輸出是觀察紀錄(規格未定的行為),不算失敗。
extends SceneTree

const MainScript := preload("res://scripts/main.gd")
const MainScene := preload("res://scenes/main.tscn")
const CONFIG := "res://data/game_config.tres"
const FUNC_LEVEL := "res://data/levels/level_func_test.json"
const COUNTED := ["laser_h", "laser_v", "laser_x", "lightning", "reaper"]
const ALL_KINDS := ["laser_h", "laser_v", "laser_x", "lightning", "reaper", "explosion", "rainbow", "teleport"]

var _passed := 0
var _failed := 0
var _section := ""


func _init() -> void:
	_sec("parse", _t_parse)
	_sec("load", _t_load)
	_sec("common", _t_common)
	_sec("bullets", _t_bullets)
	_sec("laser", _t_laser)
	_sec("lightning", _t_lightning)
	_sec("reaper", _t_reaper)
	_sec("explosion", _t_explosion)
	_sec("rainbow", _t_rainbow)
	_sec("teleport", _t_teleport)
	_sec("invincible", _t_invincible)
	_sec("win", _t_win)
	_sec("config", _t_config)
	_sec("observe", _t_observe)
	_sec("fix_b1_rainbow_420", _t_fix_b1)
	_sec("fix_b1_regress_break", _t_fix_b1_regress)
	_sec("fix_b2_teleport_removed", _t_fix_b2)
	await process_frame
	_section = "autoplay"
	await _t_autoplay()
	print("QA FUNC BRICKS RESULT: %d passed, %d failed" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _sec(name: String, f: Callable) -> void:
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


# ---------- 輔助 ----------

## 不進場景樹的主程式 + 空格子;breakable_left 由各測試自己決定。
func _mk(seed := 11) -> Node2D:
	var m: Node2D = MainScript.new()
	m.cfg = (load(CONFIG) as GameConfig).duplicate()
	m.rng.seed = seed
	m.grid = []
	for r in MainScript.MAX_ROWS:
		var row := []
		row.resize(MainScript.COLS)
		m.grid.append(row)
	return m


func _layer(m: Node2D, cell: Vector2i, layers: int) -> Object:
	var br = MainScript.Brick.new()
	br.layers = layers
	m.grid[cell.y][cell.x] = br
	m.breakable_left += 1
	return br


func _unb(m: Node2D, cell: Vector2i) -> Object:
	var br = MainScript.Brick.new()
	br.unbreakable = true
	m.grid[cell.y][cell.x] = br
	return br


func _fn(m: Node2D, cell: Vector2i, kind: String, uses := 1) -> Object:
	var br = MainScript.Brick.new()
	br.kind = kind
	br.uses = uses
	m.grid[cell.y][cell.x] = br
	if kind != "teleport":
		m.breakable_left += 1
	return br


func _ball(m: Node2D, pos: Vector2, dir: Vector2) -> Object:
	var b = MainScript.Ball.new()
	b.pos = pos
	b.dir = dir.normalized()
	m.balls.append(b)
	return b


## 只推進動畫與延遲效果(每步 10 ms)。回傳期間新建立的各種動畫數量。
func _run(m: Node2D, secs: float) -> Dictionary:
	var made := {}
	for i in roundi(secs / 0.01):
		m._update_anims(0.01)
		m._update_events(0.01)
		for a in m.anims:
			if a["t"] == 0.0:
				made[a["kind"]] = made.get(a["kind"], 0) + 1
	return made


func _count(m: Node2D, kind: String) -> int:
	return m.anims.filter(func(a: Dictionary) -> bool: return a["kind"] == kind).size()


func _pos(cell: Vector2i) -> Vector2:
	return Vector2(20 + cell.x * 40, 68 + cell.y * 20)


## 子彈 x:判定點 x+1、x+2 落在第 c 欄。
func _bx(c: int) -> float:
	return 20 + c * 40 + 5


# ---------- 關卡格式 ----------

func _t_parse() -> void:
	var F := Rules.FUNC
	var p := Rules.parse_level({"rows": ["LH LV LX Z R E W T", "LH1 LV9 LX5 Z1 R9 . . T"]}, 17, 8, 69)
	_eq(p["errors"].size(), 0, "all 8 codes + counted variants valid")
	_eq(p["cells"][0], [F, F, F, F, F, F, F, F] as Array[int], "row 0 all function")
	var kinds := []
	for c in 8:
		kinds.append(p["funcs"][Vector2i(c, 0)]["kind"])
	_eq(kinds, ALL_KINDS, "LH LV LX Z R E W T -> kinds")
	var uses := []
	for c in 5:
		uses.append(p["funcs"][Vector2i(c, 1)]["uses"])
	_eq(uses, [1, 9, 5, 1, 9], "explicit counts LH1 LV9 LX5 Z1 R9")
	_eq(p["funcs"][Vector2i(0, 0)]["uses"], 0, "no count = 0 (random later)")
	# 不合法:0、兩位數、沒有次數的種類加數字、小寫、組合字
	# (D39 起 "H" 是寶箱代號,原本的 "H" 改用不屬任何代號的 "Q")
	var bad := Rules.parse_level({"rows": ["LH0 LH10 LH55 E1 W1 T1 lh Lh", "Z0 R10 X L Q EW TT LHX"]}, 17, 8, 69)
	_eq(bad["errors"].size(), 16, "16 invalid tokens reported")
	_eq(bad["funcs"].size(), 0, "no invalid token becomes a function brick")
	_eq(bad["cells"][0] + bad["cells"][1], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] as Array[int], "invalid -> empty")
	# 奇數傳送磚:丟最後一塊(由上到下、由左到右)並記 1 個錯誤
	var one := Rules.parse_level({"rows": ["T . . . . . . ."]}, 17, 8, 69)
	_eq([one["errors"].size(), one["funcs"].size(), one["cells"][0][0]], [1, 0, 0], "1 teleport: dropped")
	var three := Rules.parse_level({"rows": [". . . . . . . T", "T . . . . . . .", ". . . T . . . ."]}, 17, 8, 69)
	_eq([three["errors"].size(), three["funcs"].has(Vector2i(3, 2)), three["funcs"].has(Vector2i(7, 0)),
		three["funcs"].has(Vector2i(0, 1)), three["cells"][2][3]], [1, false, true, true, 0], "3 teleports: last in reading order dropped")
	var five := Rules.parse_level({"rows": ["T T T T T . . ."]}, 17, 8, 69)
	_eq([five["errors"].size(), five["funcs"].size(), five["funcs"].has(Vector2i(4, 0))], [1, 4, false], "5 teleports -> 4")
	# 超過 max_rows 的排裡的傳送磚不算
	var rows := []
	for r in 17:
		rows.append(". . . . . . . .")
	rows[0] = "T . . . . . . T"
	rows.append("T . . . . . . .")
	var cut := Rules.parse_level({"rows": rows}, 17, 8, 69)
	_eq(cut["funcs"].size(), 2, "teleport in ignored 18th row not counted")
	# 多層磚 / 不可破壞磚照舊
	var mix := Rules.parse_level({"rows": ["1 69 U . LH3 70 0 Z"]}, 17, 8, 69)
	_eq([mix["cells"][0], mix["errors"].size()], [[1, 69, -1, 0, F, 0, 0, F] as Array[int], 2], "layered / U unchanged, 70 and 0 rejected")


func _t_load() -> void:
	# level_func_test.json:格式、6 種(8 代號)都在、U 2~3、傳送成對
	var data = (load(FUNC_LEVEL) as JSON).data
	var p := Rules.parse_level(data, 17, 8, 69)
	_eq(p["errors"].size(), 0, "level_func_test parses without errors")
	var seen := {}
	var tele := 0
	var expect_left := 0
	for k in p["funcs"]:
		seen[p["funcs"][k]["kind"]] = true
		if p["funcs"][k]["kind"] == "teleport":
			tele += 1
	var u := 0
	for line in p["cells"]:
		for v in line:
			if v == Rules.UNBREAKABLE:
				u += 1
			elif v != 0:
				expect_left += 1
	expect_left -= tele
	_eq(seen.keys().size(), 8, "all 8 function codes present")
	_ok(u >= 2 and u <= 3, "2~3 unbreakable (%d)" % u)
	_ok(tele >= 2 and tele % 2 == 0, "teleports even (%d)" % tele)
	# 不檢查設定檔預設的 level_path(使用者試玩時會改);測試自己指定關卡
	var lt := Rules.parse_level((load("res://data/levels/level_test.json") as JSON).data, 17, 8, 69)
	_eq([lt["errors"].size(), lt["funcs"].size()], [0, 0], "level_test.json has no function bricks")
	# 載入:勝利計數、隨機次數 1~9 全涵蓋、指定次數照指定
	var values := {}
	var out_of_range := 0
	var explicit_ok := true
	var left_ok := true
	var other_ok := true
	for s in 300:
		var m := _mk(s)
		m.grid = []
		m.cfg.level_path = FUNC_LEVEL
		m._load_level()
		left_ok = left_ok and m.breakable_left == expect_left
		for k in p["funcs"]:
			var br = m.grid[k.y][k.x]
			var f: Dictionary = p["funcs"][k]
			if f["kind"] in COUNTED:
				if f["uses"] > 0:
					explicit_ok = explicit_ok and br.uses == f["uses"]
				else:
					values[br.uses] = true
					if br.uses < 1 or br.uses > 9:
						out_of_range += 1
			elif f["kind"] in ["explosion", "rainbow"]:
				other_ok = other_ok and br.uses == 1
		m.free()
	_eq(left_ok, true, "breakable_left = layered + function (no teleport) = %d" % expect_left)
	_eq([out_of_range, values.size()], [0, 9], "random uses always 1~9 and every value appears over 300 loads")
	_eq(explicit_ok, true, "explicit counts kept on load")
	_eq(other_ok, true, "explosion / rainbow load with 1 use")


# ---------- 共通 ----------

func _t_common() -> void:
	# 強化 7、火焰:計數型磚每碰 1 次只扣 1;火焰 3×3 波及不動功能型磚
	for k in COUNTED:
		var m := _mk()
		m.breakable_left += 100
		var br = _fn(m, Vector2i(3, 16), k, 5)   # 最下排,雷射 / 閃電沒有其他磚可打
		m.effects.reinforce = 7
		m.effects.add_timed("flame", 20.0)
		var ball = _ball(m, Vector2(0, 0), Vector2.UP)
		m._ball_hit_brick(Vector2i(3, 16), ball)
		_eq(br.uses, 4, "%s: reinforce + flame still -1" % k)
		m.free()
	var f := _mk()
	f.breakable_left += 100
	var rp = _fn(f, Vector2i(3, 5), "reaper", 5)
	var tp = _fn(f, Vector2i(4, 4), "teleport")
	_layer(f, Vector2i(4, 5), 1)
	f.effects.add_timed("flame", 20.0)
	f._ball_hit_brick(Vector2i(4, 5))
	_eq([rp.uses, f.grid[4][4] == tp, rp.hit_t], [5, true, 0.0], "flame splash: reaper / teleport untouched")
	f.free()
	# 炸彈:任何功能型磚都不被標記;炸彈爆炸也不扣
	var b := _mk()
	b.breakable_left += 100
	var bricks := []
	for i in ALL_KINDS.size():
		bricks.append(_fn(b, Vector2i(i, 16), ALL_KINDS[i], 3 if ALL_KINDS[i] in COUNTED else 1))
	b.effects.add_timed("bomb", 10.0)
	for i in ALL_KINDS.size():
		b._ball_hit_brick(Vector2i(i, 16))
	var marked := bricks.filter(func(x) -> bool: return x.marked).size()
	_eq(marked, 0, "bomb: no function brick marked")
	b._bomb_explode()
	b.free()
	# 打磚加速:每種(含傳送)每次 +0.5%
	for k in ALL_KINDS:
		var a := _mk()
		a.breakable_left += 100
		_fn(a, Vector2i(3, 16), k, 3)
		a._ball_hit_brick(Vector2i(3, 16))
		_ok(is_equal_approx(a.brick_accel, 0.005), "%s: accel +0.005 (%f)" % [k, a.brick_accel])
		a.free()
	# 穿透:每種都反彈並觸發(傳送磚 = 傳送)
	for k in ALL_KINDS:
		var q := _mk()
		q.breakable_left += 100
		var br = _fn(q, Vector2i(4, 10), k, 3 if k in COUNTED else 1)       # y 268~288
		if k == "teleport":
			_fn(q, Vector2i(0, 0), "teleport")
		var ball = _ball(q, Vector2(200, 295.9), Vector2.UP)
		q._ball_bricks(ball, true)
		if k == "teleport":
			_ok(ball.warp > 0.0, "pierce: teleport still teleports")
		elif k == "reaper":
			_eq([br.uses, q.balls.size()], [2, 0], "pierce: reaper triggers")
		else:
			_ok(ball.dir.y > 0.0, "pierce: %s bounces" % k)
			_eq(br.uses, 2 if k in COUNTED else 0, "pierce: %s triggers once" % k)
		q.free()
	# 每次碰觸只觸發一次:球持續推進數幀,閃電(沒有可打的磚)只扣 1
	var o := _mk()
	o.breakable_left += 100
	var z = _fn(o, Vector2i(3, 5), "lightning", 9)    # y 168~188, x 140~180
	var ball2 = _ball(o, Vector2(160, 200), Vector2.UP)
	for i in 20:
		o._update_balls(1.0 / 60.0)
	_eq([z.uses, ball2.dir.y > 0.0], [8, true], "one touch over many substeps = -1 once")
	o.free()
	# 功能型磚破壞 +200(死神最後一次)
	var s := _mk()
	s.breakable_left += 100
	_fn(s, Vector2i(3, 5), "reaper", 1)
	s._ball_hit_brick(Vector2i(3, 5), _ball(s, Vector2(0, 0), Vector2.UP))
	_eq([s.grid[5][3], s.score], [null, 200], "function brick destroyed +200")
	s.free()


# ---------- 擋板槍子彈 ----------

func _t_bullets() -> void:
	for k in ALL_KINDS + ["unbreakable"]:
		var m := _mk()
		m.breakable_left += 100
		_layer(m, Vector2i(0, 0), 9)                 # 給閃電 / 彩虹當目標
		var br = _unb(m, Vector2i(3, 6)) if k == "unbreakable" else _fn(m, Vector2i(3, 6), k, 3 if k in COUNTED else 1)
		if k == "teleport":
			_fn(m, Vector2i(7, 0), "teleport")
		var above = _layer(m, Vector2i(3, 1), 5)     # 子彈若穿過會打到這塊
		_ball(m, Vector2(300, 600), Vector2.UP)
		m.bullets = [Vector2(_bx(3), 215)]
		m._update_bullets(0.05)
		m._update_bullets(0.05)
		_eq([m.bullets.size(), above.layers], [0, 5], "%s: bullet stops at the brick" % k)
		match k:
			"laser_h", "laser_v", "laser_x":
				_eq([br.uses, _count(m, "laser")], [2, 1], "%s: bullet fires laser, -1" % k)
			"lightning":
				_eq([br.uses, m.events.size() > 0], [2, true], "lightning: bullet fires bolts, -1")
			"reaper":
				_eq([br.uses, m.balls.size()], [2, 1], "reaper: bullet -1 only, no ball eaten")
			"explosion":
				_eq([br.uses, _count(m, "explosion")], [0, 1], "explosion: bullet detonates")
			"rainbow":
				_eq([br.uses, _count(m, "rainbow")], [0, 1], "rainbow: bullet triggers")
			"teleport", "unbreakable":
				_eq([_count(m, "bullet_block"), _count(m, "bullet_hit"), m.events.size(), br.hit_t], [1, 0, 0, 0.0],
					"%s: bullet blocked, no effect" % k)
		m.free()


# ---------- 雷射 ----------

func _t_laser() -> void:
	# 三塊連鎖:A → B → C,B 往回打到已用完的 A 不再觸發
	var m := _mk()
	var a = _fn(m, Vector2i(0, 4), "laser_h", 1)
	_layer(m, Vector2i(1, 4), 9)
	var b = _fn(m, Vector2i(2, 4), "laser_h", 1)
	_layer(m, Vector2i(3, 4), 9)
	_layer(m, Vector2i(4, 4), 9)
	var c = _fn(m, Vector2i(5, 4), "laser_h", 1)
	_layer(m, Vector2i(6, 4), 9)
	_layer(m, Vector2i(7, 4), 9)
	_layer(m, Vector2i(0, 0), 69)   # 讓遊戲不會因清空而結束
	m._ball_hit_brick(Vector2i(0, 4))
	var made := _run(m, 1.0)
	var lay := []
	for x in [1, 3, 4, 6, 7]:
		lay.append(m.grid[4][x].layers)
	_eq([made.get("laser", 0) + 1, a.uses, b.uses, c.uses], [3, 0, 0, 0], "3-laser chain: each fires once")
	_eq(lay, [7, 7, 7, 8, 8], "chain damage: between A-B hit twice, B-C twice, right of C once")
	_eq([m.grid[4][0], m.grid[4][2], m.grid[4][5]], [null, null, null], "all three destroyed after beaming")
	_eq(m.score, 800 + 600, "8 layers x100 + 3 function x200")
	m.free()
	# 光束被各種功能型磚擋下:觸發該磚效果、扣 1;傳送 / 不可破壞擋下沒效果;擋下之後的磚不受影响
	for k in ALL_KINDS + ["unbreakable"]:
		var t := _mk()
		t.breakable_left += 100
		_fn(t, Vector2i(0, 10), "laser_h", 3)
		var br = _unb(t, Vector2i(2, 10)) if k == "unbreakable" else _fn(t, Vector2i(2, 10), k, 3 if k in COUNTED else 1)
		if k == "teleport":
			_fn(t, Vector2i(7, 16), "teleport")
		var mid = _layer(t, Vector2i(1, 10), 5)
		var behind = _layer(t, Vector2i(3, 0), 5)   # 不在同一排,不被雷射影響;閃電 / 彩虹的目標
		var ball = _ball(t, Vector2(260, 278), Vector2.LEFT)   # 在光束那一排
		t._ball_hit_brick(Vector2i(0, 10))
		var mk := _run(t, 0.07)
		_eq(mid.layers, 4, "%s blocker: brick before it -1" % k)
		_eq([ball.pos, ball.dir, t.balls.size()], [Vector2(260, 278), Vector2.LEFT, 1], "%s: beam does not touch ball" % k)
		match k:
			"laser_h", "laser_v", "laser_x":
				_eq([br.uses, mk.get("laser", 0)], [2, 1], "beam hits %s: it fires and -1" % k)
			"lightning":
				_ok(br.uses == 2 and mk.get("bolt", 0) >= 1, "beam hits lightning: bolts, -1")
			"reaper":
				_eq([br.uses, t.balls.size()], [2, 1], "beam hits reaper: -1 only")
			"explosion":
				_eq([br.uses, mk.get("explosion", 0)], [0, 1], "beam hits explosion: detonates")
			"rainbow":
				_eq([br.uses, mk.get("rainbow", 0)], [0, 1], "beam hits rainbow: triggers")
			_:
				_eq([t.grid[10][2] == br, br.hit_t, t.events.size()], [true, 0.0, 0], "%s: blocks beam, no effect" % k)
		_ok(behind.layers <= 5, "%s: sanity" % k)
		t.free()
	# 十字:四向;垂直往下到關卡區底部(800 高時 y 800)、往上到 y 52
	var x := _mk()
	x.breakable_left += 100
	_fn(x, Vector2i(3, 8), "laser_x", 2)
	var up = _layer(x, Vector2i(3, 2), 3)
	var dn = _layer(x, Vector2i(3, 15), 3)
	var lf = _layer(x, Vector2i(0, 8), 3)
	var rt = _layer(x, Vector2i(7, 8), 3)
	var diag = _layer(x, Vector2i(4, 9), 3)
	x._ball_hit_brick(Vector2i(3, 8))
	var segs: Array = x.anims.filter(func(q: Dictionary) -> bool: return q["kind"] == "laser")[0]["segs"]
	var vy := segs.filter(func(s: Dictionary) -> bool: return s["vert"]).map(func(s: Dictionary) -> float: return s["pos"].y)
	var hx := segs.filter(func(s: Dictionary) -> bool: return not s["vert"]).map(func(s: Dictionary) -> float: return s["pos"].x)
	_ok(vy.min() <= 52.0 and vy.min() > 32.0, "X: vertical reaches field top (min y %s)" % vy.min())
	_ok(vy.max() + 20.0 >= 800.0 and vy.max() < 800.0, "X: vertical reaches field bottom (max y %s)" % vy.max())
	_ok(hx.min() <= 20.0 and hx.max() + 20.0 >= 340.0, "X: horizontal reaches both walls")
	var vx := segs.filter(func(s: Dictionary) -> bool: return s["vert"]).map(func(s: Dictionary) -> float: return s["pos"].x)
	_ok(vx.all(func(v: float) -> bool: return v == 20 + 3 * 40 + 10), "vertical segs at brick x + 10")
	_run(x, 0.07)
	_eq([up.layers, dn.layers, lf.layers, rt.layers, diag.layers], [2, 2, 2, 2, 3], "X: 4 directions -1, diagonal untouched")
	x.free()
	# 動畫 4 幀 thin full full thin,每幀 60 ms;光束 1 層扣到 0 破壞:+100+200,照常掉道具
	var d := _mk()
	d.breakable_left += 100
	d.cfg.debug_force_item = "slow"
	_fn(d, Vector2i(0, 3), "laser_h", 3)
	_layer(d, Vector2i(1, 3), 1)
	d._ball_hit_brick(Vector2i(0, 3))
	var la: Dictionary = d.anims.filter(func(q: Dictionary) -> bool: return q["kind"] == "laser")[0]
	_eq(snappedf(la["dur"], 0.001), 0.24, "beam 4 frames x 60 ms")
	var widths := []
	for t in [0.01, 0.07, 0.13, 0.19]:
		widths.append(d._beam_width({"t": t}))
	_eq(widths, ["thin", "full", "full", "thin"], "beam frames thin full full thin")
	_run(d, 0.07)
	_eq([d.grid[3][1], d.score, d.items.size()], [null, 300, 1], "beam destroys 1-layer brick: 100+200, drop rolls")
	d.free()
	# 剩 1 次:先發射再破壞;破壞前仍擋球、不再觸發
	var l := _mk()
	l.breakable_left += 100
	var last = _fn(l, Vector2i(3, 10), "laser_v", 1)
	l._ball_hit_brick(Vector2i(3, 10))
	_eq([last.uses, l.grid[10][3] == last, _count(l, "laser")], [0, true, 1], "last use: fires first")
	var bb = _ball(l, Vector2(160, 295.9), Vector2.UP)
	l._ball_bricks(bb, false)
	_eq([bb.dir.y > 0.0, _count(l, "laser")], [true, 1], "spent laser still bounces ball, no refire")
	_run(l, 0.25)
	_eq([l.grid[10][3], l.score], [null, 200], "destroyed after beam, +200")
	l.free()


# ---------- 閃電 ----------

func _t_lightning() -> void:
	# 道數 = 碰觸前次數;目標不重複;只打多層磚;每道 -2;80 ms 錯開
	for n in range(1, 10):
		var m := _mk(n)
		m.breakable_left += 100
		for i in 12:
			_layer(m, Vector2i(i % 8, 1 + i / 8), 5)
		_unb(m, Vector2i(0, 6))
		var others := []
		for k in ["laser_h", "reaper", "explosion", "rainbow", "teleport"]:
			others.append(_fn(m, Vector2i(others.size() + 1, 6), k, 3))
		var z = _fn(m, Vector2i(7, 10), "lightning", n)
		m._ball_hit_brick(Vector2i(7, 10))
		var starts: Array = m.events.map(func(e: Dictionary) -> float: return snappedf(e["t"], 0.001))
		var want := []
		for i in n:
			want.append(snappedf(0.08 * i, 0.001))
		_eq(starts, want, "uses %d: %d bolts 80 ms apart" % [n, n])
		var made := _run(m, 1.2)
		var hit := 0
		var bad := 0
		for i in 12:
			var lv: int = m.grid[1 + i / 8][i % 8].layers
			if lv == 3:
				hit += 1
			elif lv != 5:
				bad += 1
		_eq([hit, bad, made.get("bolt", 0)], [n, 0, n], "uses %d: %d distinct bricks -2 each" % [n, n])
		_eq([others[0].uses, others[1].uses, others[2].uses, others[3].uses, m.grid[6][0].unbreakable], [3, 3, 3, 3, true],
			"uses %d: function / U never targeted" % n)
		_eq(m.score, n * 200 + (200 if n == 1 else 0), "uses %d: score 2 layers x100 per bolt (+200 when lightning destroyed)" % n)
		_eq([z.uses, m.grid[10][7] == null], [n - 1, n == 1], "uses %d: -1, destroyed only at 0" % n)
		m.free()
	# 目標不足:打到現有數量為止
	var s := _mk()
	s.breakable_left += 100
	_layer(s, Vector2i(0, 0), 5)
	_layer(s, Vector2i(5, 3), 1)
	_fn(s, Vector2i(3, 9), "lightning", 7)
	s._ball_hit_brick(Vector2i(3, 9))
	var mm := _run(s, 1.0)
	_eq([mm.get("bolt", 0), s.grid[0][0].layers, s.grid[3][5]], [2, 3, null], "2 targets for 7 uses: 2 bolts")
	_eq(s.score, 200 + 100 + 200, "bolt destroys 1-layer brick: 1 layer +200")
	s.free()
	# 完全沒有多層磚:不出錯、照扣次數
	var e := _mk()
	e.breakable_left += 100
	_unb(e, Vector2i(0, 0))
	var z2 = _fn(e, Vector2i(3, 9), "lightning", 4)
	e._ball_hit_brick(Vector2i(3, 9))
	_run(e, 0.5)
	_eq([z2.uses, e.events.size(), _count(e, "bolt")], [3, 0, 0], "no layered bricks: no bolts, uses -1")
	e.free()
	# 落雷位置:anim pos = 目標磚左上角;落點偏移 (0, -10);中段張數 = 列號
	var p := _mk()
	p.breakable_left += 100
	_layer(p, Vector2i(2, 5), 5)
	_fn(p, Vector2i(6, 9), "lightning", 1)
	p._ball_hit_brick(Vector2i(6, 9))
	_run(p, 0.01)
	var bolt: Dictionary = p.anims.filter(func(q: Dictionary) -> bool: return q["kind"] == "bolt")[0]
	_eq([bolt["pos"], p.cfg.lightning_hit_offset, snappedf(bolt["dur"], 0.001)], [_pos(Vector2i(2, 5)), Vector2(0, -10), 0.18],
		"bolt at target, hit offset (0,-10), 3 frames")
	_eq(int((bolt["pos"].y - 68) / 20), 5, "mid count = row (D38 formula 58 + 20i)")
	p.free()


# ---------- 死神 ----------

func _t_reaper() -> void:
	var m := _mk()
	m.breakable_left += 100
	m.time_left = 100.0
	var rp = _fn(m, Vector2i(3, 8), "reaper", 3)   # y 228~248, x 140~180
	var b1 = _ball(m, Vector2(160, 256.5), Vector2.UP)
	var b2 = _ball(m, Vector2(300, 600), Vector2.DOWN.rotated(0.3))
	m._update_balls(0.01)
	_eq([m.balls.size(), b1.gone, rp.uses, rp.hit_t > 0.0, snappedf(rp.hit_t, 0.001)], [1, true, 2, true, 0.06],
		"ball eaten, brick hit frame 60 ms, -1")
	var v: Array = m.anims.filter(func(q: Dictionary) -> bool: return q["kind"] == "vanish")
	_eq([v.size(), v[0]["pos"].distance_to(b1.pos) < 5.0], [1, true], "ball_vanish at the ball")
	m._step(0.001)
	_eq(m.state, MainScript.State.PLAYING, "other ball still in play: continue")
	m.balls.erase(b2)
	m._step(0.001)
	_eq(m.state, MainScript.State.ENDED, "all balls gone: lose (normal rule)")
	m.free()


# ---------- 爆炸 ----------

func _t_explosion() -> void:
	# 三顆互相相鄰:每顆只引爆 1 次
	var m := _mk()
	m.breakable_left += 100
	var e1 = _fn(m, Vector2i(3, 8), "explosion")
	_fn(m, Vector2i(4, 8), "explosion")
	_fn(m, Vector2i(3, 9), "explosion")
	_fn(m, Vector2i(4, 9), "explosion")
	m._ball_hit_brick(Vector2i(3, 8))
	var made := _run(m, 2.0)
	_eq(made.get("explosion", 0) + 1, 4, "4 adjacent explosions: 4 detonations total")
	_eq([m.grid[8][3], m.grid[8][4], m.grid[9][3], m.grid[9][4]], [null, null, null, null], "all removed")
	_eq([made.get("func_break", 0), made.get("break", 0)], [0, 0], "no break frames")
	_eq(m.score, 800, "4 x 200")
	_ok(e1.uses == 0, "uses 0")
	m.free()
	# 3×3:多層磚不論層數破壞(層數 x100 + 200,掉道具);U / 功能型 / 範圍外不受影響;F3 = 120 ms
	var t := _mk()
	t.breakable_left += 100
	t.cfg.debug_force_item = "slow"
	_fn(t, Vector2i(3, 8), "explosion")
	var ring := [Vector2i(2, 7), Vector2i(3, 7), Vector2i(4, 7), Vector2i(2, 8), Vector2i(4, 8), Vector2i(2, 9), Vector2i(3, 9), Vector2i(4, 9)]
	var lay := [69, 1, 35, 7, 8, 2, 14, 50]
	for i in ring.size():
		_layer(t, ring[i], lay[i])
	var far1 = _layer(t, Vector2i(5, 8), 3)
	var far2 = _layer(t, Vector2i(3, 10), 3)
	t._ball_hit_brick(Vector2i(3, 8))
	var ex: Dictionary = t.anims.filter(func(q: Dictionary) -> bool: return q["kind"] == "explosion")[0]
	_eq([ex["pos"], snappedf(ex["dur"], 0.001)], [_pos(Vector2i(3, 8)) - Vector2(40, 20), 0.24], "fx at -(40,20), 4 x 60 ms")
	_run(t, 0.11)
	_eq(t.grid[8][3] != null and t.grid[7][2] != null, true, "before F3: still there")
	var mk := _run(t, 0.02)
	var gone := ring.filter(func(c: Vector2i) -> bool: return t.grid[c.y][c.x] == null).size()
	_eq([gone, t.grid[8][3], far1.layers, far2.layers], [8, null, 3, 3], "F3: 3x3 layered + itself removed, outside untouched")
	_eq([mk.get("break", 0), mk.get("func_break", 0)], [0, 0], "no break frames")
	var sum := 0
	for v in lay:
		sum += v * 100 + 200
	_eq(t.score, sum + 200, "score: layers x100 + 200 each + 200 explosion")
	_eq(t.items.size(), 8, "each destroyed layered brick rolls drop (forced)")
	t.free()
	var u := _mk()
	u.breakable_left += 100
	_fn(u, Vector2i(3, 8), "explosion")
	_unb(u, Vector2i(2, 7))
	var fs := []
	for k in ["laser_h", "lightning", "reaper", "rainbow", "teleport"]:
		fs.append(_fn(u, [Vector2i(3, 7), Vector2i(4, 7), Vector2i(2, 8), Vector2i(4, 8), Vector2i(2, 9)][fs.size()], k, 3))
	u._ball_hit_brick(Vector2i(3, 8))
	_run(u, 0.5)
	var alive := 0
	for c in [Vector2i(2, 7), Vector2i(3, 7), Vector2i(4, 7), Vector2i(2, 8), Vector2i(4, 8), Vector2i(2, 9)]:
		alive += 1 if u.grid[c.y][c.x] != null else 0
	_eq([alive, fs[0].uses, fs[1].uses, fs[2].uses, fs[3].uses], [6, 3, 3, 3, 3], "U / function / teleport in range unaffected")
	u.free()


# ---------- 彩虹 ----------

func _t_rainbow() -> void:
	# 只從多層磚顏色挑:場上只有綠色多層磚(4 層、11 層有數字)+ 一堆非多層磚
	var only_green := true
	for s in 30:
		var m := _mk(s)
		m.breakable_left += 100
		_layer(m, Vector2i(0, 0), 4)
		_layer(m, Vector2i(1, 0), 11)
		_unb(m, Vector2i(2, 0))
		_fn(m, Vector2i(3, 0), "laser_h", 3)
		_fn(m, Vector2i(4, 0), "teleport")
		_fn(m, Vector2i(5, 0), "teleport")
		_fn(m, Vector2i(6, 0), "reaper", 2)
		_fn(m, Vector2i(3, 6), "rainbow")
		m._ball_hit_brick(Vector2i(3, 6))
		var a: Array = m.anims.filter(func(q: Dictionary) -> bool: return q["kind"] == "rainbow")
		only_green = only_green and a.size() == 1 and a[0]["color"] == 3 and a[0]["targets"].size() == 2
		m.free()
	_eq(only_green, true, "picks only colors of layered bricks (green, with/without digit)")
	# 兩色時兩色都會被挑到
	var seen := {}
	for s in 40:
		var m := _mk(s)
		m.breakable_left += 100
		_layer(m, Vector2i(0, 0), 1)
		_layer(m, Vector2i(1, 0), 5)
		_fn(m, Vector2i(3, 6), "rainbow")
		m._ball_hit_brick(Vector2i(3, 6))
		seen[m.anims.filter(func(q: Dictionary) -> bool: return q["kind"] == "rainbow")[0]["color"]] = true
		m.free()
	_eq(seen.keys().size() == 2 and seen.has(0) and seen.has(4), true, "both existing colors can be picked (%s)" % [seen.keys()])
	# 流程:挑色環 3 幀、位置 -(10,10)、用該色版本;F3 後同色全破壞;整段 420 ms
	var r := _mk()
	r.breakable_left += 100
	r.cfg.debug_force_item = "slow"
	_layer(r, Vector2i(0, 0), 3)
	_layer(r, Vector2i(1, 0), 10)
	_layer(r, Vector2i(2, 0), 4)
	_fn(r, Vector2i(3, 6), "rainbow")
	r._ball_hit_brick(Vector2i(3, 6))
	var a0: Dictionary = r.anims.filter(func(q: Dictionary) -> bool: return q["kind"] == "rainbow")[0]
	var color: int = a0["color"]
	_eq([a0["pos"], snappedf(a0["dur"], 0.001)], [_pos(Vector2i(3, 6)) - Vector2(10, 10), 0.18], "ring at -(10,10), 3 frames")
	var tex_name := "d38_fx_rainbow_pick_%s_f1" % Rules.COLOR_NAMES[color]
	_ok(r._t(tex_name) != null, "ring texture of picked color exists (%s)" % tex_name)
	_run(r, 0.17)
	_ok(r.grid[0][0] != null and r.grid[6][3] != null, "targets still there during ring")
	_run(r, 0.02)
	if color == 2:
		_eq([r.grid[0][0], r.grid[0][1], r.grid[0][2] != null], [null, null, true], "yellow (3, 10) destroyed, green kept")
		_eq(r.score, 300 + 200 + 1000 + 200 + 200, "score: layers x100 + 200 each + 200 rainbow")
		_eq(r.items.size(), 2, "destroyed bricks roll drops")
	else:
		_eq([r.grid[0][0] != null, r.grid[0][1] != null, r.grid[0][2]], [true, true, null], "green destroyed, yellow kept")
	# 規格:整段 420 ms(挑色環 180 + 破壞 F1~F4 240)。420 ms 後不應還有彩虹相關的破壞動畫
	_run(r, 0.26)   # 累計 0.45 s(留 30 ms 給逐步推進的誤差)
	_eq([_count(r, "rainbow"), _count(r, "func_break"), _count(r, "break")], [0, 0, 0],
		"rainbow flow finished within 420 ms (no ring / break anims left at 450 ms)")
	r.free()
	# 沒有多層磚:直接破壞、不播挑色環
	var e := _mk()
	e.breakable_left += 100
	_unb(e, Vector2i(0, 0))
	_fn(e, Vector2i(1, 0), "laser_h", 3)
	_fn(e, Vector2i(3, 6), "rainbow")
	e._ball_hit_brick(Vector2i(3, 6))
	_eq([e.grid[6][3], _count(e, "rainbow"), _count(e, "func_break"), e.score], [null, 0, 1, 200], "no layered: break at once, no ring")
	e.free()


# ---------- 傳送 ----------

func _t_teleport() -> void:
	# 出口角度:3000 次全部與水平夾角 >= 15°,上下左右都有,接近 15° 與接近 90° 都會出現
	var m := _mk(5)
	_fn(m, Vector2i(1, 8), "teleport")
	_fn(m, Vector2i(6, 8), "teleport")
	var min_deg := 90.0
	var max_deg := 0.0
	var up := 0
	var down := 0
	var left := 0
	var right := 0
	var exits_ok := true
	var warp_ok := true
	for i in 3000:
		var b = MainScript.Ball.new()
		m._teleport(Vector2i(1, 8), b)
		var deg := rad_to_deg(asin(absf(b.dir.y)))
		min_deg = minf(min_deg, deg)
		max_deg = maxf(max_deg, deg)
		up += 1 if b.dir.y < 0.0 else 0
		down += 1 if b.dir.y > 0.0 else 0
		left += 1 if b.dir.x < 0.0 else 0
		right += 1 if b.dir.x > 0.0 else 0
		exits_ok = exits_ok and b.ghost == Vector2i(6, 8) and b.pos == _pos(Vector2i(6, 8)) + Vector2(20, 10)
		warp_ok = warp_ok and is_equal_approx(b.warp, 0.48)
	_ok(min_deg >= 15.0 - 0.001, "exit never < 15 deg from horizontal (min %.3f)" % min_deg)
	_ok(min_deg < 17.0 and max_deg > 85.0, "exit covers 15..90 deg (min %.2f max %.2f)" % [min_deg, max_deg])
	_ok(up > 1300 and down > 1300 and left > 1300 and right > 1300, "exit up/down/left/right all ~50%% (%d %d %d %d)" % [up, down, left, right])
	_eq([exits_ok, warp_ok], [true, true], "exit = other teleport center, ~480 ms away")
	m.anims.clear()
	m.events.clear()
	# 入口吸入 4 幀(入口)、出口倒播
	var b = _ball(m, Vector2(80, 255.9), Vector2.UP)
	m._ball_bricks(b, false)
	_eq([_count(m, "tele_in"), _count(m, "vanish"), m.grid[8][1].hit_t], [1, 1, 0.0], "entrance suck-in, no white flash")
	var tin: Dictionary = m.anims.filter(func(q: Dictionary) -> bool: return q["kind"] == "tele_in")[0]
	_eq([tin["pos"], snappedf(tin["dur"], 0.001)], [_pos(Vector2i(1, 8)), 0.24], "tele_in at entrance, 4 x 60 ms")
	var made := _run(m, 0.3)
	_eq([made.get("tele_out", 0), made.get("appear", 0)], [1, 1], "exit reverse anim after 240 ms")
	m.free()
	# 不會被任何東西破壞:爆炸 3×3、雷射、子彈、火焰、炸彈、彩虹、閃電、穿透結束
	var t := _mk()
	t.breakable_left += 100
	var t1 = _fn(t, Vector2i(3, 8), "teleport")
	var t2 = _fn(t, Vector2i(5, 12), "teleport")
	_fn(t, Vector2i(4, 8), "explosion")
	_fn(t, Vector2i(0, 8), "laser_h", 1)
	_fn(t, Vector2i(5, 16), "laser_v", 1)
	_fn(t, Vector2i(7, 16), "rainbow")
	_fn(t, Vector2i(6, 16), "lightning", 9)
	_layer(t, Vector2i(3, 9), 1)
	t._ball_hit_brick(Vector2i(4, 8))
	t._ball_hit_brick(Vector2i(0, 8))
	t._ball_hit_brick(Vector2i(5, 16))
	t._ball_hit_brick(Vector2i(6, 16))
	t._ball_hit_brick(Vector2i(7, 16))
	t.effects.add_timed("flame", 20.0)
	if t.grid[9][3] != null:
		t._ball_hit_brick(Vector2i(3, 9))
	t._damage(Vector2i(3, 8), 99)
	t._heal(Vector2i(3, 8), 5)
	t.grid[8][3].marked = false
	t._bomb_explode()
	_run(t, 1.0)
	_eq([t.grid[8][3] == t1, t.grid[12][5] == t2, t1.hit_t <= 0.0, t2.hit_t <= 0.0], [true, true, true, true],
		"teleports survive explosion / laser / flame / damage / heal / bomb / rainbow / lightning")
	t.free()
	# 傳送途中:算在場上(唯一的球在傳送中不判輸);分裂的新球也從出口出來
	var w := _mk()
	w.breakable_left += 100
	w.time_left = 100.0
	_fn(w, Vector2i(1, 8), "teleport")
	_fn(w, Vector2i(6, 8), "teleport")
	var wb = _ball(w, Vector2(80, 255.9), Vector2.UP)
	w._ball_bricks(wb, false)
	w._step(0.02)
	_eq(w.state, MainScript.State.PLAYING, "warping ball counts as in play")
	w._split_balls()
	_eq([w.balls.size(), w.balls[1].warp > 0.0, w.balls[1].pos], [2, true, _pos(Vector2i(6, 8)) + Vector2(20, 10)], "split during warp: new ball at exit")
	w.free()


# ---------- 無敵 ----------

func _t_invincible() -> void:
	for k in ALL_KINDS:
		var m := _mk()
		m.breakable_left += 100
		m.effects.add_timed("invincible", 10.0)
		_layer(m, Vector2i(0, 0), 5)
		var br = _fn(m, Vector2i(4, 10), k, 3 if k in COUNTED else 1)   # y 268~288
		if k == "teleport":
			_fn(m, Vector2i(0, 16), "teleport")
		var b = _ball(m, Vector2(200, 295.9), Vector2.UP)
		m._ball_bricks(b, false)
		_eq([br.uses, b.dir.y > 0.0, b.warp, m.balls.size(), m.events.size(), m.grid[10][4] == br],
			[3 if k in COUNTED else 1, true, 0.0, 1, 0, true], "invincible: %s does nothing, ball bounces" % k)
		_eq(m.anims.filter(func(q: Dictionary) -> bool: return q["kind"] in ["laser", "bolt", "explosion", "rainbow", "tele_in", "vanish"]).size(),
			0, "invincible: %s no effect anim" % k)
		if k == "teleport":
			_eq(br.hit_t, 0.0, "invincible: teleport no flash")
		m.bullets = [Vector2(_bx(4), 300)]
		m._update_bullets(0.05)
		_eq([br.uses, m.bullets.size(), _count(m, "bullet_block")], [3 if k in COUNTED else 1, 0, 1], "invincible: bullet blocked by %s" % k)
		m.free()


# ---------- 勝利 ----------

func _t_win() -> void:
	# 只剩傳送磚 + 不可破壞磚:過關
	var m := _mk()
	_layer(m, Vector2i(0, 0), 1)
	_fn(m, Vector2i(1, 0), "teleport")
	_fn(m, Vector2i(2, 0), "teleport")
	_unb(m, Vector2i(3, 0))
	m._damage(Vector2i(0, 0), 1)
	_eq(m.state, MainScript.State.ENDED, "only teleport + U left: cleared")
	m.free()
	# 各種功能型磚是最後一塊:破壞後才過關
	for k in ["laser_h", "laser_v", "laser_x", "lightning", "reaper", "explosion", "rainbow"]:
		var w := _mk()
		_fn(w, Vector2i(3, 5), k, 1)
		_fn(w, Vector2i(0, 16), "teleport")
		_fn(w, Vector2i(7, 16), "teleport")
		w._ball_hit_brick(Vector2i(3, 5), _ball(w, Vector2(0, 0), Vector2.UP) if k == "reaper" else null)
		_run(w, 0.5)
		_eq([w.state, w.breakable_left], [MainScript.State.ENDED, 0], "last brick %s destroyed -> cleared" % k)
		w.free()
	# 雷射用完後還在播光束時尚未過關
	var l := _mk()
	_fn(l, Vector2i(3, 5), "laser_h", 1)
	l._ball_hit_brick(Vector2i(3, 5))
	_run(l, 0.1)
	_eq(l.state, MainScript.State.PLAYING, "spent laser still beaming: not yet cleared")
	l.free()
	# 彩虹清掉最後的多層磚,自己也破壞後過關;計數不會變負
	var r := _mk()
	_layer(r, Vector2i(0, 0), 1)
	_layer(r, Vector2i(1, 0), 8)
	_fn(r, Vector2i(3, 5), "rainbow")
	r._ball_hit_brick(Vector2i(3, 5))
	_run(r, 0.5)
	_eq([r.state, r.breakable_left], [MainScript.State.ENDED, 0], "rainbow clears the last bricks -> cleared, counter 0")
	r.free()


# ---------- 設定 ----------

func _t_config() -> void:
	var c := load(CONFIG) as GameConfig
	_eq([c.func_frame, c.lightning_stagger, c.laser_damage, c.lightning_damage], [0.06, 0.08, 1, 2], "frame 60 ms, stagger 80 ms, laser 1, lightning 2")
	_eq([c.func_digit_offset, c.laser_v_offset, c.lightning_hit_offset, c.explosion_fx_offset, c.rainbow_ring_offset],
		[Vector2(10, 0), Vector2(10, 0), Vector2(0, -10), Vector2(-40, -20), Vector2(-10, -10)], "D38 offsets in config")
	_ok(c.explosion_chain_delay > 0.0 and c.explosion_chain_delay <= 0.5, "explosion chain delay in config (%s)" % c.explosion_chain_delay)
	_eq([c.score_per_layer, c.score_per_brick, c.drop_chance, c.brick_accel_other], [100, 200, 0.3, 0.005], "score / drop / accel")
	# 功能型磚 D38 圖都在
	var m := _mk()
	var missing := []
	for k in ALL_KINDS:
		if m._t("d38_brick_" + k) == null:
			missing.append(k)
		if k != "teleport" and m._t("d38_brick_%s_hit" % k) == null:
			missing.append(k + "_hit")
	for d in range(1, 10):
		if m._t("d31_digit_%d" % d) == null:
			missing.append(d)
	if m._t("d31_invincible_frame") == null or m._t("d31_brick_dust_f4") == null:
		missing.append("d31 shared")
	_eq(missing, [], "brick / hit / digit / frame / dust textures exist")
	m.free()


# ---------- 規格未定的行為:只記錄 ----------

func _t_observe() -> void:
	# 1) 爆炸已觸發、F3 前進入無敵:範圍內的磚?
	var m := _mk()
	m.breakable_left += 100
	_fn(m, Vector2i(3, 8), "explosion")
	_fn(m, Vector2i(4, 8), "explosion")
	_layer(m, Vector2i(2, 8), 5)
	m._ball_hit_brick(Vector2i(3, 8))
	m.effects.add_timed("invincible", 10.0)
	_run(m, 1.0)
	print("INFO explosion triggered then invincible before F3: neighbour layered survives=%s, explosion brick removed=%s, chained explosion removed=%s" %
		[m.grid[8][2] != null, m.grid[8][3] == null, m.grid[8][4] == null])
	m.free()
	# 2) 閃電目標在落雷前被別的東西打掉:是否改打別塊
	var z := _mk(3)
	z.breakable_left += 100
	for i in 6:
		_layer(z, Vector2i(i, 0), 5)
	_fn(z, Vector2i(3, 9), "lightning", 3)
	z._ball_hit_brick(Vector2i(3, 9))
	var second: Vector2i = (z.events[1]["fn"] as Callable).get_bound_arguments()[0]
	z.grid[second.y][second.x] = null
	z.breakable_left -= 1
	var mk := _run(z, 1.0)
	print("INFO lightning target removed before its bolt: bolts landed=%d of 3 (other layered bricks still available)" % mk.get("bolt", 0))
	z.free()
	# 3) 傳送途中被「合併」移除:出口仍播出現動畫
	var t := _mk()
	t.breakable_left += 100
	_fn(t, Vector2i(1, 8), "teleport")
	_fn(t, Vector2i(6, 8), "teleport")
	var keep = _ball(t, Vector2(300, 600), Vector2.DOWN)
	var b = _ball(t, Vector2(80, 255.9), Vector2.UP)
	t._ball_bricks(b, false)
	t._remove_balls(1)
	var mk2 := _run(t, 0.5)
	print("INFO warping ball removed by merge: ball gone=%s, 'appear' anim still played at exit=%d" % [not t.balls.has(b), mk2.get("appear", 0)])
	t.free()


# ---------- 重測 B1:彩虹目標不播被擊中幀,整段 420 ms ----------

## 回傳某種動畫(第一個)或空字典。
func _first(m: Node2D, kind: String) -> Dictionary:
	var a: Array = m.anims.filter(func(q: Dictionary) -> bool: return q["kind"] == kind)
	return a[0] if a.size() > 0 else {}


## 依 main.gd 繪圖規則,算出 break 動畫在時間 t 畫的是哪一幀:0 = 被擊中、1~3 = F1~F3、4 = 灰塵 F4。
func _break_frame(a: Dictionary, t: float) -> int:
	return int(t / MainScript.FRAME) + (0 if a.get("hit", true) else 1)


func _t_fix_b1() -> void:
	var r := _mk()
	r.breakable_left += 100
	r.cfg.drop_chance = 0.0
	# 只放同一色(紅:1 層、8 層有數字 1、15 層有數字 2),保證全部是目標
	_layer(r, Vector2i(0, 0), 1)
	_layer(r, Vector2i(1, 0), 8)
	_layer(r, Vector2i(2, 0), 15)
	var self_br = _fn(r, Vector2i(3, 6), "rainbow")
	r._ball_hit_brick(Vector2i(3, 6))
	var ring := _first(r, "rainbow")
	_eq([ring.get("color", -1), ring.get("targets", []).size(), snappedf(ring.get("dur", 0.0), 0.001)], [0, 3, 0.18],
		"ring: red, 3 targets, 3 x 60 ms")
	_eq(ring.get("targets", []), [_pos(Vector2i(0, 0)), _pos(Vector2i(1, 0)), _pos(Vector2i(2, 0))], "ring target flash positions = target cells")
	_eq([self_br.hit_t > 0.0, _count(r, "break"), _count(r, "func_break")], [true, 0, 0], "t=0: rainbow brick hit flash only, no break yet")
	# 每 10 ms 推進,記錄破壞動畫建立的時間點、彩虹環消失的時間點、最後一個破壞動畫結束的時間點
	var break_start := -1.0
	var ring_end := -1.0
	var last_end := -1.0
	var break_anims := []
	var func_anim := {}
	for i in 60:
		r._update_anims(0.01)
		r._update_events(0.01)
		var now := (i + 1) * 0.01
		for a in r.anims:
			if a["t"] == 0.0 and a["kind"] == "break":
				break_anims.append(a)
				if break_start < 0.0:
					break_start = now
			if a["t"] == 0.0 and a["kind"] == "func_break":
				func_anim = a
		if ring_end < 0.0 and _count(r, "rainbow") == 0:
			ring_end = now
		if (_count(r, "break") > 0 or _count(r, "func_break") > 0):
			last_end = now + 0.01
	_eq(break_anims.size(), 3, "3 target break anims")
	_eq(break_anims.all(func(a: Dictionary) -> bool: return a["hit"] == false and is_equal_approx(a["dur"], 0.24)), true,
		"every target break: no hit frame, 4 x 60 ms")
	_eq(break_anims.all(func(a: Dictionary) -> bool: return a["color"] == 0), true, "break frames use red (color at destruction)")
	# 繪圖幀序列:F1、F2、F3、灰塵,不出現被擊中幀(0)
	var seq := []
	if break_anims.size() > 0:
		for t in [0.0, 0.07, 0.13, 0.19, 0.239]:
			seq.append(_break_frame(break_anims[0], t))
	_eq(seq, [1, 2, 3, 4, 4], "target frames drawn: F1, F2, F3, dust (never hit frame)")
	_eq([func_anim.get("hit", "?"), snappedf(func_anim.get("dur", 0.0), 0.001)], ["", 0.24], "rainbow brick itself: F1~F4 only, 240 ms")
	_ok(break_start >= 0.18 - 0.001 and break_start <= 0.20 + 0.001, "target break starts right after ring (at %.2f s)" % break_start)
	_ok(ring_end >= 0.18 - 0.001 and ring_end <= 0.20 + 0.001, "ring ends at ~180 ms (%.2f s)" % ring_end)
	_ok(last_end >= 0.42 - 0.001 and last_end <= 0.44 + 0.001, "whole rainbow flow lasts ~420 ms (last break anim gone at %.2f s)" % last_end)
	_eq([r.grid[0][0], r.grid[0][1], r.grid[0][2], r.grid[6][3]], [null, null, null, null], "all targets + rainbow removed")
	_eq(r.score, (1 + 8 + 15) * 100 + 3 * 200 + 200, "score: all layers + per brick + rainbow")
	r.free()
	# 彩虹目標在無敵外框下 / 炸彈標記中:標記的磚也被破壞且不播被擊中幀
	var k := _mk()
	k.breakable_left += 100
	var mb = _layer(k, Vector2i(0, 0), 3)
	mb.marked = true
	_fn(k, Vector2i(3, 6), "rainbow")
	k._ball_hit_brick(Vector2i(3, 6))
	_run(k, 0.19)
	var kb := _first(k, "break")
	_eq([k.grid[0][0], kb.get("hit", true)], [null, false], "bomb-marked rainbow target: destroyed, no hit frame")
	k.free()


## 修 B1 時改了 _damage 的參數:其他會破壞多層磚的路徑都要維持「被擊中 1 幀 + F1~F4」= 300 ms。
func _t_fix_b1_regress() -> void:
	var cases := {}
	# 1) 一般球碰 1 層磚
	var m := _mk()
	m.breakable_left += 100
	_layer(m, Vector2i(2, 3), 1)
	m._ball_hit_brick(Vector2i(2, 3))
	cases["ball"] = _first(m, "break")
	m.free()
	# 2) 子彈
	m = _mk()
	m.breakable_left += 100
	_layer(m, Vector2i(4, 10), 1)
	m.bullets = [Vector2(_bx(4), 300)]
	m._update_bullets(0.05)
	cases["bullet"] = _first(m, "break")
	m.free()
	# 3) 火焰擴散打掉鄰格
	m = _mk()
	m.breakable_left += 100
	m.effects.add_timed("flame", 20.0)
	_layer(m, Vector2i(2, 3), 30)
	_layer(m, Vector2i(3, 3), 1)
	m._ball_hit_brick(Vector2i(2, 3))
	cases["flame_splash"] = _first(m, "break")
	m.free()
	# 4) 閃電
	m = _mk()
	m.breakable_left += 100
	_layer(m, Vector2i(0, 0), 2)
	_fn(m, Vector2i(3, 9), "lightning", 3)
	m._ball_hit_brick(Vector2i(3, 9))
	_run(m, 0.07)
	cases["lightning"] = _first(m, "break")
	m.free()
	# 5) 雷射
	m = _mk()
	m.breakable_left += 100
	_layer(m, Vector2i(0, 5), 1)
	_fn(m, Vector2i(3, 5), "laser_h", 3)
	m._ball_hit_brick(Vector2i(3, 5))
	_run(m, 0.07)
	cases["laser"] = _first(m, "break")
	m.free()
	# 6) 穿透結束
	m = _mk()
	m.breakable_left += 100
	_layer(m, Vector2i(2, 3), 5)
	_ball(m, _pos(Vector2i(2, 3)) + Vector2(20, 10), Vector2.UP)
	m._pierce_end()
	cases["pierce_end"] = _first(m, "break")
	m.free()
	# 7) 炸彈結束
	m = _mk()
	m.breakable_left += 100
	var bb = _layer(m, Vector2i(2, 3), 5)
	bb.marked = true
	m._bomb_explode()
	cases["bomb"] = _first(m, "break")
	m.free()
	for key in cases:
		var a: Dictionary = cases[key]
		_eq([a.is_empty(), a.get("hit", null), snappedf(a.get("dur", 0.0), 0.001)], [false, true, 0.3], "%s: break keeps hit frame + F1~F4 (300 ms)" % key)
		if not a.is_empty():
			var seq := []
			for t in [0.0, 0.07, 0.13, 0.19, 0.25]:
				seq.append(_break_frame(a, t))
			_eq(seq, [0, 1, 2, 3, 4], "%s: frames hit, F1, F2, F3, dust" % key)
	# 8) 多層磚扣層未破壞:只閃 1 幀,不播破壞
	m = _mk()
	m.breakable_left += 100
	var lb = _layer(m, Vector2i(2, 3), 5)
	m._ball_hit_brick(Vector2i(2, 3))
	_eq([lb.layers, lb.hit_t > 0.0, _count(m, "break")], [4, true, 0], "partial damage: hit flash only")
	m.free()
	# 9) 爆炸:範圍內磚與爆炸磚都不播破壞幀(D18 不受影響)
	m = _mk()
	m.breakable_left += 100
	_layer(m, Vector2i(2, 8), 20)
	_fn(m, Vector2i(3, 8), "explosion")
	m._ball_hit_brick(Vector2i(3, 8))
	var made := _run(m, 0.5)
	_eq([m.grid[8][2], m.grid[8][3], made.get("break", 0), made.get("func_break", 0)], [null, null, 0, 0], "explosion: neighbours and itself removed without break frames")
	m.free()
	# 10) 功能型磚自己的破壞:死神 / 閃電最後一次有被擊中幀(300 ms)、雷射最後一次沒有(光束後 240 ms)
	for k in ["reaper", "lightning", "laser_h"]:
		m = _mk()
		m.breakable_left += 100
		_layer(m, Vector2i(0, 0), 50)
		_fn(m, Vector2i(3, 5), k, 1)
		var bl = _ball(m, Vector2(0, 0), Vector2.UP)
		m._ball_hit_brick(Vector2i(3, 5), bl if k == "reaper" else null)
		var fb := {}
		for i in 40:
			m._update_anims(0.01)
			m._update_events(0.01)
			if fb.is_empty():
				fb = _first(m, "func_break")
		if fb.is_empty():
			fb = _first(m, "func_break")
		var want_hit: bool = k != "laser_h"
		_eq([fb.is_empty(), fb.get("hit", "?") != "", snappedf(fb.get("dur", 0.0), 0.001)], [false, want_hit, 0.3 if want_hit else 0.24],
			"%s last use: func_break %s" % [k, "with hit frame 300 ms" if want_hit else "F1~F4 240 ms"])
		m.free()


# ---------- 重測 B2:傳送途中球被移除,出口不播出現動畫 ----------

func _warp_setup() -> Array:
	var t := _mk()
	t.breakable_left += 100
	_fn(t, Vector2i(1, 8), "teleport")
	_fn(t, Vector2i(6, 8), "teleport")
	var keep = _ball(t, Vector2(300, 600), Vector2.DOWN)
	var b = _ball(t, Vector2(80, 255.9), Vector2.UP)
	t._ball_bricks(b, false)
	return [t, keep, b]


func _t_fix_b2() -> void:
	var exit_pos := _pos(Vector2i(6, 8))
	var exit_center := exit_pos + Vector2(20, 10)
	# 1) 沒被移除:240 ms 時在出口中心播出現(回歸)
	var s := _warp_setup()
	var t: Node2D = s[0]
	var made := _run(t, 0.23)
	_eq([made.get("tele_out", 0), made.get("appear", 0)], [0, 0], "before 240 ms: no exit anims yet")
	made = _run(t, 0.03)
	var ap := _first(t, "appear")
	var to := _first(t, "tele_out")
	_eq([made.get("appear", 0), made.get("tele_out", 0), ap.get("pos", null), to.get("pos", null), snappedf(ap.get("dur", 0.0), 0.001)],
		[1, 1, exit_center, exit_pos, 0.24], "ball kept: appear at exit center + tele_out at exit, 240 ms")
	t.free()
	# 2) 合併 / 大黑洞 / 直接 _remove_balls 在 0~240 ms 之間移除:不播出現,出口 tele_out 照播
	for id in ["merge", "blackhole_big"]:
		for delay in [0.0, 0.1, 0.22]:
			s = _warp_setup()
			t = s[0]
			_run(t, delay)
			t._apply_item(id)
			made = _run(t, 0.5)
			_eq([t.balls.has(s[2]), t.balls.has(s[1]), made.get("appear", 0), made.get("tele_out", 0)], [false, true, 0, 1],
				"%s at %.2f s: warping ball gone, keep ball stays, no appear, tele_out still plays" % [id, delay])
			t.free()
	# 3) 兩顆球同時傳送、只移除其中一顆:另一顆照常出現
	s = _warp_setup()
	t = s[0]
	var b2 = _ball(t, Vector2(80, 255.9), Vector2.UP)
	t._teleport(Vector2i(1, 8), b2)
	t._remove_balls(1)   # 移除 b2(最後加入)
	made = _run(t, 0.5)
	_eq([t.balls.has(s[2]), t.balls.has(b2), made.get("appear", 0)], [true, false, 1], "two warping, one removed: only survivor appears")
	t.free()
	# 4) 240 ms 之後才被移除:出現動畫已開始,不要求撤回;記錄現象
	s = _warp_setup()
	t = s[0]
	_run(t, 0.3)
	t._apply_item("merge")
	print("INFO B2 removed after appear started (0.30 s): appear anims alive=%d, vanish at exit=%d" %
		[_count(t, "appear"), t.anims.filter(func(q: Dictionary) -> bool: return q["kind"] == "vanish" and q["pos"] == exit_center).size()])
	t.free()
	# 5) 觀察:移除時的消失動畫位置(球在傳送中時 pos 已是出口中心)
	s = _warp_setup()
	t = s[0]
	_run(t, 0.1)
	t._apply_item("merge")
	var v: Array = t.anims.filter(func(q: Dictionary) -> bool: return q["kind"] == "vanish")
	print("INFO B2 merge during warp: vanish anims=%d at %s (entrance ball pos (80,255.9), exit center %s)" %
		[v.size(), v.map(func(q: Dictionary) -> Vector2: return q["pos"]), exit_center])
	t.free()
	# 6) 傳送中遊戲結束(過關):事件不再執行,不會有出現動畫
	s = _warp_setup()
	t = s[0]
	t._end(true, "test")
	made = _run(t, 0.5)
	_eq(made.get("appear", 0), 0, "game ended during warp: no appear")
	t.free()


# ---------- 自動遊玩 level_func_test(場景樹內,呼叫 _step) ----------

func _t_autoplay() -> void:
	var shared := load(CONFIG) as GameConfig
	var orig_path := shared.level_path
	shared.level_path = FUNC_LEVEL
	var wins := 0
	var losses := 0
	var unfinished := 0
	var inv_bad := 0
	var uses_bad := 0
	var fixed_bad := 0
	var win_left_bad := 0
	for seed in 6:
		var m: Node2D = MainScene.instantiate()
		root.add_child(m)
		await process_frame
		m.cfg = m.cfg.duplicate()
		m.cfg.max_balls = 20
		# 奇數種子只掉「減速」:沒有合併 / 大黑洞,球只會因死神(最多 4 次)或掉出底部而減少
		if seed % 2 == 1:
			m.cfg.debug_force_item = "slow"
		m.rng.seed = 100 + seed
		m.time_left = 1.0e6
		# 開局分裂成 8 顆:死神最多吃幾顆,避免一開始就因死神判輸而玩不到後面
		for i in 3:
			m._split_balls()
		var fell := 0
		var count_fixed := func() -> Array:
			var u := 0
			var tp := 0
			for row in m.grid:
				for br in row:
					if br != null and br.unbreakable:
						u += 1
					elif br != null and br.kind == "teleport":
						tp += 1
			return [u, tp]
		var fixed0: Array = count_fixed.call()
		var r := RandomNumberGenerator.new()
		r.seed = seed
		var off := 0.0
		var t := 0.0
		while m.state == MainScript.State.PLAYING and t < 420.0:
			if m.menu != null:
				m.menu.free()
				m.menu = null
				m.menu_queue.clear()
			m._launch_stuck()
			var low = null
			for b in m.balls:
				if b.warp <= 0.0 and not b.stuck and b.dir.y > 0.0 and (low == null or b.pos.y > low.pos.y):
					low = b
			if low != null:
				if low.pos.y < 600.0:
					off = r.randf_range(-30.0, 30.0)
				m.paddle_x = clampf(low.pos.x + off, 20.0 + m._paddle_len() / 2.0, 340.0 - m._paddle_len() / 2.0)
				m.target_x = m.paddle_x
			m.effects.timed.erase("blackhole")
			m._step(1.0 / 60.0)
			t += 1.0 / 60.0
			for a in m.anims:
				if a["kind"] == "vanish" and a["t"] == 0.0 and a["pos"].y >= m.view_h - 20:
					fell += 1
			if m.state != MainScript.State.PLAYING:
				break
			var left := 0
			for row in m.grid:
				for br in row:
					if br == null:
						continue
					if not br.unbreakable and br.kind != "teleport":
						left += 1
					if br.kind in COUNTED and (br.uses < 0 or br.uses > 9):
						uses_bad += 1
					elif br.kind in ["explosion", "rainbow"] and (br.uses < 0 or br.uses > 1):
						uses_bad += 1
			if left != m.breakable_left:
				inv_bad += 1
			if int(t * 60) % 60 == 0 and count_fixed.call() != fixed0:
				fixed_bad += 1
		if m.state == MainScript.State.ENDED:
			if m.breakable_left <= 0:
				wins += 1
				var rest := 0
				for row in m.grid:
					for br in row:
						if br != null and not br.unbreakable and br.kind != "teleport":
							rest += 1
				win_left_bad += rest
			else:
				losses += 1
				_ok(seed % 2 == 0 or fell > 0, "seed %d (only slow drops, 8 balls, reaper max 4): lost without balls falling" % seed)
		else:
			unfinished += 1
			var rest := []
			for rr in MainScript.MAX_ROWS:
				for cc in MainScript.COLS:
					var br = m.grid[rr][cc]
					if br != null and not br.unbreakable and br.kind != "teleport":
						rest.append([cc, rr, br.kind, br.layers, br.uses])
			print("INFO autoplay seed %d unfinished after 420 s, left: %s" % [seed, rest])
		var reaper_uses := []
		for row in m.grid:
			for br in row:
				if br != null and br.kind == "reaper":
					reaper_uses.append(br.uses)
		print("INFO autoplay seed %d: state=%s left=%d score=%d sim=%.1fs balls=%d fell_off_bottom=%d reaper_uses_left=%s" %
			[seed, m.state, m.breakable_left, m.score, t, m.balls.size(), fell, reaper_uses])
		await process_frame
		m.queue_free()
		await process_frame
	shared.level_path = orig_path
	_eq([inv_bad, uses_bad, fixed_bad, win_left_bad], [0, 0, 0, 0], "autoplay invariants: win counter = bricks on grid, uses in range, U/teleports never removed")
	_ok(wins + losses + unfinished == 6, "autoplay ran 6 seeds (wins %d, losses %d, unfinished %d)" % [wins, losses, unfinished])
