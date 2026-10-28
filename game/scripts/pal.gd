## D01 調色盤中由程式直接繪製(矩形、線段條、選項框)會用到的顏色。
## 色碼照設計稿,不自行調整;註解為 D01 代號。
class_name Pal
extends RefCounted

const K := Color("#1B1A2E")         # K 描邊深藍黑
const W := Color("#FFFFFF")         # W 白
const G := Color("#B8BCD0")         # G 灰塵灰
const RED_R := Color("#E8696B")     # r 紅 T2(時間閃爍紅)
const YEL_A := Color("#FFF7C2")     # A 黃 T1
const YEL_B := Color("#FFEB8A")     # B 黃 T2
const YEL_Y := Color("#F7D84A")     # Y 黃 T3
const YEL_C := Color("#C9A22A")     # C 黃 T4
const YEL_D := Color("#7E6416")     # D 黃 T5
const VIO_M := Color("#D2A8F8")     # m 紫 T1
const LIGHT_7 := Color("#DDE0EA")   # 7 淺灰
const MID_8 := Color("#9EA4B6")     # 8 中灰
const STEEL_F := Color("#8A93A8")   # f 鋼灰 T3
const GUN_Y := Color("#6D7690")     # y 槍金屬紋亮部
const STEEL_G := Color("#566077")   # g 鋼灰 T4
const STEEL_J := Color("#363D4F")   # j 鋼灰 T5(線段條外框)
const BOSS_V := Color("#241C30")    # v 魔王 T5(線段條空的底色)
const DEB_LIGHT := Color("#B85CB0") # _ 暗紫亮邊
const DEB_MID := Color("#8C3F86")   # < 暗紫中邊
const DEB_FACE := Color("#6A2166")  # > 暗紫底板面
const DEB_DARK := Color("#45143F")  # , 暗紫暗邊

## D16 分段線段的 7 種灰,由白到深(W 7 G 8 f y g)。
const SEGMENT_GRAYS := [W, LIGHT_7, G, MID_8, STEEL_F, GUN_Y, STEEL_G]

## D29 9 宮格網格用的代號 → 顏色。
const GRID_CODES := {
	"K": K, "A": YEL_A, "B": YEL_B, "Y": YEL_Y, "C": YEL_C, "D": YEL_D,
	"_": DEB_LIGHT, "<": DEB_MID, ">": DEB_FACE, ",": DEB_DARK,
}
