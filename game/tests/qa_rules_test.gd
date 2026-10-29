## QA 獨立驗證(headless,不需額外框架)。直接建立主場景,操作格子與道具,檢查規則結果。
## 執行:Godot --headless --path game --script res://tests/qa_rules_test.gd
## 全部通過時結束碼 0,有失敗時結束碼 1。
extends SceneTree

const MainScene := preload("res://scenes/main.tscn")
const MainScript := preload("res://scripts/main.gd")
## 固定測試關卡(無魔王):不依賴 game_config.tres 目前的 level_path(魔王關進場有 1.6 秒 BOSS 警告)
const LEVEL := "res://data/levels/level_func_test.json"

var cfg: GameConfig
var _passed := 0
var _failed := 0
var _section := ""


var _started := false


## 主場景的 _ready 要等場景樹開始跑才會呼叫,所以測試在第一個 process 幀執行。
## 判讀:除了結束碼,輸出也不應出現 SCRIPT ERROR(GDScript 執行錯誤不會讓測試自動失敗)。
func _process(_delta: float) -> bool:
	if _started:
		return false
	_started = true
	cfg = load("res://data/game_config.tres") as GameConfig
	cfg.level_path = LEVEL
	_run_all()
	return false


func _run_all() -> void:
	_run("layers_table", _t_layers_table)
	_run("damage_main", _t_damage_main)
	_run("reinforce_cap", _t_reinforce_cap)
	_run("flame", _t_flame)
	_run("bomb", _t_bomb)
	_run("bomb_invincible", _t_bomb_invincible)
	_run("pierce", _t_pierce)
	_run("heal", _t_heal)
	_run("invincible", _t_invincible)
	_run("ball_count", _t_ball_count)
	_run("blackhole", _t_blackhole)
	_run("sticky", _t_sticky)
	_run("gun", _t_gun)
	_run("drops", _t_drops)
	_run("debug", _t_debug)
	_run("score", _t_score)
	_run("win_lose", _t_win_lose)
	_run("end_after_win_pickup", _t_end_after_win_pickup)
	_run("timed_accumulate", _t_timed_accumulate)
	_run("speed", _t_speed)
	_run("paddle_len_main", _t_paddle_len_main)
	_run("layout", _t_layout)
	_run("time_blink_scan", _t_time_blink_scan)
	_run("menu_flow", _t_menu_flow)
	_run("menu_queue", _t_menu_queue)
	_run("menu_pools", _t_menu_pools)
	_run("menu_input", _t_menu_input)
	_run("level_parse", _t_level_parse)
	print("QA RESULT: %d passed, %d failed" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


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


# ---------- 輔助 ----------

## 建立乾淨的主場景:清空格子,只留一塊遠處的哨兵磚避免意外過關;一顆停在空中的球。
func _fresh(sentinel := true):
	var m = MainScene.instantiate()
	root.add_child(m)
	m.rng.seed = 12345
	# 40×20 規格:格子 8 欄 × 17 排
	for r in MainScript.MAX_ROWS:
		for c in MainScript.COLS:
			m.grid[r][c] = null
	m.breakable_left = 0
	m.items.clear()
	m.score = 0
	if sentinel:
		_brick(m, 7, 0, 69)   # 哨兵磚放最右欄(8 欄格子的第 7 欄)
	m.balls.clear()
	var b = MainScript.Ball.new()
	b.pos = Vector2(180, 600)
	b.dir = Vector2.UP
	m.balls.append(b)
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


func _expire_all(m) -> void:
	for id in m.effects.tick(9999.0):
		m._on_expired(id)


func _kill(m) -> void:
	m.free()


# ---------- 規則 ----------

func _t_layers_table() -> void:
	var names := ["紅", "橙", "黃", "綠", "藍", "靛", "紫"]
	for n in range(1, 70):
		_eq(Rules.layer_color(n), (n - 1) % 7, "color %d" % n)
		_eq(Rules.layer_round(n), int((n - 1) / 7), "round %d" % n)
		_eq(Rules.sheet_row(n, false), n - 1, "sheet row %d" % n)
	# README 例:8 層 = 紅 1;20 層 = 靛 2
	_eq([names[Rules.layer_color(8)], Rules.layer_round(8)], ["紅", 1], "README 8")
	_eq([names[Rules.layer_color(20)], Rules.layer_round(20)], ["靛", 2], "README 20")
	# 扣層換色順序:每扣一層顏色往前一色,跨輪時紅 → 紫
	for n in range(2, 70):
		var c0 := Rules.layer_color(n)
		var c1 := Rules.layer_color(n - 1)
		_eq(c1, (c0 + 6) % 7, "step color %d->%d" % [n, n - 1])
	# 40×20 規格(D31):不再用 bricks_multi 精靈圖;層數 → art/bricks40 的底圖(顏色)+ 數字疊加層(輪數,0 不顯示)
	var color_names := ["red", "orange", "yellow", "green", "blue", "indigo", "purple"]
	for n in range(1, 70):
		var want_digit := "" if (n - 1) / 7 == 0 else "d31_digit_%d" % ((n - 1) / 7)
		_eq(Rules.brick_art(Rules.sheet_row(n, false)), ["d31_brick_" + color_names[(n - 1) % 7], want_digit], "art layer %d" % n)
		# 炸彈標記:同色第 0 輪底圖、不顯示數字
		_eq(Rules.brick_art(Rules.sheet_row(n, true)), ["d31_brick_" + color_names[(n - 1) % 7], ""], "marked art layer %d" % n)
		for name in Rules.brick_art(Rules.sheet_row(n, false)):
			if name != "":
				var t: Texture2D = load("res://art/bricks40/%s.png" % name)
				if t == null or t.get_size() != Vector2(40, 20):
					_ok(false, "art file %s missing or not 40x20" % name)
	_eq(Rules.brick_art(Rules.sheet_row(69, false)), ["d31_brick_indigo", "d31_digit_9"], "69 = indigo 9 (max digit 9)")


func _t_damage_main() -> void:
	var m = _fresh()
	_brick(m, 3, 5, 20)
	m.effects.reinforce = 7
	m._ball_hit_brick(Vector2i(3, 5))
	_eq(_layers(m, 3, 5), 12, "20 - 8 = 12 (one hit, final layer directly)")
	_eq(m.grid[5][3].hit_row, 19, "hit frame uses pre-damage row (20 layers)")
	# 40×20 規格(D31):被擊中幀 = 閃白底圖 + 扣層前的數字(20 層 = 數字 2)
	_eq(Rules.brick_art(m.grid[5][3].hit_row)[1], "d31_digit_2", "hit frame digit = pre-damage digit 2")
	_ok(m.grid[5][3].hit_t > 0.0, "hit frame active after damage")
	_eq(m.score, 800, "8 layers x 100")
	m._ball_hit_brick(Vector2i(3, 5))
	_eq(_layers(m, 3, 5), 4, "12 - 8 = 4")
	m._ball_hit_brick(Vector2i(3, 5))
	_eq(_layers(m, 3, 5), -999, "4 - 8 -> destroyed")
	_eq(m.score, 800 + 800 + 400 + 200, "overkill only scores remaining layers + break")
	_kill(m)


func _t_reinforce_cap() -> void:
	var m = _fresh()
	for i in 12:
		m._apply_item("reinforce")
	_eq(m.effects.reinforce, 7, "reinforce capped at +7")
	_brick(m, 0, 0, 30)
	m._ball_hit_brick(Vector2i(0, 0))
	_eq(_layers(m, 0, 0), 22, "max 8 per hit")
	_kill(m)


## 2 倍規格:3×3 中心由 (4, 10) 改到 (2, 5)(原中心右邊與下面的欄、排已不存在),相對位置不變。
func _t_flame() -> void:
	var m = _fresh()
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			_brick(m, 2 + dx, 5 + dy, 5 if (dx == 0 and dy == 0) else 3)
	m.grid[4][1] = null
	m.breakable_left -= 1
	_brick(m, 1, 4, 1, true)
	_brick(m, 4, 5, 3)   # 3×3 之外,不受影響
	m._apply_item("flame")
	m._ball_hit_brick(Vector2i(2, 5))
	_eq(_layers(m, 2, 5), 3, "flame center -2")
	for n in [Vector2i(3, 4), Vector2i(2, 4), Vector2i(1, 5), Vector2i(3, 5), Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6)]:
		_eq(_layers(m, n.x, n.y), 2, "flame neighbor -1 at %s" % n)
	_eq(_layers(m, 1, 4), 1, "unbreakable neighbor untouched")
	_ok(m.grid[4][1].unbreakable, "still unbreakable")
	_eq(_layers(m, 4, 5), 3, "outside 3x3 untouched")
	# 強化對中心有效、對周圍無效
	m.effects.reinforce = 3
	m._ball_hit_brick(Vector2i(2, 5))
	_eq(_layers(m, 2, 5), -999, "flame 2 + reinforce 3 destroys 3-layer center")
	_eq(_layers(m, 2, 4), 1, "neighbor still -1 only")
	# 角落不越界(40×20 規格:最後一排為第 16 排)
	_brick(m, 0, 16, 5)
	m._ball_hit_brick(Vector2i(0, 16))
	_eq(_layers(m, 0, 16), -999, "corner brick destroyed (5 - 5), no out-of-range crash")
	_kill(m)


