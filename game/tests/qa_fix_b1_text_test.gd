## QA 重測:B1(結束後不再加分/生效)與道具說明文字由設定檔代入。
## 執行:Godot --headless --path game --script res://tests/qa_fix_b1_text_test.gd
## 全部通過時結束碼 0,有失敗時結束碼 1。
extends SceneTree

const MainScene := preload("res://scenes/main.tscn")
const MainScript := preload("res://scripts/main.gd")
const DOC := "../docs/design/ui-menus.md"

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
	cfg.drop_chance = 0.0   # 不讓破壞磚掉落干擾
	_run("b1_win_ball_same_frame", _t_win_ball_same_frame)
	_run("b1_win_bullet_same_frame", _t_win_bullet_same_frame)
	_run("b1_win_bomb_same_frame", _t_win_bomb_same_frame)
	_run("b1_win_pierce_end_same_frame", _t_win_pierce_end_same_frame)
	_run("b1_time_up", _t_time_up)
	_run("b1_balls_gone", _t_balls_gone)
	_run("b1_after_end_frames", _t_after_end_frames)
	_run("b1_playing_still_scores", _t_playing_still_scores)
	cfg.drop_chance = 0.3
	_run("text_d29_exact", _t_text_d29_exact)
	_run("text_values_format", _t_text_values_format)
	_run("text_follows_config", _t_text_follows_config)
	_run("text_menu_a11y", _t_text_menu_a11y)
	print("QA FIX RESULT: %d passed, %d failed" % [_passed, _failed])
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

func _fresh():
	var m = MainScene.instantiate()
	root.add_child(m)
	m.rng.seed = 999
	# 40×20 規格:格子 8 欄 × 17 排
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
	m.time_left = 100.5
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
	b.dir = dir
	m.balls.append(b)
	return b


## 在擋板上方放一個這一幀會被接到的道具。
func _item_on_paddle(m, id: String) -> void:
	m.items.append({"id": id, "pos": Vector2(172, m._paddle_y() - 16.5)})


func _end_text_score(m) -> int:
	for ui in m.get_children():
		if ui is Control and not ui is ChoiceMenu:
			for ch in ui.get_children():
				if ch is Label:
					var parts: PackedStringArray = ch.text.split("分數 ")
					return int(parts[parts.size() - 1])
	return -1


func _snapshot(m) -> Dictionary:
	# 2026-10-28:吸附、槍改為限時效果(effects.timed),擋板長度改為 paddle_factor + 共用計時
	return {"score": m.score, "ball_tier": m.effects.ball_tier, "paddle_tier": m.effects.paddle_tier,
		"reinforce": m.effects.reinforce, "sticky": m.effects.is_active("sticky"), "gun": m.effects.is_active("gun"),
		"paddle_factor": m.effects.paddle_factor, "paddle_min": m.effects.paddle_min,
		"timed": m.effects.timed.keys(), "menu_queue": m.menu_queue.size(), "balls": m.balls.size()}


# 「擋板最大化」已移除,改用擋板大幅增加(仍是長度效果)
const ALL_EFFECT_ITEMS := ["thief", "split", "gun", "sticky", "pierce", "fast", "paddle_speed",
	"reinforce", "golden_ball", "black_ball", "merge", "invincible", "paddle_len_2"]


# ---------- B1 ----------

