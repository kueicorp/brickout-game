## 純規則計算(不碰場景),遊戲與 headless 測試共用。
## 規則來源:README「基本數值」與計分、D12 多層磚新規則、D13 擋板長度、D16 線段條、D22 時間閃爍。
class_name Rules
extends RefCounted

const COLORS_PER_ROUND := 7
## 顏色索引 → D31 磚圖檔名用的顏色名。
const COLOR_NAMES: Array[String] = ["red", "orange", "yellow", "green", "blue", "indigo", "purple"]
## 關卡資料中的不可破壞磚。
const UNBREAKABLE := -1
## 關卡資料中的功能型磚(種類與次數另存在 parse_level 回傳的 funcs)。
const FUNC := -2
## 關卡代號 → 功能型磚種類(種類名 = D38 圖檔名 d38_brick_<種類>)。
const FUNC_CODES := {"LH": "laser_h", "LV": "laser_v", "LX": "laser_x", "Z": "lightning", "R": "reaper",
	"E": "explosion", "W": "rainbow", "T": "teleport"}
## 有剩餘次數(顯示數字、載入時隨機 1~FUNC_USES_MAX)的種類;其餘只能碰 1 次或沒有次數(傳送)。
const COUNTED_KINDS: Array[String] = ["laser_h", "laser_v", "laser_x", "lightning", "reaper"]
const FUNC_USES_MAX := 9
## 關卡資料中的特殊磚(寶箱、金幣、圓形;種類另存在 parse_level 回傳的 specials)。
const SPECIAL := -3
## 關卡資料中的魔王格(屬於哪一隻另存在 parse_level 回傳的 bosses)。
const BOSS := -4
## 關卡代號 → 特殊磚種類(D39~D41;固定 1 層,不屬七色)。
const SPECIAL_CODES := {"H": "chest", "G": "coin", "O": "circle"}
## 魔王代號;同一代號的格子為同一隻(一關最多 2 隻)。
const BOSS_CODES: Array[String] = ["B1", "B2"]
## D16 線段條內部寬度(px)。
const BAR_INNER := 20


## 層數 → 顏色索引(0 紅、1 橙、2 黃、3 綠、4 藍、5 靛、6 紫)。
static func layer_color(layer: int) -> int:
	return (layer - 1) % COLORS_PER_ROUND


## 層數 → 輪數(= 磚上數字,0 不顯示)。
@warning_ignore("integer_division")
static func layer_round(layer: int) -> int:
	return (layer - 1) / COLORS_PER_ROUND


## 磚圖列號(= 層數 − 1,沿用舊精靈圖的名稱);交給 brick_art 選圖。
## 炸彈標記期間改用同顏色的第 0 輪圖(無數字),即列號 = 顏色索引。
static func sheet_row(layer: int, marked: bool) -> int:
	return layer_color(layer) if marked else layer - 1


## 磚圖列號 → [底圖名, 數字疊加層名](art/bricks40 的 D31 圖);第 0 輪不顯示數字,疊加層名為空字串。
static func brick_art(row: int) -> Array:
	var n := layer_round(row + 1)
	return ["d31_brick_" + COLOR_NAMES[layer_color(row + 1)], "d31_digit_%d" % n if n > 0 else ""]


## 扣層後的層數(不低於 0;0 = 破壞)。
static func damage_layers(layers: int, amount: int) -> int:
	return maxi(0, layers - amount)


## 回血後的層數(不超過上限)。
static func heal_layers(layers: int, amount: int, max_layers: int) -> int:
	return mini(max_layers, layers + amount)


## 擋板長度:基準長度乘上所有生效中的倍率,四捨五入後限制在上下限內(D13 規則)。
static func paddle_length(base: float, factors: Array, min_len: int, max_len: int) -> int:
	var length := base
	for f in factors:
		length *= f
	return clampi(roundi(length), min_len, max_len)


## 速度階數 → 倍率。每階以基準速度為準線性加減(例:+4 階 = 1.6 倍)。
static func tier_multiplier(tier: int, step: float) -> float:
	return 1.0 + step * tier


## 階數加減後限制在範圍內。
static func step_tier(tier: int, delta: int, lo: int, hi: int) -> int:
	return clampi(tier + delta, lo, hi)


## 連續線段的填色寬度 = 向上取整(20 × 剩餘 ÷ 總時間),剩 0 秒為 0。
static func timebar_fill(remaining: float, total: float) -> int:
	if remaining <= 0.0 or total <= 0.0:
		return 0
	return clampi(ceili(BAR_INNER * remaining / total), 0, BAR_INNER)


