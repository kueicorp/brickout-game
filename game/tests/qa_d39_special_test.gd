## QA 獨立驗證:D39~D44 圓形磚、寶箱、金幣磚、魔王(逐格破壞、拼接外框)、雙血條、BOSS 警告。
## 規格:README、docs/design/special-bricks.md D39~D44(D42「無敵」列作廢:無敵不影響魔王)與 PM 轉達的使用者決定。
## 執行:Godot --headless --path game --script res://tests/qa_d39_special_test.gd
## 全部通過時結束碼 0,有失敗時結束碼 1。以 INFO 開頭的輸出是觀察紀錄(規格未定或工程師自訂的行為),不算失敗。
extends SceneTree

const MainScript := preload("res://scripts/main.gd")
const MainScene := preload("res://scenes/main.tscn")
const CONFIG := "res://data/game_config.tres"
const LEVEL_TEST := "res://data/levels/level_test.json"
const K_HEX := "1b1a2e"

## D42 Q2 的 6 種形狀(欄, 排)
const SHAPES := {
	"S1": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)],
	"S2": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
	"S3": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1),
		Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)],
	"L": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2)],
	"T": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1)],
	"CONVEX": [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
}

var _passed := 0
var _failed := 0
var _section := ""
var _img_cache := {}


func _init() -> void:
	_sec("parse", _t_parse)
	_sec("load_level_test", _t_load)
	_sec("thresholds", _t_thresholds)
	_sec("masks_parts", _t_mask_parts)
	_sec("masks_pixels", _t_mask_pixels)
	_sec("boss_drop_cells", _t_drop_cells)
	_sec("boss_ball", _t_boss_ball)
	_sec("boss_drop_items", _t_boss_items)
	_sec("boss_effects", _t_boss_effects)
	_sec("boss_victory", _t_victory)
	_sec("crack_bar", _t_crack_bar)
	_sec("chest", _t_chest)
	_sec("coin", _t_coin)
	_sec("coin_catch", _t_coin_catch)
	_sec("circle_rules", _t_circle_rules)
	_sec("circle_collision", _t_circle_collision)
	_sec("specials_common", _t_specials_common)
	_sec("clearing_coins_items", _t_clearing_airborne)
	_sec("observe", _t_observe)
	await process_frame
	_section = "warning"
	await _t_warning()
	print("QA D39 SPECIAL RESULT: %d passed, %d failed" % [_passed, _failed])
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


func _near(actual: float, expected: float, tol: float, label: String) -> void:
	if absf(actual - expected) <= tol:
		_passed += 1
	else:
		_failed += 1
		print("FAIL [%s] %s: expected %.4f ± %.4f, got %.4f" % [_section, label, expected, tol, actual])


# ---------- 輔助 ----------

## 不進場景樹的主程式 + 空格子。
func _mk(seed := 11) -> Node2D:
	var m: Node2D = MainScript.new()
	m.cfg = (load(CONFIG) as GameConfig).duplicate()
	m.cfg.debug_force_item = ""
	m.rng.seed = seed
	m.time_left = m.cfg.game_time
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


func _special(m: Node2D, cell: Vector2i, kind: String) -> Object:
	var br = MainScript.Brick.new()
	br.special = kind
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


## 依 main._load_level 的資料結構建一隻魔王(cells 為絕對格座標)。
func _boss(m: Node2D, cells: Array, hp: int, id := "B1") -> Object:
	var bs = MainScript.Boss.new()
	bs.id = id
	bs.cells.assign(cells)
	bs.size = cells.size()
	bs.max_layers = hp
	bs.layers = hp
	bs.bar_old = hp
	bs.thresholds = Rules.boss_thresholds(hp, cells.size())
	for c in cells:
		bs.center_x += float(c.x) / cells.size()
		var br = MainScript.Brick.new()
		br.boss = bs
		m.grid[c.y][c.x] = br
	m.bosses.append(bs)
	return bs


func _ball(m: Node2D, pos: Vector2, dir: Vector2) -> Object:
	var b = MainScript.Ball.new()
	b.pos = pos
	b.dir = dir.normalized()
	m.balls.append(b)
	return b


## 只推進動畫與延遲效果(每步 10 ms)。
func _run(m: Node2D, secs: float) -> void:
	for i in roundi(secs / 0.01):
		m._update_anims(0.01)
		m._update_events(0.01)


## 該魔王還留在格子上的格數(錯開掉落的格要等事件觸發才離開格子)。
func _on_grid(m: Node2D, bs: Object) -> int:
	var n := 0
	for r in MainScript.MAX_ROWS:
		for c in MainScript.COLS:
			var br = m.grid[r][c]
			if br != null and br.boss == bs:
				n += 1
	return n


func _shift(cells: Array, off: Vector2i) -> Array:
	return cells.map(func(c: Vector2i) -> Vector2i: return c + off)


## 格左上角(螢幕座標)。
func _pos(cell: Vector2i) -> Vector2:
	return Vector2(20 + cell.x * 40, 68 + cell.y * 20)


func _center(cell: Vector2i) -> Vector2:
	return _pos(cell) + Vector2(20, 10)


## 子彈 x:判定點 x+1、x+2 落在第 c 欄、離格中心 13.5 px(圓形磚的圓外)。
func _bx(c: int) -> float:
	return 20 + c * 40 + 5


func _count_items(m: Node2D) -> Array:
	var buff := 0
	var debuff := 0
	for it in m.items:
		if ItemDefs.is_buff(it["id"]):
			buff += 1
		else:
			debuff += 1
	return [buff, debuff]


# ---------- 關卡代號 ----------

func _t_parse() -> void:
	var p := Rules.parse_level({"rows": ["H G O B1 B2 . . ."]}, 17, 8, 69)
	_eq(p["errors"].size(), 0, "H G O B1 B2 valid")
	_eq(p["cells"][0], [Rules.SPECIAL, Rules.SPECIAL, Rules.SPECIAL, Rules.BOSS, Rules.BOSS, 0, 0, 0] as Array[int], "cells codes")
	_eq([p["specials"][Vector2i(0, 0)], p["specials"][Vector2i(1, 0)], p["specials"][Vector2i(2, 0)]], ["chest", "coin", "circle"], "special kinds")
	_eq(p["bosses"].keys(), ["B1", "B2"], "two boss ids")
	# 只收 B1、B2(工程師自訂);其餘魔王代號、小寫、加數字的特殊磚都無效
	var bad := Rules.parse_level({"rows": ["B3 B0 b1 B h g o H1", "G2 O1 BB B12 . . . ."]}, 17, 8, 69)
	_eq(bad["errors"].size(), 12, "12 invalid boss / special tokens reported")
	_eq([bad["bosses"].size(), bad["specials"].size()], [0, 0], "no invalid token becomes boss / special")
	# 魔王格不必相連,依讀取順序
	var split := Rules.parse_level({"rows": ["B1 . . B1 . . . .", ". . . . . . . B1"]}, 17, 8, 69)
	_eq(split["bosses"]["B1"], [Vector2i(0, 0), Vector2i(3, 0), Vector2i(7, 1)], "B1 cells in reading order (not required to touch)")


# ---------- level_test.json 載入 ----------

func _t_load() -> void:
	var m := _mk()
	m.cfg.level_path = LEVEL_TEST
	m._load_level()
	_eq(m.bosses.size(), 2, "level_test has 2 bosses")
	var b1 = m.bosses[0]
	var b2 = m.bosses[1]
	_eq([b1.id, b1.cells, b1.size], ["B1", [Vector2i(0, 9), Vector2i(1, 9), Vector2i(2, 9), Vector2i(3, 9)], 4], "B1 = 4x1 row 9")
	_eq([b2.id, b2.size], ["B2", 4], "B2 = T 4 cells")
	_eq([b1.max_layers, b1.layers, b2.max_layers, b2.layers], [50, 50, 50, 50], "hp = level_number 10 x 5 each")
	_eq(b1.thresholds, [50, 38, 25, 13, 0] as Array[int], "B1 thresholds 50/4 rounded up")
	var kinds := {}
	var non_boss := 0
	for r in m.grid.size():
		for c in m.grid[r].size():
			var br = m.grid[r][c]
			if br == null:
				continue
			if br.special != "":
				kinds[br.special] = kinds.get(br.special, 0) + 1
				_eq(br.layers, 1, "special %s at %s is 1 layer" % [br.special, Vector2i(c, r)])
			if br.boss == null and not br.unbreakable:
				non_boss += 1
	_eq(kinds, {"chest": 3, "coin": 3, "circle": 3}, "3 chest + 3 coin + 3 circle")
	_eq(m.breakable_left, non_boss, "breakable_left excludes boss cells and U")
	m.free()
	# 血量 = level_number × 5;各自一份
	for lv in [1, 3, 20]:
		var n := _mk()
		n.cfg.level_path = LEVEL_TEST
		n.cfg.level_number = lv
		n._load_level()
		_eq([n.bosses[0].max_layers, n.bosses[1].max_layers], [lv * 5, lv * 5], "level %d -> hp %d" % [lv, lv * 5])
		n._boss_damage(n.bosses[0], 1)
		_eq([n.bosses[0].layers, n.bosses[1].layers], [lv * 5 - 1, lv * 5], "level %d: separate hp pools" % lv)
		n.free()


