## 單一關卡核心原型:多層磚、不可破壞磚、6 種功能型磚(D38)、特殊磚與魔王(D39~D44)、球、擋板、22 種道具效果、HUD、計分與勝敗。
## 版面座標依 D28 v5 座標總表;可調數值全部讀自 data/game_config.tres。
## 球、擋板以原圖整數 PX 倍顯示,碰撞也用放大後的尺寸(README「基本數值」);
## 磚(含疊在上面的圖層)用 art/bricks40 的 40×20 圖以 1 倍顯示;
## 掉落道具與接取閃光用 art/items40 的 40×40、48×48 圖以 1 倍顯示;
## HUD 圖示用 art/hud32 的 D34 32×32 圖以 1 倍顯示;
## HUD 線段條、UI 區、邊框、背景、擋板槍子彈維持原本的畫法。
## 球可能上百顆,所以物件都存成資料、由固定順序的繪圖圖層一次畫完,不為每顆球建節點。
extends Node2D

## CLEARING = 魔王全滅後、結束畫面前:只播動畫與延遲效果(剩下的磚依序消失),球與時間不動。
## 放在最後,既有測試直接寫 state = 1 代表 ENDED。
enum State { PLAYING, ENDED, CLEARING }

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

# ---- 特殊磚與魔王(D39~D44)
const CIRCLE_R := 10.0                        # 圓形磚碰撞半徑;圓心 = 格左上 + (20, 10)
const CIRCLE_OFFSET := Vector2(10, 0)         # 20×20 圓形磚圖相對格左上角
const CIRCLE_MARK_OFFSET := Vector2(-5, -3)   # 炸彈標記疊在圓形磚上的偏移(D39 Q10)
## 特殊磚種類 → 圖名前綴(_hit、_f1~_f3 接在後面)
const SPECIAL_ART := {"chest": "d40_brick_chest", "coin": "d41_brick_coin", "circle": "d39_brick_circle"}
const COIN_FRAME := 0.1                       # 金幣轉動每幀 100 ms
const BOSS_WARN := 1.6                        # D44 BOSS 警告總長
const BAR_SLIDE := 0.3                        # D43 血條滑入、淡出
const BAR_Y := 54

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
	var warp := 0.0           # 傳送中剩餘秒數:> 0 時不移動、不碰撞、不畫,但仍算在場上(不會因此判輸)
	var ghost := Vector2i(-1, -1)  # 剛從這塊傳送出口出來,離開它之前不與它碰撞
	var gone := false         # 已被移除(死神),本幀剩下的子步不再處理


## 一隻魔王(D42):整隻共用一個血量池與門檻表,斷成兩段也一樣。
class Boss:
	var id := ""
	var cells: Array[Vector2i] = []   # 還沒掉的格;掉格當下就移除(錯開動畫的格稍後才離開 grid)
	var size := 0                     # 總格數 N
	var max_layers := 0               # 總層數 H
	var layers := 0
	var thresholds: Array[int] = []   # Rules.boss_thresholds
	var center_x := 0.0               # 載入時的格子中心 x(欄);決定血條左右,掉格後不交換
	var marked := false               # 炸彈標記(每隻只標 1 個)
	var bar_old := 0                  # 扣血前的層數:血條尾端那段先閃白
	var bar_t := 0.0                  # 血條尾端閃白剩餘秒數


class Brick:
	var layers := 1
	var unbreakable := false
	var kind := ""            # 功能型磚種類(Rules.FUNC_CODES 的值);空字串 = 多層磚或不可破壞磚
	var special := ""         # 特殊磚種類(Rules.SPECIAL_CODES 的值);固定 1 層,其餘照多層磚規則
	var boss: Boss = null     # 魔王格所屬的魔王;魔王格的 layers 不使用
	var uses := 0             # 功能型磚剩餘次數;0 = 已用完、等效果播完後移除(期間仍擋球但不再觸發)
	var marked := false       # 炸彈標記
	var hit_t := 0.0          # 被擊中幀剩餘時間
	var hit_row := 0          # 被擊中幀要用的列(扣層前那張圖);功能型磚存扣次數前的次數(數字照舊顯示)


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
var events: Array = []        # 延遲效果 {"t": 剩餘秒數, "fn": Callable};遊戲進行中與 CLEARING 時推進
var bosses: Array[Boss] = []
var coins: Array = []         # 掉落金幣 {"value", "pos"(= 金幣中心)}
var coins_caught := 0         # 本局接到的金幣面額合計(與「分數 1%」分開)
var warn_left := 0.0          # BOSS 警告剩餘秒數;> 0 時暫停遊戲、忽略輸入
var bar_t := 0.0              # 警告結束後經過的秒數(血條滑入)
var bar_fade := -1.0          # 魔王全滅後經過的秒數(血條淡出);< 0 = 尚未全滅
var _white := {}              # 圖名 → 閃白版貼圖(非 K、非透明改 W)
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
	# D44:有魔王的關卡,磚塊顯示後先播 BOSS 警告,期間暫停
	if not bosses.is_empty():
		warn_left = BOSS_WARN


func _process(delta: float) -> void:
	if warn_left > 0.0:
		warn_left = maxf(0.0, warn_left - delta)
	elif state == State.PLAYING and menu == null:
		_step(minf(delta, MAX_DT))
	elif state == State.CLEARING:
		_update_anims(minf(delta, MAX_DT))
		_update_events(minf(delta, MAX_DT))
	if warn_left <= 0.0:
		bar_t += delta
	if bar_fade >= 0.0:
		bar_fade += delta
	hud = _hud_cells()
	(_paddle_layer.material as ShaderMaterial).set_shader_parameter("flash", paddle_flash > 0.0)
	(_time_layer.material as ShaderMaterial).set_shader_parameter("red", Rules.time_is_red(time_left))
	for layer in _layers:
		layer.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if state != State.PLAYING or menu != null or warn_left > 0.0:
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
	var funcs: Dictionary = parsed["funcs"]
	var specials: Dictionary = parsed["specials"]
	# 魔王血量 = 關卡編號 × boss_hp_per_level(README:關卡的 5 倍),每隻各自一份
	var by_id := {}
	for id in parsed["bosses"]:
		var bs := Boss.new()
		bs.id = id
		bs.cells.assign(parsed["bosses"][id])
		bs.size = bs.cells.size()
		bs.max_layers = maxi(1, cfg.level_number * cfg.boss_hp_per_level)
		bs.layers = bs.max_layers
		bs.bar_old = bs.layers
		bs.thresholds = Rules.boss_thresholds(bs.max_layers, bs.size)
		for c in bs.cells:
			bs.center_x += float(c.x) / bs.size
		bosses.append(bs)
		by_id[id] = bs
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
				if v == Rules.FUNC:
					var f: Dictionary = funcs[Vector2i(c, r)]
					br.kind = f["kind"]
					# 沒指定次數的雷射、閃電、死神隨機 1~9;爆炸、彩虹只能碰 1 次;傳送沒有次數(不使用 uses)
					br.uses = 1
					if br.kind in Rules.COUNTED_KINDS:
						br.uses = f["uses"] if f["uses"] > 0 else rng.randi_range(1, Rules.FUNC_USES_MAX)
				elif v == Rules.SPECIAL:
					br.special = specials[Vector2i(c, r)]
				elif v == Rules.BOSS:
					for id in by_id:
						if Vector2i(c, r) in by_id[id].cells:
							br.boss = by_id[id]
				# 勝利條件:可破壞磚與功能型磚都清空,傳送磚無法破壞所以不算;有魔王的關卡改看魔王(_check_clear)
				if not br.unbreakable and br.kind != "teleport" and br.boss == null:
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
	# 由下到上(D19、D28):背景/邊框/UI 區/魔王血條 → 磚 → 子彈 → 擋板 → 砲口閃光 → HUD → 道具/金幣 → 光暈 → 球 → 時間
	# → BOSS 警告(D44,蓋在最上面;接在最後,前面圖層的索引不變)
	var painters: Array[Callable] = [_paint_backdrop, _paint_bricks, _paint_bullets, _paint_paddle,
		_paint_muzzle, _paint_hud, _paint_items, _paint_halos, _paint_balls, _paint_time, _paint_warning]
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
	_update_coins(dt)
	_update_anims(dt)
	_update_events(dt)
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
		if b.warp > 0.0:
			b.warp -= dt
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
			if b.gone or b.warp > 0.0:
				break
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