## 分段線段每段寬度:w = (20 − (N − 1)) ÷ N 取整,餘下的欄由最左邊的段各多 1 欄。
@warning_ignore("integer_division")
static func segment_widths(n: int) -> Array[int]:
	var w := (BAR_INNER - (n - 1)) / n
	var extra := BAR_INNER - (n - 1) - n * w
	var out: Array[int] = []
	for i in n:
		out.append(w + 1 if i < extra else w)
	return out


## 分段線段每段在 7 種灰中的索引:round((i − 1) × 6 ÷ (N − 1)),0.5 進位。
static func segment_gray_indices(n: int) -> Array[int]:
	var out: Array[int] = []
	for i in n:
		out.append(0 if n == 1 else floori(i * 6.0 / (n - 1) + 0.5))
	return out


## 畫面上顯示的剩餘整秒數(向上取整,開局 300 秒顯示 5:00)。
static func remaining_seconds(remaining: float) -> int:
	# 減一點點容差,避免 30.0000001 這類浮點誤差被進位成 31
	return maxi(0, ceili(remaining - 0.000001))


## 時間文字:9:59 以下為 M:SS,以上為 MM:SS。
@warning_ignore("integer_division")
static func time_text(remaining: float) -> String:
	var s := remaining_seconds(remaining)
	return "%d:%02d" % [s / 60, s % 60]


## 時間是否顯示紅色(D22):剩 30~11 秒時偶數秒的前 500 ms、剩 10~1 秒時每秒的前 500 ms;0 秒停在紅色。
static func time_is_red(remaining: float) -> bool:
	if remaining <= 0.0:
		return true
	var s := remaining_seconds(remaining)
	if s > 30 or (s > 10 and s % 2 == 1):
		return false
	# 「那一秒的前 500 ms」= 剩餘時間仍大於 s − 0.5
	return remaining > s - 0.5


## 勝利時的剩餘時間加分(以完整秒計)。
static func time_bonus(remaining: float, per_second: int) -> int:
	return floori(maxf(remaining, 0.0)) * per_second


## 一次扣層的得分:每層一份,若因此破壞再加破壞分。
static func brick_score(removed: int, destroyed: bool, per_layer: int, per_brick: int) -> int:
	return removed * per_layer + (per_brick if destroyed else 0)


## 小偷偷分後的分數(最低 0)。
static func thief_steal(score: int, amount: int) -> int:
	return maxi(0, score - amount)


## 從水平夾角 ≥ min_deg 的方向中取一個(傳送出口用):u ∈ [0, 1] 決定角度,down 決定往下或往上。
## 涵蓋 360° 內排除水平 ±min_deg 的兩段。
static func exit_dir(u: float, down: bool, min_deg: float) -> Vector2:
	var deg := lerpf(min_deg, 180.0 - min_deg, u)
	return Vector2.from_angle(deg_to_rad(deg if down else -deg))