# ---------- 門檻 ----------

## 獨立算法:剩幾格 = N − #{k ∈ 1..N−1 : 層數 ≤ ceil(H(N−k)/N)},0 層 = 0 格。
func _expect_left(layers: int, h: int, n: int) -> int:
	if layers <= 0:
		return 0
	var left := n
	for k in range(1, n):
		if layers <= ceili(float(h) * (n - k) / n - 1e-9):
			left -= 1
	return left


func _t_thresholds() -> void:
	_eq(Rules.boss_thresholds(50, 4), [50, 38, 25, 13, 0] as Array[int], "H50 N4")
	_eq(Rules.boss_thresholds(20, 4), [20, 15, 10, 5, 0] as Array[int], "H20 N4 (multiple)")
	_eq(Rules.boss_thresholds(50, 3), [50, 34, 17, 0] as Array[int], "H50 N3 (not multiple)")
	_eq(Rules.boss_thresholds(50, 9), [50, 45, 39, 34, 28, 23, 17, 12, 6, 0] as Array[int], "H50 N9")
	_eq(Rules.boss_thresholds(7, 1), [7, 0] as Array[int], "N1: only the 0 threshold")
	# 邊界:剛好等於門檻就掉、比門檻多 1 不掉
	var t := Rules.boss_thresholds(50, 3)
	_eq([Rules.boss_cells_left(35, t), Rules.boss_cells_left(34, t), Rules.boss_cells_left(18, t),
		Rules.boss_cells_left(17, t), Rules.boss_cells_left(1, t), Rules.boss_cells_left(0, t)], [3, 2, 2, 1, 1, 0],
		"H50 N3 boundary 35/34/18/17/1/0")
	var t4 := Rules.boss_thresholds(50, 4)
	_eq([Rules.boss_cells_left(39, t4), Rules.boss_cells_left(38, t4), Rules.boss_cells_left(26, t4),
		Rules.boss_cells_left(25, t4), Rules.boss_cells_left(14, t4), Rules.boss_cells_left(13, t4)], [4, 3, 3, 2, 2, 1],
		"H50 N4 boundary 39/38/26/25/14/13")
	# 全面比對 H 1~120、N 1~9
	var bad := []
	for h in range(1, 121):
		for n in range(1, 10):
			var th := Rules.boss_thresholds(h, n)
			if th.size() != n + 1 or th[0] != h or th[-1] != 0:
				bad.append("shape H%d N%d" % [h, n])
			for k in range(1, n):
				if th[k] != ceili(float(h) * (n - k) / n - 1e-9):
					bad.append("t H%d N%d k%d" % [h, n, k])
			for layers in range(0, h + 1):
				if Rules.boss_cells_left(layers, th) != _expect_left(layers, h, n):
					bad.append("left H%d N%d L%d" % [h, n, layers])
	_eq(bad.slice(0, 10), [], "thresholds & cells_left match ceil formula for H1~120 N1~9")
	# H < N(例:第 1 關 H5、3×3 魔王):第 1 個門檻 = H,滿血時規則上就該少 1 格
	var small := Rules.boss_thresholds(5, 9)
	print("INFO H5 N9 thresholds=%s cells_left(5)=%d (full hp already below N; game only drops on first hit)" % [small, Rules.boss_cells_left(5, small)])


# ---------- 拼接元件(Rules.boss_parts)----------

func _parts_of(cells: Array, cell: Vector2i) -> Array:
	var has := func(n: Vector2i) -> bool: return n in cells
	var names := []
	for p in Rules.boss_parts(cell, has):
		names.append(p[1])
	names.sort()
	return names


func _t_mask_parts() -> void:
	# S1 4×1:兩端有外凸轉角、中間只有上下外緣,節點在右邊 3 格
	var s1: Array = SHAPES["S1"]
	_eq(_parts_of(s1, Vector2i(0, 0)), ["d42_boss_corner_bl", "d42_boss_corner_tl", "d42_boss_edge_b", "d42_boss_edge_l",
		"d42_boss_edge_t", "d42_boss_fill"], "S1 left end")
	_eq(_parts_of(s1, Vector2i(1, 0)), ["d42_boss_edge_b", "d42_boss_edge_t", "d42_boss_fill", "d42_boss_joint_h"], "S1 middle")
	_eq(_parts_of(s1, Vector2i(3, 0)), ["d42_boss_corner_br", "d42_boss_corner_tr", "d42_boss_edge_b", "d42_boss_edge_r",
		"d42_boss_edge_t", "d42_boss_fill", "d42_boss_joint_h"], "S1 right end")
	# S3 掉中央:四個角格各有 1 個內凹轉角
	var ring: Array = SHAPES["S3"].filter(func(c: Vector2i) -> bool: return c != Vector2i(1, 1))
	_ok("d42_boss_concave_se" in _parts_of(ring, Vector2i(0, 0)), "S3 minus center: (0,0) concave_se")
	_ok("d42_boss_concave_sw" in _parts_of(ring, Vector2i(2, 0)), "S3 minus center: (2,0) concave_sw")
	_ok("d42_boss_concave_ne" in _parts_of(ring, Vector2i(0, 2)), "S3 minus center: (0,2) concave_ne")
	_ok("d42_boss_concave_nw" in _parts_of(ring, Vector2i(2, 2)), "S3 minus center: (2,2) concave_nw")
	_ok("d42_boss_edge_b" in _parts_of(ring, Vector2i(1, 0)), "S3 minus center: (1,0) gets bottom edge")
	# L 形:(0,2) 有上、右鄰,右上斜角 (1,1) 沒格 → concave_ne
	_ok("d42_boss_concave_ne" in _parts_of(SHAPES["L"], Vector2i(0, 2)), "L: (0,2) concave_ne")
	# T 形:(1,0) 左、右、下都有格,左下 (0,1)、右下 (2,1) 沒格 → concave_sw + concave_se
	_eq(_parts_of(SHAPES["T"], Vector2i(1, 0)), ["d42_boss_concave_se", "d42_boss_concave_sw", "d42_boss_edge_t",
		"d42_boss_fill", "d42_boss_joint_h"], "T top middle")
	_eq(_parts_of(SHAPES["T"], Vector2i(1, 1)), ["d42_boss_corner_bl", "d42_boss_corner_br", "d42_boss_edge_b",
		"d42_boss_edge_l", "d42_boss_edge_r", "d42_boss_fill"], "T stem (no joint: vertical neighbours get none)")
	# 凸字:(0,1) 上方沒格、右方有、右上 (1,0) 有 → 不是內凹;(1,0) 只有下鄰
	_eq(_parts_of(SHAPES["CONVEX"], Vector2i(0, 1)), ["d42_boss_corner_bl", "d42_boss_corner_tl", "d42_boss_edge_b",
		"d42_boss_edge_l", "d42_boss_edge_t", "d42_boss_fill"], "convex bottom-left")
	# 節點:只放在「左邊有格」的格,位移 (-2, 7)
	var joint := Rules.boss_parts(Vector2i(1, 0), func(n: Vector2i) -> bool: return n in s1).filter(
		func(p: Array) -> bool: return p[1] == "d42_boss_joint_h")
	_eq(joint, [[4, "d42_boss_joint_h", Vector2i(-2, 7)]], "joint batch 4 at (-2,7)")


## 用正式 PNG 依 boss_parts 的批次順序拼出整隻魔王,檢查:
## 1) 魔王範圍內全部不透明、範圍外全透明;2) 像素是 K ⇔ 它的 8 鄰有任一點在魔王範圍外(外框連續、內部沒有多餘描邊)。
func _img(name: String) -> Image:
	if not _img_cache.has(name):
		var img := Image.load_from_file(ProjectSettings.globalize_path("res://art/special40/%s.png" % name))
		img.convert(Image.FORMAT_RGBA8)
		_img_cache[name] = img
	return _img_cache[name]


func _compose(cells: Array, cols: int, rows: int) -> Image:
	var out := Image.create_empty((cols + 2) * 40, (rows + 2) * 20, false, Image.FORMAT_RGBA8)
	var has := func(n: Vector2i) -> bool: return n in cells
	var parts := {}
	for c in cells:
		parts[c] = Rules.boss_parts(c, has)
	for layer in 5:
		for c in cells:
			for p in parts[c]:
				if p[0] == layer:
					var src := _img(p[1])
					out.blend_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), Vector2i((c.x + 1) * 40, (c.y + 1) * 20) + p[2])
	return out


