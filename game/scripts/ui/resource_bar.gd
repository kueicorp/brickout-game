class_name ResourceBar
extends Control
## D01 資源列的外觀(只畫,不處理點擊;觸控由首頁另放透明按鈕)。
## 節點放在畫面原點,以下座標都是畫面座標(home-screen-confirmed D01 修訂版 3)。

const HEART := preload("res://assets/ui/home/resource/heart.png")
const COIN := preload("res://assets/ui/home/resource/coin.png")
const GOLD := preload("res://assets/ui/home/resource/gold.png")
const SILVER := preload("res://assets/ui/home/resource/silver.png")

## [格子, icon 左上, 數量 x]
const CELLS := [
	[Rect2(8, 28, 64, 44), Vector2(18, 38), 47],
	[Rect2(76, 28, 92, 44), Vector2(86, 38), 115],
	[Rect2(172, 28, 92, 44), Vector2(182, 38), 211],
	[Rect2(268, 28, 84, 44), Vector2(272, 38), 301],
]
## 12px 數字墨跡 = baseline −8~0;對齊示意圖墨跡 y 45~53
const NUMBER_BASELINE := 53.0
## 黑 alpha 160(Q31);圓角 6px 像素階梯由 PixelBox 畫(Q77)
const BOX_COLOR := Color(0, 0, 0, 160.0 / 255.0)

var values: Array[int] = [0, 0, 0, 0]


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_values(hearts: int, coins: int, gold: int, silver: int) -> void:
	values = [hearts, coins, gold, silver]
	queue_redraw()


func _draw() -> void:
	var icons := [HEART, COIN, GOLD, SILVER]
	for i in CELLS.size():
		var cell: Array = CELLS[i]
		PixelBox.draw_rounded(self, cell[0], BOX_COLOR)
		draw_texture(icons[i], cell[1])
		# shortcut: 不做數字縮寫(Q10 未決定),超過格寬會溢出;Q10 定案後補
		PixelText.draw(self, Vector2(cell[2], NUMBER_BASELINE), str(values[i]), 12, Color.WHITE)