## 2 倍規格:中心由 (4, 10) 改到 (2, 5),各磚相對位置不變(欄 −2、排 −5)。
func _t_bomb() -> void:
	var m = _fresh()
	_brick(m, 2, 5, 5)
	for n in [Vector2i(1, 4), Vector2i(3, 6), Vector2i(2, 6)]:
		_brick(m, n.x, n.y, 3)
	_brick(m, 3, 4, 1, true)
	_brick(m, 4, 5, 3)
	m._apply_item("bomb")
	m.effects.reinforce = 7
	m._ball_hit_brick(Vector2i(2, 5))
	_eq(_layers(m, 2, 5), 5, "bomb: hit brick not damaged")
	_ok(m.grid[5][2].marked, "bomb: hit brick marked")
	_eq(Rules.sheet_row(5, true), 4, "marked uses round-0 row")
	m._ball_hit_brick(Vector2i(3, 4))
	_ok(not m.grid[4][3].marked, "bomb: unbreakable not marked")
	var before: int = m.score
	_expire_all(m)
	_eq(_layers(m, 2, 5), -999, "marked brick destroyed on expiry")
	_eq(_layers(m, 1, 4), 1, "3x3 -2 (3->1)")
	_eq(_layers(m, 2, 6), 1, "3x3 -2 (3->1) below")
	_ok(m.grid[4][3] != null and m.grid[4][3].unbreakable, "unbreakable survives")
	_eq(_layers(m, 4, 5), 3, "outside 3x3 untouched")
	_eq(m.score - before, 5 * 100 + 200 + 3 * 2 * 100, "bomb score")
	_kill(m)