func _check_mask(cells: Array, cols: int, rows: int) -> String:
	var img := _compose(cells, cols, rows)
	var inside := func(x: int, y: int) -> bool:
		return Vector2i(floori(x / 40.0) - 1, floori(y / 20.0) - 1) in cells
	for y in img.get_height():
		for x in img.get_width():
			var px := img.get_pixel(x, y)
			var ins: bool = inside.call(x, y)
			if not ins:
				if px.a > 0.0:
					return "drawn outside at %d,%d" % [x, y]
				continue
			if px.a < 1.0:
				return "transparent inside at %d,%d" % [x, y]
			var boundary := false
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if not inside.call(x + dx, y + dy):
						boundary = true
			var is_k := px.to_html(false) == K_HEX
			if boundary and not is_k:
				return "outline gap (not K) at %d,%d cell %s" % [x, y, Vector2i(x / 40 - 1, y / 20 - 1)]
			if is_k and not boundary:
				return "stray K inside at %d,%d cell %s" % [x, y, Vector2i(x / 40 - 1, y / 20 - 1)]
	return ""


func _t_mask_pixels() -> void:
	# 每種形狀的所有非空子集合(= 任意掉格後剩下的樣子,含斷成兩段),S3 共 511 種
	for name in SHAPES:
		var shape: Array = SHAPES[name]
		var cols := 0
		var rows := 0
		for c in shape:
			cols = maxi(cols, c.x + 1)
			rows = maxi(rows, c.y + 1)
		var bad := []
		var total := 0
		for mask in range(1, 1 << shape.size()):
			var sub := []
			for i in shape.size():
				if mask & (1 << i):
					sub.append(shape[i])
			total += 1
			var err := _check_mask(sub, cols, rows)
			if err != "":
				bad.append("%s: %s" % [sub, err])
		_eq(bad.slice(0, 5), [], "%s: all %d drop states stitch with continuous K outline" % [name, total])
	# 兩隻魔王相鄰時各自拼接(用 has 只看同一隻):這裡用 boss_parts 驗證「另一隻的格」不算鄰格
	var a := [Vector2i(0, 0), Vector2i(1, 0)]
	var b := [Vector2i(2, 0)]
	_eq(_parts_of(a, Vector2i(1, 0)).has("d42_boss_edge_r"), true, "boss A right end keeps edge next to boss B")
	_eq(_parts_of(b, Vector2i(2, 0)).has("d42_boss_edge_l"), true, "boss B left end keeps edge next to boss A")


# ---------- 掉格 ----------

func _t_drop_cells() -> void:
	# H20 N4 → [20, 15, 10, 5, 0]
	var m := _mk()
	var cells := _shift(SHAPES["S1"], Vector2i(2, 5))
	var bs = _boss(m, cells, 20)
	m._boss_damage(bs, 4)
	_eq([bs.layers, bs.cells.size(), _on_grid(m, bs)], [16, 4, 4], "16 > 15: no drop")
	m._boss_damage(bs, 1)
	_eq([bs.layers, bs.cells.size(), _on_grid(m, bs)], [15, 3, 3], "15 <= 15: drop 1 immediately")
	_eq(m.anims.filter(func(a: Dictionary) -> bool: return a["kind"] == "boss_break").size(), 1, "1 boss_break anim")
	# 掉的那格不再碰撞:找出被移除的格,球放在格內
	var gone: Vector2i = cells.filter(func(c: Vector2i) -> bool: return c not in bs.cells)[0]
	var b = _ball(m, _center(gone), Vector2.UP)
	m._ball_bricks(b, false)
	_eq([b.pos, bs.layers], [_center(gone), 15], "dropped cell no longer collides")
	m.free()
	# 一次跨 2 個門檻:同時掉 2 格,第 2 格錯開 100 ms
	var s := _mk()
	var bs2 = _boss(s, _shift(SHAPES["S1"], Vector2i(2, 5)), 20)
	s._boss_damage(bs2, 11)
	_eq([bs2.layers, bs2.cells.size(), _on_grid(s, bs2)], [9, 2, 3], "cross 2 thresholds: logic 2 left, grid 3 at t=0")
	_run(s, 0.09)
	_eq(_on_grid(s, bs2), 3, "second cell still on grid at 90 ms")
	_run(s, 0.02)
	_eq(_on_grid(s, bs2), 2, "second cell drops at 100 ms")
	s.free()
	# 歸零:剩下 4 格依序 0 / 100 / 200 / 300 ms 掉,+1000
	var z := _mk()
	_layer(z, Vector2i(0, 0), 1)
	var bs3 = _boss(z, _shift(SHAPES["S1"], Vector2i(2, 5)), 20)
	var before: int = z.score
	z._boss_damage(bs3, 25)
	_eq(z.score - before, 20 * 100 + 1000, "kill: only remaining layers x100 + 1000")
	var seen := [_on_grid(z, bs3)]
	_run(z, 0.05)
	for i in 3:
		_run(z, 0.1)
		seen.append(_on_grid(z, bs3))   # 取樣在 150 / 250 / 350 ms
	_eq(seen, [3, 2, 1, 0], "4 cells at 0/100/200/300 ms")
	z.free()
	# 掉格位置隨機:多個種子下第一格各位置都出現過
	var first := {}
	for sd in 200:
		var r := _mk(sd)
		var c4 := _shift(SHAPES["S1"], Vector2i(2, 5))
		var bb = _boss(r, c4, 20)
		r._boss_damage(bb, 5)
		for c in c4:
			if r.grid[c.y][c.x] == null:
				first[c] = true
		r.free()
	_eq(first.size(), 4, "first dropped cell is random (all 4 positions seen over 200 seeds)")
	# 回血(工程師自訂):最多回到總層數,掉的格不長回來;之後扣血再依門檻掉
	var h := _mk()
	var bs4 = _boss(h, _shift(SHAPES["S1"], Vector2i(2, 5)), 20)
	h._boss_damage(bs4, 6)
	h._boss_heal(bs4, 100)
	_eq([bs4.layers, bs4.cells.size(), _on_grid(h, bs4)], [20, 3, 3], "heal caps at max, dropped cell does not grow back")
	h._boss_damage(bs4, 6)
	_eq([bs4.layers, bs4.cells.size()], [14, 3], "after heal: 14 still 3 cells (15 threshold already used)")
	h._boss_damage(bs4, 4)
	_eq([bs4.layers, bs4.cells.size()], [10, 2], "after heal: 10 drops next")
	h.free()


# ---------- 球打魔王 ----------

## 球放在第 cell 格正下方、往上,剛好碰到。
func _hit_from_below(m: Node2D, cell: Vector2i) -> Object:
	var b = _ball(m, Vector2(_center(cell).x, _pos(cell).y + 20 + 7), Vector2.UP)
	m._ball_bricks(b, m._pierce_on())
	return b


func _t_boss_ball() -> void:
	var cells := _shift(SHAPES["S1"], Vector2i(2, 5))
	# 一般:扣 1、+100、該格閃白、球反彈
	var m := _mk()
	var bs = _boss(m, cells, 100)
	var b = _hit_from_below(m, Vector2i(3, 5))
	_eq([bs.layers, m.score, b.dir.y > 0.0], [99, 100, true], "ball: -1, +100, bounce")
	_ok(m.grid[5][3].hit_t > 0.0 and m.grid[5][2].hit_t <= 0.0, "only the hit cell flashes")
	m.free()
	# 強化 +3:扣 4
	var r := _mk()
	var bsr = _boss(r, cells, 100)
	r.effects.reinforce = 3
	_hit_from_below(r, Vector2i(3, 5))
	_eq(bsr.layers, 96, "reinforce 3: -4")
	r.free()
	# 火焰:扣 2、周圍 3×3 不重複算自己、另一隻魔王 -1、一般磚 -1
	var f := _mk()
	var bsf = _boss(f, cells, 100)
	var other = _boss(f, [Vector2i(4, 6)], 100, "B2")
	var nb = _layer(f, Vector2i(2, 6), 3)
	f.effects.add_timed("flame", 10.0)
	_hit_from_below(f, Vector2i(3, 6) + Vector2i(0, -1))
	_eq([bsf.layers, other.layers, nb.layers], [98, 99, 2], "flame: self -2 once, other boss -1, neighbour brick -1")
	f.free()
	# 火焰 + 強化
	var fr := _mk()
	var bsfr = _boss(fr, cells, 100)
	fr.effects.add_timed("flame", 10.0)
	fr.effects.reinforce = 7
	_hit_from_below(fr, Vector2i(3, 5))
	_eq(bsfr.layers, 91, "flame + reinforce 7: -9")
	fr.free()
	# 無敵不影響魔王:照扣
	var inv := _mk()
	var bsi = _boss(inv, cells, 100)
	inv.effects.add_timed("invincible", 10.0)
	_hit_from_below(inv, Vector2i(3, 5))
	_eq(bsi.layers, 99, "invincible: ball still -1 on boss")
	inv.free()
	# 穿透(工程師自訂):照常反彈、扣血
	var p := _mk()
	var bsp = _boss(p, cells, 100)
	p.effects.add_timed("pierce", 10.0)
	var pb = _hit_from_below(p, Vector2i(3, 5))
	_eq([bsp.layers, pb.dir.y > 0.0], [99, true], "pierce: boss bounces + -1")
	p.free()
	# 穿透結束時球在魔王格內(工程師自訂):扣 1,跨兩格只算 1 次;同時壓到兩隻各扣 1
	var pe := _mk()
	var bse = _boss(pe, cells, 100)
	_ball(pe, Vector2(_pos(Vector2i(3, 5)).x, _center(Vector2i(3, 5)).y), Vector2.UP)   # 壓在 (2,5)/(3,5) 交界
	pe._pierce_end()
	_eq(bse.layers, 99, "pierce end inside boss (2 cells): -1 once")
	pe.free()
	var pe2 := _mk()
	var x1 = _boss(pe2, [Vector2i(2, 5)], 100)
	var x2 = _boss(pe2, [Vector2i(3, 5)], 100, "B2")
	_ball(pe2, Vector2(_pos(Vector2i(3, 5)).x, _center(Vector2i(3, 5)).y), Vector2.UP)
	pe2._pierce_end()
	_eq([x1.layers, x2.layers], [99, 99], "pierce end over 2 bosses: each -1")
	pe2.free()
	# 回血:+1,不超過總層數;範圍回血 +2
	var hl := _mk()
	var bsh = _boss(hl, cells, 100)
	hl._boss_damage(bsh, 10)
	hl.effects.add_timed("heal", 10.0)
	_hit_from_below(hl, Vector2i(3, 5))
	_eq(bsh.layers, 91, "heal: +1")
	hl.effects.timed.erase("heal")
	hl.effects.add_timed("heal_area", 10.0)
	_hit_from_below(hl, Vector2i(3, 5))
	_eq(bsh.layers, 93, "heal_area: +2")
	hl.free()


