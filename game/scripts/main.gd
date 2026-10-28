## 單一關卡核心原型:多層磚與不可破壞磚、球、擋板、22 種道具效果、HUD、計分與勝敗。
## 版面座標依 D28 v5 座標總表;可調數值全部讀自 data/game_config.tres。
## 球、擋板以原圖整數 PX 倍顯示,碰撞也用放大後的尺寸(README「基本數值」);
## 磚(含疊在上面的圖層)用 art/bricks40 的 40×20 圖以 1 倍顯示;
## 掉落道具與接取閃光用 art/items40 的 40×40、48×48 圖以 1 倍顯示;
## HUD 圖示用 art/hud32 的 D34 32×32 圖以 1 倍顯示;
## HUD 線段條、UI 區、邊框、背景、擋板槍子彈維持原本的畫法。
## 球可能上百顆,所以物件都存成資料、由固定順序的繪圖圖層一次畫完,不為每顆球建節點。
extends Node2D

enum State { PLAYING, ENDED }

const CONFIG_PATH := "res://data/game_config.tres"
const PADDLE_SHADER := preload("res://shaders/paddle_flash.gdshader")
const TIME_SHADER := preload("res://shaders/time_red.gdshader")

# ---- 版面(D28 v5,螢幕座標)
const FIELD_LEFT := 20
const FIELD_RIGHT := 340   # 右牆內緣;球可佔到 x 339
const FIELD_TOP := 52
const UI_H := 32
const PX := 2              # 球、擋板的放大倍率;使用者決定寫死 2 倍,不做成設定(磚不放大)
const BRICK_TOP := 68
const BRICK_W := 40
const BRICK_H := 20
const COLS := 8            # 8 × 40 剛好填滿 x 20~340
const MAX_ROWS := 17       # 到 y 408,不壓到 HUD 第 1 格(y 424)
# 擋板上緣 = 畫面高 − 45(800 高時 y 755~770)。放大後往上長高 8,下緣維持 D28 v5 的 y 770
const PADDLE_FROM_BOTTOM := 45
const PADDLE_H := 16
const BALL_R := 8.0
const HUD_X := 24
const HUD_Y := 424
const HUD_STEP := 52
## D35 方案 C:每欄格數 = 向下取整((H − 473) ÷ 52),格底端離擋板上緣(H − 45)至少留 12 px;
## 800 高 = 6、707 高 = 4、640 高 = 3
const HUD_COL_RESERVE := 473
## D35、D36 狀態種類;陣列順序就是同一幀同時出現(R10)與開局建立時的固定順序
const HUD_KINDS: Array[String] = ["reinforce", "fever", "speed", "pierce", "flame", "bomb", Effects.PADDLE_LEN,
	"paddle_speed", "sticky", "gun", "heal", "heal_area", "blackhole", "invincible", "invisible"]
## 會觸發球光暈的種類(D36 Q3):只有 D35 原本的球狀態,擋板長度與 D36 新種類都不觸發
const HALO_KINDS: Array[String] = ["reinforce", "fever", "speed", "pierce", "flame", "bomb"]
const MIN_H := 640
const MAX_H := 800

# ---- 時間
const FRAME := 0.06       # D12 小磚每幀 60 ms
const BOMB_MARK_ENDS: Array[float] = [0.16, 0.26, 0.36, 0.5]  # D37 炸彈標記 F1~F4 各幀的結束時間(秒),最後一個 = 一輪長度
const MAX_DT := 0.05      # 卡頓時一幀最多模擬 50 ms,避免球一次飛太遠
const STEP_PX := 2.0    # 球每個子步最多移動的距離,高速時不會穿磚

## D25 主題 1 裝飾(關卡區座標,左上角);依遠景 → 近景排序
const MEADOW_DECOR := {
	"d25_meadow_mound": [Vector2(16, 392), Vector2(144, 452), Vector2(248, 524), Vector2(40, 596), Vector2(176, 668)],
	"d25_meadow_bush": [Vector2(272, 380), Vector2(100, 500), Vector2(8, 540), Vector2(228, 610), Vector2(120, 700), Vector2(290, 690)],
	"d25_meadow_flowers": [Vector2(96, 388), Vector2(210, 470), Vector2(150, 560), Vector2(20, 640), Vector2(260, 650), Vector2(90, 712)],
}


class Ball:
	var pos := Vector2.ZERO   # 圓心
	var dir := Vector2.UP     # 單位向量
	var stuck := false        # 黏在擋板上(開局與吸附)
	var offset := 0.0         # 黏住時相對擋板中心的 x
	var inside := {}          # 穿透中正在重疊的磚格(只在進入時扣層一次)


class Brick:
	var layers := 1
	var unbreakable := false
	var marked := false       # 炸彈標記
	var hit_t := 0.0          # 被擊中幀剩餘時間
	var hit_row := 0          # 被擊中幀要用的列(扣層前那張圖)


var cfg: GameConfig
var effects := Effects.new()
var rng := RandomNumberGenerator.new()
var view_h := MAX_H
var reduced_motion := false
var grid: Array = []          # [排][欄] → Brick 或 null
var breakable_left := 0
var balls: Array[Ball] = []
var items: Array = []         # {"id", "pos"(= 圖示中心 − (8, 8),沿用舊 16×16 的慣例;實際以 _item_rect 的 40×40 畫與接取)}
var bullets: Array = []       # 子彈圖左上角 Vector2
var anims: Array = []         # {"kind", "pos", "t", "dur", ...}
var paddle_x := 180.0         # 擋板中心
var target_x := 180.0
var paddle_flash := 0.0
## 打磚加速(0 ~ brick_accel_max);整局所有球共用,重玩時場景重新載入自然歸零
var brick_accel := 0.0
var gun_cd := 0.0
var score := 0
var time_left := 0.0
var state := State.PLAYING
var menu: ChoiceMenu = null
var menu_queue: Array[bool] = []  # 待開的 3 選 1(true = 金球);同時接到兩顆時依序顯示
var hud: Array = []           # 本幀 HUD 的格,依獲得順序:[圖示, 線段內容]
## HUD 獲得順序清單(D35):存在中的狀態種類,最先獲得在前;重玩時場景重新載入自然清空
var hud_order: Array[String] = []
var _tex := {}
var _layers: Array[DrawLayer] = []
var _paddle_layer: DrawLayer
var _time_layer: DrawLayer