## 解析關卡資料(系統邊界:外部檔案,逐格檢查)。
## data 格式:{"rows": ["cols 個以空白分隔的格", ...]};格:"." 空、"U" 不可破壞、"1"~"max_layers" 多層磚、
## 功能型磚代號(FUNC_CODES;雷射、閃電、死神可在代號後加 1~9 指定次數,例 "LH5")、
## 特殊磚代號(SPECIAL_CODES)、魔王格(BOSS_CODES,同代號的格子不必相連)。
## 回傳 {"cells": Array[Array[int]](0 空、-1 不可破壞、FUNC 功能型、SPECIAL 特殊磚、BOSS 魔王格、n 層數),
## "funcs": {Vector2i(欄, 排): {"kind": 種類, "uses": 次數(0 = 未指定,由載入端隨機)}},
## "specials": {Vector2i: 種類}, "bosses": {代號: Array[Vector2i](讀取順序)}, "errors": PackedStringArray};
## 有錯的格當成空格,讓其餘部分仍可遊玩;超過 max_rows 的排、超過 cols 的格不載入並記錯誤;
## 傳送磚是奇數塊時丟棄最後一塊(由上到下、由左到右的最後一塊)並記錯誤。
static func parse_level(data: Variant, max_rows: int, cols: int, max_layers: int) -> Dictionary:
	var cells: Array = []
	var funcs := {}
	var specials := {}
	var bosses := {}
	var errors := PackedStringArray()
	if not (data is Dictionary and data.get("rows") is Array):
		errors.append("缺少 rows 陣列")
		return {"cells": cells, "funcs": funcs, "specials": specials, "bosses": bosses, "errors": errors}
	var rows: Array = data["rows"]
	if rows.size() > max_rows:
		errors.append("排數 %d 超過上限 %d,多的排忽略" % [rows.size(), max_rows])
	for r in mini(rows.size(), max_rows):
		var tokens := str(rows[r]).split(" ", false)
		if tokens.size() != cols:
			errors.append("第 %d 排有 %d 格,應為 %d 格" % [r, tokens.size(), cols])
		var line: Array[int] = []
		for c in cols:
			var t := tokens[c] if c < tokens.size() else "."
			if t == ".":
				line.append(0)
			elif t == "U":
				line.append(UNBREAKABLE)
			elif t.is_valid_int() and t.to_int() >= 1 and t.to_int() <= max_layers:
				line.append(t.to_int())
			elif _func_cell(t) != {}:
				line.append(FUNC)
				funcs[Vector2i(c, r)] = _func_cell(t)
			elif SPECIAL_CODES.has(t):
				line.append(SPECIAL)
				specials[Vector2i(c, r)] = SPECIAL_CODES[t]
			elif t in BOSS_CODES:
				line.append(BOSS)
				bosses.get_or_add(t, []).append(Vector2i(c, r))
			else:
				errors.append("第 %d 排第 %d 格「%s」無效" % [r, c, t])
				line.append(0)
		cells.append(line)
	var teleports := funcs.keys().filter(func(k: Vector2i) -> bool: return funcs[k]["kind"] == "teleport")
	if teleports.size() % 2 == 1:
		# funcs 依讀取順序插入,最後一個鍵就是最後一塊
		var last: Vector2i = teleports[-1]
		errors.append("傳送磚有 %d 塊(應成對),丟棄第 %d 排第 %d 格" % [teleports.size(), last.y, last.x])
		funcs.erase(last)
		cells[last.y][last.x] = 0
	return {"cells": cells, "funcs": funcs, "specials": specials, "bosses": bosses, "errors": errors}


## 一格功能型磚代號 → {"kind", "uses"};不是有效代號時回傳空字典。
static func _func_cell(t: String) -> Dictionary:
	var code := t.rstrip("123456789")
	if not FUNC_CODES.has(code):
		return {}
	var kind: String = FUNC_CODES[code]
	var n := t.substr(code.length())
	if n == "":
		return {"kind": kind, "uses": 0}
	# 只有雷射、閃電、死神有次數;次數只能是 1 位數 1~9(數字圖只有 1~9)
	if kind in COUNTED_KINDS and n.length() == 1:
		return {"kind": kind, "uses": n.to_int()}
	return {}


# ===================== 特殊磚與魔王(D39~D43) =====================

## 魔王掉格門檻表(D42 Q6):回傳 [H, t1, …, t(N−1), 0],共 N + 1 個。
## t_k = 向上取整(H × (N − k) ÷ N);剩餘層數 ≤ t_k 時掉第 k 格,0 層時最後一格破壞。
@warning_ignore("integer_division")
static func boss_thresholds(total: int, cells: int) -> Array[int]:
	var out: Array[int] = [total]
	for k in range(1, cells):
		out.append((total * (cells - k) + cells - 1) / cells)
	out.append(0)
	return out


## 目前層數下魔王應該剩幾格(不含回血長回來:呼叫端取 min)。
## = 1 + 「層數仍高於的中間門檻」數;0 層 = 0 格。
static func boss_cells_left(layers: int, thresholds: Array[int]) -> int:
	if layers <= 0:
		return 0
	var n := 1
	for k in range(1, thresholds.size() - 1):
		if layers > thresholds[k]:
			n += 1
	return n


## 裂痕疊加(D42 C):這一段血量(上一個門檻到下一個門檻)消耗 < 1/3 → 0、1/3~2/3 → 1、≥ 2/3 → 2。
## cells = 目前剩下的格數;回血超過這段上限時視為沒消耗。
static func boss_crack(layers: int, cells: int, thresholds: Array[int]) -> int:
	var n := thresholds.size() - 1
	if cells <= 0 or cells > n:
		return 0
	var hi := thresholds[n - cells]
	var span := hi - thresholds[n - cells + 1]
	var used := hi - layers
	if span <= 0 or used * 3 < span:
		return 0
	return 1 if used * 3 < span * 2 else 2


