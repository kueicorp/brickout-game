## headless 冒煙測試:實際跑主場景,逐一觸發 27 種道具(含 3 選 1、到期處理、槍),檢查執行期沒有錯誤。
## 執行:Godot --headless --fixed-fps 60 --path game --script res://tests/smoke_run.gd
## 判讀:輸出不應出現 SCRIPT ERROR / ERROR;最後印出 SMOKE DONE。
extends SceneTree

const FRAMES_PER_ITEM := 420   # 7 秒:涵蓋 5 秒限時效果到期與 3 選 1 動畫

var _ids: Array = ItemDefs.BUFF + ItemDefs.DEBUFF
var _index := -1
var _frame := 0
var _main: Node2D
## 要留著參照:設定檔是共用快取,參照歸零就會被釋放,主場景會重新載入成預設值
var _cfg: GameConfig


func _initialize() -> void:
	_cfg = load("res://data/game_config.tres") as GameConfig
	_cfg.debug_start_balls = 40   # 同時壓一點球數
	_cfg.replay_level = true      # 讓小偷進入候選
	_next()


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 2:
		_main._launch_stuck()
	if _frame == 30:
		_main._apply_item(_ids[_index])
	if _frame % 20 == 0:
		_main._fire_gun()
		_main._launch_stuck()
	# 擋板追最低的下落球,讓球活久一點、多跑幾種碰撞
	var low := -1.0
	for b in _main.balls:
		if b.dir.y > 0.0 and b.pos.y > low:
			low = b.pos.y
			_main.target_x = b.pos.x
	# 3 選 1 開著時,鎖定結束後直接選第 1 個
	if _main.menu != null and _main.menu._t > 0.5 and _main.menu._picked < 0:
		_main.menu._on_pressed(0)
	if _frame >= FRAMES_PER_ITEM:
		print("item %-18s state=%d balls=%d score=%d hud=%d" % [_ids[_index], _main.state, _main.balls.size(), _main.score, _main.hud.size()])
		_next()
	return _index >= _ids.size()


func _next() -> void:
	if _main != null:
		_main.queue_free()
	_index += 1
	_frame = 0
	if _index >= _ids.size():
		print("SMOKE DONE")
		return
	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)