## 球與磚:穿透中多層磚(含特殊磚)直接穿過(進入時觸發一次);其餘磚(含功能型磚、魔王)取穿入最深的一塊反彈,
## 一個子步只處理一塊(同時碰到圓形磚與相鄰方形磚時也是取最深者)。圓形磚用圓形碰撞,反彈改隨機角度(D39)。
func _ball_bricks(b: Ball, pierce: bool) -> void:
	var c0 := maxi(0, floori((b.pos.x - BALL_R - FIELD_LEFT) / BRICK_W))
	var c1 := mini(COLS - 1, floori((b.pos.x + BALL_R - FIELD_LEFT) / BRICK_W))
	var r0 := maxi(0, floori((b.pos.y - BALL_R - BRICK_TOP) / BRICK_H))
	var r1 := mini(MAX_ROWS - 1, floori((b.pos.y + BALL_R - BRICK_TOP) / BRICK_H))
	var best := Vector3(0, 0, 0)
	var best_cell := Vector2i(-1, -1)
	var now_inside := {}
	var in_ghost := false
	for r in range(r0, r1 + 1):
		for c in range(c0, c1 + 1):
			var br: Brick = grid[r][c]
			if br == null:
				continue
			var cell := Vector2i(c, r)
			var hit := _hit_shape(b.pos, cell, br)
			if hit.z <= 0.0:
				continue
			if cell == b.ghost:
				in_ghost = true
			elif pierce and _is_layered(br) and not effects.is_active("invincible"):
				now_inside[cell] = true
				if not b.inside.has(cell):
					_ball_hit_brick(cell)
			elif hit.z > best.z:
				best = hit
				best_cell = cell
	b.inside = now_inside
	if not in_ghost:
		b.ghost = Vector2i(-1, -1)
	if best_cell.x < 0:
		return
	var n := Vector2(best.x, best.y)
	b.pos += n * best.z
	if b.dir.dot(n) < 0.0:
		if (grid[best_cell.y][best_cell.x] as Brick).special == "circle":
			b.dir = Rules.circle_bounce(n, rng, cfg.min_angle_deg)
		else:
			b.dir = b.dir - 2.0 * b.dir.dot(n) * n
			_fix_dir(b)
	_ball_hit_brick(best_cell, b)


## 球與一格磚的碰撞:圓形磚用圓(圓心格左上 + (20, 10)、半徑 CIRCLE_R),其餘用整格矩形。回傳格式同 _circle_rect。
func _hit_shape(p: Vector2, cell: Vector2i, br: Brick) -> Vector3:
	if br.special != "circle":
		return _circle_rect(p, _cell_rect(cell))
	var d := p - _cell_rect(cell).get_center()
	var l := d.length()
	if l >= BALL_R + CIRCLE_R:
		return Vector3(0, 0, -1)
	var n := d / l if l > 0.0 else Vector2.DOWN
	return Vector3(n.x, n.y, BALL_R + CIRCLE_R - l)


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
	b.gone = true
	_anim("vanish", at, FRAME * 4)


func _update_bullets(dt: float) -> void:
	var keep := []
	for bl in bullets:
		var ny: float = bl.y - cfg.bullet_speed * dt
		var hit := _bullet_trace(bl.x, bl.y, ny)
		if hit.x >= 0:
			var cell := Vector2i(hit.x, hit.y)
			var br: Brick = grid[cell.y][cell.x]
			# 打到不可破壞磚、傳送磚(或無敵中的磚)被擋下、磚不受影響;可破壞磚固定扣 1,不吃任何加成(D19);
			# 其他功能型磚觸發效果並扣 1 次,子彈停在該磚;魔王扣 1 層並擋下子彈(無敵不影響魔王)
			if br.boss != null:
				_anim("bullet_hit", Vector2(bl.x - 2, hit.z - 3), 0.12)
				_boss_damage(br.boss, 1, cell)
			elif br.unbreakable or br.kind == "teleport" or effects.is_active("invincible"):
				_anim("bullet_block", Vector2(bl.x - 2, hit.z), 0.16)
			elif br.kind != "":
				_anim("bullet_hit", Vector2(bl.x - 2, hit.z - 3), 0.12)
				_trigger(cell)
			else:
				_anim("bullet_hit", Vector2(bl.x - 2, hit.z - 3), 0.12)
				_damage(cell, 1)
		elif ny >= FIELD_TOP:
			keep.append(Vector2(bl.x, ny))
	bullets = keep


## 子彈掃掠判定(D19):判定點是子彈圖第 0 列內部 2 欄;這一幀從 y0 往上到 y1 之間,
## 第一個碰到的磚是「下緣下一列 B 落在 (y1, y0]」裡最低的那塊。回傳 (欄, 排, B);沒碰到時欄為 −1。
## 圓形磚用判定點那一欄(像素中心)實際碰到圓的位置當下緣;判定點落在圓外時子彈從圓旁邊穿過,繼續往上找。
func _bullet_trace(x: float, y0: float, y1: float) -> Vector3i:
	var found := Vector3i(-1, -1, -1)
	for px in [x + 1, x + 2]:
		var c := floori((px - FIELD_LEFT) / BRICK_W)
		if c < 0 or c >= COLS:
			continue
		for r in range(MAX_ROWS - 1, -1, -1):
			var br: Brick = grid[r][c]
			if br == null:
				continue
			var bottom := float(BRICK_TOP + (r + 1) * BRICK_H)
			if br.special == "circle":
				var dx: float = floorf(px) + 0.5 - _cell_rect(Vector2i(c, r)).get_center().x
				if absf(dx) >= CIRCLE_R:
					continue
				bottom = _cell_rect(Vector2i(c, r)).get_center().y + sqrt(CIRCLE_R * CIRCLE_R - dx * dx)
			if bottom <= y0 and bottom > y1 and bottom > found.z:
				found = Vector3i(c, r, ceili(bottom))
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


## 掉落金幣(D41):垂直下落(速度同道具),金幣矩形與擋板矩形重疊就接到;上緣離開畫面底就消失。
## 結束後接到的照樣消失但不計(同道具 B1)。
func _update_coins(dt: float) -> void:
	var prect := Rect2(_paddle_left(_paddle_len()), _paddle_y(), _paddle_len(), PADDLE_H)
	var keep := []
	for co in coins:
		var p: Vector2 = co["pos"] + Vector2(0, cfg.item_fall_speed * dt)
		var rect := _coin_rect(co["value"], p)
		if rect.intersects(prect):
			if state == State.PLAYING:
				coins_caught += co["value"]
				# 接到特效 20×20,中心對齊金幣中心
				_anim("coin_pick", p - Vector2(10, 10), FRAME * 3)
		elif rect.position.y <= view_h:
			keep.append({"value": co["value"], "pos": p})
	coins = keep


## 金幣矩形:尺寸取自該面額 F1 貼圖(D41,換圖不必改程式),中心對齊 center。
func _coin_rect(value: int, center: Vector2) -> Rect2:
	var s := _t("d41_coin_%d_f1" % value).get_size()
	return Rect2(center - s / 2.0, s)


## 該面額有 F1 貼圖才能生成金幣;先查是否存在,避免 load 不存在的檔案。
func _coin_has_art(value: int) -> bool:
	return ResourceLoader.exists("res://art/special40/d41_coin_%d_f1.png" % value)


func _update_anims(dt: float) -> void:
	for a in anims:
		a["t"] += dt
	anims = anims.filter(func(a: Dictionary) -> bool: return a["t"] < a["dur"])
	for row in grid:
		for br in row:
			if br != null and br.hit_t > 0.0:
				br.hit_t -= dt
	for bs in bosses:
		bs.bar_t = maxf(0.0, bs.bar_t - dt)


