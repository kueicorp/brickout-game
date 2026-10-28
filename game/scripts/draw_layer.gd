## 單一繪圖圖層:把 _draw 轉交給主程式指定的函式,讓各圖層依設計稿的繪製順序疊放。
class_name DrawLayer
extends Node2D

var painter: Callable


func _draw() -> void:
	if painter.is_valid():
		painter.call(self)
