## QA 驗收(2026-10-28 D35 HUD 獲得順序 / 方案 C 版面 / 光暈 / BUG-1 擋板不出牆)。
## 執行:Godot --headless --path game --script res://tests/qa_hud_order_test.gd
## 全部通過時結束碼 0,有失敗時結束碼 1。
extends SceneTree

const MainScene := preload("res://scenes/main.tscn")
const MainScript := preload("res://scripts/main.gd")
const FPS := 1.0 / 60.0
## 固定測試關卡(無魔王):不依賴 game_config.tres 目前的 level_path(魔王關進場有 1.6 秒 BOSS 警告)
const LEVEL := "res://data/levels/level_func_test.json"
const LEN := Effects.PADDLE_LEN
## R10 固定順序(D35)
const FIXED := ["reinforce", "fever", "speed", "pierce", "flame", "bomb", "paddle_len"]
const LEN_IDS := ["paddle_len_1", "paddle_len_2", "paddle_len_down_1", "paddle_len_down_2", "paddle_len_min"]
const FUZZ_POOL := ["slow", "fast", "reinforce", "pierce", "flame", "bomb",
	"paddle_len_1", "paddle_len_2", "paddle_len_down_1", "paddle_len_down_2", "paddle_len_min"]

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
	cfg.drop_chance = 0.0
	cfg.debug_enchant = ""
	cfg.debug_force_item = ""
	_run("r1_r2_append_and_fill", _t_r1_r2)
	_run("r3_reacquire_same_kind", _t_r3)
	_run("r4_r5_speed", _t_r4_r5)
	_run("r6_r7_length", _t_r6_r7)
	_run("r8_enchant", _t_r8)
	_run("r10_same_frame", _t_r10)
	_run("r10_golden_menu", _t_r10_menu)
	_run("r11_expire_and_reacquire", _t_r11)
	_run("r12_restart", _t_r12)
	_run("layout_c_slots", _t_layout)
	_run("layout_c_cross_column_fill", _t_cross_column)
	_run("halo", _t_halo)
	_run("long_sequence", _t_long_sequence)
	_run("bug1_expiry_frame", _t_bug1_expiry)
	_run("bug1_pickup_at_wall", _t_bug1_pickup)
	_run("bug1_menu_pick", _t_bug1_menu)
	_run("fuzz_vs_reference", _t_fuzz)
	print("QA HUD ORDER RESULT: %d passed, %d failed" % [_passed, _failed])
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


# ---------- 輔助 ----------

func _fresh(h := 800):
	var m = MainScene.instantiate()
	root.add_child(m)
	m.rng.seed = 777
	m.view_h = h
	for r in MainScript.MAX_ROWS:
		for c in MainScript.COLS:
			m.grid[r][c] = null
	# 哨兵磚:不讓遊戲因為沒有磚而過關
	var br = MainScript.Brick.new()
	br.layers = 69
	m.grid[0][7] = br
	m.breakable_left = 1
	m.items.clear()
	m.bullets.clear()
	m.balls.clear()
	m.anims.clear()
	m.paddle_x = 180.0
	m.target_x = 180.0
	m.time_left = 9999.0
	m.reduced_motion = false
	# 一顆黏在擋板上的球:遊戲不會因沒球而結束
	var b = MainScript.Ball.new()
	b.stuck = true
	b.pos = Vector2(180, m._paddle_y() - 8)
	m.balls.append(b)
	return m


## 跑一幀真實流程(_process → _step → HUD 更新)
func _frame(m, dt := 0.0) -> void:
	m._process(dt)


## 放一個道具在擋板正上方,下一幀 _update_items 會接到
func _drop(m, id: String) -> void:
	m.items.append({"id": id, "pos": Vector2(m.paddle_x - 8, m._paddle_y() - 20)})


func _kinds(m) -> Array:
	return m.hud_order.map(func(k): return k)


func _icons(m) -> Array:
	return m.hud.map(func(c: Array) -> String: return c[0])


func _expire_next(m, id: String) -> void:
	m.effects.timed[id]["remaining"] = FPS * 0.5


