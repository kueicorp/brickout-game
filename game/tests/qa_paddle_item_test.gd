## QA 獨立驗證:擋板相對滑動、道具 40×40(D32 items40,原 32×32)、回血規則(headless)。
## 執行:Godot --headless --path game --script res://tests/qa_paddle_item_test.gd
## 全部通過時結束碼 0;輸出不應出現 SCRIPT ERROR。
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


func _process(_delta: float) -> bool:
	if _started:
		return false
	_started = true
	cfg = load("res://data/game_config.tres") as GameConfig
	cfg.level_path = LEVEL
	_run("tap_no_move", _t_tap_no_move)
	_run("drag_both_dirs", _t_drag_both_dirs)
	_run("speed_tiers", _t_speed_tiers)
	_run("leftover", _t_leftover)
	_run("edges", _t_edges)
	_run("length_change", _t_length_change)
	_run("second_finger", _t_second_finger)
	_run("gun_launch_sticky", _t_gun_launch_sticky)
	_run("menu_end_block", _t_menu_end_block)
	_run("item_center", _t_item_center)
	_run("item_catch_edges", _t_item_catch_edges)
	_run("item_fall_remove", _t_item_fall_remove)
	_run("item_offscreen_b4", _t_item_offscreen_b4)
	_run("item_art", _t_item_art)
	_run("items40_art", _t_items40_art)
	_run("items40_drop_draw", _t_items40_drop_draw)
	_run("items40_catch_lengths", _t_items40_catch_lengths)
	_run("items40_catch_states", _t_items40_catch_states)
	_run("items40_side_walls", _t_items40_side_walls)
	_run("items40_pickup_flash", _t_items40_pickup_flash)
	_run("heal_rule", _t_heal_rule)
	print("QA PADDLE/ITEM RESULT: %d passed, %d failed" % [_passed, _failed])
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


func _near(a: float, b: float, label: String) -> void:
	if absf(a - b) < 0.001:
		_passed += 1
	else:
		_failed += 1
		print("FAIL [%s] %s: expected %.3f, got %.3f" % [_section, label, b, a])


# ---------- 輔助 ----------

func _fresh():
	var m = MainScene.instantiate()
	root.add_child(m)
	m.rng.seed = 1
	# 40×20 規格:格子 8 欄 × 17 排;哨兵放最右欄第 7 欄
	for r in MainScript.MAX_ROWS:
		for c in MainScript.COLS:
			m.grid[r][c] = null
	m.breakable_left = 0
	m.items.clear()
	m.score = 0
	_brick(m, 7, 0, 69)  # 哨兵磚,避免意外過關
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


func _one_ball(m, b) -> void:
	m.balls.clear()
	m.balls.append(b)


## 經由視埠送入事件(真實輸入路徑,會經過 _unhandled_input)
func _push_touch(x: float, pressed: bool, index := 0) -> void:
	var e := InputEventScreenTouch.new()
	e.index = index
	e.pressed = pressed
	e.position = Vector2(x, 500)
	root.push_input(e)


func _push_drag(dx: float, index := 0, x := 180.0) -> void:
	var e := InputEventScreenDrag.new()
	e.index = index
	e.position = Vector2(x, 500)
	e.relative = Vector2(dx, 13)
	root.push_input(e)


func _settle(m, sec := 2.0) -> void:
	m._update_paddle(sec)


# ---------- 擋板 ----------

func _t_tap_no_move() -> void:
	var m = _fresh()
	for x in [20.0, 100.0, 330.0, 359.0]:
		_push_touch(x, true)
		_settle(m)
		_eq(m.paddle_x, 180.0, "press at x=%d: no move" % x)
		_push_touch(x, false)
		_settle(m)
		_eq(m.paddle_x, 180.0, "release at x=%d: no move" % x)
	_eq(m.target_x, 180.0, "target unchanged after taps")
	# 跑實際幀,確認 _step 不會把擋板拉向點擊處
	_push_touch(340, true)
	for i in 30:
		m._step(1.0 / 60.0)
	_eq(m.paddle_x, 180.0, "after 30 frames with finger down at 340: no move")
	_push_touch(340, false)
	m.free()


func _t_drag_both_dirs() -> void:
	var m = _fresh()
	_push_drag(25)
	_settle(m)
	_near(m.paddle_x, 205.0, "drag right +25")
	_push_drag(-60)
	_settle(m)
	_near(m.paddle_x, 145.0, "drag left -60")
	# 多個小事件在同一幀累加
	for i in 10:
		_push_drag(3)
	_settle(m)
	_near(m.paddle_x, 175.0, "10 x +3 accumulate")
	# 小數位移
	_push_drag(0.4)
	_push_drag(0.4)
	_settle(m)
	_near(m.paddle_x, 175.8, "fractional drag kept")
	# 只有垂直位移不動
	var e := InputEventScreenDrag.new()
	e.relative = Vector2(0, 80)
	root.push_input(e)
	_settle(m)
	_near(m.paddle_x, 175.8, "vertical-only drag no move")
	# 擋板位移與手指位置無關(手指在最右邊往左滑仍是往左)
	_push_drag(-10, 0, 350.0)
	_settle(m)
	_near(m.paddle_x, 165.8, "relative regardless of finger position")
	m.free()


