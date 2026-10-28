## 純規則計算(不碰場景),遊戲與 headless 測試共用。
## 規則來源:README「基本數值」與計分、D12 多層磚新規則、D13 擋板長度、D16 線段條、D22 時間閃爍。
class_name Rules
extends RefCounted

const COLORS_PER_ROUND := 7
## 顏色索引 → D31 磚圖檔名用的顏色名。
const COLOR_NAMES: Array[String] = ["red", "orange", "yellow", "green", "blue", "indigo", "purple"]
## 關卡資料中的不可破壞磚。
const UNBREAKABLE := -1
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


## 解析關卡資料(系統邊界:外部檔案,逐格檢查)。
## data 格式:{"rows": ["cols 個以空白分隔的格", ...]};格:"." 空、"U" 不可破壞、"1"~"max_layers" 多層磚。
## 回傳 {"cells": Array[Array[int]](0 空、-1 不可破壞、n 層數), "errors": PackedStringArray};
## 有錯的格當成空格,讓其餘部分仍可遊玩;超過 max_rows 的排、超過 cols 的格不載入並記錯誤。
static func parse_level(data: Variant, max_rows: int, cols: int, max_layers: int) -> Dictionary:
	var cells: Array = []
	var errors := PackedStringArray()
	if not (data is Dictionary and data.get("rows") is Array):
		errors.append("缺少 rows 陣列")
		return {"cells": cells, "errors": errors}
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
			else:
				errors.append("第 %d 排第 %d 格「%s」無效" % [r, c, t])
				line.append(0)
		cells.append(line)
	return {"cells": cells, "errors": errors}