## 規格未寫:炸彈結束時無敵仍生效,記錄實際行為(標記清除、不爆炸)。
func _t_bomb_invincible() -> void:
	var m = _fresh()
	_brick(m, 7, 16, 5)
	m._apply_item("bomb")
	m._ball_hit_brick(Vector2i(7, 16))
	m.effects.add_timed("invincible", 100.0)
	for id in m.effects.tick(6.0):
		m._on_expired(id)
	print("INFO bomb expires during invincible: layers=%d marked=%s" % [_layers(m, 7, 16), m.grid[16][7].marked])
	_kill(m)


func _t_pierce() -> void:
	var m = _fresh()
	_brick(m, 7, 16, 10)
	var b = m.balls[0]
	var rect: Rect2 = m._cell_rect(Vector2i(7, 16))
	b.pos = rect.get_center()
	b.dir = Vector2(0.3, -1).normalized()
	m._apply_item("pierce")
	m._ball_bricks(b, m._pierce_on())
	_eq(_layers(m, 7, 16), 9, "pierce entry -1")
	_eq(b.dir, Vector2(0.3, -1).normalized(), "pierce: no bounce on breakable")
	m._ball_bricks(b, m._pierce_on())
	_eq(_layers(m, 7, 16), 9, "pierce: staying inside does not deduct again")
	_expire_all(m)
	_eq(_layers(m, 7, 16), -999, "pierce end: brick under ball destroyed directly")
	# 不可破壞磚仍反彈
	var m2 = _fresh()
	_brick(m2, 7, 16, 1, true)
	m2._apply_item("pierce")
	var b2 = m2.balls[0]
	var r2: Rect2 = m2._cell_rect(Vector2i(7, 16))
	b2.pos = Vector2(r2.get_center().x, r2.end.y + 2.0)
	b2.dir = Vector2.UP
	m2._ball_bricks(b2, true)
	_ok(b2.dir.y > 0.0, "pierce: unbreakable still bounces")
	# 球不在磚上時,結束不破壞任何磚
	_brick(m2, 0, 0, 3)
	b2.pos = Vector2(180, 600)
	_expire_all(m2)
	_eq(_layers(m2, 0, 0), 3, "pierce end: no brick under ball -> nothing destroyed")
	_kill(m)
	_kill(m2)


func _t_heal() -> void:
	var m = _fresh()
	_brick(m, 7, 16, 68)
	m._apply_item("heal")
	m._ball_hit_brick(Vector2i(7, 16))
	_eq(_layers(m, 7, 16), 69, "heal +1")
	m._ball_hit_brick(Vector2i(7, 16))
	_eq(_layers(m, 7, 16), 69, "heal capped at 69")
	_expire_all(m)
	_brick(m, 2, 2, 5)
	_brick(m, 1, 1, 69)
	_brick(m, 3, 3, 4)
	_brick(m, 2, 1, 1, true)
	_brick(m, 4, 4, 4)
	m._apply_item("heal_area")
	m._ball_hit_brick(Vector2i(2, 2))
	_eq(_layers(m, 2, 2), 7, "heal_area +2")
	_eq(_layers(m, 1, 1), 69, "heal_area splash capped 69")
	_eq(_layers(m, 3, 3), 5, "heal_area splash +1")
	_eq(_layers(m, 4, 4), 4, "outside 3x3 untouched")
	_ok(m.grid[1][2].unbreakable and m.grid[1][2].layers == 1, "unbreakable untouched")
	_eq(m.score, 0, "heal gives no score")
	_kill(m)


func _t_invincible() -> void:
	var m = _fresh()
	_brick(m, 7, 16, 5)
	m._apply_item("invincible")
	m._apply_item("flame")
	m.effects.reinforce = 7
	m._ball_hit_brick(Vector2i(7, 16))
	_eq(_layers(m, 7, 16), 5, "invincible: no damage")
	m._apply_item("pierce")
	var b = m.balls[0]
	var r: Rect2 = m._cell_rect(Vector2i(7, 16))
	b.pos = Vector2(r.get_center().x, r.end.y + 2.0)
	b.dir = Vector2.UP
	m._ball_bricks(b, m._pierce_on())
	_ok(b.dir.y > 0.0, "invincible: pierce disabled, ball bounces")
	_eq(_layers(m, 7, 16), 5, "still 5")
	m._damage(Vector2i(7, 16), 1)
	_eq(_layers(m, 7, 16), 5, "bullet-type damage blocked")
	_kill(m)


func _t_ball_count() -> void:
	var m = _fresh()
	for i in 2:
		var b = MainScript.Ball.new()
		b.pos = Vector2(100 + i * 20, 600)
		b.dir = Vector2.UP
		m.balls.append(b)
	_eq(m.balls.size(), 3, "setup 3")
	m._apply_item("split")
	_eq(m.balls.size(), 6, "split x2")
	m._apply_item("merge")
	_eq(m.balls.size(), 3, "merge 6 -> 3")
	m._apply_item("merge")
	_eq(m.balls.size(), 2, "merge 3 -> 2 (ceil)")
	m._apply_item("merge")
	_eq(m.balls.size(), 1, "merge 2 -> 1")
	m._apply_item("merge")
	_eq(m.balls.size(), 1, "merge 1 stays 1")
	for i in 3:
		m._apply_item("split")
	_eq(m.balls.size(), 8, "split x3 -> 8")
	m._apply_item("blackhole_big")
	_eq(m.balls.size(), 1, "big blackhole -> 1")
	var old: int = cfg.max_balls
	cfg.max_balls = 5
	for i in 4:
		m._apply_item("split")
	_eq(m.balls.size(), 5, "split capped by max_balls")
	cfg.max_balls = old
	_kill(m)