# ---------- 魔王掉落 20% / 5% ----------

func _t_boss_items() -> void:
	var m := _mk(5)
	var bs = _boss(m, _shift(SHAPES["S1"], Vector2i(2, 5)), 1000000)
	var buff := 0
	var debuff := 0
	var multi := 0
	var bad_pos := 0
	var trials := 20000
	var b = MainScript.Ball.new()
	for i in trials:
		m.items.clear()
		b.pos = Vector2(_center(Vector2i(3, 5)).x, _pos(Vector2i(3, 5)).y + 20 + 8)
		m._boss_ball_hit(Vector2i(3, 5), b)
		var c := _count_items(m)
		buff += c[0]
		debuff += c[1]
		if c[0] + c[1] > 1:
			multi += 1
		for it in m.items:
			# items 的 pos = 圖示中心 − 8;中心應在被擊中那格的範圍內(擊中點)
			var ctr: Vector2 = it["pos"] + Vector2(8, 8)
			if not Rect2(_pos(Vector2i(3, 5)), Vector2(40, 20)).grow(0.01).has_point(ctr):
				bad_pos += 1
	_eq(multi, 0, "one ball hit drops at most 1 item")
	_near(float(debuff) / trials, 0.20, 0.012, "debuff drop rate 20%")
	_near(float(buff) / trials, 0.05, 0.006, "buff drop rate 5%")
	_eq(bad_pos, 0, "drop spawns at hit point inside the hit cell")
	m.free()
	# 不吃一般 30%:drop_chance = 1 時,子彈、雷射、閃電、炸彈打魔王或魔王掉格都不掉道具
	var n := _mk()
	n.cfg.drop_chance = 1.0
	var bs2 = _boss(n, _shift(SHAPES["S1"], Vector2i(2, 5)), 20)
	n.bullets = [Vector2(_bx(3), _pos(Vector2i(3, 6)).y + 4)]
	n._update_bullets(0.02)
	n._lightning(1)
	_run(n, 0.5)
	n._boss_damage(bs2, 30)
	_run(n, 1.0)
	_eq([n.items.size(), bs2.layers], [0, 0], "bullet / lightning / cell drops / death never use 30% drop")
	n.free()


# ---------- 其他效果打魔王 ----------

func _t_boss_effects() -> void:
	var cells := _shift(SHAPES["S1"], Vector2i(2, 5))
	# 子彈:-1、被擋下(上方磚不受影響);無敵中也照扣
	for inv in [false, true]:
		var m := _mk()
		var bs = _boss(m, cells, 100)
		var above = _layer(m, Vector2i(3, 3), 5)
		if inv:
			m.effects.add_timed("invincible", 10.0)
		m.bullets = [Vector2(_bx(3), _pos(Vector2i(3, 6)).y + 4)]
		for i in 5:
			m._update_bullets(0.02)
		_eq([bs.layers, m.bullets.size(), above.layers, m.score], [99, 0, 5, 100], "bullet: -1, stopped (invincible=%s)" % inv)
		m.free()
	# 雷射:被魔王擋下、-1,魔王另一側的磚不受影響
	var l := _mk()
	var bsl = _boss(l, cells, 100)
	_fn(l, Vector2i(1, 5), "laser_h", 2)
	var far = _layer(l, Vector2i(7, 5), 5)
	var left = _layer(l, Vector2i(0, 5), 5)
	l._trigger(Vector2i(1, 5))
	_run(l, 0.3)
	_eq([bsl.layers, far.layers, left.layers], [99, 5, 4], "laser_h: boss -1 and blocks; other side untouched")
	l.free()
	# 十字雷射兩道光束都被同一隻擋下(規格未定):記錄
	var lx := _mk()
	var bsx = _boss(lx, [Vector2i(3, 5), Vector2i(2, 5), Vector2i(2, 6)], 100)
	_fn(lx, Vector2i(3, 6), "laser_x", 2)
	lx._trigger(Vector2i(3, 6))
	_run(lx, 0.3)
	print("INFO laser_x with 2 beams blocked by the same boss: boss -%d (engineer: each beam counts)" % (100 - bsx.layers))
	lx.free()
	# 閃電:每隻魔王算 1 個目標、-2;道數多於目標時不重複
	var z := _mk(3)
	var bz = _boss(z, cells, 100)
	var bz2 = _boss(z, [Vector2i(3, 10), Vector2i(4, 10)], 100, "B2")
	var one = _layer(z, Vector2i(0, 0), 5)
	z._lightning(9)
	_run(z, 1.5)
	_eq([bz.layers, bz2.layers, one.layers], [98, 98, 3], "lightning x9: each boss is one target (-2), brick -2")
	z.free()
	var hits := {}
	for sd in 100:
		var zz := _mk(sd)
		var bb = _boss(zz, cells, 100)
		_layer(zz, Vector2i(0, 0), 5)
		_layer(zz, Vector2i(7, 0), 5)
		zz._lightning(1)
		_run(zz, 0.5)
		hits[bb.layers] = hits.get(bb.layers, 0) + 1
		zz.free()
	print("INFO lightning x1 with 1 boss + 2 bricks over 100 seeds: boss hp after -> %s (boss is 1 of 3 targets)" % hits)
	_ok(hits.get(98, 0) > 15 and hits.get(98, 0) < 55, "lightning x1: boss chosen about 1/3 of the time (%d/100)" % hits.get(98, 0))
	# 炸彈:球碰魔王只標記不扣;結束時 -10、以標記格為中心 3×3 -2(不波及自己)、另一隻 -2
	var bm := _mk()
	var bsb = _boss(bm, cells, 100)
	var other = _boss(bm, [Vector2i(6, 4)], 100, "B2")
	var n1 = _layer(bm, Vector2i(4, 4), 5)
	var n2 = _layer(bm, Vector2i(0, 4), 5)
	bm.effects.add_timed("bomb", 10.0)
	_hit_from_below(bm, Vector2i(3, 5))
	_eq([bsb.layers, bsb.marked, bm.score], [100, true, 0], "bomb: ball marks boss, no damage")
	_eq(bm._boss_mark_cell(bsb), Vector2i(5, 5), "mark cell = top row, rightmost")
	bm._bomb_explode()
	_eq([bsb.layers, other.layers, n1.layers, n2.layers, bsb.marked], [90, 98, 3, 5, false],
		"bomb end: boss -10, 3x3 around mark (5,5): other boss -2, brick (4,4) -2, far brick untouched")
	bm.free()
	# 炸彈 + 無敵:魔王照扣 -10;被標記的一般磚旁邊的魔王 -2
	var bi := _mk()
	var bsi = _boss(bi, cells, 100)
	var mk = _layer(bi, Vector2i(3, 4), 5)
	bi.effects.add_timed("bomb", 10.0)
	_hit_from_below(bi, Vector2i(3, 5))
	mk.marked = true
	bi.effects.add_timed("invincible", 10.0)
	bi._bomb_explode()
	_eq([bsi.layers, mk.layers], [88, 5], "bomb end during invincible: boss -10 (+ -2 from marked brick's 3x3), normal bricks protected")
	bi.free()
	var bn := _mk()
	var bsn = _boss(bn, cells, 100)
	var mk2 = _layer(bn, Vector2i(3, 4), 5)
	mk2.marked = true
	bn._bomb_explode()
	_eq([bsn.layers, bn.grid[4][3]], [98, null], "marked brick next to boss: brick destroyed, boss -2 once")
	bn.free()
	# 爆炸磚:魔王不受影響
	var e := _mk()
	var bse = _boss(e, cells, 100)
	_fn(e, Vector2i(1, 5), "explosion")
	e._trigger(Vector2i(1, 5))
	_run(e, 0.5)
	_eq([bse.layers, _on_grid(e, bse)], [100, 4], "explosion: boss unaffected")
	e.free()
	# 無敵不影響魔王:雷射、閃電在無敵中不觸發(功能型磚不發動),但已在飛的子彈 / 炸彈照扣(上面已測)
	# 一擊必殺:成長系統未實作,無法驗證(見回報)