func _inside(m) -> bool:
	var len: int = m._paddle_len()
	var left: int = m._paddle_left(len)
	return left >= MainScript.FIELD_LEFT and left + len <= MainScript.FIELD_RIGHT


func _paddle_str(m) -> String:
	var len: int = m._paddle_len()
	var left: int = m._paddle_left(len)
	return "len %d left %d right %d paddle_x %.2f" % [len, left, left + len, m.paddle_x]


## 擋板移到牆邊(真實移動),side = -1 左、+1 右
func _to_wall(m, side: int) -> void:
	m.target_x = 1000.0 * side
	for i in 90:
		_frame(m, FPS)


# ---------- R1、R2 ----------

func _t_r1_r2() -> void:
	var m = _fresh()
	_frame(m)
	_eq(_kinds(m), [], "start: empty list")
	m._apply_item("flame")
	_frame(m)
	m._apply_item("reinforce")
	_frame(m)
	_eq(_kinds(m), ["flame", "reinforce"], "flame then reinforce (not fixed order)")
	m._apply_item("bomb")
	_frame(m)
	_eq(_kinds(m), ["flame", "reinforce", "bomb"], "R1 example: bomb appended last")
	_eq(_icons(m), ["d34_hud_icon_flame", "d34_hud_icon_reinforce", "d34_hud_icon_bomb"], "hud cells follow list order")
	_expire_next(m, "flame")
	_frame(m, FPS)
	_eq(_kinds(m), ["reinforce", "bomb"], "R2: flame expires -> removed, rest move up")
	_eq(_icons(m), ["d34_hud_icon_reinforce", "d34_hud_icon_bomb"], "R2: cells move up immediately")
	m._apply_item("flame")
	_frame(m)
	_eq(_kinds(m), ["reinforce", "bomb", "flame"], "R2 example: flame again -> new, last")
	m.free()


# ---------- R3 ----------

func _t_r3() -> void:
	var m = _fresh()
	for id in ["flame", "reinforce", "slow", "paddle_len_1", "bomb"]:
		m._apply_item(id)
		_frame(m, FPS)
	var want := ["flame", "reinforce", "speed", "paddle_len", "bomb"]
	_eq(_kinds(m), want, "setup order")
	m._apply_item("flame")
	_frame(m)
	_eq(_kinds(m), want, "R3: flame again -> position unchanged")
	_ok(m.effects.total("flame") > 20.0, "R3: flame time accumulated (%.2f)" % m.effects.total("flame"))
	m._apply_item("reinforce")
	m._apply_item("slow")
	m._apply_item("paddle_len_2")
	m._apply_item("bomb")
	_frame(m)
	_eq(_kinds(m), want, "R3: reinforce +1, slow again, len again, bomb again -> unchanged")
	_eq(m.hud[1][1], {"segments": cfg.reinforce_max, "filled": 2}, "R3: reinforce bar updated to 2")
	_eq(m.hud[2][1], {"segments": -cfg.ball_tier_min, "filled": 2}, "R3: slow bar updated to 2")
	m.free()


# ---------- R4、R5 ----------