func _ready() -> void:
	cfg = load(CONFIG_PATH) as GameConfig
	rng.randomize()
	reduced_motion = DisplayServer.accessibility_should_reduce_animation()
	# 內部寬固定 360,高 640~800;更高的螢幕把 800 高的畫面垂直置中
	var vis := get_viewport().get_visible_rect().size
	view_h = clampi(int(vis.y), MIN_H, MAX_H)
	position.y = floorf(maxf(0.0, vis.y - view_h) / 2.0)
	time_left = cfg.game_time
	if cfg.debug_enchant in ["pierce", "flame"]:
		effects.enchant = cfg.debug_enchant
	elif cfg.debug_enchant != "":
		push_error("debug_enchant「%s」無效,只能是 pierce、flame 或空字串" % cfg.debug_enchant)
	if cfg.debug_force_item != "" and not ItemDefs.exists(cfg.debug_force_item):
		push_error("debug_force_item「%s」不是道具 id,改為正常隨機掉落" % cfg.debug_force_item)
	_load_level()
	_spawn_start_balls()
	_build_layers()


func _process(delta: float) -> void:
	if state == State.PLAYING and menu == null:
		_step(minf(delta, MAX_DT))
	hud = _hud_cells()
	(_paddle_layer.material as ShaderMaterial).set_shader_parameter("flash", paddle_flash > 0.0)
	(_time_layer.material as ShaderMaterial).set_shader_parameter("red", Rules.time_is_red(time_left))
	for layer in _layers:
		layer.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if state != State.PLAYING or menu != null:
		return
	# 只看第一根手指;桌機以滑鼠模擬觸控(project.godot 已開)
	if event is InputEventScreenTouch and event.index == 0:
		if event.pressed:
			_fire_gun()
		else:
			_launch_stuck()
	elif event is InputEventScreenDrag and event.index == 0:
		# 相對滑動:目標只隨手指水平位移改變,點擊不動擋板。目標先後各夾一次在關卡區內,
		# 手指滑出邊界的位移直接丟掉,往回滑時擋板馬上跟著動;還沒追上的位移留在 target_x 繼續追
		var half := _paddle_len() / 2.0
		var lo := FIELD_LEFT + half
		var hi := FIELD_RIGHT - half
		target_x = clampf(clampf(target_x, lo, hi) + event.relative.x, lo, hi)


# ===================== 初始化 =====================

func _load_level() -> void:
	var res = load(cfg.level_path)
	var parsed := Rules.parse_level(res.data if res is JSON else null, MAX_ROWS, COLS, cfg.max_layers)
	for e in parsed["errors"]:
		push_error("關卡資料 %s:%s" % [cfg.level_path, e])
	var cells: Array = parsed["cells"]
	grid = []
	for r in MAX_ROWS:
		var row := []
		for c in COLS:
			var v: int = cells[r][c] if r < cells.size() else 0
			var br: Brick = null
			if v != 0:
				br = Brick.new()
				br.unbreakable = v == Rules.UNBREAKABLE
				br.layers = maxi(v, 1)
				if not br.unbreakable:
					breakable_left += 1
			row.append(br)
		grid.append(row)


func _spawn_start_balls() -> void:
	var n := clampi(cfg.debug_start_balls, 1, cfg.max_balls)
	var length := _paddle_len()
	var center := _paddle_center(length)
	for i in n:
		var b := Ball.new()
		b.stuck = true
		# 多顆球平均排在擋板上,發射時依位置散開
		b.offset = ((i + 0.5) / n - 0.5) * (length - BALL_R * 2)
		b.pos = Vector2(center + b.offset, _paddle_y() - BALL_R)
		balls.append(b)


func _build_layers() -> void:
	# 由下到上(D19、D28):背景/邊框/UI 區 → 磚 → 子彈 → 擋板 → 砲口閃光 → HUD → 道具 → 光暈 → 球 → 時間
	var painters: Array[Callable] = [_paint_backdrop, _paint_bricks, _paint_bullets, _paint_paddle,
		_paint_muzzle, _paint_hud, _paint_items, _paint_halos, _paint_balls, _paint_time]
	for p in painters:
		var layer := DrawLayer.new()
		layer.painter = p
		add_child(layer)
		_layers.append(layer)
	_paddle_layer = _layers[3]
	_paddle_layer.material = ShaderMaterial.new()
	(_paddle_layer.material as ShaderMaterial).shader = PADDLE_SHADER
	_layers[5].modulate.a = cfg.hud_alpha
	_time_layer = _layers[9]
	_time_layer.material = ShaderMaterial.new()
	(_time_layer.material as ShaderMaterial).shader = TIME_SHADER


# ===================== 每幀更新 =====================

func _step(dt: float) -> void:
	time_left -= dt
	if time_left <= 0.0:
		time_left = 0.0
		_end(false, "時間到")
		return
	gun_cd = maxf(0.0, gun_cd - dt)
	paddle_flash = maxf(0.0, paddle_flash - dt)
	# 先到期再移動擋板:擋板長度到期變回 85 的那一幀,就用新長度夾位置(BUG-1)。
	# 到期仍在球、子彈、道具更新之前,其他效果的到期時序不變
	for id in effects.tick(dt):
		_on_expired(id)
	_update_paddle(dt)
	_update_balls(dt)
	_update_bullets(dt)
	_update_items(dt)
	_update_anims(dt)
	if state != State.PLAYING:
		return
	if balls.is_empty():
		_end(false, "球全部消失")
	elif not menu_queue.is_empty():
		_open_menu(menu_queue.pop_front())


func _update_paddle(dt: float) -> void:
	var half := _paddle_len() / 2.0
	var speed := cfg.paddle_speed * Rules.tier_multiplier(effects.paddle_tier, cfg.speed_tier_step)
	var goal := clampf(target_x, FIELD_LEFT + half, FIELD_RIGHT - half)
	paddle_x = clampf(move_toward(paddle_x, goal, speed * dt), FIELD_LEFT + half, FIELD_RIGHT - half)


func _update_balls(dt: float) -> void:
	var speed := _ball_speed()
	var length := _paddle_len()
	var left := _paddle_left(length)
	var center := _paddle_center(length)
	var py := _paddle_y()
	var pierce := _pierce_on()
	var steps := maxi(1, ceili(speed * dt / STEP_PX))
	var sdt := dt / steps
	for b in balls.duplicate():
		if b.stuck:
			b.pos = Vector2(clampf(center + b.offset, left + BALL_R, left + length - BALL_R), py - BALL_R)
			continue
		for i in steps:
			# 打磚/擋板加速立刻套用到之後的每個子步與每顆球;方向不變,只換速率。
			# 放在子步開頭,擋板碰撞後 break 換下一顆球時也會吃到新速度。
			# 子步數仍用本幀開頭的速度算,單步最多多走 brick_accel_max 比例,不至於穿磚
			speed = _ball_speed()
			b.pos += b.dir * speed * sdt
			_ball_walls(b)
			_ball_bricks(b, pierce)
			if state != State.PLAYING:
				return
			if _ball_paddle(b, left, length, py):
				break
			if b.pos.y - BALL_R > view_h:
				# 消失動畫(原圖 14×14 放大)下緣貼齊畫面底
				_remove_ball(b, Vector2(b.pos.x, view_h - 7 * PX))
				break