func _anim(kind: String, pos: Vector2, dur: float, extra := {}) -> void:
	var a := {"kind": kind, "pos": pos, "t": 0.0, "dur": dur}
	a.merge(extra)
	anims.append(a)


## 推進延遲效果:到時的依到期先後執行;執行中新排的效果從下一幀開始計時。
func _update_events(dt: float) -> void:
	for e in events:
		e["t"] -= dt
	var due := events.filter(func(e: Dictionary) -> bool: return e["t"] <= 0.0)
	events = events.filter(func(e: Dictionary) -> bool: return e["t"] > 0.0)
	due.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["t"] < b["t"])
	for e in due:
		if state == State.ENDED:
			return
		(e["fn"] as Callable).call()


func _later(delay: float, fn: Callable) -> void:
	events.append({"t": delay, "fn": fn})


# ===================== 磚塊規則 =====================

## 球碰到磚(反彈或穿透進入)。效果優先順序(假設):無敵 > 炸彈標記 > 回血 > 扣層(火焰、強化)。
## 打磚加速只在這裡累加:子彈、火焰擴散、炸彈爆炸都直接走 _damage,不經過這裡。
## 功能型磚:不受強化、火焰、炸彈標記、回血影響,每次碰觸只觸發一次(_trigger);ball 給死神、傳送用。
func _ball_hit_brick(cell: Vector2i, ball: Ball = null) -> void:
	var br: Brick = grid[cell.y][cell.x]
	if br == null:
		return
	brick_accel = minf(brick_accel + (cfg.brick_accel_unbreakable if br.unbreakable else cfg.brick_accel_other), cfg.brick_accel_max)
	if br.boss != null:
		_boss_ball_hit(cell, ball)
		return
	if br.kind != "":
		if not effects.is_active("invincible"):
			_trigger(cell, ball)
		elif br.kind != "teleport":
			_func_hit_flash(br)
		return
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
			_splash(cell, cfg.heal_area_splash, null, true)
		return
	var flame := _flame_on()
	_damage(cell, (cfg.flame_damage if flame else 1) + effects.reinforce)
	if flame:
		_splash(cell, cfg.flame_splash)


## 周圍一圈(3×3 扣掉中心)的範圍效果:一般磚各自扣層(或回血);魔王每隻只算一次,skip = 中心那隻魔王(不重複算)。
func _splash(cell: Vector2i, amount: int, skip: Boss = null, heal := false) -> void:
	var hit: Array[Boss] = []
	for n in _neighbors(cell):
		var br: Brick = grid[n.y][n.x]
		if br != null and br.boss != null:
			if br.boss != skip and br.boss not in hit:
				hit.append(br.boss)
		elif heal:
			_heal(n, amount)
		else:
			_damage(n, amount)
	for bs in hit:
		if heal:
			_boss_heal(bs, amount)
		else:
			_boss_damage(bs, amount)


## 扣層:先播扣層前那張圖的被擊中幀,再換成最終層數(一次扣多層也只播 1 幀);扣到 0 就破壞。
## 只作用在多層磚與特殊磚(魔王走 _boss_damage);quiet = 破壞時不播破壞動畫(爆炸 F3 直接移除,D18);
## hit_frame = false 時破壞動畫省略被擊中幀、直接播 F1~F4(彩虹目標已播過選中閃光,整段才會是 420 ms)。
## 特殊磚固定 1 層,破壞只給 score_per_brick(不另給每層分);寶箱必掉 1 個道具,金幣磚另外必掉 1 枚金幣。
func _damage(cell: Vector2i, amount: int, quiet := false, hit_frame := true) -> void:
	var br: Brick = grid[cell.y][cell.x]
	if state != State.PLAYING or not _is_layered(br) or amount <= 0 or effects.is_active("invincible"):
		return
	var old_row := Rules.sheet_row(br.layers, br.marked)
	var old_color := Rules.layer_color(br.layers)
	var removed := mini(amount, br.layers)
	br.layers = Rules.damage_layers(br.layers, amount)
	score += cfg.score_per_brick if br.special != "" else Rules.brick_score(removed, br.layers == 0, cfg.score_per_layer, cfg.score_per_brick)
	if br.layers > 0:
		br.hit_row = old_row
		br.hit_t = FRAME
		return
	grid[cell.y][cell.x] = null
	breakable_left -= 1
	var pos := _cell_rect(cell).position
	# 破壞:被擊中 1 幀(hit_frame)+ F1~F4,破壞幀用破壞當下的顏色(特殊磚用自己的圖)
	if not quiet:
		_anim("break", pos, FRAME * (5 if hit_frame else 4), {"hit_row": old_row, "color": old_color, "hit": hit_frame,
			"special": br.special})
	match br.special:
		"chest":
			_spawn_item(_cell_rect(cell).get_center(), cfg.chest_buff_ratio)
		"coin":
			_roll_drop(pos)
			var value := Rules.coin_value(rng.randf(), cfg.coin_values, cfg.coin_weights)
			# coin_values 是可調設定:填了沒有圖的面額時不生成,免得繪圖與判定取不到尺寸而當掉
			if _coin_has_art(value):
				coins.append({"value": value, "pos": _cell_rect(cell).get_center()})
			else:
				push_error("coin_values 的面額 %d 沒有對應的金幣圖 d41_coin_%d_f1~f4,略過此金幣" % [value, value])
		_:
			_roll_drop(pos)
	_check_clear()


## 一般關卡:可破壞磚與功能型磚都清空就過關;有魔王的關卡改由魔王全滅(_boss_victory)判定。
func _check_clear() -> void:
	if bosses.is_empty() and breakable_left <= 0:
		_end(true, "所有可破壞磚塊都已破壞")


## 回血:只作用在多層磚(特殊磚固定 1 層、魔王走 _boss_heal);被擊中幀照播。
func _heal(cell: Vector2i, amount: int) -> void:
	var br: Brick = grid[cell.y][cell.x]
	if br == null or br.unbreakable or br.kind != "" or br.boss != null or effects.is_active("invincible"):
		return
	if br.special != "":
		br.hit_t = FRAME
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


## 一般 30% 掉落判定;從被破壞磚的位置開始往下掉(圖示中心 = 磚中心)。
func _roll_drop(brick_pos: Vector2) -> void:
	if not ItemDefs.exists(cfg.debug_force_item) and rng.randf() >= cfg.drop_chance:
		return
	_spawn_item(brick_pos + Vector2(BRICK_W, BRICK_H) / 2.0, cfg.buff_ratio)


## 在 center(圖示中心)產生 1 個道具:buff_ratio 的機率是增益(寶箱 0.7、魔王用 0 或 1 指定),其餘減益。
## debug_force_item 有效時一律掉該道具,不抽亂數(與舊行為相同)。
func _spawn_item(center: Vector2, buff_ratio: float) -> void:
	var id := cfg.debug_force_item if ItemDefs.exists(cfg.debug_force_item) else ""
	if id == "":
		var pool := ItemDefs.drop_pool(rng.randf() < buff_ratio, cfg.replay_level)
		id = pool[rng.randi_range(0, pool.size() - 1)]
	# items 的 pos 沿用舊慣例 = 圖示中心 − 8
	items.append({"id": id, "pos": center - Vector2(8, 8)})


