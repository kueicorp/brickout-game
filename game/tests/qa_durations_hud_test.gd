## QA 驗收(2026-10-28 道具秒數 / 擋板長度共用計時 / D34 HUD / D33 第 2 欄):規格 A~E 與邊界。
## 執行:Godot --headless --path game --script res://tests/qa_durations_hud_test.gd
## 全部通過時結束碼 0,有失敗時結束碼 1。
extends SceneTree

const MainScene := preload("res://scenes/main.tscn")
const MainScript := preload("res://scripts/main.gd")
const FPS := 1.0 / 60.0
## 固定測試關卡(無魔王):不依賴 game_config.tres 目前的 level_path(魔王關進場有 1.6 秒 BOSS 警告)
const LEVEL := "res://data/levels/level_func_test.json"

## 規格 A 的秒數(使用者確認)
const DUR := {
	"pierce": 20.0, "flame": 20.0, "bomb": 10.0, "sticky": 30.0, "gun": 10.0, "heal": 10.0,
	"heal_area": 10.0, "blackhole": 5.0, "invincible": 10.0, "invisible": 10.0,
}
const WHOLE_GAME := ["slow", "split", "reinforce", "golden_ball", "paddle_speed", "paddle_speed_down",
	"fast", "merge", "blackhole_big", "thief", "black_ball"]
const LEN_IDS := ["paddle_len_1", "paddle_len_2", "paddle_len_down_1", "paddle_len_down_2", "paddle_len_min"]

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
	_run("a_config_values", _t_config_values)
	_run("a_pickup_durations", _t_pickup_durations)
	_run("a_accumulate", _t_accumulate)
	_run("a_whole_game", _t_whole_game)
	_run("a_expire_exact_frame", _t_expire_exact_frame)
	_run("a_expire_real_frames", _t_expire_real_frames)
	_run("a_sticky_expire_multi", _t_sticky_expire_multi)
	_run("a_gun_expire", _t_gun_expire)
	_run("a_enchant", _t_enchant)
	_run("a_menu_pick_durations", _t_menu_pick_durations)
	_run("b_len_multiply", _t_len_multiply)
	_run("b_len_timer_reset", _t_len_timer_reset)
	_run("b_len_clamp", _t_len_clamp)
	_run("b_len_expire_all", _t_len_expire_all)
	_run("b_len_max_removed", _t_len_max_removed)
	_run("c_text", _t_text)
	_run("d_hud_column1", _t_hud_column1)
	_run("e_hud_len_cell", _t_hud_len_cell)
	_run("e_halo_rule", _t_halo_rule)
	_run("e_expiry_paddle_edge", _t_expiry_paddle_edge)
	print("QA DURATIONS/HUD RESULT: %d passed, %d failed" % [_passed, _failed])
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


func _near(actual: float, expected: float, label: String) -> void:
	_ok(absf(actual - expected) < 0.0001, "%s (%.5f vs %.5f)" % [label, actual, expected])


# ---------- 輔助 ----------

func _fresh():
	var m = MainScene.instantiate()
	root.add_child(m)
	m.rng.seed = 4242
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
	m.score = 0
	m.paddle_x = 180.0
	m.target_x = 180.0
	m.time_left = 9999.0
	m.reduced_motion = false
	return m


func _ball(m, pos: Vector2, dir: Vector2, stuck := false):
	var b = MainScript.Ball.new()
	b.pos = pos
	b.dir = dir
	b.stuck = stuck
	m.balls.append(b)
	return b


func _tick(m, dt: float) -> Array:
	var out: Array = m.effects.tick(dt)
	for id in out:
		m._on_expired(id)
	return out


# ---------- A ----------

func _t_config_values() -> void:
	for id in DUR:
		_eq(cfg.get("dur_" + id), DUR[id], "game_config dur_%s" % id)
	_eq(cfg.dur_paddle_len, 30.0, "game_config dur_paddle_len")
	_eq(cfg.get("effect_duration"), null, "old shared effect_duration removed")