## 球打破最後一塊磚過關,同一幀接到各種道具:不加分、不生效、道具消失、結束畫面分數 = score。
func _t_win_ball_same_frame() -> void:
	var m = _fresh()
	_brick(m, 4, 0, 1)
	var r: Rect2 = m._cell_rect(Vector2i(4, 0))
	# 2 倍規格:球半徑 8,離磚下緣 8.5 = 開始時沒碰到、這一幀內碰到(原半徑 4 時是 4.5)
	_ball(m, Vector2(r.get_center().x, r.end.y + 8.5), Vector2.UP)
	_ball(m, Vector2(100, 600), Vector2.UP)   # 第二顆球,讓 split/merge 有可觀察的變化
	m.score = 10000
	for id in ALL_EFFECT_ITEMS:
		_item_on_paddle(m, id)
	var tl: float = m.time_left
	m._step(0.016)
	_eq(m.state, 1, "won this frame")
	var expect: int = 10000 + 300 + Rules.time_bonus(tl - 0.016, cfg.score_per_second)
	_eq(m.score, expect, "score = before + brick + time bonus only")
	_eq(_end_text_score(m), m.score, "end screen score equals score")
	_eq(m.items.size(), 0, "items still disappear")
	_eq(m.balls.size(), 2, "split/merge not applied")
	_eq([m.effects.ball_tier, m.effects.paddle_tier, m.effects.reinforce, m.effects.is_active("sticky"),
		m.effects.is_active("gun"), m.effects.paddle_factor], [0, 0, 0, false, false, 1.0], "effects not applied")
	_eq(m._paddle_len(), 85, "paddle length unchanged")
	_eq(m.effects.timed.size(), 0, "timed effects not applied")
	_eq(m.menu_queue.size(), 0, "golden/black ball not queued")
	var anims_pickup: int = m.anims.filter(func(a) -> bool: return a["kind"] == "pickup").size()
	_eq(anims_pickup, 0, "no pickup animation after end")
	m.free()


## 子彈打破最後一塊磚過關,同一幀接到道具。
func _t_win_bullet_same_frame() -> void:
	var m = _fresh()
	_ball(m, Vector2(100, 600), Vector2.UP)
	m._apply_item("gun")
	var len: int = m._paddle_len()
	var left: int = m._paddle_left(len)
	var bx: float = left + 2
	# 40×20 規格:磚寬 40、最後一排第 16 排、磚區下緣 68 + 17 × 20 = 408
	var c := floori((bx + 1 - 20) / 40.0)
	_brick(m, c, 16, 1)
	var bottom: float = 68 + 17 * 20
	m.bullets.append(Vector2(bx, bottom + 2))
	m.bullets.append(Vector2(bx, bottom + 4))   # 第二發,過關後同一幀
	m.score = 10000
	_item_on_paddle(m, "thief")
	_item_on_paddle(m, "split")
	var tl: float = m.time_left
	m._step(0.016)
	_eq(m.state, 1, "won by bullet")
	_eq(m.score, 10000 + 300 + Rules.time_bonus(tl - 0.016, cfg.score_per_second), "no score after bullet win")
	_eq(_end_text_score(m), m.score, "end screen score equals score")
	_eq(m.balls.size(), 1, "split not applied")
	m.free()


## 炸彈到期爆炸過關(道具計時在球、道具之前更新),同一幀接到道具、球撞磚。
func _t_win_bomb_same_frame() -> void:
	var m = _fresh()
	var br = _brick(m, 4, 5, 1)
	br.marked = true
	_brick(m, 0, 0, 1, true)
	_ball(m, Vector2(100, 600), Vector2.UP)
	m.effects.add_timed("bomb", 0.01)
	m.score = 5000
	_item_on_paddle(m, "thief")
	_item_on_paddle(m, "fast")
	var tl: float = m.time_left
	m._step(0.016)
	_eq(m.state, 1, "won by bomb explosion")
	_eq(m.score, 5000 + 300 + Rules.time_bonus(tl - 0.016, cfg.score_per_second), "no score after bomb win")
	_eq(_end_text_score(m), m.score, "end screen score equals score")
	_eq(m.effects.ball_tier, 0, "fast not applied")
	m.free()


## 穿透到期、球所在的最後一塊磚被直接破壞過關,同一幀接到道具。
func _t_win_pierce_end_same_frame() -> void:
	var m = _fresh()
	_brick(m, 7, 16, 3)   # 40×20 規格:最後一格 (7, 16)
	var r: Rect2 = m._cell_rect(Vector2i(7, 16))
	_ball(m, r.get_center(), Vector2.UP)
	m.effects.add_timed("pierce", 0.01)
	_item_on_paddle(m, "golden_ball")
	var tl: float = m.time_left
	m._step(0.016)
	_eq(m.state, 1, "won by pierce end")
	_eq(m.score, 300 + 200 + Rules.time_bonus(tl - 0.016, cfg.score_per_second), "no score after pierce-end win")
	_eq(m.menu_queue.size(), 0, "golden ball not queued")
	_eq(_end_text_score(m), m.score, "end screen score equals score")
	m.free()


