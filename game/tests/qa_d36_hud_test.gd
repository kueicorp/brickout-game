## QA 驗收(2026-10-28 D36 其他道具 HUD):8 種新狀態的存在條件、圖示、線段條、擋板移動速度分階、
## 同幀順序(R10)、獲得順序(D35)、光暈例外(Q3)、再次獲得累積(R3)、黑洞最後 1 秒閃爍(Q8)、14 格版面。
## 執行:Godot --headless --path game --script res://tests/qa_d36_hud_test.gd
## 全部通過時結束碼 0,有失敗時結束碼 1。
extends SceneTree

const MainScene := preload("res://scenes/main.tscn")
const MainScript := preload("res://scripts/main.gd")
const FPS := 1.0 / 60.0
## 固定測試關卡(無魔王):不依賴 game_config.tres 目前的 level_path(魔王關進場有 1.6 秒 BOSS 警告)
const LEVEL := "res://data/levels/level_func_test.json"
## D36 第二節:7 種限時(id = HUD 種類 = 道具 id)與規格秒數
const TIMED := {"sticky": 30.0, "gun": 10.0, "heal": 10.0, "heal_area": 10.0, "blackhole": 5.0,
	"invincible": 10.0, "invisible": 10.0}
## D36 第六節 R10 固定順序(獨立於實作抄寫)
const FIXED := ["reinforce", "fever", "speed", "pierce", "flame", "bomb", "paddle_len",
	"paddle_speed", "sticky", "gun", "heal", "heal_area", "blackhole", "invincible", "invisible"]
const HALO := ["reinforce", "speed", "pierce", "flame", "bomb"]
const NEW_ICONS := ["sticky", "gun", "invincible", "paddle_speed_up", "paddle_speed_down", "heal", "heal_area",
	"blackhole", "invisible"]
const OLD_ICONS := ["paddle_len_up1", "paddle_len_down1", "slow", "fast", "reinforce", "pierce", "flame", "bomb"]
## 14 種各一個道具(反序撿,測同幀順序)
const ALL14 := ["invisible", "invincible", "blackhole", "heal_area", "heal", "gun", "sticky", "paddle_speed",
	"paddle_len_1", "bomb", "flame", "pierce", "fast", "reinforce"]
const FUZZ_POOL := ["slow", "fast", "reinforce", "pierce", "flame", "bomb", "paddle_len_1", "paddle_len_down_1",
	"paddle_len_min", "paddle_speed", "paddle_speed_down", "sticky", "gun", "heal", "heal_area", "blackhole",
	"invincible", "invisible"]

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
	_run("icons_files", _t_icons)
	_run("config_durations", _t_config)
	_run("timed_presence_icon_bar", _t_timed)
	_run("timed_bar_progress", _t_timed_progress)
	_run("timed_reacquire_accumulate", _t_reacquire)
	_run("blackhole_blink_last_second", _t_blackhole_blink)
	_run("blink_all_timed_and_reduced_motion", _t_blink_all)
	_run("paddle_speed_steps", _t_paddle_speed)
	_run("paddle_speed_cross_zero", _t_paddle_cross)
	_run("paddle_speed_zero_removed_fill", _t_paddle_zero)
	_run("paddle_speed_same_frame_two", _t_paddle_same_frame)
	_run("r10_same_frame_all14", _t_r10_all)
	_run("r10_same_frame_mixed", _t_r10_mixed)
	_run("acquisition_order", _t_acq)
	_run("halo_exceptions", _t_halo)
	_run("layout_14", _t_layout14)
	_run("menu_pick_new_kind", _t_menu)
	_run("fuzz_vs_reference", _t_fuzz)
	print("QA D36 HUD RESULT: %d passed, %d failed" % [_passed, _failed])
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
	m.rng.seed = 4242
	m.view_h = h
	for r in MainScript.MAX_ROWS:
		for c in MainScript.COLS:
			m.grid[r][c] = null
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
	var b = MainScript.Ball.new()
	b.stuck = true
	b.pos = Vector2(180, m._paddle_y() - 8)
	m.balls.append(b)
	return m


func _frame(m, dt := 0.0) -> void:
	m._process(dt)


func _drop(m, id: String) -> void:
	m.items.append({"id": id, "pos": Vector2(m.paddle_x - 8, m._paddle_y() - 20)})


func _kinds(m) -> Array:
	return m.hud_order.map(func(k): return k)


func _icons(m) -> Array:
	return m.hud.map(func(c: Array) -> String: return c[0])