func _t_pickup_durations() -> void:
	for id in DUR:
		var m = _fresh()
		_ball(m, Vector2(100, 400), Vector2.UP)
		m._pickup(id, Vector2(100, 600))
		_eq([m.effects.remaining(id), m.effects.total(id)], [DUR[id], DUR[id]], "%s picked: remaining = total = %.0f" % [id, DUR[id]])
		m.free()
	for id in LEN_IDS:
		var m = _fresh()
		m._pickup(id, Vector2(100, 600))
		_eq([m.effects.remaining(Effects.PADDLE_LEN), m.effects.timed.keys()], [30.0, [Effects.PADDLE_LEN]], "%s picked: shared timer 30, no per-id timer" % id)
		m.free()


func _t_accumulate() -> void:
	for id in DUR:
		var m = _fresh()
		_ball(m, Vector2(100, 400), Vector2.UP)
		m._apply_item(id)
		m.effects.tick(DUR[id] - 1.5)
		m._apply_item(id)
		var want: float = 1.5 + DUR[id]
		_near(m.effects.remaining(id), want, "%s: 1.5 left + %.0f = %.1f" % [id, DUR[id], want])
		_near(m.effects.total(id), want, "%s: bar total = accumulated remaining" % id)
		m.free()
	# 不同效果互不影響
	var m2 = _fresh()
	m2._apply_item("pierce")
	m2._apply_item("blackhole")
	m2.effects.tick(5.0)
	_eq([m2.effects.is_active("pierce"), m2.effects.is_active("blackhole")], [true, false], "pierce 20 still on when blackhole 5 expired")
	m2.free()


func _t_whole_game() -> void:
	for id in WHOLE_GAME:
		var m = _fresh()
		for i in 4:
			_ball(m, Vector2(60 + 40 * i, 400), Vector2.UP)
		m.score = 10000
		m._apply_item(id)
		_eq(m.effects.timed.keys(), [], "%s: no timer created" % id)
		m.free()
	var m2 = _fresh()
	_ball(m2, Vector2(100, 400), Vector2.UP)
	for id in ["slow", "slow", "reinforce", "paddle_speed"]:
		m2._apply_item(id)
	_tick(m2, 10000.0)
	_eq([m2.effects.ball_tier, m2.effects.reinforce, m2.effects.paddle_tier], [-2, 1, 1], "untimed effects survive 10000 s")
	m2.free()


## 計時剛好到期:tick(剩餘) 那一次就移除;少一點點還在(用 2 進位可精確表示的 0.25 秒,避免浮點誤差)
func _t_expire_exact_frame() -> void:
	for id in DUR:
		var m = _fresh()
		_ball(m, Vector2(100, 400), Vector2.UP)
		m._apply_item(id)
		_eq(_tick(m, DUR[id] - 0.25), [], "%s: active at %.2f s" % [id, DUR[id] - 0.25])
		_ok(m.effects.is_active(id), "%s: still active 250 ms before" % id)
		_eq(_tick(m, 0.25), [id], "%s: expires on the exact frame" % id)
		_ok(not m.effects.is_active(id), "%s: gone" % id)
		m.free()
	var m2 = _fresh()
	m2._apply_item("paddle_len_2")
	m2.effects.tick(29.75)
	_eq(m2._paddle_len(), 136, "length still 136 at 29.75 s")
	_eq(m2.effects.tick(0.25), [Effects.PADDLE_LEN] as Array[String], "length timer expires at exactly 30 s")
	_eq(m2._paddle_len(), 85, "length back to 85 on that frame")
	m2.free()


## 真實逐幀(_step,60 fps):10 秒效果在第 600 或 601 幀到期(浮點累積誤差至多 1 幀),記錄實際幀數
func _t_expire_real_frames() -> void:
	for id in ["gun", "pierce", "blackhole"]:
		var m = _fresh()
		# 球黏在擋板上:不會掉出去結束遊戲
		_ball(m, Vector2(180, m._paddle_y() - 8), Vector2.UP, true)
		m._apply_item(id)
		var n := 0
		while m.effects.is_active(id) and n < 5000 and m.state == 0:
			m._step(FPS)
			n += 1
		var want := roundi(DUR[id] * 60)
		print("INFO %s (%.0f s) expired after %d frames at 60 fps (exact = %d)" % [id, DUR[id], n, want])
		_ok(n == want or n == want + 1, "%s expires at frame %d or %d (got %d)" % [id, want, want + 1, n])
		m.free()