func _t_speed_tiers() -> void:
	var m = _fresh()
	# 道具把階數夾在 −3~+4
	for i in 10:
		m._apply_item("paddle_speed")
	_eq(m.effects.paddle_tier, 4, "paddle_speed capped at +4")
	for i in 20:
		m._apply_item("paddle_speed_down")
	_eq(m.effects.paddle_tier, -3, "paddle_speed_down capped at -3")
	for t in range(-3, 5):
		m.effects.paddle_tier = t
		m.paddle_x = 100.0
		m.target_x = 100.0
		_push_drag(200)
		m._update_paddle(0.1)
		# 擋板基本速度 600 → 450;每階 ±15% 規則不變
		var expect := 450.0 * (1.0 + 0.15 * t) * 0.1
		_near(m.paddle_x - 100.0, expect, "tier %d moves %.1f in 0.1 s" % [t, expect])
		# 往左同樣受限
		m.paddle_x = 260.0
		m.target_x = 260.0
		_push_drag(-200)
		m._update_paddle(0.1)
		_near(260.0 - m.paddle_x, expect, "tier %d left moves %.1f in 0.1 s" % [t, expect])
	# 透過真實 _step 跑 15 幀,基本速度
	# 新規格:擋板 85,左邊界中心 62.5(= 20 + 42.5;原 128 時 84)
	m.effects.paddle_tier = 0
	m.paddle_x = 62.5
	m.target_x = 62.5
	_push_drag(1000)
	for i in 15:
		m._step(1.0 / 60.0)
	# 450 px/s × 0.25 s = 112.5 px:62.5 → 175(原 600 時 212.5)
	_near(m.paddle_x, 175.0, "15 frames (0.25 s) at 450 px/s via _step")
	m.free()


func _t_leftover() -> void:
	var m = _fresh()
	m.paddle_x = 100.0
	m.target_x = 100.0
	_push_drag(150)
	var xs := []
	for i in 4:
		m._update_paddle(0.1)
		xs.append(snappedf(m.paddle_x, 0.001))
	# 450 px/s 每 0.1 s 走 45 px:145、190、235,第 4 幀到 250 停(原 600 時 160、220、250、250)
	_eq(xs, [145.0, 190.0, 235.0, 250.0], "chase 150 px over frames, stops at target")
	# 追的途中改方向:保留的位移與新位移相加
	m.paddle_x = 100.0
	m.target_x = 100.0
	_push_drag(150)
	m._update_paddle(0.1)   # 145,目標 250
	_push_drag(-120)        # 目標 130
	m._update_paddle(0.1)
	_near(m.paddle_x, 130.0, "reverse mid-chase: target = 100 + 150 - 120")
	m.free()


func _t_edges() -> void:
	var m = _fresh()
	# 新規格:擋板 85,中心範圍 62.5~297.5(= 20 + 42.5 ~ 340 − 42.5;原 128 時 84~276)
	_push_drag(1000)
	_settle(m)
	_near(m.paddle_x, 297.5, "right edge")
	_push_drag(-1)
	m._update_paddle(1.0 / 60.0)
	_near(m.paddle_x, 296.5, "back 1 px from right edge moves next frame")
	_push_drag(1000)
	_settle(m)
	_push_drag(-1000)
	_settle(m)
	_near(m.paddle_x, 62.5, "left edge")
	_eq(m._paddle_left(85), 20, "left edge = field left 20")
	_push_drag(5)
	m._update_paddle(1.0 / 60.0)
	_near(m.paddle_x, 67.5, "back 5 px from left edge moves next frame")
	# 擋板還沒追到邊界時往回滑:超出邊界的位移已丟掉
	m.paddle_x = 100.0
	m.target_x = 100.0
	_push_drag(1000)   # 目標 297.5
	m._update_paddle(0.1)  # 145
	_push_drag(-20)    # 目標 277.5
	_settle(m)
	_near(m.paddle_x, 277.5, "overshoot discarded while still chasing")
	# 右端像素不超出 339
	_push_drag(1000)
	_settle(m)
	var len: int = m._paddle_len()
	_eq(m._paddle_left(len) + len, 340, "paddle right end = 340 (last px 339)")
	m.free()


func _t_length_change() -> void:
	var m = _fresh()
	# 新規格:在右邊界時變長(85 → 102):中心改 340 − 51 = 289,往回滑馬上動(原 154 時 263)
	_push_drag(1000)
	_settle(m)
	m._apply_item("paddle_len_1")
	var len: int = m._paddle_len()
	_eq(len, 102, "len_1 = 102")
	m._update_paddle(1.0 / 60.0)
	_near(m.paddle_x, 289.0, "grow at right edge: clamped to 289")
	_eq(m._paddle_left(len) + len, 340, "grown paddle inside right wall")
	_push_drag(-3)
	m._update_paddle(1.0 / 60.0)
	_near(m.paddle_x, 286.0, "grow then drag back 3: moves immediately")
	# 在左邊界時變長
	_push_drag(-1000)
	_settle(m)
	_near(m.paddle_x, 71.0, "left edge with 102")
	_eq(m._paddle_left(len), 20, "102 left end 20")
	m._apply_item("paddle_len_2")
	len = m._paddle_len()
	m._update_paddle(1.0 / 60.0)
	_eq(m._paddle_left(len), 20, "grow again at left edge stays inside (len %d)" % len)
	_push_drag(4)
	m._update_paddle(1.0 / 60.0)
	_near(m.paddle_x, 20.0 + len / 2.0 + 4.0, "grow at left edge then drag right 4: moves immediately")
	# 長到 320(2026-10-28「擋板最大化」已移除;163 × 1.6 × 1.6 = 417 → 夾到 320):不能動
	m._apply_item("paddle_len_2")
	m._apply_item("paddle_len_2")
	len = m._paddle_len()
	_eq(len, 320, "max 320")
	_push_drag(50)
	m._update_paddle(1.0)
	_near(m.paddle_x, 180.0, "full width: centered")
	_push_drag(-50)
	m._update_paddle(1.0)
	_near(m.paddle_x, 180.0, "full width: drag no move")
	m.free()
	# 變短:在右邊界、變短後可以再往右滑到新邊界
	var m2 = _fresh()
	_push_drag(1000)
	_settle(m2)
	m2._apply_item("paddle_len_min")
	var l2: int = m2._paddle_len()
	print("INFO paddle_len_min length = %d" % l2)
	# 新規格:右邊界中心 297.5(原 128 時 276);效果結束變回 85(原 128)
	_eq(l2, 32, "paddle_len_min = 32")
	m2._update_paddle(1.0)
	_near(m2.paddle_x, 297.5, "shrink at right edge: paddle stays at same center")
	_push_drag(1000)
	_settle(m2)
	_eq(m2._paddle_left(l2) + l2, 340, "shrunk paddle can reach right wall")
	# 縮短效果結束,擋板變回 85:不超出牆
	for id in m2.effects.tick(999.0):
		m2._on_expired(id)
	_eq(m2._paddle_len(), 85, "back to base 85 after expiry")
	m2._update_paddle(1.0 / 60.0)
	_eq(m2._paddle_left(85) + 85, 340, "shrink expired at right wall: back inside")
	_push_drag(-2)
	m2._update_paddle(1.0 / 60.0)
	_near(m2.paddle_x, 295.5, "after expiry, drag back 2 moves immediately")
	m2.free()


