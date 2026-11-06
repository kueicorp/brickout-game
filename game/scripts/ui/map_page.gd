class_name MapPage
extends Control
## D15 的一組(10 關):路 → 格子 → 號碼 → 棋子,全部在 _draw 畫。
## 本節點座標原點 = D15 外框左上(640 高時畫面 8, 140);常數用 640 高時的畫面座標,畫時減 ORIGIN。
## 畫面變高時整個 D15 由首頁平移,這裡的座標不變;只有扣高(row_cuts)會縮短排間距。

const ORIGIN := Vector2(8, 140)
const PAGE_SIZE := Vector2(344, 232)

## 組內序號 1~10 的格子中心(畫面座標,D15 第 2 點)
const CENTERS := [
	Vector2(91, 199), Vector2(180, 199), Vector2(269, 199),
	Vector2(314, 266), Vector2(224, 266), Vector2(136, 266), Vector2(46, 266),
	Vector2(91, 332), Vector2(180, 332), Vector2(269, 332),
]
const TILE_HALF := 38.0
const TOUCH_HALF := 33.0
## 棋子圖左上 = 格子圖左上 + (14, −22)(13-4)
const PAWN_OFFSET := Vector2(14, -22)
## 號碼:12px 數字墨跡在格子圖內 y 19~27 → baseline 27
const NUMBER_BASELINE := 27.0
## 沒走過的路段乘 #909090(Q74)
const ROAD_DIM := Color("#909090")
const PRESS_OVERLAY_ALPHA := 40.0 / 255.0

const TEX_ROAD_H := preload("res://assets/ui/home/level-map/road/t01/road_h.png")
const TEX_ROAD_DOWN := preload("res://assets/ui/home/level-map/road/t01/road_corner_down.png")
const TEX_ROAD_RIGHT := preload("res://assets/ui/home/level-map/road/t01/road_corner_right.png")
const TEX_PAWN := preload("res://assets/ui/home/level-map/pawn.png")
const TILE_TEX := {
	"normal": [
		preload("res://assets/ui/home/level-map/tile_normal_cleared.png"),
		preload("res://assets/ui/home/level-map/tile_normal_playable.png"),
		preload("res://assets/ui/home/level-map/tile_normal_locked.png"),
	],
	"boss": [
		preload("res://assets/ui/home/level-map/tile_boss_cleared.png"),
		preload("res://assets/ui/home/level-map/tile_boss_playable.png"),
		preload("res://assets/ui/home/level-map/tile_boss_locked.png"),
	],
}
## 路段 k→k+1(k = 組內序號 1~9)的圖與左上角(畫面座標,13-3 D 表)
## shortcut: 只有 T01 的路圖,其他主題暫用 T01;各主題的路出圖後改成依主題取圖
const ROADS := [
	[TEX_ROAD_H, Vector2(120, 191)],
	[TEX_ROAD_H, Vector2(209, 191)],
	[TEX_ROAD_DOWN, Vector2(270, 191)],
	[TEX_ROAD_H, Vector2(253, 258)],
	[TEX_ROAD_H, Vector2(164, 258)],
	[TEX_ROAD_H, Vector2(75, 258)],
	[TEX_ROAD_RIGHT, Vector2(38, 264)],
	[TEX_ROAD_H, Vector2(120, 324)],
	[TEX_ROAD_H, Vector2(209, 324)],
]

## 轉角路圖在垂直直線段上的切點(圖內 y);扣高時從這裡剪掉 row_cuts 列,接縫落在直線段上看不出來
const CORNER_SPLIT := {TEX_ROAD_DOWN: 40, TEX_ROAD_RIGHT: 10}

## 按下時疊的白色剪影(依格子圖 alpha 產生),各張只產生一次
static var _overlay_cache := {}

## D15 扣高(D15 第 11 點):[第 1→2 排縮短, 第 2→3 排縮短];平常是 0
var row_cuts := [0, 0]

var group := 1
var first_uncleared := 1
## 棋子所在的關卡號;0 = 本頁沒有棋子
var selected_level := 0
## 按下中的組內序號;0 = 沒有
var pressed_index := 0
## 可玩格目前是否在「上移 1px」那一格
var bob_up := false
## 跳躍中的棋子位置(本節點座標);非跳躍時為 null
var hop_pos: Variant = null


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = PAGE_SIZE


## 第 row 排(0~2)因扣高往上移的量
func _row_shift(row: int) -> float:
	return float(row_cuts[0] + row_cuts[1]) if row == 2 else (float(row_cuts[0]) if row == 1 else 0.0)


## 組內序號 → 格子中心(本節點座標,含扣高)
func center(index: int) -> Vector2:
	var row := 0 if index <= 3 else (1 if index <= 7 else 2)
	return CENTERS[index - 1] - ORIGIN - Vector2(0, _row_shift(row))