func _t_r4_r5() -> void:
	var m = _fresh()
	m._apply_item("reinforce")
	_frame(m)
	m._apply_item("fast")
	_frame(m)
	m._apply_item("pierce")
	_frame(m)
	_eq(_kinds(m), ["reinforce", "speed", "pierce"], "fast +1 in position 2")
	_eq(_icons(m)[1], "d34_hud_icon_fast", "fast icon")
	m._apply_item("slow")
	_frame(m)
	_eq(_kinds(m), ["reinforce", "pierce"], "R4: +1 -> 0 removed")
	m._apply_item("slow")
	_frame(m)
	_eq(_kinds(m), ["reinforce", "pierce", "speed"], "R4: 0 -> -1 new, last")
	_eq(_icons(m)[2], "d34_hud_icon_slow", "slow icon")
	# R5:一次跨過 0(不經過 0)→ 同一格、位置不動,只換圖示
	m.effects.ball_tier = 2
	_frame(m)
	_eq(_kinds(m), ["reinforce", "pierce", "speed"], "R5: -1 -> +2 in one step: same cell")
	_eq(_icons(m)[2], "d34_hud_icon_fast", "R5: icon switched to fast")
	m.effects.ball_tier = 0
	_frame(m)
	m.effects.ball_tier = -1
	_frame(m)
	m._apply_item("bomb")
	_frame(m)
	_eq(_kinds(m), ["reinforce", "pierce", "speed", "bomb"], "R4 again via direct values")
	m.free()
	# 同一幀撿到兩個減速:+1 → 0 → -1 都在同一幀(實作只看幀末存在與否)
	var m2 = _fresh()
	m2._apply_item("fast")
	_frame(m2)
	m2._apply_item("pierce")
	_frame(m2)
	_drop(m2, "slow")
	_drop(m2, "slow")
	_frame(m2, FPS)
	print("INFO same frame +1 -> 0 -> -1 (two slows): tier %d, list %s (spec R5 ambiguous; impl keeps position)" % [m2.effects.ball_tier, _kinds(m2)])
	_eq(m2.effects.ball_tier, -1, "two slows in one frame picked")
	m2.free()


# ---------- R6、R7 ----------

func _t_r6_r7() -> void:
	var m = _fresh()
	m._apply_item("paddle_len_1")
	_frame(m)
	m._apply_item("reinforce")
	_frame(m)
	_eq(_kinds(m), ["paddle_len", "reinforce"], "len first, reinforce second")
	_expire_next(m, LEN)
	_frame(m, FPS)
	_eq([_kinds(m), m._paddle_len()], [["reinforce"], 85], "R6: back to 85 -> removed")
	m._apply_item("paddle_len_down_1")
	_frame(m)
	_eq(_kinds(m), ["reinforce", "paddle_len"], "R6 example: down again -> new, last")
	_eq(_icons(m)[1], "d34_hud_icon_paddle_len_down1", "R6: '-' icon")
	m.free()
	# R7:+ → − 沒經過 85
	var m2 = _fresh()
	m2._apply_item("paddle_len_1")
	_frame(m2)
	m2._apply_item("pierce")
	_frame(m2)
	m2._apply_item("paddle_len_down_2")
	_frame(m2)
	_eq([_kinds(m2), m2._paddle_len()], [["paddle_len", "pierce"], 41], "R7: 102 -> 41, same cell")
	_eq(_icons(m2)[0], "d34_hud_icon_paddle_len_down1", "R7: icon '+' -> '-'")
	for i in 3:
		m2._apply_item("paddle_len_2")
		_frame(m2)
	_eq(_kinds(m2), ["paddle_len", "pierce"], "R7: '-' -> '+' (len %d) same cell" % m2._paddle_len())
	_eq(_icons(m2)[0], "d34_hud_icon_paddle_len_up1", "R7: icon back to '+'")
	m2.free()
	# 最短化後再變長(> 85):仍是 −,位置不動
	var m3 = _fresh()
	m3._apply_item("paddle_len_min")
	_frame(m3)
	m3._apply_item("bomb")
	_frame(m3)
	for i in 3:
		m3._apply_item("paddle_len_2")
		_frame(m3)
	_eq([_kinds(m3), _icons(m3)[0]], [["paddle_len", "bomb"], "d34_hud_icon_paddle_len_down1"], "min then ups (len %d > 85): '-' and same cell" % m3._paddle_len())
	m3.free()
	# 計時中長度剛好回到 85(1.25 × 0.8):移除;再 ≠ 85 → 排最後
	var old: float = cfg.len_small_up
	cfg.len_small_up = 1.25
	var m4 = _fresh()
	m4._apply_item("paddle_len_1")
	_frame(m4)
	m4._apply_item("reinforce")
	_frame(m4)
	m4._apply_item("paddle_len_down_1")
	_frame(m4)
	_eq([_kinds(m4), m4._paddle_len(), m4.effects.is_active(LEN)], [["reinforce"], 85, true], "R6: exactly 85 while timer runs -> removed")
	m4._apply_item("paddle_len_down_1")
	_frame(m4)
	_eq(_kinds(m4), ["reinforce", "paddle_len"], "R6: != 85 again -> last")
	m4.free()
	cfg.len_small_up = old