func _t_second_finger() -> void:
	var m = _fresh()
	_push_drag(40, 1)
	_push_drag(-40, 2)
	_settle(m)
	_eq(m.paddle_x, 180.0, "drag from finger 1/2 ignored")
	m._apply_item("gun")
	_push_touch(100, true, 1)
	_eq(m.bullets.size(), 0, "second finger tap does not fire gun")
	var b = m.balls[0]
	_ok(b.stuck, "start ball stuck")
	_push_touch(100, false, 1)
	_ok(b.stuck, "second finger release does not launch")
	# 第一根手指按住、第二根手指拖曳時,只有第一根手指的位移算
	_push_touch(200, true, 0)
	_push_drag(30, 0)
	_push_drag(-80, 1)
	_settle(m)
	_near(m.paddle_x, 210.0, "only finger 0 displacement counts")
	m.free()


func _t_gun_launch_sticky() -> void:
	var m = _fresh()
	var b = m.balls[0]
	_ok(b.stuck, "start: ball stuck")
	# 按下拖曳,球跟著擋板,放開才發射
	_push_touch(300, true)
	_ok(b.stuck, "press does not launch")
	_push_drag(40)
	_settle(m)
	m._update_balls(0.0)
	# 新規格:黏住的球以畫出來的中心為準。擋板 85、paddle_x 220 → 左緣 round(177.5) = 178,中心 178 + 42.5 = 220.5
	_eq(b.offset, 0.0, "start ball offset 0 (centered)")
	_near(b.pos.x, 220.5 + b.offset, "stuck ball follows paddle while dragging (drawn center 220.5)")
	_push_touch(300, false)
	_ok(not b.stuck and b.dir.y < 0.0, "release launches")
	_near(m.paddle_x, 220.0, "release does not move paddle")
	# 槍:按下發射、擋板不動
	m._apply_item("gun")
	_push_touch(50, true)
	_eq(m.bullets.size(), 2, "tap fires 2 bullets")
	_settle(m)
	_near(m.paddle_x, 220.0, "gun tap: no move")
	_push_touch(50, false)
	# 吸附
	m._apply_item("sticky")
	b.pos = Vector2(m.paddle_x + 5, m._paddle_y() - 3)
	b.dir = Vector2.DOWN
	var len: int = m._paddle_len()
	m._ball_paddle(b, m._paddle_left(len), len, m._paddle_y())
	_ok(b.stuck, "sticky: ball sticks")
	# 吸附位置以畫出來的中心 220.5 為準:球 x 225 → offset 4.5
	_near(b.offset, 4.5, "sticky offset measured from drawn center 220.5")
	_push_drag(-30)
	_settle(m)
	m._update_balls(0.0)
	_ok(b.stuck, "sticky: drag keeps it stuck")
	# paddle_x 190 → 左緣 round(147.5) = 148,中心 190.5;球 = 190.5 + 4.5 = 195(與擋板的相對位置不變)
	_near(b.pos.x, 190.5 + 4.5, "sticky ball follows paddle drag")
	_push_touch(10, true)
	_ok(b.stuck, "sticky: press does not launch")
	_push_touch(10, false)
	_ok(not b.stuck and b.dir.y < 0.0, "sticky: release launches")
	m.free()


func _t_menu_end_block() -> void:
	var m = _fresh()
	m._apply_item("golden_ball")
	m._step(0.016)
	_ok(m.menu != null, "menu open")
	var x0: float = m.paddle_x
	var t0: float = m.target_x
	_push_drag(80)
	_push_drag(-50)
	_eq(m.target_x, t0, "menu open: drag does not change target")
	m._process(0.5)
	_eq(m.paddle_x, x0, "menu open: paddle not moved")
	# 選單關閉後擋板不會跳
	var menu = m.menu
	menu._process(0.6)
	menu._on_pressed(0)
	menu._process(0.6)
	_ok(m.menu == null, "menu closed")
	m._process(0.05)
	_eq(m.paddle_x, x0, "after menu closes: no jump")
	m.free()
	# 遊戲結束後
	var m2 = _fresh()
	m2._end(false, "test")
	var t2: float = m2.target_x
	_push_drag(100)
	_push_drag(-30)
	_eq(m2.target_x, t2, "ended: drag does not change target")
	m2._update_paddle(1.0)
	_eq(m2.paddle_x, 180.0, "ended: paddle not moved")
	m2.free()


# ---------- 道具 ----------

func _t_item_center() -> void:
	var m = _fresh()
	cfg.debug_force_item = "slow"
	# 40×20 規格:改用 8 × 17 的四角與中間;(7, 0) 是哨兵,改用 (6, 0)
	for cell in [Vector2i(0, 0), Vector2i(6, 0), Vector2i(3, 8), Vector2i(0, 16), Vector2i(7, 16)]:
		m.items.clear()
		_brick(m, cell.x, cell.y, 1)
		m._ball_hit_brick(cell)
		_eq(m.items.size(), 1, "drop from %s" % cell)
		if m.items.size() == 1:
			var r: Rect2 = m._item_rect(m.items[0]["pos"])
			_eq(r.size, Vector2(40, 40), "40x40 at %s" % cell)
			_eq(r.get_center(), m._cell_rect(cell).get_center(), "center = brick center at %s" % cell)
	cfg.debug_force_item = ""
	m.free()