# ---------- 勝利與清場 ----------

func _t_victory() -> void:
	var m := _mk()
	var b1 = _boss(m, _shift(SHAPES["S1"], Vector2i(0, 9)), 10)
	var b2 = _boss(m, [Vector2i(5, 9), Vector2i(6, 9)], 10, "B2")
	var bricks := [Vector2i(0, 0), Vector2i(3, 2), Vector2i(7, 4)]
	for c in bricks:
		_layer(m, c, 9)
	_special(m, Vector2i(1, 1), "coin")
	_fn(m, Vector2i(2, 1), "lightning", 3)
	_fn(m, Vector2i(5, 12), "teleport")
	_fn(m, Vector2i(6, 12), "teleport")
	_unb(m, Vector2i(4, 4))
	m._boss_damage(b1, 10)
	_eq(m.state, MainScript.State.PLAYING, "one boss dead: still playing")
	_run(m, 0.5)
	var score_before: int = m.score
	m._boss_damage(b2, 10)
	_eq(m.state, MainScript.State.CLEARING, "all bosses dead: CLEARING")
	_eq(m.score - score_before, 10 * 100 + 1000, "boss 2 kill score")
	score_before = m.score
	# 清場:一般磚、特殊磚、功能型磚依序消失(間隔 0.02 秒),不計分;U、傳送磚留下
	_run(m, 0.7)
	_eq([m.grid[0][0], m.grid[1][1], m.grid[1][2], m.grid[2][3], m.grid[4][7]], [null, null, null, null, null], "remaining bricks cleared")
	_ok(m.grid[4][4] != null and m.grid[12][5] != null and m.grid[12][6] != null, "U and teleports stay")
	_eq(m.state, MainScript.State.ENDED, "ends after clearing")
	_eq(m.score - score_before, floori(m.time_left) * m.cfg.score_per_second, "clearing adds no score (only time bonus)")
	m.free()
	# 清場順序與間隔
	var o := _mk()
	var ob = _boss(o, [Vector2i(0, 9)], 1)
	for c in [Vector2i(5, 0), Vector2i(1, 2), Vector2i(2, 2)]:
		_layer(o, c, 3)
	o._boss_damage(ob, 1)
	var order := []
	for i in 60:
		o._update_anims(0.005)
		o._update_events(0.005)
		for a in o.anims:
			if a["kind"] == "dust" and a["t"] == 0.0:
				order.append([a["pos"], snappedf((i + 1) * 0.005, 0.005)])
	_eq(order.map(func(x: Array) -> Vector2: return x[0]), [_pos(Vector2i(5, 0)), _pos(Vector2i(1, 2)), _pos(Vector2i(2, 2))], "dust order top-to-bottom, left-to-right")
	if order.size() == 3:
		_near(order[1][1] - order[0][1], 0.02, 0.006, "dust stagger 0.02 s")
		_near(order[0][1], 0.24, 0.011, "clearing starts after last cell break (4 frames)")
	o.free()
	# 一般磚全清但魔王還活著:不過關
	var g := _mk()
	_boss(g, [Vector2i(0, 9)], 10)
	_layer(g, Vector2i(3, 3), 1)
	g._damage(Vector2i(3, 3), 1)
	_eq([g.state, g.breakable_left], [MainScript.State.PLAYING, 0], "normal bricks all gone but boss alive: keep playing")
	g.free()


# ---------- 裂痕、血條 ----------

func _t_crack_bar() -> void:
	var t := Rules.boss_thresholds(20, 4)
	_eq([Rules.boss_crack(20, 4, t), Rules.boss_crack(19, 4, t), Rules.boss_crack(18, 4, t), Rules.boss_crack(17, 4, t),
		Rules.boss_crack(16, 4, t), Rules.boss_crack(15, 3, t), Rules.boss_crack(17, 3, t)], [0, 0, 1, 1, 2, 0, 0],
		"crack: <1/3 none, 1/3~2/3 crack1, >=2/3 crack2, reset on drop, healed above segment = none")
	_eq([Rules.boss_bar_fill(50, 50, 306), Rules.boss_bar_fill(1, 50, 146), Rules.boss_bar_fill(0, 50, 146),
		Rules.boss_bar_fill(25, 50, 146)], [306, 3, 0, 73], "bar fill = ceil(inner x layers / total)")
	# 刻度位置(main._draw_boss_bar 的算式):146 內槽 4 格 = 37、73、110(D43)
	var ticks := []
	for j in range(1, 4):
		ticks.append(roundi(146 * float(j) / 4))
	_eq(ticks, [37, 73, 110], "tick offsets 37/73/110 for inner 146")


# ---------- 寶箱 ----------

func _t_chest() -> void:
	var trials := 4000
	var buff := 0
	var count_bad := 0
	var score_bad := 0
	for sd in trials:
		var m := _mk(sd)
		m.cfg.drop_chance = 0.0   # 不吃 30%:就算一般掉落機率 0 也必掉
		_special(m, Vector2i(3, 5), "chest")
		_layer(m, Vector2i(0, 0), 1)
		m._damage(Vector2i(3, 5), 1)
		if m.items.size() != 1:
			count_bad += 1
		else:
			buff += 1 if ItemDefs.is_buff(m.items[0]["id"]) else 0
			if m.items[0]["pos"] + Vector2(8, 8) != _center(Vector2i(3, 5)):
				count_bad += 1
		if m.score != 200:
			score_bad += 1
		m.free()
	_eq(count_bad, 0, "chest: exactly 1 item at brick center every time (drop_chance 0)")
	_near(float(buff) / trials, 0.7, 0.025, "chest: 70% buff")
	_eq(score_bad, 0, "chest: +200")
	# drop_chance = 1 也只掉 1 個
	var one := _mk()
	one.cfg.drop_chance = 1.0
	_special(one, Vector2i(3, 5), "chest")
	_layer(one, Vector2i(0, 0), 1)
	one._damage(Vector2i(3, 5), 1)
	_eq(one.items.size(), 1, "chest: still exactly 1 item when drop_chance = 1")
	one.free()


# ---------- 金幣磚 ----------

func _t_coin() -> void:
	var trials := 6000
	var items := 0
	var coin_bad := 0
	var values := {10: 0, 50: 0, 100: 0}
	var pos_bad := 0
	for sd in trials:
		var m := _mk(sd)
		_special(m, Vector2i(3, 5), "coin")
		_layer(m, Vector2i(0, 0), 1)
		m._damage(Vector2i(3, 5), 1)
		items += m.items.size()
		if m.coins.size() != 1:
			coin_bad += 1
		else:
			values[m.coins[0]["value"]] = values.get(m.coins[0]["value"], 0) + 1
			if m.coins[0]["pos"] != _center(Vector2i(3, 5)):
				pos_bad += 1
		if m.score != 200 or m.coins_caught != 0:
			coin_bad += 1
		m.free()
	_eq(coin_bad, 0, "coin brick: always exactly 1 coin, +200, nothing caught yet")
	_eq(pos_bad, 0, "coin spawns at brick center")
	_near(float(items) / trials, 0.3, 0.02, "coin brick: normal 30% item drop")
	_near(float(values[10]) / trials, 0.6, 0.02, "coin 10: 60%")
	_near(float(values[50]) / trials, 0.3, 0.02, "coin 50: 30%")
	_near(float(values[100]) / trials, 0.1, 0.012, "coin 100: 10%")
	_eq(values.keys().size(), 3, "only 10/50/100")
	_eq([Rules.coin_value(0.0, [10, 50, 100], [0.6, 0.3, 0.1]), Rules.coin_value(0.5999, [10, 50, 100], [0.6, 0.3, 0.1]),
		Rules.coin_value(0.6, [10, 50, 100], [0.6, 0.3, 0.1]), Rules.coin_value(0.8999, [10, 50, 100], [0.6, 0.3, 0.1]),
		Rules.coin_value(0.9, [10, 50, 100], [0.6, 0.3, 0.1]), Rules.coin_value(0.99999, [10, 50, 100], [0.6, 0.3, 0.1])],
		[10, 10, 50, 50, 100, 100], "coin_value boundaries")


