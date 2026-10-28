## 本局生效中的道具效果。
## 限時效果:相同效果還在時再撿到,剩餘時間累積,並以累積後的剩餘時間當新的總時間(D16);
## 不同效果各自計時、可同時存在。其餘欄位為整局有效的效果。
class_name Effects
extends RefCounted

## id → {"remaining": 秒, "total": 秒}
var timed := {}
## 強化加成(每次撞磚多扣的層數)。
var reinforce := 0
## 球速淨階數(加速 +、減速 −,互相抵銷)。
var ball_tier := 0
## 擋板速度淨階數。
var paddle_tier := 0
var sticky := false
var gun := false
## 付費「附魔」整局效果("pierce"、"flame" 或空字串);本原型由除錯設定模擬。
var enchant := ""


func add_timed(id: String, duration: float) -> void:
	var left: float = duration + (timed[id]["remaining"] if timed.has(id) else 0.0)
	timed[id] = {"remaining": left, "total": left}


func is_active(id: String) -> bool:
	return timed.has(id)


func remaining(id: String) -> float:
	return timed[id]["remaining"] if timed.has(id) else 0.0


func total(id: String) -> float:
	return timed[id]["total"] if timed.has(id) else 0.0


## 經過 dt 秒;回傳這次到期(已移除)的效果 id。
func tick(dt: float) -> Array[String]:
	var expired: Array[String] = []
	for id in timed:
		timed[id]["remaining"] -= dt
		if timed[id]["remaining"] <= 0.0:
			expired.append(id)
	for id in expired:
		timed.erase(id)
	return expired


## 生效中的擋板長度倍率。最大化、最短化換算成「上限 ÷ 基準」「下限 ÷ 基準」,與其他倍率一樣相乘。
func paddle_factors(cfg: GameConfig) -> Array[float]:
	var table := {
		"paddle_len_1": cfg.len_small_up,
		"paddle_len_2": cfg.len_big_up,
		"paddle_len_max": cfg.paddle_max_length / cfg.paddle_base_length,
		"paddle_len_down_1": cfg.len_small_down,
		"paddle_len_down_2": cfg.len_big_down,
		"paddle_len_min": cfg.paddle_min_length / cfg.paddle_base_length,
	}
	var out: Array[float] = []
	for id in table:
		if timed.has(id):
			out.append(table[id])
	return out