func _cell(m, kind: String) -> Array:
	var i: int = m.hud_order.find(kind)
	return m.hud[i] if i >= 0 else []


func _fill(rem: float, total: float) -> int:
	if rem <= 0.0:
		return 0
	return clampi(ceili(20.0 * rem / total), 0, 20)


func _img(id: String) -> Image:
	var t := load("res://art/hud32/d34_hud_icon_%s.png" % id) as Texture2D
	if t == null:
		return null
	var i := t.get_image()
	if i.is_compressed():
		i.decompress()
	i.convert(Image.FORMAT_RGBA8)
	return i


# ---------- 圖檔 ----------

func _t_icons() -> void:
	var imgs := {}
	for id in NEW_ICONS + OLD_ICONS:
		var i := _img(id)
		_ok(i != null, "icon %s loads" % id)
		if i == null:
			continue
		_eq(i.get_size(), Vector2i(32, 32), "icon %s is 32x32" % id)
		imgs[id] = i
	# 17 張彼此不同(沒有錯圖、重複圖)
	var dup := []
	var keys := imgs.keys()
	for a in keys.size():
		for b in range(a + 1, keys.size()):
			if imgs[keys[a]].get_data() == imgs[keys[b]].get_data():
				dup.append("%s == %s" % [keys[a], keys[b]])
	_eq(dup, [], "all 17 HUD icons are distinct")
	# 擋板速度 + / − 同一造型,只差右上角:不同像素都在右上 1/4(x ≥ 16、y < 16)
	if imgs.has("paddle_speed_up") and imgs.has("paddle_speed_down"):
		var outside := 0
		var diff := 0
		for y in 32:
			for x in 32:
				if imgs["paddle_speed_up"].get_pixel(x, y) != imgs["paddle_speed_down"].get_pixel(x, y):
					diff += 1
					if x < 16 or y >= 16:
						outside += 1
		_ok(diff > 0, "paddle_speed up/down differ (%d px)" % diff)
		_eq(outside, 0, "paddle_speed up/down differ only in top-right quadrant")


func _t_config() -> void:
	for id in TIMED:
		_eq(cfg.get("dur_" + id), TIMED[id], "dur_%s" % id)
	_eq([cfg.paddle_tier_min, cfg.paddle_tier_max], [-3, 4], "paddle tier range -3..+4")


# ---------- 7 種限時 ----------

func _t_timed() -> void:
	for id in TIMED:
		var m = _fresh()
		_frame(m)
		_eq(_kinds(m), [], "%s: empty before pickup" % id)
		_drop(m, id)
		_frame(m, FPS)
		_eq(_kinds(m), [id], "%s: present after real pickup" % id)
		_eq(_icons(m), ["d34_hud_icon_" + id], "%s: icon" % id)
		var c := _cell(m, id)
		_eq(c[1] if c.size() > 1 else null, {"fill": 20, "color": Pal.W}, "%s: full white time bar" % id)
		_eq(m.effects.total(id), TIMED[id], "%s: total = dur_%s" % [id, id])
		_ok(not c[1].has("segments") if c.size() > 1 else false, "%s: time bar, not segments" % id)
		# 到期 → 移除
		m.effects.timed[id]["remaining"] = FPS * 0.5
		_frame(m, FPS)
		_eq([_kinds(m), m.hud], [[], []], "%s: expired -> removed" % id)
		m.free()


func _t_timed_progress() -> void:
	for id in TIMED:
		var m = _fresh()
		m._apply_item(id)
		_frame(m)
		var bad := []
		var total: float = TIMED[id]
		# 每 0.25 秒取樣到剩 1 秒前(避開閃爍區)
		var t := 0.0
		while t < total - 1.1:
			m.effects.tick(0.25)
			t += 0.25
			_frame(m)
			var rem: float = m.effects.remaining(id)
			var c := _cell(m, id)
			if c.is_empty() or c[1].get("fill", -1) != _fill(rem, total) or c[1].get("color") != Pal.W:
				bad.append("t %.2f rem %.2f cell %s" % [t, rem, c])
		_eq(bad, [], "%s: fill = ceil(20 x rem / %.0f)" % [id, total])
		m.free()