## 吸附到期:多顆已黏住的球維持黏住、跟著擋板,點擊放開才一起發射;到期後新碰到的球反彈
func _t_sticky_expire_multi() -> void:
	var m = _fresh()
	m._apply_item("sticky")
	var py: int = m._paddle_y()
	var bs := []
	for x in [150.0, 170.0, 190.0, 210.0]:
		bs.append(_ball(m, Vector2(x, py - 10), Vector2.DOWN))
	m._step(FPS)
	_ok(bs.all(func(b) -> bool: return b.stuck), "4 balls stuck")
	var n := 0
	while m.effects.is_active("sticky") and n < 3000:
		m._step(FPS)
		n += 1
	_ok(not m.effects.is_active("sticky"), "sticky expired after %d frames" % n)
	# 到期後拖動擋板,球仍黏著
	m.target_x = 260.0
	for i in 60:
		m._step(FPS)
	_ok(bs.all(func(b) -> bool: return b.stuck), "after expiry: all 4 still stuck")
	var len: int = m._paddle_len()
	var left: int = m._paddle_left(len)
	_ok(bs.all(func(b) -> bool: return b.pos.x >= left and b.pos.x <= left + len and is_equal_approx(b.pos.y, py - 8.0)), "stuck balls follow moved paddle")
	_eq(m.balls.size(), 4, "no ball lost while stuck after expiry")
	# 新球碰擋板 → 反彈
	var nb = _ball(m, Vector2(m.paddle_x + 30, py - 10), Vector2.DOWN)
	m._step(FPS)
	_eq([nb.stuck, nb.dir.y < 0.0], [false, true], "new ball after expiry bounces")
	# 點擊放開 → 4 顆都發射
	var t := InputEventScreenTouch.new()
	t.index = 0
	t.pressed = false
	m._unhandled_input(t)
	_ok(bs.all(func(b) -> bool: return not b.stuck and b.dir.y < 0.0), "tap release launches all 4 stuck balls")
	m.free()
	# 黏住的球在吸附到期前後撿到分裂:新球也是黏著
	var m2 = _fresh()
	m2._apply_item("sticky")
	var s = _ball(m2, Vector2(180, m2._paddle_y() - 8), Vector2.UP, true)
	_tick(m2, 31.0)
	m2._apply_item("split")
	_ok(m2.balls.all(func(b) -> bool: return b.stuck), "split after sticky expiry: copies of stuck ball stay stuck (%d balls)" % m2.balls.size())
	m2.free()


## 槍到期:不再發射;飛行中的子彈飛完並照常打磚;擋板槍端消失(用 is_active 判定)
func _t_gun_expire() -> void:
	var m = _fresh()
	_ball(m, Vector2(100, 300), Vector2.UP)
	var br = MainScript.Brick.new()
	br.layers = 5
	m.grid[10][4] = br
	m.breakable_left += 1
	m.paddle_x = 180.0
	m._apply_item("gun")
	m.effects.timed["gun"]["remaining"] = 0.02
	m._fire_gun()
	_eq(m.bullets.size(), 2, "fired 2 bullets just before expiry")
	m._step(FPS)
	m._step(FPS)
	_ok(not m.effects.is_active("gun"), "gun expired")
	var n0: int = m.bullets.size()
	_ok(n0 > 0, "bullets still flying after expiry (%d)" % n0)
	var t := InputEventScreenTouch.new()
	t.index = 0
	t.pressed = true
	m.gun_cd = 0.0
	m._unhandled_input(t)
	_eq(m.bullets.size(), n0, "tap after expiry fires nothing")
	for i in 120:
		m._step(FPS)
	_eq(m.bullets.size(), 0, "flying bullets finish")
	_ok(m.grid[10][4] != null and m.grid[10][4].layers < 5, "in-flight bullets after expiry still damage bricks (layers %s)" % (m.grid[10][4].layers if m.grid[10][4] != null else -1))
	m.free()