func _ball_walls(b: Ball) -> void:
	if b.pos.x - BALL_R < FIELD_LEFT:
		b.pos.x = FIELD_LEFT + BALL_R
		b.dir.x = absf(b.dir.x)
	elif b.pos.x + BALL_R > FIELD_RIGHT:
		b.pos.x = FIELD_RIGHT - BALL_R
		b.dir.x = -absf(b.dir.x)
	if b.pos.y - BALL_R < FIELD_TOP:
		b.pos.y = FIELD_TOP + BALL_R
		b.dir.y = absf(b.dir.y)


## 球與磚:穿透中可破壞磚直接穿過(進入時觸發一次);其餘磚取穿入最深的一塊反彈,一個子步只處理一塊。
func _ball_bricks(b: Ball, pierce: bool) -> void:
	var c0 := maxi(0, floori((b.pos.x - BALL_R - FIELD_LEFT) / BRICK_W))
	var c1 := mini(COLS - 1, floori((b.pos.x + BALL_R - FIELD_LEFT) / BRICK_W))
	var r0 := maxi(0, floori((b.pos.y - BALL_R - BRICK_TOP) / BRICK_H))
	var r1 := mini(MAX_ROWS - 1, floori((b.pos.y + BALL_R - BRICK_TOP) / BRICK_H))
	var best := Vector3(0, 0, 0)
	var best_cell := Vector2i(-1, -1)
	var now_inside := {}
	for r in range(r0, r1 + 1):
		for c in range(c0, c1 + 1):
			var br: Brick = grid[r][c]
			if br == null:
				continue
			var hit := _circle_rect(b.pos, _cell_rect(Vector2i(c, r)))
			if hit.z <= 0.0:
				continue
			var cell := Vector2i(c, r)
			if pierce and not br.unbreakable and not effects.is_active("invincible"):
				now_inside[cell] = true
				if not b.inside.has(cell):
					_ball_hit_brick(cell)
			elif hit.z > best.z:
				best = hit
				best_cell = cell
	b.inside = now_inside
	if best_cell.x < 0:
		return
	var n := Vector2(best.x, best.y)
	b.pos += n * best.z
	if b.dir.dot(n) < 0.0:
		b.dir = b.dir - 2.0 * b.dir.dot(n) * n
		_fix_dir(b)
	_ball_hit_brick(best_cell)


## 回傳 true 表示這顆球不再移動(黏住或被黑洞吸走)。
func _ball_paddle(b: Ball, left: int, length: int, py: int) -> bool:
	if b.dir.y <= 0.0:
		return false
	if _circle_rect(b.pos, Rect2(left, py, length, PADDLE_H)).z <= 0.0:
		return false
	if effects.is_active("blackhole"):
		_remove_ball(b, b.pos)
		return true
	# 擋板加速與打磚加速共用 brick_accel 與上限;黑洞吸走不算。
	# 只在這裡加:反彈後球往上、黏住後 stuck 不再進這個函式,所以每次碰撞只加一次
	brick_accel = minf(brick_accel + cfg.brick_accel_paddle, cfg.brick_accel_max)
	paddle_flash = FRAME
	var offset := b.pos.x - _paddle_center(length)
	b.pos.y = py - BALL_R
	# 吸附到期後新碰到的球照常反彈;已經黏住的球維持 stuck,等玩家點擊由 _launch_stuck 發射
	if effects.is_active("sticky"):
		b.stuck = true
		b.offset = offset
		b.inside = {}
		return true
	b.dir = _bounce_dir(offset, length)
	return false


## 圓與矩形碰撞:回傳 (法線 x, 法線 y, 穿入深度);深度 ≤ 0 表示沒碰到。
func _circle_rect(p: Vector2, rect: Rect2) -> Vector3:
	var q := p.clamp(rect.position, rect.end)
	var d := p - q
	var l2 := d.length_squared()
	if l2 > 0.0:
		if l2 >= BALL_R * BALL_R:
			return Vector3(0, 0, -1)
		var l := sqrt(l2)
		return Vector3(d.x / l, d.y / l, BALL_R - l)
	# 圓心已在矩形內:從最近的邊推出去
	var dl := p.x - rect.position.x
	var dr := rect.end.x - p.x
	var dt := p.y - rect.position.y
	var db := rect.end.y - p.y
	var m := minf(minf(dl, dr), minf(dt, db))
	if m == dt:
		return Vector3(0, -1, dt + BALL_R)
	if m == db:
		return Vector3(0, 1, db + BALL_R)
	if m == dl:
		return Vector3(-1, 0, dl + BALL_R)
	return Vector3(1, 0, dr + BALL_R)


## 避免球幾乎水平來回:與水平線夾角至少 min_angle_deg。
func _fix_dir(b: Ball) -> void:
	var s := sin(deg_to_rad(cfg.min_angle_deg))
	if absf(b.dir.y) < s:
		var sy := 1.0 if b.dir.y > 0.0 else -1.0
		var sx := -1.0 if b.dir.x < 0.0 else 1.0
		b.dir = Vector2(sx * sqrt(1.0 - s * s), sy * s)
	b.dir = b.dir.normalized()


## 擋板反彈:依擊中位置離擋板中心多遠決定偏角。
func _bounce_dir(offset: float, length: int) -> Vector2:
	var ratio := clampf(offset / (length / 2.0), -1.0, 1.0)
	return Vector2.UP.rotated(deg_to_rad(ratio * cfg.paddle_bounce_max_deg))


func _launch_dir(offset: float, length: int) -> Vector2:
	var deg := clampf(offset / (length / 2.0), -1.0, 1.0) * cfg.paddle_bounce_max_deg
	if absf(deg) < cfg.launch_min_deg:
		var side := signf(deg) if deg != 0.0 else (1.0 if rng.randf() < 0.5 else -1.0)
		deg = cfg.launch_min_deg * side
	return Vector2.UP.rotated(deg_to_rad(deg))


func _launch_stuck() -> void:
	var length := _paddle_len()
	for b in balls:
		if b.stuck:
			b.stuck = false
			b.dir = _launch_dir(b.offset, length)


func _remove_ball(b: Ball, at: Vector2) -> void:
	balls.erase(b)
	_anim("vanish", at, FRAME * 4)


func _update_bullets(dt: float) -> void:
	var keep := []
	for bl in bullets:
		var ny: float = bl.y - cfg.bullet_speed * dt
		var hit := _bullet_trace(bl.x, bl.y, ny)
		if hit.x >= 0:
			var cell := Vector2i(hit.x, hit.y)
			var br: Brick = grid[cell.y][cell.x]
			# 打到不可破壞磚(或無敵中的磚)被擋下、磚不受影響;可破壞磚固定扣 1,不吃任何加成(D19)
			if br.unbreakable or effects.is_active("invincible"):
				_anim("bullet_block", Vector2(bl.x - 2, hit.z), 0.16)
			else:
				_anim("bullet_hit", Vector2(bl.x - 2, hit.z - 3), 0.12)
				_damage(cell, 1)
		elif ny >= FIELD_TOP:
			keep.append(Vector2(bl.x, ny))
	bullets = keep