## 穿透結束:球所在位置若有可破壞磚,直接破壞;球在魔王格內則該魔王扣 1(每顆球每隻只算一次,不直接破壞)。
func _pierce_end() -> void:
	for b in balls:
		b.inside = {}
		var c0 := maxi(0, floori((b.pos.x - BALL_R - FIELD_LEFT) / BRICK_W))
		var c1 := mini(COLS - 1, floori((b.pos.x + BALL_R - FIELD_LEFT) / BRICK_W))
		var r0 := maxi(0, floori((b.pos.y - BALL_R - BRICK_TOP) / BRICK_H))
		var r1 := mini(MAX_ROWS - 1, floori((b.pos.y + BALL_R - BRICK_TOP) / BRICK_H))
		var hit: Array[Boss] = []
		for r in range(r0, r1 + 1):
			for c in range(c0, c1 + 1):
				var br: Brick = grid[r][c]
				if br == null or _hit_shape(b.pos, Vector2i(c, r), br).z <= 0.0:
					continue
				if br.boss != null:
					if br.boss not in hit:
						hit.append(br.boss)
						_boss_damage(br.boss, 1, Vector2i(c, r))
				else:
					_damage(Vector2i(c, r), br.layers)


## 炸彈結束:被標記的磚全部破壞、被標記的魔王扣 bomb_boss_damage 層,再對各自周圍 3×3 扣層
## (魔王以標記格為中心,不波及自己)。無敵不影響魔王。
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
	# 標記格在扣血前決定:扣血掉格後才算的話,爆炸中心會跳到別格
	var boss_marks := {}
	for bs in bosses:
		if bs.marked and bs.layers > 0:
			boss_marks[bs] = _boss_mark_cell(bs)
			_boss_damage(bs, cfg.bomb_boss_damage, boss_marks[bs])
	for cell in marked:
		_splash(cell, cfg.bomb_splash)
	for bs in boss_marks:
		_splash(boss_marks[bs], cfg.bomb_splash, bs)
	# 無敵中爆炸無效,標記仍隨效果結束清除
	for row in grid:
		for br in row:
			if br != null:
				br.marked = false
	for bs in bosses:
		bs.marked = false


# ===================== 功能型磚(D38;規則見 README「功能型磚塊」、handoff 3.3、D17、D18) =====================

## 多層磚與特殊磚(可被效果扣層、被閃電挑中;彩虹另外排除特殊磚);null、不可破壞磚、功能型磚、魔王格都不是。
func _is_layered(br: Brick) -> bool:
	return br != null and not br.unbreakable and br.kind == "" and br.boss == null


func _field_rect() -> Rect2:
	return Rect2(FIELD_LEFT, FIELD_TOP, FIELD_RIGHT - FIELD_LEFT, view_h - FIELD_TOP)


## 功能型磚被碰到(球、子彈、光束)時觸發一次效果並扣 1 次;不吃任何加成。
## ball 為 null 表示子彈或光束:死神只扣次數、傳送沒有效果。
## 無敵期間不發動;已用完(uses 0,等效果播完才移除)的不再觸發。
func _trigger(cell: Vector2i, ball: Ball = null) -> void:
	var br: Brick = grid[cell.y][cell.x]
	if state != State.PLAYING or br == null or br.kind == "" or effects.is_active("invincible"):
		return
	if br.kind == "teleport":
		if ball != null:
			_teleport(cell, ball)
		return
	if br.uses <= 0:
		return
	var before := br.uses
	_func_hit_flash(br)
	br.uses -= 1
	match br.kind:
		"laser_h", "laser_v", "laser_x":
			_fire_laser(cell, br.kind.trim_prefix("laser_"))
			if br.uses == 0:
				# 剩 1 次被碰:仍發射,光束 4 幀播完才破壞(D17)
				_later(cfg.func_frame * 4, _break_func.bind(cell, false))
		"lightning":
			_lightning(before)
			if br.uses == 0:
				_break_func(cell, true)
		"reaper":
			if ball != null:
				_remove_ball(ball, ball.pos)
			if br.uses == 0:
				_break_func(cell, true)
		"explosion":
			_explode(cell)
		"rainbow":
			_rainbow(cell)


## 被擊中 1 幀;數字照舊顯示扣之前的次數(D17)。
func _func_hit_flash(br: Brick) -> void:
	br.hit_row = br.uses
	br.hit_t = cfg.func_frame


## 移除功能型磚:破壞分、計入勝利條件(不掉道具)。hit_frame = 破壞前先播 1 幀被擊中;show = false 時不播破壞(爆炸)。
func _break_func(cell: Vector2i, hit_frame: bool, show := true) -> void:
	var br: Brick = grid[cell.y][cell.x]
	if state != State.PLAYING or br == null or br.kind == "":
		return
	grid[cell.y][cell.x] = null
	breakable_left -= 1
	score += cfg.score_per_brick
	if show:
		_anim("func_break", _cell_rect(cell).position, cfg.func_frame * (5 if hit_frame else 4), {
			"mat": "laser" if br.kind.begins_with("laser_") else br.kind,
			"hit": "d38_brick_%s_hit" % br.kind if hit_frame else "",
			"digit": br.kind in Rules.COUNTED_KINDS})
	_check_clear()


## 雷射:axis = "h"、"v"、"x"。光束從磚往兩側(或上下、十字四向)延伸,沿途多層磚扣層,
## 遇到不可破壞磚或功能型磚停下;沒被擋就到關卡區邊緣(垂直往下到關卡區底部)。
## 光束形狀在發射時決定(D17 拼法);F2 開頭(1 幀後)才扣層並觸發擋下它的功能型磚(雷射磚會再發射,形成連鎖)。
func _fire_laser(cell: Vector2i, axis: String) -> void:
	var dirs: Array[Vector2i] = []
	if axis != "v":
		dirs.append_array([Vector2i.LEFT, Vector2i.RIGHT])
	if axis != "h":
		dirs.append_array([Vector2i.UP, Vector2i.DOWN])
	var pos := _cell_rect(cell).position
	var segs := []
	var hits: Array[Vector2i] = []
	var blockers: Array[Vector2i] = []
	for d in dirs:
		var vert := d.x == 0
		var gap := 0
		var blocked := false
		var n := cell + d
		while n.x >= 0 and n.x < COLS and n.y >= 0 and n.y < MAX_ROWS:
			var br: Brick = grid[n.y][n.x]
			if br != null and not _is_layered(br):
				blocked = true
				blockers.append(n)
				break
			if br != null:
				hits.append(n)
			gap += 1
			n += d
		# 每段 20×20:水平一格磚 = 2 段、垂直一排 = 1 段;垂直段水平置中(laser_v_offset)
		var stp := Vector2(d) * 20.0
		var p0 := pos + (cfg.laser_v_offset + Vector2(0, 20 * d.y) if vert else Vector2(40 if d.x > 0 else -20, 0))
		var count := gap * (1 if vert else 2)
		if not blocked:
			# 沒被擋:一路排到關卡區邊緣,超出的部分畫的時候裁掉
			while _field_rect().intersects(Rect2(p0 + stp * count, Vector2(20, 20))):
				count += 1
		var mid := "d38_fx_laser_v_mid_" if vert else "d38_fx_laser_mid_"
		for i in count:
			segs.append({"name": mid, "pos": p0 + stp * i, "vert": vert, "flip": false})
		if blocked:
			# 最靠近擋下磚的那一段換成端點;緊貼時沒有中段,端點蓋在起點格靠擋下磚的那一半(count − 1 = −1)
			if count > 0:
				segs.pop_back()
			var end := "d38_fx_laser_block_"
			if d.y != 0:
				end = "d38_fx_laser_v_block_up_" if d.y < 0 else "d38_fx_laser_v_block_down_"
			segs.append({"name": end, "pos": p0 + stp * (count - 1), "vert": vert, "flip": d.x < 0})
	_anim("laser", pos, cfg.func_frame * 4, {"origin": "d38_fx_laser_origin_%s_" % axis, "segs": segs})
	_later(cfg.func_frame, _laser_hit.bind(hits, blockers))


## 擋下光束的魔王扣 laser_damage(每道光束各算一次);功能型磚觸發。
func _laser_hit(hits: Array[Vector2i], blockers: Array[Vector2i]) -> void:
	for h in hits:
		_damage(h, cfg.laser_damage)
	for b in blockers:
		var br: Brick = grid[b.y][b.x]
		if br != null and br.boss != null:
			_boss_damage(br.boss, cfg.laser_damage, b)
		else:
			_trigger(b)