func _catch(m, rect_pos: Vector2) -> bool:
	# rect_pos = 40×40 接取範圍左上角;D32:_item_rect = pos − 12,所以 pos = rect_pos + (12, 12)(原 32×32 為 + 8)
	m.items = [{"id": "slow", "pos": rect_pos + Vector2(12, 12)}]
	m._update_items(0.0)
	return m.items.is_empty()


func _t_item_catch_edges() -> void:
	var m = _fresh()
	m.paddle_x = 180.0
	var len: int = m._paddle_len()
	# 新規格:擋板 85 × 16(原 128 × 16)
	_eq([len, m._paddle_left(len)], [85, 138], "paddle 85 at x 138 when paddle_x = 180")
	var pl: int = m._paddle_left(len)   # 138
	var pr: int = pl + len               # 223(最後一像素 222)
	var py: int = m._paddle_y()          # 上緣
	var pb: int = py + 16
	print("INFO paddle px %d..%d, y %d..%d" % [pl, pr - 1, py, pb - 1])
	var ymid := float(py - 12)
	# 右側:道具最左像素 = 擋板最右像素 → 重疊 1 px 接到;再右 1 px 接不到
	_ok(_catch(m, Vector2(pr - 1, ymid)), "right: 1 px overlap caught")
	_ok(not _catch(m, Vector2(pr, ymid)), "right: adjacent (0 overlap) missed")
	# 左側(40×40:最右像素 = 左上 + 39)
	_ok(_catch(m, Vector2(pl - 39, ymid)), "left: 1 px overlap caught")
	_ok(not _catch(m, Vector2(pl - 40, ymid)), "left: adjacent missed")
	# 上方:道具最下像素 = 擋板最上像素(道具置中 x 160 = 180 − 20)
	_ok(_catch(m, Vector2(180 - 20, py - 39)), "top: 1 px overlap caught")
	_ok(not _catch(m, Vector2(180 - 20, py - 40)), "top: 1 px above missed")
	# 下方(已掉過擋板)
	_ok(_catch(m, Vector2(180 - 20, pb - 1)), "bottom: 1 px overlap caught")
	_ok(not _catch(m, Vector2(180 - 20, pb)), "bottom: below paddle missed")
	# 角落
	_ok(_catch(m, Vector2(pr - 1, py - 39)), "corner 1x1 overlap caught")
	_ok(not _catch(m, Vector2(pr, py - 39)), "corner diagonal adjacent missed")
	# 隱形中也能接
	m._apply_item("invisible")
	_ok(_catch(m, Vector2(pr - 1, ymid)), "invisible paddle still catches")
	m.free()


func _t_item_fall_remove() -> void:
	var m = _fresh()
	_eq(cfg.item_fall_speed, 100.0, "fall speed 100 px/s (config)")
	# 新規格:擋板停在左邊界中心 62.5(原 128 時 84),不擋到 x 250 的道具
	m.paddle_x = 62.5
	m.target_x = 62.5
	m.items = [{"id": "slow", "pos": Vector2(250, 100)}]
	m._update_items(0.1)
	_near(m.items[0]["pos"].y, 110.0, "falls 10 px in 0.1 s")
	_near(m.items[0]["pos"].x, 250.0, "x unchanged while falling")
	# 用真實 _step 跑 60 幀
	m.items = [{"id": "slow", "pos": Vector2(250, 100)}]
	for i in 60:
		m._step(1.0 / 60.0)
	_near(m.items[0]["pos"].y, 200.0, "falls 100 px in 60 frames")
	# 掉出畫面
	var vh: int = m.view_h
	m.items = [{"id": "slow", "pos": Vector2(250, vh - 1)}]
	m._update_items(0.0)
	_eq(m.items.size(), 1, "still kept just above bottom")
	# 40×40:上緣 = pos.y − 12;vh + 25 → 上緣 vh + 13 > view_h,已整張離開畫面
	m.items = [{"id": "slow", "pos": Vector2(250, vh + 25)}]
	m._update_items(0.0)
	_eq(m.items.size(), 0, "removed once 40x40 is fully off screen")
	# B4 新規格:pos.y 越過 view_h 時 40×40 上緣仍在畫面內(約 12 列可見),必須保留
	m.items = [{"id": "slow", "pos": Vector2(250, vh - 0.5)}]
	m._update_items(0.01)
	_eq(m.items.size(), 1, "kept at pos.y > view_h while 40x40 top <= view_h")
	print("INFO item kept until 40x40 rect top (pos.y - 12) > view_h (%d), i.e. pos.y > %d; removed only after the icon is fully off screen" % [vh, vh + 12])
	m.free()


# B4 回歸:邊界值、逐幀掉落、底部接取
func _item_top_kept(m, top: float) -> bool:
	# 40×40 上緣 = pos.y − 12(原 32×32 為 − 8)
	m.items = [{"id": "slow", "pos": Vector2(250, top + 12.0)}]
	m._update_items(0.0)
	return m.items.size() == 1