func _t_blackhole() -> void:
	var m = _fresh()
	m._apply_item("blackhole")
	var b = m.balls[0]
	m.paddle_x = 180.0
	b.pos = Vector2(180, m._paddle_y() - 3)
	b.dir = Vector2.DOWN
	var len: int = m._paddle_len()
	var stopped: bool = m._ball_paddle(b, m._paddle_left(len), len, m._paddle_y())
	_ok(stopped and m.balls.is_empty(), "blackhole: ball touching paddle vanishes")
	_kill(m)


func _t_sticky() -> void:
	var m = _fresh()
	m._apply_item("sticky")
	var b = m.balls[0]
	m.paddle_x = 180.0
	b.pos = Vector2(190, m._paddle_y() - 3)
	b.dir = Vector2.DOWN
	var len: int = m._paddle_len()
	m._ball_paddle(b, m._paddle_left(len), len, m._paddle_y())
	_ok(b.stuck, "sticky: ball sticks")
	m._update_balls(0.1)
	# 2 倍規格:球半徑 8(原 4)
	_ok(b.stuck and is_equal_approx(b.pos.y, m._paddle_y() - 8.0), "sticky: ball stays on paddle")
	m._launch_stuck()
	_ok(not b.stuck and b.dir.y < 0.0, "launch after release")
	_kill(m)


func _t_gun() -> void:
	var m = _fresh()
	m._fire_gun()
	_eq(m.bullets.size(), 0, "no gun -> no bullets")
	m._apply_item("gun")
	m.effects.reinforce = 7
	m._apply_item("flame")
	m.paddle_x = 180.0
	var len: int = m._paddle_len()
	var left: int = m._paddle_left(len)
	# 槍端 16 寬、子彈在槍端 +6(判定點 +7/+8);40×20 規格:磚寬 40,打最後一排第 16 排
	var c_left := int((left + 7 - 20) / 40)
	var c_right := int((left + len - 16 + 7 - 20) / 40)
	_brick(m, c_left, 16, 5)
	_brick(m, c_right, 16, 5, c_left == c_right)
	m._fire_gun()
	_eq(m.bullets.size(), 2, "one tap -> 2 bullets (left & right)")
	m._fire_gun()
	_eq(m.bullets.size(), 2, "cooldown blocks immediate refire")
	for i in 120:
		m._update_bullets(1.0 / 60.0)
	_eq(m.bullets.size(), 0, "bullets consumed")
	if c_left != c_right:
		_eq(_layers(m, c_left, 16), 4, "bullet -1 (no reinforce/flame bonus) left")
		_eq(_layers(m, c_right, 16), 4, "bullet -1 right")
	else:
		print("INFO gun: both muzzles in same column %d" % c_left)
	_kill(m)


func _t_drops() -> void:
	var m = _fresh()
	var n := 20000
	var buff := 0
	var seen := {}
	for i in n:
		m._roll_drop(Vector2(20, 68))
	for it in m.items:
		seen[it["id"]] = true
		if ItemDefs.is_buff(it["id"]):
			buff += 1
	var rate := float(m.items.size()) / n
	_ok(absf(rate - 0.3) < 0.015, "drop rate ~30%% (got %.3f)" % rate)
	var br := float(buff) / maxi(1, m.items.size())
	_ok(absf(br - 0.5) < 0.025, "buff ratio ~50%% (got %.3f)" % br)
	_ok(not seen.has("thief"), "no thief when replay_level = false")
	_ok(seen.has("golden_ball") and seen.has("black_ball"), "ball items can drop")
	# 2026-10-28:「擋板最大化」移出掉落池,非小偷道具 25 種
	_eq(seen.size(), 25, "all 25 non-thief items appear")
	_ok(not seen.has("paddle_len_max"), "paddle_len_max never drops")
	cfg.replay_level = true
	m.items.clear()
	for i in 20000:
		m._roll_drop(Vector2(20, 68))
	var thief: int = m.items.filter(func(it) -> bool: return it["id"] == "thief").size()
	_ok(thief > 0, "thief drops when replay_level = true (%d)" % thief)
	cfg.replay_level = false
	# 道具從被破壞磚的位置往下掉。新規格(使用者確認):16×16 圖示中心 = 磚中心(40×20 → +20, +10)
	m.items.clear()
	cfg.debug_force_item = "flame"
	m._roll_drop(Vector2(60, 88))   # 格子 (1, 1) 的左上角
	_eq(m.items[0]["pos"] + Vector2(8, 8), Vector2(60 + 20, 88 + 10), "drop icon center = brick center")
	cfg.debug_force_item = ""
	_kill(m)


func _t_debug() -> void:
	cfg.debug_force_item = "gun"
	var m = _fresh()
	for i in 50:
		m._roll_drop(Vector2(20, 68))
	_eq(m.items.size(), 50, "debug_force_item: 100% drop")
	_ok(m.items.all(func(it) -> bool: return it["id"] == "gun"), "debug_force_item: always that item")
	_kill(m)
	cfg.debug_force_item = ""
	cfg.debug_start_balls = 7
	var m2 = MainScene.instantiate()
	root.add_child(m2)
	_eq(m2.balls.size(), 7, "debug_start_balls = 7")
	_ok(m2.balls.all(func(b) -> bool: return b.stuck), "start balls are stuck on paddle")
	_kill(m2)
	cfg.debug_start_balls = 5000
	var m3 = MainScene.instantiate()
	root.add_child(m3)
	_eq(m3.balls.size(), cfg.max_balls, "debug_start_balls clamped to max_balls")
	_kill(m3)
	cfg.debug_start_balls = 1