## 閃電:n 道(= 碰觸前剩餘次數),各打一塊不重複的隨機多層磚(含特殊磚)或魔王(每隻算 1 個目標,落在牠隨機一格),
## 可打的不夠時打到現有數量為止;每道錯開 lightning_stagger 起始。
func _lightning(n: int) -> void:
	var pool := []
	for r in MAX_ROWS:
		for c in COLS:
			if _is_layered(grid[r][c]):
				pool.append(Vector2i(c, r))
	for bs in bosses:
		if bs.layers > 0:
			pool.append(bs.cells[rng.randi_range(0, bs.cells.size() - 1)])
	var targets := ItemDefs.pick_distinct(pool, n, rng)
	for i in targets.size():
		_later(cfg.lightning_stagger * i, _bolt.bind(targets[i]))


## 一道落雷:3 幀,F2 開頭(1 幀後)扣層(D17);目標在這之前已被破壞(魔王格已掉)就不劈。
func _bolt(target: Vector2i) -> void:
	var br: Brick = grid[target.y][target.x]
	if not _is_layered(br) and not (br != null and br.boss != null):
		return
	_anim("bolt", _cell_rect(target).position, cfg.func_frame * 3)
	_later(cfg.func_frame, _bolt_hit.bind(target))


func _bolt_hit(target: Vector2i) -> void:
	var br: Brick = grid[target.y][target.x]
	if br != null and br.boss != null:
		_boss_damage(br.boss, cfg.lightning_damage, target)
	else:
		_damage(target, cfg.lightning_damage)


## 爆炸:4 幀爆炸圖;F3 開頭(2 幀後)3×3 內多層磚不論層數直接移除、爆炸磚自己也移除(都不播破壞幀,D18);
## 範圍內其他爆炸磚在 explosion_chain_delay 後引爆。uses 已歸零,所以每顆只觸發 1 次。
func _explode(cell: Vector2i) -> void:
	_anim("explosion", _cell_rect(cell).position + cfg.explosion_fx_offset, cfg.func_frame * 4)
	_later(cfg.func_frame * 2, _explode_clear.bind(cell))
	_later(cfg.explosion_chain_delay, _explode_chain.bind(cell))


func _explode_clear(cell: Vector2i) -> void:
	for n in _neighbors(cell):
		var br: Brick = grid[n.y][n.x]
		if _is_layered(br):
			_damage(n, br.layers, true)
	_break_func(cell, false, false)


func _explode_chain(cell: Vector2i) -> void:
	for n in _neighbors(cell):
		var br: Brick = grid[n.y][n.x]
		if br != null and br.kind == "explosion":
			_trigger(n)


## 彩虹:從場上多層磚現有的顏色隨機挑一色(不論有沒有數字);挑色環 3 幀,該色的磚從第 2 幀起疊選中閃光 2 幀,
## 3 幀後該色磚全部破壞、彩虹磚自己也破壞(共 420 ms,D18)。沒有多層磚時直接破壞,不播挑色環。
func _rainbow(cell: Vector2i) -> void:
	var by_color := {}
	for r in MAX_ROWS:
		for c in COLS:
			var br: Brick = grid[r][c]
			# 特殊磚不屬七色,不會被挑到(README)
			if _is_layered(br) and br.special == "":
				by_color.get_or_add(Rules.layer_color(br.layers), []).append(Vector2i(c, r))
	if by_color.is_empty():
		_break_func(cell, true)
		return
	var keys := by_color.keys()
	var color: int = keys[rng.randi_range(0, keys.size() - 1)]
	var targets: Array = by_color[color]
	_anim("rainbow", _cell_rect(cell).position + cfg.rainbow_ring_offset, cfg.func_frame * 3,
		{"color": color, "targets": targets.map(func(t: Vector2i) -> Vector2: return _cell_rect(t).position)})
	_later(cfg.func_frame * 3, _rainbow_clear.bind(cell, targets))


func _rainbow_clear(cell: Vector2i, targets: Array) -> void:
	for t in targets:
		var br: Brick = grid[t.y][t.x]
		if _is_layered(br):
			_damage(t, br.layers, false, false)
	_break_func(cell, false)


## 傳送:被碰到的是入口,出口從其他傳送磚隨機挑;球在入口播吸入 4 幀、出口倒播 4 幀(共 8 幀不在場),
## 之後從出口磚中心以隨機角度(與水平夾角 ≥ min_angle_deg)飛出,離開出口磚之前不與它碰撞。
func _teleport(cell: Vector2i, ball: Ball) -> void:
	var exits := []
	for r in MAX_ROWS:
		for c in COLS:
			var br: Brick = grid[r][c]
			if br != null and br.kind == "teleport" and Vector2i(c, r) != cell:
				exits.append(Vector2i(c, r))
	if exits.is_empty():
		return
	var exit: Vector2i = exits[rng.randi_range(0, exits.size() - 1)]
	var f := cfg.func_frame
	_anim("tele_in", _cell_rect(cell).position, f * 4)
	_anim("vanish", ball.pos, f * 4)
	ball.pos = _cell_rect(exit).get_center()
	ball.dir = Rules.exit_dir(rng.randf(), rng.randf() < 0.5, cfg.min_angle_deg)
	ball.warp = f * 8
	ball.ghost = exit
	ball.inside = {}
	_later(f * 4, _anim.bind("tele_out", _cell_rect(exit).position, f * 4))
	# 傳送途中球可能被合併/大黑洞移除(_remove_balls 不設 gone,所以看是否還在 balls),移除了就不播出現
	_later(f * 4, func() -> void:
		if balls.has(ball):
			_anim("appear", ball.pos, f * 4))


# ===================== 魔王(D42、D43;規則見 README「魔王磚塊」) =====================

## 球打到魔王格:該格閃白;另外擲一次掉落(20% 減益、5% 增益,從擊中點往下掉,不吃一般 30% 判定)。
## 炸彈中只標記不扣血;回血中加層;其餘扣 (火焰 ? flame_damage : 1) + 強化,火焰另波及周圍 3×3(不重複算自己)。
## 無敵不影響魔王。ball 為 null(穿透進入不會發生,保留給直接呼叫)時不擲掉落。
func _boss_ball_hit(cell: Vector2i, ball: Ball) -> void:
	var br: Brick = grid[cell.y][cell.x]
	var bs := br.boss
	br.hit_t = FRAME
	if ball != null:
		var drop := Rules.boss_drop(rng.randf(), cfg.boss_debuff_chance, cfg.boss_buff_chance)
		if drop != "":
			# 反彈後球心離格 BALL_R,夾回格內的最近點就是擊中點
			_spawn_item(ball.pos.clamp(_cell_rect(cell).position, _cell_rect(cell).end), 1.0 if drop == "buff" else 0.0)
	if effects.is_active("bomb"):
		bs.marked = true
		return
	var heal := (cfg.heal_amount if effects.is_active("heal") else 0) + (cfg.heal_area_amount if effects.is_active("heal_area") else 0)
	if heal > 0:
		_boss_heal(bs, heal)
		if effects.is_active("heal_area"):
			_splash(cell, cfg.heal_area_splash, bs, true)
		return
	var flame := _flame_on()
	_boss_damage(bs, (cfg.flame_damage if flame else 1) + effects.reinforce, cell)
	if flame:
		_splash(cell, cfg.flame_splash, bs)