## 付費附魔整局:限時穿透/火焰到期後仍生效,HUD 顯示滿條
func _t_enchant() -> void:
	for id in ["pierce", "flame"]:
		var m = _fresh()
		m.effects.enchant = id
		m._apply_item(id)
		_tick(m, 100.0)
		_ok(not m.effects.is_active(id), "%s timed part expired" % id)
		_ok(m._pierce_on() if id == "pierce" else m._flame_on(), "%s enchant still on after timer" % id)
		var cells: Array = m._hud_cells()
		_eq(cells, [["d34_hud_icon_" + id, {"fill": Rules.BAR_INNER}]], "%s enchant HUD full bar" % id)
		m.free()


## 金球/黑球 3 選 1 選到限時道具:秒數與直接撿到相同(含吸附 30、槍 10),選單開著時不流逝
func _t_menu_pick_durations() -> void:
	for pair in [[true, "sticky"], [true, "gun"], [true, "pierce"], [true, "bomb"], [false, "blackhole"],
			[false, "invincible"], [false, "heal_area"], [true, "paddle_len_2"], [false, "paddle_len_min"]]:
		var m = _fresh()
		_ball(m, Vector2(100, 400), Vector2.UP)
		var menu := ChoiceMenu.new()
		menu.setup(pair[0], [pair[1], "slow" if pair[0] else "fast", "split" if pair[0] else "merge"], 800, true)
		menu.picked.connect(m._on_menu_picked)
		menu.closed.connect(func() -> void: m.menu = null)
		m.menu = menu
		m.add_child(menu)
		menu._process(0.6)
		menu._on_pressed(0)
		var key: String = Effects.PADDLE_LEN if pair[1].begins_with("paddle_len") else pair[1]
		var want: float = 30.0 if key == Effects.PADDLE_LEN else DUR[pair[1]]
		_eq(m.effects.remaining(key), want, "menu (%s) picks %s -> %.0f s" % ["golden" if pair[0] else "black", pair[1], want])
		# 選單關閉前遊戲暫停
		m._process(0.1)
		_eq(m.effects.remaining(key), want, "%s: timer paused while menu still open" % pair[1])
		menu._process(1.0)
		m._process(0.05)
		_ok(m.effects.remaining(key) < want, "%s: timer runs after menu closes" % pair[1])
		m.free()


# ---------- B ----------

func _t_len_multiply() -> void:
	var m = _fresh()
	var seq := []
	for i in 2:
		m._apply_item("paddle_len_1")
		seq.append(m._paddle_len())
	_eq(seq, [102, 122], "85 -> 102 -> 122 (same item multiplies again)")
	m._apply_item("paddle_len_down_2")
	_eq(m._paddle_len(), roundi(85 * 1.2 * 1.2 * 0.4), "mixed: 85 x 1.2 x 1.2 x 0.4")
	m.free()
	var m2 = _fresh()
	m2._apply_item("paddle_len_min")
	_eq(m2._paddle_len(), 32, "min = 32")
	m2._apply_item("paddle_len_1")
	_eq(m2._paddle_len(), 38, "min then small up: 32 x 1.2 = 38.4 -> 38")
	_eq(m2._hud_len_cell()[0], "d34_hud_icon_paddle_len_down1", "min then up: still '-'")
	for i in 3:
		m2._apply_item("paddle_len_2")
	_ok(m2._paddle_len() > 85, "min then many ups: %d > 85" % m2._paddle_len())
	_eq(m2._hud_len_cell()[0], "d34_hud_icon_paddle_len_down1", "min active, length > 85: still '-'")
	m2.free()


func _t_len_timer_reset() -> void:
	var m = _fresh()
	m._apply_item("paddle_len_1")
	m.effects.tick(12.0)
	_near(m.effects.remaining(Effects.PADDLE_LEN), 18.0, "18 s left")
	m._apply_item("paddle_len_down_1")
	_eq([m.effects.remaining(Effects.PADDLE_LEN), m.effects.total(Effects.PADDLE_LEN)], [30.0, 30.0], "next length item resets to 30 (not 48)")
	m._apply_item("paddle_len_1")
	_eq(m.effects.remaining(Effects.PADDLE_LEN), 30.0, "same item again: reset to 30, no accumulation")
	# 長度計時不影響其他限時效果
	m._apply_item("pierce")
	m.effects.tick(5.0)
	m._apply_item("paddle_len_2")
	_near(m.effects.remaining("pierce"), 15.0, "pierce unaffected by length reset")
	m.free()