func _t_score() -> void:
	var m = _fresh()
	m._pickup("slow", Vector2(100, 600))
	_eq(m.score, 200, "buff pickup +200")
	m._pickup("fast", Vector2(100, 600))
	_eq(m.score, 250, "debuff pickup +50")
	_brick(m, 0, 0, 1)
	m._ball_hit_brick(Vector2i(0, 0))
	_eq(m.score, 250 + 300, "1-layer brick: 100 + 200")
	m.score = 300
	m._apply_item("thief")
	_eq(m.score, 0, "thief floors at 0")
	m.score = 10000
	m._apply_item("thief")
	_ok(m.score >= 5000 and m.score <= 9500, "thief steals 500~5000 (%d)" % m.score)
	_kill(m)


func _t_win_lose() -> void:
	var m = _fresh(false)
	_brick(m, 2, 2, 1)
	m.time_left = 100.5
	m._ball_hit_brick(Vector2i(2, 2))
	_eq(m.state, 1, "win when last breakable destroyed")
	_eq(m.score, 300 + 200, "win: +2 per remaining full second")
	_kill(m)
	# 不可破壞磚不影響勝利
	var m2 = _fresh(false)
	_brick(m2, 0, 0, 1, true)
	_brick(m2, 2, 2, 1)
	m2._ball_hit_brick(Vector2i(2, 2))
	_eq(m2.state, 1, "unbreakable bricks don't block win")
	_kill(m2)
	var m3 = _fresh()
	m3.balls.clear()
	m3._step(0.016)
	_eq(m3.state, 1, "lose when no balls")
	_kill(m3)
	var m4 = _fresh()
	m4.time_left = 0.01
	m4._step(0.02)
	_eq([m4.state, m4.time_left, m4.score], [1, 0.0, 0], "lose on time up, no time bonus")
	_kill(m4)
	var m5 = MainScene.instantiate()
	root.add_child(m5)
	_eq(m5.time_left, 300.0, "game time 5 minutes")
	_kill(m5)


## 過關的那一幀之後,同一幀內仍會撿道具並加分(結束畫面已顯示舊分數)。
func _t_end_after_win_pickup() -> void:
	var old_drop: float = cfg.drop_chance
	cfg.drop_chance = 0.0
	var m = _fresh(false)
	_brick(m, 4, 0, 1)
	var b = m.balls[0]
	var r: Rect2 = m._cell_rect(Vector2i(4, 0))
	# 2 倍規格:球半徑 8,離磚下緣 8.5 = 開始時沒碰到、這一幀內碰到(原半徑 4 時是 4.5)
	b.pos = Vector2(r.get_center().x, r.end.y + 8.5)
	b.dir = Vector2.UP
	m.paddle_x = 180.0
	m.target_x = 180.0
	m.items.append({"id": "slow", "pos": Vector2(172, m._paddle_y() - 16.5)})
	m._step(0.016)
	_eq(m.state, 1, "won this frame")
	_eq(m.items.size(), 0, "item consumed")
	var shown := ""
	for ui in m.get_children():
		if ui is Control and not ui is ChoiceMenu:
			for ch in ui.get_children():
				if ch is Label:
					shown = ch.text.replace("\n", " / ")
	print("INFO after win in same frame: score var=%d, end screen text='%s'" % [m.score, shown])
	_eq(m.score, 300 + Rules.time_bonus(m.time_left, 2), "no score change after game ended")
	_kill(m)
	cfg.drop_chance = old_drop


func _t_timed_accumulate() -> void:
	var m = _fresh()
	# 2026-10-28:穿透 20 秒;相同效果再撿到剩餘時間累積(18 + 20 = 38)
	m._apply_item("pierce")
	m.effects.tick(2.0)
	m._apply_item("pierce")
	_ok(is_equal_approx(m.effects.remaining("pierce"), 38.0), "pierce 18 + 20 = 38 (got %.3f)" % m.effects.remaining("pierce"))
	m._apply_item("flame")
	m._apply_item("paddle_len_1")
	m._apply_item("invisible")
	_ok(m.effects.is_active("pierce") and m.effects.is_active("flame") and m.effects.is_active(Effects.PADDLE_LEN) and m.effects.is_active("invisible"), "different effects coexist")
	# 吸附、槍改為限時(30、10 秒),不再整局有效
	m._apply_item("sticky")
	m._apply_item("gun")
	_ok(m.effects.is_active("sticky") and m.effects.is_active("gun"), "sticky / gun active after pickup")
	m.effects.tick(1000.0)
	_ok(not m.effects.is_active("sticky") and not m.effects.is_active("gun"), "sticky / gun expire (no longer whole game)")
	_kill(m)