## 時間到:同一幀不移動球、子彈、道具,分數不變。
func _t_time_up() -> void:
	var m = _fresh()
	# 40×20 規格:最後一排第 16 排、磚區下緣 68 + 17 × 20、球半徑 8(離磚 8.5)
	_brick(m, 4, 0, 3)
	_brick(m, 0, 16, 3)
	var r: Rect2 = m._cell_rect(Vector2i(4, 0))
	_ball(m, Vector2(r.get_center().x, r.end.y + 8.5), Vector2.UP)
	m.bullets.append(Vector2(22, 68 + 17 * 20 + 2))
	_item_on_paddle(m, "thief")
	m.score = 1234
	m.time_left = 0.01
	m._step(0.02)
	_eq(m.state, 1, "ended on time up")
	_eq(m.score, 1234, "no score change on time-up frame")
	_eq([m.grid[0][4].layers, m.grid[16][0].layers], [3, 3], "no brick damage on time-up frame")
	_eq(_end_text_score(m), 1234, "end screen score equals score")
	m.free()


## 球全部消失:結束判定在本幀最後;記錄同一幀接到的道具行為,並確認結束畫面分數 = score。
func _t_balls_gone() -> void:
	var m = _fresh()
	# 2 倍規格:哨兵移到第 4 欄;球半徑 8,球心在 view_h + 7.5 = 上緣仍在畫面內、這一幀掉出(原半徑 4 時是 + 3.5)
	_brick(m, 4, 0, 69)
	_ball(m, Vector2(100, m.view_h + 7.5), Vector2.DOWN)
	_item_on_paddle(m, "slow")
	m._step(0.016)
	_eq(m.state, 1, "ended when last ball falls out")
	print("INFO balls gone + same-frame pickup: score=%d (pickup happens before end check)" % m.score)
	_eq(_end_text_score(m), m.score, "end screen score equals score")
	# 結束後不再改變
	var snap := _snapshot(m)
	for i in 30:
		m._process(0.05)
	_eq(_snapshot(m), snap, "no change in later frames")
	m.free()
	# 開局就沒有球:直接結束
	var m2 = _fresh()
	_brick(m2, 4, 0, 69)
	m2._step(0.016)
	_eq([m2.state, m2.score, _end_text_score(m2)], [1, 0, 0], "no balls -> end, score 0")
	m2.free()


## 結束後:直接呼叫 _pickup、子彈更新、輸入,都不影響分數與效果。
func _t_after_end_frames() -> void:
	var m = _fresh()
	# 40×20 規格:哨兵第 4 欄、最後一排第 16 排、磚區下緣 68 + 17 × 20
	_brick(m, 4, 0, 69)
	_brick(m, 0, 16, 3)
	_ball(m, Vector2(100, 600), Vector2.UP)
	m.score = 8000
	m._end(false, "test")
	var snap := _snapshot(m)
	for id in ItemDefs.BUFF + ItemDefs.DEBUFF:
		m._pickup(id, Vector2(100, 600))
	_eq(_snapshot(m), snap, "_pickup of all 26 items after end: no change")
	m.bullets.append(Vector2(22, 68 + 17 * 20 + 2))
	m._update_bullets(0.016)
	_eq([m.score, m.grid[16][0].layers], [8000, 3], "bullet after end: no damage / score")
	m._update_anims(1.0)
	_eq(m.score, 8000, "anims after end: no score")
	m._apply_item("gun")
	var t := InputEventScreenTouch.new()
	t.index = 0
	t.pressed = true
	t.position = Vector2(30, 400)
	m._unhandled_input(t)
	_eq(m.bullets.size(), 0, "input ignored after end")
	m._end(true, "again")
	_eq(m.score, 8000, "second _end ignored (no time bonus)")
	m.free()


## 回歸:遊戲中撿道具照常加分、生效。
func _t_playing_still_scores() -> void:
	var m = _fresh()
	_brick(m, 4, 0, 69)   # 2 倍規格:哨兵移到第 4 欄
	_ball(m, Vector2(100, 600), Vector2.UP)
	_item_on_paddle(m, "slow")
	_item_on_paddle(m, "fast")
	_item_on_paddle(m, "golden_ball")
	m._step(0.016)
	_eq(m.state, 0, "still playing")
	_eq(m.score, 200 + 50 + 200, "pickups score while playing")
	_eq(m.effects.ball_tier, 0, "slow + fast net 0")
	_ok(m.menu != null, "golden ball menu opens while playing")
	m.free()