func _t_coin_catch() -> void:
	# 接到:擋板(x 137.5~222.5、y 755~771)正上方;計入 coins_caught,與分數分開
	for v in [10, 50, 100]:
		var m := _mk()
		var py: float = m._paddle_y()
		m.coins = [{"value": v, "pos": Vector2(180, py - 20)}]
		var frames := 0
		while not m.coins.is_empty() and frames < 200:
			m._update_coins(1.0 / 60.0)
			frames += 1
		_eq([m.coins_caught, m.score], [v, 0], "coin %d caught: coins_caught += %d, score unchanged" % [v, v])
		_eq(m.anims.filter(func(a: Dictionary) -> bool: return a["kind"] == "coin_pick").size(), 1, "coin %d: pick effect" % v)
		m.free()
	# 沒接到:落到畫面外消失,不計、不扣
	var miss := _mk()
	miss.coins = [{"value": 100, "pos": Vector2(30, 700)}]
	var steps := 0
	while not miss.coins.is_empty() and steps < 600:
		miss._update_coins(1.0 / 60.0)
		steps += 1
	_eq([miss.coins.size(), miss.coins_caught, miss.score], [0, 0, 0], "coin missed: removed off screen, nothing counted")
	# 上緣離開畫面底才移除
	_ok(steps * (1.0 / 60.0) * miss.cfg.item_fall_speed >= (800 + 8) - 700 - 2, "coin removed only after its top leaves the screen")
	miss.free()
	# 尺寸(使用者決定):10 = 16×16、50 = 18×18、100 = 20×20;矩形中心 = 金幣中心
	var px := {10: 16, 50: 18, 100: 20}
	var sz := _mk()
	for v in px:
		var s: int = px[v]
		_eq(sz._coin_rect(v, Vector2(180, 178)), Rect2(180 - s / 2.0, 178 - s / 2.0, s, s), "coin %d rect %dx%d centered" % [v, s, s])
		for f in [1, 2, 3, 4]:
			_eq(sz._t("d41_coin_%d_f%d" % [v, f]).get_size(), Vector2(s, s), "coin %d F%d texture %dx%d" % [v, f, s, s])
		_ok(sz._coin_has_art(v), "coin %d has art" % v)
	# 置中對齊磚中心:磚 (3,5) 中心,繪圖左上 = 中心 - 尺寸/2(整數)
	var cc := _center(Vector2i(3, 5))
	for v in px:
		var s: int = px[v]
		var r: Rect2 = sz._coin_rect(v, cc)
		_eq([r.get_center(), r.position.floor(), r.position.floor() == r.position], [cc, cc - Vector2(s, s) / 2.0, true],
			"coin %d on brick center: draw at center - %d (pixel aligned)" % [v, s / 2])
	sz.free()
	# 擋板邊緣(三種面額,左右兩側、上緣):重疊 1 px 算接到、剛好相切不算
	for v in px:
		var half: float = px[v] / 2.0
		var edge := _mk()
		var len: float = edge._paddle_len()
		var left: float = edge._paddle_left(len)
		var right: float = left + len
		var py2: float = edge._paddle_y()
		var cases := [
			[Vector2(left - half + 1, py2 + 8), v, "left edge overlap 1 px"],
			[Vector2(left - half, py2 + 8), 0, "left edge touching"],
			[Vector2(right + half - 1, py2 + 8), v, "right edge overlap 1 px"],
			[Vector2(right + half, py2 + 8), 0, "right edge touching"],
			[Vector2(left + len / 2, py2 - half + 1), v, "top edge overlap 1 px"],
			[Vector2(left + len / 2, py2 - half), 0, "top edge touching"],
		]
		for c in cases:
			edge.coins_caught = 0
			edge.coins = [{"value": v, "pos": c[0]}]
			edge._update_coins(0.0)
			_eq(edge.coins_caught, c[1], "coin %d %s" % [v, c[2]])
		edge.free()
	# 沒有對應圖的面額:不生成、不當掉(會 push_error),分數與道具照常
	var bad := _mk()
	_ok(not bad._coin_has_art(7) and not bad._coin_has_art(0) and not bad._coin_has_art(-10), "values 7 / 0 / -10 have no art")
	var v7: Array[int] = [7]
	var w1: Array[float] = [1.0]
	bad.cfg.coin_values = v7
	bad.cfg.coin_weights = w1
	_special(bad, Vector2i(3, 5), "coin")
	_layer(bad, Vector2i(0, 0), 1)
	bad._damage(Vector2i(3, 5), 1)
	_eq([bad.coins.size(), bad.score, bad.grid[5][3]], [0, 200, null], "coin value without art: skipped, brick still breaks, +200")
	bad._update_coins(1.0 / 60.0)
	_eq(bad.coins_caught, 0, "no coins caught after skip")
	# 混合:有圖的照常生成
	var v750: Array[int] = [7, 50]
	var w55: Array[float] = [0.5, 0.5]
	bad.cfg.coin_values = v750
	bad.cfg.coin_weights = w55
	var made := 0
	for i in 40:
		_special(bad, Vector2i(3, 5), "coin")
		bad._damage(Vector2i(3, 5), 1)
	for co in bad.coins:
		if co["value"] == 50:
			made += 1
	_ok(made == bad.coins.size() and made > 0 and made < 40, "mixed [7, 50]: only 50 spawned (%d / 40)" % made)
	bad.free()
	_ok(true, "coin_catch section reached the end (no script error)")
	# 完整流程:打破金幣磚 → 金幣從磚中心落下 → 擋板接到
	var full := _mk(4)
	_special(full, Vector2i(4, 5), "coin")
	_layer(full, Vector2i(0, 0), 1)
	full._damage(Vector2i(4, 5), 1)
	var val: int = full.coins[0]["value"]
	full.paddle_x = _center(Vector2i(4, 5)).x
	for i in 600:
		full._update_coins(1.0 / 60.0)
	_eq(full.coins_caught, val, "coin from brick falls and is caught (value %d)" % val)
	# 結束畫面列出接到的金幣(分數 1% 另外一項)
	full.score = 1234
	full._end(false, "test")
	var label: Label = null
	for ch in full.get_children():
		for g in ch.get_children():
			if g is Label:
				label = g
	_ok(label != null and ("接到 %d" % val) in label.text and "分數換算 12" in label.text, "end screen shows score-gold and caught coins separately")
	# 結束後接到的不計
	full.coins = [{"value": 100, "pos": Vector2(full.paddle_x, full._paddle_y() + 8)}]
	full._update_coins(0.0)
	_eq(full.coins_caught, val, "coin caught after game end: not counted")
	full.free()


# ---------- 圓形磚 ----------

func _angle_ok(d: Vector2, n: Vector2, min_deg: float) -> String:
	if absf(d.length() - 1.0) > 1e-5:
		return "not unit"
	if d.dot(n) <= 0.0:
		return "not leaving the circle (d.n=%.3f)" % d.dot(n)
	if absf(d.y) < sin(deg_to_rad(min_deg)) - 1e-6:
		return "too flat (%.2f deg)" % rad_to_deg(asin(absf(d.y)))
	return ""


func _t_circle_rules() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var bad := []
	var flats := 0.0
	var by_quadrant := {}
	var min_seen := 90.0
	for deg in 360:
		var n := Vector2.from_angle(deg_to_rad(deg))
		for i in 200:
			var d := Rules.circle_bounce(n, rng, 15.0)
			var e := _angle_ok(d, n, 15.0)
			if e != "":
				bad.append("n=%d: %s" % [deg, e])
			min_seen = minf(min_seen, rad_to_deg(asin(absf(d.y))))
	_eq(bad.slice(0, 5), [], "72000 samples: unit, d.n > 0, >= 15 deg from horizontal")
	_ok(min_seen < 16.0, "angles reach near 15 deg (min %.2f)" % min_seen)
	# 隨機性:法線朝上時,角度分布橫跨 15~165 度、各 30 度區間都有
	var bins := {}
	for i in 6000:
		var d := Rules.circle_bounce(Vector2.UP, rng, 15.0)
		var a := rad_to_deg(atan2(-d.y, d.x))
		bins[int((a - 15.0) / 30.0)] = bins.get(int((a - 15.0) / 30.0), 0) + 1
	_eq(bins.keys().size(), 5, "normal UP: every 30-deg band of 15~165 used")
	var ok_bins := true
	for k in bins:
		ok_bins = ok_bins and bins[k] > 900 and bins[k] < 1500
	_ok(ok_bins, "normal UP: roughly uniform over angle (%s)" % bins)
	# 法線接近水平(例:撞圓的正側面)仍朝外且 >= 15 度
	var side_bad := 0
	for i in 2000:
		var n := Vector2(1, 0.01).normalized()
		if _angle_ok(Rules.circle_bounce(n, rng, 15.0), n, 15.0) != "":
			side_bad += 1
	_eq(side_bad, 0, "near-horizontal normal: still valid")