# ---------- R8 ----------

func _t_r8() -> void:
	for e in ["pierce", "flame"]:
		cfg.debug_enchant = e
		var m = _fresh()
		cfg.debug_enchant = ""
		_frame(m)
		_eq(_kinds(m), [e], "%s enchant: list built at start" % e)
		_eq(m.hud[0], ["d34_hud_icon_" + e, {"fill": Rules.BAR_INNER}], "%s enchant: full bar" % e)
		m._apply_item("reinforce")
		_frame(m)
		m._apply_item("paddle_len_2")
		_frame(m)
		m._apply_item(e)
		_frame(m)
		_eq(_kinds(m), [e, "reinforce", "paddle_len"], "%s enchant: stays first; re-pick same kind -> unchanged" % e)
		var other: String = "flame" if e == "pierce" else "pierce"
		m._apply_item(other)
		m._apply_item("bomb")
		_frame(m)
		_eq(_kinds(m), [e, "reinforce", "paddle_len", other, "bomb"], "%s enchant + %s + bomb same frame" % [e, other])
		for i in 4:
			m.effects.tick(30.0)
			_frame(m, FPS)
		_eq(_kinds(m), [e, "reinforce"], "%s enchant: after all timers end, enchant still first" % e)
		_eq(m.hud[0], ["d34_hud_icon_" + e, {"fill": Rules.BAR_INNER}], "%s enchant: full bar after timed part ended" % e)
		m.free()


# ---------- R10 ----------

func _t_r10() -> void:
	var m = _fresh()
	m._apply_item("bomb")
	m._apply_item("reinforce")
	_frame(m)
	_eq(_kinds(m), ["reinforce", "bomb"], "R10 example: bomb + reinforce same frame -> reinforce first")
	m.free()
	# 從空清單同一幀全部出現(反序撿到)→ 固定順序,擋板長度最後
	var m2 = _fresh()
	for id in ["paddle_len_down_1", "bomb", "flame", "pierce", "slow", "reinforce"]:
		m2._apply_item(id)
	_frame(m2)
	_eq(_kinds(m2), ["reinforce", "speed", "pierce", "flame", "bomb", "paddle_len"], "R10: all at once in reverse -> fixed order")
	m2.free()
	# 真實掉落:同一幀接到多個道具,已有 [火焰]
	var m3 = _fresh()
	m3._apply_item("flame")
	_frame(m3)
	for id in ["paddle_len_2", "bomb", "slow", "reinforce"]:
		_drop(m3, id)
	_frame(m3, FPS)
	_eq(m3.items.size(), 0, "all 4 items caught in one frame")
	_eq(_kinds(m3), ["flame", "reinforce", "speed", "bomb", "paddle_len"], "R10: 4 caught same frame appended in fixed order after existing")
	m3.free()
	# 同一幀先移除再新增
	var m4 = _fresh()
	for id in ["flame", "reinforce", "bomb"]:
		m4._apply_item(id)
		_frame(m4)
	_expire_next(m4, "flame")
	_drop(m4, "pierce")
	_drop(m4, "fast")
	_frame(m4, FPS)
	_eq(_kinds(m4), ["reinforce", "bomb", "speed", "pierce"], "R10: remove first, then new ones in fixed order")
	m4.free()


