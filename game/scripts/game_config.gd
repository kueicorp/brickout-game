## 遊戲可調參數。數值要實機試玩後才能定版,集中放在 data/game_config.tres,不寫死在程式。
## 預設值依 README「基本數值」、道具與計分規則、docs/handoff.md 第 3 節;註明「假設」者為規格未定、由工程師暫定。
class_name GameConfig
extends Resource

@export_group("關卡與時間")
## 關卡資料檔(JSON,格式見 scripts/rules.gd 的 parse_level)。
@export_file("*.json") var level_path := "res://data/levels/level_test.json"
## 每局秒數。
@export var game_time := 300.0
## 多層磚層數上限。
@export var max_layers := 69

@export_group("球")
## 球的基準速度(px/s)。
@export var ball_speed := 240.0
## 每階速度變化比例;以基準速度為準線性加減(假設:+4 階 = 1.6 倍,不是 1.15 的 4 次方)。
@export var speed_tier_step := 0.15
@export var ball_tier_min := -3
@export var ball_tier_max := 4
## 場上球數上限,防止分裂一直翻倍拖垮效能(假設)。
@export var max_balls := 1000
## 球打在擋板上的最大反彈偏角,與垂直線的夾角(度;假設)。
@export var paddle_bounce_max_deg := 60.0
## 發射時的最小偏角,避免從擋板正中央垂直上下彈(度;假設)。
@export var launch_min_deg := 10.0
## 球的方向與水平線的最小夾角,避免幾乎水平來回(度;假設)。
@export var min_angle_deg := 15.0
## 分裂時新球相對原球的偏轉角(度;假設)。
@export var split_angle_deg := 20.0
## 打磚加速:球每碰到一次磚,整局共用的加速加上這個比例(相加不複利);
## 與速度階倍率直接相乘,不設總上限。減速道具只降階、不清除;新開一局歸零。
@export var brick_accel_unbreakable := 0.01
@export var brick_accel_other := 0.005
## 球每碰到一次擋板(反彈或被吸附黏住)也加這個比例,累加到同一個打磚加速;黑洞吸走不算。
@export var brick_accel_paddle := 0.005
## 打磚加速本局累計上限(擋板加速共用)(0.5 = 倍率最高 1.5)。
@export var brick_accel_max := 0.5

@export_group("擋板")
## 擋板最高移動速度(px/s)。
@export var paddle_speed := 450.0
## 擋板速度階數範圍;規格未定,暫用與球相同的 −3~+4(假設)。
@export var paddle_tier_min := -3
@export var paddle_tier_max := 4
## 擋板長度(px,原圖 2 倍):基準 85(試玩後縮為原 128 的 2/3)、最短 32(左右端各 16)、最長 = 關卡區全寬 320。
@export var paddle_base_length := 85.0
@export var paddle_min_length := 32
@export var paddle_max_length := 320
@export var len_small_up := 1.2
@export var len_big_up := 1.6
@export var len_small_down := 0.8
@export var len_big_down := 0.4
## 隱形時擋板的不透明度(0 = 完全看不見)。
@export var invisible_alpha := 0.0

@export_group("道具")
## 可破壞磚被破壞時掉落道具的機率。
@export var drop_chance := 0.3
## 掉落時是增益道具的機率(其餘為減益)。
@export var buff_ratio := 0.5
## 限時道具的持續秒數。
@export var effect_duration := 5.0
## 道具掉落速度(px/s;假設)。
@export var item_fall_speed := 100.0
@export var reinforce_max := 7
@export var flame_damage := 2
@export var flame_splash := 1
@export var bomb_splash := 2
@export var heal_amount := 1
@export var heal_area_amount := 2
@export var heal_area_splash := 1
## 擋板槍子彈速度(px/s)與最短發射間隔(秒)。
@export var bullet_speed := 600.0
@export var gun_cooldown := 0.3
@export var thief_min := 500
@export var thief_max := 5000
## 模擬「重複遊玩的關卡」:true 時小偷才會出現在掉落與黑球選項中。
@export var replay_level := false

@export_group("計分")
@export var score_per_layer := 100
@export var score_per_brick := 200
@export var score_buff := 200
@export var score_debuff := 50
@export var score_per_second := 2

@export_group("顯示")
## HUD 球狀態列不透明度(D28)。
@export var hud_alpha := 0.5

@export_group("除錯")
## 指定後每塊可破壞磚被破壞時必掉這個道具(id 見 scripts/item_defs.gd);空字串 = 正常隨機。
@export var debug_force_item := ""
## 開場球數(實機壓測用)。
@export var debug_start_balls := 1
## 模擬付費「附魔」整局效果:"pierce"、"flame" 或空字串(用來檢查 HUD 全滿線段)。
@export var debug_enchant := ""