func _t_reacquire() -> void:
	for id in TIMED:
		var m = _fresh()
		m._apply_item("reinforce")
		_frame(m)
		m._apply_item(id)
		_frame(m)
		m._apply_item("bomb")
		_frame(m)
		# 2 秒:炸彈(10 秒)不會先到期
		m.effects.tick(2.0)
		_frame(m)
		var rem_before: float = m.effects.remaining(id)
		_drop(m, id)
		_frame(m, FPS)
		_eq(_kinds(m), ["reinforce", id, "bomb"], "%s again: position unchanged" % id)
		var rem: float = m.effects.remaining(id)
		_ok(absf(rem - (rem_before + TIMED[id] - FPS)) < 0.02, "%s again: time accumulated (%.3f -> %.3f)" % [id, rem_before, rem])
		_ok(absf(m.effects.total(id) - rem) < 0.02, "%s again: total = accumulated remaining" % id)
		_eq(_cell(m, id)[1].get("fill"), 20, "%s again: bar back to full" % id)
		m.free()


func _t_blackhole_blink() -> void:
	var m = _fresh()
	m._apply_item("blackhole")
	_frame(m)
	var colors := {}
	var blink_outside := []
	var g_count := 0
	var w_count := 0
	# 真實幀推進 5 秒
	for f in 310:
		_frame(m, FPS)
		if not m.effects.is_active("blackhole"):
			break
		var rem: float = m.effects.remaining("blackhole")
		var c := _cell(m, "blackhole")
		if c.is_empty():
			blink_outside.append("missing at rem %.3f" % rem)
			continue
		var col: Color = c[1]["color"]
		var want: Color = Pal.G if rem <= 1.0 and int(rem * 10.0) % 2 == 1 else Pal.W
		if col != want:
			blink_outside.append("rem %.3f color %s" % [rem, col])
		if rem <= 1.0:
			if col == Pal.G:
				g_count += 1
			else:
				w_count += 1
		elif col != Pal.W:
			blink_outside.append("blink before last second rem %.3f" % rem)
	_eq(blink_outside, [], "blackhole: W until last second, then W/G every 100 ms")
	_ok(g_count > 20 and w_count > 20, "blackhole: last second both G (%d) and W (%d) frames" % [g_count, w_count])
	_eq(_kinds(m), [], "blackhole: removed after 5 s")
	m.free()


func _t_blink_all() -> void:
	for id in TIMED:
		var m = _fresh()
		m._apply_item(id)
		_frame(m)
		m.effects.timed[id]["remaining"] = 0.95
		_frame(m)
		_eq(_cell(m, id)[1].get("color"), Pal.G, "%s: rem 0.95 -> G" % id)
		m.effects.timed[id]["remaining"] = 0.85
		_frame(m)
		_eq(_cell(m, id)[1].get("color"), Pal.W, "%s: rem 0.85 -> W" % id)
		m.effects.timed[id]["remaining"] = 1.15
		_frame(m)
		_eq(_cell(m, id)[1].get("color"), Pal.W, "%s: rem 1.15 -> W (not last second)" % id)
		m.reduced_motion = true
		m.effects.timed[id]["remaining"] = 0.95
		_frame(m)
		_eq(_cell(m, id)[1].get("color"), Pal.W, "%s: reduced motion -> no blink" % id)
		m.free()


# ---------- 擋板移動速度 ----------

func _t_paddle_speed() -> void:
	var m = _fresh()
	for n in range(1, 6):
		_drop(m, "paddle_speed")
		_frame(m, FPS)
		var k := mini(n, 4)
		_eq(_icons(m), ["d34_hud_icon_paddle_speed_up"], "up x%d: one '+' cell" % n)
		_eq(m.hud[0][1], {"segments": 4, "filled": k}, "up x%d: 4 segments, %d filled" % [n, k])
	m.free()
	var m2 = _fresh()
	for n in range(1, 5):
		_drop(m2, "paddle_speed_down")
		_frame(m2, FPS)
		var k := mini(n, 3)
		_eq(_icons(m2), ["d34_hud_icon_paddle_speed_down"], "down x%d: one '-' cell" % n)
		_eq(m2.hud[0][1], {"segments": 3, "filled": k}, "down x%d: 3 segments, %d filled" % [n, k])
	# 不倒數、不閃爍:經過很久仍相同
	for i in 120:
		_frame(m2, 0.5)
	_eq(m2.hud, [["d34_hud_icon_paddle_speed_down", {"segments": 3, "filled": 3}]], "down: whole game, no countdown after 60 s")
	m2.free()


