class_name PixelButton
extends BaseButton
## 自繪按鈕的共同基底。沿用 BaseButton 的判定:放開時手指仍在範圍內才觸發,
## 移出範圍時按下外觀消失、放開不觸發。子類別在 _draw 依 is_held() 畫按下外觀。


func _init() -> void:
	# 整個遊戲不做鍵盤 / 無障礙操作(使用者決定),不需要焦點
	focus_mode = Control.FOCUS_NONE


## 手指正按在範圍內
func is_held() -> bool:
	var mode := get_draw_mode()
	return mode == DRAW_PRESSED or mode == DRAW_HOVER_PRESSED