## 金球/黑球 3 選 1:選中後依選擇順序加入;選單開著時(暫停中)也立即更新
func _t_r10_menu() -> void:
	var m = _fresh()
	m._apply_item("flame")
	_frame(m)
	_drop(m, "golden_ball")
	_drop(m, "golden_ball")
	_frame(m, FPS)
	_ok(m.menu != null, "golden menu opened")
	_eq(m.menu_queue.size(), 1, "second golden ball queued")
	var first: ChoiceMenu = m.menu
	first._process(0.6)
	print("INFO golden menu 1 ids %s" % [first.ids])
	# 選項換成測試需要的(畫面不重要),走真實按下流程
	first.ids[0] = "bomb"
	first._on_pressed(0)
	_frame(m)
	_eq(_kinds(m), ["flame", "bomb"], "menu pick bomb (paused) -> appended")
	first._process(2.0)
	_frame(m, FPS)
	_frame(m, FPS)
	_ok(m.menu != null and m.menu != first, "second menu opened")
	if m.menu != null:
		m.menu._process(0.6)
		m.menu.ids[0] = "reinforce"
		m.menu._on_pressed(0)
	_frame(m)
	_eq(_kinds(m), ["flame", "bomb", "reinforce"], "2nd golden pick reinforce -> last (pick order, not fixed order)")
	m.free()


# ---------- R11 ----------

func _t_r11() -> void:
	var m = _fresh()
	for id in ["flame", "reinforce"]:
		m._apply_item(id)
		_frame(m)
	_expire_next(m, "flame")
	_drop(m, "flame")
	_frame(m, FPS)
	_eq(_kinds(m), ["flame", "reinforce"], "R11 example: flame expires and is picked same frame -> unchanged")
	_ok(m.effects.remaining("flame") > 19.9, "flame restarted (%.3f)" % m.effects.remaining("flame"))
	m.free()
	var m2 = _fresh()
	m2._apply_item("paddle_len_1")
	_frame(m2)
	m2._apply_item("pierce")
	_frame(m2)
	_expire_next(m2, LEN)
	_drop(m2, "paddle_len_down_1")
	_frame(m2, FPS)
	_eq([_kinds(m2), m2._paddle_len()], [["paddle_len", "pierce"], 68], "R11: length expiry + new length same frame -> unchanged, 85 x 0.8")
	_eq(_icons(m2)[0], "d34_hud_icon_paddle_len_down1", "R11: icon follows new length")
	m2.free()
	# 炸彈到期與再撿同一幀:記錄是否爆炸(R11 寫「先加時間,再判斷到期」)
	var m3 = _fresh()
	var br = MainScript.Brick.new()
	br.layers = 3
	br.marked = true
	m3.grid[5][3] = br
	m3.breakable_left += 1
	m3._apply_item("bomb")
	_frame(m3)
	_expire_next(m3, "bomb")
	_drop(m3, "bomb")
	_frame(m3, FPS)
	print("INFO R11 bomb expire + re-pick same frame: marked brick %s (spec 'add time first' would keep it marked)" % ["exploded" if m3.grid[5][3] == null else "still there"])
	m3.free()


# ---------- R12 ----------

func _t_r12() -> void:
	var m = _fresh()
	for id in ["flame", "reinforce", "slow", "paddle_len_2"]:
		m._apply_item(id)
	_frame(m)
	_eq(_kinds(m).size(), 4, "old game has 4 cells")
	m.free()
	var m2 = _fresh()
	_frame(m2)
	_eq([_kinds(m2), m2.hud], [[], []], "R12: new game (scene reload) -> empty")
	m2.free()
	cfg.debug_enchant = "flame"
	var m3 = _fresh()
	cfg.debug_enchant = ""
	_frame(m3)
	_eq(_kinds(m3), ["flame"], "R12: new game with enchant -> only enchant")
	m3.free()


# ---------- 版面(方案 C) ----------