func _t_paddle_cross() -> void:
	var m = _fresh()
	m._apply_item("flame")
	_frame(m)
	m._apply_item("paddle_speed_down")
	m._apply_item("paddle_speed_down")
	_frame(m)
	m._apply_item("gun")
	_frame(m)
	_eq(_kinds(m), ["flame", "paddle_speed", "gun"], "setup: -2 in position 2")
	m.effects.paddle_tier = 1
	_frame(m)
	_eq(_kinds(m), ["flame", "paddle_speed", "gun"], "-2 -> +1 in one step: position unchanged")
	_eq(m.hud[1], ["d34_hud_icon_paddle_speed_up", {"segments": 4, "filled": 1}], "-2 -> +1: icon '+' and 4-seg bar")
	m.effects.paddle_tier = -3
	_frame(m)
	_eq(_kinds(m), ["flame", "paddle_speed", "gun"], "+1 -> -3 in one step: position unchanged")
	_eq(m.hud[1], ["d34_hud_icon_paddle_speed_down", {"segments": 3, "filled": 3}], "+1 -> -3: icon '-' and 3-seg bar")
	m.free()


func _t_paddle_zero() -> void:
	var m = _fresh(707)
	for id in ["paddle_speed", "sticky", "invisible", "reinforce", "heal"]:
		m._apply_item(id)
		_frame(m, FPS)
	_eq(_kinds(m), ["paddle_speed", "sticky", "invisible", "reinforce", "heal"], "setup acquisition order")
	_eq(m._hud_slot(4), Vector2(76, 424), "707: 5th cell in column 2")
	_drop(m, "paddle_speed_down")
	_frame(m, FPS)
	_eq(m.effects.paddle_tier, 0, "+1 then down -> 0")
	_eq(_icons(m), ["d34_hud_icon_sticky", "d34_hud_icon_invisible", "d34_hud_icon_reinforce", "d34_hud_icon_heal"],
		"paddle speed 0 -> removed, rest move up (heal jumps to column 1)")
	_drop(m, "paddle_speed_down")
	_frame(m, FPS)
	_eq(_kinds(m), ["sticky", "invisible", "reinforce", "heal", "paddle_speed"], "0 -> -1: new cell, last")
	_eq(_icons(m)[4], "d34_hud_icon_paddle_speed_down", "0 -> -1: '-' icon")
	m.free()


func _t_paddle_same_frame() -> void:
	# 同一幀 +1 → 0 → -1(兩個減速同時接到):幀末仍存在 → 依 D35 R11 精神視為一直存在
	var m = _fresh()
	m._apply_item("paddle_speed")
	_frame(m)
	m._apply_item("gun")
	_frame(m)
	_drop(m, "paddle_speed_down")
	_drop(m, "paddle_speed_down")
	_frame(m, FPS)
	_eq(m.effects.paddle_tier, -1, "two downs in one frame -> -1")
	print("INFO same-frame +1 -> 0 -> -1 paddle speed: list %s" % [_kinds(m)])
	m.free()


# ---------- R10 / 獲得順序 ----------

func _t_r10_all() -> void:
	var m = _fresh()
	for id in ALL14:
		m._apply_item(id)
	_frame(m)
	var want := FIXED.filter(func(k): return k != "fever")
	_eq(_kinds(m), want, "14 kinds in one frame (reverse pickup) -> fixed order")
	_eq(m.hud.size(), 14, "14 cells")
	var want_icons := ["reinforce", "fast", "pierce", "flame", "bomb", "paddle_len_up1", "paddle_speed_up", "sticky",
		"gun", "heal", "heal_area", "blackhole", "invincible", "invisible"].map(func(s): return "d34_hud_icon_" + s)
	_eq(_icons(m), want_icons, "14 cells icons")
	m.free()
	# 真實掉落:同一幀接到 8 個新種類
	var m2 = _fresh()
	for id in ["invisible", "invincible", "blackhole", "heal_area", "heal", "gun", "sticky", "paddle_speed_down"]:
		_drop(m2, id)
	_frame(m2, FPS)
	_eq(m2.items.size(), 0, "8 items caught in one frame")
	_eq(_kinds(m2), ["paddle_speed", "sticky", "gun", "heal", "heal_area", "blackhole", "invincible", "invisible"],
		"8 new kinds caught same frame -> fixed order")
	m2.free()


func _t_r10_mixed() -> void:
	var m = _fresh()
	m._apply_item("invisible")
	_frame(m)
	m._apply_item("bomb")
	_frame(m)
	for id in ["heal", "reinforce", "gun", "paddle_len_down_1", "sticky"]:
		_drop(m, id)
	_frame(m, FPS)
	_eq(_kinds(m), ["invisible", "bomb", "reinforce", "paddle_len", "sticky", "gun", "heal"],
		"existing kept; new same-frame appended in fixed order")
	# 同一幀:隱形到期 + 新出現兩種
	m.effects.timed["invisible"]["remaining"] = FPS * 0.5
	_drop(m, "invincible")
	_drop(m, "paddle_speed")
	_frame(m, FPS)
	_eq(_kinds(m), ["bomb", "reinforce", "paddle_len", "sticky", "gun", "heal", "paddle_speed", "invincible"],
		"remove first then append new in fixed order")
	m.free()


