## 道具定義:26 張圖示對應 22 種效果(擋板長度增 2 張、減 3 張圖;「擋板最大化」已移除,圖檔保留不用)。
## 名稱與說明照 docs/design/ui-menus.md D29 第六節(「｜」換行處拆成陣列)。
class_name ItemDefs
extends RefCounted

const BUFF := [
	"paddle_len_1", "paddle_len_2", "pierce", "flame", "bomb", "slow",
	"split", "reinforce", "sticky", "golden_ball", "paddle_speed", "gun",
]
const DEBUFF := [
	"paddle_len_down_1", "paddle_len_down_2", "paddle_len_min", "fast", "paddle_speed_down",
	"merge", "heal", "heal_area", "blackhole", "blackhole_big", "invincible", "invisible",
	"thief", "black_ball",
]

## 數值來源;與 main.gd 的 CONFIG_PATH 相同,load 會拿到同一份快取資源。
const CONFIG_PATH := "res://data/game_config.tres"

## id → [名稱, 說明各行]。{鍵} 由 desc_lines 換成設定檔的值(對照見 _values),
## 改設定檔後說明文字跟著變;沒有對應設定欄位的數字(1階、2倍等)維持寫死。
const TEXT := {
	"paddle_len_1": ["擋板小幅增加", ["長度變成{len_small_up}倍", "持續{dur_paddle_len}秒"]],
	"paddle_len_2": ["擋板大幅增加", ["長度變成{len_big_up}倍", "持續{dur_paddle_len}秒"]],
	"pierce": ["穿透", ["穿過磚塊並減1層", "持續{dur_pierce}秒"]],
	"flame": ["火焰", ["撞到的磚塊減{flame_damage}層", "周圍一圈減{flame_splash}層", "持續{dur_flame}秒"]],
	"bomb": ["炸彈", ["撞到的磚塊被標記", "{dur_bomb}秒後全部爆炸"]],
	"slow": ["減速", ["球速下降1階"]],
	"split": ["分裂", ["場上的球變2倍"]],
	"reinforce": ["強化", ["每次撞磚多減1層", "最多加{reinforce_max}層"]],
	"sticky": ["吸附", ["球碰到擋板會黏住", "點一下才發射", "持續{dur_sticky}秒"]],
	"golden_ball": ["金球", ["三選一"]],
	"paddle_speed": ["擋板移動速度增加", ["移動速度上升1階"]],
	"gun": ["槍", ["點畫面，兩端各射1發", "減1層 不觸發功能磚", "持續{dur_gun}秒"]],
	"paddle_len_down_1": ["擋板小幅減少", ["長度變成{len_small_down}倍", "持續{dur_paddle_len}秒"]],
	"paddle_len_down_2": ["擋板大幅減少", ["長度變成{len_big_down}倍", "持續{dur_paddle_len}秒"]],
	"paddle_len_min": ["擋板最短化", ["縮到最短，持續{dur_paddle_len}秒"]],
	"fast": ["加速", ["球速上升1階"]],
	"paddle_speed_down": ["擋板移動速度減少", ["移動速度下降1階"]],
	"merge": ["融合", ["場上的球減半"]],
	"heal": ["回血", ["撞到的磚塊加{heal_amount}層", "持續{dur_heal}秒"]],
	"heal_area": ["範圍回血", ["撞到的磚塊加{heal_area_amount}層", "周圍一圈加{heal_area_splash}層", "持續{dur_heal_area}秒"]],
	"blackhole": ["黑洞", ["球碰到擋板就消失", "持續{dur_blackhole}秒"]],
	"blackhole_big": ["大黑洞", ["全場的球只剩1顆"]],
	"invincible": ["無敵", ["所有磚塊無法破壞", "魔王除外，持續{dur_invincible}秒"]],
	"invisible": ["隱形", ["擋板變成透明", "持續{dur_invisible}秒"]],
	"thief": ["小偷", ["偷走{thief_min}到{thief_max}分", "分數最低到0"]],
	"black_ball": ["黑球", ["三選一"]],
}


static func exists(id: String) -> bool:
	return id in BUFF or id in DEBUFF


static func is_buff(id: String) -> bool:
	return id in BUFF


## D32 的 40×40 道具圖(D29 選單用;舊 D20/D21 16×16 圖已不再使用)。
static func icon_path(id: String, frame2: bool) -> String:
	return "res://art/items40/d32_item_%s_f%d.png" % [id, 2 if frame2 else 1]


static func item_name(id: String) -> String:
	return TEXT[id][0]


## 說明各行,{鍵} 已代入目前設定檔的數值。
static func desc_lines(id: String) -> Array:
	var values := _values(load(CONFIG_PATH) as GameConfig)
	return TEXT[id][1].map(func(line: String) -> String: return line.format(values))


## TEXT 佔位鍵 → 設定值字串。整數值的 float 去掉「.0」(5.0 → 5、1.2 不變),符合 D29 寫法。
static func _values(cfg: GameConfig) -> Dictionary:
	var out := {
		"dur_paddle_len": cfg.dur_paddle_len, "dur_pierce": cfg.dur_pierce, "dur_flame": cfg.dur_flame,
		"dur_bomb": cfg.dur_bomb, "dur_sticky": cfg.dur_sticky, "dur_gun": cfg.dur_gun, "dur_heal": cfg.dur_heal,
		"dur_heal_area": cfg.dur_heal_area, "dur_blackhole": cfg.dur_blackhole,
		"dur_invincible": cfg.dur_invincible, "dur_invisible": cfg.dur_invisible, "len_small_up": cfg.len_small_up, "len_big_up": cfg.len_big_up,
		"len_small_down": cfg.len_small_down, "len_big_down": cfg.len_big_down,
		"flame_damage": cfg.flame_damage, "flame_splash": cfg.flame_splash, "reinforce_max": cfg.reinforce_max,
		"heal_amount": cfg.heal_amount, "heal_area_amount": cfg.heal_area_amount,
		"heal_area_splash": cfg.heal_area_splash, "thief_min": cfg.thief_min, "thief_max": cfg.thief_max,
	}
	for k in out:
		var v = out[k]
		out[k] = str(int(v)) if v is float and v == roundf(v) else str(v)
	return out


## 磚塊掉落的候選:小偷只在重複遊玩的關卡出現。
static func drop_pool(buff: bool, replay: bool) -> Array:
	if buff:
		return BUFF.duplicate()
	return DEBUFF.filter(func(id: String) -> bool: return replay or id != "thief")


## 金球/黑球 3 選 1 的候選:金球池不含金球、黑球池不含黑球(D29)。
static func choice_pool(golden: bool, replay: bool) -> Array:
	var own := "golden_ball" if golden else "black_ball"
	return drop_pool(golden, replay).filter(func(id: String) -> bool: return id != own)


## 從候選中抽 n 個不重複的道具。
static func pick_distinct(pool: Array, n: int, rng: RandomNumberGenerator) -> Array:
	var bag := pool.duplicate()
	var out := []
	for i in mini(n, bag.size()):
		out.append(bag.pop_at(rng.randi_range(0, bag.size() - 1)))
	return out