func _t_layout() -> void:
	var expect := {
		800: [[24, 424], [24, 476], [24, 528], [24, 580], [24, 632], [24, 684], [76, 424]],
		707: [[24, 424], [24, 476], [24, 528], [24, 580], [76, 424], [76, 476], [76, 528]],
		640: [[24, 424], [24, 476], [24, 528], [76, 424], [76, 476], [76, 528], [128, 424]],
	}
	var m = _fresh()
	for h in expect:
		m.view_h = h
		var got := []
		for i in 7:
			var s: Vector2 = m._hud_slot(i)
			got.append([int(s.x), int(s.y)])
		_eq(got, expect[h], "H %d slots" % h)
	# 640~800 每個高度:最下一列格底端離擋板上緣(H − 45)≥ 12 px,且 7 格不超出關卡右牆
	var bad := []
	for h in range(640, 801):
		m.view_h = h
		@warning_ignore("integer_division")
		var per_col: int = (h - 473) / 52
		var lowest := 0
		var rightmost := 0
		for i in 7:
			var s: Vector2 = m._hud_slot(i)
			lowest = maxi(lowest, int(s.y) + 44)
			rightmost = maxi(rightmost, int(s.x) + 44)
			if int(s.y) < 424:
				bad.append("H %d slot %d y %d" % [h, i, s.y])
		if lowest > h - 45 - 12 or rightmost > MainScript.FIELD_RIGHT or per_col < 1:
			bad.append("H %d lowest %d rightmost %d" % [h, lowest, rightmost])
		if int(m._hud_slot(per_col).x) != 76 and per_col < 7:
			bad.append("H %d slot %d not in column 2" % [h, per_col])
	_eq(bad, [], "all H 640..800: cells clear of paddle by 12 px, inside field, column switch at per_col")
	m.free()


## 707 高:6 格跨兩欄;第 1 格結束 → 第 2 欄最上一格補到第 1 欄最後一格
func _t_cross_column() -> void:
	var m = _fresh(707)
	for id in ["bomb", "paddle_len_1", "reinforce", "slow", "pierce", "flame"]:
		m._apply_item(id)
		_frame(m, FPS)
	_eq(_kinds(m), ["bomb", "paddle_len", "reinforce", "speed", "pierce", "flame"], "707: 6 cells in acquisition order")
	_eq([m._hud_slot(4), m._hud_slot(5)], [Vector2(76, 424), Vector2(76, 476)], "707: pierce / flame in column 2")
	_expire_next(m, "bomb")
	_frame(m, FPS)
	_eq(_icons(m), ["d34_hud_icon_paddle_len_up1", "d34_hud_icon_reinforce", "d34_hud_icon_slow", "d34_hud_icon_pierce", "d34_hud_icon_flame"], "707: bomb gone, rest move up")
	_eq(m._hud_slot(3), Vector2(24, 580), "707: pierce jumps to column 1 last slot")
	_eq(m._hud_slot(4), Vector2(76, 424), "707: flame to column 2 top")
	m.free()
	var m2 = _fresh(640)
	for id in ["flame", "reinforce", "slow", "pierce", "bomb", "paddle_len_down_2"]:
		m2._apply_item(id)
		_frame(m2)
	_eq(_kinds(m2).size(), 6, "640: 6 cells (fever not implemented -> max 6)")
	_eq(m2._hud_slot(5), Vector2(76, 528), "640: 6th cell at column 2 row 3")
	m2.free()


# ---------- 光暈 ----------

func _t_halo() -> void:
	var cases := [
		[[], false, "nothing"],
		[["paddle_len_1"], false, "length only (+)"],
		[["paddle_len_down_1"], false, "length only (-)"],
		[["paddle_len_1", "slow"], true, "length + slow"],
		[["fast"], true, "fast only"],
		[["reinforce"], true, "reinforce only"],
		[["bomb", "paddle_len_min"], true, "bomb + length"],
	]
	for c in cases:
		var m = _fresh()
		for id in c[0]:
			m._apply_item(id)
		_frame(m)
		_eq(m._halo_on(), c[1], "halo: %s" % c[2])
		m.free()
	cfg.debug_enchant = "pierce"
	var m2 = _fresh()
	cfg.debug_enchant = ""
	_frame(m2)
	_eq(m2._halo_on(), true, "halo: enchant only")
	m2.free()
	# 長度格 + 其他,其他結束後只剩長度 → 熄
	var m3 = _fresh()
	m3._apply_item("paddle_len_2")
	m3._apply_item("bomb")
	_frame(m3)
	_ok(m3._halo_on(), "halo on: length + bomb")
	_expire_next(m3, "bomb")
	_frame(m3, FPS)
	_eq([_kinds(m3), m3._halo_on()], [["paddle_len"], false], "bomb ends -> only length -> halo off")
	m3.free()


# ---------- 長序列 ----------

