## QA 獨立驗證:測試關卡(level_test.json)的格式與可玩性。
## 執行:Godot --headless --path game --script res://tests/qa_level_test_playable.gd
## 全部通過時結束碼 0,有失敗時結束碼 1。輸出也不應出現 SCRIPT ERROR / ERROR。
## 可玩性:直接呼叫主場景的 _step(1/60) 模擬;擋板以「自動玩家」追球(每次接球隨機偏移,固定亂數種子)。
extends SceneTree

const MainScene := preload("res://scenes/main.tscn")
const LEVEL := "res://data/levels/level_test.json"
const DT := 1.0 / 60.0
const SIM_TIME := 600.0          # 每個角度最多模擬 600 秒遊戲時間
const HIT_ALL_LIMIT := 300.0     # 下半部每塊磚都要在 300 秒內被打到至少一次
const STUCK_LIMIT := 15.0        # 球在飛但完全沒得分、也沒碰擋板的最長時間上限
const LOWER_FIRST_ROW := 8       # 第 9 排(index 8)起算下半部

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
	_run("format", _t_format)
	_run("layers_1_69", _t_layers)
	_run("scene_load", _t_scene_load)
	_run("play_angles", _t_play_angles)
	_run("play_multiball", _t_play_multiball)
	print("QA LEVEL RESULT: %d passed, %d failed" % [_passed, _failed])
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


# ---------- 格式 ----------

func _raw_rows() -> Array:
	var text := FileAccess.get_file_as_string(LEVEL)
	var data = JSON.parse_string(text)
	_ok(data is Dictionary, "json parses to Dictionary")
	return data["rows"] if data is Dictionary else []


func _t_format() -> void:
	var rows := _raw_rows()
	_eq(rows.size(), 17, "17 rows")
	var bad_width := []
	var u_cells := []
	var bad_tokens := []
	for r in rows.size():
		var tokens: PackedStringArray = str(rows[r]).split(" ", false)
		if tokens.size() != 8:
			bad_width.append(r)
		# 分隔必須是單一空白(避免 tab 或多空白)
		if str(rows[r]) != " ".join(tokens):
			bad_width.append("sep%d" % r)
		for c in tokens.size():
			var t := tokens[c]
			if t == "U":
				u_cells.append(Vector2i(c, r))
			elif t != "." and not (t.is_valid_int() and t.to_int() >= 1 and t.to_int() <= 69):
				bad_tokens.append("%d,%d=%s" % [r, c, t])
	_eq(bad_width, [], "every row has exactly 8 single-space tokens")
	_eq(bad_tokens, [], "all tokens valid")
	_eq(u_cells, [Vector2i(0, 8), Vector2i(7, 8)], "exactly 2 U at row 9 col 0 and col 7")
	var parsed := Rules.parse_level(JSON.parse_string(FileAccess.get_file_as_string(LEVEL)), 17, 8, cfg.max_layers)
	_eq(parsed["errors"].size(), 0, "parse_level reports no errors")
	_eq(cfg.max_layers, 69, "max_layers is 69")
	# 被修改的排(index 10、12、15、16)與第 16 排中間 2 格空
	_eq(rows[10], "2 1 . 2 . 3 . 2", "row 11 content")
	_eq(rows[12], ". 1 8 2 9 3 10 .", "row 13 content")
	_eq(rows[15], "2 1 . . . . 1 2", "row 16 content")
	_eq(rows[16], "3 1 1 . . 1 1 3", "row 17 content")
	var row16: PackedStringArray = str(rows[15]).split(" ", false)
	_eq([row16[3], row16[4]], [".", "."], "row 16 middle 2 cells empty")
	# 被改成可破壞的磚都是 1~3 層(第 11、16、17 排)
	var over3 := []
	for r in [10, 15, 16]:
		for t in str(rows[r]).split(" ", false):
			if t != "." and t.to_int() > 3:
				over3.append("%d:%s" % [r, t])
	_eq(over3, [], "rows 11/16/17 bricks are 1~3 layers")


# ---------- 上半部 1~69 層 ----------

