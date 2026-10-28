## headless 規則測試(不需額外框架)。
## 執行:Godot --headless --path game --script res://tests/run_tests.gd
## 全部通過時結束碼 0,有失敗時結束碼 1。
extends SceneTree

var _passed := 0
var _failed := 0


func _init() -> void:
	_test_layers()
	_test_damage()
	_test_effect_time()
	_test_paddle_length()
	_test_speed_tier()
	_test_score()
	_test_time_display()
	_test_hud_bars()
	_test_items()
	_test_level()
	_test_config()
	_test_paddle_drag()
	_test_item_rect()
	_test_item_textures()
	_test_pickup_flash()
	_test_scaled_geometry()
	_test_brick_grid()
	_test_brick_textures()
	_test_bomb_mark_frames()
	_test_brick_accel()
	_test_paddle_center()
	_test_high_speed_no_tunnel()
	_test_item_durations()
	_test_sticky_gun_expiry()
	_test_hud_icons()
	_test_hud_len_cell()
	_test_hud_order()
	_test_hud_d36()
	_test_hud_slots()
	_test_paddle_in_wall_on_len_change()
	# _init 時 root 還不在樹裡,加進去的節點不會跑 _ready;等一幀再測要用到樹的選單
	await process_frame
	_test_choice_menu_layout()
	print("RESULT: %d passed, %d failed" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual == expected:
		_passed += 1
	else:
		_failed += 1
		print("FAIL %s: expected %s, got %s" % [label, expected, actual])


func _test_layers() -> void:
	# 層數 → (顏色, 輪數):D12 對照表範例
	var cases := {1: [0, 0], 2: [1, 0], 7: [6, 0], 8: [0, 1], 9: [1, 1], 13: [5, 1], 14: [6, 1],
		15: [0, 2], 20: [5, 2], 24: [2, 3], 61: [4, 8], 69: [5, 9]}
	for layer in cases:
		_eq([Rules.layer_color(layer), Rules.layer_round(layer)], cases[layer], "layer %d color/round" % layer)
	_eq(Rules.sheet_row(20, false), 19, "sheet row 20")
	_eq(Rules.sheet_row(20, true), 5, "sheet row 20 bomb-marked uses round-0 same color")
	_eq(Rules.sheet_row(1, true), 0, "sheet row 1 marked")
	# 層數 → D31 底圖與數字疊加層(數字 = 輪數,0 不顯示;炸彈標記用同色第 0 輪、不顯示數字)
	var art := {1: ["d31_brick_red", ""], 7: ["d31_brick_purple", ""], 8: ["d31_brick_red", "d31_digit_1"],
		14: ["d31_brick_purple", "d31_digit_1"], 24: ["d31_brick_yellow", "d31_digit_3"],
		61: ["d31_brick_blue", "d31_digit_8"], 69: ["d31_brick_indigo", "d31_digit_9"]}
	for layer in art:
		_eq(Rules.brick_art(Rules.sheet_row(layer, false)), art[layer], "brick art layer %d" % layer)
	_eq(Rules.brick_art(Rules.sheet_row(69, true)), ["d31_brick_indigo", ""], "brick art 69 bomb-marked")


func _test_damage() -> void:
	# 扣層順序:同輪往下一色、跨輪回到紫且數字減 1、最後一層破壞
	_eq(Rules.damage_layers(9, 1), 8, "orange1 -> red1")
	_eq(Rules.damage_layers(8, 1), 7, "red1 -> violet")
	_eq([Rules.layer_color(7), Rules.layer_round(7)], [6, 0], "violet round0")
	_eq(Rules.damage_layers(15, 1), 14, "red2 -> violet1")
	_eq(Rules.damage_layers(20, 1), 19, "indigo2 -> blue2")
	_eq(Rules.damage_layers(1, 1), 0, "red -> destroyed")
	# 一次扣多層(強化 +7 = 每次 8 層)直接到最終層,不低於 0
	_eq(Rules.damage_layers(20, 8), 12, "indigo2 -8 -> blue1")
	_eq(Rules.damage_layers(3, 8), 0, "overkill clamps to 0")
	_eq(Rules.heal_layers(68, 2, 69), 69, "heal capped at 69")
	_eq(Rules.heal_layers(5, 1, 69), 6, "heal +1")


func _test_effect_time() -> void:
	var e := Effects.new()
	e.add_timed("pierce", 5.0)
	_eq(e.remaining("pierce"), 5.0, "first pickup 5s")
	e.tick(2.0)
	_eq(e.remaining("pierce"), 3.0, "after 2s")
	e.add_timed("pierce", 5.0)
	_eq(e.remaining("pierce"), 8.0, "same effect accumulates 3+5")
	_eq(e.total("pierce"), 8.0, "total resets to accumulated remaining")
	e.add_timed("flame", 5.0)
	_eq(e.is_active("pierce") and e.is_active("flame"), true, "different effects coexist")
	var expired := e.tick(5.0)
	_eq(expired, ["flame"] as Array[String], "flame expires first")
	_eq(e.is_active("pierce"), true, "pierce still active")
	_eq(e.tick(3.0), ["pierce"] as Array[String], "pierce expires")
	_eq(e.timed.is_empty(), true, "all cleared")


func _test_paddle_length() -> void:
	var cfg := GameConfig.new()
	# 單一道具換算(README:基準 85、小增 102、大增 136、小減 68、大減 34、最短 32)
	var expect := {"": 85, "paddle_len_1": 102, "paddle_len_2": 136,
		"paddle_len_down_1": 68, "paddle_len_down_2": 34, "paddle_len_min": 32}
	for id in expect:
		_eq(_len(_with([id] if id != "" else []), cfg), expect[id], "paddle length %s" % id)
	# 疊加相乘、上下限 32~320
	_eq(_len(_with(["paddle_len_1", "paddle_len_2"]), cfg), 163, "85 x 1.2 x 1.6 -> 163.2 -> 163")
	_eq(_len(_with(["paddle_len_2", "paddle_len_2", "paddle_len_2"]), cfg), 320, "85 x 1.6^3 = 348 -> capped at 320")
	_eq(_len(_with(["paddle_len_down_2", "paddle_len_min"]), cfg), 32, "floored at 32")
	_eq(_len(_with(["paddle_len_down_2", "paddle_len_down_1"]), cfg), 32, "85 x 0.4 x 0.8 -> 27.2 -> floored at 32")
	_eq(_len(_with(["paddle_len_2", "paddle_len_down_2"]), cfg), 54, "85 x 1.6 x 0.4 -> 54.4 -> 54")
	_eq(_len(_with(["paddle_len_1", "paddle_len_down_1"]), cfg), 82, "85 x 1.2 x 0.8 -> 81.6 -> 82")
	_eq(_len(_with(["paddle_len_min", "paddle_len_2"]), cfg), 51, "min (32/85) x 1.6 -> 51.2 -> 51")
	# 設定檔(實際遊戲用的)與程式預設值一致
	var tres := load("res://data/game_config.tres") as GameConfig
	_eq([tres.paddle_base_length, tres.paddle_min_length, tres.paddle_max_length], [85.0, 32, 320], "config paddle lengths")
	_test_paddle_len_shared_timer(cfg)


## 規格 B:所有長度道具共用一個 30 秒計時;每撿一個就再乘倍率並把計時重設為 30(不累加)。
func _test_paddle_len_shared_timer(cfg: GameConfig) -> void:
	var e := Effects.new()
	e.add_paddle_len("paddle_len_1", cfg)
	_eq([_len(e, cfg), e.remaining(Effects.PADDLE_LEN), e.total(Effects.PADDLE_LEN)], [102, 30.0, 30.0], "len_1: 102, timer 30")
	e.tick(10.0)
	e.add_paddle_len("paddle_len_1", cfg)
	_eq([_len(e, cfg), e.remaining(Effects.PADDLE_LEN), e.total(Effects.PADDLE_LEN)], [122, 30.0, 30.0],
		"same kind again: 85 -> 102 -> 122, timer reset to 30 (not 50)")
	e.tick(5.0)
	e.add_paddle_len("paddle_len_down_1", cfg)
	_eq([_len(e, cfg), e.remaining(Effects.PADDLE_LEN)], [98, 30.0], "down_1 multiplies in: 85 x 1.44 x 0.8 -> 98, timer reset")
	_eq(e.timed.keys(), [Effects.PADDLE_LEN], "length items share one timer entry")
	e.add_timed("pierce", 40.0)
	_eq(e.tick(29.9), [] as Array[String], "still active at 29.9 s")
	_eq(e.tick(0.2), [Effects.PADDLE_LEN] as Array[String], "shared timer expires at 30 s")
	_eq([_len(e, cfg), e.paddle_factor, e.paddle_min, e.is_active("pierce")], [85, 1.0, false, true],
		"expired: back to 85, other timed effects untouched")
	e.add_paddle_len("paddle_len_min", cfg)
	_eq([_len(e, cfg), e.paddle_min], [32, true], "min after expiry starts fresh from 85")


func _len(e: Effects, cfg: GameConfig) -> int:
	return Rules.paddle_length(cfg.paddle_base_length, [e.paddle_factor], cfg.paddle_min_length, cfg.paddle_max_length)


func _with(ids: Array) -> Effects:
	var e := Effects.new()
	for id in ids:
		e.add_paddle_len(id, GameConfig.new())
	return e


func _test_speed_tier() -> void:
	_eq(is_equal_approx(Rules.tier_multiplier(0, 0.15), 1.0), true, "tier 0 = 1.0")
	_eq(is_equal_approx(Rules.tier_multiplier(-3, 0.15), 0.55), true, "tier -3 = 0.55")
	_eq(is_equal_approx(Rules.tier_multiplier(4, 0.15), 1.6), true, "tier +4 = 1.6")
	_eq(is_equal_approx(240.0 * Rules.tier_multiplier(1, 0.15), 276.0), true, "240 +1 tier = 276")
	_eq(Rules.step_tier(4, 1, -3, 4), 4, "cannot exceed +4")
	_eq(Rules.step_tier(-3, -1, -3, 4), -3, "cannot go below -3")
	# 加速與減速互相抵銷(HUD 顯示淨值)
	var t := 0
	for d in [1, 1, 1, -1]:
		t = Rules.step_tier(t, d, -3, 4)
	_eq(t, 2, "fast x3 + slow x1 = net +2")


func _test_score() -> void:
	_eq(Rules.brick_score(1, false, 100, 200), 100, "one layer")
	_eq(Rules.brick_score(1, true, 100, 200), 300, "last layer + destroy")
	_eq(Rules.brick_score(8, true, 100, 200), 1000, "8 layers at once + destroy")
	_eq(Rules.time_bonus(12.7, 2), 24, "12 full seconds x 2")
	_eq(Rules.time_bonus(-1.0, 2), 0, "no negative bonus")
	_eq(Rules.thief_steal(300, 500), 0, "thief floors at 0")
	_eq(Rules.thief_steal(6000, 500), 5500, "thief steals")


func _test_time_display() -> void:
	_eq(Rules.time_text(300.0), "5:00", "start 5:00")
	_eq(Rules.time_text(299.2), "5:00", "rounds up")
	_eq(Rules.time_text(59.1), "1:00", "1:00")
	_eq(Rules.time_text(700.0), "11:40", "MM:SS")
	_eq(Rules.time_text(0.0), "0:00", "zero")
	# 30~11 秒偶數秒前 500 ms 紅;10~1 秒每秒前 500 ms 紅;0 秒停紅
	var cases := {31.0: false, 30.4: false, 30.0: true, 29.7: true, 29.4: false, 29.0: false, 28.8: false,
		12.0: true, 11.9: true, 11.0: false, 10.0: true, 9.6: true, 9.4: false, 1.0: true, 0.6: true, 0.4: false, 0.0: true}
	for rem in cases:
		_eq(Rules.time_is_red(rem), cases[rem], "red at %.1f" % rem)


func _test_hud_bars() -> void:
	_eq(Rules.timebar_fill(5.0, 5.0), 20, "full bar")
	_eq(Rules.timebar_fill(2.4, 5.0), 10, "ceil(9.6)")
	_eq(Rules.timebar_fill(0.01, 5.0), 1, "tiny remaining still 1")
	_eq(Rules.timebar_fill(0.0, 5.0), 0, "empty")
	_eq(Rules.segment_widths(7), [2, 2, 2, 2, 2, 2, 2] as Array[int], "N=7 widths")
	_eq(Rules.segment_widths(4), [5, 4, 4, 4] as Array[int], "N=4 widths")
	_eq(Rules.segment_widths(3), [6, 6, 6] as Array[int], "N=3 widths")
	_eq(Rules.segment_widths(5), [4, 3, 3, 3, 3] as Array[int], "N=5 widths")
	_eq(Rules.segment_gray_indices(7), [0, 1, 2, 3, 4, 5, 6] as Array[int], "N=7 grays")
	_eq(Rules.segment_gray_indices(3), [0, 3, 6] as Array[int], "N=3 grays W 8 g")
	_eq(Rules.segment_gray_indices(4), [0, 2, 4, 6] as Array[int], "N=4 grays W G f g")
	_eq(Rules.segment_gray_indices(5), [0, 2, 3, 5, 6] as Array[int], "N=5 grays W G 8 y g")


func _test_items() -> void:
	_eq(ItemDefs.BUFF.size() + ItemDefs.DEBUFF.size(), 26, "26 icons (paddle_len_max removed)")
	for id in ItemDefs.BUFF + ItemDefs.DEBUFF:
		_eq(ResourceLoader.exists(ItemDefs.icon_path(id, false)) and ResourceLoader.exists(ItemDefs.icon_path(id, true)), true, "icon exists %s" % id)
		_eq(ItemDefs.TEXT.has(id), true, "text exists %s" % id)
	# 擋板最大化已移除:不在掉落池、金球池、說明表;圖檔也已刪除
	var all_pools: Array = ItemDefs.drop_pool(true, true) + ItemDefs.drop_pool(false, true) \
		+ ItemDefs.choice_pool(true, true) + ItemDefs.choice_pool(false, true)
	_eq(["paddle_len_max" in all_pools, ItemDefs.exists("paddle_len_max"), ItemDefs.TEXT.has("paddle_len_max")],
		[false, false, false], "paddle_len_max not in any pool / text")
	_eq(ResourceLoader.exists("res://art/items40/d32_item_paddle_len_max_f1.png"), false, "paddle_len_max art removed")
	var gold := ItemDefs.choice_pool(true, false)
	_eq([gold.size(), "golden_ball" in gold], [11, false], "golden pool 11 without golden ball")
	var dark := ItemDefs.choice_pool(false, false)
	_eq([dark.size(), "black_ball" in dark, "thief" in dark], [12, false, false], "black pool 12, no thief on new level")
	_eq(ItemDefs.choice_pool(false, true).size(), 13, "black pool 13 with thief on replay")
	_eq("thief" in ItemDefs.drop_pool(false, false), false, "no thief drop on new level")
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var ok := true
	for i in 200:
		var picks := ItemDefs.pick_distinct(gold, 3, rng)
		var uniq := {}
		for p in picks:
			uniq[p] = true
			ok = ok and p in gold
		ok = ok and picks.size() == 3 and uniq.size() == 3
	_eq(ok, true, "3 distinct picks from pool")
	# 說明文字從設定檔產生:預設值要與 D29 字面一致,改設定後跟著變
	_eq(ItemDefs.desc_lines("paddle_len_1"), ["長度變成1.2倍", "持續30秒"], "D29 text paddle_len_1")
	_eq(ItemDefs.desc_lines("bomb"), ["撞到的磚塊被標記", "10秒後全部爆炸"], "D29 text bomb")
	_eq(ItemDefs.desc_lines("thief"), ["偷走500到5000分", "分數最低到0"], "D29 text thief")
	_eq(ItemDefs.desc_lines("heal_area"), ["撞到的磚塊加2層", "周圍一圈加1層", "持續10秒"], "D29 text heal_area")
	_eq(ItemDefs.desc_lines("gun"), ["點畫面，兩端各射1發", "減1層 不觸發功能磚", "持續10秒"], "D29 text gun")
	_eq(ItemDefs.desc_lines("sticky"), ["球碰到擋板會黏住", "點一下才發射", "持續30秒"], "D29 text sticky")
	_test_item_text_matches_doc()
	var cfg := load(ItemDefs.CONFIG_PATH) as GameConfig
	var old := [cfg.dur_invincible, cfg.dur_paddle_len, cfg.thief_min, cfg.thief_max]
	cfg.dur_invincible = 7.5
	cfg.dur_paddle_len = 12.0
	cfg.thief_min = 100
	cfg.thief_max = 900
	_eq(ItemDefs.desc_lines("invincible"), ["所有磚塊無法破壞", "魔王除外，持續7.5秒"], "text follows dur_invincible")
	_eq([ItemDefs.desc_lines("paddle_len_down_2")[1], ItemDefs.desc_lines("paddle_len_min")[0]],
		["持續12秒", "縮到最短，持續12秒"], "text follows dur_paddle_len")
	_eq(ItemDefs.desc_lines("thief")[0], "偷走100到900分", "text follows thief range")
	cfg.dur_invincible = old[0]
	cfg.dur_paddle_len = old[1]
	cfg.thief_min = old[2]
	cfg.thief_max = old[3]
	# 每個說明都不能殘留未代入的 {鍵}
	var leftover := []
	for id in ItemDefs.TEXT:
		for line in ItemDefs.desc_lines(id):
			if "{" in line:
				leftover.append(id)
	_eq(leftover, [], "no unfilled placeholders")


## 說明文字逐字對照 docs/design/ui-menus.md D29 第六節表格(「| `item_<id>` | 名稱 | 說明(｜換行) |」)。
func _test_item_text_matches_doc() -> void:
	var path := ProjectSettings.globalize_path("res://").path_join("../docs/design/ui-menus.md")
	var f := FileAccess.open(path, FileAccess.READ)
	_eq(f != null, true, "ui-menus.md readable")
	if f == null:
		return
	var re := RegEx.create_from_string("^\\s*\\| `item_(\\w+)` \\| ([^|]+) \\| ([^|]+) \\|")
	var seen := []
	var bad := []
	for line in f.get_as_text().split("\n"):
		var m := re.search(line)
		if m == null:
			continue
		var id := m.get_string(1)
		seen.append(id)
		# 「小偷（僅重複關卡）」的括號是給工程師的條件,畫面只顯示「小偷」
		var name := m.get_string(2).strip_edges().replace("（僅重複關卡）", "")
		var lines := Array(m.get_string(3).strip_edges().split("｜"))
		if not ItemDefs.TEXT.has(id) or ItemDefs.item_name(id) != name or ItemDefs.desc_lines(id) != lines:
			bad.append(id)
	_eq(bad, [], "item text matches D29 table")
	var ids := (ItemDefs.BUFF + ItemDefs.DEBUFF).filter(func(id: String) -> bool: return id not in ["golden_ball", "black_ball"])
	seen.sort()
	ids.sort()
	_eq(seen, ids, "D29 table lists exactly the 24 non-menu items")


func _test_level() -> void:
	var data = load("res://data/levels/level_test.json").data
	var main_script := load("res://scripts/main.gd")
	var rows: int = main_script.MAX_ROWS
	var cols: int = main_script.COLS
	_eq([cols, rows], [8, 17], "grid 8 cols x 17 rows")
	var parsed := Rules.parse_level(data, rows, cols, 69)
	_eq(parsed["errors"].size(), 0, "test level has no errors")
	_eq(parsed["cells"].size(), 17, "test level fills 17 rows")
	# 測試關卡要涵蓋 1~69 每一種層數(含 7 種顏色、數字 1~9)、不可破壞磚與空格
	var seen := {}
	for line in parsed["cells"]:
		for v in line:
			seen[v] = true
	var missing := []
	for v in range(1, 70):
		if not seen.has(v):
			missing.append(v)
	_eq([missing, seen.has(Rules.UNBREAKABLE), seen.has(0)], [[], true, true], "test level covers 1~69, U and empty")
	var bad := Rules.parse_level({"rows": ["1 x 70 U 0 . . .", "1", "1 2 3 4 5 6 7 8 9"]}, rows, cols, 69)
	_eq(bad["cells"][0], [1, 0, 0, -1, 0, 0, 0, 0] as Array[int], "invalid cells become empty")
	_eq(bad["cells"][2], [1, 2, 3, 4, 5, 6, 7, 8] as Array[int], "9th column dropped")
	_eq(bad["errors"].size(), 5, "errors: x + 70 + 0 + short row + 9-col row")
	var eighteen := []
	for i in 18:
		eighteen.append("1 1 1 1 1 1 1 1")
	var over := Rules.parse_level({"rows": eighteen}, rows, cols, 69)
	_eq([over["cells"].size(), over["errors"].size()], [17, 1], "18th row rejected with error")
	_eq(Rules.parse_level(null, rows, cols, 69)["errors"].size(), 1, "missing rows reported")


func _test_config() -> void:
	var cfg := load("res://data/game_config.tres") as GameConfig
	_eq(cfg != null, true, "config loads as GameConfig")
	if cfg == null:
		return
	_eq([cfg.ball_speed, cfg.paddle_speed, cfg.drop_chance, cfg.game_time],
		[240.0, 450.0, 0.3, 300.0], "config basic values")
	_eq([cfg.dur_paddle_len, cfg.dur_pierce, cfg.dur_flame, cfg.dur_bomb, cfg.dur_sticky, cfg.dur_gun,
		cfg.dur_heal, cfg.dur_heal_area, cfg.dur_blackhole, cfg.dur_invincible, cfg.dur_invisible],
		[30.0, 20.0, 20.0, 10.0, 30.0, 10.0, 10.0, 10.0, 5.0, 10.0, 10.0], "config item durations (README)")
	_eq("effect_duration" in cfg, false, "shared effect_duration removed")
	_eq([cfg.debug_force_item, cfg.debug_start_balls], ["", 1], "debug defaults")


## 不進場景樹的主程式:不跑 _ready,只用到 cfg 與資料,足以測輸入、擋板與道具邏輯。
## 設定檔用複本,測試中改值不會影響其他測試。
func _bare_main() -> Node2D:
	var m: Node2D = load("res://scripts/main.gd").new()
	m.cfg = (load("res://data/game_config.tres") as GameConfig).duplicate()
	return m


func _touch(m: Node2D, x: float, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = 0
	e.pressed = pressed
	e.position = Vector2(x, 400)
	m._unhandled_input(e)


func _drag(m: Node2D, dx: float, index := 0) -> void:
	var e := InputEventScreenDrag.new()
	e.index = index
	e.relative = Vector2(dx, 37)
	m._unhandled_input(e)


func _test_paddle_drag() -> void:
	var m := _bare_main()
	# 點擊(按下、放開)不移動擋板
	_touch(m, 320, true)
	_touch(m, 320, false)
	m._update_paddle(1.0)
	_eq(m.paddle_x, 180.0, "tap does not move paddle")
	# 擋板跟著手指的水平位移,方向相同;垂直位移無作用
	_drag(m, 30)
	m._update_paddle(1.0)
	_eq(m.paddle_x, 210.0, "drag +30 moves paddle +30")
	_drag(m, -50)
	m._update_paddle(1.0)
	_eq(m.paddle_x, 160.0, "drag -50 moves paddle -50")
	_drag(m, 40, 1)
	m._update_paddle(1.0)
	_eq(m.paddle_x, 160.0, "second finger ignored")
	# 速度上限 450 px/s:0.1 秒最多 45;追不上的位移保留,下一幀繼續追
	_drag(m, 100)
	m._update_paddle(0.1)
	_eq(is_equal_approx(m.paddle_x, 205.0), true, "capped at 450 px/s (x=%.2f)" % m.paddle_x)
	m._update_paddle(0.1)
	_eq(is_equal_approx(m.paddle_x, 250.0), true, "leftover displacement kept (x=%.2f)" % m.paddle_x)
	# 擋板速度 +1 階 = 517.5 px/s
	m.effects.paddle_tier = 1
	m.paddle_x = 180.0
	m.target_x = 180.0
	_drag(m, 100)
	m._update_paddle(0.1)
	_eq(is_equal_approx(m.paddle_x, 231.75), true, "+1 tier capped at 517.5 px/s (x=%.2f)" % m.paddle_x)
	m.effects.paddle_tier = 0
	# 滑過右邊界(擋板 85 → 中心最多 297.5)後往回滑,擋板馬上往回動
	_drag(m, 500)
	m._update_paddle(1.0)
	_eq(m.paddle_x, 297.5, "clamped at right edge")
	_eq(m._paddle_left(85) + 85, 340, "right edge: paddle ends at field right 340")
	_drag(m, -20)
	m._update_paddle(1.0)
	_eq(m.paddle_x, 277.5, "drag back from right edge moves immediately")
	_drag(m, -900)
	_drag(m, 15)
	m._update_paddle(1.0)
	_eq(m.paddle_x, 77.5, "drag back from left edge (62.5 + 15) moves immediately")
	m.free()


func _test_item_rect() -> void:
	var m := _bare_main()
	# 掉落的 40×40 範圍中心 = 被破壞磚的中心(第 0 欄、中間、最後一格都測)
	m.cfg.debug_force_item = "slow"
	for cell in [Vector2i(0, 0), Vector2i(2, 3), Vector2i(7, 16)]:
		m.items.clear()
		m._roll_drop(m._cell_rect(cell).position)
		var r: Rect2 = m._item_rect(m.items[0]["pos"])
		_eq([r.size, r.get_center()], [Vector2(40, 40), m._cell_rect(cell).get_center()], "item rect 40x40 centered on brick %s" % cell)
	# 擋板 85、中心 180 → 左緣 round(137.5) = 138,範圍 x 138~223、y 755~771(右、下緣不含)。
	# 道具範圍 = pos − 12 起 40×40。剛好 1 px 重疊算接到,剛好碰邊不算
	var cases := [
		[Vector2(234, 740), true, "right: rect x 222 overlaps 1 px"],
		[Vector2(235, 740), false, "right: rect x 223 touches edge"],
		[Vector2(111, 740), true, "left: rect end x 139 overlaps 1 px"],
		[Vector2(110, 740), false, "left: rect end x 138 touches edge"],
		[Vector2(172, 728), true, "top: rect end y 756 overlaps 1 px"],
		[Vector2(172, 727), false, "top: rect end y 755 touches edge"],
	]
	for c in cases:
		m.items = [{"id": "slow", "pos": c[0]}]
		m.effects.ball_tier = 0
		m._update_items(0.0)
		_eq([m.items.is_empty(), m.effects.ball_tier == -1], [c[1], c[1]], "40x40 catch %s" % c[2])
	# 移除:40×40 上緣(pos.y − 12)> view_h 才移除;上緣 = view_h 保留。x 20 遠離擋板
	var vh: int = m.view_h
	m.items = [{"id": "slow", "pos": Vector2(20, vh + 12)}, {"id": "slow", "pos": Vector2(20, vh + 12.5)}]
	m._update_items(0.0)
	_eq(m.items, [{"id": "slow", "pos": Vector2(20, vh + 12)}], "item kept at 40x40 top = view_h, removed once top > view_h")
	m.free()


## D32 掉落道具 26 種 × F1/F2 都是 40×40、接取閃光 3 幀都是 48×48,而且 _t 會到 art/items40 找。
func _test_item_textures() -> void:
	var m := _bare_main()
	var bad := []
	var count := 0
	for id in ItemDefs.BUFF + ItemDefs.DEBUFF:
		for f in [1, 2]:
			count += 1
			var tex: Texture2D = m._t("d32_item_%s_f%d" % [id, f])
			if tex == null or tex.get_size() != Vector2(40, 40):
				bad.append("%s_f%d" % [id, f])
	for f in [1, 2, 3]:
		count += 1
		var tex: Texture2D = m._t("d32_item_pickup_f%d" % f)
		if tex == null or tex.get_size() != Vector2(48, 48):
			bad.append("pickup_f%d" % f)
	_eq([count, bad], [55, []], "55 D32 item textures load with correct size (26 x 2 + 3)")
	_eq(m._t("d32_item_slow_f1").resource_path, "res://art/items40/d32_item_slow_f1.png", "d32 loads from art/items40")
	m.free()


## 接取閃光:以道具中心為中心的 48×48,3 幀各 60 ms,共 180 ms 後移除。
func _test_pickup_flash() -> void:
	var m := _bare_main()
	m._pickup("slow", Vector2(100, 600))
	var a: Dictionary = m.anims[0]
	_eq([a["kind"], Rect2(a["pos"], Vector2(48, 48)).get_center()], ["pickup", Vector2(108, 608)], "flash centered on item center")
	_eq([m._pickup_frame(0.0), m._pickup_frame(0.059), m._pickup_frame(0.061), m._pickup_frame(0.119),
		m._pickup_frame(0.121), m._pickup_frame(0.179)], [1, 1, 2, 2, 3, 3], "flash frames 60 ms each")
	# 避開剛好 180 ms 的浮點誤差:179 ms 還在、181 ms 已移除
	m._update_anims(0.179)
	_eq(m.anims.size(), 1, "flash still showing at 179 ms")
	m._update_anims(0.002)
	_eq(m.anims.size(), 0, "flash removed by 181 ms")
	m.free()


## D29 修訂(2026-10-28):選單用 D32 的 40×40 圖示與 48×48 閃光,1 倍顯示;
## 畫面座標以 H = 800 為準,其他高度整體跟著面板位移(面板 y 差 = dy)。
func _test_choice_menu_layout() -> void:
	_eq([ItemDefs.icon_path("slow", false), ItemDefs.icon_path("thief", true)],
		["res://art/items40/d32_item_slow_f1.png", "res://art/items40/d32_item_thief_f2.png"], "menu icon path -> items40")
	_eq([ChoiceOption.PICKUP[0].resource_path, ChoiceOption.PICKUP[2].resource_path],
		["res://art/items40/d32_item_pickup_f1.png", "res://art/items40/d32_item_pickup_f3.png"], "menu pickup flash -> items40")
	# 1 倍:畫的矩形大小 = 圖檔大小
	_eq([ChoiceOption.ICON_RECT.size, (load(ItemDefs.icon_path("slow", false)) as Texture2D).get_size()],
		[Vector2(40, 40), Vector2(40, 40)], "option icon drawn 1x")
	_eq([ChoiceOption.PICKUP_RECT.size, (ChoiceOption.PICKUP[0] as Texture2D).get_size()],
		[Vector2(48, 48), Vector2(48, 48)], "pickup flash drawn 1x")
	_eq(ChoiceOption.ICON_RECT.get_center(), ChoiceOption.PICKUP_RECT.get_center(), "flash and icon share center")
	_eq(ChoiceOption.TEXT_W, 216, "option text width 216")
	for h in [800, 640]:
		for golden in [true, false]:
			var menu := ChoiceMenu.new()
			menu.setup(golden, ["slow", "split", "gun"] if golden else ["fast", "thief", "merge"], h, false)
			root.add_child(menu)
			menu._apply_entry(1.0)
			var dy: float = menu._panel.position.y - 210
			var tag := "H=%d %s" % [h, "gold" if golden else "black"]
			var icon := menu._panel.get_child(1) as TextureRect
			_eq([icon.get_global_rect(), icon.texture.get_size()], [Rect2(40, 225 + dy, 40, 40), Vector2(40, 40)], "title icon 40x40 1x %s" % tag)
			_eq(icon.texture.resource_path, ItemDefs.icon_path("golden_ball" if golden else "black_ball", false), "title icon path %s" % tag)
			for i in [2, 3]:
				var l := menu._panel.get_child(i) as Label
				_eq([l.global_position.x, l.size.x, l.global_position.x + l.size.x - 1], [88.0, 232.0, 319.0], "title text %d x 88 w 232 %s" % [i, tag])
			for k in 3:
				var o: ChoiceOption = menu._options[k]
				var g := o.global_position
				_eq(o.get_global_rect(), Rect2(40, 278 + dy + 120 * k, 280, 112), "option %d rect %s" % [k, tag])
				_eq(Rect2(g + ChoiceOption.ICON_RECT.position, ChoiceOption.ICON_RECT.size), Rect2(48, 314 + dy + 120 * k, 40, 40), "option %d icon %s" % [k, tag])
				_eq(Rect2(g + ChoiceOption.PICKUP_RECT.position, ChoiceOption.PICKUP_RECT.size), Rect2(44, 310 + dy + 120 * k, 48, 48), "option %d flash %s" % [k, tag])
				_eq(g + ChoiceOption.PICKUP_RECT.get_center(), Vector2(68, g.y + 56), "option %d flash center %s" % [k, tag])
				_eq([g.x + ChoiceOption.TEXT_X, g.x + ChoiceOption.TEXT_X + ChoiceOption.TEXT_W - 1], [96.0, 311.0], "option %d text x 96~311 %s" % [k, tag])
			menu.free()
	# H = 640 面板 y = 52 + floor((640 − 484) / 2) = 130,比 H = 800 高 80
	var m640 := ChoiceMenu.new()
	m640.setup(true, ["slow", "split", "gun"], 640, false)
	root.add_child(m640)
	_eq(m640._panel.position.y, 130.0, "panel y 130 at H=640")
	m640.free()


## 尺寸:磚格 40×20 座標、擋板位置、球的碰撞半徑、漏球、槍口位置。
func _test_scaled_geometry() -> void:
	var m := _bare_main()
	var main_script := load("res://scripts/main.gd")
	# 磚格 40×20,8 欄剛好填滿 x 20~340;17 排從 y 68 到 y 408
	_eq(m._cell_rect(Vector2i(0, 0)), Rect2(20, 68, 40, 20), "cell (0,0)")
	_eq(m._cell_rect(Vector2i(7, 16)), Rect2(300, 388, 40, 20), "last cell (7,16)")
	_eq(m._cell_rect(Vector2i(7, 16)).end, Vector2(340, 408), "grid ends at x 340, y 408")
	# 擋板高 16,下緣維持 y 770(800 高時上緣 755)
	_eq([m._paddle_y(), m._paddle_y() + main_script.PADDLE_H - 1], [755, 770], "paddle y 755~770")
	_eq(main_script.BALL_R, 8.0, "ball radius 8 (16x16)")
	# 球半徑 8:圓心離磚下緣/側邊 7.9 碰到、8.1 碰不到;轉角看斜向距離(5.6√2 ≈ 7.92 碰到,5.7√2 ≈ 8.06 碰不到)
	var cell: Rect2 = m._cell_rect(Vector2i(0, 16))
	_eq(m._circle_rect(Vector2(40, 415.9), cell).z > 0.0, true, "ball r=8 touches bottom at 7.9")
	_eq(m._circle_rect(Vector2(40, 416.1), cell).z > 0.0, false, "ball r=8 misses bottom at 8.1")
	_eq(m._circle_rect(Vector2(67.9, 398), cell).z > 0.0, true, "ball r=8 touches side at 7.9")
	_eq(m._circle_rect(Vector2(68.1, 398), cell).z > 0.0, false, "ball r=8 misses side at 8.1")
	_eq(m._circle_rect(Vector2(65.6, 413.6), cell).z > 0.0, true, "ball r=8 touches corner at 7.92")
	_eq(m._circle_rect(Vector2(65.7, 413.7), cell).z > 0.0, false, "ball r=8 misses corner at 8.06")
	# 漏球:球上緣(圓心 − 8)超過畫面底才移除
	var vh: int = m.view_h
	for y in [vh + 7.5, vh + 8.5]:
		var b = main_script.Ball.new()
		b.pos = Vector2(100, y)
		b.dir = Vector2.DOWN
		m.balls.append(b)
	m._update_balls(0.0001)
	_eq(m.balls.size(), 1, "only ball whose top passed view_h is removed")
	_eq(m.balls[0].pos.y < vh + 8.0, true, "ball still touching screen kept")
	# 槍:原尺寸子彈 4 寬置中於放大後砲管(槍端 16 寬的第 4~11 欄),從砲管上方射出
	m._apply_item("gun")
	m._fire_gun()
	var left: int = m._paddle_left(m._paddle_len())
	_eq(m.bullets, [Vector2(left + 6, 739), Vector2(left + 85 - 16 + 6, 739)], "bullets centered on 2x barrels")
	m.free()


## 空的 8×17 格子(_bare_main 不跑 _load_level)。
func _empty_grid(m: Node2D) -> void:
	var main_script := load("res://scripts/main.gd")
	m.grid = []
	for r in main_script.MAX_ROWS:
		var row := []
		row.resize(main_script.COLS)
		m.grid.append(row)


func _brick(m: Node2D, cell: Vector2i, layers: int) -> void:
	var br = load("res://scripts/main.gd").Brick.new()
	br.layers = layers
	m.grid[cell.y][cell.x] = br
	m.breakable_left += 1


## 依 40×20 格子運作的規則:球碰磚、火焰 3×3、子彈、道具掉落中心。
func _test_brick_grid() -> void:
	var m := _bare_main()
	m.rng.seed = 1
	_empty_grid(m)
	# 球由下往上:圓心離 (3,5) 下緣(y 188)7.9 會打到並反彈,8.1 不會
	_brick(m, Vector2i(3, 5), 3)
	_brick(m, Vector2i(7, 16), 9)
	var b = load("res://scripts/main.gd").Ball.new()
	b.pos = Vector2(160, 196.1)
	b.dir = Vector2.UP
	m._ball_bricks(b, false)
	_eq([m.grid[5][3].layers, b.dir], [3, Vector2.UP], "ball 8.1 below brick: no hit")
	b.pos = Vector2(160, 195.9)
	m._ball_bricks(b, false)
	_eq([m.grid[5][3].layers, b.dir.y > 0.0], [2, true], "ball 7.9 below brick: hit and bounce")
	# 火焰 3×3:最後一格 (7,16) 在角落,只有 3 個鄰格
	_eq(m._neighbors(Vector2i(7, 16)).size(), 3, "corner cell has 3 neighbors")
	_eq(m._neighbors(Vector2i(3, 5)).size(), 8, "inner cell has 8 neighbors")
	_brick(m, Vector2i(6, 15), 5)
	m.effects.add_timed("flame", 5.0)
	m._ball_hit_brick(Vector2i(7, 16))
	_eq([m.grid[16][7].layers, m.grid[15][6].layers], [7, 4], "flame: hit -2, diagonal neighbor -1")
	m.effects.timed.clear()
	# 子彈:x 300 起的判定點落在第 7 欄,碰到 (7,16) 的下緣 y 408
	_eq(m._bullet_trace(300, 420, 400), Vector3i(7, 16, 408), "bullet hits last cell bottom")
	_eq(m._bullet_trace(300, 407, 400), Vector3i(-1, -1, -1), "bullet above bottom edge misses")
	# 破壞時道具圖示中心 = 磚中心 (160, 178)
	m.cfg.debug_force_item = "slow"
	m._damage(Vector2i(3, 5), 99)
	_eq(m._item_rect(m.items[0]["pos"]).get_center(), Vector2(160, 178), "drop centered on 40x20 brick")
	m.free()


## D31 磚圖都載入得到、都是 40×20,而且 _t 會到 art/bricks40 找。
func _test_brick_textures() -> void:
	var m := _bare_main()
	var names: Array[String] = ["d31_brick_hit", "d31_brick_dust_f4", "d31_brick_unbreakable", "d31_brick_unbreakable_hit",
		"d31_invincible_frame", "d37_bomb_mark_f1", "d37_bomb_mark_f2", "d37_bomb_mark_f3", "d37_bomb_mark_f4"]
	for color in Rules.COLOR_NAMES:
		for suffix in ["", "_f1", "_f2", "_f3"]:
			names.append("d31_brick_%s%s" % [color, suffix])
	for d in range(1, 10):
		names.append("d31_digit_%d" % d)
	_eq(names.size(), 46, "46 brick textures")
	var bad := []
	for n in names:
		var tex: Texture2D = m._t(n)
		if tex == null or tex.get_size() != Vector2(40, 20):
			bad.append(n)
	_eq(bad, [], "all D31/D37 textures load as 40x20")
	m.free()


## D37 炸彈標記:F1 0~160、F2 160~260、F3 260~360、F4 360~500 ms;減少動態固定 F1。
func _test_bomb_mark_frames() -> void:
	var m := _bare_main()
	var got := []
	for ms in [0, 159, 160, 259, 260, 359, 360, 499]:
		got.append(m._bomb_mark(ms / 1000.0))
	_eq(got, ["d37_bomb_mark_f1", "d37_bomb_mark_f1", "d37_bomb_mark_f2", "d37_bomb_mark_f2",
		"d37_bomb_mark_f3", "d37_bomb_mark_f3", "d37_bomb_mark_f4", "d37_bomb_mark_f4"], "D37 bomb mark frame by time")
	_eq(m.BOMB_MARK_ENDS[-1], 0.5, "D37 bomb mark cycle 500 ms")
	m.reduced_motion = true
	_eq([m._bomb_mark(0.2), m._bomb_mark(0.3), m._bomb_mark(0.4)], ["d37_bomb_mark_f1", "d37_bomb_mark_f1", "d37_bomb_mark_f1"],
		"D37 bomb mark reduced motion fixed F1")
	m.free()


func _unbreakable(m: Node2D, cell: Vector2i) -> void:
	var br = load("res://scripts/main.gd").Brick.new()
	br.unbreakable = true
	m.grid[cell.y][cell.x] = br


## 打磚加速:不可破壞 +1%、其他 +0.5%、上限 2.0;與速度階相乘;只算球碰磚。
func _test_brick_accel() -> void:
	var m := _bare_main()
	_empty_grid(m)
	_unbreakable(m, Vector2i(0, 0))
	_brick(m, Vector2i(1, 0), 69)
	_brick(m, Vector2i(2, 0), 69)
	_eq(is_equal_approx(m._ball_speed(), 240.0), true, "no accel at start: 240")
	m._ball_hit_brick(Vector2i(0, 0))
	_eq(is_equal_approx(m._ball_speed(), 240.0 * 1.01), true, "unbreakable hit +1%")
	m._ball_hit_brick(Vector2i(1, 0))
	_eq(is_equal_approx(m._ball_speed(), 240.0 * 1.015), true, "multi-layer hit +0.5% (additive)")
	# 子彈打可破壞磚、打不可破壞磚都不加速;火焰擴散/炸彈走 _damage,同樣不加速
	# 子彈 x 59 判定點落在第 1 欄、x 19 落在第 0 欄;這一幀從 y 100 掃到 70,經過磚下緣 88
	m.bullets = [Vector2(59, 100), Vector2(19, 100)]
	m._update_bullets(0.05)
	m._damage(Vector2i(2, 0), 1)
	_eq([m.grid[0][1].layers, m.grid[0][2].layers], [67, 68], "bullet and _damage did hurt bricks")
	_eq(is_equal_approx(m.brick_accel, 0.015), true, "bullet / splash damage do not accelerate")
	# 上限 +100%:再打 100 次不可破壞磚仍停在 2.0
	for i in 100:
		m._ball_hit_brick(Vector2i(0, 0))
	_eq(is_equal_approx(1.0 + m.brick_accel, 2.0), true, "accel capped at 2.0")
	# 與 +4 階直接相乘:1.6 × 2.0 = 3.2 → 768 px/s,不設總上限
	m.effects.ball_tier = 4
	_eq(is_equal_approx(m._ball_speed(), 240.0 * 3.2), true, "+4 tier x 2.0 accel = 3.2x (768)")
	# 減速只降 1 階,不清除累積加速
	m._apply_item("slow")
	_eq([m.effects.ball_tier, is_equal_approx(m.brick_accel, 1.0)], [3, true], "slow drops 1 tier, keeps accel")
	_eq(is_equal_approx(m._ball_speed(), 240.0 * 1.45 * 2.0), true, "slow: 1.45 x 2.0")
	# 加速立刻套用到所有球、方向不變:兩顆球同一幀,第二顆用新速度移動
	m.effects.ball_tier = 0
	m.brick_accel = 0.0
	m.grid[0][0] = null
	m.grid[0][1] = null
	m.grid[0][2] = null
	_unbreakable(m, Vector2i(4, 10))   # 格子 x 180~220、y 268~288
	var main_script := load("res://scripts/main.gd")
	var a = main_script.Ball.new()
	a.pos = Vector2(200, 296.5)        # 往上 0.6 px 就碰到磚下緣 288
	a.dir = Vector2.UP
	var c = main_script.Ball.new()
	c.pos = Vector2(100, 500)
	c.dir = Vector2(0.6, -0.8)
	m.balls.assign([a, c])
	m._update_balls(0.01)
	_eq(is_equal_approx(m.brick_accel, 0.01), true, "ball bounce off unbreakable accelerates")
	_eq(c.dir, Vector2(0.6, -0.8), "other ball keeps direction")
	_eq(is_equal_approx((c.pos - Vector2(100, 500)).length(), 240.0 * 1.01 * 0.01), true,
		"other ball moves at new speed in the same frame (%.4f)" % (c.pos - Vector2(100, 500)).length())
	# 穿透:進入可破壞磚時加速一次,停留在磚內不重複加
	m.brick_accel = 0.0
	_brick(m, Vector2i(1, 5), 69)
	var p = main_script.Ball.new()
	p.pos = Vector2(80, 190)           # 與 (1,5) 的 y 168~188 重疊
	p.dir = Vector2.UP
	m._ball_bricks(p, true)
	m._ball_bricks(p, true)
	_eq([m.grid[5][1].layers, is_equal_approx(m.brick_accel, 0.005)], [68, true], "pierce entry accelerates once")
	m.free()
	# 新開一局歸零:新的主程式從 0 開始
	var fresh := _bare_main()
	_eq(fresh.brick_accel, 0.0, "new game starts with no accel")
	fresh.free()
	# 設定檔預設值
	var tres := load("res://data/game_config.tres") as GameConfig
	_eq([tres.brick_accel_unbreakable, tres.brick_accel_other, tres.brick_accel_max], [0.01, 0.005, 1.0], "config accel defaults")
	_eq(tres.brick_accel_paddle, 0.005, "config paddle accel default")
	_test_paddle_accel()


## 擋板加速:每次碰擋板(反彈或黏住)+0.5%,與打磚共用上限;黑洞、黏住後跟著擋板移動都不加。
func _test_paddle_accel() -> void:
	var main_script := load("res://scripts/main.gd")
	var m := _bare_main()
	_empty_grid(m)
	var length: int = m._paddle_len()
	var left: int = m._paddle_left(length)
	var py: int = m._paddle_y()
	var b = main_script.Ball.new()
	b.pos = Vector2(180, py - 4)
	b.dir = Vector2(0, 1)
	m._ball_paddle(b, left, length, py)
	_eq([b.dir.y < 0.0, is_equal_approx(m.brick_accel, 0.005)], [true, true], "paddle bounce +0.005")
	# 反彈後球往上,同一位置再判定不會重複加
	m._ball_paddle(b, left, length, py)
	_eq(is_equal_approx(m.brick_accel, 0.005), true, "bounce counted once")
	# 吸附:黏住那次 +0.005,之後跟著擋板移動好幾幀都不加
	m.brick_accel = 0.0
	m._apply_item("sticky")
	b.pos = Vector2(180, py - 4)
	b.dir = Vector2(0, 1)
	m.balls.assign([b])
	m._update_balls(0.01)
	_eq([b.stuck, is_equal_approx(m.brick_accel, 0.005)], [true, true], "sticky: stick counts +0.005")
	for i in 30:
		m._update_balls(1.0 / 60.0)
	_eq(is_equal_approx(m.brick_accel, 0.005), true, "sticky: following paddle adds nothing")
	m.effects.timed.erase("sticky")
	# 黑洞:球碰擋板消失,不加速
	m.brick_accel = 0.0
	m.effects.add_timed("blackhole", 5.0)
	var h = main_script.Ball.new()
	h.pos = Vector2(180, py - 4)
	h.dir = Vector2(0, 1)
	m.balls.assign([h])
	m._update_balls(0.01)
	_eq([m.balls.is_empty(), m.brick_accel], [true, 0.0], "blackhole: ball vanishes, no accel")
	m.effects.timed.erase("blackhole")
	# 與打磚加速共用上限 1.0
	_unbreakable(m, Vector2i(0, 0))
	m.brick_accel = 0.0
	for i in 99:
		m._ball_hit_brick(Vector2i(0, 0))
	for i in 3:
		b.pos = Vector2(180, py - 4)
		b.dir = Vector2(0, 1)
		m._ball_paddle(b, left, length, py)
	_eq(is_equal_approx(m.brick_accel, 1.0), true, "paddle + brick share cap 1.0 (%.4f)" % m.brick_accel)
	# 多球同一幀各自撞擋板:各加一次
	m.brick_accel = 0.0
	var arr := []
	for x in [160.0, 180.0, 200.0]:
		var nb = main_script.Ball.new()
		nb.pos = Vector2(x, py - 4)
		nb.dir = Vector2(0, 1)
		arr.append(nb)
	m.balls.assign(arr)
	m._update_balls(0.01)
	_eq(is_equal_approx(m.brick_accel, 0.015), true, "3 balls hit paddle same frame: +0.015 (%.4f)" % m.brick_accel)
	m.free()


## 擋板中心以畫出來的中心(左緣取整後 + 長度/2)為準:正中央反彈 0 度、吸附球置中。
func _test_paddle_center() -> void:
	for length in [85, 205, 32]:
		var m := _bare_main()
		_empty_grid(m)
		m.cfg.paddle_base_length = length
		_eq(m._paddle_len(), length, "paddle length %d" % length)
		var left: int = m._paddle_left(length)
		var center: float = left + length / 2.0
		var py: int = m._paddle_y()
		var b = load("res://scripts/main.gd").Ball.new()
		b.pos = Vector2(center, py - 4)
		b.dir = Vector2(0, 1)
		m._ball_paddle(b, left, length, py)
		_eq(b.dir.is_equal_approx(Vector2.UP), true, "len %d: center hit bounces at 0 deg (dir %s)" % [length, b.dir])
		# 吸附:打在畫出來的正中央 → 黏住的球圓心 = 畫出來的中心
		m._apply_item("sticky")
		b.pos = Vector2(center, py - 4)
		b.dir = Vector2(0, 1)
		m._ball_paddle(b, left, length, py)
		m.balls.assign([b])
		m._update_balls(0.01)
		_eq([b.stuck, b.pos.x], [true, center], "len %d: stuck ball centered on drawn paddle" % length)
		# 開局吸附的單顆球也置中
		m.balls.clear()
		m._spawn_start_balls()
		m._update_balls(0.01)
		_eq(m.balls[0].pos.x, center, "len %d: start ball centered" % length)
		m.free()


## 最高速 3.2 倍(+4 階 × 加速上限 2.0 = 768 px/s)逐幀跑 _update_balls:
## 球不會穿過一整排磚(20 高),也不會穿過擋板(16 高,長度 85 與 32)。
## 每幀結束檢查圓心沒越過磚下緣 / 擋板上緣,直到球反彈為止。
func _test_high_speed_no_tunnel() -> void:
	var main_script := load("res://scripts/main.gd")
	var angles := [-70.0, -45.0, -20.0, 0.0, 20.0, 45.0, 70.0]
	for dt in [1.0 / 60.0, 0.05]:
		# 整排不可破壞磚放在第 10 排(y 268~288),球從下方往上打
		var m := _bare_main()
		_empty_grid(m)
		for c in main_script.COLS:
			_unbreakable(m, Vector2i(c, 10))
		m.effects.ball_tier = 4
		m.brick_accel = m.cfg.brick_accel_max
		_eq(is_equal_approx(m._ball_speed(), 768.0), true, "top speed 768 px/s")
		var brick_bottom := 288.0
		for a in angles:
			var dir := Vector2.UP.rotated(deg_to_rad(a))
			var b = main_script.Ball.new()
			b.pos = Vector2(180, brick_bottom + main_script.BALL_R) - dir * 150.0
			b.dir = dir
			m.balls.assign([b])
			var ok := true
			var bounced := false
			for f in 120:
				m._update_balls(dt)
				if b.pos.y <= brick_bottom:
					ok = false
					break
				if b.dir.y > 0.0:
					bounced = true
					break
			_eq([ok, bounced], [true, true], "dt %.3f angle %d: ball bounces off brick row at 3.2x" % [dt, a])
		m.free()
		# 擋板:球從上方往下,瞄準擋板中央與兩端內側
		for length in [85, 32]:
			var p := _bare_main()
			_empty_grid(p)
			p.cfg.paddle_base_length = length
			p.effects.ball_tier = 4
			p.brick_accel = p.cfg.brick_accel_max
			var left: int = p._paddle_left(length)
			var py: int = p._paddle_y()
			for tx in [left + 1.0, left + length / 2.0, left + length - 1.0]:
				for a in angles:
					var dir := Vector2.DOWN.rotated(deg_to_rad(a))
					var b = main_script.Ball.new()
					# 起點只退 60 px,斜 70 度時也不會先撞側牆而改變落點
					b.pos = Vector2(tx, py - main_script.BALL_R) - dir * 60.0
					b.dir = dir
					p.balls.assign([b])
					var ok := true
					var bounced := false
					for f in 120:
						p._update_balls(dt)
						if p.balls.is_empty() or b.pos.y >= py:
							ok = false
							break
						if b.dir.y < 0.0:
							bounced = true
							break
					_eq([ok, bounced], [true, true], "dt %.3f len %d x %.1f angle %d: ball bounces off paddle at 3.2x" % [dt, length, tx, a])
			p.free()


## 規格 A:各限時道具撿到後的秒數;擋板長度以外再撿到累積;沒寫秒數的道具維持整局(不進計時)。
func _test_item_durations() -> void:
	var expect := {"pierce": 20.0, "flame": 20.0, "bomb": 10.0, "sticky": 30.0, "gun": 10.0, "heal": 10.0,
		"heal_area": 10.0, "blackhole": 5.0, "invincible": 10.0, "invisible": 10.0}
	for id in expect:
		var m := _bare_main()
		m._apply_item(id)
		_eq([m.effects.remaining(id), m.effects.total(id)], [expect[id], expect[id]], "%s lasts %d s" % [id, expect[id]])
		m.effects.tick(1.0)
		m._apply_item(id)
		_eq(m.effects.remaining(id), expect[id] * 2.0 - 1.0, "%s picked again accumulates" % id)
		m.free()
	for id in ["paddle_len_1", "paddle_len_2", "paddle_len_down_1", "paddle_len_down_2", "paddle_len_min"]:
		var m := _bare_main()
		m._apply_item(id)
		_eq([m.effects.timed.keys(), m.effects.remaining(Effects.PADDLE_LEN)], [[Effects.PADDLE_LEN], 30.0], "%s uses shared 30 s timer" % id)
		m.free()
	var w := _bare_main()
	for id in ["slow", "fast", "split", "reinforce", "paddle_speed", "paddle_speed_down", "merge", "blackhole_big", "thief",
		"golden_ball", "black_ball"]:
		w._apply_item(id)
	_eq(w.effects.timed.is_empty(), true, "whole-game items are not timed")
	w.free()


## 吸附到期:黏住的球保留到點擊才發射,新碰到擋板的球反彈。槍到期:不再發射,飛行中的子彈照常飛。
func _test_sticky_gun_expiry() -> void:
	var main_script := load("res://scripts/main.gd")
	var m := _bare_main()
	_empty_grid(m)
	var py: int = m._paddle_y()
	m._apply_item("sticky")
	var a = main_script.Ball.new()
	a.pos = Vector2(180, py - 4)
	a.dir = Vector2.DOWN
	m.balls.assign([a])
	m._update_balls(0.01)
	_eq(a.stuck, true, "sticky: ball sticks")
	_eq(m.effects.tick(30.0), ["sticky"] as Array[String], "sticky expires at 30 s")
	m._update_balls(0.5)
	_eq([a.stuck, a.pos.y], [true, py - 8.0], "sticky expired: stuck ball stays on paddle")
	var b = main_script.Ball.new()
	b.pos = Vector2(200, py - 4)
	b.dir = Vector2.DOWN
	m.balls.append(b)
	m._update_balls(0.01)
	_eq([b.stuck, b.dir.y < 0.0], [false, true], "sticky expired: new ball bounces")
	_touch(m, 100, false)
	_eq([a.stuck, a.dir.y < 0.0], [false, true], "sticky expired: stuck ball launches on tap release")
	# 槍
	m._apply_item("gun")
	m._fire_gun()
	_eq(m.bullets.size(), 2, "gun fires 2 bullets")
	m.gun_cd = 0.0
	_eq(m.effects.tick(10.0), ["gun"] as Array[String], "gun expires at 10 s")
	m._fire_gun()
	_eq(m.bullets.size(), 2, "gun expired: no new bullets")
	var y0: float = m.bullets[0].y
	m._update_bullets(0.01)
	_eq([m.bullets.size(), m.bullets[0].y < y0], [2, true], "gun expired: flying bullets keep flying")
	m.free()


## 規格 D:HUD 圖示改用 art/hud32 的 D34 32×32 圖(fever 只對好路徑)。
func _test_hud_icons() -> void:
	var m := _bare_main()
	var bad := []
	for id in ["reinforce", "slow", "fast", "pierce", "flame", "bomb", "fever", "paddle_len_up1", "paddle_len_down1"]:
		var tex: Texture2D = m._t("d34_hud_icon_" + id)
		if tex == null or tex.get_size() != Vector2(32, 32) or tex.resource_path != "res://art/hud32/d34_hud_icon_%s.png" % id:
			bad.append(id)
	_eq(bad, [], "9 D34 HUD icons load from art/hud32 as 32x32")
	m.effects.reinforce = 2
	m.effects.ball_tier = -1
	m._apply_item("pierce")
	m._apply_item("flame")
	m._apply_item("bomb")
	_eq(m._hud_cells().map(func(c: Array) -> String: return c[0]),
		["d34_hud_icon_reinforce", "d34_hud_icon_slow", "d34_hud_icon_pierce", "d34_hud_icon_flame", "d34_hud_icon_bomb"],
		"D34 icons; same-frame gains use fixed order")
	m.effects.ball_tier = 2
	_eq(m._hud_cells()[1][0], "d34_hud_icon_fast", "fast uses D34 icon")
	m.free()


## 規格 E:擋板長度格的顯示條件、圖示、時間條;只有擋板長度格時不亮光暈。
func _test_hud_len_cell() -> void:
	var m := _bare_main()
	_eq(m._hud_len_cell(), [], "no length effect: no cell")
	m._apply_item("paddle_len_1")
	_eq(m._hud_len_cell(), ["d34_hud_icon_paddle_len_up1", {"fill": 20, "color": Pal.W}], "102 > 85: + icon, full bar")
	_eq([m._hud_cells().size(), m._halo_on()], [1, false], "length cell alone: shown in list, no halo")
	m.effects.tick(15.0)
	_eq(m._hud_len_cell()[1]["fill"], 10, "bar = remaining 15 / 30")
	m._apply_item("paddle_len_down_1")
	_eq([m._paddle_len(), m._hud_len_cell()], [82, ["d34_hud_icon_paddle_len_down1", {"fill": 20, "color": Pal.W}]],
		"82 < 85: - icon, bar reset to full")
	# 最後 1 秒閃爍(剩 0.95 → 第 9 個 100 ms 為奇數 → G);減少動態時不閃
	m.effects.tick(29.05)
	_eq(m._hud_len_cell()[1], {"fill": 1, "color": Pal.G}, "last second blinks")
	m.reduced_motion = true
	_eq(m._hud_len_cell()[1]["color"], Pal.W, "reduced motion: no blink")
	m.effects.tick(1.0)
	_eq([m._hud_len_cell(), m._paddle_len()], [[], 85], "expired: no cell, back to 85")
	# 最短化生效中:乘到比 85 長仍顯示 −
	m._apply_item("paddle_len_min")
	for i in 3:
		m._apply_item("paddle_len_2")
	_eq([m._paddle_len() > 85, m._hud_len_cell()[0]], [true, "d34_hud_icon_paddle_len_down1"], "min active: - icon even when > 85")
	m.free()
	# 實際長度剛好 85:不顯示,但計時照走
	var e := _bare_main()
	var old_up: float = e.cfg.len_small_up
	e.cfg.len_small_up = 1.25
	e._apply_item("paddle_len_1")
	e._apply_item("paddle_len_down_1")
	_eq([e._paddle_len(), e._hud_len_cell(), e.effects.is_active(Effects.PADDLE_LEN)], [85, [], true], "length = 85: hidden, timer runs")
	e.cfg.len_small_up = old_up
	e.free()


## 本幀更新後的獲得順序清單(轉成一般陣列方便比對)。
func _order(m: Node2D) -> Array:
	m._hud_cells()
	var out := []
	out.assign(m.hud_order)
	return out


## D35:HUD 依獲得順序排列(R1~R12)、光暈條件。
func _test_hud_order() -> void:
	var m := _bare_main()
	_eq(_order(m), [], "empty list")
	# R1 新獲得接在最後;R2 移除後補位、再獲得排最後
	m._apply_item("flame")
	_eq(_order(m), ["flame"], "R1 flame")
	m.effects.tick(15.0)
	m._apply_item("reinforce")
	_eq(_order(m), ["flame", "reinforce"], "R1 reinforce appended")
	m._apply_item("bomb")
	_eq(_order(m), ["flame", "reinforce", "bomb"], "R1 bomb appended")
	m.effects.tick(5.0)
	_eq(_order(m), ["reinforce", "bomb"], "R2 flame expired: rest move up")
	m._apply_item("flame")
	_eq(_order(m), ["reinforce", "bomb", "flame"], "R2 flame again counts as new")
	# R3 存在中再獲得:位置不動,只更新內容
	m._apply_item("flame")
	m._apply_item("reinforce")
	_eq(_order(m), ["reinforce", "bomb", "flame"], "R3 same kind again: order kept")
	_eq(m._hud_cells()[0][1]["filled"], 2, "R3 reinforce bar updated to 2")
	# R11 同一幀到期又再獲得:視為一直存在
	m.effects.tick(m.effects.remaining("bomb"))
	m._apply_item("bomb")
	_eq(_order(m), ["reinforce", "bomb", "flame"], "R11 expire + regain same frame: order kept")
	m.free()

	# R4 速度淨階數歸 0 移除,再非 0 排最後;R5 一次跨過 0 位置不動、只換圖示
	var s := _bare_main()
	s._apply_item("fast")
	_order(s)
	s._apply_item("reinforce")
	_eq(_order(s), ["speed", "reinforce"], "R4 setup")
	s._apply_item("slow")
	_eq(_order(s), ["reinforce"], "R4 net 0: speed removed")
	s._apply_item("slow")
	_eq([_order(s), s._hud_cells()[1][0]], [["reinforce", "speed"], "d34_hud_icon_slow"], "R4 non-zero again: appended")
	s._apply_item("bomb")
	s.effects.ball_tier = 1
	_eq([_order(s), s._hud_cells()[1][0]], [["reinforce", "speed", "bomb"], "d34_hud_icon_fast"], "R5 jump over 0: same slot, icon flips")
	s.free()

	# R6 擋板長度回到 85 移除,再 ≠ 85 排最後;R7 +/− 翻轉沒經過 85 位置不動
	var p := _bare_main()
	p._apply_item("paddle_len_1")
	_order(p)
	p._apply_item("reinforce")
	_eq(_order(p), [Effects.PADDLE_LEN, "reinforce"], "R6 setup")
	p.effects.tick(30.0)
	_eq(_order(p), ["reinforce"], "R6 back to 85: removed")
	p._apply_item("paddle_len_down_1")
	_order(p)
	p._apply_item("bomb")
	_eq([_order(p), p._hud_cells()[1][0]], [["reinforce", Effects.PADDLE_LEN, "bomb"], "d34_hud_icon_paddle_len_down1"],
		"R6 != 85 again: appended (then bomb)")
	p._apply_item("paddle_len_2")
	_eq([p._paddle_len() > 85, _order(p), p._hud_cells()[1][0]],
		[true, ["reinforce", Effects.PADDLE_LEN, "bomb"], "d34_hud_icon_paddle_len_up1"], "R7 - to + without 85: same slot")
	p.free()

	# R10 同一幀多個新增依固定順序;先移除再新增
	var f := _bare_main()
	for id in ["paddle_len_1", "bomb", "flame", "pierce", "fast", "reinforce"]:
		f._apply_item(id)
	_eq(_order(f), ["reinforce", "speed", "pierce", "flame", "bomb", Effects.PADDLE_LEN], "R10 same-frame gains in fixed order")
	f.effects.tick(10.0)
	f.effects.reinforce = 0
	_eq(_order(f), ["speed", "pierce", "flame", Effects.PADDLE_LEN], "bomb and reinforce gone")
	# 同一幀:穿透、火焰到期,同時獲得炸彈與強化 → 先移除,再依固定順序(強化 → 炸彈)接在最後
	f.effects.tick(10.0)
	f._apply_item("bomb")
	f._apply_item("reinforce")
	_eq(_order(f), ["speed", Effects.PADDLE_LEN, "reinforce", "bomb"], "R10 removals first, then same-frame gains in fixed order")
	f.free()

	# R8 附魔開局建立、永不移除;附魔與限時穿透同時在開局時穿透在前
	var a := _bare_main()
	a.effects.enchant = "flame"
	_eq(_order(a), ["flame"], "R8 enchant flame built at start")
	a._apply_item("reinforce")
	a._apply_item("flame")
	a.effects.tick(1000.0)
	_eq(_order(a), ["flame", "reinforce"], "R8 enchant never removed, regain keeps slot")
	a.free()
	var b := _bare_main()
	b.effects.enchant = "flame"
	b._apply_item("pierce")
	_eq(_order(b), ["pierce", "flame"], "R8/R10 start: pierce before flame")
	b.free()
	# R12 重玩 = 場景重新載入、新實例:清單只由附魔重建
	var r := _bare_main()
	r.effects.enchant = "pierce"
	_eq(_order(r), ["pierce"], "R12 fresh game: only enchant")
	r.free()

	# fever 玩法未做:球數 ≥ 50 也不出現
	var v := _bare_main()
	for i in 60:
		v.balls.append(load("res://scripts/main.gd").Ball.new())
	_eq(_order(v), [], "fever not implemented: never in list")
	# 光暈:清單中有非擋板長度的格才亮
	_eq(v._halo_on(), false, "halo off: empty")
	v._apply_item("paddle_len_down_1")
	_order(v)
	_eq(v._halo_on(), false, "halo off: only length")
	v._apply_item("bomb")
	_order(v)
	_eq(v._halo_on(), true, "halo on: length + bomb")
	v.effects.tick(10.0)
	_order(v)
	_eq(v._halo_on(), false, "halo off: bomb gone")
	v.free()


## D36:8 種新 HUD 格(圖示、線段條、到期補位)、同幀固定順序、不觸發光暈。
func _test_hud_d36() -> void:
	var timed := ["sticky", "gun", "heal", "heal_area", "blackhole", "invincible", "invisible"]
	var t := _bare_main()
	var bad := []
	for id in timed + ["paddle_speed_up", "paddle_speed_down"]:
		var tex: Texture2D = t._t("d34_hud_icon_" + id)
		if tex == null or tex.get_size() != Vector2(32, 32) or tex.resource_path != "res://art/hud32/d34_hud_icon_%s.png" % id:
			bad.append(id)
	_eq(bad, [], "9 D36 HUD icons load from art/hud32 as 32x32")
	t.free()
	# 各限時種類:剛獲得滿條、總時間取 dur_<id>、到期移除;只有新種類時不亮光暈
	for id in timed:
		var m := _bare_main()
		m._apply_item(id)
		_eq([_order(m), m._hud_cells()[0], m._halo_on()], [[id], ["d34_hud_icon_" + id, {"fill": 20, "color": Pal.W}], false],
			"%s: icon, full bar, no halo" % id)
		var dur: float = m.cfg.get("dur_" + id)
		m.effects.tick(dur / 2.0)
		_eq(m._hud_cells()[0][1]["fill"], 10, "%s: half of dur_%s" % [id, id])
		m.effects.tick(dur)
		_eq(_order(m), [], "%s: expired, removed" % id)
		m.free()
	# 黑洞 5 秒:最後 1 秒照常閃爍(剩 0.95 → G)
	var h := _bare_main()
	h._apply_item("blackhole")
	h.effects.tick(4.05)
	_eq(h._hud_cells()[0][1], {"fill": 4, "color": Pal.G}, "blackhole last second blinks")
	h.free()
	# 擋板移動速度:分階線段,+ 4 段、− 3 段;一次跨過 0 位置不動只換圖;歸 0 移除後面補位
	var p := _bare_main()
	p._apply_item("paddle_speed")
	p._apply_item("paddle_speed")
	_eq([_order(p), p._hud_cells()[0], p._halo_on()],
		[["paddle_speed"], ["d34_hud_icon_paddle_speed_up", {"segments": 4, "filled": 2}], false], "paddle speed +2: 4 segments, no halo")
	p._apply_item("sticky")
	p.effects.paddle_tier = -1
	_eq([_order(p), p._hud_cells()[0]], [["paddle_speed", "sticky"], ["d34_hud_icon_paddle_speed_down", {"segments": 3, "filled": 1}]],
		"paddle speed jump over 0: same slot, - icon, 3 segments")
	p._apply_item("paddle_speed")
	_eq(_order(p), ["sticky"], "paddle speed net 0: removed, sticky moves up")
	# 新種類 + 擋板長度仍不亮;加入原本的球狀態才亮
	p._apply_item("paddle_len_1")
	_order(p)
	_eq(p._halo_on(), false, "length + new kinds: no halo")
	p._apply_item("pierce")
	_order(p)
	_eq(p._halo_on(), true, "pierce: halo on")
	p.free()
	# 同一幀同時新出現:依 HUD_KINDS 固定順序
	var f := _bare_main()
	for id in ["invisible", "invincible", "blackhole", "heal_area", "heal", "gun", "sticky", "paddle_speed_down", "paddle_len_1", "bomb"]:
		f._apply_item(id)
	_eq(_order(f), ["bomb", Effects.PADDLE_LEN, "paddle_speed", "sticky", "gun", "heal", "heal_area", "blackhole", "invincible", "invisible"],
		"D36 same-frame gains in fixed order")
	f.free()


## D35 方案 C 格位:每欄格數 = floor((H − 473) / 52),欄由左到右、欄內由上到下;跨欄補位。
func _test_hud_slots() -> void:
	var m := _bare_main()
	var expect := {
		800: [Vector2(24, 424), Vector2(24, 476), Vector2(24, 528), Vector2(24, 580), Vector2(24, 632), Vector2(24, 684), Vector2(76, 424)],
		707: [Vector2(24, 424), Vector2(24, 476), Vector2(24, 528), Vector2(24, 580), Vector2(76, 424), Vector2(76, 476), Vector2(76, 528)],
		640: [Vector2(24, 424), Vector2(24, 476), Vector2(24, 528), Vector2(76, 424), Vector2(76, 476), Vector2(76, 528), Vector2(128, 424)],
	}
	for h in expect:
		m.view_h = h
		_eq(range(7).map(func(i: int) -> Vector2: return m._hud_slot(i)), expect[h], "H %d: 7 slots" % h)
	# 707 高:第 5 格在第 2 欄;前面一格結束後跨欄補到第 1 欄最後一格
	m.view_h = 707
	for id in ["reinforce", "fast", "pierce", "flame", "bomb"]:
		m._apply_item(id)
	_order(m)
	_eq(m._hud_slot(m.hud_order.find("bomb")), Vector2(76, 424), "707: 5th cell in column 2")
	m.effects.reinforce = 0
	_order(m)
	_eq(m._hud_slot(m.hud_order.find("bomb")), Vector2(24, 580), "707: cross-column refill")
	m.free()


## BUG-1:擋板長度到期或變長的那一幀,擋板就在牆內(左右都夾在 20~340)。
func _test_paddle_in_wall_on_len_change() -> void:
	var main_script := load("res://scripts/main.gd")
	var m := _bare_main()
	_empty_grid(m)
	m.time_left = 100.0
	var ball = main_script.Ball.new()
	ball.stuck = true
	m.balls.assign([ball])
	m._apply_item("paddle_len_down_1")
	m.target_x = 1000.0
	m._update_paddle(10.0)
	_eq(m._paddle_left(68) + 68, 340, "short paddle at right wall")
	m.effects.tick(29.99)
	m._step(0.02)
	var left: int = m._paddle_left(m._paddle_len())
	_eq([m._paddle_len(), left, left + m._paddle_len()], [85, 255, 340], "expiry frame: back to 85 and inside right wall")
	# 貼牆時變長:同一幀就夾回牆內
	m._apply_item("paddle_len_2")
	var len2: int = m._paddle_len()
	_eq(m._paddle_left(len2) + len2, 340, "grow at right wall: inside wall at once")
	m.target_x = -1000.0
	m._update_paddle(10.0)
	m._apply_item("paddle_len_2")
	_eq(m._paddle_left(m._paddle_len()), 20, "grow at left wall: inside wall at once")
	m.free()