## 上下限:撞到 32/320 後再乘。實作是「倍率不夾、只夾結果」,記錄撞限後再撿反向道具的行為
func _t_len_clamp() -> void:
	var m = _fresh()
	for i in 4:
		m._apply_item("paddle_len_2")
	_eq(m._paddle_len(), 320, "4 x big up -> 320 (clamped)")
	m._apply_item("paddle_len_2")
	_eq(m._paddle_len(), 320, "at 320, one more up stays 320")
	m._apply_item("paddle_len_down_1")
	var after_down: int = m._paddle_len()
	print("INFO at max (factor %.3f): small down -> %d (if factor were clamped first: %d)" % [m.effects.paddle_factor, after_down, roundi(320 * 0.8)])
	_ok(after_down >= 32 and after_down <= 320, "still within 32..320 (%d)" % after_down)
	m.free()
	var m2 = _fresh()
	m2._apply_item("paddle_len_min")
	m2._apply_item("paddle_len_down_2")
	_eq(m2._paddle_len(), 32, "min x big down -> 32 (clamped)")
	m2._apply_item("paddle_len_1")
	var after_up: int = m2._paddle_len()
	print("INFO at min (factor %.4f): small up -> %d (if factor were clamped first: %d)" % [m2.effects.paddle_factor, after_up, roundi(32 * 1.2)])
	_ok(after_up >= 32 and after_up <= 320, "still within 32..320 (%d)" % after_up)
	_eq(m2._hud_len_cell()[0], "d34_hud_icon_paddle_len_down1", "at min after up: '-'")
	m2.free()


func _t_len_expire_all() -> void:
	var m = _fresh()
	for id in LEN_IDS:
		m._apply_item(id)
	m._apply_item("paddle_len_2")
	_tick(m, 29.75)
	_ok(m.effects.is_active(Effects.PADDLE_LEN), "still active at 29.75")
	_eq(_tick(m, 0.25), [Effects.PADDLE_LEN], "all length effects end together at 30 s")
	_eq([m._paddle_len(), m.effects.paddle_factor, m.effects.paddle_min, m._hud_len_cell()], [85, 1.0, false, []], "back to 85, flags cleared, no cell")
	# 到期後重新撿:從 85 重新開始乘
	m._apply_item("paddle_len_1")
	_eq(m._paddle_len(), 102, "after expiry new pickup starts from 85 -> 102")
	_eq(m._hud_len_cell()[0], "d34_hud_icon_paddle_len_up1", "after expiry: min flag gone, '+'")
	m.free()


func _t_len_max_removed() -> void:
	_ok(not ItemDefs.exists("paddle_len_max"), "paddle_len_max not an item")
	for buff in [true, false]:
		for replay in [true, false]:
			_ok(not ItemDefs.drop_pool(buff, replay).has("paddle_len_max"), "not in drop pool buff=%s replay=%s" % [buff, replay])
			_ok(not ItemDefs.choice_pool(buff, replay).has("paddle_len_max"), "not in 3-choose-1 pool golden=%s replay=%s" % [buff, replay])
	for f in [1, 2]:
		var p := "res://art/items40/d32_item_paddle_len_max_f%d.png" % f
		_ok(not FileAccess.file_exists(p), "art removed (user cleanup 2026-10-28): %s" % p)
		_ok(not FileAccess.file_exists(p + ".import"), ".import removed: %s" % p)
	# debug_force_item 指定已移除的 id:不當機、退回正常掉落
	cfg.debug_force_item = "paddle_len_max"
	var m = _fresh()
	cfg.drop_chance = 1.0
	for i in 200:
		m._roll_drop(Vector2(20, 68))
	_ok(not m.items.any(func(it) -> bool: return it["id"] == "paddle_len_max"), "debug_force_item=paddle_len_max never drops it")
	cfg.drop_chance = 0.0
	cfg.debug_force_item = ""
	m.free()


# ---------- C ----------