func _t_speed() -> void:
	var m = _fresh()
	var b = m.balls[0]
	b.pos = Vector2(180, 600)
	b.dir = Vector2.UP
	m._update_balls(0.01)
	_ok(absf((600 - b.pos.y) - 2.4) < 0.01, "base 240 px/s (moved %.3f)" % (600 - b.pos.y))
	for i in 10:
		m._apply_item("fast")
	_eq(m.effects.ball_tier, 4, "fast capped +4")
	b.pos = Vector2(180, 600)
	m._update_balls(0.01)
	_ok(absf((600 - b.pos.y) - 3.84) < 0.01, "+4 = 384 px/s (moved %.3f)" % (600 - b.pos.y))
	for i in 20:
		m._apply_item("slow")
	_eq(m.effects.ball_tier, -3, "slow capped -3")
	b.pos = Vector2(180, 600)
	m._update_balls(0.01)
	_ok(absf((600 - b.pos.y) - 1.32) < 0.01, "-3 = 132 px/s (moved %.3f)" % (600 - b.pos.y))
	# 擋板速度
	m.paddle_x = 180.0
	m.target_x = 330.0
	m._update_paddle(0.1)
	# 擋板速度 600 → 450:0.1 s 走 45 px(180 → 225)
	_ok(is_equal_approx(m.paddle_x, 225.0), "paddle 450 px/s (x=%.2f)" % m.paddle_x)
	m._apply_item("paddle_speed")
	m.paddle_x = 180.0
	m._update_paddle(0.1)
	# +1 階 = 450 × 1.15 = 517.5 px/s:0.1 s 走 51.75 px(180 → 231.75)
	_ok(is_equal_approx(m.paddle_x, 231.75), "paddle +1 tier 517.5 px/s (x=%.2f)" % m.paddle_x)
	_kill(m)


func _t_paddle_len_main() -> void:
	var m = _fresh()
	# 2026-10-28:「擋板最大化」已移除;長度上限 320 改由多次增加道具相乘達到
	# (1.6^4 × 85 = 557 → 夾到 320);最短化倍率 = 32/85
	_eq(m._paddle_len(), 85, "base 85")
	for i in 4:
		m._apply_item("paddle_len_2")
	_eq(m._paddle_len(), 320, "max 320 (clamped)")
	m.paddle_x = 20.0
	m.target_x = 0.0
	m._update_paddle(0.1)
	_eq(m._paddle_left(320), 20, "full-width paddle starts at field left")
	_kill(m)
	_ok(not ItemDefs.exists("paddle_len_max"), "paddle_len_max is no longer an item id")
	# README 長度道具換算(基準 85):小增 102、大增 136、小減 68、大減 34、最短 32
	var table := {
		"paddle_len_1": 102, "paddle_len_2": 136, "paddle_len_down_1": 68,
		"paddle_len_down_2": 34, "paddle_len_min": 32,
	}
	for id in table:
		var m2 = _fresh()
		m2._apply_item(id)
		_eq(m2._paddle_len(), table[id], "README length %s" % id)
		_kill(m2)
	# 疊加(基準 85):163.2→163、217.6→218(同一種撿 2 次再乘)、12.8→32、27.2→32(夾到下限)、54.4→54、81.6→82
	for combo in [[["paddle_len_1", "paddle_len_2"], 163], [["paddle_len_2", "paddle_len_2"], 218],
			[["paddle_len_down_2", "paddle_len_min"], 32], [["paddle_len_down_1", "paddle_len_down_2"], 32],
			[["paddle_len_2", "paddle_len_down_2"], 54], [["paddle_len_1", "paddle_len_down_1"], 82]]:
		var m3 = _fresh()
		for id in combo[0]:
			m3._apply_item(id)
		_eq(m3._paddle_len(), combo[1], "stack %s" % [combo[0]])
		_kill(m3)
	_eq([cfg.paddle_base_length, cfg.paddle_min_length, cfg.paddle_max_length], [85.0, 32, 320], "base 85 / min 32 / max 320")


func _t_layout() -> void:
	_eq([MainScript.FIELD_LEFT, MainScript.FIELD_RIGHT, MainScript.FIELD_TOP], [20, 340, 52], "field 20..339, top 52")
	_eq(MainScript.BRICK_TOP, 68, "brick top 68")
	# 40×20 規格:8 欄 × 17 排、磚 40×20,最後一格 (7, 16) 在 x 300~339、y 388~407;球、擋板維持 2 倍;擋板 y 755~770
	_eq([MainScript.COLS, MainScript.MAX_ROWS], [8, 17], "8 cols x 17 rows")
	_eq([MainScript.BRICK_W, MainScript.BRICK_H, MainScript.BALL_R, MainScript.PADDLE_H], [40, 20, 8.0, 16], "brick 40x20, ball r 8, paddle h 16")
	var m = _fresh()
	m.view_h = 800
	var last: Rect2 = m._cell_rect(Vector2i(7, 16))
	_eq([last.position, last.end], [Vector2(300, 388), Vector2(340, 408)], "last brick cell ends at x 339, y 407")
	_eq(m._paddle_y(), 755, "paddle top 755 at H=800")
	_eq(m._paddle_y() + MainScript.PADDLE_H - 1, 770, "paddle last row 770 at H=800")
	m.view_h = 640
	_eq(m._paddle_y(), 595, "paddle top 595 at H=640")
	m.view_h = 800
	_ok(last.end.y <= MainScript.HUD_Y, "bricks end above HUD row 1")
	_eq([MainScript.HUD_X, MainScript.HUD_Y, MainScript.HUD_STEP], [24, 424, 52], "HUD x 24, y 424, step 52")
	_eq(cfg.hud_alpha, 0.5, "HUD 50%")
	_kill(m)
	# D29 面板位置公式
	for h in [800, 707, 640]:
		var menu := ChoiceMenu.new()
		menu.setup(true, ["slow", "split", "gun"], h, false)
		root.add_child(menu)
		menu._apply_entry(1.0)
		var py := 52 + floori((h - 484) / 2.0)
		_eq(menu._panel.position, Vector2(28, py), "panel pos H=%d" % h)
		for k in 3:
			var g: Rect2 = menu._options[k].get_global_rect()
			_eq(g, Rect2(40, py + 68 + 120 * k, 280, 112), "option %d rect H=%d" % [k, h])
		menu.free()


