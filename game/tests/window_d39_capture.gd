## 視窗截圖(非 headless):D39~D44 特殊磚與魔王在測試關卡 level_test.json 的實際畫面,供人工對照設計稿。
## 依序截:BOSS 警告(停住期間)、雙血條與特殊磚、魔王掉 1 格後(含裂痕)、掉落金幣(F1 正面)與接到特效、魔王格閃白。
## 每張另存一張局部 2 倍放大(_zoom)。跑完自動關閉。
## 執行:Godot --path game --script res://tests/window_d39_capture.gd -- <輸出資料夾> [視窗高,預設 800]
extends SceneTree

const MainScene := preload("res://scenes/main.tscn")

var _m
var _cfg: GameConfig   # 要留著參照:設定檔是共用快取,參照歸零會被釋放
var _out := ""
var _step := 0
var _t := 0.0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else OS.get_user_data_dir()
	DisplayServer.window_set_size(Vector2i(360, int(args[1]) if args.size() > 1 else 800))
	DirAccess.make_dir_recursive_absolute(_out)
	_cfg = load("res://data/game_config.tres") as GameConfig
	_cfg.level_path = "res://data/levels/level_test.json"
	_m = MainScene.instantiate()
	root.add_child(_m)


## 存整張與局部放大;region 為遊戲座標。
func _shot(name: String, region: Rect2i) -> void:
	var img := root.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	img.save_png(_out.path_join(name + ".png"))
	var z := img.get_region(region)
	z.resize(region.size.x * 2, region.size.y * 2, Image.INTERPOLATE_NEAREST)
	z.save_png(_out.path_join(name + "_zoom.png"))
	print("SHOT %s viewport=%s" % [name, img.get_size()])


func _process(delta: float) -> bool:
	_t += delta
	match _step:
		0:
			# 警告開始後 0.6 秒:停住期間
			if _m.warn_left > 0.0 and _m.warn_left <= 1.0:
				_shot("d44_boss_warning", Rect2i(0, 360, 360, 80))
				_step = 1
		1:
			if _m.warn_left <= 0.0 and _m.bar_t >= 0.5:
				_shot("d43_boss_bars_specials", Rect2i(0, 40, 360, 330))
				print("BOSS layers=%s cells=%s" % [_m.bosses.map(func(b) -> int: return b.layers), _m.bosses.map(func(b) -> int: return b.cells.size())])
				# B1 扣 13(50 → 37,跨過門檻 38 掉 1 格);B2 扣 5(這段消耗 5/12 → crack_1)
				_m._boss_damage(_m.bosses[0], 13)
				_m._boss_damage(_m.bosses[1], 5)
				_t = 0.0
				_step = 2
		2:
			if _t >= 0.5:
				_shot("d42_boss_drop1", Rect2i(0, 40, 360, 330))
				print("BOSS layers=%s cells=%s" % [_m.bosses.map(func(b) -> int: return b.layers), _m.bosses.map(func(b) -> int: return b.cells.size())])
				# 打破第 11 排的金幣磚,讓金幣照實際邏輯掉一段
				_m._damage(Vector2i(4, 11), 1)
				_t = 0.0
				_step = 3
		3:
			if _t >= 0.6:
				# 三種面額並排 + 接到特效第 2 幀 + B2 一格閃白,然後凍結(state = ENDED 不推進,不出結束畫面)
				_m.coins.append_array([{"value": 10, "pos": Vector2(250, 470)}, {"value": 50, "pos": Vector2(280, 470)},
					{"value": 100, "pos": Vector2(310, 470)}])
				_m.anims.append({"kind": "coin_pick", "pos": Vector2(240, 500), "t": 0.07, "dur": 0.18})
				_m.grid[13][2].hit_t = 99.0
				_m.state = 1
				# 金幣共用同一轉動時鐘,截到 F3 側面時只剩 4 px 寬;截圖固定用 F1 正面
				_m.reduced_motion = true
				_t = 0.0
				_step = 4
		4:
			if _t >= 0.1:
				_shot("d41_coins_flash", Rect2i(0, 300, 360, 220))
				print("COINS %s" % [_m.coins])
				return true
	return false