func _t_text() -> void:
	var expect := {
		"paddle_len_1": "持續30秒", "paddle_len_2": "持續30秒", "pierce": "持續20秒", "flame": "持續20秒",
		"sticky": "持續30秒", "gun": "持續10秒", "paddle_len_down_1": "持續30秒", "paddle_len_down_2": "持續30秒",
		"heal": "持續10秒", "heal_area": "持續10秒", "blackhole": "持續5秒", "invisible": "持續10秒",
	}
	for id in expect:
		_eq(ItemDefs.desc_lines(id)[-1], expect[id], "%s last line" % id)
	_eq(ItemDefs.desc_lines("bomb")[1], "10秒後全部爆炸", "bomb")
	_eq(ItemDefs.desc_lines("invincible")[1], "魔王除外，持續10秒", "invincible")
	_eq(ItemDefs.desc_lines("paddle_len_min"), ["縮到最短，持續30秒"], "paddle_len_min")
	for id in WHOLE_GAME:
		_ok(not "|".join(ItemDefs.desc_lines(id)).contains("持續"), "whole-game %s has no duration text" % id)
	# 寬度:D29 估算規則(全形 22、半形 12)每行 ≤ 216、最多 3 行
	var over := []
	for id in ItemDefs.TEXT:
		var lines := ItemDefs.desc_lines(id)
		if lines.size() > 3:
			over.append("%s %d lines" % [id, lines.size()])
		for l in [ItemDefs.item_name(id)] + lines:
			var w := 0
			for i in (l as String).length():
				w += 12 if (l as String).unicode_at(i) < 0x2E80 else 22
			if w > 216:
				over.append("%s %d" % [l, w])
	_eq(over, [], "estimated widths <= 216 and <= 3 lines")
	# 秒數跟設定檔(含小數)
	var old: float = cfg.dur_gun
	cfg.dur_gun = 12.5
	_eq(ItemDefs.desc_lines("gun")[2], "持續12.5秒", "gun text follows dur_gun = 12.5")
	var m = _fresh()
	m._apply_item("gun")
	_eq(m.effects.remaining("gun"), 12.5, "gun timer follows dur_gun = 12.5")
	m.free()
	cfg.dur_gun = old


# ---------- D ----------

func _t_hud_column1() -> void:
	var m = _fresh()
	_eq(m._hud_cells(), [], "nothing active: no cells")
	m._apply_item("bomb")
	m._apply_item("pierce")
	m.effects.ball_tier = 1
	m._apply_item("flame")
	m.effects.reinforce = 3
	var ids: Array = m._hud_cells().map(func(c: Array) -> String: return c[0])
	_eq(ids, ["d34_hud_icon_reinforce", "d34_hud_icon_fast", "d34_hud_icon_pierce", "d34_hud_icon_flame", "d34_hud_icon_bomb"], "D35 R10: all new in the same frame -> fixed order reinforce, (fever), fast, pierce, flame, bomb")
	var cells: Array = m._hud_cells()
	_ok(cells[0][1].has("segments") and cells[1][1].has("segments"), "reinforce / fast = segmented bars")
	_ok(cells[2][1].has("fill") and cells[3][1].has("fill") and cells[4][1].has("fill"), "pierce / flame / bomb = time bars")
	_eq(cells[1][1], {"segments": cfg.ball_tier_max, "filled": 1}, "fast segments")
	# 補位:穿透到期 → 火焰、炸彈往上補
	m.effects.timed.erase("pierce")
	ids = m._hud_cells().map(func(c: Array) -> String: return c[0])
	_eq(ids, ["d34_hud_icon_reinforce", "d34_hud_icon_fast", "d34_hud_icon_flame", "d34_hud_icon_bomb"], "D35 R2: gap filled after pierce ends")
	# 時間條:剩餘 ÷ 各自總時間
	m.effects.tick(10.0)
	_eq(m._hud_cells()[2][1]["fill"], 10, "flame 10/20 -> 10 cols")
	_eq(m._hud_cells().size(), 3, "bomb (10 s) gone at 10 s")
	# 版面常數
	_eq([MainScript.HUD_X, MainScript.HUD_Y, MainScript.HUD_STEP, cfg.hud_alpha], [24, 424, 52, 0.5], "x 24, y 424, step 52, 50%")
	# fever 尚未實作,圖示已刪除,不檢查
	for id in ["reinforce", "slow", "fast", "pierce", "flame", "bomb"]:
		var tex: Texture2D = load("res://art/hud32/d34_hud_icon_%s.png" % id)
		_eq(tex.get_size() if tex else Vector2.ZERO, Vector2(32, 32), "hud32 %s is 32x32" % id)
	m.free()


