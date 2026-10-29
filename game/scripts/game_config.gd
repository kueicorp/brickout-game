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
## 關卡編號(魔王血量 = 關卡編號 × boss_hp_per_level);本原型只有單關,先用設定模擬。
@export var level_number := 10

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
## 打磚加速本局累計上限(擋板加速共用)(1.0 = 倍率最高 2.0)。
@export var brick_accel_max := 1.0

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
## 限時道具各自的持續秒數(README 道具一節);欄位名 = "dur_" + 道具 id,main.gd 以此對應。
## 擋板長度 5 種道具共用 dur_paddle_len 一個計時(撿到就重設,不累加)。
@export var dur_paddle_len := 30.0
@export var dur_pierce := 20.0
@export var dur_flame := 20.0
@export var dur_bomb := 10.0
@export var dur_sticky := 30.0
@export var dur_gun := 10.0
@export var dur_heal := 10.0
@export var dur_heal_area := 10.0
@export var dur_blackhole := 5.0
@export var dur_invincible := 10.0
@export var dur_invisible := 10.0
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

@export_group("功能型磚")
## 雷射光束對沿途每塊可破壞磚扣的層數;閃電每道扣的層數(README)。
@export var laser_damage := 1
@export var lightning_damage := 2
## 功能型磚所有動畫的每幀秒數(D38:雷射、落雷、爆炸、挑色環、選中閃光、傳送、被擊中、破壞都是 60 ms)。
@export var func_frame := 0.06
## 閃電多道時每道起始的間隔秒數(D17 建議值)。
@export var lightning_stagger := 0.08
## 爆炸連鎖:被引爆的爆炸磚在前一顆觸發後多久引爆(假設:0.12 = 前一顆爆炸 F3 開頭、火球最大時)。
@export var explosion_chain_delay := 0.12
## 剩餘次數數字(d31_digit_N)相對磚左上角的偏移(D38 Q4)。
@export var func_digit_offset := Vector2(10, 0)
## 垂直光束中段、端點(20×20)相對所在磚欄左緣的偏移(D38)。
@export var laser_v_offset := Vector2(10, 0)
## 落雷落點圖、爆炸圖、彩虹挑色環相對目標磚/功能型磚左上角的偏移(D38)。
@export var lightning_hit_offset := Vector2(0, -10)
@export var explosion_fx_offset := Vector2(-40, -20)
@export var rainbow_ring_offset := Vector2(-10, -10)

@export_group("特殊磚與魔王")
## 寶箱破壞必掉 1 個道具,其中增益的機率(其餘減益;取代一般 30% 掉落判定)。
@export var chest_buff_ratio := 0.7
## 金幣磚必掉 1 枚金幣:面額與對應機率(D41,依序累加,合計應為 1)。
@export var coin_values: Array[int] = [10, 50, 100]
@export var coin_weights: Array[float] = [0.6, 0.3, 0.1]
## 魔王每隻血量 = level_number × 這個值(README:關卡的 5 倍)。
@export var boss_hp_per_level := 5
## 魔王被球擊中時掉落(單次擲骰):減益機率、增益機率;魔王不吃一般 30% 掉落判定。
@export var boss_debuff_chance := 0.2
@export var boss_buff_chance := 0.05
## 炸彈效果結束時,被標記的魔王扣的層數(README)。
@export var bomb_boss_damage := 10
## 一次跨多個門檻同時掉多格時,各格破壞動畫錯開的秒數(D42 Q8)。
@export var boss_drop_stagger := 0.1
## 魔王全滅後,剩下的磚依序播灰塵幀消失的間隔秒數(假設;規格只寫「依序」)。
@export var boss_clear_stagger := 0.02

@export_group("計分")
@export var score_per_layer := 100
## 一般磚破壞分;寶箱、金幣、圓形磚破壞也只給這個(不另給每層分)。魔王每層用 score_per_layer。
@export var score_per_brick := 200
## 每隻魔王死亡的加分(README)。
@export var score_boss_kill := 1000
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