func _t_long_sequence() -> void:
	var m = _fresh()
	var steps := [
		["slow", ["speed"]],
		["paddle_len_2", ["speed", "paddle_len"]],
		["bomb", ["speed", "paddle_len", "bomb"]],
		["fast", ["paddle_len", "bomb"]],                       # 速度歸 0
		["flame", ["paddle_len", "bomb", "flame"]],
		["fast", ["paddle_len", "bomb", "flame", "speed"]],     # 速度 +1 排最後
		["reinforce", ["paddle_len", "bomb", "flame", "speed", "reinforce"]],
		["paddle_len_down_2", ["paddle_len", "bomb", "flame", "speed", "reinforce"]],  # 163 × 0.4 → 65:換圖不換位
		["!bomb", ["paddle_len", "flame", "speed", "reinforce"]],
		["pierce", ["paddle_len", "flame", "speed", "reinforce", "pierce"]],
		["!paddle_len", ["flame", "speed", "reinforce", "pierce"]],
		["bomb", ["flame", "speed", "reinforce", "pierce", "bomb"]],
		["paddle_len_min", ["flame", "speed", "reinforce", "pierce", "bomb", "paddle_len"]],
		["!flame", ["speed", "reinforce", "pierce", "bomb", "paddle_len"]],
		["slow", ["reinforce", "pierce", "bomb", "paddle_len"]],
		["slow", ["reinforce", "pierce", "bomb", "paddle_len", "speed"]],
		["!pierce", ["reinforce", "bomb", "paddle_len", "speed"]],
		["flame", ["reinforce", "bomb", "paddle_len", "speed", "flame"]],
		["bomb", ["reinforce", "bomb", "paddle_len", "speed", "flame"]],
	]
	for s in steps:
		var op: String = s[0]
		if op.begins_with("!"):
			_expire_next(m, op.substr(1))
		else:
			m._apply_item(op)
		_frame(m, FPS)
		_eq(_kinds(m), s[1], "after %s" % op)
	m.free()


# ---------- BUG-1 ----------

func _t_bug1_expiry() -> void:
	for side in [-1, 1]:
		for id in ["paddle_len_min", "paddle_len_down_2", "paddle_len_down_1"]:
			var m = _fresh()
			m._apply_item(id)
			_to_wall(m, side)
			_ok(_inside(m), "%s at wall %d before expiry: %s" % [id, side, _paddle_str(m)])
			_expire_next(m, LEN)
			_frame(m, FPS)
			_ok(not m.effects.is_active(LEN) and m._paddle_len() == 85, "%s side %d: expired this frame" % [id, side])
			_ok(_inside(m), "%s side %d: inside walls on expiry frame (%s)" % [id, side, _paddle_str(m)])
			var all_in := true
			for i in 30:
				_frame(m, FPS)
				all_in = all_in and _inside(m)
			_ok(all_in, "%s side %d: inside walls for 30 frames after" % [id, side])
			m.free()


func _t_bug1_pickup() -> void:
	for side in [-1, 1]:
		for id in LEN_IDS:
			var m = _fresh()
			_to_wall(m, side)
			_drop(m, id)
			_frame(m, FPS)
			_ok(m.items.is_empty(), "%s side %d: caught" % [id, side])
			_ok(_inside(m), "%s side %d: inside walls on pickup frame (%s)" % [id, side, _paddle_str(m)])
			m.free()
		# 連續變長到上限,每個接到的幀都在牆內(含奇數長度 102 × 1.6 = 163)
		var m2 = _fresh()
		_to_wall(m2, side)
		var bad := []
		for id in ["paddle_len_1", "paddle_len_2", "paddle_len_2", "paddle_len_2", "paddle_len_2"]:
			_drop(m2, id)
			_frame(m2, FPS)
			if not _inside(m2):
				bad.append(_paddle_str(m2))
			for i in 3:
				_frame(m2, FPS)
				if not _inside(m2):
					bad.append(_paddle_str(m2))
		_eq(bad, [], "side %d: consecutive ups to 320, inside every frame" % side)
		m2.free()