## 魔王扣層:每層 score_per_layer;依門檻表掉格(一次跨多個門檻同時掉多格,動畫錯開 boss_drop_stagger);
## 歸零時剩下的格全部掉落、加 score_boss_kill;全部魔王都死就進入勝利清場。flash = 要閃白的格。
func _boss_damage(bs: Boss, amount: int, flash := Vector2i(-1, -1)) -> void:
	if state != State.PLAYING or bs.layers <= 0 or amount <= 0:
		return
	var removed := mini(amount, bs.layers)
	# 血條尾端閃白:連續受擊時從還沒閃完的那段最高點開始算
	bs.bar_old = bs.bar_old if bs.bar_t > 0.0 else bs.layers
	bs.bar_t = FRAME
	bs.layers -= removed
	score += removed * cfg.score_per_layer
	if flash.x >= 0 and grid[flash.y][flash.x] != null:
		(grid[flash.y][flash.x] as Brick).hit_t = FRAME
	var drops := bs.cells.size() - Rules.boss_cells_left(bs.layers, bs.thresholds)
	for i in maxi(0, drops):
		var cell: Vector2i = bs.cells.pop_at(rng.randi_range(0, bs.cells.size() - 1))
		if i == 0:
			_boss_drop_cell(cell)
		else:
			_later(cfg.boss_drop_stagger * i, _boss_drop_cell.bind(cell))
	if bs.layers > 0:
		return
	score += cfg.score_boss_kill
	bs.marked = false
	if bosses.all(func(b: Boss) -> bool: return b.layers <= 0):
		# 等最後一格的破壞動畫(4 幀)播完才清場
		_boss_victory(cfg.boss_drop_stagger * maxi(0, drops - 1) + FRAME * 4)


## 魔王回血:不超過總層數;已掉的格不會長回來。
func _boss_heal(bs: Boss, amount: int) -> void:
	if bs.layers > 0:
		bs.layers = mini(bs.max_layers, bs.layers + amount)


## 一格魔王離場:從格子移除(不再碰撞,相鄰格下一幀就依新鄰接重拼外框),播單格破壞 F1~F3 + 灰塵。
func _boss_drop_cell(cell: Vector2i) -> void:
	grid[cell.y][cell.x] = null
	_anim("boss_break", _cell_rect(cell).position, FRAME * 4)


## 炸彈標記位置(D42):剩下的格子中最上排、最右的那一格。
func _boss_mark_cell(bs: Boss) -> Vector2i:
	var best := bs.cells[0]
	for c in bs.cells:
		if c.y < best.y or (c.y == best.y and c.x > best.x):
			best = c
	return best


## 魔王全滅:進入 CLEARING,delay 秒後剩下的可破壞磚(含功能型磚,不含不可破壞與傳送磚)由上到下、由左到右
## 依序播灰塵幀消失(不計分),全部消失後才出結束畫面;血條同時淡出。
## CLEARING 時金幣與道具不再更新,所以空中的金幣直接全數計入 coins_caught(不播特效),道具直接移除不生效。
func _boss_victory(delay: float) -> void:
	state = State.CLEARING
	bar_fade = 0.0
	for co in coins:
		coins_caught += co["value"]
	coins = []
	items = []
	var left: Array[Vector2i] = []
	for r in MAX_ROWS:
		for c in COLS:
			var br: Brick = grid[r][c]
			if br != null and not br.unbreakable and br.kind != "teleport" and br.boss == null:
				left.append(Vector2i(c, r))
	for i in left.size():
		_later(delay + cfg.boss_clear_stagger * i, _dust_cell.bind(left[i]))
	_later(maxf(delay + cfg.boss_clear_stagger * left.size() + FRAME, BAR_SLIDE), _end.bind(true, "魔王全部擊敗"))


func _dust_cell(cell: Vector2i) -> void:
	grid[cell.y][cell.x] = null
	_anim("dust", _cell_rect(cell).position, FRAME)


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
		# 傳送中的球分裂:新球跟著一起從出口出來,不會留在入口重疊傳送磚
		nb.warp = b.warp
		nb.ghost = b.ghost
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
	# shortcut: 金幣只在暫代結束畫面多一行文字,未進永久貨幣;正式結算畫面(UI 稿)出來後改到那裡顯示。
	# 分數維持最後一行:QA 測試以最後一個「分數 」後面的數字讀分數
	_show_end_screen("%s\n%s\n金幣：分數換算 %d + 接到 %d\n分數 %d" % ["過關！" if win else "失敗", reason,
		Rules.gold_from_score(score), coins_caught, score])


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
	label.position = Vector2(0, view_h / 2.0 - 140)
	label.size = Vector2(360, 130)
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
		# D38 功能型磚的磚圖在 art/bricks40、效果圖在 art/fx40
		# D39~D44 特殊磚、魔王、血條、BOSS 警告在 art/special40
		var dir := "bricks40" if name.begins_with("d31_") or name.begins_with("d37_") or name.begins_with("d38_brick_") \
			else "fx40" if name.begins_with("d38_fx_") else "items40" if name.begins_with("d32_") \
			else "hud32" if name.begins_with("d34_") \
			else "special40" if name.left(4) in ["d39_", "d40_", "d41_", "d42_", "d43_", "d44_"] else "generated"
		_tex[name] = load("res://art/%s/%s.png" % [dir, name])
	return _tex[name]


## 閃白版貼圖(D42 C:非 K、非透明的像素改 W),魔王格被擊中時用;第一次用到才產生並快取。
func _t_white(name: String) -> Texture2D:
	if not _white.has(name):
		var img := _t(name).get_image()
		img.decompress()
		for y in img.get_height():
			for x in img.get_width():
				var p := img.get_pixel(x, y)
				if p.a > 0.0 and not Color(p, 1.0).is_equal_approx(Pal.K):
					img.set_pixel(x, y, Color(Pal.W, p.a))
		_white[name] = ImageTexture.create_from_image(img)
	return _white[name]


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
	_paint_boss_bars(ci)


## 魔王血條(D43):警告結束後由 y 40 滑入 y 54(300 ms),全滅後 300 ms 淡出;減少動態時直接出現/消失。
## 一隻:x 24~335;兩隻:依魔王中心 x 由左到右對應左條 x 24~175、右條 x 184~335。
func _paint_boss_bars(ci: CanvasItem) -> void:
	if bosses.is_empty() or warn_left > 0.0:
		return
	var alpha := 1.0
	if bar_fade >= 0.0:
		alpha = 0.0 if reduced_motion else clampf(1.0 - bar_fade / BAR_SLIDE, 0.0, 1.0)
	if alpha <= 0.0:
		return
	var y := float(BAR_Y) if reduced_motion else lerpf(40.0, BAR_Y, clampf(bar_t / BAR_SLIDE, 0.0, 1.0))
	var order := bosses.duplicate()
	order.sort_custom(func(a: Boss, b: Boss) -> bool: return a.center_x < b.center_x)
	var w := 312 if order.size() == 1 else 152
	for i in order.size():
		_draw_boss_bar(ci, Vector2(24 + 160 * i, roundf(y)), w, order[i], alpha)