# ---------- E ----------

func _t_hud_len_cell() -> void:
	var m = _fresh()
	m._apply_item("paddle_len_down_1")
	_eq(m._hud_len_cell(), ["d34_hud_icon_paddle_len_down1", {"fill": 20, "color": Pal.W}], "68 < 85: '-' full bar")
	# 時間條 = ceil(20 × 剩餘 / 30)
	for pair in [[29.0, 20], [15.0, 10], [1.4, 1], [0.0001, 1]]:
		m.effects.timed[Effects.PADDLE_LEN]["remaining"] = pair[0]
		_eq(m._hud_len_cell()[1]["fill"], pair[1], "remaining %.4f -> fill %d" % pair)
	# 最後 1 秒閃爍(每 100 ms 切換)
	var colors := []
	for r in [1.05, 0.95, 0.85, 0.75, 0.15, 0.05]:
		m.effects.timed[Effects.PADDLE_LEN]["remaining"] = r
		colors.append(m._hud_len_cell()[1]["color"])
	_eq(colors, [Pal.W, Pal.G, Pal.W, Pal.G, Pal.G, Pal.W], "blink only in last second, alternating every 100 ms")
	m.reduced_motion = true
	m.effects.timed[Effects.PADDLE_LEN]["remaining"] = 0.95
	_eq(m._hud_len_cell()[1]["color"], Pal.W, "reduced motion: no blink")
	m.free()
	# _process 更新 hud(D35 長度格併入同一排;真實流程):撿到 → 格子出現;到期幀 → 消失
	var m2 = _fresh()
	_ball(m2, Vector2(180, 200), Vector2(0.6, -0.8).normalized())
	m2._pickup("paddle_len_2", Vector2(100, 600))
	m2._process(FPS)
	_eq(m2.hud.map(func(c: Array) -> String: return c[0]), ["d34_hud_icon_paddle_len_up1"], "_process: '+' cell shown in the single list")
	m2.effects.timed[Effects.PADDLE_LEN]["remaining"] = FPS
	m2._process(FPS)
	_eq([m2.hud, m2.hud_order, m2._paddle_len()], [[], [], 85], "_process on expiry frame: cell gone, 85")
	m2.free()


## 光暈(D35):清單中有任何一格不是擋板長度才亮;只有長度格 → 不亮
func _t_halo_rule() -> void:
	var m = _fresh()
	_ball(m, Vector2(180, 200), Vector2.UP)
	m._apply_item("paddle_len_1")
	m._process(0.0)
	_eq([m.hud.size(), m._halo_on()], [1, false], "only length cell -> halo off")
	m._apply_item("pierce")
	m._process(0.0)
	_eq([m.hud_order, m._halo_on()], [[Effects.PADDLE_LEN, "pierce"], true], "length + pierce -> halo on, pierce after length")
	m.effects.timed.erase("pierce")
	m._process(0.0)
	_eq([m.hud.size(), m._halo_on()], [1, false], "pierce gone: halo off again")
	m.free()


## 擋板貼右牆時長度效果到期(32 → 85):同一幀之後畫出來的擋板不能超出牆
func _t_expiry_paddle_edge() -> void:
	var m = _fresh()
	_ball(m, Vector2(100, 200), Vector2(0.6, -0.8).normalized())
	m._apply_item("paddle_len_min")
	m.target_x = 400.0
	for i in 60:
		m._step(FPS)
	_eq(m._paddle_left(32) + 32, 340, "short paddle at right wall")
	m.effects.timed[Effects.PADDLE_LEN]["remaining"] = FPS * 0.5
	m._step(FPS)   # 到期幀
	var len: int = m._paddle_len()
	var right: int = m._paddle_left(len) + len
	print("INFO expiry frame at right wall: length %d, paddle_x %.1f, right end %d (wall 340)" % [len, m.paddle_x, right])
	_ok(right <= 340, "paddle drawn inside wall on the expiry frame (right end %d)" % right)
	m._step(FPS)
	_eq(m._paddle_left(85) + 85, 340, "next frame: clamped to wall")
	m.free()