func _t_bug1_menu() -> void:
	for side in [-1, 1]:
		for id in ["paddle_len_1", "paddle_len_2"]:
			var m = _fresh()
			_to_wall(m, side)
			var menu := ChoiceMenu.new()
			menu.setup(true, [id, "slow", "split"], 800, true)
			menu.picked.connect(m._on_menu_picked)
			menu.closed.connect(func() -> void: m.menu = null)
			m.menu = menu
			m.add_child(menu)
			menu._process(0.6)
			menu._on_pressed(0)
			_ok(m.effects.is_active(LEN), "%s side %d: menu pick applied" % [id, side])
			_ok(_inside(m), "%s side %d: inside walls right after menu pick, paused (%s)" % [id, side, _paddle_str(m)])
			_frame(m, FPS)
			_ok(m.menu != null and _inside(m), "%s side %d: inside on paused frame" % [id, side])
			menu._process(2.0)
			var all_in := true
			for i in 10:
				_frame(m, FPS)
				all_in = all_in and _inside(m)
			_ok(m.menu == null and all_in, "%s side %d: inside after menu closes" % [id, side])
			m.free()


# ---------- 隨機長序列 vs 規格參考模型 ----------

func _ref_present(m) -> Dictionary:
	var e: Effects = m.effects
	var out := {}
	if e.reinforce >= 1:
		out["reinforce"] = "d34_hud_icon_reinforce"
	if e.ball_tier != 0:
		out["speed"] = "d34_hud_icon_slow" if e.ball_tier < 0 else "d34_hud_icon_fast"
	for k in ["pierce", "flame", "bomb"]:
		if e.is_active(k) or e.enchant == k:
			out[k] = "d34_hud_icon_" + k
	var len: int = m._paddle_len()
	if len != 85:
		out["paddle_len"] = "d34_hud_icon_paddle_len_down1" if e.paddle_min or len < 85 else "d34_hud_icon_paddle_len_up1"
	return out


func _t_fuzz() -> void:
	var rng := RandomNumberGenerator.new()
	var mismatches := []
	var outside := []
	var frames := 0
	for seed in 40:
		rng.seed = 1000 + seed
		var enchant: String = ["", "", "pierce", "flame"][seed % 4]
		cfg.debug_enchant = enchant
		var m = _fresh([800, 707, 640][seed % 3])
		cfg.debug_enchant = ""
		var ref := []
		for f in 500:
			if rng.randf() < 0.25:
				for i in rng.randi_range(1, 3):
					_drop(m, FUZZ_POOL[rng.randi_range(0, FUZZ_POOL.size() - 1)])
			if rng.randf() < 0.06 and not m.effects.timed.is_empty():
				var keys: Array = m.effects.timed.keys()
				_expire_next(m, keys[rng.randi_range(0, keys.size() - 1)])
			if rng.randf() < 0.05:
				m.target_x = [-1000.0, 1000.0, 180.0, rng.randf_range(0, 360)][rng.randi_range(0, 3)]
			_frame(m, FPS)
			frames += 1
			var present := _ref_present(m)
			ref = ref.filter(func(k) -> bool: return present.has(k))
			for k in FIXED:
				if present.has(k) and k not in ref:
					ref.append(k)
			var want_icons := ref.map(func(k) -> String: return present[k])
			if _kinds(m) != ref or _icons(m) != want_icons:
				if mismatches.size() < 5:
					mismatches.append("seed %d frame %d: want %s got %s / icons %s" % [seed, f, ref, _kinds(m), _icons(m)])
			var halo_want := ref.any(func(k) -> bool: return k != "paddle_len")
			if m._halo_on() != halo_want and mismatches.size() < 5:
				mismatches.append("seed %d frame %d: halo want %s" % [seed, f, halo_want])
			if not _inside(m) and outside.size() < 5:
				outside.append("seed %d frame %d %s" % [seed, f, _paddle_str(m)])
			if m.state != 0:
				break
		m.free()
	print("INFO fuzz frames %d" % frames)
	_eq(mismatches, [], "random sequences: list / icons / halo match spec reference model")
	_eq(outside, [], "random sequences: paddle inside walls every frame")
