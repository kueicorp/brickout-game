class_name HomeLogic
## 首頁的純邏輯(不依賴畫面),供首頁與測試共用。
## 名詞:關卡 1~200;「組」= 10 關,共 20 組;「主題」= 2 組 = 20 關,共 10 個。
## 進度只用一個數字表示:first_uncleared = 第一個未通關的關卡(全通關時為 201)。

enum LevelState { CLEARED, PLAYABLE, LOCKED }

const MAX_LEVEL := 200
const LEVELS_PER_GROUP := 10
const GROUP_COUNT := 20
const THEME_COUNT := 10

const THEME_NAMES := [
	"晴空草原", "迷霧森林", "烈日荒漠", "劇毒沼澤", "熔岩火山",
	"幽暗深海", "極夜冰原", "雷暴雲海", "魔王古堡", "虛空深淵",
]

# D15 滑動參數(設計稿 A-D10,實機手感測試後可調)
const TAP_SLOP := 12.0
const PAGE_DISTANCE := 86.0
const FLING_SPEED := 600.0
const FLING_MIN_DISTANCE := 24.0
const RUBBER_FACTOR := 0.3
const RUBBER_MAX := 24.0
## 滑動起手區(畫面座標):D15 外框左右各內縮 32px,避開系統返回手勢。
const SWIPE_START_RECT := Rect2(40, 140, 280, 232)

## D14 長按門檻(ms)
const LONG_PRESS_MS := 500
const HEART_REGEN_SECONDS := 20 * 60
const HEART_CAP := 20

enum Gesture { UNDECIDED, SWIPE, VERTICAL }


static func group_of_level(level: int) -> int:
	return ceili(level / float(LEVELS_PER_GROUP))


static func theme_of_group(group: int) -> int:
	return ceili(group / 2.0)


static func first_group_of_theme(theme: int) -> int:
	return theme * 2 - 1


## 組內序號(1~10)→ 關卡號
static func level_of(group: int, index: int) -> int:
	return (group - 1) * LEVELS_PER_GROUP + index


static func is_boss(level: int) -> bool:
	return level % LEVELS_PER_GROUP == 0


static func level_state(level: int, first_uncleared: int) -> LevelState:
	if level < first_uncleared:
		return LevelState.CLEARED
	if level == first_uncleared:
		return LevelState.PLAYABLE
	return LevelState.LOCKED


## 主題未解鎖 = 該主題第 1 關未解鎖(D02 第 4 點)
static func is_theme_locked(theme: int, first_uncleared: int) -> bool:
	return level_state(level_of(first_group_of_theme(theme), 1), first_uncleared) == LevelState.LOCKED


## 路段 k→k+1:起點關 k 已通關才算走過(13-3 E)
static func is_road_walked(from_level: int, first_uncleared: int) -> bool:
	return from_level < first_uncleared


## 開啟首頁時的預設選取(Q43):回傳選取的關卡號;所在組用 group_of_level 求。
static func default_selection(first_uncleared: int) -> int:
	return mini(first_uncleared, MAX_LEVEL)


## D02 箭頭 / 主題選擇切主題後的選取(Q57、Q66):該主題第 1 關
static func selection_for_theme(theme: int) -> int:
	return level_of(first_group_of_theme(theme), 1)


## 相鄰組;沒有時回傳 0(只有組 1 往前、組 20 往後)
static func neighbor_group(group: int, direction: int) -> int:
	var g := group + direction
	return g if g >= 1 and g <= GROUP_COUNT else 0


## 滑動換組後的選取(Q43、Q61、Q67)
static func selection_after_swipe(from_group: int, to_group: int, first_uncleared: int) -> int:
	if theme_of_group(from_group) != theme_of_group(to_group):
		# 跨主題:往後 → 該組第 1 關;往前 → 該組最後一關(該主題第 20 關)
		return level_of(to_group, 1) if to_group > from_group else level_of(to_group, LEVELS_PER_GROUP)
	# 同主題換組:依進度
	var first := level_of(to_group, 1)
	var last := level_of(to_group, LEVELS_PER_GROUP)
	if first_uncleared >= first and first_uncleared <= last:
		return first_uncleared
	if first_uncleared > last:
		return last
	return first


static func is_left_arrow_disabled(theme: int) -> bool:
	return theme <= 1


static func is_right_arrow_disabled(theme: int) -> bool:
	return theme >= THEME_COUNT


static func can_start_swipe(screen_pos: Vector2) -> bool:
	# 用閉區間:x 40~320、y 140~372 都算
	return screen_pos.x >= SWIPE_START_RECT.position.x and screen_pos.x <= SWIPE_START_RECT.end.x \
		and screen_pos.y >= SWIPE_START_RECT.position.y and screen_pos.y <= SWIPE_START_RECT.end.y


## 依位移判定手勢(D15 第 4 點);一旦判定就不再改變,由呼叫端保存
static func classify_motion(delta: Vector2) -> Gesture:
	var ax := absf(delta.x)
	var ay := absf(delta.y)
	if ax > TAP_SLOP and ax >= ay:
		return Gesture.SWIPE
	if ay > TAP_SLOP and ay > ax:
		return Gesture.VERTICAL
	return Gesture.UNDECIDED