func _t_circle_collision() -> void:
	var cell := Vector2i(3, 5)
	var c := _center(cell)
	# 碰撞半徑 10 + 球 8 = 18
	for d in [[17.9, true], [18.1, false]]:
		var m := _mk()
		_special(m, cell, "circle")
		_layer(m, Vector2i(0, 0), 1)
		var b = _ball(m, c + Vector2(0, d[0]), Vector2.UP)
		m._ball_bricks(b, false)
		_eq(m.grid[5][3] == null, d[1], "circle hit at center distance %.1f = %s" % [d[0], d[1]])
		m.free()
	# 方形會碰、圓形不會碰的位置(格的左上角外側)
	var m2 := _mk()
	var cb = _special(m2, cell, "circle")
	_layer(m2, Vector2i(0, 0), 1)
	var b2 = _ball(m2, _pos(cell) + Vector2(-4, 2), Vector2(1, 0.3))
	m2._ball_bricks(b2, false)
	_eq([m2.grid[5][3] == cb, b2.pos], [true, _pos(cell) + Vector2(-4, 2)], "rect corner area: circle not touched")
	m2.free()
	# 各方向打圓形:破壞 +200、反彈方向 = 隨機、朝外、>= 15 度
	var bad := []
	var dirs := {}
	for i in 720:
		var m := _mk(i)
		_special(m, cell, "circle")
		_layer(m, Vector2i(0, 0), 1)
		var ang := deg_to_rad(i * 0.5)
		var n := Vector2.from_angle(ang)
		var b = _ball(m, c + n * 17.5, -n)
		m._ball_bricks(b, false)
		var e := _angle_ok(b.dir, n, 15.0)
		if e != "":
			bad.append("%.1f: %s" % [i * 0.5, e])
		if m.score != 200 or m.grid[5][3] != null:
			bad.append("%.1f: score %d" % [i * 0.5, m.score])
		if (b.pos - c).length() < 18.0 - 1e-3:
			bad.append("%.1f: ball still overlaps" % (i * 0.5))
		dirs[snappedf(b.dir.angle(), 0.001)] = true
		m.free()
	_eq(bad.slice(0, 5), [], "720 approach angles: break +200, bounce outward >= 15 deg, pushed out")
	_ok(dirs.size() > 500, "bounce directions are random (%d distinct)" % dirs.size())
	# 同一入射重複多次:結果不固定
	var same := {}
	for i in 50:
		var m := _mk(1000 + i)
		_special(m, cell, "circle")
		_layer(m, Vector2i(0, 0), 1)
		var b = _ball(m, c + Vector2(0, 17.5), Vector2.UP)
		m._ball_bricks(b, false)
		same[snappedf(b.dir.angle(), 0.01)] = true
		m.free()
	_ok(same.size() > 30, "same hit, different seeds -> different angles (%d)" % same.size())
	# 子彈:判定點在圓外(離圓心 >= 10)穿過,圓內打到
	var bl := _mk()
	var cc = _special(bl, cell, "circle")
	_layer(bl, Vector2i(0, 0), 1)
	bl.bullets = [Vector2(_bx(3), _pos(Vector2i(3, 7)).y)]
	for i in 10:
		bl._update_bullets(0.02)
	_eq(bl.grid[5][3], cc, "bullet beside the circle passes")
	bl.bullets = [Vector2(_center(cell).x - 2, _pos(Vector2i(3, 7)).y)]
	for i in 10:
		bl._update_bullets(0.02)
	_eq(bl.grid[5][3], null, "bullet through the circle breaks it")
	bl.free()


# ---------- 特殊磚共通 ----------

func _t_specials_common() -> void:
	for kind in ["chest", "coin", "circle"]:
		# 固定 1 層:火焰 + 強化 7 也只 +200
		var m := _mk()
		_special(m, Vector2i(3, 5), kind)
		_layer(m, Vector2i(0, 0), 1)
		m.effects.add_timed("flame", 10.0)
		m.effects.reinforce = 7
		m._ball_hit_brick(Vector2i(3, 5))
		_eq([m.grid[5][3], m.score], [null, 200], "%s: 1 layer, +200 even with flame + reinforce" % kind)
		m.free()
		# 回血不加層
		var h := _mk()
		var br = _special(h, Vector2i(3, 5), kind)
		h.effects.add_timed("heal_area", 10.0)
		h._ball_hit_brick(Vector2i(3, 5))
		_eq(br.layers, 1, "%s: heal does not add layers" % kind)
		h.free()
		# 彩虹不挑:場上只有特殊磚 → 彩虹直接破壞,特殊磚留著
		var r := _mk()
		var sp = _special(r, Vector2i(3, 5), kind)
		_fn(r, Vector2i(0, 0), "rainbow")
		r._trigger(Vector2i(0, 0))
		_run(r, 0.6)
		_eq([r.grid[5][3], r.grid[0][0]], [sp, null], "%s: rainbow never picks it" % kind)
		r.free()
		var r2 := _mk()
		var sp2 = _special(r2, Vector2i(3, 5), kind)
		_layer(r2, Vector2i(5, 5), 1)   # 紅
		_fn(r2, Vector2i(0, 0), "rainbow")
		r2._trigger(Vector2i(0, 0))
		_run(r2, 0.6)
		_eq([r2.grid[5][3], r2.grid[5][5]], [sp2, null], "%s: rainbow clears red, leaves special" % kind)
		r2.free()
		# 勝利條件包含特殊磚
		var w := _mk()
		_special(w, Vector2i(3, 5), kind)
		_layer(w, Vector2i(0, 0), 1)
		w._damage(Vector2i(0, 0), 1)
		_eq(w.state, MainScript.State.PLAYING, "%s left: not cleared" % kind)
		w._damage(Vector2i(3, 5), 1)
		_eq(w.state, MainScript.State.ENDED, "%s last: cleared" % kind)
		w.free()
	# 圓形磚破壞照常 30% 掉道具
	var items := 0
	for sd in 4000:
		var m := _mk(sd)
		_special(m, Vector2i(3, 5), "circle")
		_layer(m, Vector2i(0, 0), 1)
		m._damage(Vector2i(3, 5), 1)
		items += m.items.size()
		m.free()
	_near(items / 4000.0, 0.3, 0.025, "circle: normal 30% drop")


# ---------- 清場時空中的金幣與道具(修正:金幣全數計入、道具移除不生效) ----------

func _kinds(m: Node2D, kind: String) -> int:
	return m.anims.filter(func(a: Dictionary) -> bool: return a["kind"] == kind).size()