## 一條血條:帽 3 + 中段平鋪 + 帽 3;內槽填色(1×8 拉伸)、扣血尾端閃白、N−1 條掉格刻度、中央剩餘層數。
func _draw_boss_bar(ci: CanvasItem, o: Vector2, w: int, bs: Boss, alpha: float) -> void:
	var tint := Color(1, 1, 1, alpha)
	var inner := w - 6
	ci.draw_texture(_t("d43_bar_cap_l"), o, tint)
	ci.draw_texture_rect(_t("d43_bar_mid"), Rect2(o + Vector2(3, 0), Vector2(inner, 12)), false, tint)
	ci.draw_texture(_t("d43_bar_cap_r"), o + Vector2(w - 3, 0), tint)
	var fill := Rules.boss_bar_fill(bs.layers, bs.max_layers, inner)
	ci.draw_texture_rect(_t("d43_bar_fill"), Rect2(o + Vector2(3, 2), Vector2(fill, 8)), false, tint)
	if bs.bar_t > 0.0:
		var old := Rules.boss_bar_fill(bs.bar_old, bs.max_layers, inner)
		ci.draw_rect(Rect2(o + Vector2(3 + fill, 2), Vector2(old - fill, 8)), Color(Pal.W, alpha))
	for j in range(1, bs.size):
		ci.draw_rect(Rect2(o + Vector2(3 + roundi(inner * float(j) / bs.size), 2), Vector2(1, 8)), Color(Pal.K, alpha))
	# 數字:D31 數字圖裁出 7×9 字形(0 用 d43_digit_0),字距 7,置中,上緣 = 條上緣 + 1
	var digits := str(maxi(bs.layers, 0))
	@warning_ignore("integer_division")
	var x0 := o.x + (w - 7 * digits.length()) / 2
	for i in digits.length():
		var p := Vector2(x0 + 7 * i, o.y + 1)
		if digits[i] == "0":
			ci.draw_texture(_t("d43_digit_0"), p, tint)
		else:
			ci.draw_texture_rect_region(_t("d31_digit_" + digits[i]), Rect2(p, Vector2(7, 9)), Rect2(16, 5, 7, 9), tint)


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
			if br.boss != null:
				continue   # 整隻一起畫(_paint_bosses)
			if br.kind != "":
				_draw_func_brick(ci, pos, br, invincible)
				continue
			if br.special != "":
				_draw_special(ci, pos, br, invincible, mark)
				continue
			if br.unbreakable:
				ci.draw_texture(_t("d31_brick_unbreakable_hit" if br.hit_t > 0.0 else "d31_brick_unbreakable"), pos)
				continue
			var hit := br.hit_t > 0.0
			_draw_brick(ci, pos, br.hit_row if hit else Rules.sheet_row(br.layers, br.marked), hit)
			if invincible:
				ci.draw_texture(_t("d31_invincible_frame"), pos)
			if br.marked:
				ci.draw_texture(mark, pos)
	_paint_bosses(ci, mark)
	for a in anims:
		match a["kind"]:
			"break":
				# 第 0 幀 = 被擊中(扣層前的數字),第 1~3 幀 = 破壞 F1~F3(依顏色),第 4 幀 = 灰塵;破壞幀不疊數字。
				# 沒有被擊中幀時從 F1 開始;用 get 是因為 qa_window_2x_capture 直接塞的動畫沒有 "hit" 鍵。
				# 特殊磚用自己的 _hit、_f1~_f3(圓形磚 20×20 置中),灰塵同樣是整格 40×20
				var f := int(a["t"] / FRAME) + (0 if a.get("hit", true) else 1)
				var sp: String = a.get("special", "")
				var sp_pos: Vector2 = a["pos"] + (CIRCLE_OFFSET if sp == "circle" else Vector2.ZERO)
				if f == 0 and sp != "":
					ci.draw_texture(_t(SPECIAL_ART[sp] + "_hit"), sp_pos)
				elif f == 0:
					_draw_brick(ci, a["pos"], a["hit_row"], true)
				elif f < 4 and sp != "":
					ci.draw_texture(_t("%s_f%d" % [SPECIAL_ART[sp], f]), sp_pos)
				elif f < 4:
					ci.draw_texture(_t("d31_brick_%s_f%d" % [Rules.COLOR_NAMES[a["color"]], f]), a["pos"])
				else:
					ci.draw_texture(_t("d31_brick_dust_f4"), a["pos"])
			"boss_break":
				# D42 單格破壞:F1~F3 + 灰塵,各 60 ms
				var f := mini(int(a["t"] / FRAME), 3)
				ci.draw_texture(_t("d42_boss_f%d" % (f + 1) if f < 3 else "d31_brick_dust_f4"), a["pos"])
			"dust":
				ci.draw_texture(_t("d31_brick_dust_f4"), a["pos"])
			"func_break":
				# 有被擊中幀時第 0 幀 = 被擊中(次數 1),之後 F1~F3 用 D38 材質圖、F4 灰塵
				var f := int(a["t"] / cfg.func_frame) + (0 if a["hit"] != "" else 1)
				if f == 0:
					ci.draw_texture(_t(a["hit"]), a["pos"])
					if a["digit"]:
						ci.draw_texture(_t("d31_digit_1"), a["pos"] + cfg.func_digit_offset)
				elif f < 4:
					ci.draw_texture(_t("d38_brick_%s_f%d" % [a["mat"], f]), a["pos"])
				else:
					ci.draw_texture(_t("d31_brick_dust_f4"), a["pos"])
			# 子彈的擊中/擋下特效跟子彈一樣維持原尺寸
			"bullet_hit":
				ci.draw_texture(_t("d19_bullet_hit_f1" if a["t"] < 0.06 else "d19_bullet_hit_f2"), a["pos"])
			"bullet_block":
				ci.draw_texture(_t("d19_bullet_block_f1" if a["t"] < 0.08 else "d19_bullet_block_f2"), a["pos"])
	_paint_func_fx(ci)


## 功能型磚:磚體(被擊中時換 _hit 圖,傳送磚不閃白)+ 剩餘次數(d31_digit_N 右偏 func_digit_offset)+ 無敵外框(傳送磚不套)。
func _draw_func_brick(ci: CanvasItem, pos: Vector2, br: Brick, invincible: bool) -> void:
	var hit := br.hit_t > 0.0 and br.kind != "teleport"
	ci.draw_texture(_t("d38_brick_%s%s" % [br.kind, "_hit" if hit else ""]), pos)
	var n := br.hit_row if hit else br.uses
	if br.kind in Rules.COUNTED_KINDS and n > 0:
		ci.draw_texture(_t("d31_digit_%d" % n), pos + cfg.func_digit_offset)
	if invincible and br.kind != "teleport":
		ci.draw_texture(_t("d31_invincible_frame"), pos)


## 特殊磚(D39~D41):磚體(被擊中換 _hit)+ 無敵外框(圓形用 d39_invincible_circle)+ 炸彈標記(圓形偏移 CIRCLE_MARK_OFFSET)。
func _draw_special(ci: CanvasItem, pos: Vector2, br: Brick, invincible: bool, mark: Texture2D) -> void:
	var circle := br.special == "circle"
	var p := pos + (CIRCLE_OFFSET if circle else Vector2.ZERO)
	ci.draw_texture(_t(SPECIAL_ART[br.special] + ("_hit" if br.hit_t > 0.0 else "")), p)
	if invincible:
		ci.draw_texture(_t("d39_invincible_circle" if circle else "d31_invincible_frame"), p)
	if br.marked:
		ci.draw_texture(mark, pos + (CIRCLE_MARK_OFFSET if circle else Vector2.ZERO))


## 魔王(D42):每隻依目前還在格子上的格算鄰接,逐批疊元件(本體 → 外緣 → 外凸 → 內凹 → 節點),
## 再疊裂痕、炸彈標記,最後被擊中的格用閃白版元件蓋上去。無敵不影響魔王,不畫無敵外框。
## shortcut: 每幀直接疊元件(一隻最多十幾格、約百次繪製),沒有預先烘成一張貼圖;魔王格數變多卡頓時再改成掉格時才重烘
func _paint_bosses(ci: CanvasItem, mark: Texture2D) -> void:
	for bs in bosses:
		var cells: Array[Vector2i] = []
		for r in MAX_ROWS:
			for c in COLS:
				var br: Brick = grid[r][c]
				if br != null and br.boss == bs:
					cells.append(Vector2i(c, r))
		if cells.is_empty():
			continue
		var has := func(n: Vector2i) -> bool:
			return n.x >= 0 and n.x < COLS and n.y >= 0 and n.y < MAX_ROWS and grid[n.y][n.x] != null and grid[n.y][n.x].boss == bs
		var parts := {}
		for cell in cells:
			parts[cell] = Rules.boss_parts(cell, has)
		for layer in 5:
			for cell in cells:
				for p in parts[cell]:
					if p[0] == layer:
						ci.draw_texture(_t(p[1]), _cell_rect(cell).position + Vector2(p[2]))
		var crack := Rules.boss_crack(bs.layers, bs.cells.size(), bs.thresholds)
		for cell in cells:
			if crack > 0:
				ci.draw_texture(_t("d42_boss_crack_%d" % crack), _cell_rect(cell).position)
		if bs.marked and not bs.cells.is_empty():
			ci.draw_texture(mark, _cell_rect(_boss_mark_cell(bs)).position)
		for cell in cells:
			if (grid[cell.y][cell.x] as Brick).hit_t > 0.0:
				for p in parts[cell]:
					ci.draw_texture(_t_white(p[1]), _cell_rect(cell).position + Vector2(p[2]))