## 子彈掃掠判定(D19):判定點是子彈圖第 0 列內部 2 欄;這一幀從 y0 往上到 y1 之間,
## 第一個碰到的磚是「下緣下一列 B 落在 (y1, y0]」裡最低的那塊。回傳 (欄, 排, B);沒碰到時欄為 −1。
func _bullet_trace(x: float, y0: float, y1: float) -> Vector3i:
	var found := Vector3i(-1, -1, -1)
	for px in [x + 1, x + 2]:
		var c := floori((px - FIELD_LEFT) / BRICK_W)
		if c < 0 or c >= COLS:
			continue
		for r in range(MAX_ROWS - 1, -1, -1):
			if grid[r][c] == null:
				continue
			var bottom := BRICK_TOP + (r + 1) * BRICK_H
			if bottom <= y0 and bottom > y1 and bottom > found.z:
				found = Vector3i(c, r, bottom)
			break
	return found


func _fire_gun() -> void:
	# 槍到期後不再發射;已在飛行中的子彈由 _update_bullets 照常飛完
	if not effects.is_active("gun") or gun_cd > 0.0:
		return
	gun_cd = cfg.gun_cooldown
	var length := _paddle_len()
	var left := _paddle_left(length)
	var gun_top := _paddle_y() - 4 * PX
	# 槍端原圖 8 寬、砲管在第 2~5 欄;放大後砲管在 gun_left + 4~11,原尺寸 4 寬的子彈置中於 +6。
	# 砲口閃光(原圖 8×4)跟著槍端放大,畫在砲管正上方;子彈從閃光範圍內射出
	for gun_left in [left, left + length - 8 * PX]:
		bullets.append(Vector2(gun_left + 6, gun_top - 4 * PX))
		_anim("muzzle", Vector2(gun_left, gun_top - 4 * PX), 0.1)


func _update_items(dt: float) -> void:
	var prect := Rect2(_paddle_left(_paddle_len()), _paddle_y(), _paddle_len(), PADDLE_H)
	var keep := []
	for it in items:
		var p: Vector2 = it["pos"] + Vector2(0, cfg.item_fall_speed * dt)
		if _item_rect(p).intersects(prect):
			_pickup(it["id"], p)
		elif _item_rect(p).position.y <= view_h:  # 40×40 上緣離開畫面底才移除,避免圖示還露出一截就消失
			keep.append({"id": it["id"], "pos": p})
	items = keep


## 道具以 1 倍 40×40 顯示與接取。pos 沿用舊慣例(中心 − 8),往左上各退 12,
## 中心點(pos + 8)維持在被破壞磚的中心。
func _item_rect(pos: Vector2) -> Rect2:
	return Rect2(pos - Vector2(12, 12), Vector2(40, 40))


func _update_anims(dt: float) -> void:
	for a in anims:
		a["t"] += dt
	anims = anims.filter(func(a: Dictionary) -> bool: return a["t"] < a["dur"])
	for row in grid:
		for br in row:
			if br != null and br.hit_t > 0.0:
				br.hit_t -= dt


func _anim(kind: String, pos: Vector2, dur: float, extra := {}) -> void:
	var a := {"kind": kind, "pos": pos, "t": 0.0, "dur": dur}
	a.merge(extra)
	anims.append(a)


# ===================== 磚塊規則 =====================

## 球碰到磚(反彈或穿透進入)。效果優先順序(假設):無敵 > 炸彈標記 > 回血 > 扣層(火焰、強化)。
## 打磚加速只在這裡累加:子彈、火焰擴散、炸彈爆炸都直接走 _damage,不經過這裡。
func _ball_hit_brick(cell: Vector2i) -> void:
	var br: Brick = grid[cell.y][cell.x]
	if br == null:
		return
	brick_accel = minf(brick_accel + (cfg.brick_accel_unbreakable if br.unbreakable else cfg.brick_accel_other), cfg.brick_accel_max)
	if br.unbreakable or effects.is_active("invincible"):
		br.hit_row = Rules.sheet_row(br.layers, br.marked)
		br.hit_t = FRAME
		return
	if effects.is_active("bomb"):
		br.hit_row = Rules.sheet_row(br.layers, br.marked)
		br.marked = true
		br.hit_t = FRAME
		return
	var heal := (cfg.heal_amount if effects.is_active("heal") else 0) + (cfg.heal_area_amount if effects.is_active("heal_area") else 0)
	if heal > 0:
		_heal(cell, heal)
		if effects.is_active("heal_area"):
			for n in _neighbors(cell):
				_heal(n, cfg.heal_area_splash)
		return
	var flame := _flame_on()
	_damage(cell, (cfg.flame_damage if flame else 1) + effects.reinforce)
	if flame:
		for n in _neighbors(cell):
			_damage(n, cfg.flame_splash)


## 扣層:先播扣層前那張圖的被擊中幀,再換成最終層數(一次扣多層也只播 1 幀);扣到 0 就破壞。
func _damage(cell: Vector2i, amount: int) -> void:
	var br: Brick = grid[cell.y][cell.x]
	if state != State.PLAYING or br == null or br.unbreakable or amount <= 0 or effects.is_active("invincible"):
		return
	var old_row := Rules.sheet_row(br.layers, br.marked)
	var old_color := Rules.layer_color(br.layers)
	var removed := mini(amount, br.layers)
	br.layers = Rules.damage_layers(br.layers, amount)
	score += Rules.brick_score(removed, br.layers == 0, cfg.score_per_layer, cfg.score_per_brick)
	if br.layers > 0:
		br.hit_row = old_row
		br.hit_t = FRAME
		return
	grid[cell.y][cell.x] = null
	breakable_left -= 1
	var pos := _cell_rect(cell).position
	# 破壞:被擊中 1 幀 + F1~F4,破壞幀用破壞當下的顏色
	_anim("break", pos, FRAME * 5, {"hit_row": old_row, "color": old_color})
	_roll_drop(pos)
	if breakable_left <= 0:
		_end(true, "所有可破壞磚塊都已破壞")


func _heal(cell: Vector2i, amount: int) -> void:
	var br: Brick = grid[cell.y][cell.x]
	if br == null or br.unbreakable or effects.is_active("invincible"):
		return
	br.hit_row = Rules.sheet_row(br.layers, br.marked)
	br.hit_t = FRAME
	br.layers = Rules.heal_layers(br.layers, amount, cfg.max_layers)


