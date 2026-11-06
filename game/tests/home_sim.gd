extends "res://scripts/home.gd"
## 模擬用的首頁:畫面大小與安全區由測試指定(只在測試裡用,不影響正式程式)。
## 獨立成檔、由測試在執行期 load():home.gd 用到 Autoload「AdManager」,
## 而 --script 模式下主腳本編譯時 Autoload 名稱還沒註冊,寫成測試檔內的 inner class 會編譯失敗。

var sim_view := Vector2(360, 640)
var sim_safe := Vector2i(24, 16)


func _view_size() -> Vector2:
	return sim_view


func _safe_margins(_view: Vector2) -> Vector2i:
	return sim_safe