## 功能型磚效果圖,畫在磚與破壞動畫之上(D17、D18 繪製順序),超出關卡區的部分裁掉。
## 雷射:所有水平段 → 所有垂直段(交叉時垂直蓋水平)→ 起點;4 幀依序 thin、full、full、thin。
func _paint_func_fx(ci: CanvasItem) -> void:
	var f := cfg.func_frame
	var lasers := anims.filter(func(a: Dictionary) -> bool: return a["kind"] == "laser")
	for vert in [false, true]:
		for a in lasers:
			for s in a["segs"]:
				if s["vert"] == vert:
					_draw_fx(ci, _t(s["name"] + _beam_width(a)), s["pos"], s["flip"])
	for a in lasers:
		_draw_fx(ci, _t(a["origin"] + _beam_width(a)), a["pos"])
	for a in anims:
		# 目前第幾幀(從 0 起);夾在幀數內,避免 t 剛好接近 dur 時浮點誤差算出不存在的幀
		var k := mini(int(a["t"] / f), roundi(a["dur"] / f) - 1)
		match a["kind"]:
			"bolt":
				# 方案 B(D38):頂端貼關卡區上緣,中段每 20 px 一張接到落點圖上緣,落點圖貼目標磚 − 10
				var top := _t("d38_fx_lightning_b_top_f%d" % (k + 1))
				var x: float = a["pos"].x
				_draw_fx(ci, top, Vector2(x, FIELD_TOP))
				for i in int((a["pos"].y - BRICK_TOP) / BRICK_H):
					_draw_fx(ci, _t("d38_fx_lightning_b_mid_f%d" % (k + 1)), Vector2(x, FIELD_TOP + top.get_height() + BRICK_H * i))
				_draw_fx(ci, _t("d38_fx_lightning_b_hit_f%d" % (k + 1)), a["pos"] + cfg.lightning_hit_offset)
			"explosion":
				_draw_fx(ci, _t("d38_fx_explosion_f%d" % (k + 1)), a["pos"])
			"rainbow":
				_draw_fx(ci, _t("d38_fx_rainbow_pick_%s_f%d" % [Rules.COLOR_NAMES[a["color"]], k + 1]), a["pos"])
				if k >= 1:
					for p in a["targets"]:
						_draw_fx(ci, _t("d38_fx_rainbow_target_f%d" % k), p)
			"tele_in":
				_draw_fx(ci, _t("d38_fx_teleport_in_f%d" % (k + 1)), a["pos"])
			"tele_out":
				_draw_fx(ci, _t("d38_fx_teleport_in_f%d" % (4 - k)), a["pos"])


func _beam_width(a: Dictionary) -> String:
	return "full" if int(a["t"] / cfg.func_frame) in [1, 2] else "thin"


## 以 1 倍畫效果圖,只畫落在關卡區內的部分;flip = 水平鏡射(往左的光束端點)。
func _draw_fx(ci: CanvasItem, tex: Texture2D, pos: Vector2, flip := false) -> void:
	var dst := Rect2(pos, tex.get_size()).intersection(_field_rect())
	if dst.size.x <= 0.0 or dst.size.y <= 0.0:
		return
	var src := Rect2(dst.position - pos, dst.size)
	if flip:
		# 鏡射後畫面上的這一段對應原圖另一側;目的矩形寬為負 = 水平翻轉
		src.position.x = tex.get_width() - src.end.x
		dst = Rect2(dst.end.x, dst.position.y, -dst.size.x, dst.size.y)
	ci.draw_texture_rect_region(tex, dst, src)


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
	# 金幣(D41):4 幀轉動各 100 ms(減少動態時固定 F1);接到特效 3 幀各 60 ms
	var cf := 1 if reduced_motion else int(_phase(COIN_FRAME * 4) / COIN_FRAME) + 1
	for co in coins:
		ci.draw_texture(_t("d41_coin_%d_f%d" % [co["value"], mini(cf, 4)]), _coin_rect(co["value"], co["pos"]).position.floor())
	for a in anims:
		if a["kind"] == "coin_pick":
			ci.draw_texture(_t("d41_coin_pick_f%d" % mini(_pickup_frame(a["t"]), 3)), (a["pos"] as Vector2).floor())


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
		if b.warp <= 0.0:
			_draw_px(ci, tex, (b.pos - Vector2(7, 7) * PX).floor())


## 球光暈是否顯示:獲得順序清單中有任何一格是球的狀態(D35,D36 Q3 補例外)。
func _halo_on() -> bool:
	return hud_order.any(func(k: String) -> bool: return k in HALO_KINDS)


func _paint_balls(ci: CanvasItem) -> void:
	var tex := _t("d15_ball_normal")
	for b in balls:
		# 傳送中的球不畫(由入口吸入、出口倒播的動畫代替)
		if b.warp <= 0.0:
			_draw_px(ci, tex, (b.pos - Vector2(BALL_R, BALL_R)).floor())
	for a in anims:
		# 4 幀平分整段時間:一般消失用 FRAME,傳送用 func_frame;appear = 倒播(傳送出口)
		var f := mini(int(a["t"] * 4 / a["dur"]), 3)
		if a["kind"] == "vanish":
			_draw_px(ci, _t("d15_ball_vanish_f%d" % (f + 1)), (a["pos"] - Vector2(7, 7) * PX).floor())
		elif a["kind"] == "appear":
			_draw_px(ci, _t("d15_ball_vanish_f%d" % (4 - f)), (a["pos"] - Vector2(7, 7) * PX).floor())


## BOSS 警告(D44,共 1.6 秒):0~0.2 秒由左滑入、0.2~1.4 停住(文字亮暗交替 6 張各 120 ms 後停在亮)、
## 1.4~1.6 向右滑出;停住時警示條每 120 ms 往右 4 px。減少動態時不滑動、不閃、條紋不動。
func _paint_warning(ci: CanvasItem) -> void:
	if warn_left <= 0.0:
		return
	var t := BOSS_WARN - warn_left
	var dx := 0.0
	var shift := 0
	var bright := true
	if not reduced_motion:
		if t < 0.2:
			dx = lerpf(-360.0, 0.0, t / 0.2)
		elif t >= 1.4:
			dx = lerpf(0.0, 360.0, (t - 1.4) / 0.2)
		var held := clampf(t - 0.2, 0.0, 1.2)
		shift = (int(held / 0.12) * 4) % 16
		bright = held >= 0.72 or int(held / 0.12) % 2 == 0
	dx = roundf(dx)
	var stripe := _t("d44_warn_stripe")
	for y in [368, 424]:
		# 多鋪一張再往右平移 shift,左端從 −16 起,平移後仍蓋滿 360
		for x in range(-16, 360, 16):
			ci.draw_texture(stripe, Vector2(dx + x + shift, y))
	ci.draw_rect(Rect2(dx, 376, 360, 48), Color(Pal.BOSS_V, 0.85))
	ci.draw_texture(_t("d44_boss_text_f1" if bright else "d44_boss_text_f2"), Vector2(dx + 132, 384))


## 以整數 PX 倍畫出原尺寸圖(專案預設濾鏡為 nearest,不會糊);pos 是放大後的左上角。
func _draw_px(ci: CanvasItem, tex: Texture2D, pos: Vector2, tint := Color.WHITE) -> void:
	ci.draw_texture_rect(tex, Rect2(pos, tex.get_size() * PX), false, tint)


## 以 1 倍畫一塊多層磚:底圖(被擊中時換成共用的閃白圖)+ 數字疊加層。row 是 Rules.sheet_row 的列號。
func _draw_brick(ci: CanvasItem, pos: Vector2, row: int, hit: bool) -> void:
	var art := Rules.brick_art(row)
	ci.draw_texture(_t("d31_brick_hit" if hit else art[0]), pos)
	if art[1] != "":
		ci.draw_texture(_t(art[1]), pos)