## 組內序號 → 格子圖左上(本節點座標)
func tile_origin(index: int) -> Vector2:
	return center(index) - Vector2(TILE_HALF, TILE_HALF)


## 本節點座標 → 被點到的組內序號(觸控 66×66);沒有時 0
func index_at(local_pos: Vector2) -> int:
	for i in CENTERS.size():
		if Rect2(center(i + 1) - Vector2(TOUCH_HALF, TOUCH_HALF), Vector2(TOUCH_HALF, TOUCH_HALF) * 2).has_point(local_pos):
			return i + 1
	return 0


## 某格目前的位移(可玩格上下動、按下下移 1px);棋子跟著同一個位移
func tile_shift(index: int) -> Vector2:
	var level := HomeLogic.level_of(group, index)
	var shift := Vector2.ZERO
	if bob_up and HomeLogic.level_state(level, first_uncleared) == HomeLogic.LevelState.PLAYABLE:
		shift.y -= 1
	if index == pressed_index:
		shift.y += 1
	return shift


## 棋子停在某格時的左上(本節點座標,不含位移)
func pawn_anchor(index: int) -> Vector2:
	return tile_origin(index) + PAWN_OFFSET


func _draw() -> void:
	for k in ROADS.size():
		var from_level := HomeLogic.level_of(group, k + 1)
		var tint := Color.WHITE if HomeLogic.is_road_walked(from_level, first_uncleared) else ROAD_DIM
		# 路段 k 擺在起點格那一排(轉角從上一排往下接)
		var tex: Texture2D = ROADS[k][0]
		var pos: Vector2 = ROADS[k][1] - ORIGIN - Vector2(0, _row_shift(0 if k <= 2 else (1 if k <= 6 else 2)))
		var cut: int = row_cuts[0] if k == 2 else (row_cuts[1] if k == 6 else 0)
		if cut == 0:
			draw_texture(tex, pos, tint)
		else:
			# 轉角剪掉直線段中間 cut 列:上半照畫,下半往上接
			var w := tex.get_width()
			var split: int = CORNER_SPLIT[tex]
			var rest := tex.get_height() - split - cut
			draw_texture_rect_region(tex, Rect2(pos, Vector2(w, split)), Rect2(0, 0, w, split), tint)
			draw_texture_rect_region(tex, Rect2(pos + Vector2(0, split), Vector2(w, rest)), Rect2(0, split + cut, w, rest), tint)

	var selected_index := selected_level - HomeLogic.level_of(group, 0) \
		if HomeLogic.group_of_level(selected_level) == group else 0
	for index in range(1, 11):
		var level := HomeLogic.level_of(group, index)
		var state := HomeLogic.level_state(level, first_uncleared)
		var boss := HomeLogic.is_boss(level)
		var tex: Texture2D = TILE_TEX["boss" if boss else "normal"][state]
		var pos := tile_origin(index) + tile_shift(index)
		draw_texture(tex, pos)
		if index == pressed_index:
			draw_texture(_overlay_for(tex), pos)
		# 魔王格、棋子所在的格子不顯示號碼
		if not boss and index != selected_index:
			_draw_number(level, state, pos)

	if selected_index > 0:
		var pawn_pos: Vector2 = hop_pos if hop_pos != null else pawn_anchor(selected_index) + tile_shift(selected_index)
		draw_texture(TEX_PAWN, pawn_pos)


func _draw_number(level: int, state: HomeLogic.LevelState, tile_pos: Vector2) -> void:
	var color := Color.WHITE
	var outline := Color.BLACK
	match state:
		HomeLogic.LevelState.PLAYABLE:
			# 可玩格號碼 #000000;黑框疊黑字只會變粗,所以不畫外框
			color = Color.BLACK
			outline = Color.TRANSPARENT
		HomeLogic.LevelState.LOCKED:
			color = Color("#B0B0B0")
	PixelText.draw(self, tile_pos + Vector2(0, NUMBER_BASELINE), str(level), 12, color, outline,
		TILE_HALF * 2, HORIZONTAL_ALIGNMENT_CENTER)


static func _overlay_for(tex: Texture2D) -> Texture2D:
	if not _overlay_cache.has(tex):
		var img := tex.get_image()
		img.convert(Image.FORMAT_RGBA8)
		for y in img.get_height():
			for x in img.get_width():
				var a := img.get_pixel(x, y).a
				img.set_pixel(x, y, Color(1, 1, 1, a * PRESS_OVERLAY_ALPHA))
		_overlay_cache[tex] = ImageTexture.create_from_image(img)
	return _overlay_cache[tex]
