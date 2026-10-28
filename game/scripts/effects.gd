## 本局生效中的道具效果。
## 限時效果:相同效果還在時再撿到,剩餘時間累積,並以累積後的剩餘時間當新的總時間(D16);
## 不同效果各自計時、可同時存在。
## 擋板長度例外:所有長度道具共用一個計時(PADDLE_LEN),每撿一個就把倍率再乘進去、計時重設(不累加)。
## 其餘欄位為整局有效的效果。
class_name Effects
extends RefCounted

## 擋板長度共用計時在 timed 裡的鍵(不是道具 id)。
const PADDLE_LEN := "paddle_len"

## id → {"remaining": 秒, "total": 秒}
var timed := {}
## 強化加成(每次撞磚多扣的層數)。
var reinforce := 0
## 球速淨階數(加速 +、減速 −,互相抵銷)。
var ball_tier := 0
## 擋板速度淨階數。
var paddle_tier := 0
## 擋板長度淨倍率(共用計時期間撿到的長度道具倍率連乘);計時到期回到 1。
var paddle_factor := 1.0
## 共用計時期間撿過最短化(HUD 一律顯示「−」);計時到期清除。
var paddle_min := false
## 付費「附魔」整局效果("pierce"、"flame" 或空字串);本原型由除錯設定模擬。
var enchant := ""


func add_timed(id: String, duration: float) -> void:
	var left: float = duration + (timed[id]["remaining"] if timed.has(id) else 0.0)
	timed[id] = {"remaining": left, "total": left}


## 撿到擋板長度道具:倍率再乘進去(同一種撿第 2 次也再乘),共用計時重設為 cfg.dur_paddle_len。
## 最短化換算成「最短長度 ÷ 基準長度」一起相乘;長度上下限由 Rules.paddle_length 夾。
func add_paddle_len(id: String, cfg: GameConfig) -> void:
	var table := {
		"paddle_len_1": cfg.len_small_up,
		"paddle_len_2": cfg.len_big_up,
		"paddle_len_down_1": cfg.len_small_down,
		"paddle_len_down_2": cfg.len_big_down,
		"paddle_len_min": cfg.paddle_min_length / cfg.paddle_base_length,
	}
	paddle_factor *= table[id]
	paddle_min = paddle_min or id == "paddle_len_min"
	timed[PADDLE_LEN] = {"remaining": cfg.dur_paddle_len, "total": cfg.dur_paddle_len}


func is_active(id: String) -> bool:
	return timed.has(id)


func remaining(id: String) -> float:
	return timed[id]["remaining"] if timed.has(id) else 0.0


func total(id: String) -> float:
	return timed[id]["total"] if timed.has(id) else 0.0


## 經過 dt 秒;回傳這次到期(已移除)的效果 id。擋板長度共用計時到期時,所有長度效果一起結束。
func tick(dt: float) -> Array[String]:
	var expired: Array[String] = []
	for id in timed:
		timed[id]["remaining"] -= dt
		if timed[id]["remaining"] <= 0.0:
			expired.append(id)
	for id in expired:
		timed.erase(id)
	if PADDLE_LEN in expired:
		paddle_factor = 1.0
		paddle_min = false
	return expired