func _t_item_offscreen_b4() -> void:
	for h in [800, 640]:
		var m = _fresh()
		m.view_h = h
		m.paddle_x = 62.5   # 新規格:擋板 85 的左邊界中心 62.5(原 128 時 84)
		m.target_x = 62.5
		_ok(_item_top_kept(m, h - 1.0), "h%d top = view_h-1 kept" % h)
		_ok(_item_top_kept(m, float(h)), "h%d top = view_h kept" % h)
		_ok(not _item_top_kept(m, h + 0.5), "h%d top = view_h+0.5 removed" % h)
		# 逐幀:多個小數起點,用真實 _step 跑到移除
		for off in [0.0, 0.25, 0.5, 0.77]:
			m.items = [{"id": "slow", "pos": Vector2(250, h - 80.0 + off)}]
			var last_top := -1.0
			var frames := 0
			var removed := false
			while frames < 300:
				m._step(1.0 / 60.0)
				frames += 1
				if m.items.is_empty():
					removed = true
					break
				last_top = m.items[0]["pos"].y - 12.0   # 40×40 上緣
			_ok(removed, "h%d off%.2f removed within 300 frames" % [h, off])
			# 最後一幀仍保留時,上緣 <= view_h;下一幀(移除幀)位置 = last + 100/60
			var next_top: float = last_top + 100.0 / 60.0
			# 畫的位置 = floor(pos) − 12
			var drawn_next := floorf(next_top + 12.0) - 12.0
			_ok(last_top <= h, "h%d off%.2f last kept frame top %.3f <= view_h" % [h, off, last_top])
			_ok(next_top > h, "h%d off%.2f removal frame top %.3f > view_h" % [h, off, next_top])
			_ok(drawn_next >= h, "h%d off%.2f removal frame drawn top %.0f >= view_h (0 rows visible)" % [h, off, drawn_next])
			print("INFO h%d off%.2f removed at frame %d, last kept top %.3f, removal top %.3f" % [h, off, frames, last_top, next_top])
		# 底部接取:擋板在畫面最底附近仍接得到
		var py: int = m._paddle_y()
		# 2 倍規格:擋板上緣 = view_h − 45(原 −37),下緣仍是 view_h − 30
		_eq(py, h - 45, "h%d paddle top = view_h-45" % h)
		m.paddle_x = 180.0
		m.target_x = 180.0
		# 由上方逐幀掉下來,應在擋板處被接取(不會先被移除)
		m.items = [{"id": "slow", "pos": Vector2(180 - 8, py - 80.0)}]
		var caught_top := -1.0
		for i in 300:
			var before: float = m.items[0]["pos"].y - 12.0   # 40×40 上緣
			m._step(1.0 / 60.0)
			if m.items.is_empty():
				caught_top = before + 100.0 / 60.0
				break
		# 2 倍規格:擋板高 16(原 8)
		# 40×40:道具下緣 = 上緣 + 40
		_ok(caught_top > 0.0 and caught_top + 40.0 > py and caught_top < py + 16, "h%d falling item caught at paddle (top %.3f)" % [h, caught_top])
		# 道具上緣在擋板下緣上方 1 px(最下側重疊)仍接得到(道具置中 x 160 = 180 − 20)
		_ok(_catch(m, Vector2(180 - 20, py + 15)), "h%d bottom 1 px overlap still caught" % h)
		_ok(not _catch(m, Vector2(180 - 20, py + 16)), "h%d item top at paddle bottom: missed" % h)
		m.free()


func _t_item_art() -> void:
	# D29 修訂:ItemDefs.icon_path(D29 選單用)改指向 art/items40 的 40×40 圖(原 D20/D21 16×16)
	var min_top := 99
	var worst := ""
	for id in ItemDefs.BUFF + ItemDefs.DEBUFF:
		for f2 in [false, true]:
			var path := ItemDefs.icon_path(id, f2)
			_eq(path, "res://art/items40/d32_item_%s_f%d.png" % [id, 2 if f2 else 1], "icon_path -> items40 %s F%d" % [id, 2 if f2 else 1])
			var tex: Texture2D = load(path)
			_ok(tex != null, "icon exists %s" % path)
			if tex == null:
				continue
			_eq(Vector2i(tex.get_width(), tex.get_height()), Vector2i(40, 40), "icon 40x40 %s" % path.get_file())
			var img := tex.get_image()
			if img.is_compressed():
				img.decompress()
			var top := 0
			var found := false
			for y in img.get_height():
				for x in img.get_width():
					if img.get_pixel(x, y).a > 0.0:
						found = true
						break
				if found:
					break
				top += 1
			if top < min_top:
				min_top = top
				worst = path.get_file()
	print("INFO min transparent top rows in 40x40 menu icons = %d (%s), drawn 1x" % [min_top, worst])
	# 繪圖用的矩形 = 接取矩形(floor 後)。D32:40×40 在 floor(pos) − 12(原 32×32 在 − 8)
	var m = _fresh()
	var p := Vector2(100.7, 300.4)
	var r: Rect2 = m._item_rect(p.floor())
	_eq(r, Rect2(88, 288, 40, 40), "draw rect 40x40 at floor(pos) - 12")
	m.free()


# ---------- D32 items40:40×40 道具、48×48 接取閃光 ----------

## 擋板長度表:[道具組合, 預期長度](與 qa_accel_paddle_test 相同)
const LEN_TABLE := [[[], 85], [["paddle_len_1"], 102], [["paddle_len_2"], 136], [["paddle_len_down_1"], 68],
	[["paddle_len_down_2"], 34], [["paddle_len_min"], 32],
	[["paddle_len_1", "paddle_len_2"], 163], [["paddle_len_down_1", "paddle_len_down_2"], 32],
	[["paddle_len_2", "paddle_len_down_2"], 54], [["paddle_len_1", "paddle_len_down_1"], 82],
	# 2026-10-28:「擋板最大化」已移除;同一種撿兩次再乘、大增 ×4 夾到 320
	[["paddle_len_1", "paddle_len_1"], 122],
	[["paddle_len_2", "paddle_len_2", "paddle_len_2", "paddle_len_2"], 320]]