func _t_acq() -> void:
	var m = _fresh()
	var seq := ["invisible", "heal", "reinforce", "blackhole", "paddle_speed_down", "sticky", "flame", "gun",
		"invincible", "heal_area", "slow", "paddle_len_2", "pierce", "bomb"]
	var want := ["invisible", "heal", "reinforce", "blackhole", "paddle_speed", "sticky", "flame", "gun",
		"invincible", "heal_area", "speed", "paddle_len", "pierce", "bomb"]
	for id in seq:
		m._apply_item(id)
		_frame(m, FPS)
	_eq(_kinds(m), want, "14 kinds in acquisition order (not fixed order)")
	# 中間的黑洞到期 → 後面往上補
	m.effects.timed["blackhole"]["remaining"] = FPS * 0.5
	_frame(m, FPS)
	want.erase("blackhole")
	_eq(_kinds(m), want, "blackhole expires -> removed, rest move up")
	m._apply_item("blackhole")
	_frame(m)
	want.append("blackhole")
	_eq(_kinds(m), want, "blackhole again -> last")
	m.free()


# ---------- 光暈 ----------

func _t_halo() -> void:
	var cases := [
		[["paddle_speed"], false, "paddle speed +"],
		[["paddle_speed_down"], false, "paddle speed -"],
		[["sticky"], false, "sticky"],
		[["gun"], false, "gun"],
		[["heal"], false, "heal"],
		[["heal_area"], false, "heal_area"],
		[["blackhole"], false, "blackhole"],
		[["invincible"], false, "invincible"],
		[["invisible"], false, "invisible"],
		[["paddle_len_1", "paddle_speed", "sticky", "gun", "heal", "heal_area", "blackhole", "invincible", "invisible"], false, "length + all 8 new"],
		[["sticky", "gun", "reinforce"], true, "new + reinforce"],
		[["invisible", "slow"], true, "new + slow"],
		[["invisible", "fast"], true, "new + fast"],
		[["heal", "pierce"], true, "new + pierce"],
		[["heal_area", "flame"], true, "new + flame"],
		[["blackhole", "bomb"], true, "new + bomb"],
	]
	for c in cases:
		var m = _fresh()
		for id in c[0]:
			m._apply_item(id)
		_frame(m)
		_eq(m._halo_on(), c[1], "halo: %s" % c[2])
		m.free()
	var m2 = _fresh()
	m2._apply_item("bomb")
	m2._apply_item("gun")
	m2._apply_item("invisible")
	_frame(m2)
	_ok(m2._halo_on(), "bomb + gun + invisible -> halo on")
	m2.effects.timed["bomb"]["remaining"] = FPS * 0.5
	_frame(m2, FPS)
	_eq([_kinds(m2), m2._halo_on()], [["gun", "invisible"], false], "bomb ends, only new kinds left -> halo off")
	m2.free()


# ---------- 14 格版面 ----------

func _t_layout14() -> void:
	var expect := {
		640: [3, [3, 3, 3, 3, 2], 232],
		707: [4, [4, 4, 4, 2], 180],
		800: [6, [6, 6, 2], 128],
	}
	for h in expect:
		var m = _fresh(h)
		for id in ALL14:
			m._apply_item(id)
		_frame(m)
		_eq(m.hud.size(), 14, "H %d: 14 cells" % h)
		var cols := {}
		var bad := []
		for i in 14:
			var s: Vector2 = m._hud_slot(i)
			@warning_ignore("integer_division")
			var want := Vector2(24 + 52 * (i / expect[h][0]), 424 + 52 * (i % expect[h][0]))
			if s != want:
				bad.append("slot %d %s want %s" % [i, s, want])
			cols[int(s.x)] = cols.get(int(s.x), 0) + 1
			if s.y + 44 > h - 45 - 12:
				bad.append("slot %d bottom %d too close to paddle" % [i, s.y + 44])
		_eq(bad, [], "H %d: 14 slots follow D35 formula" % h)
		var xs := cols.keys()
		xs.sort()
		_eq(xs.map(func(x): return cols[x]), expect[h][1], "H %d: cells per column" % h)
		_eq(xs.back(), expect[h][2], "H %d: rightmost column x" % h)
		m.free()