## 一格魔王要疊的元件(D42 B):[繪製批次, 圖名, 相對格左上角的位移]。
## 批次 0 本體、1 外緣條、2 外凸轉角、3 內凹轉角、4 能量節點;整隻魔王要逐批畫,節點才會蓋在兩格交界上。
## has(cell) 回傳該格是否屬於同一隻且還在場上。
static func boss_parts(cell: Vector2i, has: Callable) -> Array:
	var up: bool = has.call(cell + Vector2i.UP)
	var down: bool = has.call(cell + Vector2i.DOWN)
	var left: bool = has.call(cell + Vector2i.LEFT)
	var right: bool = has.call(cell + Vector2i.RIGHT)
	var out := [[0, "d42_boss_fill", Vector2i.ZERO]]
	if not up:
		out.append([1, "d42_boss_edge_t", Vector2i(0, 0)])
	if not down:
		out.append([1, "d42_boss_edge_b", Vector2i(0, 17)])
	if not left:
		out.append([1, "d42_boss_edge_l", Vector2i(0, 0)])
	if not right:
		out.append([1, "d42_boss_edge_r", Vector2i(37, 0)])
	if not up and not left:
		out.append([2, "d42_boss_corner_tl", Vector2i(0, 0)])
	if not up and not right:
		out.append([2, "d42_boss_corner_tr", Vector2i(37, 0)])
	if not down and not left:
		out.append([2, "d42_boss_corner_bl", Vector2i(0, 17)])
	if not down and not right:
		out.append([2, "d42_boss_corner_br", Vector2i(37, 17)])
	if up and left and not has.call(cell + Vector2i(-1, -1)):
		out.append([3, "d42_boss_concave_nw", Vector2i(0, 0)])
	if up and right and not has.call(cell + Vector2i(1, -1)):
		out.append([3, "d42_boss_concave_ne", Vector2i(37, 0)])
	if down and right and not has.call(cell + Vector2i(1, 1)):
		out.append([3, "d42_boss_concave_se", Vector2i(37, 17)])
	if down and left and not has.call(cell + Vector2i(-1, 1)):
		out.append([3, "d42_boss_concave_sw", Vector2i(0, 17)])
	if left:
		out.append([4, "d42_boss_joint_h", Vector2i(-2, 7)])
	return out


## 血條填色寬度 = 向上取整(內槽寬 × 目前層數 ÷ 總層數);只要還有 1 層就看得到。
static func boss_bar_fill(layers: int, total: int, inner: int) -> int:
	if layers <= 0 or total <= 0:
		return 0
	return clampi(ceili(inner * float(layers) / total), 0, inner)


## 魔王被球擊中時的掉落判定(單次擲骰):u < 減益機率 → "debuff"、再 < 減益 + 增益 → "buff"、其餘不掉。
static func boss_drop(u: float, debuff_chance: float, buff_chance: float) -> String:
	if u < debuff_chance:
		return "debuff"
	if u < debuff_chance + buff_chance:
		return "buff"
	return ""


## 金幣面額:u ∈ [0, 1) 依累積權重挑(預設 10 / 50 / 100 = 60% / 30% / 10%)。
static func coin_value(u: float, values: Array, weights: Array) -> int:
	var acc := 0.0
	for i in values.size():
		acc += weights[i]
		if u < acc:
			return values[i]
	return values[-1]


## 圓形磚反彈(D39):隨機方向,朝離開圓的方向(與法線 n 同側),且與水平夾角 ≥ min_deg(同傳送磚出口)。
## 用 exit_dir 抽樣、不在 n 同側就重抽;n 為單位向量。
static func circle_bounce(n: Vector2, rng: RandomNumberGenerator, min_deg: float) -> Vector2:
	for i in 64:
		var d := exit_dir(rng.randf(), rng.randf() < 0.5, min_deg)
		if d.dot(n) > 0.0:
			return d
	# 連抽 64 次都在另一側的機率可忽略;保底走 n 本身並夾到最小角度
	var s := sin(deg_to_rad(min_deg))
	var y := signf(n.y) if n.y != 0.0 else 1.0
	return n if absf(n.y) >= s else Vector2(signf(n.x) * sqrt(1.0 - s * s), y * s)


## 分數換算金幣(README:分數的 1%,四捨五入到整數)。
@warning_ignore("integer_division")
static func gold_from_score(score: int) -> int:
	return (maxi(score, 0) + 50) / 100