## 匯入後的貼圖和磁碟上的 PNG 逐像素比對;完全透明的像素只比 alpha(匯入可能改透明像素的 RGB)。
## 回傳差異像素數;尺寸不同或讀不到回傳 −1。
func _diff_vs_png(tex: Texture2D, res_path: String) -> int:
	var a := tex.get_image()
	if a.is_compressed():
		a.decompress()
	var b := Image.load_from_file(ProjectSettings.globalize_path(res_path))
	if b == null or a.get_size() != b.get_size():
		return -1
	a.convert(Image.FORMAT_RGBA8)
	b.convert(Image.FORMAT_RGBA8)
	var bad := 0
	for y in a.get_height():
		for x in a.get_width():
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			if ca.a == 0.0 and cb.a == 0.0:
				continue
			if ca != cb:
				bad += 1
	return bad


func _t_items40_art() -> void:
	var m = _fresh()
	var expected := {}
	for id in ItemDefs.BUFF + ItemDefs.DEBUFF:
		for f in [1, 2]:
			expected["d32_item_%s_f%d.png" % [id, f]] = Vector2i(40, 40)
	for f in [1, 2, 3]:
		expected["d32_item_pickup_f%d.png" % f] = Vector2i(48, 48)
	# 2026-10-28:「擋板最大化」移出道具清單;其後使用者清理檔案,圖檔已刪除
	_ok(not (ItemDefs.BUFF + ItemDefs.DEBUFF).has("paddle_len_max"), "paddle_len_max not in item lists")
	for f in [1, 2]:
		var p := "res://art/items40/d32_item_paddle_len_max_f%d.png" % f
		_ok(not FileAccess.file_exists(p), "paddle_len_max art removed: %s" % p)
		_ok(not FileAccess.file_exists(p + ".import"), "paddle_len_max .import removed: %s" % p)
	_eq(expected.size(), 55, "55 expected files (26 ids x F1/F2 + pickup F1~F3)")
	var on_disk := []
	for f in DirAccess.get_files_at("res://art/items40"):
		if f.ends_with(".png"):
			on_disk.append(f)
	on_disk.sort()
	var keys := expected.keys()
	keys.sort()
	_eq(on_disk, keys, "art/items40 png set == expected 55 names (no missing, no extra)")
	var ok_count := 0
	for file in keys:
		var name: String = file.get_basename()
		var tex: Texture2D = m._t(name)   # 走遊戲實際的載入路徑(main._t 的資料夾判斷)
		_ok(tex != null, "loads via main._t: %s" % name)
		if tex == null:
			continue
		_eq(tex.resource_path, "res://art/items40/" + file, "resolved path %s" % name)
		_eq(Vector2i(tex.get_width(), tex.get_height()), expected[file], "size %s" % name)
		var d := _diff_vs_png(tex, "res://art/items40/" + file)
		_eq(d, 0, "imported pixels == source PNG %s" % name)
		if d == 0:
			ok_count += 1
	print("INFO items40: %d / %d textures load with correct size and match PNG pixels" % [ok_count, keys.size()])
	m.free()


## 每格磚掉出的道具:接取與繪圖的 40×40 都以磚中心為中心,且不超出關卡區 x 20~340。
func _t_items40_drop_draw() -> void:
	cfg.debug_force_item = "slow"
	var m = _fresh()
	var bad := []
	var n := 0
	for r in MainScript.MAX_ROWS:
		for c in MainScript.COLS:
			if c == 7 and r == 0:
				continue   # 哨兵
			m.items.clear()
			_brick(m, c, r, 1)
			m._ball_hit_brick(Vector2i(c, r))
			if m.items.size() != 1:
				bad.append([c, r, "no drop"])
				continue
			n += 1
			var cr: Rect2 = m._cell_rect(Vector2i(c, r))
			var want := Rect2(cr.get_center() - Vector2(20, 20), Vector2(40, 40))
			var p: Vector2 = m.items[0]["pos"]
			var catch_r: Rect2 = m._item_rect(p)
			var draw_r: Rect2 = m._item_rect(p.floor())
			if catch_r != want or draw_r != want or want.position.x < MainScript.FIELD_LEFT or want.end.x > MainScript.FIELD_RIGHT:
				bad.append([c, r, catch_r, draw_r])
	_eq(n, 135, "135 cells dropped an item")
	_eq(bad, [], "catch & draw 40x40 centered on brick center, inside x 20..340, for every cell")
	cfg.debug_force_item = ""
	m.free()


## 接取範圍 40×40 對擋板 [pl, pr) × [py, py+16):重疊 ≥ 1 px 才接到,剛好碰邊不算。四邊、四角。
func _check_box(m, tag: String) -> void:
	var len: int = m._paddle_len()
	var pl: int = m._paddle_left(len)
	var pr: int = pl + len
	var py: int = m._paddle_y()
	var pb: int = py + 16
	var xm := floorf(pl + len / 2.0) - 20.0   # 道具水平置中在擋板上
	var ym := float(py - 12)
	var cases := [
		["right 1px overlap", Vector2(pr - 1, ym), true], ["right touching", Vector2(pr, ym), false],
		["left 1px overlap", Vector2(pl - 39, ym), true], ["left touching", Vector2(pl - 40, ym), false],
		["top 1px overlap", Vector2(xm, py - 39), true], ["top touching", Vector2(xm, py - 40), false],
		["bottom 1px overlap", Vector2(xm, pb - 1), true], ["bottom touching", Vector2(xm, pb), false],
	]
	# 角落:1×1 重疊接到;往外 1 px(水平、垂直、對角)都接不到
	for k in [[pl - 39, py - 39, -1, -1, "TL"], [pr - 1, py - 39, 1, -1, "TR"], [pl - 39, pb - 1, -1, 1, "BL"], [pr - 1, pb - 1, 1, 1, "BR"]]:
		var v := Vector2(k[0], k[1])
		cases.append(["corner %s 1x1" % k[4], v, true])
		cases.append(["corner %s out x" % k[4], v + Vector2(k[2], 0), false])
		cases.append(["corner %s out y" % k[4], v + Vector2(0, k[3]), false])
		cases.append(["corner %s out diag" % k[4], v + Vector2(k[2], k[3]), false])
	for cs in cases:
		_eq(_catch(m, cs[1]), cs[2], "%s: %s" % [tag, cs[0]])