func _neighbors(cell: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var n := cell + Vector2i(dx, dy)
			if (dx != 0 or dy != 0) and n.x >= 0 and n.x < COLS and n.y >= 0 and n.y < MAX_ROWS:
				out.append(n)
	return out


func _cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(FIELD_LEFT + cell.x * BRICK_W, BRICK_TOP + cell.y * BRICK_H, BRICK_W, BRICK_H)


func _roll_drop(brick_pos: Vector2) -> void:
	var id := cfg.debug_force_item if ItemDefs.exists(cfg.debug_force_item) else ""
	if id == "":
		if rng.randf() >= cfg.drop_chance:
			return
		var pool := ItemDefs.drop_pool(rng.randf() < cfg.buff_ratio, cfg.replay_level)
		id = pool[rng.randi_range(0, pool.size() - 1)]
	# 從被破壞磚的位置開始往下掉:圖示中心(pos + 8)= 磚中心
	items.append({"id": id, "pos": brick_pos + Vector2(BRICK_W, BRICK_H) / 2.0 - Vector2(8, 8)})


## 穿透結束:球所在位置若有可破壞磚,直接破壞。
func _pierce_end() -> void:
	for b in balls:
		b.inside = {}
		var c0 := maxi(0, floori((b.pos.x - BALL_R - FIELD_LEFT) / BRICK_W))
		var c1 := mini(COLS - 1, floori((b.pos.x + BALL_R - FIELD_LEFT) / BRICK_W))
		var r0 := maxi(0, floori((b.pos.y - BALL_R - BRICK_TOP) / BRICK_H))
		var r1 := mini(MAX_ROWS - 1, floori((b.pos.y + BALL_R - BRICK_TOP) / BRICK_H))
		for r in range(r0, r1 + 1):
			for c in range(c0, c1 + 1):
				var br: Brick = grid[r][c]
				if br != null and _circle_rect(b.pos, _cell_rect(Vector2i(c, r))).z > 0.0:
					_damage(Vector2i(c, r), br.layers)


## 炸彈結束:被標記的磚全部破壞,再對各自周圍 3×3 扣層。
func _bomb_explode() -> void:
	var marked: Array[Vector2i] = []
	for r in MAX_ROWS:
		for c in COLS:
			var br: Brick = grid[r][c]
			if br != null and br.marked:
				marked.append(Vector2i(c, r))
	for cell in marked:
		var br: Brick = grid[cell.y][cell.x]
		if br != null:
			_damage(cell, br.layers)
	for cell in marked:
		for n in _neighbors(cell):
			_damage(n, cfg.bomb_splash)
	# 無敵中爆炸無效,標記仍隨效果結束清除
	for row in grid:
		for br in row:
			if br != null:
				br.marked = false


# ===================== 道具 =====================

func _pickup(id: String, pos: Vector2) -> void:
	# 過關在 _update_balls 內判定,同一幀稍後才更新道具;結束後接到的道具照樣消失但不計分、不生效,
	# 結束畫面的分數才會等於 score(B1)
	if state != State.PLAYING:
		return
	score +=cfg.score_buff if ItemDefs.is_buff(id) else cfg.score_debuff
	# 閃光 48×48 以道具中心(pos + 8)為中心:左上角 = pos + 8 − 24
	_anim("pickup", pos - Vector2(16, 16), FRAME * 3)
	_apply_item(id)


func _apply_item(id: String) -> void:
	match id:
		"slow":
			effects.ball_tier = Rules.step_tier(effects.ball_tier, -1, cfg.ball_tier_min, cfg.ball_tier_max)
		"fast":
			effects.ball_tier = Rules.step_tier(effects.ball_tier, 1, cfg.ball_tier_min, cfg.ball_tier_max)
		"paddle_speed":
			effects.paddle_tier = Rules.step_tier(effects.paddle_tier, 1, cfg.paddle_tier_min, cfg.paddle_tier_max)
		"paddle_speed_down":
			effects.paddle_tier = Rules.step_tier(effects.paddle_tier, -1, cfg.paddle_tier_min, cfg.paddle_tier_max)
		"reinforce":
			effects.reinforce = mini(effects.reinforce + 1, cfg.reinforce_max)
		"paddle_len_1", "paddle_len_2", "paddle_len_down_1", "paddle_len_down_2", "paddle_len_min":
			effects.add_paddle_len(id, cfg)
			# 變長後立刻重新夾位置(不移動),貼牆時這一幀就不會超出牆;3 選 1 暫停中也一樣
			_update_paddle(0.0)
		"split":
			_split_balls()
		"merge":
			@warning_ignore("integer_division")
			_remove_balls(balls.size() / 2)
		"blackhole_big":
			_remove_balls(balls.size() - 1)
		"thief":
			score = Rules.thief_steal(score, rng.randi_range(cfg.thief_min, cfg.thief_max))
		"golden_ball":
			menu_queue.append(true)
		"black_ball":
			menu_queue.append(false)
		_:
			# 其餘都是各自計時的限時效果:穿透、火焰、炸彈、吸附、槍、回血、範圍回血、黑洞、無敵、隱形;
			# 秒數讀設定檔的 dur_<id>
			effects.add_timed(id, cfg.get("dur_" + id))


func _split_balls() -> void:
	var angle := deg_to_rad(cfg.split_angle_deg)
	for b in balls.duplicate():
		if balls.size() >= cfg.max_balls:
			break
		var nb := Ball.new()
		nb.pos = b.pos
		nb.stuck = b.stuck
		# 黏住的球錯開一點,發射時才不會疊在同一條路線
		nb.offset = b.offset + BALL_R * 2
		nb.dir = b.dir.rotated(angle)
		_fix_dir(nb)
		balls.append(nb)


func _remove_balls(count: int) -> void:
	for i in count:
		var b: Ball = balls.pop_back()
		_anim("vanish", b.pos, FRAME * 4)


func _on_expired(id: String) -> void:
	if id == "pierce" and effects.enchant != "pierce":
		_pierce_end()
	elif id == "bomb":
		_bomb_explode()


func _open_menu(golden: bool) -> void:
	var ids := ItemDefs.pick_distinct(ItemDefs.choice_pool(golden, cfg.replay_level), 3, rng)
	menu = ChoiceMenu.new()
	menu.setup(golden, ids, view_h, reduced_motion)
	menu.picked.connect(_on_menu_picked)
	menu.closed.connect(func() -> void: menu = null)
	add_child(menu)


## 3 選 1 選中的道具直接觸發,與撿到一樣計分(假設:金球/黑球本身撿到時也計一次)。
func _on_menu_picked(id: String) -> void:
	score += cfg.score_buff if ItemDefs.is_buff(id) else cfg.score_debuff
	_apply_item(id)


func _pierce_on() -> bool:
	return effects.is_active("pierce") or effects.enchant == "pierce"


func _flame_on() -> bool:
	return effects.is_active("flame") or effects.enchant == "flame"


func _paddle_len() -> int:
	return Rules.paddle_length(cfg.paddle_base_length, [effects.paddle_factor], cfg.paddle_min_length, cfg.paddle_max_length)


func _paddle_left(length: int) -> int:
	return roundi(paddle_x - length / 2.0)


## 畫面上實際畫出的擋板中心。長度為奇數時左緣取整,會比 paddle_x 多 0.5,
## 反彈角與吸附球都以這個為準,畫出來的正中央才是 0 度。
func _paddle_center(length: int) -> float:
	return _paddle_left(length) + length / 2.0


## 球速 = 基礎速度 × 速度階倍率 × 打磚加速倍率,直接相乘、不設總上限。
func _ball_speed() -> float:
	return cfg.ball_speed * Rules.tier_multiplier(effects.ball_tier, cfg.speed_tier_step) * (1.0 + brick_accel)


func _paddle_y() -> int:
	return view_h - PADDLE_FROM_BOTTOM


# ===================== 結束 =====================

func _end(win: bool, reason: String) -> void:
	if state == State.ENDED:
		return
	state = State.ENDED
	if win:
		score += Rules.time_bonus(time_left, cfg.score_per_second)
	_show_end_screen("%s\n%s\n分數 %d" % ["過關！" if win else "失敗", reason, score])


func _show_end_screen(text: String) -> void:
	# shortcut: 結束畫面只有文字與重玩,字型暫用 Godot 預設;結算畫面等選單 UI 設計(任務 C)後再做
	var ui := Control.new()
	ui.size = Vector2(360, view_h)
	add_child(ui)
	var dim := ColorRect.new()
	dim.color = Color(Pal.K, 0.75)
	dim.size = ui.size
	ui.add_child(dim)
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(0, view_h / 2.0 - 110)
	label.size = Vector2(360, 100)
	label.add_theme_font_size_override("font_size", 22)
	ui.add_child(label)
	var btn := Button.new()
	btn.text = "重玩"
	btn.add_theme_font_size_override("font_size", 22)
	btn.position = Vector2(110, view_h / 2.0 + 10)
	btn.size = Vector2(140, 56)
	btn.pressed.connect(func() -> void: get_tree().reload_current_scene())
	ui.add_child(btn)
	btn.grab_focus.call_deferred()


# ===================== 繪圖 =====================

func _t(name: String) -> Texture2D:
	if not _tex.has(name):
		# D31 磚圖與 D37 炸彈標記放在 art/bricks40、D32 掉落道具在 art/items40、D34 HUD 圖示在 art/hud32,其餘在 art/generated
		var dir := "bricks40" if name.begins_with("d31_") or name.begins_with("d37_") else "items40" if name.begins_with("d32_") \
			else "hud32" if name.begins_with("d34_") else "generated"
		_tex[name] = load("res://art/%s/%s.png" % [dir, name])
	return _tex[name]


## 全域動畫時鐘的相位;所有球光暈、炸彈標記、道具呼吸共用,不受遊戲暫停影響。
func _phase(period: float) -> float:
	return fmod(Time.get_ticks_msec() / 1000.0, period)


## 炸彈標記(D37)在一輪內第 t 秒(0 ≤ t < 0.5)的圖名,依 BOMB_MARK_ENDS 切換 F1~F4;減少動態時固定 F1。
func _bomb_mark(t: float) -> String:
	var f := 1
	if not reduced_motion:
		while f < BOMB_MARK_ENDS.size() and t >= BOMB_MARK_ENDS[f - 1]:
			f += 1
	return "d37_bomb_mark_f%d" % f


func _paint_backdrop(ci: CanvasItem) -> void:
	# 背景(D25 主題 1):64×64 底圖從關卡區左上角鋪滿,超出畫面底的部分裁掉
	var tile := _t("d25_meadow_tile")
	for y in range(FIELD_TOP, view_h, 64):
		var h := mini(64, view_h - y)
		for x in range(FIELD_LEFT, FIELD_RIGHT, 64):
			ci.draw_texture_rect_region(tile, Rect2(x, y, 64, h), Rect2(0, 0, 64, h))
	for name in MEADOW_DECOR:
		var tex := _t(name)
		for p in MEADOW_DECOR[name]:
			var top: float = FIELD_TOP + p.y
			var h := minf(tex.get_height(), view_h - top)
			if h > 0:
				ci.draw_texture_rect_region(tex, Rect2(FIELD_LEFT + p.x, top, tex.get_width(), h), Rect2(0, 0, tex.get_width(), h))
	# 邊框(D23 主題 1 苔石,位置依 v5):左右 20×32 由 y 51 往下拼;上邊框 40×20 由 x 19 往右拼;兩個轉角同一張圖不鏡像
	var side := _t("d23_border_moss_tile")
	for y in range(51, view_h, 32):
		var h := mini(32, view_h - y)
		for x in [0, 340]:
			ci.draw_texture_rect_region(side, Rect2(x, y, 20, h), Rect2(0, 0, 20, h))
	var top_tile := _t("d23_border_moss_top_tile")
	for x in range(19, 340, 40):
		var w := mini(40, 340 - x)
		ci.draw_texture_rect_region(top_tile, Rect2(x, 32, w, 20), Rect2(0, 0, w, 20))
	var corner := _t("d23_border_moss_corner_tl")
	ci.draw_texture(corner, Vector2(0, 32))
	ci.draw_texture(corner, Vector2(340, 32))
	# UI 區(D27、D28 v5):分數靠右,最右一位起點 x 286,往左每位 −11;星形在最左一位左邊
	ci.draw_rect(Rect2(0, 0, 360, UI_H), Pal.K)
	var digits := str(score)
	var n := digits.length()
	ci.draw_texture(_t("d27_hud_icon_star_l"), Vector2(280 - 11 * n, 9))
	for i in n:
		ci.draw_texture(_t("d27_hud_digit_l_" + digits[i]), Vector2(286 - 11 * (n - 1 - i), 8))
	# shortcut: 暫停鈕只畫圖、沒有功能(暫停選單不在本次範圍)
	ci.draw_texture(_t("d27_hud_pause_l_normal"), Vector2(332, 4))


func _paint_time(ci: CanvasItem) -> void:
	# 時鐘 + M:SS / MM:SS,數字格起點相差 11、冒號相差 5;紅色由 time_red 著色器換色
	ci.draw_texture(_t("d27_hud_icon_clock_l"), Vector2(8, 9))
	var x := 25
	for ch in Rules.time_text(time_left):
		if ch == ":":
			ci.draw_texture(_t("d27_hud_colon_l"), Vector2(x, 8))
			x += 5
		else:
			ci.draw_texture(_t("d27_hud_digit_l_" + ch), Vector2(x, 8))
			x += 11


func _paint_bricks(ci: CanvasItem) -> void:
	var invincible := effects.is_active("invincible")
	# 炸彈標記(D37)所有標記共用同一時鐘;減少動態時固定 F1
	var mark := _t(_bomb_mark(_phase(BOMB_MARK_ENDS[-1])))
	for r in MAX_ROWS:
		for c in COLS:
			var br: Brick = grid[r][c]
			if br == null:
				continue
			var pos := _cell_rect(Vector2i(c, r)).position
			if br.unbreakable:
				ci.draw_texture(_t("d31_brick_unbreakable_hit" if br.hit_t > 0.0 else "d31_brick_unbreakable"), pos)
				continue
			var hit := br.hit_t > 0.0
			_draw_brick(ci, pos, br.hit_row if hit else Rules.sheet_row(br.layers, br.marked), hit)
			if invincible:
				ci.draw_texture(_t("d31_invincible_frame"), pos)
			if br.marked:
				ci.draw_texture(mark, pos)
	for a in anims:
		match a["kind"]:
			"break":
				# 第 0 幀 = 被擊中(扣層前的數字),第 1~3 幀 = 破壞 F1~F3(依顏色),第 4 幀 = 灰塵;破壞幀不疊數字
				var f := int(a["t"] / FRAME)
				if f == 0:
					_draw_brick(ci, a["pos"], a["hit_row"], true)
				elif f < 4:
					ci.draw_texture(_t("d31_brick_%s_f%d" % [Rules.COLOR_NAMES[a["color"]], f]), a["pos"])
				else:
					ci.draw_texture(_t("d31_brick_dust_f4"), a["pos"])
			# 子彈的擊中/擋下特效跟子彈一樣維持原尺寸
			"bullet_hit":
				ci.draw_texture(_t("d19_bullet_hit_f1" if a["t"] < 0.06 else "d19_bullet_hit_f2"), a["pos"])
			"bullet_block":
				ci.draw_texture(_t("d19_bullet_block_f1" if a["t"] < 0.08 else "d19_bullet_block_f2"), a["pos"])


func _paint_bullets(ci: CanvasItem) -> void:
	var tex := _t("d19_bullet_laser_f1" if reduced_motion or _phase(0.1) < 0.05 else "d19_bullet_laser_f2")
	for bl in bullets:
		ci.draw_texture(tex, bl.floor())


## 擋板依 D13 拼接,每段以 PX 倍畫:左端 16 + 中段 32 重複 n 次 + 裁切 r 欄 + 右端 16;
## 槍端高 24(砲管 8 在本體上方)、底部對齊本體。
func _paint_paddle(ci: CanvasItem) -> void:
	var invisible := effects.is_active("invisible")
	if invisible and cfg.invisible_alpha <= 0.0:
		return
	var tint := Color(1, 1, 1, cfg.invisible_alpha if invisible else 1.0)
	var length := _paddle_len()
	var left := _paddle_left(length)
	var py := _paddle_y()
	var gun := effects.is_active("gun")
	var kind := "sticky" if effects.is_active("sticky") else "normal"
	var end_kind := "gun" if gun else kind
	var end_y := py - 4 * PX if gun else py
	var end_w := 8 * PX
	var mid_w := 16 * PX
	_draw_px(ci, _t("d13_paddle_%s_left" % end_kind), Vector2(left, end_y), tint)
	var mid := _t("d13_paddle_%s_mid" % kind)
	@warning_ignore("integer_division")
	var full := (length - 2 * end_w) / mid_w
	var rest := (length - 2 * end_w) % mid_w
	for i in full:
		_draw_px(ci, mid, Vector2(left + end_w + mid_w * i, py), tint)
	if rest > 0:
		# 長度可能是奇數(例:205),裁切寬換回原圖是半個像素;nearest 取樣下仍是完整像素
		ci.draw_texture_rect_region(mid, Rect2(left + end_w + mid_w * full, py, rest, PADDLE_H),
			Rect2(0, 0, rest / float(PX), PADDLE_H / float(PX)), tint)
	_draw_px(ci, _t("d13_paddle_%s_right" % end_kind), Vector2(left + length - end_w, end_y), tint)


func _paint_muzzle(ci: CanvasItem) -> void:
	for a in anims:
		if a["kind"] == "muzzle":
			_draw_px(ci, _t("d19_gun_muzzle_flash_f1" if a["t"] < 0.05 else "d19_gun_muzzle_flash_f2"), a["pos"])


## 依 D35 更新獲得順序清單 hud_order,回傳本幀 HUD 的格(依清單順序)。
## 先移除不存在的(R2,後面自動補位),再依 HUD_KINDS 固定順序把新出現的接在最後(R1、R10);
## 存在中的種類位置不動、只更新內容(R3、R5、R7)。只比對「本幀存在與否」,
## 所以同一幀到期又再獲得視為一直存在(R11)。同一狀態下重複呼叫結果相同。
func _hud_cells() -> Array:
	var cells := {}
	for kind in HUD_KINDS:
		var cell := _hud_cell(kind)
		if not cell.is_empty():
			cells[kind] = cell
	hud_order = hud_order.filter(func(k: String) -> bool: return cells.has(k))
	for kind in HUD_KINDS:
		if cells.has(kind) and kind not in hud_order:
			hud_order.append(kind)
	return hud_order.map(func(k: String) -> Array: return cells[k])


## 一種狀態本幀的格 [圖示, 線段內容];不存在時回傳空陣列(D16 線段條、D34 圖示)。
func _hud_cell(kind: String) -> Array:
	match kind:
		"reinforce":
			if effects.reinforce > 0:
				return ["d34_hud_icon_reinforce", {"segments": cfg.reinforce_max, "filled": effects.reinforce}]
		"fever":
			# shortcut: fever 玩法未做,恆不存在(不依球數,避免沒有玩法卻亮出 fever 格與光暈);實作 fever 時改成「球數 ≥ 50」並補線段內容
			pass
		"speed":
			if effects.ball_tier < 0:
				return ["d34_hud_icon_slow", {"segments": -cfg.ball_tier_min, "filled": -effects.ball_tier}]
			if effects.ball_tier > 0:
				return ["d34_hud_icon_fast", {"segments": cfg.ball_tier_max, "filled": effects.ball_tier}]
		"pierce", "flame", "bomb":
			if effects.enchant == kind:
				return ["d34_hud_icon_" + kind, {"fill": Rules.BAR_INNER}]
			if effects.is_active(kind):
				return ["d34_hud_icon_" + kind, _timebar(kind)]
		Effects.PADDLE_LEN:
			return _hud_len_cell()
		"paddle_speed":
			# D36 第三節:比照球速,一次跨過 0 仍是同一格、只換圖
			if effects.paddle_tier < 0:
				return ["d34_hud_icon_paddle_speed_down", {"segments": -cfg.paddle_tier_min, "filled": -effects.paddle_tier}]
			if effects.paddle_tier > 0:
				return ["d34_hud_icon_paddle_speed_up", {"segments": cfg.paddle_tier_max, "filled": effects.paddle_tier}]
		"sticky", "gun", "heal", "heal_area", "blackhole", "invincible", "invisible":
			if effects.is_active(kind):
				return ["d34_hud_icon_" + kind, _timebar(kind)]
	return []


## 擋板長度格(D33、D34):共用計時進行中且實際長度 ≠ 基準時才顯示;
## 比基準長 → +,比基準短或最短化生效中 → −。回傳 [圖示, 線段內容],不顯示時回傳空陣列。
func _hud_len_cell() -> Array:
	var length := _paddle_len()
	var base := roundi(cfg.paddle_base_length)
	if not effects.is_active(Effects.PADDLE_LEN) or length == base:
		return []
	var down := effects.paddle_min or length < base
	return ["d34_hud_icon_paddle_len_down1" if down else "d34_hud_icon_paddle_len_up1", _timebar(Effects.PADDLE_LEN)]


## 限時效果的連續時間條:剩餘 ÷ 總時間;最後 1 秒填色在 W 與 G 之間每 100 ms 切換(減少動態時不閃)。
func _timebar(id: String) -> Dictionary:
	var rem := effects.remaining(id)
	var blink := not reduced_motion and rem <= 1.0 and int(rem * 10.0) % 2 == 1
	return {"fill": Rules.timebar_fill(rem, effects.total(id)), "color": Pal.G if blink else Pal.W}


func _paint_hud(ci: CanvasItem) -> void:
	# 每格 44×44:D34 圖示 32×32 以 1 倍畫在格內第 6 欄起,線段條 44×8 在第 36 列
	for k in hud.size():
		_draw_hud_cell(ci, _hud_slot(k), hud[k])


## 第 i 格(從 0 起)的左上角(D35 方案 C):欄由左到右、欄內由上到下,一欄放滿就換下一欄。
func _hud_slot(i: int) -> Vector2:
	@warning_ignore("integer_division")
	var per_col := (view_h - HUD_COL_RESERVE) / HUD_STEP
	@warning_ignore("integer_division")
	return Vector2(HUD_X + HUD_STEP * (i / per_col), HUD_Y + HUD_STEP * (i % per_col))


func _draw_hud_cell(ci: CanvasItem, o: Vector2, cell: Array) -> void:
	ci.draw_texture(_t(cell[0]), o + Vector2(6, 0))
	_draw_bar(ci, o + Vector2(0, 36), cell[1])


## 2 倍線段條:外框 j、內部 20×2 逐欄上色。每個像素只畫一次,整組 50% 半透明時才不會因重疊變色。
func _draw_bar(ci: CanvasItem, o: Vector2, spec: Dictionary) -> void:
	ci.draw_rect(Rect2(o, Vector2(44, 2)), Pal.STEEL_J)
	ci.draw_rect(Rect2(o + Vector2(0, 6), Vector2(44, 2)), Pal.STEEL_J)
	ci.draw_rect(Rect2(o + Vector2(0, 2), Vector2(2, 4)), Pal.STEEL_J)
	ci.draw_rect(Rect2(o + Vector2(42, 2), Vector2(2, 4)), Pal.STEEL_J)
	var cols := []
	if spec.has("segments"):
		var n: int = spec["segments"]
		var widths := Rules.segment_widths(n)
		var grays := Rules.segment_gray_indices(n)
		for s in n:
			var color: Color = Pal.SEGMENT_GRAYS[grays[s]] if s < spec["filled"] else Pal.BOSS_V
			for i in widths[s]:
				cols.append(color)
			if s < n - 1:
				cols.append(Pal.STEEL_J)
	else:
		for i in Rules.BAR_INNER:
			cols.append(spec.get("color", Pal.W) if i < spec["fill"] else Pal.BOSS_V)
	for i in cols.size():
		ci.draw_rect(Rect2(o + Vector2(2 + 2 * i, 2), Vector2(2, 4)), cols[i])


func _paint_items(ci: CanvasItem) -> void:
	var f2 := not reduced_motion and _phase(0.8) >= 0.4
	for it in items:
		# 40×40 原圖以 1 倍畫在整數座標,nearest 取樣不會糊
		ci.draw_texture(_t("d32_item_%s_f%d" % [it["id"], 2 if f2 else 1]), _item_rect((it["pos"] as Vector2).floor()).position)
	for a in anims:
		if a["kind"] == "pickup":
			ci.draw_texture(_t("d32_item_pickup_f%d" % _pickup_frame(a["t"])), (a["pos"] as Vector2).floor())


## 接取閃光播到第幾幀(1~3,每幀 FRAME = 60 ms)。
func _pickup_frame(t: float) -> int:
	return int(t / FRAME) + 1


func _paint_halos(ci: CanvasItem) -> void:
	# 清單中有球的狀態才顯示光暈(D35、D36 Q3);所有光暈畫在所有球本體之下,全部同相位呼吸
	if not _halo_on():
		return
	var tex := _t("d15_ball_opt_c_halo_f1" if reduced_motion or _phase(0.8) < 0.4 else "d15_ball_opt_c_halo_f2")
	# 光暈與消失動畫原圖 14×14、球 8×8,都以 PX 倍畫並以球心置中
	for b in balls:
		_draw_px(ci, tex, (b.pos - Vector2(7, 7) * PX).floor())


## 球光暈是否顯示:獲得順序清單中有任何一格是球的狀態(D35,D36 Q3 補例外)。
func _halo_on() -> bool:
	return hud_order.any(func(k: String) -> bool: return k in HALO_KINDS)


func _paint_balls(ci: CanvasItem) -> void:
	var tex := _t("d15_ball_normal")
	for b in balls:
		_draw_px(ci, tex, (b.pos - Vector2(BALL_R, BALL_R)).floor())
	for a in anims:
		if a["kind"] == "vanish":
			_draw_px(ci, _t("d15_ball_vanish_f%d" % (int(a["t"] / FRAME) + 1)), (a["pos"] - Vector2(7, 7) * PX).floor())


## 以整數 PX 倍畫出原尺寸圖(專案預設濾鏡為 nearest,不會糊);pos 是放大後的左上角。
func _draw_px(ci: CanvasItem, tex: Texture2D, pos: Vector2, tint := Color.WHITE) -> void:
	ci.draw_texture_rect(tex, Rect2(pos, tex.get_size() * PX), false, tint)


## 以 1 倍畫一塊多層磚:底圖(被擊中時換成共用的閃白圖)+ 數字疊加層。row 是 Rules.sheet_row 的列號。
func _draw_brick(ci: CanvasItem, pos: Vector2, row: int, hit: bool) -> void:
	var art := Rules.brick_art(row)
	ci.draw_texture(_t("d31_brick_hit" if hit else art[0]), pos)
	if art[1] != "":
		ci.draw_texture(_t(art[1]), pos)