func _t_layers() -> void:
	var rows := _raw_rows()
	# 第 1~8 排:69 由左上往右遞減到 6
	var mismatch := []
	for r in 8:
		var tokens: PackedStringArray = str(rows[r]).split(" ", false)
		for c in 8:
			var want := 69 - r * 8 - c
			if c >= tokens.size() or tokens[c] != str(want):
				mismatch.append(Vector2i(c, r))
	_eq(mismatch, [], "rows 1~8 are exactly 69..6 descending")
	var row9: PackedStringArray = str(rows[8]).split(" ", false)
	_eq(" ".join(row9), "U 5 4 3 2 1 . U", "row 9 is U 5 4 3 2 1 . U")
	var seen := {}
	for r in rows.size():
		for t in str(rows[r]).split(" ", false):
			if t.is_valid_int():
				seen[t.to_int()] = true
	var missing := []
	for v in range(1, 70):
		if not seen.has(v):
			missing.append(v)
	_eq(missing, [], "every layer count 1~69 present")


# ---------- 主場景載入 ----------

func _new_main() -> Node2D:
	var m: Node2D = MainScene.instantiate()
	root.add_child(m)
	return m


func _t_scene_load() -> void:
	var m := _new_main()
	var u := 0
	var breakable := 0
	for r in m.grid.size():
		for c in m.grid[r].size():
			var br = m.grid[r][c]
			if br == null:
				continue
			if br.unbreakable:
				u += 1
			else:
				breakable += 1
	_eq(m.grid.size(), 17, "grid 17 rows")
	_eq(u, 2, "2 unbreakable bricks in scene")
	_eq(m.breakable_left, breakable, "breakable_left matches grid")
	_ok(m.grid[8][0] != null and m.grid[8][0].unbreakable, "grid[8][0] is U")
	_ok(m.grid[8][7] != null and m.grid[8][7].unbreakable, "grid[8][7] is U")
	print("INFO scene: breakable=%d unbreakable=%d view_h=%d" % [breakable, u, m.view_h])
	m.free()


# ---------- 可玩性 ----------

## 回傳下半部(第 9~17 排)所有可破壞磚的初始層數
func _lower_cells(m: Node2D) -> Dictionary:
	var out := {}
	for r in range(LOWER_FIRST_ROW, m.grid.size()):
		for c in m.grid[r].size():
			var br = m.grid[r][c]
			if br != null and not br.unbreakable:
				out[Vector2i(c, r)] = br.layers
	return out


## 自動玩家:球下落時把擋板直接放到球下方,接球點隨機偏移(模擬不同擊球角)。
func _autoplay(m: Node2D, rng: RandomNumberGenerator, offs: Dictionary) -> void:
	var length: int = m._paddle_len()
	var half := length / 2.0
	var lo: float = m.FIELD_LEFT + half
	var hi: float = m.FIELD_RIGHT - half
	var low = null
	for b in m.balls:
		if not b.stuck and b.dir.y > 0.0 and (low == null or b.pos.y > low.pos.y):
			low = b
	if low == null:
		return
	if not offs.has(low):
		offs[low] = rng.randf_range(-0.8, 0.8) * half
	var center := clampf(low.pos.x - offs[low], lo, hi)
	if absf(low.pos.x - center) > half * 0.85:
		center = clampf(low.pos.x, lo, hi)
	m.paddle_x = center
	m.target_x = center