func _t_items40_catch_lengths() -> void:
	for row in LEN_TABLE:
		for tx in [180.0, 0.0, 360.0, 100.25]:
			var m = _fresh()
			for id in row[0]:
				m._apply_item(id)
			m.target_x = tx
			m.paddle_x = tx
			m._update_paddle(0.0)
			var len: int = m._paddle_len()
			_eq(len, row[1], "len %s" % [row[0]])
			_check_box(m, "len %d target %.2f left %d" % [len, tx, m._paddle_left(len)])
			m.free()


## 逐幀掉落(真實 _step)直到被接或 max_frames;回傳是否被接取(且不是掉出畫面)。
func _fall_until_caught(m, pos: Vector2, max_frames := 400) -> bool:
	m.items = [{"id": "slow", "pos": pos}]
	var s0: int = m.score
	for i in max_frames:
		m._step(1.0 / 60.0)
		if m.items.is_empty():
			return m.score == s0 + cfg.score_buff
	return false


func _t_items40_catch_states() -> void:
	var states := [["invisible"], ["sticky"], ["invincible"], ["gun"], ["blackhole"], ["pierce"], ["flame"], ["bomb"],
		["paddle_len_min", "invisible"], ["invisible", "sticky", "invincible", "gun"]]
	for st in states:
		var m = _fresh()
		for id in st:
			m._apply_item(id)
		var on := []
		# 2026-10-28:吸附、槍改為限時;長度道具改為共用計時鍵 Effects.PADDLE_LEN
		for id in st:
			on.append(m.effects.is_active(Effects.PADDLE_LEN if id.begins_with("paddle_len") else id))
		_ok(not on.has(false), "%s active" % [st])
		m.paddle_x = 180.0
		m.target_x = 180.0
		m._update_paddle(0.0)
		_check_box(m, "state %s" % [st])
		# 真實逐幀:從擋板上方 120 px 掉下,在擋板處被接到並計分
		_ok(_fall_until_caught(m, Vector2(172, m._paddle_y() - 120.0)), "state %s: falling item caught and scored" % [st])
		m.free()


## 兩側邊界:第 0 欄、第 7 欄掉出的道具剛好貼齊 x 20 / 340,不超出;擋板貼牆時各種長度都接得到。
func _t_items40_side_walls() -> void:
	cfg.debug_force_item = "slow"
	for row in LEN_TABLE:
		for side in [[0, 0.0], [7, 360.0]]:
			var m = _fresh()
			for id in row[0]:
				m._apply_item(id)
			m.target_x = side[1]
			m.paddle_x = side[1]
			m._update_paddle(0.0)
			var len: int = m._paddle_len()
			var tag := "len %d col %d" % [len, side[0]]
			var cell := Vector2i(side[0], 16)
			_brick(m, cell.x, cell.y, 1)
			m._ball_hit_brick(cell)
			if m.items.size() != 1:
				_ok(false, "%s: drop" % tag)
				m.free()
				continue
			var p: Vector2 = m.items[0]["pos"]
			var r: Rect2 = m._item_rect(p)
			if side[0] == 0:
				_eq([r.position.x, m._paddle_left(len)], [20.0, 20], "%s: item left = 20 = paddle left" % tag)
			else:
				_eq([r.end.x, m._paddle_left(len) + len], [340.0, 340], "%s: item right = 340 = paddle right" % tag)
			var s0: int = m.score
			var caught := false
			for i in 400:
				m._step(1.0 / 60.0)
				if m.items.is_empty():
					caught = true
					break
				if absf(m.items[0]["pos"].x - p.x) > 0.0:
					break
			_ok(caught and m.score == s0 + cfg.score_buff, "%s: wall-side item caught by wall-side paddle" % tag)
			m.free()
	cfg.debug_force_item = ""


func _t_items40_pickup_flash() -> void:
	var m = _fresh()
	m.paddle_x = 180.0
	m.target_x = 180.0
	var py: float = m._paddle_y()   # headless 視埠高 640 → 595;不寫死
	for p in [Vector2(172, py - 15), Vector2(172.6, py - 14.7), Vector2(20 + 8, py - 15)]:
		m.anims.clear()
		m.items = [{"id": "slow", "pos": p}]
		m._update_items(0.0)
		if p.x < 100:
			m.items.clear()   # 擋板在中間時第三個不會被接;直接呼叫 _pickup 看位置
			m._pickup("slow", p)
		var fl: Array = m.anims.filter(func(a: Dictionary) -> bool: return a["kind"] == "pickup")
		_eq(fl.size(), 1, "one pickup flash at %s" % p)
		if fl.size() != 1:
			continue
		var a: Dictionary = fl[0]
		_near(a["dur"], 0.18, "flash dur 3 x 60 ms")
		var ap: Vector2 = a["pos"]
		_ok((ap + Vector2(24, 24)).is_equal_approx(p + Vector2(8, 8)), "flash 48x48 center == item center at %s (flash %s)" % [p, ap])
		_ok(ap.is_equal_approx(m._item_rect(p).position - Vector2(4, 4)), "flash top-left == item rect top-left - (4,4) at %s" % p)
		_eq(ap.floor() + Vector2(24, 24), m._item_rect(p.floor()).get_center(), "drawn flash center == drawn item center at %s" % p)
	# 幀數換算
	for k in [[0.0, 1], [0.001, 1], [0.059, 1], [0.06, 2], [0.119, 2], [0.12, 3], [0.179, 3]]:
		_eq(m._pickup_frame(k[0]), k[1], "pickup frame at t=%.3f" % k[0])
	# 逐幀:和 _step 相同順序(先 _update_items 產生閃光、同一步 _update_anims),記錄每次繪圖看到的幀
	for dt in [1.0 / 60.0, 1.0 / 30.0, 0.05, 1.0 / 144.0]:
		m.anims.clear()
		m.items = [{"id": "slow", "pos": Vector2(172, py - 15)}]
		m._update_items(dt)
		m._update_anims(dt)
		var seq := []
		var t_last := 0.0
		for i in 100:
			var fl: Array = m.anims.filter(func(a: Dictionary) -> bool: return a["kind"] == "pickup")
			if fl.is_empty():
				break
			seq.append(m._pickup_frame(fl[0]["t"]))
			t_last = fl[0]["t"]
			m._update_anims(dt)
		var sorted := seq.duplicate()
		sorted.sort()
		_ok(seq == sorted and seq.has(1) and seq.has(2) and seq.has(3) and seq.max() == 3, "dt %.4f: frames 1->2->3 in order, never > 3 (%s)" % [dt, seq])
		_ok(t_last < 0.18 and t_last + dt >= 0.18 - 0.000001, "dt %.4f: removed right after 180 ms (last t %.4f)" % [dt, t_last])
		var counts := [seq.count(1), seq.count(2), seq.count(3)]
		print("INFO pickup flash dt %.4f: draws per frame F1/F2/F3 = %s (~%s ms), first draw at t = dt" % [dt, counts, counts.map(func(c: int) -> int: return roundi(c * dt * 1000.0))])
	m.free()