# ---------- 說明文字 ----------

## 直接解析 D29 第六節表格,與 ItemDefs 比對(預設設定)。
func _t_text_d29_exact() -> void:
	var path := ProjectSettings.globalize_path("res://").path_join(DOC).simplify_path()
	var f := FileAccess.open(path, FileAccess.READ)
	_ok(f != null, "open D29 doc %s" % path)
	if f == null:
		return
	var rows := {}
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if not line.begins_with("| `item_"):
			continue
		var cols := line.split("|")
		var id := cols[1].strip_edges().trim_prefix("`item_").trim_suffix("`")
		var name := cols[2].strip_edges().replace("（僅重複關卡）", "")
		var desc := Array(cols[3].strip_edges().split("｜"))
		rows[id] = [name, desc, int(cols[5].strip_edges().replace("*", ""))]
	# 2026-10-28 道具秒數修訂:刪除「擋板最大化」列,共 24 種
	_eq(rows.size(), 24, "D29 table has 24 items")
	_ok(not rows.has("paddle_len_max"), "D29 table has no paddle_len_max")
	for id in rows:
		_ok(ItemDefs.exists(id), "D29 id exists in ItemDefs: %s" % id)
		if not ItemDefs.exists(id):
			continue
		_eq(ItemDefs.item_name(id), rows[id][0], "name %s" % id)
		_eq(ItemDefs.desc_lines(id), rows[id][1], "desc %s" % id)
		_eq(ItemDefs.desc_lines(id).size(), rows[id][2], "line count %s" % id)
	var missing := []
	for id in ItemDefs.BUFF + ItemDefs.DEBUFF:
		if not rows.has(id):
			missing.append(id)
	print("INFO ItemDefs ids not in D29 table: %s; their text: %s / %s" % [missing,
		ItemDefs.desc_lines("golden_ball"), ItemDefs.desc_lines("black_ball")])
	_eq(missing, ["golden_ball", "black_ball"], "only ball items are outside D29 table")


func _t_text_values_format() -> void:
	# 2026-10-28:單一 effect_duration 改為各道具 dur_*;格式規則不變
	var c := GameConfig.new()
	c.dur_pierce = 5.0
	c.len_small_up = 1.2
	c.len_big_up = 2.0
	c.len_small_down = 0.75
	c.len_big_down = 0.5
	var v := ItemDefs._values(c)
	_eq([v["dur_pierce"], v["len_small_up"], v["len_big_up"], v["len_small_down"], v["len_big_down"]],
		["5", "1.2", "2", "0.75", "0.5"], "float formatting")
	c.dur_pierce = 7.5
	_eq(ItemDefs._values(c)["dur_pierce"], "7.5", "7.5 stays 7.5")
	c.dur_pierce = 10.0
	_eq(ItemDefs._values(c)["dur_pierce"], "10", "10.0 -> 10")
	c.dur_pierce = 0.5
	_eq(ItemDefs._values(c)["dur_pierce"], "0.5", "0.5 stays 0.5")
	c.dur_pierce = 0.0
	_eq(ItemDefs._values(c)["dur_pierce"], "0", "0.0 -> 0")
	c.dur_pierce = 120.25
	_eq(ItemDefs._values(c)["dur_pierce"], "120.25", "120.25 stays")
	c.thief_min = 0
	c.thief_max = 100000
	_eq([ItemDefs._values(c)["thief_min"], ItemDefs._values(c)["thief_max"]], ["0", "100000"], "int values")
	for k in v:
		_ok(v[k] is String, "value %s is String" % k)


func _all_text() -> String:
	var s := ""
	for id in ItemDefs.TEXT:
		s += ItemDefs.item_name(id) + "|" + "|".join(ItemDefs.desc_lines(id)) + "\n"
	return s