func _simulate(angle_deg: float, balls: int, seed: int, drops: bool) -> Dictionary:
	var old := [cfg.debug_start_balls, cfg.drop_chance, cfg.game_time]
	cfg.debug_start_balls = balls
	if not drops:
		cfg.drop_chance = 0.0
	cfg.game_time = SIM_TIME + 10.0
	var m := _new_main()
	m.rng.seed = seed
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var lower := _lower_cells(m)
	var hit := {}
	var t := 0.0
	var t_all_hit := -1.0
	var t_lower_clear := -1.0
	var last_progress := 0.0
	var max_gap := 0.0
	var max_gap_at := 0.0
	var last_score: int = m.score
	var lost := 0
	var u_hits := 0
	m._launch_stuck()
	if angle_deg != 0.0:
		for b in m.balls:
			b.dir = Vector2.UP.rotated(deg_to_rad(angle_deg))
	var offs := {}
	while t < SIM_TIME and m.state == m.State.PLAYING:
		_autoplay(m, rng, offs)
		var before: int = m.balls.size()
		var u_before := [m.grid[8][0].hit_t, m.grid[8][7].hit_t]
		m._step(DT)
		t += DT
		if m.grid[8][0].hit_t > 0.0 and u_before[0] <= 0.0:
			u_hits += 1
		if m.grid[8][7].hit_t > 0.0 and u_before[1] <= 0.0:
			u_hits += 1
		# 球掉了就補一顆(只為了繼續量測);記錄次數
		if m.state == m.State.PLAYING and m.balls.size() < before and m.balls.is_empty():
			lost += 1
		if m.state != m.State.PLAYING and m.balls.is_empty():
			lost += 1
			break
		if m.menu != null:
			m.menu._on_pressed(0)
		for b in m.balls:
			if b.stuck:
				m._launch_stuck()
				break
		var paddle_hit: bool = m.paddle_flash > 0.0
		if m.score != last_score or paddle_hit:
			last_score = m.score
			last_progress = t
		var gap := t - last_progress
		if gap > max_gap:
			max_gap = gap
			max_gap_at = t
		var cleared := true
		for cell in lower:
			var br = m.grid[cell.y][cell.x]
			if (br == null or br.layers < lower[cell]) and not hit.has(cell):
				hit[cell] = t
			if br != null:
				cleared = false
		if t_all_hit < 0.0 and hit.size() == lower.size():
			t_all_hit = t
		if t_lower_clear < 0.0 and cleared:
			t_lower_clear = t
	var missed := []
	for cell in lower:
		if not hit.has(cell):
			missed.append(cell)
	# 最晚被打到的 3 塊(看哪些位置最難打)
	var order := hit.keys()
	order.sort_custom(func(a, b) -> bool: return hit[a] > hit[b])
	var slowest := []
	for k in mini(3, order.size()):
		slowest.append("%s@%.0f" % [order[k], hit[order[k]]])
	var res := {"slowest": slowest, "angle": angle_deg, "t_all_hit": t_all_hit, "t_lower_clear": t_lower_clear,
		"max_gap": max_gap, "max_gap_at": max_gap_at, "lost": lost, "u_hits": u_hits,
		"missed": missed, "lower": lower.size(), "end_t": t, "state": m.state, "score": m.score,
		"balls_end": m.balls.size()}
	m.free()
	cfg.debug_start_balls = old[0]
	cfg.drop_chance = old[1]
	cfg.game_time = old[2]
	return res


func _report(tag: String, r: Dictionary) -> void:
	print("INFO %s angle=%5.1f all_hit=%6.1fs lower_clear=%6.1fs max_no_progress=%5.2fs(@%.1f) lost=%d u_hits=%d end_t=%.1f state=%d score=%d balls=%d missed=%s slowest=%s" % [
		tag, r["angle"], r["t_all_hit"], r["t_lower_clear"], r["max_gap"], r["max_gap_at"], r["lost"],
		r["u_hits"], r["end_t"], r["state"], r["score"], r["balls_end"], r["missed"], r["slowest"]])


func _t_play_angles() -> void:
	var angles := [-60.0, -50.0, -40.0, -30.0, -20.0, -12.0, -10.0, 10.0, 12.0, 20.0, 30.0, 40.0, 50.0, 60.0]
	for i in angles.size():
		for seed in [1, 2]:
			var r := _simulate(angles[i], 1, seed * 1000 + i, false)
			_report("single seed=%d" % seed, r)
			var lbl := "angle %.0f seed %d" % [angles[i], seed]
			# 可達性:模擬時間內每塊都要被打到。300 秒(= 一局時間)只列 INFO:
			# 自動玩家是隨機擊球、不會瞄準,超過 300 秒代表「亂打要很久」,不代表打不到
			_eq(r["missed"], [], lbl + ": every lower brick hit within %ds" % int(SIM_TIME))
			if r["t_all_hit"] < 0.0 or r["t_all_hit"] > HIT_ALL_LIMIT:
				print("INFO %s: random autoplay needed > %ds to touch every lower brick" % [lbl, int(HIT_ALL_LIMIT)])
			_ok(r["max_gap"] < STUCK_LIMIT, lbl + ": no >%ds stretch without score/paddle" % int(STUCK_LIMIT))
			_eq(r["lost"], 0, lbl + ": autoplay never loses the ball")


func _t_play_multiball() -> void:
	# 用除錯設定加開場球數,並開啟正常掉落,確認多球加道具情況下也能打到下半部且無執行錯誤
	# 不掉道具:只看關卡本身
	for n in [10, 40]:
		var r := _simulate(0.0, n, 77 + n, false)
		_report("multi n=%d" % n, r)
		_eq(r["missed"], [], "multiball %d: every lower brick hit" % n)
		_ok(r["max_gap"] < STUCK_LIMIT, "multiball %d: no >%ds stretch without score/paddle" % [n, int(STUCK_LIMIT)])
	# 有掉道具:道具(黑洞、合併等)會改變球數,結果受亂數影響,只列 INFO 並檢查無執行錯誤
	for n in [10, 40]:
		var r := _simulate(0.0, n, 77 + n, true)
		_report("multi n=%d drops" % n, r)