# ---------- 回血規則 ----------

func _t_heal_rule() -> void:
	# 40×20 規格:以右下角 (7, 16) 為中心(原 5 × 11 的 (4, 10)),鄰居只取格子內的
	for combo in [["heal"], ["heal", "flame"], ["heal", "reinforce"], ["heal", "flame", "reinforce"], ["heal_area", "flame", "reinforce"]]:
		var m = _fresh()
		_brick(m, 7, 16, 10)
		for n in m._neighbors(Vector2i(7, 16)):
			_brick(m, n.x, n.y, 10)
		var area: bool = combo.has("heal_area")
		for id in combo:
			if id == "reinforce":
				m.effects.reinforce = 7
			else:
				m._apply_item(id)
		m._ball_hit_brick(Vector2i(7, 16))
		var tag := "+".join(combo)
		_eq(_layers(m, 7, 16), 12 if area else 11, "%s: center only heals" % tag)
		var nb := []
		for n in m._neighbors(Vector2i(7, 16)):
			nb.append(_layers(m, n.x, n.y))
		_ok(nb.all(func(v) -> bool: return v == (11 if area else 10)), "%s: neighbors %s (no flame splash)" % [tag, nb])
		_eq(m.score, 0, "%s: no damage score" % tag)
		m.free()
	# 實際碰撞路徑(_ball_bricks 反彈)+ 火焰 + 強化,上限 69
	var m2 = _fresh()
	_brick(m2, 7, 16, 68)
	m2._apply_item("heal")
	m2._apply_item("flame")
	m2.effects.reinforce = 7
	var b = MainScript.Ball.new()
	var rc: Rect2 = m2._cell_rect(Vector2i(7, 16))
	b.pos = Vector2(rc.get_center().x, rc.end.y + 2.0)
	b.dir = Vector2.UP
	_one_ball(m2, b)
	m2._ball_bricks(b, m2._pierce_on())
	_eq(_layers(m2, 7, 16), 69, "real collision with heal+flame+reinforce: +1")
	_ok(b.dir.y > 0.0, "ball bounces")
	b.pos = Vector2(rc.get_center().x, rc.end.y + 2.0)
	b.dir = Vector2.UP
	m2._ball_bricks(b, m2._pierce_on())
	_eq(_layers(m2, 7, 16), 69, "capped at 69")
	m2.free()
	# 範圍回血 + 火焰,鄰居 69 不超過
	var m3 = _fresh()
	# 40×20 規格:右下角 (7, 16),鄰居放左邊 (6, 16)
	_brick(m3, 7, 16, 68)
	_brick(m3, 6, 16, 69)
	m3._apply_item("heal_area")
	m3._apply_item("flame")
	m3._ball_hit_brick(Vector2i(7, 16))
	_eq([_layers(m3, 7, 16), _layers(m3, 6, 16)], [69, 69], "heal_area cap 69 (center & neighbor)")
	m3.free()
	# 穿透(道具)+ 回血 + 火焰:進入時加層
	var m4 = _fresh()
	_brick(m4, 7, 16, 10)
	m4._apply_item("pierce")
	m4._apply_item("heal")
	m4._apply_item("flame")
	var b4 = MainScript.Ball.new()
	b4.pos = m4._cell_rect(Vector2i(7, 16)).get_center()
	b4.dir = Vector2.UP
	_one_ball(m4, b4)
	m4._ball_bricks(b4, m4._pierce_on())
	_eq(_layers(m4, 7, 16), 11, "pierce entry with heal: +1")
	# 規格未寫:穿透結束時球仍在磚內,回血仍生效 → 記錄行為
	m4.effects.add_timed("heal", 100.0)
	for id in m4.effects.tick(cfg.dur_pierce + 0.01):
		m4._on_expired(id)
	print("INFO pierce expires during heal, ball inside brick: layers=%d (-999 = destroyed)" % _layers(m4, 7, 16))
	m4.free()
	# 回血到期後恢復扣層
	var m5 = _fresh()
	_brick(m5, 7, 16, 10)
	m5._apply_item("heal")
	for id in m5.effects.tick(cfg.dur_heal + 0.01):
		m5._on_expired(id)
	m5._ball_hit_brick(Vector2i(7, 16))
	_eq(_layers(m5, 7, 16), 9, "after heal expires: damage again")
	m5.free()