func _t_text_follows_config() -> void:
	# 2026-10-28:各道具秒數獨立(dur_*),每個設不同值,確認每條說明對到自己的欄位
	var keys := ["dur_paddle_len", "dur_pierce", "dur_flame", "dur_bomb", "dur_sticky", "dur_gun",
		"dur_heal", "dur_heal_area", "dur_blackhole", "dur_invincible", "dur_invisible",
		"len_small_up", "len_big_up", "len_small_down", "len_big_down",
		"flame_damage", "flame_splash", "reinforce_max", "heal_amount", "heal_area_amount",
		"heal_area_splash", "thief_min", "thief_max"]
	var old := {}
	for k in keys:
		old[k] = cfg.get(k)
	var default_text := _all_text()
	_ok(not ("{" in default_text or "}" in default_text), "defaults: no leftover braces")
	cfg.dur_paddle_len = 31.0
	cfg.dur_pierce = 21.0
	cfg.dur_flame = 22.0
	cfg.dur_bomb = 7.5
	cfg.dur_sticky = 33.0
	cfg.dur_gun = 12.0
	cfg.dur_heal = 13.0
	cfg.dur_heal_area = 14.0
	cfg.dur_blackhole = 6.0
	cfg.dur_invincible = 15.0
	cfg.dur_invisible = 16.0
	cfg.len_small_up = 1.25
	cfg.len_big_up = 2.0
	cfg.len_small_down = 0.7
	cfg.len_big_down = 0.3
	cfg.flame_damage = 3
	cfg.flame_splash = 2
	cfg.reinforce_max = 9
	cfg.heal_amount = 4
	cfg.heal_area_amount = 6
	cfg.heal_area_splash = 5
	cfg.thief_min = 100
	cfg.thief_max = 900
	var expect := {
		"paddle_len_1": ["長度變成1.25倍", "持續31秒"],
		"paddle_len_2": ["長度變成2倍", "持續31秒"],
		"pierce": ["穿過磚塊並減1層", "持續21秒"],
		"flame": ["撞到的磚塊減3層", "周圍一圈減2層", "持續22秒"],
		"bomb": ["撞到的磚塊被標記", "7.5秒後全部爆炸"],
		"reinforce": ["每次撞磚多減1層", "最多加9層"],
		"sticky": ["球碰到擋板會黏住", "點一下才發射", "持續33秒"],
		"gun": ["點畫面，兩端各射1發", "減1層 不觸發功能磚", "持續12秒"],
		"paddle_len_down_1": ["長度變成0.7倍", "持續31秒"],
		"paddle_len_down_2": ["長度變成0.3倍", "持續31秒"],
		"paddle_len_min": ["縮到最短，持續31秒"],
		"heal": ["撞到的磚塊加4層", "持續13秒"],
		"heal_area": ["撞到的磚塊加6層", "周圍一圈加5層", "持續14秒"],
		"blackhole": ["球碰到擋板就消失", "持續6秒"],
		"invincible": ["所有磚塊無法破壞", "魔王除外，持續15秒"],
		"invisible": ["擋板變成透明", "持續16秒"],
		"thief": ["偷走100到900分", "分數最低到0"],
	}
	for id in expect:
		_eq(ItemDefs.desc_lines(id), expect[id], "changed config text %s" % id)
	var changed_text := _all_text()
	_ok(not ("{" in changed_text or "}" in changed_text), "changed: no leftover braces")
	# 沒有佔位的說明不應受影響
	for id in ["slow", "split", "golden_ball", "paddle_speed", "fast",
			"paddle_speed_down", "merge", "blackhole_big", "black_ball"]:
		_eq(changed_text.contains(ItemDefs.item_name(id)), true, "name kept %s" % id)
	for k in keys:
		cfg.set(k, old[k])
	_eq(_all_text(), default_text, "restored config -> default text again")


## 3 選 1 畫面的讀屏標籤也用代入後的文字。
func _t_text_menu_a11y() -> void:
	var menu := ChoiceMenu.new()
	menu.setup(false, ["thief", "invincible", "heal_area"], 800, false)
	root.add_child(menu)
	var names := []
	for o in menu._options:
		names.append(o.accessibility_name)
	_eq(names, ["小偷，偷走500到5000分，分數最低到0，按兩下選擇",
		"無敵，所有磚塊無法破壞，魔王除外，持續10秒，按兩下選擇",
		"範圍回血，撞到的磚塊加2層，周圍一圈加1層，持續10秒，按兩下選擇"], "a11y labels with substituted values")
	menu.free()