# ---------- 金球選單 ----------

func _t_menu() -> void:
	var m = _fresh()
	m._apply_item("flame")
	_frame(m)
	var menu := ChoiceMenu.new()
	menu.setup(true, ["sticky", "gun", "paddle_speed"], 800, true)
	menu.picked.connect(m._on_menu_picked)
	menu.closed.connect(func() -> void: m.menu = null)
	m.menu = menu
	m.add_child(menu)
	menu._process(0.6)
	menu._on_pressed(2)
	_frame(m)
	_eq(_kinds(m), ["flame", "paddle_speed"], "menu pick paddle_speed (paused) -> appended")
	_eq(m.hud[1], ["d34_hud_icon_paddle_speed_up", {"segments": 4, "filled": 1}], "menu pick: '+' cell")
	menu._process(2.0)
	_frame(m, FPS)
	m.free()


# ---------- 隨機長序列 vs 規格參考模型 ----------

func _ref_present(m) -> Dictionary:
	var e: Effects = m.effects
	var out := {}
	if e.reinforce >= 1:
		out["reinforce"] = ["d34_hud_icon_reinforce", {"segments": cfg.reinforce_max, "filled": e.reinforce}]
	if e.ball_tier != 0:
		out["speed"] = ["d34_hud_icon_slow" if e.ball_tier < 0 else "d34_hud_icon_fast", null]
	for k in ["pierce", "flame", "bomb"]:
		if e.is_active(k):
			out[k] = ["d34_hud_icon_" + k, null]
	var len: int = m._paddle_len()
	if e.is_active("paddle_len") and len != 85:
		out["paddle_len"] = ["d34_hud_icon_paddle_len_down1" if e.paddle_min or len < 85 else "d34_hud_icon_paddle_len_up1", null]
	if e.paddle_tier > 0:
		out["paddle_speed"] = ["d34_hud_icon_paddle_speed_up", {"segments": 4, "filled": e.paddle_tier}]
	elif e.paddle_tier < 0:
		out["paddle_speed"] = ["d34_hud_icon_paddle_speed_down", {"segments": 3, "filled": -e.paddle_tier}]
	for k in TIMED:
		if e.is_active(k):
			var rem := e.remaining(k)
			var blink: bool = not m.reduced_motion and rem <= 1.0 and int(rem * 10.0) % 2 == 1
			out[k] = ["d34_hud_icon_" + k, {"fill": _fill(rem, e.total(k)), "color": Pal.G if blink else Pal.W}]
	return out


func _t_fuzz() -> void:
	var rng := RandomNumberGenerator.new()
	var mismatches := []
	var frames := 0
	var max_cells := 0
	for seed in 40:
		rng.seed = 5000 + seed
		var m = _fresh([800, 707, 640][seed % 3])
		var ref := []
		for f in 600:
			if rng.randf() < 0.3:
				for i in rng.randi_range(1, 4):
					_drop(m, FUZZ_POOL[rng.randi_range(0, FUZZ_POOL.size() - 1)])
			if rng.randf() < 0.05 and not m.effects.timed.is_empty():
				var keys: Array = m.effects.timed.keys()
				m.effects.timed[keys[rng.randi_range(0, keys.size() - 1)]]["remaining"] = FPS * 0.5
			_frame(m, FPS)
			frames += 1
			var present := _ref_present(m)
			ref = ref.filter(func(k) -> bool: return present.has(k))
			for k in FIXED:
				if present.has(k) and k not in ref:
					ref.append(k)
			max_cells = maxi(max_cells, ref.size())
			var ok: bool = _kinds(m) == ref
			if ok:
				for i in ref.size():
					var want: Array = present[ref[i]]
					if m.hud[i][0] != want[0] or (want[1] != null and m.hud[i][1] != want[1]):
						ok = false
						break
			var halo_want := ref.any(func(k) -> bool: return k in HALO)
			if m._halo_on() != halo_want:
				ok = false
			if not ok and mismatches.size() < 5:
				mismatches.append("seed %d frame %d: want %s got %s / hud %s halo %s" % [seed, f, ref, _kinds(m), m.hud, m._halo_on()])
			if m.state != 0:
				break
		m.free()
	print("INFO fuzz frames %d, max cells seen %d" % [frames, max_cells])
	_eq(mismatches, [], "random sequences: list / icons / bars / halo match D36 reference model")