func _t_time_blink_scan() -> void:
	var t := 40.0
	var bad := []
	while t > 0.0:
		var s := Rules.remaining_seconds(t)
		var red := Rules.time_is_red(t)
		var expect := false
		if s <= 30 and s >= 11:
			expect = s % 2 == 0 and t > s - 0.5
		elif s <= 10 and s >= 1:
			expect = t > s - 0.5
		if red != expect:
			bad.append(snappedf(t, 0.01))
		t -= 0.01
	_eq(bad.size(), 0, "blink pattern 30~11 every 2s, 10~1 every 1s (bad at %s)" % [bad.slice(0, 5)])


# ---------- D29 ----------

func _t_menu_flow() -> void:
	_menu_flow(false)
	_menu_flow(true)


func _menu_flow(reduced: bool) -> void:
	var close_t := 0.24 if reduced else 0.42
	var m = _fresh()
	print("INFO environment reduce_animation=%s; testing reduced=%s" % [m.reduced_motion, reduced])
	m.reduced_motion = reduced
	m._pickup("golden_ball", Vector2(100, 600))
	_eq(m.score, 200, "golden ball pickup scores +200 (engineer assumption)")
	m.time_left = 100.0
	m._step(0.016)
	_ok(m.menu != null, "menu opens")
	var menu: ChoiceMenu = m.menu
	_eq(menu.ids.size(), 3, "3 options")
	var tl: float = m.time_left
	m.items.append({"id": "slow", "pos": Vector2(20, 100)})
	m._apply_item("pierce")
	var rem: float = m.effects.remaining("pierce")
	for i in 10:
		m._process(0.05)
	_eq([m.time_left, m.items[0]["pos"], m.effects.remaining("pierce")], [tl, Vector2(20, 100), rem], "paused while menu open")
	# 入場鎖定 500 ms
	menu._process(0.1)
	menu._process(0.1)
	menu._process(0.1)
	menu._process(0.1)
	menu._process(0.09)
	_ok(menu._options.all(func(o) -> bool: return o.disabled), "locked at 0.49 s")
	menu._process(0.02)
	_ok(menu._options.all(func(o) -> bool: return not o.disabled), "unlocked at 0.51 s")
	_eq(menu._options[0].action_mode, BaseButton.ACTION_MODE_BUTTON_RELEASE, "select on release")
	var picked_id: String = menu.ids[1]
	var s0: int = m.score
	menu._on_pressed(1)
	_eq(m.score - s0, 200, "picked buff scores +200 immediately")
	_ok(menu._options.all(func(o) -> bool: return o.disabled), "all disabled after pick")
	menu._on_pressed(2)
	_eq(m.score - s0, 200, "second pick ignored")
	menu._process(close_t - 0.02)
	_ok(m.menu != null, "still open just before %.2f s after pick" % close_t)
	m._process(0.05)
	_eq(m.time_left, tl, "still paused just before close")
	menu._process(0.03)
	_ok(m.menu == null, "closed at %.2f s after pick (picked %s)" % [close_t, picked_id])
	m._process(0.05)
	_ok(m.time_left < tl, "game resumes after close")
	_kill(m)


func _t_menu_queue() -> void:
	var m = _fresh()
	m._apply_item("golden_ball")
	m._apply_item("black_ball")
	m._step(0.016)
	_ok(m.menu != null and m.menu.golden, "first menu golden")
	_eq(m.menu_queue.size(), 1, "second queued")
	var menu: ChoiceMenu = m.menu
	menu._process(0.6)
	menu._on_pressed(0)
	menu._process(0.5)
	_ok(m.menu == null, "first closed")
	m._step(0.016)
	_ok(m.menu != null and not m.menu.golden, "second menu black opens after first")
	_kill(m)


func _t_menu_pools() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for replay in [false, true]:
		for golden in [true, false]:
			var seen := {}
			for i in 3000:
				var ids := ItemDefs.pick_distinct(ItemDefs.choice_pool(golden, replay), 3, rng)
				var u := {}
				for id in ids:
					u[id] = true
					seen[id] = true
				if u.size() != 3:
					_ok(false, "duplicate in menu %s" % [ids])
			_ok(not seen.has("golden_ball") and not seen.has("black_ball"), "no ball items in pool golden=%s replay=%s" % [golden, replay])
			_ok(seen.keys().all(func(id) -> bool: return ItemDefs.is_buff(id) == golden), "pool type matches golden=%s" % golden)
			if not golden:
				_eq(seen.has("thief"), replay, "thief only on replay (replay=%s)" % replay)
			# 2026-10-28:金球池刪「擋板最大化」= 11 種;黑球池 12 種(重複關卡加小偷 13 種)
			var want := 11 if golden else (13 if replay else 12)
			_eq(seen.size(), want, "pool size golden=%s replay=%s" % [golden, replay])
			_ok(not seen.has("paddle_len_max"), "no paddle_len_max in pool golden=%s replay=%s" % [golden, replay])