func _t_clearing_airborne() -> void:
	# 1) 多枚金幣(含重複面額)+ 增益/減益道具,最後一隻魔王被非球傷害打死
	var m := _mk()
	var b1 = _boss(m, [Vector2i(0, 9)], 2)
	var b2 = _boss(m, [Vector2i(5, 9)], 3, "B2")
	m._boss_damage(b1, 2)
	_eq(m.state, MainScript.State.PLAYING, "1st boss dead: still playing")
	m.coins_caught = 70   # 先前已接到的金幣
	var py: float = m._paddle_y()
	m.coins = [
		{"value": 10, "pos": Vector2(60, 300)},
		{"value": 50, "pos": Vector2(120, 500)},
		{"value": 100, "pos": Vector2(250, 650)},
		{"value": 100, "pos": Vector2(m.paddle_x, py)},   # 已壓在擋板上
		{"value": 10, "pos": Vector2(30, 900)},           # 已在畫面外但還沒被移除
	]
	m.items = [
		{"id": "slow", "pos": Vector2(100, 400)},
		{"id": "gun", "pos": Vector2(m.paddle_x - 8, py)},   # 已壓在擋板上
		{"id": "blackhole", "pos": Vector2(200, 600)},
	]
	var score0: int = m.score
	m._boss_damage(b2, 3)
	_eq(m.state, MainScript.State.CLEARING, "last boss dead: CLEARING")
	_eq(m.coins_caught, 70 + 10 + 50 + 100 + 100 + 10, "all airborne coins added at face value (+270 on top of 70)")
	_eq([m.coins.size(), m.items.size()], [0, 0], "coins and items removed at clearing start")
	_eq(m.score - score0, 3 * m.cfg.score_per_layer + m.cfg.score_boss_kill, "only boss damage/kill score, no item score")
	_eq([m.effects.is_active("gun"), m.effects.is_active("blackhole"), m.effects.ball_tier], [false, false, 0], "no item effect applied")
	_eq([_kinds(m, "pickup"), _kinds(m, "coin_pick")], [0, 0], "no pickup / coin-pick animation")
	var caught: int = m.coins_caught
	# 清場期間再呼叫各路徑:不重複計入
	m._boss_damage(b2, 1)
	m._update_coins(1.0 / 60.0)
	m._update_items(1.0 / 60.0)
	_eq([m.coins_caught, m.score - score0], [caught, 3 * m.cfg.score_per_layer + m.cfg.score_boss_kill], "repeat calls in CLEARING: no double count")
	_run(m, 1.0)
	_eq(m.state, MainScript.State.ENDED, "clearing ends")
	_eq(m.coins_caught, caught, "after end: coins_caught unchanged (no double count)")
	var label: Label = null
	for ch in m.get_children():
		for g in ch.get_children():
			if g is Label:
				label = g
	_ok(label != null and ("接到 %d" % caught) in label.text, "end screen shows caught coins incl. airborne (%d)" % caught)
	m.free()

	# 2) 空中沒有金幣、沒有道具:coins_caught 不變、不出錯
	var e := _mk()
	var eb = _boss(e, [Vector2i(0, 9)], 1)
	e.coins_caught = 50
	e._boss_damage(eb, 1)
	_eq([e.state, e.coins_caught, e.coins.size(), e.items.size()], [MainScript.State.CLEARING, 50, 0, 0], "no airborne coins: coins_caught unchanged")
	_run(e, 1.0)
	_eq([e.state, e.coins_caught], [MainScript.State.ENDED, 50], "no airborne coins: ends with same coins_caught")
	e.free()
	var z := _mk()
	var zb = _boss(z, [Vector2i(0, 9)], 1)
	z._boss_damage(zb, 1)
	_eq(z.coins_caught, 0, "no coins ever: coins_caught 0")
	z.free()

	# 3) 完整一幀 _step:球打死最後一隻魔王(會擲魔王掉落),同一幀稍後才更新道具與金幣;
	#    壓在擋板上的金幣只算一次、道具(含擊殺那一下掉的)不生效
	var drop_seen := 0
	var bad := []
	for sd in 200:
		var s := _mk(sd)
		var sb = _boss(s, [Vector2i(4, 16)], 1)
		var spy: float = s._paddle_y()
		s.coins = [{"value": 50, "pos": Vector2(s.paddle_x, spy + 8)}, {"value": 10, "pos": Vector2(60, 200)}]
		s.items = [{"id": "gun", "pos": Vector2(s.paddle_x - 8, spy)}]
		var cell := Vector2i(4, 16)
		var ball = _ball(s, Vector2(_center(cell).x, _pos(cell).y + 20 + 9), Vector2.UP)
		var sc0: int = s.score
		s._step(1.0 / 60.0)
		if s.state != MainScript.State.CLEARING:
			bad.append("seed %d: state %d (ball at %s)" % [sd, s.state, ball.pos])
		elif s.coins_caught != 60 or not s.coins.is_empty() or not s.items.is_empty() \
				or s.effects.is_active("gun") or s.score - sc0 != s.cfg.score_per_layer + s.cfg.score_boss_kill:
			bad.append("seed %d: caught=%d coins=%d items=%d gun=%s dscore=%d" % [sd, s.coins_caught, s.coins.size(), s.items.size(),
				s.effects.is_active("gun"), s.score - sc0])
		s.free()
	_eq(bad.slice(0, 3), [], "full _step kill: coins counted once (60), items removed, no item effect/score (200 seeds)")
	# 確認這種擊殺確實會擲出魔王掉落(否則上一項沒涵蓋「擊殺那一下掉的道具」)
	for sd in 200:
		var s2 := _mk(sd)
		var sb2 = _boss(s2, [Vector2i(4, 16)], 5)
		var c2 := Vector2i(4, 16)
		_ball(s2, Vector2(_center(c2).x, _pos(c2).y + 20 + 9), Vector2.UP)
		s2._step(1.0 / 60.0)
		drop_seen += s2.items.size()
		s2.free()
	_ok(drop_seen > 0, "same hit rolls boss drops when not lethal (%d / 200), so lethal-hit drops were covered" % drop_seen)

	# 4) 子彈打死最後一隻魔王(_update_bullets 之後才更新道具、金幣)
	var u := _mk()
	var ub = _boss(u, [Vector2i(4, 10)], 1)
	var upy: float = u._paddle_y()
	u.coins = [{"value": 100, "pos": Vector2(u.paddle_x, upy + 8)}]
	u.items = [{"id": "slow", "pos": Vector2(u.paddle_x - 8, upy)}]
	_ball(u, Vector2(30, 600), Vector2(0.3, 1).normalized())   # 球不碰魔王
	u.bullets = [Vector2(_bx(4), _pos(Vector2i(4, 10)).y + 20 + 5)]
	var usc: int = u.score
	u._step(1.0 / 60.0)
	_eq([u.state, u.coins_caught, u.coins.size(), u.items.size(), u.effects.ball_tier, u.score - usc],
		[MainScript.State.CLEARING, 100, 0, 0, 0, u.cfg.score_per_layer + u.cfg.score_boss_kill],
		"bullet kill: coin counted once, item removed without effect/score")
	u.free()

	# 5) 清場時剩下的金幣磚 / 寶箱、待執行的爆炸:清場灰塵與延遲效果都不再產生金幣或道具
	var k := _mk()
	var kb = _boss(k, [Vector2i(0, 9)], 1)
	_special(k, Vector2i(3, 3), "coin")
	_special(k, Vector2i(5, 3), "chest")
	_fn(k, Vector2i(4, 5), "explosion")
	_special(k, Vector2i(4, 4), "coin")   # 爆炸 3×3 範圍內
	k._trigger(Vector2i(4, 5))           # 爆炸排入延遲事件
	k._boss_damage(kb, 1)                 # 同一時刻清場
	_run(k, 1.5)
	_eq([k.state, k.coins.size(), k.items.size(), k.coins_caught], [MainScript.State.ENDED, 0, 0, 0],
		"clearing dust / pending explosion: no new coins or items")
	k.free()


# ---------- 規格未定的行為:只記錄 ----------

func _t_observe() -> void:
	# 1) 一隻魔王已死、牠錯開掉落的格還在格子上(最多 300 ms)時被球打到:是否還擲 20% / 5% 掉落
	var drops := 0
	for sd in 400:
		var m := _mk(sd)
		var dead = _boss(m, _shift(SHAPES["S1"], Vector2i(2, 5)), 4)
		_boss(m, [Vector2i(0, 12)], 100, "B2")
		m._boss_damage(dead, 4)   # 歸零:1 格立刻掉,其餘 100/200/300 ms 後
		var left: Array = _shift(SHAPES["S1"], Vector2i(2, 5)).filter(func(c: Vector2i) -> bool: return m.grid[c.y][c.x] != null)
		var b = _ball(m, Vector2(_center(left[0]).x, _pos(left[0]).y + 27), Vector2.UP)
		m._ball_bricks(b, false)
		drops += m.items.size()
		m.free()
	print("INFO dead boss's pending cells (before stagger drop) hit by ball: %d items over 400 hits (%.1f%%); ball bounces off them" % [drops, drops / 4.0])
	# 2) 魔王全滅後(CLEARING)仍在空中的金幣:已修正為清場開始時全數計入(斷言在 clearing_coins_items 區段)
	var c := _mk()
	var bs = _boss(c, [Vector2i(0, 9)], 1)
	c.coins = [{"value": 100, "pos": Vector2(c.paddle_x, c._paddle_y() - 30)}]
	c._boss_damage(bs, 1)
	_run(c, 1.0)   # CLEARING 時 _process 只推進動畫與事件,不呼叫 _update_coins
	print("INFO coin falling at victory: state=%d coins_left=%d coins_caught=%d (airborne coins counted when clearing starts)" % [c.state, c.coins.size(), c.coins_caught])
	c.free()


# ---------- BOSS 警告(場景樹內) ----------

func _t_warning() -> void:
	var shared := load(CONFIG) as GameConfig
	var orig := shared.level_path
	shared.level_path = LEVEL_TEST
	var m: Node2D = MainScene.instantiate()
	root.add_child(m)
	m.set_process(false)   # 手動推進
	_eq(snappedf(m.warn_left, 0.001), 1.6, "boss level: warning 1.6 s on load")
	var t0: float = m.time_left
	var ball_pos: Vector2 = m.balls[0].pos
	var px: float = m.paddle_x
	# 警告中:放開手指(發射)、拖曳都忽略;時間、球、擋板不動
	var rel := InputEventScreenTouch.new()
	rel.index = 0
	rel.pressed = false
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.relative = Vector2(80, 0)
	for i in 95:
		m._unhandled_input(drag)
		m._unhandled_input(rel)
		m._process(1.0 / 60.0)
	_ok(m.warn_left > 0.0, "still warning at 95 frames (%.3f left)" % m.warn_left)
	_eq([m.time_left, m.balls[0].stuck, m.balls[0].pos, m.paddle_x, m.target_x == px], [t0, true, ball_pos, px, true],
		"during warning: time / ball / paddle frozen, input ignored")
	_eq(m.bar_t, 0.0, "bars not started during warning")
	for i in 2:
		m._process(1.0 / 60.0)
	_eq(m.warn_left, 0.0, "warning over after 1.6 s")
	m._unhandled_input(rel)
	_eq(m.balls[0].stuck, false, "input accepted after warning")
	for i in 30:
		m._process(1.0 / 60.0)
	_ok(m.time_left < t0, "game runs after warning")
	_ok(m.bar_t >= 0.3, "bar slide-in timer runs after warning (%.2f)" % m.bar_t)
	m.queue_free()
	await process_frame
	# 沒有魔王的關卡:不警告
	shared.level_path = "res://data/levels/level_func_test.json"
	var n: Node2D = MainScene.instantiate()
	root.add_child(n)
	n.set_process(false)
	_eq(n.warn_left, 0.0, "no boss: no warning")
	n.queue_free()
	await process_frame
	shared.level_path = orig