## 放開時是否算點擊:直線距離 ≤ 12px
static func is_tap(delta: Vector2) -> bool:
	return delta.length() <= TAP_SLOP


## 放開時是否換頁。dx 為水平位移(往左為負),velocity 為放開時水平速度(px/s)。
## 回傳 -1 = 上一組(手指往右)、+1 = 下一組(手指往左)、0 = 回彈。
## 快甩要與位移同方向才算,避免拖一段再反向甩時翻錯方向。
static func page_change_direction(dx: float, velocity: float) -> int:
	var flung := absf(velocity) >= FLING_SPEED and absf(dx) >= FLING_MIN_DISTANCE and signf(velocity) == signf(dx)
	if absf(dx) >= PAGE_DISTANCE or flung:
		return -1 if dx > 0 else 1
	return 0


## 邊界橡皮筋位移
static func rubber_band(dx: float) -> float:
	return clampf(dx * RUBBER_FACTOR, -RUBBER_MAX, RUBBER_MAX)


## D14 文字:「下一顆 mm:ss」;愛心 ≥ 20 時固定 00:00
static func heart_countdown_text(seconds_left: int, hearts: int) -> String:
	if hearts >= HEART_CAP:
		seconds_left = 0
	seconds_left = clampi(seconds_left, 0, HEART_REGEN_SECONDS)
	@warning_ignore("integer_division")
	return "下一顆 %02d:%02d" % [seconds_left / 60, seconds_left % 60]


## D14 放開時要不要去商城:已出現懸浮視窗、手指移出或被取消都不去
static func heart_release_goes_to_shop(tooltip_shown: bool, released_inside: bool) -> bool:
	return released_inside and not tooltip_shown


## 按住時間是否已達長按
static func is_long_press(held_ms: int) -> bool:
	return held_ms >= LONG_PRESS_MS


# ---- 直向延伸版面(T02、T03) ----

## 首頁內容從 T 往下排滿 600px(D01 ~ banner 下緣),多的高度才分給上下留白
const CONTENT_HEIGHT := 600
const SAFE_TOP_MIN := 24
const SAFE_BOTTOM_MIN := 16


## 系統 inset(實體像素)→ 安全區上 T、下 B(viewport px);scale = 實體 px / viewport px。
## 用無條件進位:互動元件寧可多避 1px,也不要被瀏海或手勢列蓋到。
static func safe_margins(top_px: float, bottom_px: float, scale: float) -> Vector2i:
	if scale <= 0.0:
		return Vector2i(SAFE_TOP_MIN, SAFE_BOTTOM_MIN)
	return Vector2i(maxi(SAFE_TOP_MIN, ceili(top_px / scale)), maxi(SAFE_BOTTOM_MIN, ceili(bottom_px / scale)))


## 首頁各區塊的 y(T03)。h = 畫面高,top / bottom = 安全區 T、B。
## 餘量 S < 0(640 高且 T + B 超過保底)時依 D15 第 11 點扣高:
## D02~D15 留白 12→4、D15~D06 留白 16→8、三排間隔各 26→18,最多 32px;
## 超過 32 的部分不再吸收,會吃掉 D06 與底部列之間的 24px 間隔。
## 回傳的 row_cuts = [第 1→2 排縮短, 第 2→3 排縮短],D15 高度 = 232 − 兩者合計。
static func home_layout(h: int, top: int, bottom: int) -> Dictionary:
	var s := h - top - bottom - CONTENT_HEIGHT
	var add_top := 0
	var cut := 0
	if s >= 0:
		# round(0.6 × S) 用整數算,避免浮點誤差
		@warning_ignore("integer_division")
		add_top = (6 * s + 5) / 10
	else:
		cut = -s
	var cut_top := mini(cut, 8)
	var cut_bottom := clampi(cut - 8, 0, 8)
	var cut_rows := clampi(cut - 16, 0, 16)
	@warning_ignore("integer_division")
	var row_cut_1 := cut_rows / 2
	var d01 := top + 4
	var d02 := top + 56 + add_top
	var d15 := d02 + 60 - cut_top
	var d15_height := 232 - cut_rows
	return {
		"add_top": add_top,
		"add_bottom": maxi(s, 0) - add_top,
		"d01": d01,
		"d14": d01 + 48,
		"d02": d02,
		"d15": d15,
		"d15_height": d15_height,
		"row_cuts": [row_cut_1, cut_rows - row_cut_1],
		"d06": d15 + d15_height + 16 - cut_bottom,
		"bottom": h - bottom - 132,
		"banner": h - bottom - 50,
	}


## 載入畫面(T04)的 y:[Logo, 進度條外框, 金磚填充]
static func loading_layout(h: int) -> Array[int]:
	var frame := h - 120
	return [roundi(0.375 * h - 40), frame, frame + 7]