func _mouse(pos: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = pos
	e.global_position = pos
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	root.push_input(e)


func _motion(pos: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = pos
	e.global_position = pos
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(e)


## 用真實的滑鼠事件(觸控在 Android 會模擬成滑鼠)驗證:鎖定期間、放開才選、滑開取消、間隔無作用。
func _t_menu_input() -> void:
	var m = _fresh()
	m._apply_item("golden_ball")
	m._step(0.016)
	var menu: ChoiceMenu = m.menu
	var picks := []
	menu.picked.connect(func(id: String) -> void: picks.append(id))
	var c0: Vector2 = menu._options[0].get_global_rect().get_center()
	var c1: Vector2 = menu._options[1].get_global_rect().get_center()
	menu._process(0.3)
	_mouse(c0, true)
	_mouse(c0, false)
	_eq(picks.size(), 0, "tap during 500 ms lock ignored")
	_mouse(c0, true)   # 鎖定中按下、解鎖後放開
	menu._process(0.3)
	_mouse(c0, false)
	_eq(picks.size(), 0, "press during lock + release after lock ignored")
	# 間隔(兩個選項之間 8 px)
	var gap := Vector2(c0.x, menu._options[0].get_global_rect().end.y + 4)
	_mouse(gap, true)
	_mouse(gap, false)
	_eq(picks.size(), 0, "gap tap does nothing")
	# 按下後滑到別的選項再放開:不選
	_mouse(c0, true)
	_motion(c1)
	_mouse(c1, false)
	_eq(picks.size(), 0, "press on 1, release on 2 -> no pick")
	# 按下只算放開
	_mouse(c1, true)
	_eq(picks.size(), 0, "press alone does not pick")
	_mouse(c1, false)
	_eq(picks, [menu.ids[1]], "release on same option picks it")
	_mouse(c0, true)
	_mouse(c0, false)
	_eq(picks.size(), 1, "input ignored after pick")
	_kill(m)


func _t_level_parse() -> void:
	# 40×20 規格:8 欄 × 17 排;參數讀 main.gd 常數,與遊戲載入時一致
	var R: int = MainScript.MAX_ROWS
	var C: int = MainScript.COLS
	_eq([R, C], [17, 8], "parse limits 17 rows x 8 cols")
	var p := Rules.parse_level({"rows": ["69 70 0 -1 U . . 1"]}, R, C, 69)
	_eq(p["cells"][0], [69, 0, 0, 0, -1, 0, 0, 1] as Array[int], "69 ok, 70/0/-1 rejected")
	var rows := []
	for i in 25:
		rows.append(". . . . . . . 1")
	var p2 := Rules.parse_level({"rows": rows}, R, C, 69)
	_eq(p2["cells"].size(), 17, "rows beyond 17 ignored")
	_ok(p2["errors"].size() == 1 and "25" in p2["errors"][0] and "17" in p2["errors"][0], "row overflow logged once: %s" % [p2["errors"]])
	# 超過 8 欄:多的格丟掉、記錄錯誤,其餘照常
	var p4 := Rules.parse_level({"rows": ["1 2 3 4 5 6 7 8 9 10", "U . 3 . U . . 1"]}, R, C, 69)
	_eq(str(p4["cells"]), str([[1, 2, 3, 4, 5, 6, 7, 8], [-1, 0, 3, 0, -1, 0, 0, 1]]), "extra columns dropped, other rows intact")
	_eq(p4["errors"].size(), 1, "one error for over-wide row: %s" % [p4["errors"]])
	# 剛好 9 欄(只多 1 欄)也算超欄
	var p7 := Rules.parse_level({"rows": ["1 1 1 1 1 1 1 1 9"]}, R, C, 69)
	_eq(str([p7["cells"][0], p7["errors"].size()]), str([[1, 1, 1, 1, 1, 1, 1, 1], 1]), "9-col row: 9th dropped + error")
	# 少於 8 欄:補空格並記錄
	var p5 := Rules.parse_level({"rows": ["1 2"]}, R, C, 69)
	_eq(str([p5["cells"][0], p5["errors"].size()]), str([[1, 2, 0, 0, 0, 0, 0, 0], 1]), "short row padded with empty + error")
	# 剛好 17 排不記錯;18 排記 1 筆
	var r17 := []
	for i in 17:
		r17.append("1 1 1 1 1 1 1 1")
	_eq(Rules.parse_level({"rows": r17}, R, C, 69)["errors"].size(), 0, "exactly 17 rows: no error")
	r17.append("1 1 1 1 1 1 1 1")
	var p8 := Rules.parse_level({"rows": r17}, R, C, 69)
	_eq([p8["cells"].size(), p8["errors"].size()], [17, 1], "18 rows -> 17 + 1 error")
	# 同時超欄又超排
	var big := []
	for i in 22:
		big.append("1 1 1 1 1 1 1 1 1 1")
	var p6 := Rules.parse_level({"rows": big}, R, C, 69)
	_eq([p6["cells"].size(), p6["cells"][16].size(), p6["errors"].size()], [17, 8, 18], "22x10 level -> 17x8 with 1 row error + 17 col errors")
	# 固定讀 level_test.json(17 排),不檢查設定檔預設指向哪一關
	var test_level = load("res://data/levels/level_test.json").data
	var p3 := Rules.parse_level(test_level, R, C, 69)
	_eq([p3["cells"].size(), p3["errors"].size()], [17, 0], "level_test.json 17 rows, no errors")
	# 遊戲實際載入超規格關卡:不中斷、格子仍是 17 × 8
	var tmp := "user://qa_oversize_level.json"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	f.store_string(JSON.stringify({"rows": big}))
	f.close()
	var old_path: String = cfg.level_path
	cfg.level_path = tmp
	var mm = MainScene.instantiate()
	root.add_child(mm)
	_eq([mm.grid.size(), mm.grid[0].size(), mm.breakable_left], [17, 8, 136], "oversize level loads as 17x8")
	_kill(mm)
	cfg.level_path = old_path
	DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))
