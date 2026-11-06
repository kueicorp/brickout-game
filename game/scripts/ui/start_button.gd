class_name StartButton
extends PixelButton
## D06 開始按鈕(216×80):5 種底圖 + 程式疊「開始」(Cubic 11 24px、白字 + 1px 深色外框);按下字下移 2px。
## 未解鎖 → 停用灰且不可點;魔王關(10 的倍數)用魔王版,按下用魔王按下圖。

enum Look { NORMAL, BOSS, DISABLED }

const TEX_NORMAL := preload("res://assets/ui/home/start-button/start_normal.png")
const TEX_PRESSED := preload("res://assets/ui/home/start-button/start_pressed.png")
const TEX_DISABLED := preload("res://assets/ui/home/start-button/start_disabled.png")
const TEX_BOSS := preload("res://assets/ui/home/start-button/start_boss.png")
const TEX_BOSS_PRESSED := preload("res://assets/ui/home/start-button/start_boss_pressed.png")

const LABEL := "開始"
## 字級量自 art/mockups/home/d06_normal.png:墨跡 22px 高 = Cubic 11 24px;墨跡 y 412~433 → baseline 430(畫面)− 388
const LABEL_SIZE := 24
const LABEL_BASELINE := 42.0
## 外框色取自同一張示意圖
const LABEL_OUTLINE := Color("#1E1E1E")

var look := Look.NORMAL


func set_look(value: Look) -> void:
	look = value
	disabled = value == Look.DISABLED
	queue_redraw()


func _draw() -> void:
	var held := is_held()
	var tex: Texture2D
	match look:
		Look.DISABLED:
			tex = TEX_DISABLED
		Look.BOSS:
			tex = TEX_BOSS_PRESSED if held else TEX_BOSS
		_:
			tex = TEX_PRESSED if held else TEX_NORMAL
	draw_texture(tex, Vector2.ZERO)
	var baseline := Vector2(0, LABEL_BASELINE + (2.0 if held else 0.0))
	PixelText.draw(self, baseline, LABEL, LABEL_SIZE, Color.WHITE, LABEL_OUTLINE, size.x, HORIZONTAL_ALIGNMENT_CENTER)
