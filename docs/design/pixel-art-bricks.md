# 可破壞磚塊像素美術規格

- 狀態：全部項目（D01、D02、D12~D21）使用者已確認；D03~D11 舊稿已依使用者決定刪除（代號不重新編號）
- 依據：README.md「磚塊種類」與「基本數值」；尺寸：內部解析度寬 360、關卡區高 640，一排 10 塊磚（磚 32×16，磚區寬 320，左右邊框各 20）
- 圖用文字網格表示：一字元 = 一像素；`.` = 透明；其他字元見 D01 調色盤；之後由工程師轉成 PNG
- 本文不含程式碼、不含圖檔
- 使用者已決定（本稿遵守）：採路線 B（細緻像素風，D12 母版）；磚 32×16；可破壞磚塊配色為彩虹七色；圓形 16×16 且碰撞為圓形；魔王 128×48；破壞動畫每幀小磚 60 ms、魔王 100 ms；一般磚併入多層磚，最多 69 層，顏色代表層數（每輪由低到高紅橙黃綠藍靛紫），磚中間的數字 1~9 代表第幾輪（第 0 輪不顯示數字）；不加橫向磚縫

## 視覺方向

| 項目 | 內容 |
|---|---|
| 主題 | 直式打磚塊 Roguelike（Android），給休閒手機玩家；玩家要在小螢幕上一眼分辨磚塊種類、顏色與剩餘層數；彩虹磚會依顏色一次破壞同色磚，所以「顏色」是玩法資訊 |
| 色彩 | 深藍黑描邊 `K`；可破壞磚塊主色限定彩虹七色（紅橙黃綠藍靛紫）；魔王用獨立的暗紫灰（不在七色內）；完整色碼見 D01 |
| 字型 | 無字型。多層磚的數字用自繪 5×7 像素字（D12；白色填色加 1 px `K` 描邊），非外部素材，無授權問題 |
| 版面 | 磚塊格 32×16；圓形 16×16 置中；魔王 128×48（= 4 欄 × 3 列格）；各磚種的精靈圖排版由轉檔工具依 D12 規則產生 |
| 原則 | 1. 顏色是玩法資訊：同一個顏色只代表「同色」，磚種靠形狀記號辨識 2. 顏色之外一定有第二線索（數字、圖案、形狀） 3. 七色在灰階下亮度盡量拉開 |

自我檢查（已換掉的通用預設）：
- 不用漸層與抖色，用 5 階色階的斜面與凹坑表現立體
- 不用「統一圓角卡片」語彙；磚塊是直角、寶箱有鎖、金幣有錢幣、圓形磚是圓、魔王有臉
- 多層磚的顏色與數字有真實順序（顏色＝層數，數字＝第幾輪），不是裝飾

---

1. [D01] 調色盤（使用者已確認，2026-10-26；七色各 5 階，共 82 色（含 D13 擋板用 2 色、D14 不可破壞磚塊用 2 色、D15 球用 6 色、D16 HUD 用 2 色、D17 功能型磚塊用 13 色、D18 功能型磚塊第 2 批用 5 色、D21 減益底板用 4 色），不受 32 色限制）：
   - 代號即網格字元，大小寫有別；本表為全檔唯一調色盤
   - 色階階次（每色 5 階，T1 最亮 → T5 最暗）：
     - T1：斜面最亮邊（上緣、左緣最外 1 px）、高光點、金屬高光
     - T2：斜面次亮邊（亮面）、凹坑下緣（亮邊）
     - T3：主色（磚面、木面主色）
     - T4：斜面暗部（右緣、下緣內側）、凹坑上緣（暗邊）、木板下緣
     - T5：最暗（最下緣與最右緣）、裂痕、木板接縫
   - 七色各用同一組階次；母版以紅色階（`h r R t o`）繪製，其他顏色用換色對照表產生（見 D12）

   | 代號 | HEX | 名稱 | 灰階亮度 Y | 用途 |
   |---|---|---|---|---|
   | `.` | 透明 | 透明 | - | 無像素 |
   | `K` | #1B1A2E | 描邊深藍黑 | 29 | 所有描邊、數字、鑰匙孔 |
   | `W` | #FFFFFF | 白 | 255 | 被擊中閃白、高光、牙齒、多層磚數字填色（D12） |
   | `G` | #B8BCD0 | 灰塵灰 | 189 | 破壞動畫灰塵；魔王牙尖陰影 |
   | `h` | #FF9C9C | 紅 T1 | 186 | 紅色階（見上方階次說明） |
   | `r` | #E8696B | 紅 T2 | 133 | 紅色階 |
   | `R` | #C22A30 | 紅 T3（主色） | 88 | 紅色階 |
   | `t` | #A3222A | 紅 T4 | 74 | 紅色階 |
   | `o` | #7E1A20 | 紅 T5 | 49 | 紅色階 |
   | `a` | #FFB866 | 橙 T1 | 199 | 橙色階（寶箱木面） |
   | `O` | #F28C28 | 橙 T2 | 159 | 橙色階 |
   | `d` | #E07A1E | 橙 T3（主色） | 143 | 橙色階 |
   | `b` | #B8601A | 橙 T4 | 117 | 橙色階 |
   | `c` | #7A3E10 | 橙 T5 | 74 | 橙色階 |
   | `A` | #FFF7C2 | 黃 T1 | 243 | 黃色階（金幣） |
   | `B` | #FFEB8A | 黃 T2 | 230 | 黃色階 |
   | `Y` | #F7D84A | 黃 T3（主色） | 209 | 黃色階 |
   | `C` | #C9A22A | 黃 T4 | 160 | 黃色階 |
   | `D` | #7E6416 | 黃 T5 | 99 | 黃色階 |
   | `E` | #D6F7BC | 綠 T1 | 230 | 綠色階（多層磚第 4 色，例：4、11、18 層…） |
   | `F` | #B0EC8E | 綠 T2 | 207 | 綠色階 |
   | `L` | #8EDB6A | 綠 T3（主色） | 183 | 綠色階 |
   | `H` | #5FA848 | 綠 T4 | 135 | 綠色階 |
   | `J` | #2F6A2C | 綠 T5 | 81 | 綠色階 |
   | `M` | #A8CEFF | 藍 T1 | 200 | 藍色階（多層磚第 5 色，例：5、12、19 層…） |
   | `N` | #6EA8F5 | 藍 T2 | 159 | 藍色階 |
   | `U` | #3E86E8 | 藍 T3（主色） | 124 | 藍色階 |
   | `P` | #2A60B8 | 藍 T4 | 90 | 藍色階 |
   | `S` | #183C80 | 藍 T5 | 57 | 藍色階 |
   | `T` | #8E88E8 | 靛 T1 | 149 | 靛色階 |
   | `X` | #6860D0 | 靛 T2 | 111 | 靛色階 |
   | `I` | #3A33A8 | 靛 T3（主色） | 66 | 靛色階 |
   | `k` | #28237A | 靛 T4 | 46 | 靛色階 |
   | `l` | #1E1A60 | 靛 T5 | 35 | 靛色階 |
   | `m` | #D2A8F8 | 紫 T1 | 190 | 紫色階（圓形磚） |
   | `n` | #AA78E0 | 紫 T2 | 147 | 紫色階 |
   | `V` | #8348C8 | 紫 T3（主色） | 104 | 紫色階 |
   | `p` | #5E2E9A | 紫 T4 | 73 | 紫色階 |
   | `q` | #3C1C68 | 紫 T5 | 46 | 紫色階 |
   | `i` | #E8ECF4 | 鋼灰 T1 | 236 | 金屬高光（寶箱） |
   | `e` | #C5CCDA | 鋼灰 T2 | 202 | 金屬亮面 |
   | `f` | #8A93A8 | 鋼灰 T3 | 148 | 金屬中間 |
   | `g` | #566077 | 鋼灰 T4 | 95 | 金屬暗面 |
   | `j` | #363D4F | 鋼灰 T5 | 61 | 金屬輪廓、鉚釘、鎖輪廓 |
   | `w` | #8CEBFA | 青（亮） | 208 | D13 擋板用：端帽小燈上半 |
   | `x` | #2BB5D4 | 青（中） | 143 | D13 擋板用：端帽小燈下半 |
   | `s` | #3F475C | 深槍金屬（面） | 71 | D14 不可破壞磚塊用：鋼板底色 |
   | `y` | #6D7690 | 槍金屬紋亮部 | 118 | D14 不可破壞磚塊用：斜紋防滑紋 |
   | `1` | #EDEAF7 | 珍珠白 T2 | 236 | D15 用：球本體亮面（T1 沿用 `W`） |
   | `2` | #D2CEE6 | 珍珠白 T3（主色） | 210 | D15 用：球本體主色 |
   | `3` | #9E98BC | 珍珠白 T4 | 158 | D15 用：球本體暗部 |
   | `4` | #6A6490 | 珍珠白 T5 | 107 | D15 用：球本體最暗（右下） |
   | `5` | #FF6FB5 | 品紅（亮） | 162 | D17 雷射磚用（D16 強化已改 ATK 字樣，不再使用；原 D15 外圍記號用，該方案已刪除） |
   | `6` | #B02A78 | 品紅（暗） | 91 | D17 雷射磚用（D16 強化已改 ATK 字樣，不再使用；原 D15 外圍記號用，該方案已刪除） |
   | `7` | #DDE0EA | 淺灰 | 224 | D16 用：強化線段第 2 階 |
   | `8` | #9EA4B6 | 中灰 | 164 | D16 用：強化線段第 4 階 |
   | `u` | #B4A6C8 | 魔王 T1 | 174 | 魔王最亮邊 |
   | `Q` | #8A7AA0 | 魔王 T2 | 128 | 魔王亮面 |
   | `Z` | #5A4A6E | 魔王 T3（主色） | 80 | 魔王主色（不在七色內） |
   | `z` | #3A2F4A | 魔王 T4 | 52 | 魔王暗面 |
   | `v` | #241C30 | 魔王 T5 | 33 | 魔王最暗 |
   | `@` | #FFC2DF | 洋紅 T1 | 216 | D17 用：雷射磚最亮邊（洋紅 T2 沿用 `5`、T4 沿用 `6`） |
   | `#` | #EA4FA6 | 洋紅 T3（主色） | 135 | D17 用：雷射磚主色 |
   | `%` | #6E1650 | 洋紅 T5 | 55 | D17 用：雷射磚最暗邊 |
   | `+` | #C8FFF0 | 電青 T1 | 237 | D17 用：閃電磚最亮邊、閃電外暈 |
   | `=` | #7DEFD6 | 電青 T2 | 202 | D17 用：閃電磚亮面 |
   | `~` | #1FC4AA | 電青 T3（主色） | 144 | D17 用：閃電磚主色 |
   | `*` | #138C80 | 電青 T4 | 102 | D17 用：閃電磚暗面 |
   | `&` | #0B544E | 電青 T5 | 62 | D17 用：閃電磚最暗邊 |
   | `0` | #FFF8E4 | 骨白 T1 | 248 | D17 用：死神磚最亮邊、牙齒、眼窩 |
   | `9` | #EFE4CB | 骨白 T2 | 228 | D17 用：死神磚亮面 |
   | `$` | #D9C9A8 | 骨白 T3（主色） | 202 | D17 用：死神磚主色 |
   | `^` | #A08E6C | 骨白 T4 | 144 | D17 用：死神磚暗面、骷髏亮部 |
   | `!` | #5C503C | 骨白 T5 | 81 | D17 用：死神磚最暗邊、骷髏本體 |
   | `?` | #F0C9A4 | 炸藥褐 T1 | 209 | D18 用：爆炸磚最亮邊 |
   | `-` | #CC9262 | 炸藥褐 T2 | 158 | D18 用：爆炸磚亮面 |
   | `/` | #94603C | 炸藥褐 T3（主色） | 108 | D18 用：爆炸磚主色 |
   | `;` | #66402A | 炸藥褐 T4 | 73 | D18 用：爆炸磚暗面、凹坑上緣 |
   | `:` | #3E2517 | 炸藥褐 T5 | 43 | D18 用：爆炸磚最暗邊 |
   | `_` | #B85CB0 | 暗紫（亮邊） | 129 | D21 用：減益底板 F1 的上緣、左緣內圈 |
   | `<` | #8C3F86 | 暗紫（中邊） | 94 | D21 用：減益底板 F1 的下緣、右緣內圈與轉角 |
   | `>` | #6A2166 | 暗紫（底板面） | 63 | D21 用：減益底板面（內容的透明處） |
   | `,` | #45143F | 暗紫（暗邊） | 40 | D21 用：減益底板 F2 的下緣、右緣內圈 |
   | `(` | #8F9A78 | 苔石 T1 | 147 | D23 用（方案 A 苔石牆；若使用者不選方案 A 則刪除這 5 色）：石板最亮邊 |
   | `)` | #6F7B5C | 苔石 T2 | 116 | D23 用：石板亮面 |
   | `[` | #55604A | 苔石 T3（主色） | 90 | D23 用：石板主色 |
   | `]` | #3E4837 | 苔石 T4 | 67 | D23 用：石板暗面、凹坑上緣 |
   | `{` | #2A3226 | 苔石 T5 | 46 | D23 用：石板最暗邊、裂痕 |

   - 灰階亮度 Y = 0.299R + 0.587G + 0.114B，手算近似值，請工程師用工具複核
   - 七色主色（T3）灰階由亮到暗：黃 209、綠 183、橙 143、藍 124、紫 104、紅 88、靛 66；相鄰最小差 16 / 255（紫與紅）
   - 多層磚數字與底色對比：改為白字加 `K` 描邊，七色底（T3）上至少一組達 4.69:1 以上（`K`／`W` 與七色的實算對比見 D12「多層磚層數（新規則）」）；原本「`K` 字在藍底約 4.8:1、在綠底約 11:1」的算法已作廢
   - 色數統計：`K`、`W`、`G` 共 3 + 七色 7×5 = 35 + 鋼灰 5 + 魔王 5 = 48 色；加 D13 擋板用的青色 2 色（`w`、`x`）、D14 不可破壞磚塊用的槍金屬 2 色（`s`、`y`）共 52 色；再加 D15 球用的珍珠白 4 色（`1`~`4`，T1 沿用 `W`）、品紅 2 色（`5`、`6`；現為 D17 雷射磚用，D16 強化已改 ATK 字樣，不再使用）共 58 色；D15 方案 C 沒有新增顏色；再加 D16 HUD 強化線段用的淺灰 `7`、中灰 `8` 共 60 色；再加 D17 功能型磚塊用的洋紅 3 色（`@`、`#`、`%`；T2、T4 沿用 `5`、`6`）、電青 5 色（`+ = ~ * &`）、骨白 5 色（`0 9 $ ^ !`）共 13 色，合計 73 色；再加 D18 功能型磚塊第 2 批用的炸藥褐 5 色（`? - / ; :`）共 78 色（彩虹磚、傳送磚沿用既有顏色，不新增）；再加 D21 減益道具底板用的暗紫 4 色（`_ < > ,`）共 82 色（D20 沒有新增顏色）
   - 靛色階（`T X I k l`）在 D12 的網格中沒有出現，但多層磚的七色換色對照表需要它，所以保留
   - 本表為全檔唯一調色盤
   - D23 方案 A（苔石牆）新增苔石 5 色（`( ) [ ] {`），若採用則合計 87 色；方案 B（橡木桁架）不新增顏色
   - 色彩來源為本稿自訂，無外部取色來源
   - 色盲：七色紅橙黃綠藍靛紫在紅綠色盲下會有混淆（紅、橙、綠）；本稿以亮度差加形狀記號補強，未用色盲模擬器驗證，請 QA 或使用者複核

2. [D02] 風格指南（使用者已確認，2026-10-26）：
   - 內部解析度寬 360、關卡區高 640；一排 10 塊磚，磚 32×16，磚區寬 320，左右邊框各 20（邊框美術不在本稿）
   - 細緻度標準：泰拉瑞亞式的細緻像素風（5 階色階、斜面、凹坑、木紋、金屬）；只參考風格，沒有複製任何圖
   - 不加橫向磚縫（保持數字預留區完整）

   | 項目 | 規則 |
   |---|---|
   | 光源 | 左上；上緣、左緣亮，下緣、右緣暗 |
   | 描邊 | 1 px `K`，四邊皆有；兩磚相鄰時黑邊成 2 px 線（用來分隔磚） |
   | 斜面寬度 | 2 px：上緣 T1、T2 兩列；左緣 T1、T2 兩行；下緣 T4、T5 兩列；右緣 T4、T5 兩行 |
   | 斜面轉角 | 右上與左下的 2×2 轉角用 `T2 T3 / T3 T4`（以紅為例 `rR / Rt`）銜接 |
   | 色階用法（磚面） | T3 為磚面；T2 為凹坑下緣；T4 為凹坑上緣；T5 為裂痕與最暗邊；T1 為最亮邊與高光 |
   | 高光 | 上緣最亮列左側有 4 px 白色高光條（`W`），上緣中段有 3 px 磨損（T2） |
   | 紋理規則 | 磚面只用「凹坑」與「裂痕」，不用隨機點：凹坑 3×2（上列 T4 3 px、下列 T2 2 px 且右移 1 px）；裂痕 T5 連續斜線，5 px 長 |
   | 凹坑密度 | 約 6 個，分散在左右兩側，中間不放 |
   | 數字預留區 | 參照 D12「多層磚層數（新規則）」；內容為數字白字加 `K` 描邊；預留區不放紋理、不加亮影；有數字的磚裂痕改 T3，第 0 輪（無數字）保留裂痕 |
   | 木紋（寶箱） | 橫向 2~4 px 短段（T4 或 T1），板上緣 T1、板下緣 T4；板與板之間 T5 接縫；右側 3 px 加深 |
   | 金屬（寶箱） | 鋼灰 5 階；柱體左亮右暗；鉚釘 2×2（左上亮、右下暗）；鎖有輪廓、高光、暗面 |
   | 抖色 (dithering) | 不用 |
   | 被擊中 | 規則以 D12 為準（D12「被擊中（1 幀）」） |
   | 破壞動畫 | 幀數、幀時間以 D12 為準（小磚 60 ms、魔王 100 ms） |
   | 以 D12 為準 | 本表與 D12 若有任何不一致（位置、尺寸、被擊中、自動產生規則等），一律以 D12 為準；D12 的欄、列編號從 0 起算 |

12. [D12] 路線 B 正式母版（使用者已確認，2026-10-26）：
    - 使用者已確認：採路線 B；內部解析度寬 360、關卡區高 640；一排 10 塊磚；磚 32×16；磚區寬 320，左右邊框各 20（邊框不在本稿）；魔王 128×48（4×3 格，置中於關卡格的第 3~6 欄，欄編號從 0 起算，即 1 起算的第 4~7 欄）；圓形磚 16×16 置中於 32×16 格內，碰撞範圍為圓形；不加橫向磚縫；多層磚（一般磚已併入多層磚，最多 69 層；顏色代表層數、數字 1~9 代表第幾輪，詳見下方「多層磚層數（新規則）」）；寶箱橙、金幣黃、圓形紫維持原外觀，但不屬於七色（不會被彩虹磚挑中）；魔王不在七色內；破壞動畫每幀小磚 60 ms、魔王 100 ms
    - 本項只畫「母版」；七色換色版本、多層磚各層、各色破壞幀由轉檔工具依下列規則自動產生
    - 母版色階一律使用 D01 的代號；母版的色階對照紅色階 `h r R t o`（T1~T5）
    - 魔王嘴巴與舌頭：2026-10-26 使用者提議把魔王舌頭當血條，新版以 D27 的 `boss_mouth_v2_patch` 疊在 `boss_normal` 上得 `boss_normal_v2`；本項原圖不改（待 D27 確認）
    - 網格尺寸為 32×16（磚、圓形所在的格）、128×48（魔王）、5×7（數字）
    - **欄、列編號一律從 0 起算**：左上角像素為第 0 欄、第 0 列，與網格的字元索引一致；本項所有「第 N 欄、第 N 列」皆依此（例：數字左上角在第 13 欄、第 4 列；裂痕在第 25~27 欄、第 3~7 列）

    自動產生規則：

    | 項目 | 規則 |
    |---|---|
    | 被擊中（1 幀） | 母版中除 `K`、`.` 以外的像素全部改成 `W`；魔王同規則 |
    | 魔王裂痕疊加（F1） | 裂痕層的非 `.` 像素覆蓋「魔王正常」圖的對應像素，`.` 的位置不變；兩張同為 128×48，逐像素對齊（此規則寫死在轉檔工具中；要修改請通知 PM，由工程師改工具） |
    | 七色換色 | 母版紅色階換成目標色階（見下方換色對照表）；`K`、`W`、`G`、`.` 不變 |
    | 通用破壞 F1~F4 | 以紅色階 `h r R t o` 繪製；套用到多層磚（用破壞當下的顏色）、寶箱（橙）、金幣（黃）、圓形（紫）時，換成該磚的色階；數字、鎖與錢幣細節不保留 |
    | 圓形專用 | 圓形的 F1（裂開）、F2（四塊散開）為專用網格（紫色階）；F3、F4 用通用幀（此規則寫死在轉檔工具中；要修改請通知 PM，由工程師改工具） |

    換色對照表（母版 → 目標）：

    | 目標 | T1（`h`） | T2（`r`） | T3（`R`） | T4（`t`） | T5（`o`） |
    |---|---|---|---|---|---|
    | 紅 | `h` | `r` | `R` | `t` | `o` |
    | 橙 | `a` | `O` | `d` | `b` | `c` |
    | 黃 | `A` | `B` | `Y` | `C` | `D` |
    | 綠 | `E` | `F` | `L` | `H` | `J` |
    | 藍 | `M` | `N` | `U` | `P` | `S` |
    | 靛 | `T` | `X` | `I` | `k` | `l` |
    | 紫 | `m` | `n` | `V` | `p` | `q` |

    各磚種與色階（僅供參考，網格已用實際代號繪製）：一般磚＝紅色階換七色；寶箱＝橙色階＋鋼灰；金幣＝黃色階；圓形＝紫色階；魔王＝魔王色階（`u Q Z z v`），眼睛用黃色階、舌頭用紅色階、牙齒用 `W` 與 `G`

    一般磚正常：
    ```text
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    KhhhWWWWhhhhhhhhhrrrhhhhhhhhhrRK
    KrrrrrrrrrrrrrrrrrrrrrrrrrrrrRtK
    KhrRRRRRRRRRRRRttRRRRRRRRRRoRtoK
    KhrRtttRRRRRRRRRRRRRRRtttRRoRtoK
    KhrRRrrRRRRRRRRRRRRRRRRrrRoRRtoK
    KhrRRRRRRRRRRRRRRRRRRRRRRRoRRtoK
    KhrRRRRRRRRRRRRRRRRRRRRRRoRRRtoK
    KhrRRRtttRRRRRRRRRRRRRRRtttRRtoK
    KhrRRRRrrRRRRRRRRRRRRRRRRrrRRtoK
    KhrRRRRRRRRRRRRRRRRRRRRRRRRRRtoK
    KhrtttRRRRRRRRRRRRRRRtttRRRRRtoK
    KhrRrrRRRRRRRRRRrrRRRRrrRRRRRtoK
    KrRtttttttttttttttttttttttttttoK
    KRtooooooooooooooooooooooooooooK
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    ```

    寶箱正常：
    ```text
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    KiefgaaaaaaaaaaaaaaaaaaaaaaefgjK
    KiefgOOOddddOOOOOOaaaOOddOdefgjK
    KiejgddbbddbjjjjjjjjdddbbddejgjK
    KiefgcccccccjieeeefjcccccccefgjK
    KiefgeeeeeeejeffffgjeeeeeeeefgjK
    KiefgfffieffjefKKfgjffiefffefgjK
    KiefgfffgjffjeKKKKgjffgjfffefgjK
    KiefggggggggjeKKKKgjgggggggefgjK
    KiefgbbbbbbbjefKKfgjbbbbbbbefgjK
    KiefgOddddOOjggggggjOOOOdddefgjK
    KiefgOOddddOjjjjjjjjOddOdddefgjK
    KiejgddddddddbbbbdddddddbbbejgjK
    KiefgbbbbbbbbbbbbbbbbbbbbbbefgjK
    KiefgccccccccccccccccccccccefgjK
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    ```

    金幣正常：
    ```text
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    KAAAWWWWAAAAAAAAABBBAAAAAAAAABYK
    KBBBBBBBBBBBBBBBBBBBBBBBBBBBBYCK
    KABYYYYYYYYYYYDDDDYYYYYYYYYYYCDK
    KABYCCCYYYYYDDAAACDDYYYCCCYYYCDK
    KABYYBBYYYYDAWDDDBBCDYYYBBYYYCDK
    KABYYYYYYYYDAWDBBBBCDYYYYYYYYCDK
    KABYYYYYYYYDABDDDBBCDYYYYYYYYCDK
    KABYYYYYYYYDBBBBDBBCDYYYYYYYYCDK
    KABYYCCCYYYDBBDDDBBCDYYCCCYYYCDK
    KABYYYBBYYYDBBBBBBBCDYYYBBYYYCDK
    KABYYYYYYYYYDDCCCCDDYYYYYYYYYCDK
    KABYYYYYYYYYYYDDDDYYYYYYYYYYYCDK
    KBYCCCCCCCCCCCCCCCCCCCCCCCCCCCDK
    KYCDDDDDDDDDDDDDDDDDDDDDDDDDDDDK
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    ```

    圓形正常：
    ```text
    .............KKKKKK.............
    ...........KKmnnnnVKK...........
    ..........KmmnnnnVVVVK..........
    .........KmmnnnnVVVVVVK.........
    .........KmnnnnVVpppVVK.........
    ........KmnnnnVVVVnnVppK........
    ........KnnnnVVVVVVVpppK........
    ........KnnnVVVVVVVppppK........
    ........KnnVVVVVVVpppppK........
    ........KnVpppVVVpppppqK........
    ........KVVVnnVVpppppqqK........
    .........KVVVVVpppppqqK.........
    .........KVVVVpppppqqqK.........
    ..........KVVpppppqqqK..........
    ...........KKppppqqKK...........
    .............KKKKKK.............
    ```
    F1 裂開：
    ```text
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    KhhhhhhhhhhhhhhhKhhhhhhhhhhhhrRK
    KrrrrrrrrrrrrrrKrrrrrrrrrrrrrRtK
    KhrRRRRRRRRRRRRRKRRRRRRRRRRRRtoK
    KhrRRRRRRRRRRRRRRKRRRRRRRRRRRtoK
    KhrRRRRRRRRRRRRRKRRRRRRRRRRRRtoK
    KhrRRRRRRRRRRRRKRRRRRRRRRRRRRtoK
    KhrRRRRRRRRRRRRKRRRRRRRRRRRRRtoK
    KhrRRRRRRRRRRRRRKRRRRRRRRRRRRtoK
    KhrRRRRRRRRRRRRRRKKKKRRRRRRRRtoK
    KhrRRRRRRRRRRRRRRKRRRRRRRRRRRtoK
    KhrRRRRRRRRRRRRRKRRRRRRRRRRRRtoK
    KhrRRRRRRRRKKKKKRRRRRRRRRRRRRtoK
    KrRttttttttttttKttttttttttttttoK
    KRtoooooooooooooKooooooooooooooK
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    ```

    F2 分成兩半：
    ```text
    .................KKKKKKKKKKKKKKK
    KKKKKKKKKKKKKKK..KhhhhhhhhhhhrRK
    KhhhhhhhhhhhhhK..KrrrrrrrrrrrRtK
    KrrrrrrrrrrrrrK..KRRRRRRRRRRRtoK
    KhrRRRRRRRRRRRK..KRRRRRRRRRRRtoK
    KhrRRRRRRRRRRRK..KRRRRRRRRRRRtoK
    KhrRRRRRRRRRRRK..KRRRRRRRRRRRtoK
    KhrRRRRRRRRRRRK..KRRRRRRRRRRRtoK
    KhrRRRRRRRRRRRK..KRRRRRRRRRRRtoK
    KhrRRRRRRRRRRRK..KRRRRRRRRRRRtoK
    KhrRRRRRRRRRRRK..KRRRRRRRRRRRtoK
    KhrRRRRRRRRRRRK..KRRRRRRRRRRRtoK
    KhrRRRRRRRRRRRK..KttttttttttttoK
    KrRtttttttttttK..KoooooooooooooK
    KRtoooooooooooK..KKKKKKKKKKKKKKK
    KKKKKKKKKKKKKKK.................
    ```

    F3 碎片：
    ```text
    ................................
    ...KKKKK........................
    ...KrRtK................KKKKK...
    ...KKKKK................KrRtK...
    ............KKKKK.......KKKKK...
    ............KrRtK...............
    ............KKKKK...............
    ................................
    .....KKKKK..........KKKKK.......
    .....KrRtK..........KrRtK.......
    .....KKKKK..........KKKKK.......
    ...........................KKKKK
    .............KKKKK.........KrRtK
    .............KrRtK.........KKKKK
    .............KKKKK..............
    ................................
    ```

    F4 灰塵：
    ```text
    ................................
    ................................
    ......W.........................
    ................................
    ...................G............
    ................................
    ..........G.....................
    ................................
    ...........................W....
    ..............G.................
    ................................
    ....G...........................
    .......................W........
    .................G..............
    .........G......................
    ................................
    ```

    圓形 F1 裂開：
    ```text
    .............KKKKKK.............
    ...........KKmnnKnVKK...........
    ..........KmmnnKnVVVVK..........
    .........KmmnnnnKVVVVVK.........
    .........KmnnnnVVKppVVK.........
    ........KmnnnnVVKVnnVppK........
    ........KnnnnVVKVVVVpppK........
    ........KnnnVVVVKVVppppK........
    ........KnnVVVVVVKpppppK........
    ........KnVpppVVKpppppqK........
    ........KVVVnnVKpppppqqK........
    .........KVVVVVpKpppqqK.........
    .........KVVVVpppKpqqqK.........
    ..........KVVpppKpqqqK..........
    ...........KKppKpqqKK...........
    .............KKKKKK.............
    ```

    圓形 F2 四塊散開：
    ```text
    ................................
    .....KKKKKK..........KKKKKK.....
    .....KmnVVK..........KnVVVK.....
    .....KnVVVK..........KVVVVK.....
    .....KVVVpK..........KVVVpK.....
    .....KVVppK..........KVVppK.....
    .....KKKKKK..........KKKKKK.....
    ................................
    ................................
    .........KKKKKK..KKKKKK.........
    .........KmnVVK..KnVVVK.........
    .........KnVVVK..KVVVVK.........
    .........KVVVpK..KVVVpK.........
    .........KVVppK..KVVppK.........
    .........KKKKKK..KKKKKK.........
    ................................
    ```
    數字字型 0~9（每個 5×7，`K` 為墨色、`.` 為透明；組合規則見上表，不加亮影）：

    數字 0：
    ```text
    .KKK.
    K...K
    K...K
    K...K
    K...K
    K...K
    .KKK.
    ```

    數字 1：
    ```text
    ..K..
    .KK..
    ..K..
    ..K..
    ..K..
    ..K..
    .KKK.
    ```

    數字 2：
    ```text
    .KKK.
    K...K
    ....K
    ...K.
    ..K..
    .K...
    KKKKK
    ```

    數字 3：
    ```text
    KKKK.
    ....K
    ....K
    .KKK.
    ....K
    ....K
    KKKK.
    ```

    數字 4：
    ```text
    ...K.
    ..KK.
    .K.K.
    K..K.
    KKKKK
    ...K.
    ...K.
    ```

    數字 5：
    ```text
    KKKKK
    K....
    KKKK.
    ....K
    ....K
    K...K
    .KKK.
    ```

    數字 6：
    ```text
    .KKK.
    K....
    K....
    KKKK.
    K...K
    K...K
    .KKK.
    ```

    數字 7：
    ```text
    KKKKK
    ....K
    ...K.
    ..K..
    ..K..
    ..K..
    ..K..
    ```

    數字 8：
    ```text
    .KKK.
    K...K
    K...K
    .KKK.
    K...K
    K...K
    .KKK.
    ```

    數字 9：
    ```text
    .KKK.
    K...K
    K...K
    .KKKK
    ....K
    ....K
    .KKK.
    ```

    ---

    多層磚層數（新規則）（取代上方舊的「藍層 1~9、綠層 10~14、個位數字」規則）：

    - 來源：README 第 14 行與使用者決定。一般磚已併入多層磚；最多 69 層；數字只用 1 位數（1~9），不畫 2 位數
    - 寶箱、金幣、圓形磚維持原外觀，但不屬於七色
    - 顏色代表層數，數字代表「第幾輪」；數字 0 不顯示

    層數對應：

    | 項目 | 規則 |
    |---|---|
    | 輪數 | （層數 − 1）除以 7 取整數，範圍 0~9；0 ＝ 第 0 輪，不顯示數字 |
    | 顏色 | （層數 − 1）除以 7 的餘數：0 紅、1 橙、2 黃、3 綠、4 藍、5 靛、6 紫 |
    | 數字 | 等於輪數；1~9 用對應字形；0 不畫 |
    | 範圍 | 層 1~69（最高為「靛 9」＝ 69 層）；「紫 9」＝ 70 層會產生圖但不使用 |

    | 層數 | 外觀 | 層數 | 外觀 |
    |---|---|---|---|
    | 1 | 紅（無數字） | 14 | 紫 1 |
    | 2 | 橙（無數字） | 15 | 紅 2 |
    | 7 | 紫（無數字） | 20 | 靛 2（README 範例） |
    | 8 | 紅 1（README 範例） | 24 | 黃 3 |
    | 9 | 橙 1 | 61 | 藍 8 |
    | 13 | 靛 1 | 69 | 靛 9 |

    數字的畫法（數字 1~9 共用同一套規則）：

    | 項目 | 規則 |
    |---|---|
    | 字形 | 沿用上方 D12「數字字型 0~9」的 5×7 字形，只用 1~9 |
    | 位置 | 字形左上角放在第 13 欄、第 4 列（欄列從 0 起算）；字形佔第 13~17 欄、第 4~10 列 |
    | 填色 | 字形的 `K` 像素改成 `W`（白） |
    | 描邊 | 字形每個像素的 8 個相鄰格（上下左右與四個斜角）中，不屬於字形的格子畫 `K`；描邊使整個數字佔第 12~18 欄、第 3~11 列（7×9） |
    | 疊加方式 | 白字加描邊做成一張 32×16 的疊加圖（`.` 透明），非 `.` 像素覆蓋磚的對應像素；磚面色（T3）由換色表決定 |
    | 預留區 | 母版第 11~20 欄、第 4~11 列不放紋理；第 3 列第 15~16 欄的磨損（T4）一定被描邊蓋住，不需處理；第 12 列第 16~17 欄的磨損（T2）改成 T3，免得貼在描邊下緣像多一個點 |
    | 裂痕 | 母版右上的裂痕（第 25~27 欄、第 3~7 列的 T5 像素）換成 T3；只有「有數字」的磚這樣做，第 0 輪（無數字）保留母版裂痕 |
    | 亮影 | 不加 |
    | 被擊中、破壞中的數字 | 被擊中幀的數字白字與磚面同為白，只剩 `K` 描邊，數字輪廓仍可見；破壞 F1~F4 不保留數字 |

    為什麼用「白字加 `K` 描邊」：
    - 單用 `K` 字：在靛、紅、紫三色底上不到 4.5:1（見下表），原本的做法行不通
    - 單用 `W` 字：在黃、綠、橙、藍四色底上不到 4.5:1，也行不通
    - 白字加 `K` 描邊：任何一色底，字的邊緣（`K` 或 `W` 其中一組）都 ≥ 4.69:1；白字與 `K` 描邊之間固定 17.0:1，所以數字的形狀永遠讀得出來
    - 代價：字變成 7×9 的粗輪廓；仍在預留區（第 11~20 欄、第 3~11 列）內，沒有蓋到其他磚面細節

    對比數值（磚色用 T3 主色，按 WCAG 相對亮度公式手算，請工程師用工具複核）：

    | 磚色 | T3 色碼 | `W` 對底 | `K` 對底 | 較高的一組 |
    |---|---|---|---|---|
    | 紅 `R` | #C22A30 | 5.73:1 | 2.97:1 | 5.73:1（W） |
    | 橙 `d` | #E07A1E | 3.01:1 | 5.65:1 | 5.65:1（K） |
    | 黃 `Y` | #F7D84A | 1.41:1 | 12.06:1 | 12.06:1（K） |
    | 綠 `L` | #8EDB6A | 1.68:1 | 10.12:1 | 10.12:1（K） |
    | 藍 `U` | #3E86E8 | 3.63:1 | 4.69:1 | 4.69:1（K）← 全部最低 |
    | 靛 `I` | #3A33A8 | 9.46:1 | 1.80:1 | 9.46:1（W） |
    | 紫 `V` | #8348C8 | 5.64:1 | 3.02:1 | 5.64:1（W） |
    | `W` 對 `K` | - | - | - | 17.02:1 |

    最難讀的組合與範例：
    - 靛底：`K` 字只有 1.80:1，是舊做法最糟的底色 → 範例「靛 2」
    - 藍底：`W` 與 `K` 對底都低於 5:1（3.63、4.69），是新做法下對比最低的底色；再配上描邊最密、內孔被填滿的「8」→ 範例「藍 8」，我判斷是最難讀的組合
    - 黃底：白字幾乎消失（1.41:1），完全靠 `K` 描邊讀字 → 範例「黃 3」
    - 紅底：README 範例「紅 1」→ 範例「紅 1」
    - 其餘組合依同一規則自動產生，沒有另附範例

    圖寬：32　圖高：16
    多層磚 紅 ＋ 數字 1（第 8 層）（id: layer_example_red1）：
    ```text
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    KhhhWWWWhhhhhhhhhrrrhhhhhhhhhrRK
    KrrrrrrrrrrrrrrrrrrrrrrrrrrrrRtK
    KhrRRRRRRRRRRRKKKRRRRRRRRRRRRtoK
    KhrRtttRRRRRRKKWKRRRRRtttRRRRtoK
    KhrRRrrRRRRRRKWWKRRRRRRrrRRRRtoK
    KhrRRRRRRRRRRKKWKRRRRRRRRRRRRtoK
    KhrRRRRRRRRRRRKWKRRRRRRRRRRRRtoK
    KhrRRRtttRRRRRKWKRRRRRRRtttRRtoK
    KhrRRRRrrRRRRKKWKKRRRRRRRrrRRtoK
    KhrRRRRRRRRRRKWWWKRRRRRRRRRRRtoK
    KhrtttRRRRRRRKKKKKRRRtttRRRRRtoK
    KhrRrrRRRRRRRRRRRRRRRRrrRRRRRtoK
    KrRtttttttttttttttttttttttttttoK
    KRtooooooooooooooooooooooooooooK
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    ```

    圖寬：32　圖高：16
    多層磚 靛 ＋ 數字 2（第 20 層）（id: layer_example_indigo2）：
    ```text
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    KTTTWWWWTTTTTTTTTXXXTTTTTTTTTXIK
    KXXXXXXXXXXXXXXXXXXXXXXXXXXXXIkK
    KTXIIIIIIIIIIKKKKKIIIIIIIIIIIklK
    KTXIkkkIIIIIKKWWWKKIIIkkkIIIIklK
    KTXIIXXIIIIIKWKKKWKIIIIXXIIIIklK
    KTXIIIIIIIIIKKKKKWKIIIIIIIIIIklK
    KTXIIIIIIIIIIIKKWKKIIIIIIIIIIklK
    KTXIIIkkkIIIIKKWKKIIIIIIkkkIIklK
    KTXIIIIXXIIIKKWKKKKIIIIIIXXIIklK
    KTXIIIIIIIIIKWWWWWKIIIIIIIIIIklK
    KTXkkkIIIIIIKKKKKKKIIkkkIIIIIklK
    KTXIXXIIIIIIIIIIIIIIIIXXIIIIIklK
    KXIkkkkkkkkkkkkkkkkkkkkkkkkkkklK
    KIkllllllllllllllllllllllllllllK
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    ```

    圖寬：32　圖高：16
    多層磚 藍 ＋ 數字 8（第 61 層）（id: layer_example_blue8）：
    ```text
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    KMMMWWWWMMMMMMMMMNNNMMMMMMMMMNUK
    KNNNNNNNNNNNNNNNNNNNNNNNNNNNNUPK
    KMNUUUUUUUUUUKKKKKUUUUUUUUUUUPSK
    KMNUPPPUUUUUKKWWWKKUUUPPPUUUUPSK
    KMNUUNNUUUUUKWKKKWKUUUUNNUUUUPSK
    KMNUUUUUUUUUKWKKKWKUUUUUUUUUUPSK
    KMNUUUUUUUUUKKWWWKKUUUUUUUUUUPSK
    KMNUUUPPPUUUKWKKKWKUUUUUPPPUUPSK
    KMNUUUUNNUUUKWKKKWKUUUUUUNNUUPSK
    KMNUUUUUUUUUKKWWWKKUUUUUUUUUUPSK
    KMNPPPUUUUUUUKKKKKUUUPPPUUUUUPSK
    KMNUNNUUUUUUUUUUUUUUUUNNUUUUUPSK
    KNUPPPPPPPPPPPPPPPPPPPPPPPPPPPSK
    KUPSSSSSSSSSSSSSSSSSSSSSSSSSSSSK
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    ```

    圖寬：32　圖高：16
    多層磚 黃 ＋ 數字 3（第 24 層）（id: layer_example_yellow3）：
    ```text
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    KAAAWWWWAAAAAAAAABBBAAAAAAAAABYK
    KBBBBBBBBBBBBBBBBBBBBBBBBBBBBYCK
    KABYYYYYYYYYKKKKKKYYYYYYYYYYYCDK
    KABYCCCYYYYYKWWWWKKYYYCCCYYYYCDK
    KABYYBBYYYYYKKKKKWKYYYYBBYYYYCDK
    KABYYYYYYYYYYKKKKWKYYYYYYYYYYCDK
    KABYYYYYYYYYYKWWWKKYYYYYYYYYYCDK
    KABYYYCCCYYYYKKKKWKYYYYYCCCYYCDK
    KABYYYYBBYYYKKKKKWKYYYYYYBBYYCDK
    KABYYYYYYYYYKWWWWKKYYYYYYYYYYCDK
    KABCCCYYYYYYKKKKKKYYYCCCYYYYYCDK
    KABYBBYYYYYYYYYYYYYYYYBBYYYYYCDK
    KBYCCCCCCCCCCCCCCCCCCCCCCCCCCCDK
    KYCDDDDDDDDDDDDDDDDDDDDDDDDDDDDK
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    ```

    範例網格說明：以上四張都由「第 0 輪母版換色 → 裂痕與第 12 列磨損改 T3 → 疊上白字加 `K` 描邊的數字」產生；數字區在第 12~18 欄、第 3~11 列；未畫的其他數字（2~9 其餘組合）依同一規則產生

    扣層順序（層數 n → n − 1）：

    | 步驟 | 內容 |
    |---|---|
    | 1 | 先播 1 幀「被擊中」：用扣層前那張圖（含數字）套 D12 被擊中規則，60 ms |
    | 2 | 再切換成 n − 1 層的正常圖（顏色換成下一個較低的顏色，必要時數字減 1） |
    | 3 | 層數降到 0 ＝ 被擊中後播破壞 F1~F4（用當下顏色的色階，紅色階；數字不保留） |

    | 例（扣層前 → 被擊中幀 → 換成） | 說明 |
    |---|---|
    | 橙 1（9 層）→ 橙 1 被擊中 → 紅 1（8 層） | 同輪內往下一個顏色 |
    | 紅 1（8 層）→ 紅 1 被擊中 → 紫（7 層，無數字） | 輪數減 1，數字 1 消失，回到紫 |
    | 紅 2（15 層）→ 紅 2 被擊中 → 紫 1（14 層） | 跨輪：顏色回到紫，數字減 1 |
    | 靛 2（20 層）→ 靛 2 被擊中 → 藍 2（19 層） | 同輪 |
    | 紅（1 層）→ 紅被擊中 → 破壞 F1~F4（紅色階） | 最後一層 |

    - 一次扣多層（球的攻擊力加成）：使用者已決定：一次扣多層只播 1 幀被擊中，直接換成最終層的圖

    炸彈標記期間（對應 D15 原規則「被標記的磚不顯示層數數字」）：
    - 有數字的磚（第 1 輪以上）改用「同顏色、第 0 輪（無數字）」那張圖；顏色仍是當下層數的顏色
    - 這張圖是第 0 輪七色圖之一，不需要新增圖；標記移除前不顯示數字；層數仍由磚的資料記錄
    - 第 0 輪圖保留母版裂痕（第 25~27 欄、第 3~7 列），炸彈標記（右上角）會蓋住大部分裂痕；使用者已決定：保留裂痕，不另產無裂痕版

    已由工程師實作（2026-10-26）的自動產生規則（規則寫死在轉檔工具；要修改請通知 PM，由工程師改工具）：

    | 項目 | 新規則 | 張數 |
    |---|---|---|
    | 第 0 輪正常圖 | 母版紅色階換七色（沿用換色表） | 7 |
    | 數字 1~9 正常圖 | 七色 ×（數字 1~9）：先換色，再把裂痕與第 12 列第 16~17 欄磨損改 T3，再疊上對應數字的白字加 `K` 描邊疊加圖 | 63 |
    | 正常圖合計 | 7 色 ×（無數字 ＋ 數字 1~9）＝ 10 種外觀 × 7 色 | 70 |
    | 數字疊加圖 | 由字形自動產生：字形 `K` 改 `W`，再對每個 `W` 的 8 個鄰格畫 `K`；數字 1~9 共 9 張 32×16 疊加圖（或直接在合成時計算，不輸出） | 9（或 0） |
    | 被擊中圖 | 70 張正常圖各套 D12 被擊中規則（除 `K`、`.` 外全改 `W`） | 70 |
    | 破壞 F1~F4 | 七色各 4 張，只看破壞當下的顏色，與數字無關 | 28 |
    | 炸彈標記 | 重用第 0 輪七色圖，不新增 | 0 |
    | 圖與層數對應 | 工具輸出對照表：層 1~69 → （顏色, 數字） | - |
    | 不可刪除 | 數字 0~9 字形（D17 功能型磚塊仍用 0~9，K 墨色），上方字形網格請保留 | - |

    給工程師的需求：
    - 不需要新的後端資料或 API
    - 遊戲程式要處理：層數 1~69 轉成（顏色, 數字）的對應；扣層時先播被擊中再換圖；炸彈標記期間改顯示第 0 輪圖；彩虹磚只看顏色、不看數字（見 D18）

    魔王正常：
    ```text
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    KuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuQZK
    KQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQZzK
    KuQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQzvK
    KuQQQQQQQQQQQZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZQQQQQQQQQQzvK
    KuQZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZzvK
    KuQZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZKKZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZzvK
    KuQZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZKYYKZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZzvK
    KuQZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZKYAAYKZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZzvK
    KuQZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZKYYAAYYKZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZzvK
    KuQZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZKYAAYKZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZzvK
    KuQZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZKYYKZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZzvK
    KuQZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZKKZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZzvK
    KuQZZZZZZKKKKKKKKKKKKKKZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZKKKKKKKKKKKKKKZZZZZZzvK
    KuQZZZZZZKKKKKKKKKKKKKKZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZKKKKKKKKKKKKKKZZZZZZzvK
    KuQZZZZZZKKKKKKKKKKKKKKZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZKKKKKKKKKKKKKKZZZZZZzvK
    KuQZZZZZZZZZZZZZZZZZZZZKKKKKKKKKKKKKKZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZKKKKKKKKKKKKKKZZZZZZZZZZZZZZZZZZZZzvK
    KuQZZZZZZZZZZZZZZZZZZZZKKKKKKKKKKKKKKZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZKKKKKKKKKKKKKKZZZZZZZZZZZZZZZZZZZZzvK
    KuQZZZZZZZZZZZZZZZZZZZZKKKKKKKKKKKKKKZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZKKKKKKKKKKKKKKZZZZZZZZZZZZZZZZZZZZzvK
    KuQZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZKKKKKKKKKKKKKKZZZZZZZZZZZZZZZZZZZZZZZZZZKKKKKKKKKKKKKKZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZzvK
    KuQZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZKKKKKKKKKKKKKKZZZZZZZZZZZZZZZZZZZZZZZZZZKKKKKKKKKKKKKKZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZzvK
    KuQZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZKKKKKKKKKKKKKKZZZZZZZZZZZZZZZZZZZZZZZZZZKKKKKKKKKKKKKKZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZzvK
    KuQZZZZZKKKKKKKKKKKKKKKKKKKKKKKKKKZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZKKKKKKKKKKKKKKKKKKKKKKKKKKZZZZZzvK
    KuQZZZZZKCCCCCCCCCCCCCCCCCCCCCCCCKZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZKCCCCCCCCCCCCCCCCCCCCCCCCKZZZZZzvK
    KuQZZZZZKCCCCCCCCCCCCCCCCCCCCCCCCKZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZKCCCCCCCCCCCCCCCCCCCCCCCCKZZZZZzvK
    KuQZZZZZKYYYYYYYYYYYYYYYYYYYYYYYYKZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZKYYYYYYYYYYYYYYYYYYYYYYYYKZZZZZzvK
    KuQZZZZZKYYYYYYYYYYYYYYWWKKYYYYYYKZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZKYYYYYYKKWWYYYYYYYYYYYYYYKZZZZZzvK
    KuQZZZZZKYYYYYYYYYYYYYYKKKKYYYYYYKZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZKYYYYYYKKKKYYYYYYYYYYYYYYKZZZZZzvK
    KuQZZZZZKYYYYYYYYYYYYYYKKKKYYYYYYKZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZKYYYYYYKKKKYYYYYYYYYYYYYYKZZZZZzvK
    KuQZZZZZKYYYYYYYYYYYYYYKKKKYYYYYYKZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZKYYYYYYKKKKYYYYYYYYYYYYYYKZZZZZzvK
    KuQZZZZZKAAAAAAAAAAAAAAAAAAAAAAAAKZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZKAAAAAAAAAAAAAAAAAAAAAAAAKZZZZZzvK
    KuQZZZZZKAAAAAAAAAAAAAAAAAAAAAAAAKZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZKAAAAAAAAAAAAAAAAAAAAAAAAKZZZZZzvK
    KuQZZZZZKKKKKKKKKKKKKKKKKKKKKKKKKKZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZKKKKKKKKKKKKKKKKKKKKKKKKKKZZZZZzvK
    KuQZZZZZZZZzzzZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZzzzZZZZZZZZzvK
    KuQZZZZZZZZZQQZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZKKKKKKKKZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZQQZZZZZZZZZzvK
    KuQZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZKKKKKKKKZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZzvK
    KuQZZZZZZZZZZKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKZZZZZZZZZZzvK
    KuQZZZZZZZZZZKWWWWWKWWWWWKWWWWWKWWWWWKWWWWWKWWWWWKWWWWWKWWWWWKWWWWKWWWWWKWWWWWKWWWWWKWWWWWKWWWWWKWWWWWKWWWWWKWWWWWKZZZZZZZZZZzvK
    KuQZZZZZZZZZZKWWWWWKWWWWWKWWWWWKWWWWWKWWWWWKWWWWWKWWWWWKWWWWWKWWWWKWWWWWKWWWWWKWWWWWKWWWWWKWWWWWKWWWWWKWWWWWKWWWWWKZZZZZZZZZZzvK
    KuQZZZZZZZZZZKGGGGGKGGGGGKGGGGGKGGGGGKGGGGGKGGGGGKGGGGGKGGGGGKGGGGKGGGGGKGGGGGKGGGGGKGGGGGKGGGGGKGGGGGKGGGGGKGGGGGKZZZZZZZZZZzvK
    KuQZZZZZZZZZZKKKKKKKKKKrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrKKKKKKKKKKZZZZZZZZZZzvK
    KuQZZZZZZZZZZKKKKKKKKKKRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRKKKKKKKKKKZZZZZZZZZZzvK
    KuQZZZZZZZZZZKKKKKKKKKKttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttKKKKKKKKKKZZZZZZZZZZzvK
    KuQZZZZZZZZZZKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKZZZZZZZZZZzvK
    KuQzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzvK
    KQZzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzK
    KZzvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvK
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    ```
    魔王裂痕疊加：
    ```text
    ................................................................................................................................
    .................................................................K..............................................................
    ................................................................K...............................................................
    ...............................................................K................................................................
    ................................................................K...............................................................
    .................................................................K..............................................................
    ................................................................K...............................................................
    ...............................................................K................................................................
    ................................................................K...............................................................
    .................................................................K..............................................................
    ................................................................K...............................................................
    ...............................................................K................................................................
    ................................................................K...............................................................
    .................................................................K..............................................................
    ................................................................K...............................................................
    ...............................................................K................................................................
    ................................................................KKKKKKKKKKK.....................................................
    .................................................................K..............................................................
    ................................................................K...............................................................
    ...............................................................K................................................................
    ................................................................K...............................................................
    .................................................................K..............................................................
    ................................................................K...............................................................
    ...............................................................K................................................................
    ................................................................K...............................................................
    .................................................................K..............................................................
    ................................................................K...............................................................
    ...............................................................K................................................................
    ................................................................K...............................................................
    .................................................................K..............................................................
    ................................................................K...............................................................
    ...............................................................K................................................................
    ......................................................KKKKKKKKKKK...............................................................
    .................................................................K..............................................................
    ................................................................K...............................................................
    ...............................................................K................................................................
    ................................................................K...............................................................
    .................................................................K..............................................................
    ................................................................K...............................................................
    ...............................................................K................................................................
    ................................................................K...............................................................
    .................................................................K..............................................................
    ................................................................K...............................................................
    ...............................................................K................................................................
    ................................................................K...............................................................
    .................................................................K..............................................................
    ................................................................K...............................................................
    ................................................................................................................................
    ```
    魔王 F2 裂成六塊：
    ```text
    ................................................................................................................................
    ................................................................................................................................
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK....KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK....KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    KuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuK....KuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuK....KuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuK
    KQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQK....KQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQK....KQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQK
    KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK
    KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK
    KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK
    KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK
    KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK
    KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK
    KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK
    KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK
    KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK
    KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK
    KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK
    KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK
    KzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzK....KzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzK....KzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzK
    KvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvK....KvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvK....KvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvK
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK....KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK....KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK....KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK....KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    KuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuK....KuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuK....KuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuK
    KQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQK....KQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQK....KQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQK
    KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK
    KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK
    KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK
    KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK
    KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK
    KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK
    KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK
    KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK
    KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK
    KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK
    KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK
    KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK....KZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZK
    KzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzK....KzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzK....KzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzK
    KvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvK....KvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvK....KvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvK
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK....KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK....KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    ................................................................................................................................
    ................................................................................................................................
    ```

    魔王 F3 碎片：
    ```text
    ................................................................................................................................
    ................................................................................................................................
    ......KKKKKKKK......................KKKKKKKK..........................KKKKKKKK..............................KKKKKKKK............
    ......KQQZZZzK......................KQQZZZzK..........................KQQZZZzK..............................KQQZZZzK............
    ......KQZZZzzK......................KQZZZzzK..........................KQZZZzzK..............................KQZZZzzK............
    ......KZZzzzzK......................KZZzzzzK..........................KZZzzzzK..............................KZZzzzzK............
    ......KKKKKKKK......................KKKKKKKK..........................KKKKKKKK..............................KKKKKKKK............
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ....................KKKKKKKK........................KKKKKKKK............................KKKKKKKK......................KKKKKKKK..
    ....................KQQZZZzK........................KQQZZZzK............................KQQZZZzK......................KQQZZZzK..
    ....................KQZZZzzK........................KQZZZzzK............................KQZZZzzK......................KQZZZzzK..
    ....................KZZzzzzK........................KZZzzzzK............................KZZzzzzK......................KZZzzzzK..
    ....................KKKKKKKK........................KKKKKKKK............................KKKKKKKK......................KKKKKKKK..
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ............KKKKKKKK........................KKKKKKKK..........................KKKKKKKK..................KKKKKKKK................
    ............KQQZZZzK........................KQQZZZzK..........................KQQZZZzK..................KQQZZZzK................
    ............KQZZZzzK........................KQZZZzzK..........................KQZZZzzK..................KQZZZzzK................
    ............KZZzzzzK........................KZZzzzzK..........................KZZzzzzK..................KZZzzzzK................
    ............KKKKKKKK........................KKKKKKKK..........................KKKKKKKK..................KKKKKKKK................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ............................KKKKKKKK..........................KKKKKKKK..........................KKKKKKKK..........KKKKKKKK......
    ............................KQQZZZzK..........................KQQZZZzK..........................KQQZZZzK..........KQQZZZzK......
    ............................KQZZZzzK..........................KQZZZzzK..........................KQZZZzzK..........KQZZZzzK......
    ............................KZZzzzzK..........................KZZzzzzK..........................KZZzzzzK..........KZZzzzzK......
    ............................KKKKKKKK..........................KKKKKKKK..........................KKKKKKKK..........KKKKKKKK......
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ```

    魔王 F4 灰塵：
    ```text
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ......G.........................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ........................................W.......................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ......................G.........................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ......................................................G.........................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ..............................W.................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ............G...................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ```


13. [D13] 擋板（使用者已確認，2026-10-26）：
    - 使用者決定：高 8 px；基準長度 64 px；最大長度 320 px（關卡區全寬，左右碰到邊框）
    - 道具改變長度後的結果長度：小增 77、大增 102、小減 51、大減 26、最短暫定 16（最短待 README 更新時確認）
    - 因為長度會變，擋板拆成「左端、可重複的中段、右端」，由程式依長度拼接
    - 狀態：正常、被擊中（1 幀閃白）、槍（增益）、吸附（增益）、隱形（減益；由程式調透明度，不用畫）
    - 風格沿用 D01、D02：1 px `K` 描邊、左上光源、5 階色階；擋板不屬彩虹七色
    - 材質：鋼灰 5 階（`i e f g j`）金屬板，端帽有青色小燈；與彩色的磚塊一眼可分
    - 欄、列編號一律從 0 起算（左上角像素為第 0 欄、第 0 列）
    - 使用者決定：擋板本體高 8；槍的砲管可以往上突出 4 px（槍端圖高 12）
    - 尺寸規格（固定句型，供工具解析）：
      - 圖高（本體）：8
      - 圖高（槍左端）：12
      - 圖高（槍右端）：12
      - 圖高（完整圖，正常與吸附）：8
      - 圖高（完整圖，槍）：12
      - 左端寬：8
      - 右端寬：8
      - 中段圖塊寬：16
      - 完整圖寬：64
    - 底部對齊與碰撞：拼接時各段底部對齊，整條高 = 各段最大高；**碰撞範圍只算本體 8 px，砲管（槍端上方 4 列）不參與碰撞**（給之後的遊戲程式）

    拼接規則（程式依這些規則組出任意長度的擋板）：

    | 項目 | 規則 |
    |---|---|
    | 組成 | 左端（寬 8）＋ 中段（寬 `L − 16`）＋ 右端（寬 8）；`L` 為擋板長度，單位 px |
    | 長度取整與範圍 | `L` 先四捨五入為整數，再限制在 16~320 之間（小於 16 一律當 16；大於 320 一律當 320） |
    | 中段拼法 | 令 `W = L − 16`；**中段圖塊寬 16**；`n = W 除以 16 取整數（無條件捨去）`；`r = W 除以 16 的餘數`；中段 = 「中段圖塊」完整重複 `n` 次，再補 1 個「裁切圖塊」（若 `r > 0`） |
    | 裁切圖塊 | 取中段圖塊最左邊的 `r` 欄（第 0~`r−1` 欄），從右邊裁掉其餘；中段圖塊的鉚釘在第 7~8 欄，若 `r = 8` 只會露出鉚釘左半邊（1 欄寬），屬可接受的小瑕疵 |
    | 最短 16 px | `W = 0`，中段不畫：左端的第 0~7 欄緊接右端的第 0~7 欄，共 16 欄 |
    | 例 | `L = 64`：`W = 48`，`n = 3`、`r = 0`，3 個完整圖塊，無裁切（與下方三張 64 px 完整圖一致）；`L = 77`：`W = 61`，`n = 3`、`r = 13`；`L = 102`：`W = 86`，`n = 5`、`r = 6`；`L = 51`：`W = 35`，`n = 2`、`r = 3`；`L = 26`：`W = 10`，`n = 0`、`r = 10`；`L = 320`：`W = 304`，`n = 19`、`r = 0` |
    | 位置 | 擋板的左端最左欄對齊擋板左邊界；中段由左端右側開始，由左向右排；右端貼在最後 |
    | 槍 | 把左端、右端換成「槍左端、槍右端」（各 8 寬 × 12 高：上 4 列只畫砲管，下 8 列是擋板本體）；中段沿用正常中段圖塊（高 8）；砲管在左端第 2~5 欄、右端第 2~5 欄（最左、最右邊），砲口閃光在第 3~4 欄；槍的端帽小燈改為黃色 |
    | 高度與對齊 | 拼接時各段底部對齊；整條高 = 各段最大高（正常、吸附為 8；槍為 12）；中段圖塊高 8，上方不足的列補透明，不另畫 |
    | 碰撞 | 只算本體 8 px（槍的下 8 列）；砲管（槍的上 4 列）不參與碰撞 |
    | 吸附 | 把左端、中段、右端三個圖塊全部換成吸附版；拼接規則不變（2026-10-26 使用者要求移除綠色，吸附版外觀與正常版相同；吸附狀態靠球黏住與 HUD 辨識） |
    | 同時有槍與吸附 | 左端、右端用槍版，中段用吸附版（吸附版已與正常版相同（2026-10-26 使用者要求移除綠色），所以實際外觀就是槍端加正常中段；如使用者要不同組合，請通知 PM） |
    | 被擊中（1 幀） | 對「組好的整條擋板」套用：除 `K` 與 `.` 以外的像素全部改成 `W`（與 D12 同規則） |
    | 隱形 | 由程式調整透明度，不畫圖 |

    取捨說明：
    - 吸附：2026-10-26 使用者要求移除綠色，吸附版外觀與正常版相同（網格 id 與尺寸保留，供轉檔工具使用）；吸附狀態靠球黏住與 HUD 辨識
    - 槍只改兩端：砲管往上突出 4 px（頂端黃色閃光、管身左亮右暗、底部一圈金屬環），因為使用者要求「最左、最右邊可以發射雷射」，砲口位置即雷射發射點；本體端帽小燈改黃色（表示彈藥就緒）
    - 第 2 版調整（依 PM 看圖）：1. 拿掉每 8 欄一條的接縫，避免長擋板像履帶；中段圖塊改寬 16，只有一顆鉚釘、兩小段刮痕，細節稀疏而不連成帶狀 2. 左端上緣加 3 px 白色高光（與磚塊一致） 3. 炮管改為有結構的深色管

    正常左端（id: paddle_normal_left）：
    ```text
    .KKKKKKK
    KiWWWiii
    Kieeeeee
    Kifwwfff
    Kifxxfff
    Kggggggg
    Kjjjjjjj
    .KKKKKKK
    ```

    正常中段（id: paddle_normal_mid）：
    ```text
    KKKKKKKKKKKKKKKK
    iiiiiiiiiiiiiiii
    eeeeeeeeeeeeeeee
    fffffffieffeefff
    ffggfffgjfffffff
    gggggggggggggggg
    jjjjjjjjjjjjjjjj
    KKKKKKKKKKKKKKKK
    ```

    正常右端（id: paddle_normal_right）：
    ```text
    KKKKKKK.
    iiiiiieK
    eeeeeefK
    fffwwfgK
    fffxxfgK
    ggggggjK
    jjjjjjjK
    KKKKKKK.
    ```

    槍左端（id: paddle_gun_left）：
    ```text
    ..KAAK..
    ..KifK..
    ..KefK..
    .KeeggK.
    .KKKKKKK
    KiWWWiii
    Kieeeeee
    KifAAfff
    KifYYfff
    Kggggggg
    Kjjjjjjj
    .KKKKKKK
    ```

    槍右端（id: paddle_gun_right）：
    ```text
    ..KAAK..
    ..KifK..
    ..KefK..
    .KeeggK.
    KKKKKKK.
    iiiiiieK
    eeeeeefK
    fffAAfgK
    fffYYfgK
    ggggggjK
    jjjjjjjK
    KKKKKKK.
    ```

    吸附左端（id: paddle_sticky_left）：
    ```text
    .KKKKKKK
    KiWWWiii
    Kieeeeee
    Kifwwfff
    Kifxxfff
    Kggggggg
    Kjjjjjjj
    .KKKKKKK
    ```

    吸附中段（id: paddle_sticky_mid）：
    ```text
    KKKKKKKKKKKKKKKK
    iiiiiiiiiiiiiiii
    eeeeeeeeeeeeeeee
    fffffffieffeefff
    ffggfffgjfffffff
    gggggggggggggggg
    jjjjjjjjjjjjjjjj
    KKKKKKKKKKKKKKKK
    ```

    吸附右端（id: paddle_sticky_right）：
    ```text
    KKKKKKK.
    iiiiiieK
    eeeeeefK
    fffwwfgK
    fffxxfgK
    ggggggjK
    jjjjjjjK
    KKKKKKK.
    ```

    正常完整 64（id: paddle_normal_64）：
    ```text
    .KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK.
    KiWWWiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiieK
    KieeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeefK
    KifwwffffffffffieffeeffffffffffieffeeffffffffffieffeeffffffwwfgK
    KifxxfffffggfffgjfffffffffggfffgjfffffffffggfffgjffffffffffxxfgK
    KgggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggjK
    KjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjK
    .KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK.
    ```

    槍完整 64（id: paddle_gun_64）：
    ```text
    ..KAAK....................................................KAAK..
    ..KifK....................................................KifK..
    ..KefK....................................................KefK..
    .KeeggK..................................................KeeggK.
    .KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK.
    KiWWWiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiieK
    KieeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeefK
    KifAAffffffffffieffeeffffffffffieffeeffffffffffieffeeffffffAAfgK
    KifYYfffffggfffgjfffffffffggfffgjfffffffffggfffgjffffffffffYYfgK
    KgggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggjK
    KjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjK
    .KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK.
    ```

    吸附完整 64（id: paddle_sticky_64）：
    ```text
    .KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK.
    KiWWWiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiieK
    KieeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeefK
    KifwwffffffffffieffeeffffffffffieffeeffffffffffieffeeffffffwwfgK
    KifxxfffffggfffgjfffffffffggfffgjfffffffffggfffgjffffffffffxxfgK
    KgggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggjK
    KjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjK
    .KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK.
    ```

14. [D14] 不可破壞磚塊（使用者已確認，2026-10-26）：
    - 規格（README）：被球碰觸後不會消失，用來阻擋玩家攻擊；雷射磚塊的雷射與擋板槍的雷射都會被它擋下；閃電不能打它；彩虹磚不會挑到它，它不在彩虹七色內；減益道具「無敵」會讓所有磚塊（魔王除外）變成不可破壞，持續 5 秒，結束後恢復原本層數
    - 尺寸：32×16（一般磚格）；風格、光源、描邊沿用 D01、D02
    - 欄、列編號一律從 0 起算
    - 設計：深色槍金屬（gunmetal）厚鋼板：十字鋼條加黃銅螺栓，四個象限有斜紋防滑紋；與擋板（水平鋼板加青色小燈）、寶箱（橙木加鋼灰柱）一眼可分
    - 它不會被破壞，所以沒有破壞動畫
    - 新增顏色：`s`（深槍金屬面）、`y`（槍金屬紋亮部），標「D14 不可破壞磚塊用」，見 D01；其餘用既有鋼灰、黃（黃銅）色階
    - 被擊中：不用閃白；中央螺栓與上緣亮邊一閃，四個方向射出火花（`A`、`W`）
    - 「無敵」狀態（5 秒）採用做法 A：疊加 `invincible_a_overlay`，原磚顏色與數字可見；七色與 14 層共用同一張疊加層（使用者已決定）；另附一般磚（紅）與多層磚（藍 7）套用後的範例
    - 5 秒結束後移除疊加層，恢復原磚

    無敵規則（工具依這些規則產生）：

    | 項目 | 規則 |
    |---|---|
    | 無敵疊加方式（做法 A） | 疊加層的非 `.` 像素覆蓋原磚的對應像素，`.` 的位置不變；兩張同為 32×16，逐像素對齊；疊加層只畫外框（上下各 3 列、左右各 3 欄）與四角黃銅鉚釘，中間（第 3~28 欄、第 3~12 列）全為 `.` |
    | 被擊中 | 球碰到不可破壞磚時，播放「被擊中」圖 1 幀，再回到正常圖（不使用 D12 的閃白規則；「無敵」狀態下的磚被擊中時，仍播各自原本的被擊中圖即可，不另畫） |
    | 無敵與魔王 | 魔王不受「無敵」影響，不套用疊加 |

    不可破壞磚塊正常（id: unbreakable_normal）：
    ```text
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    KiiiWWWWiiiiiiiiiiiiiiiiiiiiieyK
    KeeeeeeeeeeeeeeeeeeeeeeeeeeeeygK
    KiessysssysssyeffgsssysssysssgjK
    KiesysssysssyseffgssysssysssygjK
    KieysssysssysseffgsysssysssysgjK
    KieeeeeeeeeeeeABBYeeeeeeeeeeegjK
    KiefffffffffffBYYCfffffffffffgjK
    KiegggggggggggYCCDggggggggggggjK
    KieysssysssysseffgsysssysssysgjK
    KiesssysssyssseffgysssysssyssgjK
    KiessysssysssyeffgsssysssysssgjK
    KiesysssysssyseffgssysssysssygjK
    KeygggggggggggggggggggggggggggjK
    KygjjjjjjjjjjjjjjjjjjjjjjjjjjjjK
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    ```
    不可破壞磚塊被擊中（id: unbreakable_hit）：
    ```text
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    KWWWWWWWWWWWWWWWWWWWWWWWWWWWWeyK
    KeeeeeeeeeeeeeeeeeeeeeeeeeeeeygK
    KiessysssyAssyeffgsssAsssysssgjK
    KiesysssyssWyseffgssWsssysssygjK
    KieysssysssyAseffgsAsssysssysgjK
    KieeeeeeeeeeeeAWWAeeeeeeeeeeegjK
    KiefffffffffffWWWWfffffffffffgjK
    KiegggggggggggAWWAggggggggggggjK
    KieysssysssysseffgsysssysssysgjK
    KiesssysssysAseffgyAssysssyssgjK
    KiessysssysWsyeffgssWysssysssgjK
    KiesysssysAsyseffgssyAssysssygjK
    KeygggggggggggggggggggggggggggjK
    KygjjjjjjjjjjjjjjjjjjjjjjjjjjjjK
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    ```

    疊加層：金屬外框（id: invincible_a_overlay）：
    ```text
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    KBYeeeeeeeeeeeeeeeeeeeeeeeeeeBYK
    KYCffffffffffffffffffffffffffYCK
    Kef..........................gjK
    Kef..........................gjK
    Kef..........................gjK
    Kef..........................gjK
    Kef..........................gjK
    Kef..........................gjK
    Kef..........................gjK
    Kef..........................gjK
    Kef..........................gjK
    Kef..........................gjK
    KBYggggggggggggggggggggggggggBYK
    KYCjjjjjjjjjjjjjjjjjjjjjjjjjjYCK
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    ```

    無敵做法 A：一般磚（紅）（id: invincible_a_red）：
    ```text
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    KBYeeeeeeeeeeeeeeeeeeeeeeeeeeBYK
    KYCffffffffffffffffffffffffffYCK
    KefRRRRRRRRRRRRttRRRRRRRRRRoRgjK
    KefRtttRRRRRRRRRRRRRRRtttRRoRgjK
    KefRRrrRRRRRRRRRRRRRRRRrrRoRRgjK
    KefRRRRRRRRRRRRRRRRRRRRRRRoRRgjK
    KefRRRRRRRRRRRRRRRRRRRRRRoRRRgjK
    KefRRRtttRRRRRRRRRRRRRRRtttRRgjK
    KefRRRRrrRRRRRRRRRRRRRRRRrrRRgjK
    KefRRRRRRRRRRRRRRRRRRRRRRRRRRgjK
    KeftttRRRRRRRRRRRRRRRtttRRRRRgjK
    KefRrrRRRRRRRRRRrrRRRRrrRRRRRgjK
    KBYggggggggggggggggggggggggggBYK
    KYCjjjjjjjjjjjjjjjjjjjjjjjjjjYCK
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    ```

    無敵做法 A：多層磚（藍 7）（id: invincible_a_blue7）：
    ```text
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    KBYeeeeeeeeeeeeeeeeeeeeeeeeeeBYK
    KYCffffffffffffffffffffffffffYCK
    KefUUUUUUUUUUUUPPUUUUUUUUUUUUgjK
    KefUPPPUUUUUUKKKKKUUUUPPPUUUUgjK
    KefUUNNUUUUUUUUUUKUUUUUNNUUUUgjK
    KefUUUUUUUUUUUUUKUUUUUUUUUUUUgjK
    KefUUUUUUUUUUUUKUUUUUUUUUUUUUgjK
    KefUUUPPPUUUUUUKUUUUUUUUPPPUUgjK
    KefUUUUNNUUUUUUKUUUUUUUUUNNUUgjK
    KefUUUUUUUUUUUUKUUUUUUUUUUUUUgjK
    KefPPPUUUUUUUUUUUUUUUPPPUUUUUgjK
    KefUNNUUUUUUUUUUNNUUUUNNUUUUUgjK
    KBYggggggggggggggggggggggggggBYK
    KYCjjjjjjjjjjjjjjjjjjjjjjjjjjYCK
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    ```

15. [D15] 球（使用者已確認）：
    - 規格（README）：球 8×8、速度 240 px/s、**碰撞為圓形（直徑 8、半徑 4，圓心在本體中心）**；同時可能 50 顆以上
    - 狀態：正常、穿透（5 秒；附魔可整局）、火焰（5 秒；附魔可整局）、炸彈（5 秒）、強化（每次減層 +1，最多 +7，整局）、fever（球 50 顆以上，低於 50 解除）；狀態可同時存在
    - 風格沿用 D01、D02：1 px `K` 描邊、左上光源、不用抖色、漸層、隨機點
    - 欄、列編號一律從 0 起算
    - 顏色：珍珠白 `1`~`4`（T1 沿用 `W`）標「D15 用」，已加入 D01；品紅 `5`、`6` 原為已刪除的外圍記號方案所用，D01 保留，目前由 D17 雷射磚使用（D16 強化已改 ATK 字樣，不再使用）；色數統計為 58 色

    設計重點（取捨）：
    - **白色核心 = 這是球**：七色磚、鋼灰擋板、深灰藍不可破壞磚都沒有「近中性的珍珠白」；本體永遠是珍珠白，**不換色**（本體換成橙或紅會和七色玩法資訊混淆）
    - **球的狀態不畫在球身上**：所有狀態共用同一種光暈（方案 C），是哪一種狀態改看 D16 的 HUD 圖示
    - **不畫拖尾、不畫被擊中幀**：球會一直碰撞，閃白會一直閃；拖尾在 50 顆球時會糊成一片
    - 8×8 本體太小（內部只有 6×6），斜面簡化為「左上 1 px 亮、右下 1 px 暗」，不做 D02 的 2 px 斜面，否則看不出球形

    球本體圖：8×8（`ball_normal`），不換色；碰撞固定為圓形、直徑 8、圓心在本體中心；欄、列從 0 起算。

    炸彈磚塊標記疊加圖（使用者已確認：`bomb_mark_overlay`、`bomb_mark_overlay_f2`、`bomb_mark_circle_overlay`、`bomb_mark_circle_overlay_f2`、`bomb_mark_boss_overlay`、`bomb_mark_boss_overlay_f2`（放大版魔王標記，見下方「魔王（128×48）」））：
    - 做法沿用 D14 `invincible_a_overlay`：疊加層的非 `.` 像素覆蓋原磚的對應像素，`.` 不變；逐像素對齊
    - 使用者回饋（第 2 版）：只放一顆炸彈、在磚塊右上角、整顆不超出磚塊；炸彈要有跳動動畫（2 幀）；被標記的磚不顯示層數數字
    - 造型：深色橫長方形炸彈（寬 10、高 5 的本體），1 px `K` 描邊（D02），本體用鋼灰 `f g j v`、左上 1 px 白色高光 `W`（左側白色高光點），右上有灰色引信 `G`、頂端黃色火花 `Y` `W`（十字）；不新增顏色
    - 材質感：本體由左上到右下依序 `f` → `g` → `j` → `v`，上亮下暗（光源在左上，D02）；高光點在左上角；引信為 2 格斜線接到本體上緣
    - **位置（32×16 磚，欄、列從 0 起算）**：整顆在第 20~29 欄；第 1 幀（高 9）在第 4~12 列、第 2 幀（高 11）在第 2~12 列；兩幀的底部（最後一列）都在第 12 列，**整顆（含引信與火花）都在 32×16 範圍內**，不蓋到磚的最外圈描邊（第 0、31 欄，第 0、15 列）
    - 跳動動畫（2 幀）：

    | 幀 | 圖 id | 內容 | 尺寸 | 幀時間 |
    |---|---|---|---|---|
    | F1 | `bomb_mark_overlay` | 正常：本體 10 欄寬 × 5 列高，加引信火花共高 9 列 | 10×9 | 300 ms |
    | F2 | `bomb_mark_overlay_f2` | 高一點、窄一點：本體 8 欄寬 × 7 列高（左右各縮 1 欄、上方加高 2 列），加引信火花共高 11 列 | 8~10 欄寬 × 11 | 200 ms |
    | 合計 | - | F1、F2 輪流播放，一輪 500 ms | - | - |

    - **兩幀底部對齊**：F1、F2 的最後一列都在第 12 列（圓形磚版在第 10 列），F2 只往上長高 2 列、左右各縮 1 欄（中心不動），看起來是在原地跳、不會左右飄
    - 火花與引信：兩幀火花在相同的欄（第 27~29 欄）；F2 的引信只剩 1 格（被拉長的本體佔了列），不影響辨識
    - 所有炸彈共用同一個時鐘（同一個相位），多顆炸彈同時跳動不會亂；玩家開啟系統「減少動態」時固定顯示 F1
    - 被標記期間，標記**一直顯示**，直到炸彈效果結束、磚塊爆炸為止
    - **被標記的磚不顯示層數數字**（使用者決定）：多層磚被標記期間，底圖改用「沒有數字的版本」，標記移除前都不顯示數字；**需程式支援**，見「需工具支援」；所以炸彈**不需要閃避數字預留區**，標記可直接蓋在磚面上
    - **圓形磚（16×16）需要另一組**（`bomb_mark_circle_overlay`、`bomb_mark_circle_overlay_f2`）：圓形磚在 32×16 格內置中（第 8~23 欄），32×16 的標記放在右上角（第 20~29 欄）會浮在圓形磚外面；圓形版也放在 16×16 的右上，第 6~15 欄；第 1 幀在第 2~10 列、第 2 幀在第 0~10 列，兩幀底部都在第 10 列，整顆都在 16×16 範圍內
    - **圓形磚的炸彈放圓內還是透明角（我的判斷）**：本體放在圓內（右上偏下），引信與火花伸進右上透明角
      - 理由：圓形的右上透明角只有約 3×3，放不下 10 欄寬的本體；本體壓在透明角上會看起來像浮在磚外
      - 本體放在圓內（第 6~15 欄、第 6~10 列，圓在這幾列剛好滿寬），邊緣與圓的邊緣貼齊；引信與火花細，伸進透明角，仍在 16×16 內，讀起來是「掛在圓的右上」
      - 取捨：炸彈本體會蓋住圓形磚約 10×5 的面積，圓形磚的紫色紋理被擋一部分
    - **哪些磚會被標記（README 已更新）**：可被標記的是一般磚、多層磚、寶箱、金幣、圓形磚、魔王；**不可破壞磚不會被標記**，所以不畫它的標記圖；炸彈效果結束時，被標記的磚爆炸，魔王則扣 10 層
    - **魔王（128×48）需要另一組**（`bomb_mark_boss_overlay`＝第 1 幀、`bomb_mark_boss_overlay_f2`＝第 2 幀），128×48，疊在魔王上；同樣只放一顆炸彈在右上角，整顆不超出魔王邊界；F2 高一點、窄一點；兩幀底部對齊；幀時間與一般磚相同（F1 300 ms、F2 200 ms）
    - **炸彈大小（使用者要求比一般磚的炸彈大一點，約 1.5 倍；2 幀跳動照做）**
      - 第 1 幀（正常）：本體 15 欄寬 × 8 列高，連引信與火花共 15 欄寬 × 12 列高（一般磚版為本體 10×5、共 10×9）
      - 第 2 幀（高一點、窄一點）：本體 13 欄寬 × 10 列高（左右各縮 1 欄、上下加高 2 列），連引信與火花共 15 欄寬 × 14 列高；兩幀的中心欄相同（第 116 欄）
      - 造型與一般磚的炸彈一致（同樣的鋼灰 `f g j v`、左上白色高光 `W`、灰引信 `G`、黃色火花 `Y` `W`），放大後補上的細節：火花由十字擴成 3×3（四角加淺黃 `A`）、本體高光改為 2 格、右側加深 `v` 變寬、四個角削成圓角（上下各 2 列）；不新增顏色
      - 沒有再放大的理由：再大會蓋到右眼，違反「不蓋住臉」；魔王右眉毛以上只有第 1~12 列
    - **位置（魔王 128×48，欄、列從 0 起算）**：整顆在第 109~123 欄；第 1 幀在第 3~14 列、第 2 幀在第 1~14 列；兩幀的底部（最後一列）都在第 14 列（底部對齊，看起來是在原地跳）；整顆含引信與火花都在魔王範圍內，不蓋到最外圈描邊（第 0、127 欄，第 0 列），第 124 欄留 1 欄空白，離右側斜面（第 125~126 欄）2 欄
    - **蓋到魔王的範圍**：只蓋到右眉毛的一部分，沒有蓋到眼睛和嘴
      - 右眉毛最右一段在第 13~15 列、第 105~118 欄；炸彈的底部最多蓋到第 13~14 列、第 110~118 欄（第 1 幀蓋第 13 列的第 110~118 欄與第 14 列的第 111~118 欄；第 2 幀蓋第 13 列的第 111~118 欄與第 14 列的第 112~118 欄）
      - 第 15 列的眉毛與第 105~109 欄的眉毛都沒被蓋到；右眼從第 22 列起，離炸彈底部（第 14 列）還有 7 列，嘴在第 30 列之後更遠
      - 炸彈有 `K` 描邊，蓋在眉毛上時輪廓仍清楚；標記移除後眉毛完整恢復

    消失動畫（黑洞、死神磚、落底共用 1 組 4 幀；`ball_vanish_f1`~`f4` 使用者已確認）：
    - 14×14，圖的中心 = 球的圓心；沒有顏色（白、灰），三種來源都適用
    - 流程：球縮小（6×6）→ 再縮小（4×4）加 4 點火花 → 縮成白點、火花往外 → 灰塵散去

    | 幀 | 圖 id | 內容 | 建議時間 |
    |---|---|---|---|
    | F1 | `ball_vanish_f1` | 球縮成 6×6 | 60 ms |
    | F2 | `ball_vanish_f2` | 球縮成 4×4，四個斜角各 1 點白火花 | 60 ms |
    | F3 | `ball_vanish_f3` | 2×2 白核心，上下左右各 2 px 灰火花 | 60 ms |
    | F4 | `ball_vanish_f4` | 四個角落各 1 點灰塵 | 60 ms |
    | 合計 | - | 全程 240 ms | 與 D12 小磚破壞幀（60 ms）一致；50 顆球同時消失也不會拖慢節奏 |

    不畫（使用者指定）：
    - 被擊中幀：球一直碰撞，閃白會一直閃
    - 拖尾

    需工具支援（規則寫死在轉檔工具；要修改請通知 PM，由工程師改工具）：
    - 炸彈標記疊加：把 `bomb_mark_overlay`（第 1 幀）與 `bomb_mark_overlay_f2`（第 2 幀）疊在 32×16 的可破壞磚（一般磚七色、多層磚各層、寶箱、金幣）上；`bomb_mark_circle_overlay` 與 `bomb_mark_circle_overlay_f2` 疊在圓形磚上；`bomb_mark_boss_overlay` 與 `bomb_mark_boss_overlay_f2`（128×48）疊在魔王上；疊加規則同 D14，兩幀由程式輪流切換（F1 300 ms、F2 200 ms）；不可破壞磚不疊
    - **需程式支援：被標記的多層磚改用同顏色、第 0 輪（無數字）的圖**，保留母版裂痕（使用者決定不另產無裂痕版）；不需要另外產圖；層數仍由磚的資料記錄

    已知限制（8×8 下看不清楚的組合，如實寫出）：

    | 組合 | 問題 | 緩解 |
    |---|---|---|
    | 炸彈標記的引信、火花在黃磚上 | 灰與淺黃對比低 | 炸彈本體有 `K` 描邊，輪廓仍可辨認 |
    | 本體在黃磚上 | 珍珠白 T3 與黃磚亮度相近（210 對 209，色相不同） | 靠 K 描邊分開 |
    | 本體與擋板 | 珍珠白與鋼灰亮度接近 | 球是圓形、有 K 描邊，擋板是長條；接觸只有短暫瞬間 |
    | 顏色未實測 | 對比數字為手算近似值，背景色以盤面截圖估計 | 請 QA 或使用者在實機複核；色盲未用模擬器驗證 |

    對比（近似）：
    - 珍珠白主色（`2`）對深色背景（估計約 #0F0F1E，依盤面截圖判斷，未量測）約 12:1
    - `K` 描邊對藍磚（`U`）約 4.8:1（同 D01）、對黃磚（`Y`）約 12:1；本體（`2`）對 `K` 約 11:1
    - 本體與磚的區分主要靠描邊，不是靠本體與磚的明度差

    給工程師的需求：
    - 不需要新的後端資料或 API
    - 繪製順序：所有球的光暈在下、所有球本體在上（見方案 C 的「光暈規則」）
    - 光暈顯示條件（HUD 有任何一格在顯示）、消失動畫播放與光暈隱藏、炸彈標記兩幀輪播，由遊戲程式處理

    正常球（id: ball_normal）：
    ```text
    ..KKKK..
    .KWW12K.
    KW12223K
    K122233K
    K222334K
    K223344K
    .K3344K.
    ..KKKK..
    ```

    消失 F1（id: ball_vanish_f1）：
    ```text
    ..............
    ..............
    ..............
    ..............
    .....KKKK.....
    ....KW122K....
    ....K1223K....
    ....K2233K....
    ....K2334K....
    .....KKKK.....
    ..............
    ..............
    ..............
    ..............
    ```

    消失 F2（id: ball_vanish_f2）：
    ```text
    ..............
    ..............
    ..............
    ...W......W...
    ..............
    ......KK......
    .....KW1K.....
    .....K23K.....
    ......KK......
    ..............
    ...W......W...
    ..............
    ..............
    ..............
    ```

    消失 F3（id: ball_vanish_f3）：
    ```text
    ..............
    ..............
    ......GG......
    ..............
    ..............
    ..............
    ..G...WW...G..
    ..G...WW...G..
    ..............
    ..............
    ..............
    ......GG......
    ..............
    ..............
    ```

    消失 F4（id: ball_vanish_f4）：
    ```text
    ..............
    ..............
    ..G........G..
    ..............
    ..............
    ..............
    ..............
    ..............
    ..............
    ..............
    ..............
    ..G........G..
    ..............
    ..............
    ```

    炸彈標記疊加層：32×16 磚，第 1 幀（正常；原 id 即第 1 幀）（id: bomb_mark_overlay）：
    ```text
    ................................
    ................................
    ................................
    ................................
    ............................Y...
    ...........................YWY..
    ...........................GY...
    ..........................G.....
    .....................KKKKKKKK...
    ....................KWfggggjjK..
    ....................KfgggggjvK..
    ....................KggggjjvvK..
    .....................KKKKKKKK...
    ................................
    ................................
    ................................
    ```

    炸彈標記疊加層：32×16 磚，第 2 幀（高一點、窄一點）（id: bomb_mark_overlay_f2）：
    ```text
    ................................
    ................................
    ............................Y...
    ...........................YWY..
    ...........................GY...
    ..........................G.....
    ......................KKKKKK....
    .....................KWfgggjK...
    .....................KfggggjK...
    .....................KggggjjK...
    .....................KgggjjvK...
    .....................KggjjvvK...
    ......................KKKKKK....
    ................................
    ................................
    ................................
    ```

    炸彈標記疊加層：圓形磚 16×16，第 1 幀（正常；原 id 即第 1 幀）（id: bomb_mark_circle_overlay）：
    ```text
    ................
    ................
    ..............Y.
    .............YWY
    .............GY.
    ............G...
    .......KKKKKKKK.
    ......KWfggggjjK
    ......KfgggggjvK
    ......KggggjjvvK
    .......KKKKKKKK.
    ................
    ................
    ................
    ................
    ................
    ```

    炸彈標記疊加層：圓形磚 16×16，第 2 幀（高一點、窄一點）（id: bomb_mark_circle_overlay_f2）：
    ```text
    ..............Y.
    .............YWY
    .............GY.
    ............G...
    ........KKKKKK..
    .......KWfgggjK.
    .......KfggggjK.
    .......KggggjjK.
    .......KgggjjvK.
    .......KggjjvvK.
    ........KKKKKK..
    ................
    ................
    ................
    ................
    ................
    ```

    炸彈標記疊加層：魔王 128×48，第 1 幀（正常）（id: bomb_mark_boss_overlay）：
    ```text
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ........................................................................................................................AYA.....
    ........................................................................................................................YWY.....
    ........................................................................................................................GYA.....
    .......................................................................................................................G........
    ...............................................................................................................KKKKKKKKKKK......
    ..............................................................................................................KWWffggggjjjK.....
    .............................................................................................................KWfffgggggjjjvK....
    .............................................................................................................KffgggggggjjjvK....
    .............................................................................................................KfgggggggjjjvvK....
    .............................................................................................................KgggggggjjjvvvK....
    ..............................................................................................................KggggggjjjvvK.....
    ...............................................................................................................KKKKKKKKKKK......
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ```

    炸彈標記疊加層：魔王 128×48，第 2 幀（高一點、窄一點）（id: bomb_mark_boss_overlay_f2）：
    ```text
    ................................................................................................................................
    ........................................................................................................................AYA.....
    ........................................................................................................................YWY.....
    ........................................................................................................................GYA.....
    .......................................................................................................................G........
    ................................................................................................................KKKKKKKKK.......
    ...............................................................................................................KWWfggggjjK......
    ..............................................................................................................KWfffgggggjjK.....
    ..............................................................................................................KffggggggjjvK.....
    ..............................................................................................................KfggggggjjvvK.....
    ..............................................................................................................KggggggjjjvvK.....
    ..............................................................................................................KgggggjjjvvvK.....
    ..............................................................................................................KggggjjjvvvvK.....
    ...............................................................................................................KgggjjjvvvK......
    ................................................................................................................KKKKKKKKK.......
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ```

    方案 C：單一光暈（使用者已確認；本小節屬 D15）：
    - 使用者決定：球本體維持 `ball_normal`（8×8，不換色）；只要 D16 的 HUD 上有任何一格在顯示（穿透、火焰、炸彈、強化、fever、減速、加速，含付費「附魔」），就顯示**同一種**光暈，所有狀態共用、不區分；是哪一種狀態改看 D16 的 HUD 圖示
    - 搭配使用：`ball_normal`、`ball_vanish_f1`~`f4`、炸彈標記（見「炸彈磚塊標記疊加圖」）
    - 新增顏色：無（光暈只用 D01 既有的 `w`、`x`、`K`；色數仍為 58 色）

    光暈規則：

    | 項目 | 規則 |
    |---|---|
    | 顯示條件（使用者決定） | **只要 D16 的 HUD 上有任何一格在顯示，球就顯示光暈**（涵蓋穿透、火焰、炸彈、強化、fever、減速、加速，含付費「附魔」）；HUD 上所有格都消失時，光暈移除 |
    | 圖的尺寸 | 14×14，本體 8×8 置中（本體在第 3~10 欄、第 3~10 列）；圖中心 = 球的圓心 |
    | 碰撞 | 固定 8×8（圓形、直徑 8）；光暈不參與碰撞 |
    | 構造 | 兩圈：內圈（距本體 1 px，24 格）為青色亮環；外圈（距本體 2 px，28 格）為 `K` 深色環；亮環與本體之間隔著本體自己的 `K` 描邊 |
    | 動態（呼吸，2 幀） | F1 內圈用 `w`（亮青）、F2 內圈用 `x`（中青）；外圈兩幀都是 `K`；F1、F2 各 400 ms，循環一輪 800 ms |
    | 同步 | 全部球共用同一個時鐘、同一個相位，不是各球自己計時；50 顆球同時呼吸，不會變成亂閃 |
    | 減少動態 | 玩家若開啟系統的「減少動態」，固定顯示 F1 |
    | 繪製順序（由下到上） | 磚塊、擋板 → **所有球的光暈** → **所有球的本體**；50 顆球擠在一起時，白色本體不會被別顆球的光暈蓋住 |
    | 球消失時 | 光暈立刻隱藏，只播消失動畫（`ball_vanish_f1`~`f4`） |
    | fever 時 | 球 50 顆以上 = 每顆球都有光暈，光暈此時不再區分單顆球；這是方案 C「所有狀態共用」的結果 |
    | 炸彈標記 | 標記在磚上，與光暈無關，照 `bomb_mark_overlay`、`bomb_mark_overlay_f2`、`bomb_mark_circle_overlay`、`bomb_mark_circle_overlay_f2`（2 幀跳動） |

    為什麼用青色加深色外環（兩圈各負責一種背景）：
    - 亮的磚和擋板（黃、淺藍、淺綠、鋼灰）上，青色內圈亮度接近，靠 `K` 外環分出輪廓
    - 暗的磚（靛、紫、深灰藍不可破壞磚）和深色背景上，`K` 外環看不見，靠青色內圈
    - 兩圈各管一種背景，任何背景上至少有一圈對比 ≥ 約 2.7:1（見下表）

    對比（近似，手算；背景色以盤面截圖估計，未量測）：

    | 背景 | 青內圈 `w`／`x` 對背景 | `K` 外環對背景 | 結論 |
    |---|---|---|---|
    | 深色背景（約 #0F0F1E） | 約 14:1／約 8:1 | 約 1.1:1（看不見） | 看得清楚（靠青環） |
    | 黃磚（`Y`） | 約 1.1:1（亮度相同、色相不同） | 約 12:1 | 看得清楚（靠 `K` 環） |
    | 橙磚（`d`） | 約 2.2:1 | 約 5.8:1 | 看得清楚 |
    | 紅磚、紫磚（`R`、`V`） | 約 4.2:1 | 約 3.0:1 | 看得清楚 |
    | 藍磚（`U`） | 約 2.7:1 | 約 4.8:1 | 看得清楚 |
    | 淺藍磚（`M`、`N`）、淺綠磚（`L`、`F`） | 約 1.2:1 | 約 10:1 | 靠 `K` 環；青環幾乎看不見 |
    | 靛磚（`I`） | 約 7:1 | 約 1.8:1 | 靠青環 |
    | 不可破壞磚（`s`） | 約 6.8:1 | 約 1.9:1 | 靠青環 |
    | 鋼灰擋板（`i`、`e`） | 約 1.2:1 | 約 10:1 | 靠 `K` 環；青環幾乎看不見 |

    青色與七色的關係：
    - 青色相約 190 度，在綠（約 100 度）與藍（約 216 度）之間；不是七色任一色，但**最接近藍**
    - 不會被誤認為藍磚的原因：光暈是 1 px 的環，不是一塊面；磚是矩形或紫色圓，光暈環繞白色圓球；青環外側一定有 `K` 外環；青色在盤面上不單獨存在
    - 這是風險不是保證；實機若覺得和藍磚像，替代方案是改成純白環（無色相、不可能被誤認為七色之一，但和珍珠白本體較接近）；使用者已確認採用青色光暈，此替代方案不採用

    已知限制：
    - 50 顆以上密集時，每顆的光暈外圈 `K` 會蓋住鄰球的青環一部分；若實機覺得太糊，可把光暈拆成「外環」「亮環」兩張，先畫全部外環、再畫全部亮環、最後畫本體（要另畫兩張圖）；現在不拆，待實機確認
    - 光暈不分狀態：玩家看不出是穿透還是火焰，要看 D16 的 HUD
    - 呼吸幀只差內圈亮度（`w` 對 `x`），在淺色背景上差異不明顯
    - 光暈 14×14 比本體大，球靠近磚塊時，光暈會蓋住磚塊邊緣 2 px

    需工具支援：無（光暈是 1 張圖加 2 幀，由程式依顯示條件疊在本體之下）；是否預先烘焙成「本體加光暈」由工程師決定，只有 2 種（無光暈、有光暈 F1／F2）

    光暈 F1（id: ball_opt_c_halo_f1）：
    ```text
    ..............
    .....KKKK.....
    ....KwwwwK....
    ...Kw....wK...
    ..Kw......wK..
    .Kw........wK.
    .Kw........wK.
    .Kw........wK.
    .Kw........wK.
    ..Kw......wK..
    ...Kw....wK...
    ....KwwwwK....
    .....KKKK.....
    ..............
    ```

    光暈 F2（id: ball_opt_c_halo_f2）：
    ```text
    ..............
    .....KKKK.....
    ....KxxxxK....
    ...Kx....xK...
    ..Kx......xK..
    .Kx........xK.
    .Kx........xK.
    .Kx........xK.
    .Kx........xK.
    ..Kx......xK..
    ...Kx....xK...
    ....KxxxxK....
    .....KKKK.....
    ..............
    ```

    光暈加本體合成範例（F1）（id: ball_opt_c_example）：
    ```text
    ..............
    .....KKKK.....
    ....KwwwwK....
    ...KwKKKKwK...
    ..KwKWW12KwK..
    .KwKW12223KwK.
    .KwK122233KwK.
    .KwK222334KwK.
    .KwK223344KwK.
    ..KwK3344KwK..
    ...KwKKKKwK...
    ....KwwwwK....
    .....KKKK.....
    ..............
    ```

16. [D16] HUD 球狀態圖示（使用者已確認）：
    - 使用者決定：球身上只有一種共用光暈（D15 方案 C），所以「是哪種狀態」「剩多久」「強化幾級」改由 HUD 圖示告知
    - 位置已由 D28 取代（使用者 2026-10-26 已確認）：HUD 改為半透明 50% 懸浮在關卡區左下、垂直排列、整數 2 倍放大（每格 44×44）、有狀態往上補位（改寫下方「固定格位、不補位」，只限新位置）；格內結構、排列順序、圖示與線段條外觀不變
    - 範圍：只做 5 種狀態圖示、圖示下方的線段條與排列；時間、分數、魔王血量等其他 HUD 元素不在本次範圍
    - 風格沿用 D01、D02：1 px `K` 描邊、左上光源；新增顏色 2 色（淺灰 `7`、中灰 `8`，標「D16 用」，已加入 D01），色數統計為 60 色
    - 欄、列編號一律從 0 起算
    - 2026-10-26 使用者已確認 SP/ATK 文字畫法：減速/加速/強化改為文字畫法（`hud_icon_slow`、`hud_icon_fast`、`hud_icon_reinforce` 與 `hud_row_example` 對應位置已重畫；文字用 `W`，下方球用珍珠白）
    - 使用者回饋（第 2 版）：1. 5 個圖示要一樣大、都是正方形 2. 下方提示全部改為線段，不再用 +N 數字和 ∞ 記號，5 格的線段尺寸、位置、高度完全一致
    - **正方形的做法：統一的 16×16 底板加固定內容框**
      - 5 個圖示共用同一塊 16×16 的正方形底板：最外圈 1 px `K` 描邊；內側上緣、左緣 1 px `f`（亮邊），下緣、右緣 1 px `j`（暗邊），右上與左下轉角用 `g`；底板面用 `g`（左上光源，與 D02 一致）
      - 圖示內容全部畫在 12×12 的內容框內（底板的第 2~13 欄、第 2~13 列），內容的外形都**頂到內容框的四邊**，所以 5 個看起來一樣大；內容框外不再有突出物（上一版炸彈與 fever 的火花會突出，已改掉：炸彈的引信與火花收進框內，fever 取消火花）
      - 內容框內沒畫到的透明處，會露出底板面（網格中以 `g` 表示，不用 `.`）
    - 色盲照顧：穿透（箭穿橫板）、火焰（水滴）、炸彈（有引信的圓炸彈）、fever（三顆球成堆）外形各不相同；強化（ATK 字樣）、減速與加速（球加 SP）改為文字記號，靠字辨識，不靠顏色；**加速與減速只差右上的 +／−（1 px 筆畫），其餘完全相同**，色盲與小螢幕下較易混淆；顏色只是輔助
    - 圖示內容縮到 12×12 的代價：筆畫細節比上一版（16×16 內容）少，見「已知限制」

    各狀態圖示（16×16，底板加 12×12 內容）：

    | 狀態 | 圖示 | 外形記號 | 主要顏色（D01 代號） | 圖 id |
    |---|---|---|---|---|
    | 穿透 | 向上的箭穿過一塊橫板 | 箭頭加橫板，橫板頂到左右兩邊 | 青 `w` `x`、鋼灰 `e` `f` | `hud_icon_pierce` |
    | 火焰 | 火焰 | 水滴狀、頂端尖 | 橙 `a` `O` `d` `b`、黃 `A` `B`、紅 `R` `t` | `hud_icon_flame` |
    | 炸彈 | 圓炸彈加引信火花 | 圓形加右上引信（火花收進內容框） | 鋼灰 `f` `g` `j`、魔王最暗 `v`、引信 `G`、火花 `Y` `W` | `hud_icon_bomb` |
    | 強化 | 文字 ATK 加右上 +（使用者已確認 SP/ATK，2026-10-26） | 3×5 像素字，ATK 在 + 下方，無球 | 白 `W`（文字） | `hud_icon_reinforce` |
    | fever | 三顆球成堆 | 上 1 顆、下 2 顆緊貼 | 珍珠白 `W` `1`~`4` | `hud_icon_fever` |

    格子的組成（每個狀態一格，格寬 22、格高 22；第 3 版：線段加寬為 22 以放下 7 小段，圖示不變，在格內水平置中）：

    | 位置（格內，從 0 起算） | 內容 |
    |---|---|
    | 第 3~18 欄、第 0~15 列 | 狀態圖示（16×16 底板，不變）；左右各留 3 欄空白 |
    | 第 16~17 列 | 留白 2 列 |
    | 第 0~21 欄、第 18~21 列 | 線段條（22×4），5 格一律在同一位置、同一高度、同一寬度 |

    線段條的外框（5 格、所有狀態完全相同）：
    - 外形：22×4；外框 1 px `j`（上、下各 1 列，左、右各 1 欄）；內部 20×2；底色（空的部分）`v`
    - 5 格的線段條外框尺寸、高度、位置完全一致；只有「裡面怎麼填」不同，不會出現高低不均

    | 狀態 | 線段內容 |
    |---|---|
    | 5 秒狀態（穿透、火焰、炸彈；非附魔） | **連續**填色 `W`（不分段），依剩餘時間從右往左縮短 |
    | 付費「附魔」整局（穿透或火焰） | 連續填色 `W`，**維持全滿、不縮短**；圖示本體與 5 秒版相同 |
    | 強化（+1~+7） | **分段**：切成 7 小段，目前第 N 階就填滿前 N 段（各段顏色固定），其餘段顯示 `v`（見「分段通用規則」） |
    | fever | 連續填色 `W`，全滿；只要球數 50 以上就一直在，低於 50 圖示與線段一起消失 |

    分段通用規則（使用者更正：不整條換色，而是切成與階段數一樣多的小段）：
    - 段數 = 該狀態的階段數 N（強化 +1~+7 是 N = 7；以後有 5 階的狀態就是 N = 5）
    - 線段內部寬 20；段與段之間放 1 欄分隔，分隔色為外框色 `j`，所以段數數得出來；N 段共有 N − 1 個分隔
    - 每段寬度 w = 向下取整（(20 − (N − 1)) ÷ N）；剩下的欄數 r = 20 − (N − 1) − N × w，**由最左邊的 r 段各多 1 欄**
      - N = 7：w = 2，r = 0，七段各 2 欄，共 7×2 + 6 = 20 欄（本稿畫的就是這個）
      - N = 5：w = 3，r = 1，第 1 段 4 欄、其餘各 3 欄，共 4 + 4×3 + 4 = 20 欄
    - 位置（N = 7，欄從 0 起算，含外框）：外框第 0 欄；第 1 段第 1~2 欄；分隔第 3 欄；第 2 段第 4~5 欄；分隔第 6 欄；第 3 段第 7~8 欄；分隔第 9 欄；第 4 段第 10~11 欄；分隔第 12 欄；第 5 段第 13~14 欄；分隔第 15 欄；第 6 段第 16~17 欄；分隔第 18 欄；第 7 段第 19~20 欄；外框第 21 欄
    - 每段顏色固定，由左到右由白漸深：N = 7 時依序 `W`、`7`、`G`、`8`、`f`、`y`、`g`；N 不是 7 時，從這 7 種灰中取第 round((i − 1) × 6 ÷ (N − 1)) 種（i 為第幾段，從 1 起算，0.5 進位）：N = 5 依序為 `W`、`G`、`8`、`y`、`g`
    - 目前第 n 階：第 1~n 段填各自的顏色，第 n + 1~N 段填 `v`；n = 0 時整條不顯示（強化 0 階不顯示該格）
    - 例：+5 = 前 5 段 `W` `7` `G` `8` `f` 有色，後 2 段 `v`；第 N 段是最高階、最深的灰

    fever 為什麼用全滿白線段（使用者已確認可以；我的判斷是不需要不同表示）：fever 沒有倒數也沒有等級，只有「有或沒有」，全滿線段已經表達「持續中」；改用別種表示會破壞「5 格線段一致」的要求；它與附魔同為全滿白線，靠圖示分辨。

    強化的 7 段各自的顏色（一段一色；**白色 = 第 1 階（+1），深灰 = 最後一階（+7，最高級）**，由白漸深；階數看「有幾段有色」）：

    | 等級 | 代號 | HEX | 灰階亮度 Y |
    |---|---|---|---|
    | +1（最低） | `W` | #FFFFFF | 255 |
    | +2 | `7` | #DDE0EA | 224 |
    | +3 | `G` | #B8BCD0 | 189 |
    | +4 | `8` | #9EA4B6 | 164 |
    | +5 | `f` | #8A93A8 | 148 |
    | +6 | `y` | #6D7690 | 118 |
    | +7（最高） | `g` | #566077 | 95 |

    - 最深的 `g`（Y 95）與空底色 `v`（Y 33）對比約 2.7:1；每段之間還有 `j` 分隔，所以「第 7 段有色」與「第 7 段是空的」分得出來
    - 7 種灰的相鄰兩級（以相對亮度比估算，手算近似）：+1 對 +2 約 1.3:1、+2 對 +3 約 1.4:1、+3 對 +4 約 1.3:1、+4 對 +5 約 1.2:1、+5 對 +6 約 1.5:1、+6 對 +7 約 1.4:1
    - 分段後，階數主要靠「數有色段數」判讀，不再只靠顏色深淺，相鄰灰階難分的問題大幅減輕
    - 如實說明：每段只有 2×2 px（在 360 寬螢幕上放大約 3~4 倍，約 6~8 手機像素見方），段與段之間的 1 px 分隔也很細；在小螢幕或戶外可能要靠近看才數得準；最淡與最深的兩端（W 與 g）一眼可辨，中間幾段的顏色差異仍小

    時間條規則（寫死在程式；要修改請通知 PM）：
    - 總長 = 該狀態本次的總持續時間（5 秒；若成長系統「增益時間延長」有升級，則為 5 秒加上升級的秒數，最多 10 秒）
    - 填色寬度（像素）= 向上取整（20 × 剩餘時間 ÷ 總時間）；剩 0 秒時圖示與線段一起移除（線段內部寬 20，連續填色，不分段）
    - 最後 1 秒（**使用者已決定採用**）：填色在 `W` 與 `G` 之間每 100 ms 切換一次，提醒快結束（程式處理，不另畫圖）
    - 同一狀態再次拾取（**使用者已決定：疊加**）：
      - 新的剩餘時間 = 目前剩餘時間 + 新道具的時間；上限照 README 與成長系統（若有，例如「增益時間延長」）規定的最長時間，超過就取上限
      - 時間條以疊加後的剩餘時間作為**新的總時間**，回到全滿，再依上面的公式縮短
      - 附魔（整局）不倒數，再次拾取不影響

    使用者已決定的項目（第 3 版確認）：

    | 項目 | 使用者決定 |
    |---|---|
    | 強化每段 2×2 px | 目前先這樣 |
    | 整排寬 126 px | 目前先這樣 |
    | 附魔與 fever 同為全滿白線 | 可以 |
    | 最後 1 秒閃爍 | 採用 |
    | 同一狀態再次拾取 | 疊加（見上方規則） |
    | 狀態列位置 | 等畫面出來再決定，保留下方 3 個方案，待整體畫面出來後決定 |

    第 4 版新增：減速、加速（使用者已確認，含 `hud_icon_slow`、`hud_icon_fast`、`hud_slow_fast_levels`；既有 5 種圖示與規則不變）：
    - 新增 `hud_icon_slow`（減速）、`hud_icon_fast`（加速）兩個圖示；用同一塊 16×16 底板（外圈 `K`、亮邊 `f`、暗邊 `j`、底板面 `g`），內容在 12×12 內容框內，外形頂到內容框四邊
    - 外形與既有 5 種、彼此都分得開，不靠顏色：

    | 狀態 | 圖示 | 外形記號 | 主要顏色（D01 代號） | 圖 id |
    |---|---|---|---|---|
    | 減速 | 珍珠白球加文字 SP 與右上 −（使用者已確認 SP/ATK，2026-10-26） | 左上 SP、右上 −、下方 6×6 球 | 白 `W`（文字）、珍珠白 `W` `1`~`4`、`K` | `hud_icon_slow` |
    | 加速 | 珍珠白球加文字 SP 與右上 +（使用者已確認 SP/ATK，2026-10-26） | 左上 SP、右上 +、下方 6×6 球 | 白 `W`（文字）、珍珠白 `W` `1`~`4`、`K` | `hud_icon_fast` |

    - 為什麼這兩個圖示不會和既有的混淆（2026-10-26 改）：穿透是向上的箭穿橫板、強化是 ATK 字樣（無球）、加速與減速是球加 SP 字樣；有字或無字、有球或無球、整體輪廓都不同；加速與減速彼此只差右上 +／−
    - 線段（沿用 22×4 外框與分段通用規則）：減速 3 段（對應 −1~−3 階）、加速 4 段（對應 +1~+4 階）；整場有效，沒有時間條
    - 3 段與 4 段從 7 種灰挑色：用通用規則 round((i − 1) × 6 ÷ (N − 1))，7 種灰的順序為 `W`（0）`7`（1）`G`（2）`8`（3）`f`（4）`y`（5）`g`（6）

    | 狀態 | 段數 N | 每段寬度（欄） | 各段顏色（由左到右，第 1 段白、最後一段最深） |
    |---|---|---|---|
    | 減速（−1~−3） | 3 | w = 6，r = 0，三段各 6 欄，共 3×6 + 2 = 20 | `W`、`8`、`g` |
    | 加速（+1~+4） | 4 | w = 4，r = 1，第 1 段 5 欄、其餘各 4 欄，共 5 + 3×4 + 3 = 20 | `W`、`G`、`f`、`g` |

    - 顯示規則（使用者已確認）：
      - 兩格顯示的是「實際球速的淨階數」：加速與減速互相抵銷，只顯示淨值
      - 例（使用者的範例）：原本是加速 3 格，再撿到 1 個減速，HUD 顯示「加速 2 格」，**不會同時顯示加速 3 格和減速 1 格**
      - 淨值 < 0：顯示減速格，填前 |淨值| 段；淨值 > 0：顯示加速格，填前「淨值」段；淨值 = 0：兩格都不顯示
      - 兩者都是整場有效，沒有時間條，也沒有最後 1 秒閃爍
      - 減速與加速互為反方向，實際上不會同時出現；範例圖 `hud_row_example` 兩格都畫只是為了示意
    - 光暈（D15 方案 C，使用者決定）：只要 HUD 上有任何一格在顯示，球就有光暈；所以減速、加速都會讓球顯示青色光暈
    - 已知限制：
      - 加速與減速不靠顏色，靠 SP 字樣與右上 +／−（1 px 筆畫）分辨；兩者只差這一個符號，色盲與小螢幕下較易混淆
      - SP 為 3×5 像素字，球縮成 6×6，細節很少
      - 顯示的是淨階數，玩家看不到「加速、減速各疊了幾次」

    排列規則（7 格排列與新版 `hud_row_example` 使用者已確認）：

    | 項目 | 規則 |
    |---|---|
    | 格子 | 22×22，共 7 個固定格位（第 4 版加入減速、加速），格與格間距 4 px；整排寬 7×22 + 6×4 = 178 px，高 22 px（原 5 格為 126 px） |
    | 順序（由左到右） | 強化、fever、減速、加速、穿透、火焰、炸彈：整局常駐的在左，限時的在右；減速、加速是整場有效，排在 fever 之後、限時狀態之前 |
    | 固定格位 | 每個狀態有自己的格位，沒有該狀態時**該格留空，不往左補位**；圖示位置不會因別的狀態消失而跳動，玩家可以憑位置記憶 |
    | 最多同時 | 6 個（減速與加速是同一個淨階數的兩個方向，實際上不會同時出現；7 種全部排在一起只出現在範例圖） |
    | 出現與消失 | 直接出現與消失，不加淡入、位移動畫 |
    | 底色 | 每個圖示自帶 16×16 底板與 `K` 描邊，可直接放在深色背景上；線段條有 `j` 外框；若整排放在彩色磚上方請整體加一塊深色底板（待整體畫面出來後決定） |

    位置建議（使用者已決定：等畫面出來再決定，3 個方案先保留，**待整體畫面出來後決定**）：
    - 問題：README 說關卡區高 640，手機高度 640~800，多出的高度給 HUD；但在 640 高的手機上沒有多出來的空間，而這一排高 22 px
    - 資料依據：盤面預覽圖（`board_sample_x3.png`）中，磚塊從上方約 49 px 處開始（我由 3 倍圖估計，未量測），擋板在約第 603 列、下方約 33 px 空白；這是我的推測，要整體 UI 設計時確認

    | 方案 | 位置 | 優點 | 缺點 |
    |---|---|---|---|
    | 1（建議） | 關卡區頂端的空白帶（磚塊之上），靠左或置中 | 手指在下方，不會擋住 | 要與時間、分數、魔王血量共用同一條空間，可能放不下 |
    | 2 | 擋板下方的空白（約 33 px） | 離球與擋板最近，眼睛不用跑遠 | 手指拖擋板時會蓋住；擋板位置若改，這條空間也跟著變 |
    | 3 | 手機高度大於 640 時放在關卡區之下，640 時退回方案 1 或 2 | 高螢幕有完整空間 | 兩套版面都要做 |

    已知限制：
    - 圖示內容只有 12×12（上一版是 16×16），箭頭、火焰、炸彈的筆畫更少；在手機上約放大 3~4 倍，仍可辨，但細節（火焰內焰、炸彈高光）已簡化
    - 強化圖示已改為白色 ATK 字樣（2026-10-26），不再與火焰色相接近；底板（灰）讓各圖示的底色一致，白字對灰底約 6.2:1
    - 強化分段的每段只有 2×2 px，見上方說明
    - 附魔與 fever 的線段都是全滿白色，彼此只靠圖示分辨；5 秒狀態剛開始時線段也是全滿白色，要看它是否開始縮短才知道是不是附魔
    - 範例網格（`hud_row_example`）寬 126 列高 22，在文件裡每列很長；實際圖由轉檔工具輸出
    - 線段條加寬到 22 後比圖示（16）寬，格子也跟著變寬為 22；圖示在格內置中，左右各 3 欄空白

    需工具支援：
    - 數字字形換 `W` 墨色：**已不需要**（使用者已改為線段，不再顯示 +N 數字與 ∞ 記號，相關網格已刪除）
    - 線段填色：由程式依剩餘時間（連續填色）或強化階數（分段），在空線段 `hud_timebar_empty` 上畫出填色，不需要預先產生圖；分段規則見「分段通用規則」

    給工程師的需求：
    - 不需要新的後端資料或 API
    - HUD 需要的資料都在遊戲內：各狀態是否啟用、剩餘時間與總時間、是否為附魔、強化等級（1~7）、球數是否 50 以上

    穿透圖示（id: hud_icon_pierce）：
    ```text
    KKKKKKKKKKKKKKKK
    KfffffffffffffgK
    KfgggggKKgggggjK
    KfggggKwxKggggjK
    KfgggKwwxxKgggjK
    KfggKwwwxxxKggjK
    KfgKKKKwxKKKKgjK
    KfggggKwxKggggjK
    KfKKKKKKKKKKKKjK
    KfKeeeeeeeeeeKjK
    KfKffffffffffKjK
    KfKKKKKKKKKKKKjK
    KfggggKwxKggggjK
    KfggggKKKKggggjK
    KgjjjjjjjjjjjjjK
    KKKKKKKKKKKKKKKK
    ```

    火焰圖示（id: hud_icon_flame）：
    ```text
    KKKKKKKKKKKKKKKK
    KfffffffffffffgK
    KfgggggKKgggggjK
    KfggggKaaKggggjK
    KfgggKaOOdKgggjK
    KfggKaOBBdbKggjK
    KfgKaOBAABdbKgjK
    KfKOOBAAAABbbKjK
    KfKdOBAAAABbbKjK
    KfKdOBBAABBbbKjK
    KfKRdBBBBBBbRKjK
    KfgKRRdBBbRRKgjK
    KfggKtRRRRtKggjK
    KfgggKKKKKKgggjK
    KgjjjjjjjjjjjjjK
    KKKKKKKKKKKKKKKK
    ```

    炸彈圖示（id: hud_icon_bomb）：
    ```text
    KKKKKKKKKKKKKKKK
    KfffffffffffffgK
    KfggggggggggYgjK
    KfggggggggGYWYjK
    KfgggggggGggYgjK
    KfgggKKKKgggggjK
    KfgKWWfggjKgggjK
    KfKWfffgggjKggjK
    KfKWfffggjjKggjK
    KfKffgggjjjKggjK
    KfKfggggjjvKggjK
    KfKgggggjjvKggjK
    KfgKgjjvvvKgggjK
    KfgggKKKKgggggjK
    KgjjjjjjjjjjjjjK
    KKKKKKKKKKKKKKKK
    ```

    強化圖示（id: hud_icon_reinforce）：
    ```text
    KKKKKKKKKKKKKKKK
    KfffffffffffffgK
    KfggggggggggWgjK
    KfgggggggggWWWjK
    KfggggggggggWgjK
    KfggggggggggggjK
    KfggggggggggggjK
    KfggWggWWWgWgWjK
    KfgWgWggWggWgWjK
    KfgWWWggWggWWgjK
    KfgWgWggWggWgWjK
    KfgWgWggWggWgWjK
    KfggggggggggggjK
    KfggggggggggggjK
    KgjjjjjjjjjjjjjK
    KKKKKKKKKKKKKKKK
    ```

    fever 圖示（id: hud_icon_fever）：
    ```text
    KKKKKKKKKKKKKKKK
    KfffffffffffffgK
    KfggggKKKKggggjK
    KfgggKW122KgggjK
    KfgggK1223KgggjK
    KfgggK2233KgggjK
    KfgggK2334KgggjK
    KfggggKKKKggggjK
    KfgKKKKggKKKKgjK
    KfKW122KKW122KjK
    KfK1223KK1223KjK
    KfK2233KK2233KjK
    KfK2334KK2334KjK
    KfgKKKKggKKKKgjK
    KgjjjjjjjjjjjjjK
    KKKKKKKKKKKKKKKK
    ```

    線段條：滿（5 秒狀態剛開始、附魔、fever）（id: hud_timebar_full）：
    ```text
    jjjjjjjjjjjjjjjjjjjjjj
    jWWWWWWWWWWWWWWWWWWWWj
    jWWWWWWWWWWWWWWWWWWWWj
    jjjjjjjjjjjjjjjjjjjjjj
    ```

    線段條：空（填色由程式依剩餘時間畫在這張上）（id: hud_timebar_empty）：
    ```text
    jjjjjjjjjjjjjjjjjjjjjj
    jvvvvvvvvvvvvvvvvvvvvj
    jvvvvvvvvvvvvvvvvvvvvj
    jjjjjjjjjjjjjjjjjjjjjj
    ```

    強化 +1 到 +7 的分段條（由上到下 +1 到 +7；每段由左到右由白漸深；有色段數 = 階數）（id: hud_reinforce_levels）：
    ```text
    jjjjjjjjjjjjjjjjjjjjjj
    jWWjvvjvvjvvjvvjvvjvvj
    jWWjvvjvvjvvjvvjvvjvvj
    jjjjjjjjjjjjjjjjjjjjjj
    ......................
    ......................
    jjjjjjjjjjjjjjjjjjjjjj
    jWWj77jvvjvvjvvjvvjvvj
    jWWj77jvvjvvjvvjvvjvvj
    jjjjjjjjjjjjjjjjjjjjjj
    ......................
    ......................
    jjjjjjjjjjjjjjjjjjjjjj
    jWWj77jGGjvvjvvjvvjvvj
    jWWj77jGGjvvjvvjvvjvvj
    jjjjjjjjjjjjjjjjjjjjjj
    ......................
    ......................
    jjjjjjjjjjjjjjjjjjjjjj
    jWWj77jGGj88jvvjvvjvvj
    jWWj77jGGj88jvvjvvjvvj
    jjjjjjjjjjjjjjjjjjjjjj
    ......................
    ......................
    jjjjjjjjjjjjjjjjjjjjjj
    jWWj77jGGj88jffjvvjvvj
    jWWj77jGGj88jffjvvjvvj
    jjjjjjjjjjjjjjjjjjjjjj
    ......................
    ......................
    jjjjjjjjjjjjjjjjjjjjjj
    jWWj77jGGj88jffjyyjvvj
    jWWj77jGGj88jffjyyjvvj
    jjjjjjjjjjjjjjjjjjjjjj
    ......................
    ......................
    jjjjjjjjjjjjjjjjjjjjjj
    jWWj77jGGj88jffjyyjggj
    jWWj77jGGj88jffjyyjggj
    jjjjjjjjjjjjjjjjjjjjjj
    ```

    減速圖示（id: hud_icon_slow）：
    ```text
    KKKKKKKKKKKKKKKK
    KfffffffffffffgK
    KfWWWgWWWgggggjK
    KfWgggWgWgggggjK
    KfWWWgWWWggWWWjK
    KfggWgWgggggggjK
    KfWWWgWgggggggjK
    KfggggggggggggjK
    KfggggKKKKggggjK
    KfgggKW122KgggjK
    KfgggK1223KgggjK
    KfgggK2233KgggjK
    KfgggK2334KgggjK
    KfggggKKKKggggjK
    KgjjjjjjjjjjjjjK
    KKKKKKKKKKKKKKKK
    ```

    加速圖示（id: hud_icon_fast）：
    ```text
    KKKKKKKKKKKKKKKK
    KfffffffffffffgK
    KfWWWgWWWgggggjK
    KfWgggWgWgggWgjK
    KfWWWgWWWggWWWjK
    KfggWgWgggggWgjK
    KfWWWgWgggggggjK
    KfggggggggggggjK
    KfggggKKKKggggjK
    KfgggKW122KgggjK
    KfgggK1223KgggjK
    KfgggK2233KgggjK
    KfgggK2334KgggjK
    KfggggKKKKggggjK
    KgjjjjjjjjjjjjjK
    KKKKKKKKKKKKKKKK
    ```

    減速 1~3 段、加速 1~4 段示意（上 3 條為減速 −1~−3，下 4 條為加速 +1~+4；段色由左到右由白漸深）（id: hud_slow_fast_levels）：
    ```text
    jjjjjjjjjjjjjjjjjjjjjj
    jWWWWWWjvvvvvvjvvvvvvj
    jWWWWWWjvvvvvvjvvvvvvj
    jjjjjjjjjjjjjjjjjjjjjj
    ......................
    ......................
    jjjjjjjjjjjjjjjjjjjjjj
    jWWWWWWj888888jvvvvvvj
    jWWWWWWj888888jvvvvvvj
    jjjjjjjjjjjjjjjjjjjjjj
    ......................
    ......................
    jjjjjjjjjjjjjjjjjjjjjj
    jWWWWWWj888888jggggggj
    jWWWWWWj888888jggggggj
    jjjjjjjjjjjjjjjjjjjjjj
    ......................
    ......................
    ......................
    ......................
    jjjjjjjjjjjjjjjjjjjjjj
    jWWWWWjvvvvjvvvvjvvvvj
    jWWWWWjvvvvjvvvvjvvvvj
    jjjjjjjjjjjjjjjjjjjjjj
    ......................
    ......................
    jjjjjjjjjjjjjjjjjjjjjj
    jWWWWWjGGGGjvvvvjvvvvj
    jWWWWWjGGGGjvvvvjvvvvj
    jjjjjjjjjjjjjjjjjjjjjj
    ......................
    ......................
    jjjjjjjjjjjjjjjjjjjjjj
    jWWWWWjGGGGjffffjvvvvj
    jWWWWWjGGGGjffffjvvvvj
    jjjjjjjjjjjjjjjjjjjjjj
    ......................
    ......................
    jjjjjjjjjjjjjjjjjjjjjj
    jWWWWWjGGGGjffffjggggj
    jWWWWWjGGGGjffffjggggj
    jjjjjjjjjjjjjjjjjjjjjj
    ```

    HUD 狀態列範例（7 種狀態全部顯示）：強化 +5、fever、減速（−2）、加速（+3）、穿透（附魔）、火焰（剩約 60%）、炸彈（剩約 30%）；減速與加速實際上不會同時出現，這裡兩格都畫只是為了示意（id: hud_row_example）：
    ```text
    ...KKKKKKKKKKKKKKKK..........KKKKKKKKKKKKKKKK..........KKKKKKKKKKKKKKKK..........KKKKKKKKKKKKKKKK..........KKKKKKKKKKKKKKKK..........KKKKKKKKKKKKKKKK..........KKKKKKKKKKKKKKKK...
    ...KfffffffffffffgK..........KfffffffffffffgK..........KfffffffffffffgK..........KfffffffffffffgK..........KfffffffffffffgK..........KfffffffffffffgK..........KfffffffffffffgK...
    ...KfggggggggggWgjK..........KfggggKKKKggggjK..........KfWWWgWWWgggggjK..........KfWWWgWWWgggggjK..........KfgggggKKgggggjK..........KfgggggKKgggggjK..........KfggggggggggYgjK...
    ...KfgggggggggWWWjK..........KfgggKW122KgggjK..........KfWgggWgWgggggjK..........KfWgggWgWgggWgjK..........KfggggKwxKggggjK..........KfggggKaaKggggjK..........KfggggggggGYWYjK...
    ...KfggggggggggWgjK..........KfgggK1223KgggjK..........KfWWWgWWWggWWWjK..........KfWWWgWWWggWWWjK..........KfgggKwwxxKgggjK..........KfgggKaOOdKgggjK..........KfgggggggGggYgjK...
    ...KfggggggggggggjK..........KfgggK2233KgggjK..........KfggWgWgggggggjK..........KfggWgWgggggWgjK..........KfggKwwwxxxKggjK..........KfggKaOBBdbKggjK..........KfgggKKKKgggggjK...
    ...KfggggggggggggjK..........KfgggK2334KgggjK..........KfWWWgWgggggggjK..........KfWWWgWgggggggjK..........KfgKKKKwxKKKKgjK..........KfgKaOBAABdbKgjK..........KfgKWWfggjKgggjK...
    ...KfggWggWWWgWgWjK..........KfggggKKKKggggjK..........KfggggggggggggjK..........KfggggggggggggjK..........KfggggKwxKggggjK..........KfKOOBAAAABbbKjK..........KfKWfffgggjKggjK...
    ...KfgWgWggWggWgWjK..........KfgKKKKggKKKKgjK..........KfggggKKKKggggjK..........KfggggKKKKggggjK..........KfKKKKKKKKKKKKjK..........KfKdOBAAAABbbKjK..........KfKWfffggjjKggjK...
    ...KfgWWWggWggWWgjK..........KfKW122KKW122KjK..........KfgggKW122KgggjK..........KfgggKW122KgggjK..........KfKeeeeeeeeeeKjK..........KfKdOBBAABBbbKjK..........KfKffgggjjjKggjK...
    ...KfgWgWggWggWgWjK..........KfK1223KK1223KjK..........KfgggK1223KgggjK..........KfgggK1223KgggjK..........KfKffffffffffKjK..........KfKRdBBBBBBbRKjK..........KfKfggggjjvKggjK...
    ...KfgWgWggWggWgWjK..........KfK2233KK2233KjK..........KfgggK2233KgggjK..........KfgggK2233KgggjK..........KfKKKKKKKKKKKKjK..........KfgKRRdBBbRRKgjK..........KfKgggggjjvKggjK...
    ...KfggggggggggggjK..........KfK2334KK2334KjK..........KfgggK2334KgggjK..........KfgggK2334KgggjK..........KfggggKwxKggggjK..........KfggKtRRRRtKggjK..........KfgKgjjvvvKgggjK...
    ...KfggggggggggggjK..........KfgKKKKggKKKKgjK..........KfggggKKKKggggjK..........KfggggKKKKggggjK..........KfggggKKKKggggjK..........KfgggKKKKKKgggjK..........KfgggKKKKgggggjK...
    ...KgjjjjjjjjjjjjjK..........KgjjjjjjjjjjjjjK..........KgjjjjjjjjjjjjjK..........KgjjjjjjjjjjjjjK..........KgjjjjjjjjjjjjjK..........KgjjjjjjjjjjjjjK..........KgjjjjjjjjjjjjjK...
    ...KKKKKKKKKKKKKKKK..........KKKKKKKKKKKKKKKK..........KKKKKKKKKKKKKKKK..........KKKKKKKKKKKKKKKK..........KKKKKKKKKKKKKKKK..........KKKKKKKKKKKKKKKK..........KKKKKKKKKKKKKKKK...
    ..................................................................................................................................................................................
    ..................................................................................................................................................................................
    jjjjjjjjjjjjjjjjjjjjjj....jjjjjjjjjjjjjjjjjjjjjj....jjjjjjjjjjjjjjjjjjjjjj....jjjjjjjjjjjjjjjjjjjjjj....jjjjjjjjjjjjjjjjjjjjjj....jjjjjjjjjjjjjjjjjjjjjj....jjjjjjjjjjjjjjjjjjjjjj
    jWWj77jGGj88jffjvvjvvj....jWWWWWWWWWWWWWWWWWWWWj....jWWWWWWj888888jvvvvvvj....jWWWWWjGGGGjffffjvvvvj....jWWWWWWWWWWWWWWWWWWWWj....jWWWWWWWWWWWWvvvvvvvvj....jWWWWWWvvvvvvvvvvvvvvj
    jWWj77jGGj88jffjvvjvvj....jWWWWWWWWWWWWWWWWWWWWj....jWWWWWWj888888jvvvvvvj....jWWWWWjGGGGjffffjvvvvj....jWWWWWWWWWWWWWWWWWWWWj....jWWWWWWWWWWWWvvvvvvvvj....jWWWWWWvvvvvvvvvvvvvvj
    jjjjjjjjjjjjjjjjjjjjjj....jjjjjjjjjjjjjjjjjjjjjj....jjjjjjjjjjjjjjjjjjjjjj....jjjjjjjjjjjjjjjjjjjjjj....jjjjjjjjjjjjjjjjjjjjjj....jjjjjjjjjjjjjjjjjjjjjj....jjjjjjjjjjjjjjjjjjjjjj
    ```

17. [D17] 功能型磚塊 第 1 批（使用者已確認，2026-10-26）：
    - 範圍：雷射磚、閃電磚、死神磚的磚體、數字位置、被擊中、破壞，以及三種「發動效果」；第 2 批（爆炸、彩虹、傳送）之後再畫，本項不含
    - 規格（README）：雷射＝分水平、垂直、十字 3 種，水平打橫向一整排、垂直打直向一整欄、十字兩者都打，讓整排或整欄可破壞磚層數減 1，被不可破壞磚或任何功能型磚擋下（使用者 2026-10-26 決定：功能型磚不受影響、不扣次數、不發動、不破壞；擋板槍的子彈打到功能型磚同樣被擋下、磚不受影響），被碰時次數減 1（README 原寫減 2 為筆誤，使用者已改）；閃電＝打出和剩餘次數一樣多的閃電，各打隨機一塊可破壞磚減 2 層，不打不可破壞磚，被碰時次數減 1；死神＝直接破壞碰到的球；雷射、閃電的使用次數都是 1~9 隨機（死神同為 1~9 隨機），歸零時磚破壞
    - 使用者已決定（本項遵守）：尺寸 32×16；剩餘次數用 D12 的 5×7 像素數字顯示、最多 9（1 位數）；「無敵」期間沿用 D14 `invincible_a_overlay`；不會被炸彈標記（不畫標記）；效果一併繪製
    - 欄、列編號一律從 0 起算；風格沿用 D01、D02（左上光源、1 px `K` 描邊、2 px 斜面、5 階色階、凹坑紋理，不用抖色、漸層、隨機點）
    - 使用者另外決定的規則（本項遵守）：
      - 功能型磚被球碰到時，不受球的攻擊力加成影響（強化、fever、火焰等都不會）；每次碰觸只觸發一次效果
      - 閃電只打一般的可破壞磚（不打不可破壞磚，也不打功能型磚）
      - 雷射磚每次被碰減 1 次；剩 1 次被碰 → 歸零 → 仍發射一次雷射，之後磚破壞
      - 雷射、閃電的使用次數初始都是 1~9 隨機（個位數，數字顯示 1~9）
      - 死神被碰到時只播 D12 被擊中 1 幀，球播 D15 消失動畫，不另畫磚的發動圖
      - 閃電道數＝碰觸前的剩餘次數：剩 9 次被碰 → 打 9 道 → 剩 8；再被碰 → 打 8 道 → 剩 7；依此類推，剩 1 次被碰 → 打 1 道 → 歸零破壞
    - 本項所有網格每列字元數等於標示的圖寬

    視覺方向（D17）：

    | 項目 | 內容 |
    |---|---|
    | 主題 | 三種「會主動出手」的磚；玩家要在球飛過去前就認出它是哪一種、要不要避開（死神）或要不要撞（雷射、閃電） |
    | 色彩 | 洋紅（雷射）、電青（閃電）、骨白（死神）；三色都不在彩虹七色、鋼灰擋板、D14 深灰藍、魔王暗紫灰之內；色碼見 D01 |
    | 版面 | 左半放記號（雷射＝準星加光束、閃電＝閃電符號、死神＝骷髏），右半留數字；三種磚的記號位置不同但數字位置相同 |
    | 原則 | 1. 顏色和記號雙重辨識：換成灰階或色盲，只看記號也分得出 2. 數字位置固定，玩家掃一眼右半就能讀次數 3. 效果動態短而少：只有一個重點動作，不全畫面閃 |

    自我檢查（已換掉的通用預設）：
    - 三種磚都不套「七色換色」，也不用單一彩虹色當主色，避免被誤認為普通磚或彩虹磚的選色
    - 死神不用「黑底」：黑底會與背景（約 #0F0F1E）和 `K` 描邊糊在一起，也會與 D14 深色鋼板混淆；改用骨白磚加深色骷髏，全場唯一的淺暖色磚
    - 閃電不用黃色磚：黃色屬於七色；磚用電青，閃電符號本身用黃白

    新增顏色（已加入 D01，標「D17 用」；新代號 `@ # % + = ~ * & 0 9 $ ^ !`，已用 Grep 確認原稿未使用）：

    | 磚 | T1 | T2 | T3（主色） | T4 | T5 | 說明 |
    |---|---|---|---|---|---|---|
    | 雷射（洋紅） | `@` #FFC2DF | `5` #FF6FB5 | `#` #EA4FA6 | `6` #B02A78 | `%` #6E1650 | T2、T4 沿用 D01 的品紅 `5`、`6`；新增 3 色 |
    | 閃電（電青） | `+` #C8FFF0 | `=` #7DEFD6 | `~` #1FC4AA | `*` #138C80 | `&` #0B544E | 新增 5 色 |
    | 死神（骨白） | `0` #FFF8E4 | `9` #EFE4CB | `$` #D9C9A8 | `^` #A08E6C | `!` #5C503C | 新增 5 色；`!` 同時是骷髏本體色 |

    | 與誰分得開 | 做法 |
    |---|---|
    | 彩虹七色 | 洋紅色相約 325°，介於紅（358°）與紫（265°）之間但更亮更粉；電青約 175°，介於綠（100°）與藍（216°）之間；骨白是低飽和暖色，不同於飽和的黃；三色都不用七色的任何代號 |
    | 鋼灰擋板、寶箱鋼柱 | 骨白偏暖（黃褐調），鋼灰偏冷（藍灰調）；擋板是細長條，不是磚塊尺寸；電青與擋板端帽的青色小燈（`w`、`x`）只在擋板上很小一塊 |
    | D14 深灰藍不可破壞磚 | 三色都比深槍金屬（`s` 亮度 71）亮或鮮豔很多；且 D14 有十字鋼條與黃銅螺栓，D17 沒有 |
    | 魔王暗紫灰 | 魔王是 128×48 暗色大磚，三色都是 32×16 亮色磚 |
    | 三種之間 | 色相差：洋紅（粉紅）、電青（青綠）、骨白（米白）；亮度 Y 約 135／144／202，洋紅與電青亮度接近，靠色相與記號分；記號差：圓形準星加水平光束、閃電符號、骷髏 |

    已知限制（如實寫出，未用色盲模擬器驗證，請 QA 或使用者實機複核）：
    - 洋紅與紅、紫在紅綠色盲下可能偏近，靠準星加光束記號補強
    - 電青與綠、藍在部分色盲下可能偏近，靠閃電符號補強
    - 骨白磚亮度（Y 202）與黃磚（Y 209）、鋼灰 `e`（Y 202）相近，色相與飽和度不同，主要靠骷髏記號

    對比（近似，手算）：

    | 項目 | 比值 |
    |---|---|
    | 數字 `K` 對洋紅 `#` | 約 5.0:1 |
    | 數字 `K` 對電青 `~` | 約 7.7:1 |
    | 數字 `K` 對骨白 `$` | 約 10.4:1 |

    數字位置（三種磚相同；使用者要求預留；欄、列從 0 起算）：

    | 項目 | 規則 |
    |---|---|
    | 數字內容 | 1~9 的個位數；0 不顯示（歸零時磚已破壞）；字形用 D12 的 5×7 數字（數字 1~9） |
    | 數字顏色 | `K`（和 D12 相同，不加亮影） |
    | 數字位置 | 左上角放在第 21 欄、第 4 列；佔第 21~25 欄、第 4~10 列（與 D12 多層磚的第 13 欄不同，因左半要放記號） |
    | 預留區 | 第 20~26 欄、第 3~11 列（數字外各留 1 欄、上 1 列、下 1 列）；底圖在此區是純主色（T3），無紋理、無裂痕、無亮影 |
    | 底圖 | 下方 5 張磚體網格（`laser_brick_h`、`laser_brick_v`、`laser_brick_x`、`lightning_brick`、`reaper_brick`）是「沒有數字」的底圖；數字由轉檔工具疊上；`laser_brick_h_n5`、`laser_brick_v_n5`、`laser_brick_x_n5` 示範疊上數字 5 的結果；三種雷射磚的底色、斜面、數字位置完全相同，只靠記號分方向 |
    | 次數變化 | 被擊中時：先播 1 幀被擊中圖（仍顯示舊數字，`K` 不變色），再切到新數字的正常圖（與 D12「扣層」同做法） |

    被擊中、破壞（沿用 D12，不另畫）：

    | 項目 | 做法 |
    |---|---|
    | 被擊中（1 幀） | 沿用 D12：含數字的完整圖中，除 `K`、`.` 以外全改 `W`；建議 60 ms（D12 只寫 1 幀，未寫毫秒） |
    | 破壞 F1~F4 | 沿用 D12「通用破壞 F1~F4」，每幀 60 ms，換上各磚色階（下表）；記號與數字不保留（同寶箱的鎖、多層磚的數字） |
    | 死神磚 | 被球碰時只播 D12 被擊中 1 幀（使用者決定，無額外疊加圖），球播 D15 `ball_vanish_f1`~`f4` |

    破壞幀換色對照表（母版 → 目標；D12 母版為紅色階 `h r R t o`）：

    | 目標 | T1（`h`） | T2（`r`） | T3（`R`） | T4（`t`） | T5（`o`） |
    |---|---|---|---|---|---|
    | 雷射（洋紅） | `@` | `5` | `#` | `6` | `%` |
    | 閃電（電青） | `+` | `=` | `~` | `*` | `&` |
    | 死神（骨白） | `0` | `9` | `$` | `^` | `!` |

    「無敵」期間（沿用 D14 `invincible_a_overlay`，不另畫）：

    | 檢查項目 | 結果（依網格推算，未實機驗證） |
    |---|---|
    | 疊加範圍 | 只蓋外框：第 0~2 欄、第 29~31 欄、第 0~2 列、第 13~15 列；本項記號在第 4~18 欄、第 3~11 列，數字在第 21~25 欄、第 4~10 列，都在外框之內，不會被蓋到 |
    | 洋紅磚 | 鋼灰外框（`e f g j`）對洋紅主色（`#`）色相與亮度皆不同，邊界清楚 |
    | 電青磚 | 同上，鋼灰對電青清楚 |
    | 骨白磚 | 最弱：鋼灰 `f`（亮度 148）內緣對骨白 `$`（亮度 202）約 2:1，仍可見；外框右、下緣的 `g`、`j` 較暗，對比更大；外框四角的黃銅鉚釘（`B Y C`）在骨白旁較不明顯 |
    | 建議 | 使用者若覺得骨白磚的外框不夠清楚，再提出，我再改為專用疊加圖；目前不需另畫 |

    圖寬：32　圖高：16
    水平雷射磚底圖（id: laser_brick_h）：
    ```text
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    K@@@WWWW@@@@@@@@@555@@@@@@@@@5#K
    K5555555555555555555555555555#6K
    K@5############666###########6%K
    K@5#############55###########6%K
    K@5###K#########K############6%K
    K@5##KW@@@KKK@@@WK###########6%K
    K@5#KWWWWWKWKWWWWWK##########6%K
    K@5##KW@@@KKK@@@WK###########6%K
    K@5###K#########K############6%K
    K@5###########666############6%K
    K@5############55############6%K
    K@5##########################6%K
    K5#666666666666666666666666666%K
    K#6%%%%%%%%%%%%%%%%%%%%%%%%%%%%K
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    ```

    圖寬：32　圖高：16
    水平雷射磚疊上數字 5 的範例（id: laser_brick_h_n5）：
    ```text
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    K@@@WWWW@@@@@@@@@555@@@@@@@@@5#K
    K5555555555555555555555555555#6K
    K@5############666###########6%K
    K@5#############55###KKKKK###6%K
    K@5###K#########K####K#######6%K
    K@5##KW@@@KKK@@@WK###KKKK####6%K
    K@5#KWWWWWKWKWWWWWK######K###6%K
    K@5##KW@@@KKK@@@WK#######K###6%K
    K@5###K#########K####K###K###6%K
    K@5###########666#####KKK####6%K
    K@5############55############6%K
    K@5##########################6%K
    K5#666666666666666666666666666%K
    K#6%%%%%%%%%%%%%%%%%%%%%%%%%%%%K
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    ```

    圖寬：32　圖高：16
    垂直雷射磚底圖（id: laser_brick_v）：
    ```text
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    K@@@WWWW@@@@@@@@@555@@@@@@@@@5#K
    K5555555555555555555555555555#6K
    K@5########K###666###########6%K
    K@5#######KWK###55###########6%K
    K@5######KWWWK###############6%K
    K@5#######KKK################6%K
    K@5#######KWK################6%K
    K@5#######KKK################6%K
    K@5######KWWWK###############6%K
    K@5#######KWK#666############6%K
    K@5########K###55############6%K
    K@5##########################6%K
    K5#666666666666666666666666666%K
    K#6%%%%%%%%%%%%%%%%%%%%%%%%%%%%K
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    ```

    圖寬：32　圖高：16
    垂直雷射磚疊上數字 5 的範例（id: laser_brick_v_n5）：
    ```text
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    K@@@WWWW@@@@@@@@@555@@@@@@@@@5#K
    K5555555555555555555555555555#6K
    K@5########K###666###########6%K
    K@5#######KWK###55###KKKKK###6%K
    K@5######KWWWK#######K#######6%K
    K@5#######KKK########KKKK####6%K
    K@5#######KWK############K###6%K
    K@5#######KKK############K###6%K
    K@5######KWWWK#######K###K###6%K
    K@5#######KWK#666#####KKK####6%K
    K@5########K###55############6%K
    K@5##########################6%K
    K5#666666666666666666666666666%K
    K#6%%%%%%%%%%%%%%%%%%%%%%%%%%%%K
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    ```

    圖寬：32　圖高：16
    十字雷射磚底圖（id: laser_brick_x）：
    ```text
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    K@@@WWWW@@@@@@@@@555@@@@@@@@@5#K
    K5555555555555555555555555555#6K
    K@5########K###666###########6%K
    K@5#######KWK###55###########6%K
    K@5###K##KWWWK##K############6%K
    K@5##KW@@@KKK@@@WK###########6%K
    K@5#KWWWWWKWKWWWWWK##########6%K
    K@5##KW@@@KKK@@@WK###########6%K
    K@5###K##KWWWK##K############6%K
    K@5#######KWK#666############6%K
    K@5########K###55############6%K
    K@5##########################6%K
    K5#666666666666666666666666666%K
    K#6%%%%%%%%%%%%%%%%%%%%%%%%%%%%K
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    ```

    圖寬：32　圖高：16
    十字雷射磚疊上數字 5 的範例（id: laser_brick_x_n5）：
    ```text
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    K@@@WWWW@@@@@@@@@555@@@@@@@@@5#K
    K5555555555555555555555555555#6K
    K@5########K###666###########6%K
    K@5#######KWK###55###KKKKK###6%K
    K@5###K##KWWWK##K####K#######6%K
    K@5##KW@@@KKK@@@WK###KKKK####6%K
    K@5#KWWWWWKWKWWWWWK######K###6%K
    K@5##KW@@@KKK@@@WK#######K###6%K
    K@5###K##KWWWK##K####K###K###6%K
    K@5#######KWK#666#####KKK####6%K
    K@5########K###55############6%K
    K@5##########################6%K
    K5#666666666666666666666666666%K
    K#6%%%%%%%%%%%%%%%%%%%%%%%%%%%%K
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    ```

    圖寬：32　圖高：16
    閃電磚底圖（id: lightning_brick）：
    ```text
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    K+++WWWW+++++++++===+++++++++=~K
    K============================~*K
    K+=~~~~~~~KKKK~~~~~~~~~~~~~~~*&K
    K+=~~~~~~KKWAK~~+~~~~~~~~~~~~*&K
    K+=~~~~~KKWAKK~+W+~~~~~~~~~~~*&K
    K+=~~~~KKABKKK~~+~~~~~~~~~~~~*&K
    K+=~~~~KWABYCK~~~~~~~~~~~~~~~*&K
    K+=~~~~KKKBYKK~~~~~~~~~~~~~~~*&K
    K+=~~~~KKBYKK~~~~~~~~~~~~~~~~*&K
    K+=~~~~KYKKK~~***~~~~~~~~~~~~*&K
    K+=~~~~KKK~~~~~==~~~~~~~~~~~~*&K
    K+=~~~~~~~~~~~~~~~~~~~~~~~~~~*&K
    K=~***************************&K
    K~*&&&&&&&&&&&&&&&&&&&&&&&&&&&&K
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    ```

    圖寬：32　圖高：16
    死神磚底圖（id: reaper_brick）：
    ```text
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    K000WWWW0000000009990000000009$K
    K9999999999999999999999999999$^K
    K09$$$$$KKKKKK$$$$$$$$$$$$$$$^!K
    K09$$$$K^^!!!!K$^^^$$$$$$$$$$^!K
    K09$$$K^!!!!!!!K$99$$$$$$$$$$^!K
    K09$$$K!00!!00!K$$$$$$$$$$$$$^!K
    K09$$$K!00!!00!K$$$$$$$$$$$$$^!K
    K09$$$K!!!KK!!!K$$$$$$$$$$$$$^!K
    K09$$$$K!!!!!!K$$$$$$$$$$$$$$^!K
    K09^^^$$K0K0K0K$$$$$$$$$$$$$$^!K
    K09$99$$KKKKKKK$$$$$$$$$$$$$$^!K
    K09$$$$$$$$$$$$$$$$$$$$$$$$$$^!K
    K9$^^^^^^^^^^^^^^^^^^^^^^^^^^^!K
    K$^!!!!!!!!!!!!!!!!!!!!!!!!!!!!K
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    ```

    各磚說明：

    | 磚 | 記號（顏色以外的辨識線索） | 位置（欄、列從 0 起算） | 材質與紋理 |
    |---|---|---|---|
    | 雷射（水平 h） | 中央發射口（3×3 `K` 框、白點）加左右兩個箭頭，光束左右對稱：左右雙箭頭＝打左右整排 | 第 4~18 欄、第 5~9 列；發射口第 10~12 欄、第 6~8 列 | 洋紅 5 階斜面；光束核心 `W`、兩側 `@`；兩個凹坑（第 15~17 欄第 3~4 列、第 14~16 欄第 10~11 列） |
    | 雷射（垂直 v） | 同一個發射口，上下兩個箭頭：上下雙箭頭＝打上下整欄 | 第 9~13 欄、第 3~11 列；發射口第 10~12 欄、第 6~8 列 | 同上，凹坑同位置 |
    | 雷射（十字 x） | 同一個發射口，上下左右四個箭頭，等於 h 加 v 重疊 | 第 4~18 欄、第 3~11 列；發射口第 10~12 欄、第 6~8 列 | 同上，凹坑同位置 |
    | 閃電 | 細線鋸齒閃電符號（筆畫寬 2 px，上斜線、橫向折點、下斜線到尖端，折點明確；`K` 描邊、左亮右暗的 `W A B Y C`）加右側十字火花 | 閃電第 5~13 欄、第 3~11 列；火花第 15~17 欄、第 4~6 列 | 電青 5 階斜面；一個凹坑（第 14~16 欄第 10~11 列） |
    | 死神 | 骷髏（深色 `!` 本體、`^` 亮部、骨白眼窩與牙齒、`K` 鼻孔） | 骷髏第 6~15 欄、第 3~11 列 | 骨白 5 階斜面；兩個凹坑（第 3~5 欄第 10~11 列、第 16~18 欄第 4~5 列） |

    取捨：死神只畫骷髏、不畫鐮刀；32×16 內骷髏加數字已滿，再加鐮刀會讓記號變雜，骷髏已足夠辨識（使用者要求「骷髏或鐮刀類」）

    ---

    效果 1：雷射光束（水平＝橫向一整排；垂直＝直向一整欄；十字＝兩者；寬度不固定，用 16×16 分段拼接）

    3 種雷射磚的對應（使用者更新 README 後新增垂直、十字）：

    | 磚 id | 方向 | 光束 | 起點圖 |
    |---|---|---|---|
    | `laser_brick_h` | 水平 | 往左、往右兩邊，打整排 | `laser_beam_origin_*`（水平，下方原有兩張） |
    | `laser_brick_v` | 垂直 | 往上、往下兩邊，打整欄 | `laser_beam_v_origin_*` |
    | `laser_brick_x` | 十字 | 水平加垂直同時 | `laser_beam_x_origin_*` |

    拼法（水平，轉檔工具與遊戲依此規則）：

    | 項目 | 規則 |
    |---|---|
    | 分段 | 起點 `laser_beam_origin_*`（32×16）、中段 `laser_beam_mid_*`（16×16，可左右無限重複）、被擋下的端點 `laser_beam_block_*`（16×16，圖中光束由左向右撞上右側） |
    | 對齊 | 光束列的 y 與該排磚相同（高 16）；起點置中於雷射磚所在格（32×16，覆蓋整格）；磚格寬 32 = 2 個中段 |
    | 右側拼法 | 從起點右緣起向右排中段，每塊 16 px；遇到不可破壞磚或任何功能型磚，最靠近它的那一塊 16×16 換成 `laser_beam_block_*`；沒遇到擋就一路排到磚區右緣（第 340 px，內部座標）並裁掉超出磚區的部分 |
    | 左側拼法 | 與右側相同，端點圖水平鏡射；磚區左緣為第 20 px |
    | 公式 | 中段數 = 2 × （起點到擋下磚（不可破壞磚或任何功能型磚）之間的整格磚數）；若擋下磚緊貼雷射磚則沒有中段，只有端點 |
    | 到磚區邊緣 | 不另畫端點：光束被磚區裁切，邊框（磚區外的牆）畫在光束之上 |
    | 光束穿過空格 | 已被破壞的格也照畫；只有不可破壞磚或任何功能型磚（雷射、閃電、死神、爆炸、彩虹、傳送）能擋下；被擋下的磚不受影響（不扣次數、不發動、不破壞） |
    | 可平鋪 | 中段第 0 欄與第 15 欄每列顏色相同（不留接縫） |
    | 同一時間多道 | 允許同時多排光束，各自獨立播放 |

    動畫（4 幀，共 240 ms；起點、中段、端點同步換幀）：

    | 幀 | 起點 | 中段 | 端點 | 時間 | 同步事件 |
    |---|---|---|---|---|---|
    | F1 | `laser_beam_origin_thin` | `laser_beam_mid_thin` | `laser_beam_block_thin` | 60 ms | 蓄力：細光束；雷射磚播被擊中（`W`） |
    | F2 | `laser_beam_origin_full` | `laser_beam_mid_full` | `laser_beam_block_full` | 60 ms | 全寬光束；本幀開始時整排可破壞磚層數減 1（各自播 D12 被擊中） |
    | F3 | `laser_beam_origin_full` | `laser_beam_mid_full` | `laser_beam_block_full` | 60 ms | 維持全寬 |
    | F4 | `laser_beam_origin_thin` | `laser_beam_mid_thin` | `laser_beam_block_thin` | 60 ms | 收束；結束後移除光束，雷射磚播新數字或破壞 F1~F4 |

    繪製順序（由下到上）：磚（含數字）→ D14 無敵疊加層 → 雷射光束 → 擋板 → 球光暈 → 球本體；光束在磚之上，擋板與球永遠在光束之上，所以球和擋板不被光束蓋住

    垂直光束（直向一整欄）：中段與被擋下的端點由水平圖旋轉得到，不另畫網格；起點另畫。

    垂直光束的轉換規則（轉檔工具寫死；要修改請通知 PM，由工程師改工具）：

    | 垂直圖 id | 做法 | 公式（欄、列從 0 起算，尺寸 16×16） |
    |---|---|---|
    | `laser_beam_v_mid_thin`、`laser_beam_v_mid_full` | 由 `laser_beam_mid_thin`、`laser_beam_mid_full` 逆時針轉 90 度 | 新圖第 r 列第 c 欄 ＝ 原圖第 c 列第 (15 − r) 欄；光束寬 8 px 落在第 4~11 欄，可上下無縫平鋪（原圖第 0、15 欄同色，轉後第 0、15 列同色） |
    | `laser_beam_v_block_up_thin`、`laser_beam_v_block_up_full` | 由 `laser_beam_block_thin`、`laser_beam_block_full` 逆時針轉 90 度；光束由下往上撞上方的不可破壞磚 | 公式同上；原圖「撞右側」轉成「撞上方」，火花在圖的上緣 |
    | `laser_beam_v_block_down_thin`、`laser_beam_v_block_down_full` | 由 `block_up` 圖上下鏡射；光束由上往下撞下方的不可破壞磚 | 新圖第 r 列 ＝ `block_up` 第 (15 − r) 列；原水平圖上下對稱，所以等同順時針轉 90 度 |

    | 垂直項目 | 規則 |
    |---|---|
    | 對齊 | 垂直中段、端點是 16×16，水平置中於雷射磚所在欄：圖左緣 x ＝ 磚左緣 x ＋ 8（光束 8 px 寬落在磚欄中央的第 12~19 欄）；列對齊每 16 px 一塊，與磚列同高 |
    | 起點 | `laser_beam_v_origin_*`（32×16），覆蓋雷射磚整格，上下貫穿 |
    | 向上拼法 | 從起點上緣起向上排中段；遇到不可破壞磚或任何功能型磚，最靠近它的那一塊換成 `laser_beam_v_block_up_*`；沒遇到擋就一路排到磚區上緣並裁切，不畫端點 |
    | 向下拼法 | 從起點下緣起向下排中段；遇到不可破壞磚或任何功能型磚，最靠近它的那一塊換成 `laser_beam_v_block_down_*`；沒遇到擋就一路排到關卡區底部（使用者決定，穿過擋板所在高度）並裁切，不畫端點 |
    | 擋板與球 | 光束穿過擋板那一列，不影響球與擋板的碰撞；繪製上擋板、球都在光束之上 |
    | 關卡區邊緣 | 上緣（磚區上緣）、下緣（關卡區底部）、水平方向的左右緣一律直接裁切，不畫端點 |
    | 公式 | 一列磚高 16 ＝ 1 個中段；上方中段數 ＝ 起點到上方擋下磚（不可破壞磚或任何功能型磚）之間的整列磚數（擋下磚緊貼雷射磚則為 0，只有端點）；下方同理 |
    | 其他 | 穿過空格、同時多道、可平鋪等規則同水平 |

    十字光束：

    | 項目 | 規則 |
    |---|---|
    | 組成 | 水平光束（左右）加垂直光束（上下），各自依上方拼法，各自被不可破壞磚或任何功能型磚擋下；一邊被擋不影響另一邊 |
    | 起點 | `laser_beam_x_origin_*`（32×16），覆蓋雷射磚整格，水平與垂直同時貫穿 |
    | 同步 | 水平與垂直同一個時鐘、同一幀換圖（下方動畫表），F2 開始時整排與整欄的可破壞磚同時減 1 層；雷射磚本身不在被打範圍 |
    | 疊法 | 水平光束與垂直光束只在起點格相交（磚排與磚欄只交會於雷射磚那一格），其他位置不重疊，所以不需要疊加規則；兩道不同雷射磚的光束在別處交叉時，垂直光束畫在水平光束之上 |
    | 交叉處畫法（只在 `laser_beam_x_origin_*` 內） | 水平光束與垂直光束相交的 8×8（細版 4×4）方塊，每個像素取兩道光束中「較亮」的那個（亮度由高到低：`W`、`@`、`5`、`#`、`6`）：核心 `W` 連成十字，外圍是向內遞增的方框，沒有 `K` 描邊 |
    | 磚 | 十字雷射磚被擊中時一樣先播 D12 被擊中（`W`），再依次數減 1 換數字（次數歸零則仍發射一次後破壞）|

    動畫（垂直、十字的幀數、時間與水平相同）：

    | 幀 | 垂直起點／中段／端點 | 十字起點 | 時間 | 同步事件 |
    |---|---|---|---|---|
    | F1 | `laser_beam_v_origin_thin`／`laser_beam_v_mid_thin`／`laser_beam_v_block_*_thin` | `laser_beam_x_origin_thin`（水平、垂直段也用 thin 版） | 60 ms | 蓄力；雷射磚播被擊中 |
    | F2 | `…_full` 版 | `laser_beam_x_origin_full` | 60 ms | 全寬；開始時整欄（十字：整排加整欄）可破壞磚層數減 1 |
    | F3 | `…_full` 版 | `laser_beam_x_origin_full` | 60 ms | 維持全寬 |
    | F4 | `…_thin` 版 | `laser_beam_x_origin_thin` | 60 ms | 收束；結束後移除光束，雷射磚播新數字或破壞 F1~F4 |

    圖寬：16　圖高：16
    雷射光束中段，細（id: laser_beam_mid_thin）：
    ```text
    ................
    ................
    ................
    ................
    ................
    ................
    ################
    WWWWWWWWWWWWWWWW
    WWWWWWWWWWWWWWWW
    ################
    ................
    ................
    ................
    ................
    ................
    ................
    ```

    圖寬：16　圖高：16
    雷射光束中段，全寬（id: laser_beam_mid_full）：
    ```text
    ................
    ................
    ................
    ................
    6666666666666666
    ################
    55@@@@55555@@@@5
    WWWWWWWWWWWWWWWW
    WWWWWWWWWWWWWWWW
    5@@@@55555@@@@55
    ################
    6666666666666666
    ................
    ................
    ................
    ................
    ```

    圖寬：16　圖高：16
    雷射光束被擋下的端點，細（id: laser_beam_block_thin）：
    ```text
    ................
    ................
    ................
    ................
    ...........A....
    ............@...
    ###########@@WW@
    WWWWWWWWWWWWWWWW
    WWWWWWWWWWWWWWWW
    ###########@@WW@
    ............@...
    ...........A....
    ................
    ................
    ................
    ................
    ```

    圖寬：16　圖高：16
    雷射光束被擋下的端點，全寬（id: laser_beam_block_full）：
    ```text
    ................
    ..........@.....
    ...........A...@
    ............W.A.
    66666666666#@WA.
    ###########5@WW@
    55@@@@55555@WWWW
    WWWWWWWWWWWWWWWW
    WWWWWWWWWWWWWWWW
    5@@@@55555@@WWWW
    ###########5@WW@
    66666666666#@WA.
    ............W.A.
    ...........A...@
    ..........@.....
    ................
    ```

    圖寬：32　圖高：16
    雷射光束起點，細（id: laser_beam_origin_thin）：
    ```text
    ................................
    ................................
    ................................
    ................................
    ...............##...............
    ..............5@@5..............
    ############@@WWWW@@############
    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
    ############@@WWWW@@############
    ..............5@@5..............
    ...............##...............
    ................................
    ................................
    ................................
    ................................
    ```

    圖寬：32　圖高：16
    雷射光束起點，全寬（id: laser_beam_origin_full）：
    ```text
    ...............##...............
    ...............55...............
    ..............5@@5..............
    .............#5@@5#.............
    666666666666#5@@@@5#666666666666
    ##########5@WWWWWWWW@5##########
    555@@@555@WWWWWWWWWWWW@555@@@555
    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
    555@@@555@WWWWWWWWWWWW@555@@@555
    ##########5@WWWWWWWW@5##########
    666666666666#5@@@@5#666666666666
    .............#5@@5#.............
    ..............5@@5..............
    ...............55...............
    ...............##...............
    ```

    圖寬：32　圖高：16
    垂直雷射光束起點，細（id: laser_beam_v_origin_thin）：
    ```text
    ..............#WW#..............
    ..............#WW#..............
    ..............#WW#..............
    ..............#WW#..............
    ..............#WW#..............
    ..............#WW#..............
    ............5@#WW#@5............
    ..........55@@#WW#@@55..........
    ..........55@@#WW#@@55..........
    ............5@#WW#@5............
    ..............#WW#..............
    ..............#WW#..............
    ..............#WW#..............
    ..............#WW#..............
    ..............#WW#..............
    ..............#WW#..............
    ```

    圖寬：32　圖高：16
    垂直雷射光束起點，全寬（id: laser_beam_v_origin_full）：
    ```text
    ............6#5WW5#6............
    ............6#@WW@#6............
    ............6#@WW@#6............
    ............6#@WW@#6............
    ............6#5WW5#6............
    ...........#5@WWWW@5#...........
    .........5@WWWWWWWWWW@5.........
    ####55555@WWWWWWWWWWWW@55555####
    ####55555@WWWWWWWWWWWW@55555####
    .........5@WWWWWWWWWW@5.........
    ...........#5@WWWW@5#...........
    ............6#5WW5#6............
    ............6#@WW@#6............
    ............6#@WW@#6............
    ............6#@WW@#6............
    ............6#5WW5#6............
    ```

    圖寬：32　圖高：16
    十字雷射光束起點，細（id: laser_beam_x_origin_thin）：
    ```text
    ..............#WW#..............
    ..............#WW#..............
    ..............#WW#..............
    ..............#WW#..............
    ..............#WW#..............
    ..............#WW#..............
    ###############WW###############
    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
    ###############WW###############
    ..............#WW#..............
    ..............#WW#..............
    ..............#WW#..............
    ..............#WW#..............
    ..............#WW#..............
    ..............#WW#..............
    ```

    圖寬：32　圖高：16
    十字雷射光束起點，全寬（id: laser_beam_x_origin_full）：
    ```text
    ............6#5WW5#6............
    ............6#@WW@#6............
    ............6#@WW@#6............
    ............6#@WW@#6............
    6666666666666#5WW5#6666666666666
    ##############5WW5##############
    555555555555555WW555555555555555
    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
    555555555555555WW555555555555555
    ##############5WW5##############
    6666666666666#5WW5#6666666666666
    ............6#@WW@#6............
    ............6#@WW@#6............
    ............6#@WW@#6............
    ............6#5WW5#6............
    ```

    ---

    效果 2：閃電打到目標磚（落雷覆蓋圖）

    我提的方案與理由：

    | 方案 | 內容 | 結論 |
    |---|---|---|
    | A 完整路徑 | 從閃電磚畫一條折線到目標磚，長度、角度不固定 | 不採用：次數最多 9 道，同時 9 條長折線會蓋住半個畫面，也蓋住球；路徑圖要動態拼接，工具與程式成本高 |
    | B 落雷覆蓋圖（採用） | 在目標磚上方畫一道短閃電落下，打到磚中心炸出星形火花；固定大小 32×24 | 採用：一張固定尺寸圖，工具只要貼在目標磚上；9 道同時也不糊；落點一眼看得出是哪一塊被打 |
    | C 只閃磚 | 不畫閃電，只讓目標磚閃白 | 不採用：看不出是閃電造成 |

    規則：

    | 項目 | 規則 |
    |---|---|
    | 圖尺寸與對齊 | 32×24；圖的第 8~23 列對齊目標磚的第 0~15 列；圖的左上角 = 目標磚左上角 x，y 減 8（閃電從磚上方 8 px 落下，會蓋住上一排磚的下半，只有 3 幀 180 ms，可接受） |
    | 閃電落點 | 圖的第 15~16 欄、第 15~16 列＝目標磚的中心 |
    | 超出畫面 | 目標在最上排時，圖的上 8 列會超出磚區上緣；超出部分照畫，不裁（磚區上方是 HUD 以外的空白） |
    | 多道閃電 | 每次碰觸打「碰觸前剩餘次數」那麼多道（使用者決定，次數初始 1~9 隨機，所以最多 9 道）；各道落雷圖各自獨立播放；建議每道依序錯開 80 ms 起始（建議值，實作時再調）；不同道可以打到同一塊磚（README 為隨機位置） |
    | 目標限制（使用者決定） | 閃電只打一般的可破壞磚；不打不可破壞磚，也不打功能型磚（雷射、閃電、死神等） |

    動畫（3 幀，共 180 ms）：

    | 幀 | 圖 id | 內容 | 時間 | 同步事件 |
    |---|---|---|---|---|
    | F1 | `lightning_strike_f1` | 細閃電從上落下，磚中心有小白閃 | 60 ms | 無 |
    | F2 | `lightning_strike_f2` | 粗閃電加大星形火花 | 60 ms | 本幀開始時目標磚減 2 層，播 D12 被擊中（`W`） |
    | F3 | `lightning_strike_f3` | 閃電消失，小星形火花加四角餘火 | 60 ms | 目標若被減到 0，F3 結束後播 D12 破壞 F1~F4 |

    繪製順序（由下到上）：磚（含數字）→ D14 無敵疊加層 → 閃電落雷圖 → 球光暈 → 球本體

    圖寬：32　圖高：24
    閃電落雷 F1（id: lightning_strike_f1）：
    ```text
    ...............+WW+.............
    ...............+WW+.............
    ...............+WW+.............
    .............+WWWW+.............
    .............+WW+...............
    .............+WW+...............
    .............+WW+...............
    .............+WWWW+.............
    ...............+WW+.............
    ...............+WW+.............
    ..............+WW+..............
    ..............+WW+..............
    ..............+WW+..............
    ..............+WW+..............
    ..............+WW+..............
    .............+WWWW+.............
    .............+WWWW+.............
    ..............+WW+..............
    ................................
    ................................
    ................................
    ................................
    ................................
    ................................
    ```

    圖寬：32　圖高：24
    閃電落雷 F2（id: lightning_strike_f2）：
    ```text
    ..............+AWWA+............
    ..............+AWWA+............
    ..............+AWWA+............
    ............+AWWWWA+............
    ............+AWWA+..............
    ............+AWWA+..............
    ............+AWWA+..............
    ............+AWWWWA+............
    ..............+AWWA+............
    ..............+AWWA+............
    ...............++...............
    ...............AA...............
    ...........+...WW...+...........
    ............A..WW..A............
    .............AWWWWA.............
    ..........++AWWWWWWA++..........
    ..........++AWWWWWWA++..........
    .............AWWWWA.............
    ............A..WW..A............
    ...........+...WW...+...........
    ...............AA...............
    ...............++...............
    ................................
    ................................
    ```

    圖寬：32　圖高：24
    閃電落雷 F3（id: lightning_strike_f3）：
    ```text
    ................................
    ................................
    ................................
    ................................
    ................................
    ................................
    ................................
    ................................
    ................................
    ................................
    ................................
    ...........+........+...........
    ...............AA...............
    ..............+AA+..............
    .............+AWWA+.............
    ............AAWWWWAA............
    ............AAWWWWAA............
    .............+AWWA+.............
    ..............+AA+..............
    ...............AA...............
    ...........+........+...........
    ................................
    ................................
    ................................
    ```

    ---

    效果 3：死神磚發動（不另畫圖）

    決定（使用者決定）：死神被球碰到時，磚只播 D12 被擊中 1 幀，不畫任何額外疊加圖；球播 D15 `ball_vanish_f1`~`f4`

    動畫與同步（球消失 240 ms）：

    | 時間 | 磚 | 球 |
    |---|---|---|
    | 0~60 ms | 被擊中（D12，`W`），60 ms | `ball_vanish_f1` |
    | 60~120 ms | 回到新數字的正常圖，或次數歸零時開始播破壞 F1~F4（每幀 60 ms） | `ball_vanish_f2` |
    | 120~180 ms | 同上 | `ball_vanish_f3` |
    | 180~240 ms | 同上 | `ball_vanish_f4` |

    繪製順序（由下到上）：磚（含數字）→ D14 無敵疊加層（若有）→ 球光暈 → 球本體（含消失動畫）

    需轉檔工具新增的自動產生規則（規則寫死在轉檔工具；要修改請通知 PM，由工程師改工具）：

    | 項目 | 規則 |
    |---|---|
    | 磚加數字合成 | 對 `laser_brick_h`、`laser_brick_v`、`laser_brick_x`、`lightning_brick`、`reaper_brick` 各產生數字 1~9 共 9 張正常圖：底圖在第 21 欄、第 4 列疊上 D12 的 5×7 數字（`K`），`K` 覆蓋底圖，`.` 不動；共 45 張；`laser_brick_h_n5`、`laser_brick_v_n5`、`laser_brick_x_n5` 為對照用範例（雷射磚三種方向共用同一組洋紅破壞幀，破壞幀仍是 12 張） |
    | 被擊中圖 | 每張合成圖套 D12 被擊中規則（除 `K`、`.` 外全改 `W`）；共 45 張 |
    | 破壞幀 | 依上方換色對照表，把 D12 通用 F1~F4 的紅色階換成洋紅、電青、骨白；各 4 張，共 12 張；數字與記號不保留 |
    | 雷射分段拼接 | 依「效果 1」拼法在遊戲端執行（程式處理）；工具輸出本稿 10 張光束網格圖（水平 6、垂直起點 2、十字起點 2），另依「垂直光束的轉換規則」由水平中段、端點自動產生 6 張垂直圖（`laser_beam_v_mid_*` 2、`laser_beam_v_block_up_*` 2、`laser_beam_v_block_down_*` 2），並輸出排版資料（尺寸、鏡射用） |
    | 垂直光束轉換 | 逆時針轉 90 度：新圖第 r 列第 c 欄 ＝ 原圖第 c 列第 (15 − r) 欄；`block_down` ＝ `block_up` 上下鏡射（寫死在轉檔工具） |
    | 落雷 | 工具只輸出圖；對齊（落雷 y 減 8）由遊戲程式處理 |

    給工程師的需求：
    - 不需要新的後端資料或 API
    - 遊戲程式要處理：雷射光束（水平、垂直、十字）的分段拼接與裁切、垂直光束置中偏移（x ＋ 8）、垂直光束穿過擋板高度但不影響球與擋板、十字兩個方向同步換幀、光束被不可破壞磚或任何功能型磚擋下的判斷（各方向獨立；被擋的功能型磚不受影響；擋板槍的子彈打到功能型磚也被擋下、磚不受影響）、閃電多道時各道落雷依序錯開（建議每道間隔 80 ms，實作時再調）、閃電道數取碰觸前的剩餘次數、功能型磚不吃球的攻擊力加成且每次碰觸只觸發一次、閃電跳過功能型磚與不可破壞磚、各效果與 D12 被擊中的同步時機、繪製順序（磚 → 無敵疊加 → 效果 → 球光暈 → 球本體）
    - 玩家開啟系統「減少動態」時：雷射光束與落雷固定只播 F2（或 F2 相當的 1 幀 60 ms），不播其他幀（建議，請使用者確認）

    待使用者確認：目前無（D17 本身已由使用者確認，2026-10-26）

    使用者已決定（已寫入對應段落）：
    - 閃電道數＝碰觸前的剩餘次數；多道錯開時間為建議值（80 ms），實作時再調
    - 雷射每次被碰減 1 次（README 原「減 2」為筆誤）；雷射、閃電次數皆 1~9 隨機
    - 垂直光束經過擋板那一列：擋板畫在光束之上
    - 兩道雷射交叉：垂直光束畫在水平光束之上
    - 閃電只打一般的可破壞磚，不打不可破壞磚與功能型磚
    - 雷射磚剩 1 次被碰到：歸零，仍發射一次雷射後破壞
    - 骨白死神磚的無敵外框：維持現狀，實機有問題再提
    - 死神被碰時只播 D12 被擊中 1 幀，不畫咬合圖

18. [D18] 功能型磚塊 第 2 批（使用者已確認，2026-10-26）：
    - 範圍：爆炸磚、彩虹磚、傳送磚的磚體、被擊中、破壞（或不需要）、發動效果；第 1 批（雷射、閃電、死神）見 D17，不在本項
    - 規格（README）：爆炸＝被球觸碰時爆炸，以自己為中心周圍的可破壞磚不論層數直接破壞，僅能觸碰 1 次，觸碰後自己也被破壞；彩虹＝被球觸碰時隨機挑畫面中可破壞磚的一種顏色（不含魔王），把該顏色的所有磚破壞；傳送＝一定成雙成對（兩兩一組），被球碰到的為入口，其餘為出口，出口隨機選，出來的角度也隨機，沒有次數限制；以上為 README 原文，與下方「使用者已決定」不同處以「已決定」為準
    - 使用者已決定（本項遵守）：
      - 爆炸：範圍 3×3（以自己為中心的周圍 8 格加自己）；範圍內**只破壞可破壞磚**（多層磚、寶箱、金幣、圓形磚；不論層數）；魔王、其他功能型磚（雷射、閃電、死神、彩虹、傳送）、不可破壞磚都**不受影響**；**連鎖引爆**（使用者 2026-10-26 決定）：3×3 範圍內的另一顆爆炸磚會被引爆，以它為中心再爆一次 3×3，可以一直連鎖下去，每顆爆炸磚只觸發 1 次，連鎖的時間差實作時確認；只能碰 1 次，碰到後自己也破壞；爆炸效果另外畫，不與日後「炸彈道具」的爆炸共用
      - 彩虹：
        - 只能用 1 次，用完自己也破壞（破壞幀用珍珠白色階，沿用 D12 通用 F1~F4）
        - 挑色**只從畫面上現有的多層磚顏色中挑**（七色紅橙黃綠藍靛紫）；寶箱、金幣、圓形磚不屬於七色，不會被挑；魔王、功能型磚、不可破壞磚也不會被挑
        - 同一色不論有沒有數字都算同色（例：紅色 1 層與紅色 8 層〔紅＋數字 1〕一起破壞）
        - 畫面上沒有多層磚時，彩虹磚直接破壞（播珍珠白破壞幀），不播挑色環，也不播選中閃光
        - 磚面用七色斜條紋，加形狀記號；發動效果要表現「挑中某一色」與「該色磚一起被破壞」
      - 傳送：
        - 全部長得一樣，不分組、不分入口出口；入口播「吸入」、出口播「噴出」；沒有次數限制
        - **不套無敵外框**（不畫 D14 `invincible_a_overlay`）
        - **不會被任何東西破壞**（雷射、爆炸、彩虹、槍都不會）
        - 出口噴出效果**確定用吸入 4 幀倒播**，不另外畫
        - 球約 480 ms 不在畫面上可以接受，實測後再調
    - 沿用 D17 的通用規則：尺寸 32×16；被擊中沿用 D12（除 `K`、`.` 外全改 `W`，建議 60 ms）；破壞 F1~F4 沿用 D12 通用幀，每幀 60 ms，並在下方補換色對照表；「無敵」沿用 D14 `invincible_a_overlay`（爆炸、彩虹用；傳送磚不套，見下）；不會被炸彈標記（不畫標記）；不受球的攻擊力加成影響（強化、fever、火焰等），每次碰觸只觸發一次效果
    - 這三種磚都**不放數字、沒有數字預留區**（爆炸、彩虹只能用 1 次，傳送沒有次數限制；次數不顯示）
    - 欄、列編號一律從 0 起算；風格沿用 D01、D02（左上光源、1 px `K` 描邊、2 px 斜面、5 階色階、凹坑紋理，不用抖色、漸層、隨機點）
    - 本項所有網格每列字元數等於標示的圖寬

    視覺方向（D18）：

    | 項目 | 內容 |
    |---|---|
    | 主題 | 三種「改變盤面」的磚：爆炸清一片、彩虹清一色、傳送改變球的位置；玩家要一眼看出該不該撞、撞了會發生什麼 |
    | 色彩 | 爆炸＝炸藥褐（新增 5 色）；彩虹＝七色斜條紋加珍珠白邊框（不新增色）；傳送＝珍珠白邊框加深靛虛空與青色環（不新增色）；色碼見 D01 |
    | 版面 | 三種都用 32×16 磚體，記號置中；沒有數字，所以記號可以放大 |
    | 原則 | 1. 形狀記號為主、顏色為輔：爆炸＝放射星爆、彩虹＝稜鏡、傳送＝橢圓傳送門 2. 發動效果與磚的顏色脫鉤：爆炸、傳送用中性的火光與青白光；彩虹的挑色環用 D12 換色表換成被挑中的顏色 3. 效果短而有重點：爆炸 240 ms、彩虹 420 ms、傳送 240 ms |

    自我檢查（已換掉的通用預設）：
    - 爆炸不畫「黑色圓炸彈」：黑或深灰會與 D14 不可破壞磚混淆，玩家會誤以為它打不掉；改用褐色磚加明亮星爆
    - 傳送不用單一鮮豔色：色相空位已被七色、洋紅、電青、骨白佔滿，改用「暗虛空加明亮環」的形狀辨識
    - 爆炸用褐色，與橙（寶箱、橙磚）的差別在明度與飽和度；兩者同為暖色，下方「已知限制」如實寫出

    新增顏色（已加入 D01，標「D18 用」；新代號 `? - / ; :`，已用 Grep 確認原稿網格未使用；彩虹、傳送不新增色）：

    | 磚 | T1 | T2 | T3（主色） | T4 | T5 | 說明 |
    |---|---|---|---|---|---|---|
    | 爆炸（炸藥褐） | `?` #F0C9A4 | `-` #CC9262 | `/` #94603C | `;` #66402A | `:` #3E2517 | 新增 5 色 |
    | 彩虹 | 邊框用珍珠白 `W 1 2 3 4`（D15 球色）；條紋用七色 T2/T3/T4 | - | - | - | - | 不新增 |
    | 傳送 | 邊框用珍珠白 `W 1 2 3 4`；虛空用靛 `l`、`k`、`I`；環用青 `w`、`x`；漩渦用藍 `S` | - | - | - | - | 不新增 |

    色盤符號：數字 0~9、所有英文字母、`@ # % + = ~ * & $ ^ ! ? - / ; :` 已用完；尚可用 `_ < > , ( ) [ ] { } ' "`（避開 `|`、反引號、`.`）。若之後再增色，符號仍夠，但建議先確認轉檔工具對 `( ) [ ] { } ' "` 的處理。

    | 與誰分得開 | 做法 |
    |---|---|
    | 彩虹七色 | 爆炸褐色（色相約 24°，亮度 Y 108）比橙（Y 143、飽和高）暗而灰；彩虹磚是七色條紋，不是單色；傳送是暗靛虛空 |
    | 鋼灰擋板、D14 深灰藍 | 三種都有明確的亮部（星爆、彩虹、青環）；D14 是十字鋼條加黃銅螺栓、全磚暗灰藍，傳送的暗靛虛空只在中央橢圓內，周圍是珍珠白邊框 |
    | 魔王暗紫灰 | 魔王是 128×48 大磚 |
    | D17 洋紅／電青／骨白 | 爆炸褐、彩虹、傳送與它們色相不同（褐 24°、洋紅 325°、電青 175°、骨白低飽和淺色），記號也不同 |
    | 三種之間 | 爆炸（褐底黃白星爆）、彩虹（七色條紋加白稜鏡）、傳送（珍珠白框加暗靛橢圓與青環）；全是形狀不同 |

    已知限制（如實寫出，未用色盲模擬器驗證，請 QA 或使用者實機複核）：
    - 爆炸褐與橙在亮度差不大時可能偏近，靠放射星爆記號補強
    - 傳送磚與彩虹磚都用珍珠白邊框，靠中央內容（暗虛空橢圓對七色條紋）分辨；珍珠白邊框與 D15 球本體同色，但邊框只有 2 px 寬、球是 8×8 圓形，已在 D15 說明過接觸只有短暫瞬間
    - 傳送磚中央暗靛虛空接近背景（約 #0F0F1E），靠青環與珍珠白邊框撐出輪廓

    「無敵」期間（沿用 D14 `invincible_a_overlay`，不另畫）：

    | 檢查項目 | 結果（依網格推算，未實機驗證） |
    |---|---|
    | 疊加範圍 | 只蓋外框（第 0~2 欄、第 29~31 欄、第 0~2 列、第 13~15 列）；爆炸、彩虹的記號都在第 3~28 欄、第 3~12 列內，不會被蓋到；傳送磚不套無敵疊加（已決定，見最後一列） |
    | 爆炸磚 | 鋼灰外框對褐色邊界清楚 |
    | 彩虹磚 | 鋼灰外框（偏藍灰、較暗）取代珍珠白邊框，兩者差異可見；四角黃銅鉚釘清楚；內部條紋與稜鏡不受影響 |
    | 傳送磚 | **不套無敵外框**（已決定）：傳送磚不會被任何東西破壞，沒有「無敵」狀態可表示，不畫 `invincible_a_overlay`；磚面維持珍珠白邊框 |

    被擊中、破壞：

    | 磚 | 被擊中 | 破壞 F1~F4 |
    |---|---|---|
    | 爆炸 | 沿用 D12（`W` 規則），建議 60 ms；因為爆炸 F1 與被擊中同時開始，見下方時間表 | 爆炸時範圍內的磚（含自己）在爆炸 F3 開頭直接移除，**不播 D12 破壞 F1~F4**（被火球蓋住）；若爆炸磚被其他方式破壞（別的爆炸與彩虹不會破壞它，因為它是功能型磚），沿用 D12 通用 F1~F4，換成褐色階（下表） |
    | 彩虹 | 沿用 D12（`W` 規則），建議 60 ms | **已決定：只能用 1 次，用完就破壞**；沿用 D12 通用 F1~F4，換成珍珠白色階（下表），每幀 60 ms，與中選色的磚同時開始（見效果 2） |
    | 傳送 | 例外：不閃白（同 D14 的做法），被球碰到時直接播下方的吸入／噴出疊加圖當回饋 | 不需要：傳送磚不會被任何東西破壞（雷射、爆炸、彩虹、槍都不會；已決定），所以不畫破壞幀 |

    破壞幀換色對照表（母版 → 目標；D12 母版為紅色階 `h r R t o`）：

    | 目標 | T1（`h`） | T2（`r`） | T3（`R`） | T4（`t`） | T5（`o`） |
    |---|---|---|---|---|---|
    | 爆炸（炸藥褐） | `?` | `-` | `/` | `;` | `:` |
    | 彩虹（珍珠白） | `W` | `1` | `2` | `3` | `4` |

    圖寬：32　圖高：16
    爆炸磚底圖（id: explosion_brick）：
    ```text
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    K???WWWW?????????---?????????-/K
    K----------------------------/;K
    K?-///////////KKKK///////////;:K
    K?-////////KKKKrRKKKK////////;:K
    K?-/;;;////KRKKOdKKtK////;;;/;:K
    K?-//--///KKKOBABYdKKK////--/;:K
    K?-///////KrOBAWWBYdRK///////;:K
    K?-///////KROYBWBYYdtK///////;:K
    K?-///////KKKdYYCCbKKK///////;:K
    K?-/;;;////KRKKdbKKtK////;;;/;:K
    K?-//--////KKKKRtKKKK/////--/;:K
    K?-///////////KKKK///////////;:K
    K-/;;;;;;;;;;;;;;;;;;;;;;;;;;;:K
    K/;::::::::::::::::::::::::::::K
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    ```

    圖寬：32　圖高：16
    彩虹磚底圖（id: rainbow_brick）：
    ```text
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    KWWWWWWWWWWWWWWWWWWWWWWWWWWWW12K
    K111111111111111111111111111123K
    KW1rRRRtOdddbBYYYCFLLLHNUUUPX34K
    KW1RRRtOdddbBYYKCFLLLHNUUUPXI34K
    KW1RRtOdddbBYYKWKLLLHNUUUPXII34K
    KW1RtOdddbBYYKW12KLHNUUUPXIII34K
    KW1tOdddbBYYKW1123KNUUUPXIIIk34K
    KW1OdddbBYYKW112233KUUPXIIIkn34K
    KW1dddbBYYKW11222334KPXIIIknV34K
    KW1ddbBYYYKKKKKKKKKKKXIIIknVV34K
    KW1dbBYYYCFLLLHNUUUPXIIIknVVV34K
    KW1bBYYYCFLLLHNUUUPXIIIknVVVp34K
    K123333333333333333333333333334K
    K234444444444444444444444444444K
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    ```

    圖寬：32　圖高：16
    傳送磚底圖（id: teleport_brick）：
    ```text
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    KWWWWWWWWWWWWWWWWWWWWWWWWWWWW12K
    K111111111111111111111111111123K
    KW1kkklllllwwwwwwwwwwlllllkkk34K
    KW1lIIllwwwwwwwwwwwwwwwwlllII34K
    KW1lllwwwwKKKKKKKKKKKKxxxxlll34K
    KW1llwwwKKKKwwwwxxxxKKKKxxxll34K
    KW1lwwwKKKwwSSSWWSSSxxKKKxxxl34K
    KW1lwwwKKKwwSSSWWSSSxxKKKxxxl34K
    KW1llxxxKKKKxxxxxxxxKKKKxxxll34K
    KW1lllxxxxKKKKKKKKKKKKxxxxlll34K
    KW1kkkllxxxxxxxxxxxxxxxxllkkk34K
    KW1lIIlllllxxxxxxxxxxllllllII34K
    K123333333333333333333333333334K
    K234444444444444444444444444444K
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    ```

    各磚說明：

    | 磚 | 記號（顏色以外的辨識線索） | 位置（欄、列從 0 起算） | 材質與紋理 |
    |---|---|---|---|
    | 爆炸 | 放射星爆（8 向尖角，紅橙黃白由外而內，`K` 描邊），中心白熱 | 第 10~21 欄、第 3~12 列（12×10） | 炸藥褐 5 階斜面；左右兩側各 2 個凹坑（第 4~6 欄第 5~6 列、第 4~6 欄第 10~11 列；第 25~27 欄同列） |
    | 彩虹 | 白色稜鏡（三角形，`K` 描邊，珍珠白色階）置中，疊在七色斜條紋上 | 稜鏡第 10~20 欄、第 4~10 列（11×7） | 條紋：由左上到右下依序紅、橙、黃、綠、藍、靛、紫，每色 5 條斜線（第 3~28 欄、第 3~12 列內，斜線序號 ＝ 欄＋列−6）；每色第 1 條用 T2、中間 3 條用 T3、第 5 條用 T4，不用漸層；邊框為珍珠白 5 階斜面 |
    | 傳送 | 橢圓傳送門：青色橢圓環圍著 `K` 黑洞，洞中有藍色漩渦環與白色中心點 | 橢圓環第 4~27 欄、第 3~12 列；洞第 7~24 欄、第 5~10 列 | 邊框為珍珠白 5 階斜面；虛空底色深靛（`l`），四個角各 1 個凹坑（`k` 加 `I`） |

    ---

    效果 1：爆炸（3×3，96×48）

    規則：

    | 項目 | 規則 |
    |---|---|
    | 範圍 | 以爆炸磚所在格為中心的 3×3 格（周圍 8 格加自己），共 96×48；圖左上角 ＝ 爆炸磚左上角 x 減 32、y 減 16 |
    | 作用 | 範圍內**只破壞可破壞磚**（多層磚、寶箱、金幣、圓形磚；不論層數）；魔王、其他功能型磚（雷射、閃電、死神、傳送、彩虹）、不可破壞磚都不受影響（火光仍畫在它們上面，爆炸結束後它們還在）；範圍內的另一顆爆炸磚會被引爆（見下列「連鎖引爆」） |
    | 連鎖引爆 | 使用者 2026-10-26 決定：3×3 範圍內的另一顆爆炸磚會被引爆，以它為中心再爆一次 3×3，可以一直連鎖下去；每顆爆炸磚只觸發 1 次；連鎖的時間差（被引爆後多久開始爆）實作時確認，本稿不定數值 |
    | 次數 | 只能碰 1 次；碰到後自己也被破壞 |
    | 動畫 | 4 幀，每幀 60 ms，共 240 ms；每幀一張 96×48 圖，中心對齊爆炸磚 |
    | 與日後炸彈道具 | 完全分開：本效果用 `explosion_f1`~`f4`；日後炸彈道具另畫，不共用 |
    | 邊緣 | 範圍超出關卡區的部分裁切 |

    動畫與同步（磚何時被破壞）：

    | 幀 | 圖 id | 內容 | 時間 | 磚的狀態 |
    |---|---|---|---|---|
    | F1 | `explosion_f1` | 起爆閃光：約 66×31 的不規則小火球，白色核心（最寬 14 px、高 15 px），上下左右 4 條短火舌，四角各 1 顆十字火星（3×3，`Y`、`W`） | 0~60 ms | 爆炸磚播 D12 被擊中（`W`）；其他磚不動 |
    | F2 | `explosion_f2` | 火球擴大到約 88×44，輪廓凹凸不平（每一層色帶的邊界各自起伏）；上下左右 4 條火舌伸長（橫向到 88 px）；4 條斜向火舌從四角斜出；白核心最大（約 18×13） | 60~120 ms | 範圍內磚仍在，被火球逐漸蓋住 |
    | F3 | `explosion_f3` | 火球最大：主體約 82×38（比圖小，四邊與四角留空給火舌）；左右火舌伸到圖邊（橫向 94 px）；上下火舌各一條；4 條斜向火舌；白核心縮小（約 16×8）；飛出 8 塊磚塊碎片（`K`、`g`、`j`）：5×4 共 4 塊（左右兩側各 2 塊）、3×3 共 4 塊（上下兩側各 2 塊） | 120~180 ms | **範圍內的可破壞磚在本幀開頭（120 ms）直接移除**（含爆炸磚自己），不播 D12 破壞 F1~F4；掉落道具的判定也在此時 |
    | F4 | `explosion_f4` | 火球冷卻成煙：鋼灰三階雲團（`j g f`，凹凸輪廓）加 4 個分離的小煙團；中心剩一小塊餘燼（`R` 紅、`d` 橙）；沒有白色、沒有黃色；約 80×44 | 180~240 ms | 範圍內已無磚；煙畫在原位 |

    繪製順序（由下到上）：磚（含數字）→ D14 無敵疊加層 → 爆炸圖 → 球光暈 → 球本體；爆炸蓋在磚上，球永遠在爆炸之上

    我的判斷：磚在 F3 開頭移除，不是 F2。理由：F2 的火球還沒蓋滿 3×3 的四個角落，若在 F2 移除，角落的磚會在沒有火光時突然消失；F3 火球最大，磚「消失在火中」，玩家讀得出是爆炸直接破壞，不是一格一格敲掉。

    圖寬：96　圖高：48
    爆炸 F1（id: explosion_f1）：
    ```text
    ................................................................................................
    ................................................................................................
    ................................................................................................
    ................................................................................................
    ................................................................................................
    ................................................................................................
    ................................................................................................
    ................................................................................................
    ................................................................................................
    ..............................................oooo..............................................
    .............................................oRRRRo.............................................
    ............................................oRddddRo......................Y.....................
    ........................................ooRRddYYddRRoo...................YWY....................
    ......................Y.............ooRRRdddYYYYYYdddRRRoo................Y.....................
    .....................YWY.........oooRRRddddYYYYYYYYYYddddRRRooo.................................
    ......................Y........oooRRRRddddYYYYYYYYYYYYddddRRRRooo...............................
    .............................oooRRRRRdddddYYYYYYWWYYYYYYdddddRRRRRooo...........................
    ..............................oooRRRRdddddYYYYYWWWWYYYYYdddddRRRRooo............................
    ..........................oooRRRRRddddddYYYYYWWWWWWYYYYYddddddRRRRRooo..........................
    ........................ooooRRRRRddddddYYYYYWWWWWWWWYYYYYddddddRRRRRoooo........................
    ........................ooooRRRRRdddddYYYYWWWWWWWWWWYYYYdddddRRRRRoooo..........................
    .....................ooooRRRRRRddddddYYYYWWWWWWWWWWWWYYYYddddddRRRRRRoooo.......................
    ...............ooooRRRRRRRRRddddddddddYYYYWWWWWWWWWWWWYYYYddddddddddRRRRRRRRRoooo...............
    ...............oooRRRRRRRRRddddddddddYYYYWWWWWWWWWWWWWWYYYYddddddddddRRRRRRRRRooo...............
    ................oooRRRRRRRRRdddddddddYYYYWWWWWWWWWWWWWWYYYYdddddddddRRRRRRRRRooo................
    ................oooooRRRRRRRRRdddddddddYYYYWWWWWWWWWWWWYYYYdddddddddRRRRRRRRRooooo..............
    ........................ooooRRRRRRddddddYYYYWWWWWWWWWWYYYYddddddRRRRRRoooo......................
    .........................ooooRRRRRddddddYYYYWWWWWWWWYYYYddddddRRRRRoooo.........................
    ........................ooooRRRRRRddddddYYYYYWWWWWWYYYYYddddddRRRRRRoooo........................
    ..........................ooooRRRRRdddddYYYYYWWWWYYYYYdddddRRRRRoooo............................
    ............................oooRRRRRdddddYYYYYWWYYYYYdddddRRRRRooo..............................
    ............................ooooRRRRRdddddYYYYYYYYYYYYdddddRRRRRoooo............................
    ...............................oooRRRRRddddYYYYYYYYYYddddRRRRRooo...............................
    ........................Y........oooRRRRddddYYYYYYYYddddRRRRooo.................................
    .......................YWY............ooRRRddddYYYYddddRRRoo...........Y........................
    ........................Y................ooRRdddYYdddRRoo.............YWY.......................
    ............................................ooRddddRoo.................Y........................
    .............................................ooRRRRoo...........................................
    ..............................................ooRRoo............................................
    ...............................................oooo.............................................
    ................................................................................................
    ................................................................................................
    ................................................................................................
    ................................................................................................
    ................................................................................................
    ................................................................................................
    ................................................................................................
    ................................................................................................
    ```

    圖寬：96　圖高：48
    爆炸 F2（id: explosion_f2）：
    ```text
    ................................................................................................
    ................................................................................................
    .........oo...................................oooo..............................................
    ...........oRo...............................oRRRRo...................................oo........
    .............oRdRo..........................oRddddRo...............................oRo..........
    ................oRdRo......................oRddYYddRo...........................oRdRo...........
    ...................oRdRo................ooRddYYYYddRoo.......................oRdRo..............
    ......................oRdRo.......ooRRRddddYYYYYYYYddddRRRoo..............oRdRo.................
    ............................oooRRRRdddddYYYYYYYYYYYYYYdddddRRRRooo.....oRdRo....................
    ........................oooRRRRRddddddYYYYYYYYYYYYYYYYYYYYddddddRRRRRooo........................
    .....................oooRRRRRRddddddYYYYYYYYYYYYYYYYYYYYYYYYddddddRRRRRRooo.....................
    .......................oooRRRRRRddddddYYYYYYYYYYYYYYYYYYYYYYddddddRRRRRRooo.....................
    ...................oooRRRRRRRdddddddYYYYYYYYYYYYYYYYYYYYYYYYYYdddddddRRRRRRRooo.................
    ...................oooRRRRRRRddddddYYYYYYYYYYYYYYYYYYYYYYYYYYddddddRRRRRRRooo...................
    ................ooooRRRRRRRdddddddYYYYYYYYYYYYYYYYYYYYYYYYYYYYdddddddRRRRRRRoooo................
    ................ooooRRRRRRdddddddYYYYYYYYYYYYYYYYYYYYYYYYYYYYdddddddRRRRRRoooo..................
    ..............oooRRRRRRRddddddddYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYddddddddRRRRRRRooo................
    ..............ooooRRRRRRRdddddddYYYYYYYYYYYYYYWWWWYYYYYYYYYYYYYYdddddddRRRRRRRoooo..............
    ...............ooooRRRRRRRddddddYYYYYYYYYYYYYWWWWWWYYYYYYYYYYYYYddddddRRRRRRRoooo...............
    ..............ooooRRRRRRRdddddddYYYYYYYYYYYYWWWWWWWWWWYYYYYYYYYYYYdddddddRRRRRRRoooo............
    .............ooooRRRRRRRddddddddYYYYYYYYYYYWWWWWWWWWWWWYYYYYYYYYYYddddddddRRRRRRRoooo...........
    ...........ooooRRRRRRRddddddddYYYYYYYYYYYWWWWWWWWWWWWWWYYYYYYYYYYYddddddddRRRRRRRoooo...........
    ....ooooooRRRRRRRRRRddddddddddYYYYYYYYYYWWWWWWWWWWWWWWWWYYYYYYYYYYddddddddddRRRRRRRRRRoooooo....
    ....oooooRRRRRRRRRRddddddddddYYYYYYYYYYWWWWWWWWWWWWWWWWWWYYYYYYYYYYddddddddddRRRRRRRRRRooooo....
    .....oooooRRRRRRRRRRdddddddddYYYYYYYYYYWWWWWWWWWWWWWWWWWWYYYYYYYYYYdddddddddRRRRRRRRRRooooo.....
    .....oooooooRRRRRRRRRRdddddddddYYYYYYYYYYWWWWWWWWWWWWWWWWYYYYYYYYYYdddddddddRRRRRRRRRRooooooo...
    ............ooooRRRRRRRddddddddYYYYYYYYYYYYWWWWWWWWWWWWYYYYYYYYYYYYddddddddRRRRRRRoooo..........
    ............ooooRRRRRRRddddddddYYYYYYYYYYYYWWWWWWWWWWYYYYYYYYYYYYddddddddRRRRRRRoooo............
    .............ooooRRRRRRRdddddddYYYYYYYYYYYYYYWWWWWWYYYYYYYYYYYYYYdddddddRRRRRRRoooo.............
    .............ooooRRRRRRRdddddddYYYYYYYYYYYYYYWWWWYYYYYYYYYYYYYYdddddddRRRRRRRoooo...............
    ..............ooooRRRRRRRdddddddYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYdddddddRRRRRRRoooo................
    ..............ooooRRRRRRRddddddddYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYddddddddRRRRRRRoooo..............
    .................ooooRRRRRRdddddddYYYYYYYYYYYYYYYYYYYYYYYYYYYYdddddddRRRRRRoooo.................
    .................ooooRRRRRRRddddddddYYYYYYYYYYYYYYYYYYYYYYYYYYddddddddRRRRRRRoooo...............
    ....................oooRRRRRRRddddddYYYYYYYYYYYYYYYYYYYYYYYYYYddddddRRRRRRRooo..................
    ..................ooooRRRRRRRdddddddYYYYYYYYYYYYYYYYYYYYYYYYdddddddRRRRRRRoooo..................
    ......................oooRRRRRRddddddYYYYYYYYYYYYYYYYYYYYYYddddddRRRRRRooo......................
    ....................oooRRRRRRRdddddddYYYYYYYYYYYYYYYYYYYYdddddddRRRRRRRooo......................
    .......................oooRRRRRddddddYYYYYYYYYYYYYYYYYYYYddddddRRRRRooo.........................
    .............................oooRRRRdddddYYYYYYYYYYYYYYdddddRRRRooo.............................
    ..........................oRdRo....ooRRRddddYYYYYYYYddddRRRoo...oRdRo...........................
    .......................oRdRo..............ooRddYYYYddRoo...........oRdRo........................
    ....................oRdRo...................oRddYYddRo................oRdRo.....................
    .................oRdRo.......................oRddddRo....................oRdRo..................
    ..............oRo.............................oRRRRo........................oRo.................
    ............oo.................................oooo............................oo...............
    ................................................................................................
    ................................................................................................
    ```

    圖寬：96　圖高：48
    爆炸 F3（id: explosion_f3）：
    ```text
    ...oo.................KKK....................oooo.....................KKK.......................
    .....oRo..............KgK...................oRRRRo....................KgK................oo.....
    .......oRdRo..........KKK..................oRddddRo...................KKK.............oRo.......
    .........oRdRo............................oRddYYddRo...............................oRdRo........
    ...........oRdRo...................ooRRRdddYYYYYYdddRRRoo.......................oRdRo...........
    .............oRdRo..........ooRRRRdddddYYYYYYYYYYYYYYdddddRRRRoo.............oRdRo..............
    ...............oRdRo...ooRRRRRdddddddYYYYYYYYYYYYYYYYYYYYdddddddRRRRRoo...oRdRo.................
    ...................ooRRRRRddddddddYYYYYYYYYYYYYYYYYYYYYYYYYYddddddddRRRRRoo.....................
    ..................ooRRRRRddddddddYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYddddddddRRRRRoo..................
    ..............oooRRRRRRdddddddddYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYdddddddddRRRRRRooo..............
    .................oooRRRRRddddddddYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYddddddddRRRRRooo...............
    ..............oooRRRRRRdddddddddYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYdddddddddRRRRRRooo............
    ............oooRRRRRRddddddddddYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYddddddddddRRRRRRooo..KKKKK...
    ..KKKKK........oooRRRRRdddddddddYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYdddddddddRRRRRooo...KgggK...
    ..KgggK.....oooRRRRRRddddddddddYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYddddddddddRRRRRRoooKgjjK...
    ..KgjjK...oooRRRRRRddddddddddYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYddddddddddRRRRRRoooKKKKK...
    ..KKKKK....oooRRRRRRdddddddddYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYdddddddddRRRRRRooo.........
    ........oooRRRRRRddddddddddYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYddddddddddRRRRRRooo........
    .........oooRRRRRRdddddddddYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYdddddddddRRRRRRooo.........
    ......oooRRRRRRddddddddddYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYddddddddddRRRRRRooo........
    .....oooRRRRRRdddddddddddYYYYYYYYYYYYYYYYYYYYWWWWYYYYYYYYYYYYYYYYYYYYdddddddddddRRRRRRooo.......
    ...ooooRRRRRRdddddddddddYYYYYYYYYYYYYYYYYYWWWWWWWWWWYYYYYYYYYYYYYYYYYYdddddddddddRRRRRRoooo.....
    .ooooRRRRRRRddddddddddddYYYYYYYYYYYYYYYYYWWWWWWWWWWWWWWYYYYYYYYYYYYYYYYYddddddddddddRRRRRRRoooo.
    .oooRRRRRRRdddddddddddddYYYYYYYYYYYYYYYYWWWWWWWWWWWWWWWWYYYYYYYYYYYYYYYYdddddddddddddRRRRRRRooo.
    .ooRRRRRRRRdddddddddddddYYYYYYYYYYYYYYYYWWWWWWWWWWWWWWWWYYYYYYYYYYYYYYYYdddddddddddddRRRRRRRRoo.
    ..oooooRRRRRRRdddddddddddYYYYYYYYYYYYYYYYYWWWWWWWWWWWWYYYYYYYYYYYYYYYYYdddddddddddddRRRRRRRooooo
    ......ooooRRRRRRdddddddddddYYYYYYYYYYYYYYYYYYWWWWWWWWYYYYYYYYYYYYYYYYYYdddddddddddRRRRRRoooo....
    .......ooooRRRRRdddddddddddYYYYYYYYYYYYYYYYYYYYWWYYYYYYYYYYYYYYYYYYYYdddddddddddRRRRRoooo.......
    ......ooooRRRRRRdddddddddddYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYdddddddddddRRRRRRoooo......
    ........oooRRRRRRddddddddddYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYddddddddddRRRRRRooo..........
    .......ooooRRRRRRdddddddddddYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYdddddddddddRRRRRRoooo.........
    ........ooooRRRRRRdddddddddYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYdddddddddRRRRRRoooo...KKKKK....
    ..KKKKK...oooRRRRRRdddddddddYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYdddddddddRRRRRRooo.....KgggK....
    ..KgggK...ooooRRRRRRddddddddddYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYddddddddddRRRRRRoooo...KgjjK....
    ..KgjjK......oooRRRRRRdddddddddYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYdddddddddRRRRRRooo......KKKKK....
    ..KKKKK........oooRRRRRRdddddddddYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYdddddddddRRRRRRooo...............
    .................oooRRRRRRddddddddYYYYYYYYYYYYYYYYYYYYYYYYYYYYddddddddRRRRRRooo.................
    .................ooooRRRRRRdddddddddYYYYYYYYYYYYYYYYYYYYYYYYYYdddddddddRRRRRRoooo...............
    .....................oooRRRRRRddddddddYYYYYYYYYYYYYYYYYYYYYYddddddddRRRRRRooo...................
    .........................oooRRRRRdddddddYYYYYYYYYYYYYYYYYYdddddddRRRRRooo.......................
    ............................ooRRRRRddddddYYYYYYYYYYYYYYddddddRRRRRoo..oRdRo.....................
    ......................oRdRo.......ooRRRdddddYYYYYYYYdddddRRRoo...........oRdRo..................
    ...................oRdRo................ooRRdddYYdddRRoo....................oRdRo...............
    ................oRdRo......................ooRRddddRRoo.......................oRdRo.............
    .............oRdRo..........................ooRRddRRoo............................oRdRo.........
    ..........oRdRo.............KKK..............ooRRRRoo.............KKK................oRo........
    .......oRo..................KgK...............ooRRoo..............KgK...................oRo.....
    .....oo.....................KKK................oooo...............KKK......................oo...
    ```

    圖寬：96　圖高：48
    爆炸 F4（id: explosion_f4）：
    ```text
    ................................................................................................
    ................................................................................................
    .........................................jjggggjj...............................................
    ....................................jjgggffffffffgggjj.......................jjjj...............
    ................................jjjgggffffffffffffffgggjjj..................jggggj..............
    ........jjjj..................jjjggggffffffffffffffffffggggjjj..............jgffgj..............
    .......jggggj....................jjjggggffffffffffffffffggggjjj.............jggggj..............
    ......jggffggj.................jjjjggggffffffffffffffffffffffggggjjjj........jjjj...............
    ......jggffggj.............jjjjgggggffffffffffffffffffffffffffffffgggggjjjj.....................
    .......jggggj...........jjjjgggggffffffffffffffffffffffffffffffffffgggggjjjj....................
    ........jjjj............jjjjgggggffffffffffffffffffffffffffffffgggggjjjj........................
    ...............jjjjggggggffffffffffffffffffffffffffffffffffffffffggggggjjjj.....................
    .............jjjjgggggggffffffffffffffffffffffffffffffffffffffffffffgggggggjjjj.................
    .................jjjjggggggffffffffffffffffffffffffffffffffffffffffffggggggjjjj.................
    ..............jjjjgggggggffffffffffffffffffffffffffffffffffffffffffffffffgggggggjjjj............
    ............jjjjgggggggffffffffffffffffffffffffffffffffffffffffffffffffffgggggggjjjj............
    .............jjjjgggggggffffffffffffffffffffffffffffffffffffffffffffffgggggggjjjj...............
    ...........jjjjgggggggffffffffffffffffffffffffffffffffffffffffffffffffffffgggggggjjjj...........
    ...........jjjjgggggggfffffffffffffffffffffffffRRRRfffffffffffffffffffffffffgggggggjjjj.........
    ............jjjjgggggggffffffffffffffffffffffRRRRRRRRffffffffffffffffffffffgggggggjjjj..........
    .........jjjjgggggggffffffffffffffffffffffRRRRRRRRRRRRffffffffffffffffffffffgggggggjjjj.........
    ..........jjjjgggggggffffffffffffffffffffRRRRRRddRRRRRRffffffffffffffffffffgggggggjjjj..........
    ........jjjjggggggggffffffffffffffffffffRRRRRRddddRRRRRRffffffffffffffffffffggggggggjjjj........
    .........jjjjgggggggffffffffffffffffffffRRRRRRddddRRRRRRffffffffffffffffffffgggggggjjjj.........
    .........jjjjggggggggfffffffffffffffffffRRRRRRddddRRRRRRfffffffffffffffffffggggggggjjjj.........
    ........jjjjggggggggfffffffffffffffffffffRRRRRRddRRRRRRfffffffffffffffffffffggggggggjjjj........
    ............jjjjgggggggffffffffffffffffffffRRRRRRRRRRRRffffffffffffffffffffgggggggjjjj..........
    ...........jjjjggggggggffffffffffffffffffffffRRRRRRRRffffffffffffffffffffffggggggggjjjj.........
    ..............jjjjgggggggfffffffffffffffffffffffRRRRfffffffffffffffffffffffgggggggjjjj..........
    .............jjjjgggggggffffffffffffffffffffffffffffffffffffffffffffffffffffgggggggjjjj.........
    ...............jjjjggggggffffffffffffffffffffffffffffffffffffffffffffffffggggggjjjj.............
    .............jjjjgggggggffffffffffffffffffffffffffffffffffffffffffffffffgggggggjjjj.............
    ...............jjjjggggggffffffffffffffffffffffffffffffffffffffffffffggggggjjjj.................
    .............jjjjgggggggffffffffffffffffffffffffffffffffffffffffffffgggggggjjjj.................
    .................jjjjggggggffffffffffffffffffffffffffffffffffffffggggggjjjj.....................
    .................jjjjggggggffffffffffffffffffffffffffffffffffffffffggggggjjjj...................
    ......................jjjjggggggffffffffffffffffffffffffffffffffggggggjjjj..........jjjj........
    ......................jjjjggggggffffffffffffffffffffffffffffffffffggggggjjjj.......jggggj.......
    ...........jjjj.............jjjjggggggffffffffffffffffffffffffffggggjjjj..........jggffggj......
    ..........jggggj...........jjjjggggggffffffffffffffffffffffffffggggggjjjj.........jggffggj......
    ..........jgffgj...............jjjjgggggffffffffffffffffffgggggjjjj................jggggj.......
    ..........jggggj.............jjjjgggggffffffffffffffffffffgggggjjjj.................jjjj........
    ...........jjjj..................jjjggggffffffffffffffggggjjj...................................
    ......................................jjgggffffffffgggjj........................................
    ..........................................jjggffggjj............................................
    ............................................jjggjj..............................................
    ................................................................................................
    ................................................................................................
    ```

    爆炸圖的組裝與色階（重畫版；舊版 F3 是一整塊白色圓角方塊，已作廢取代）：
    - F1~F4 都是完整 96×48 圖，以爆炸磚中心對齊；中心在第 47、48 欄之間與第 23、24 列之間
    - 火光用 5 階暖色，由外到內：暗 `o`（#7E1A20）→ 紅 `R`（#C22A30）→ 橙 `d`（#E07A1E）→ 黃 `Y`（#F7D84A）→ 白 `W`（#FFFFFF）；**白色只用在核心**（F1 最寬 14 px、F2 最寬 18 px、F3 最寬 16 px），四幀的外圍都沒有白
    - 層次靠「每一層色帶的邊界各自起伏」做出，不是同心橢圓；不用抖色、隨機點、漸層
    - 放射狀火舌：F1 上下左右 4 條短火舌；F2、F3 另加 4 條斜向火舌（各自帶 `o R d` 色階，與主體留 2~4 px 空隙）
    - 碎片：F3 的 `K`、`g`、`j` 小塊是飛出的磚塊碎片（中性色，適用任何顏色的磚）；F1 的十字火星用 `Y`、`W`
    - F4 煙：外 `j`（#363D4F）、中 `g`（#566077）、內 `f`（#8A93A8）三階鋼灰，中心餘燼 `R`、`d`；共用既有色，不新增顏色
    - 與火焰色分開的原因：煙用冷灰，才不會被誤讀成還在燃燒；爆炸磚褐色（D18 新增色）不用於效果，避免與磚面混淆

    ---

    效果 2：彩虹磚發動（挑色環加同色磚一起碎）

    規則：

    | 項目 | 規則 |
    |---|---|
    | 挑色 | 遊戲程式**只從畫面上現有的多層磚顏色**（紅橙黃綠藍靛紫）中隨機挑 1 色；寶箱、金幣、圓形磚不屬於七色，不會被挑；魔王、功能型磚、不可破壞磚也不會被挑；挑出的顏色以下稱「中選色」 |
    | 何謂同色 | 同一色不論有沒有數字都算同色（紅色 1 層與紅色 8 層〔紅＋數字 1〕一起破壞）；層數不影響 |
    | 如何表現「挑中某一色」 | 彩虹磚周圍播 3 幀「挑色環」`rainbow_pick_f1`~`f3`（48×32，置中於彩虹磚，圖左上角 ＝ 磚左上角減 8、減 8）；挑色環用 D12 紅色階 `h r R t o` 繪製，並依 D12 換色對照表換成中選色（`W` 不變）；玩家看到「環的顏色」＝被挑中的顏色 |
    | 如何表現「該色磚一起被破壞」 | 所有中選色的磚各自疊上 2 幀「選中閃光」`rainbow_target_f1`~`f2`（32×16，中性白黃，任何顏色的磚都可套用，不需換色），然後同時播 D12 破壞 F1~F4（各自以自己的色階）；因為是同一時刻全部開始，玩家會看到畫面上同一種顏色一起碎掉 |
    | 換色方式 | 挑色環的換色由轉檔工具預先產生 7 色 × 3 幀 ＝ 21 張（或遊戲執行時換色，兩者擇一，結果相同）；選中閃光不換色 |
    | 中選色的磚 | 不論層數直接破壞；掉落道具的判定在破壞開始時（180 ms） |
    | 彩虹磚自己 | **已決定：只能用 1 次，用完就破壞**；與中選色的磚同時播 D12 破壞 F1~F4（珍珠白色階）；破壞幀有 4 張 |
    | 畫面上沒有多層磚 | **已決定**（使用者 2026-10-26）：不破壞任何磚，彩虹磚直接破壞（播珍珠白破壞幀 F1~F4）；不播挑色環，也不播選中閃光；不產生白色版 |

    動畫與同步（共 420 ms：效果 180 ms ＋ 破壞 240 ms）：

    | 時間 | 彩虹磚 | 中選色的磚 |
    |---|---|---|
    | 0~60 ms | 被擊中（D12，`W`）；`rainbow_pick_f1`（緊貼的環） | 不變 |
    | 60~120 ms | `rainbow_pick_f2`（環擴大加四邊亮點） | `rainbow_target_f1`（大星光） |
    | 120~180 ms | `rainbow_pick_f3`（環消失，剩四角星光） | `rainbow_target_f2`（小星光） |
    | 180~420 ms | 自己破壞：D12 破壞 F1~F4（珍珠白色階，每幀 60 ms） | 同時播 D12 破壞 F1~F4（每幀 60 ms）；層數歸零，掉落道具判定 |

    畫面上沒有多層磚時的流程（各幀時間沿用上表既有數值：被擊中 1 幀 60 ms、破壞每幀 60 ms）：

    | 時間 | 彩虹磚 | 其他磚 |
    |---|---|---|
    | 0~60 ms | 被擊中（D12，`W`）；不播挑色環 | 不變；不播選中閃光 |
    | 60~300 ms | 直接播 D12 破壞 F1~F4（珍珠白色階，每幀 60 ms） | 不變（不破壞任何磚） |

    繪製順序（由下到上）：磚（含數字）→ D14 無敵疊加層 → 選中閃光與挑色環 → 球光暈 → 球本體

    挑色環換色對照表（母版 → 目標；與 D12 同表，另列出供轉檔工具）：

    | 中選色 | `h` | `r` | `R` | `t` | `o` |
    |---|---|---|---|---|---|
    | 紅 | `h` | `r` | `R` | `t` | `o` |
    | 橙 | `a` | `O` | `d` | `b` | `c` |
    | 黃 | `A` | `B` | `Y` | `C` | `D` |
    | 綠 | `E` | `F` | `L` | `H` | `J` |
    | 藍 | `M` | `N` | `U` | `P` | `S` |
    | 靛 | `T` | `X` | `I` | `k` | `l` |
    | 紫 | `m` | `n` | `V` | `p` | `q` |

    圖寬：48　圖高：32
    彩虹挑色環 F1（id: rainbow_pick_f1）：
    ```text
    ................................................
    ................................................
    ................................................
    ................................................
    .....hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh.....
    ....rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr....
    ....hr....................................to....
    ....hr....................................to....
    ....hr....................................to....
    ....hr....................................to....
    ....hr....................................to....
    ....hr....................................to....
    ....hr....................................to....
    ....hr....................................to....
    ....hr....................................to....
    ....hr....................................to....
    ....hr....................................to....
    ....hr....................................to....
    ....hr....................................to....
    ....hr....................................to....
    ....hr....................................to....
    ....hr....................................to....
    ....hr....................................to....
    ....hr....................................to....
    ....hr....................................to....
    ....hr....................................to....
    ....hrtttttttttttttttttttttttttttttttttttttt....
    .....rooooooooooooooooooooooooooooooooooooo.....
    ................................................
    ................................................
    ................................................
    ................................................
    ```

    圖寬：48　圖高：32
    彩虹挑色環 F2（id: rainbow_pick_f2）：
    ```text
    ................................................
    ..hhhhhhhhhhhhhhhhhhhhhWWhhhhhhhhhhhhhhhhhhhhh..
    .rrrrrrrrrrrrrrrrrrrrrrWWrrrrrrrrrrrrrrrrrrrrrr.
    .hr..........................................to.
    .hr..........................................to.
    .hr..........................................to.
    .hr..........................................to.
    .hr..........................................to.
    .hr..........................................to.
    .hr..........................................to.
    .hr..........................................to.
    .hr..........................................to.
    .hr..........................................to.
    .hr..........................................to.
    .hr..........................................to.
    .WW..........................................WW.
    .WW..........................................WW.
    .hr..........................................to.
    .hr..........................................to.
    .hr..........................................to.
    .hr..........................................to.
    .hr..........................................to.
    .hr..........................................to.
    .hr..........................................to.
    .hr..........................................to.
    .hr..........................................to.
    .hr..........................................to.
    .hr..........................................to.
    .hr..........................................to.
    .hrttttttttttttttttttttWWtttttttttttttttttttttt.
    ..rooooooooooooooooooooWWooooooooooooooooooooo..
    ................................................
    ```

    圖寬：48　圖高：32
    彩虹挑色環 F3（id: rainbow_pick_f3）：
    ```text
    ................................................
    ................................................
    ....h......................................h....
    ....r......................................r....
    ..hrWrh..................................hrWrh..
    ....r......................................r....
    ....h......................................h....
    ................................................
    ................................................
    ................................................
    ................................................
    ................................................
    ................................................
    ................................................
    ................................................
    ................................................
    ................................................
    ................................................
    ................................................
    ................................................
    ................................................
    ................................................
    ................................................
    ................................................
    ................................................
    ....h......................................h....
    ....r......................................r....
    ..hrWrh..................................hrWrh..
    ....r......................................r....
    ....h......................................h....
    ................................................
    ................................................
    ```

    圖寬：32　圖高：16
    彩虹選中閃光 F1（id: rainbow_target_f1）：
    ```text
    ................................
    ................................
    ................................
    ..........A.....................
    ..........W.....................
    ........AWWWA...................
    ..........W.....................
    ..........A.....................
    .....................A..........
    .....................W..........
    ...................AWWWA........
    .....................W..........
    .....................A..........
    ................................
    ................................
    ................................
    ```

    圖寬：32　圖高：16
    彩虹選中閃光 F2（id: rainbow_target_f2）：
    ```text
    ................................
    ................................
    ................................
    ................................
    ..........W..........W..........
    .........WAW........WAW.........
    ..........W..........W..........
    ................................
    ................................
    ..........W..........W..........
    .........WAW........WAW.........
    ..........W..........W..........
    ................................
    ................................
    ................................
    ................................
    ```

    ---

    效果 3：傳送（入口吸入、出口噴出）

    規則：

    | 項目 | 規則 |
    |---|---|
    | 入口與出口 | 所有傳送磚外觀相同；球碰到的那一塊為入口，其餘為出口（遊戲程式隨機選 1 個），出口球出現後的角度隨機（程式處理） |
    | 入口「吸入」 | 入口磚疊 `teleport_in_f1`~`f4`（32×16，環由大縮小到中心閃光，青白色）；球同時播 D15 `ball_vanish_f1`~`f4`（球縮小消失） |
    | 出口「噴出」 | 出口磚疊 `teleport_in_f4`~`f1`（吸入圖倒著播：中心閃光擴大成環，同一組圖，不另畫）；球播 `ball_vanish_f4`~`f1`（倒播 D15 消失圖＝球從無到有放大）；倒播結束後球以正常圖出現 |
    | 球的位置 | 出口的球出現在出口磚中心；球在入口消失期間與出口出現期間不與任何磚碰撞（程式處理） |
    | 被擊中 | 傳送磚不閃白（同 D14 的例外）：被球碰到時直接播吸入／噴出疊加圖當回饋，因為青白環疊在全白磚上看不見 |
    | 破壞 | 不需要：傳送磚不會被任何東西破壞（雷射、爆炸、彩虹、槍都不會；已決定），所以不畫破壞幀 |
    | 無敵外框 | 不套（已決定）：不畫 D14 `invincible_a_overlay` |
    | 噴出效果 | 確定用吸入 4 幀倒播，不另外畫（已決定） |
    | 疊加位置 | 疊加層只動洞內（第 7~24 欄、第 5~10 列），邊框與虛空底色不變，逐像素對齊，同 D14 疊加規則 |

    動畫與同步（球約 480 ms 不在畫面上，已決定可接受；數值實測後再調）：

    | 時間 | 入口磚 | 球（入口） | 出口磚 | 球（出口） |
    |---|---|---|---|---|
    | 0~60 ms | `teleport_in_f1` | `ball_vanish_f1` | 不變 | 不存在 |
    | 60~120 ms | `teleport_in_f2` | `ball_vanish_f2` | 不變 | 不存在 |
    | 120~180 ms | `teleport_in_f3` | `ball_vanish_f3` | 不變 | 不存在 |
    | 180~240 ms | `teleport_in_f4` | `ball_vanish_f4` | 不變 | 不存在 |
    | 240~300 ms | 不變 | 已消失 | `teleport_in_f4`（噴出 F1） | `ball_vanish_f4` |
    | 300~360 ms | 不變 | 已消失 | `teleport_in_f3`（噴出 F2） | `ball_vanish_f3` |
    | 360~420 ms | 不變 | 已消失 | `teleport_in_f2`（噴出 F3） | `ball_vanish_f2` |
    | 420~480 ms | 不變 | 已消失 | `teleport_in_f1`（噴出 F4） | `ball_vanish_f1` |
    | 480 ms 起 | 不變 | - | 不變 | 球正常圖，以隨機角度飛出 |

    繪製順序（由下到上）：磚（含數字）→ D14 無敵疊加層 → 傳送疊加圖 → 球光暈 → 球本體（含消失／出現動畫）

    圖寬：32　圖高：16
    傳送吸入 F1（id: teleport_in_f1）：
    ```text
    ................................
    ................................
    ................................
    ................................
    ................................
    ...........wwwwwwwwww...........
    .........ww..........ww.........
    ........w..xx......xx..w........
    ........w..xx......xx..w........
    .........ww..........ww.........
    ...........wwwwwwwwww...........
    ................................
    ................................
    ................................
    ................................
    ................................
    ```

    圖寬：32　圖高：16
    傳送吸入 F2（id: teleport_in_f2）：
    ```text
    ................................
    ................................
    ................................
    ................................
    ................................
    ...........xxxxxxxxxx...........
    .........xx..WWWWWW..xx.........
    ........x..WW......WW..x........
    ........x..WW......WW..x........
    .........xx..WWWWWW..xx.........
    ...........xxxxxxxxxx...........
    ................................
    ................................
    ................................
    ................................
    ................................
    ```

    圖寬：32　圖高：16
    傳送吸入 F3（id: teleport_in_f3）：
    ```text
    ................................
    ................................
    ................................
    ................................
    ................................
    ................................
    .............xxxxxx.............
    ...........xxWWWWWWxx...........
    ...........xxWWWWWWxx...........
    .............xxxxxx.............
    ................................
    ................................
    ................................
    ................................
    ................................
    ................................
    ```

    圖寬：32　圖高：16
    傳送吸入 F4（id: teleport_in_f4）：
    ```text
    ................................
    ................................
    ................................
    ................................
    ................................
    ................................
    ...............ww...............
    .............wwWWww.............
    .............wwWWww.............
    ...............ww...............
    ................................
    ................................
    ................................
    ................................
    ................................
    ................................
    ```

    需轉檔工具新增的自動產生規則（規則寫死在轉檔工具；要修改請通知 PM，由工程師改工具）：

    | 項目 | 規則 |
    |---|---|
    | 爆炸 | 工具輸出 `explosion_f1`~`f4`（96×48，本稿網格）；位置規則（左上角 ＝ 爆炸磚左上角 x 減 32、y 減 16）由遊戲程式處理 |
    | 爆炸磚破壞 | 依上方換色表產生 D12 通用 F1~F4（褐色階），4 張 |
    | 彩虹 | 輸出彩虹磚底圖；被擊中圖套 D12 `W` 規則；彩虹磚自己破壞 F1~F4 換珍珠白色階，4 張；挑色環 3 幀 × 7 色 ＝ 21 張（依 D12 換色表）；選中閃光 2 張不換色 |
    | 傳送 | 輸出傳送磚底圖；吸入 4 幀；噴出由程式倒播吸入圖，不需另輸出 |
    | 被擊中 | 爆炸、彩虹各 1 張（套 D12 `W` 規則）；傳送不產生（例外） |
    | 疊加 | 傳送疊加層沿用 D14 疊加規則：非 `.` 像素覆蓋磚的對應像素 |

    給工程師的需求：
    - 不需要新的後端資料或 API
    - 遊戲程式要處理：爆炸 3×3 範圍判定（只破壞可破壞磚，魔王、其他功能型磚、不可破壞磚跳過；範圍內的另一顆爆炸磚引爆並連鎖，每顆只觸發 1 次，連鎖時間差實作時確認）與 F3 開頭移除；爆炸只能觸發 1 次；彩虹只能用 1 次（用完自己破壞）、隨機挑色（來源只有畫面上現有的多層磚顏色，同色不論有無數字；寶箱、金幣、圓形磚、魔王、功能型磚、不可破壞磚都不納入）、畫面上沒有多層磚時彩虹磚直接破壞（不播挑色環與選中閃光）、挑色環換色、同色磚同時開始破壞；傳送磚不畫無敵外框、不被任何東西破壞；傳送入口出口的隨機挑選、球消失與出現期間不碰撞、出現位置與隨機角度、吸入與倒播的同步；三種功能型磚不受球攻擊力加成、每次碰觸只觸發一次效果
    - 繪製順序：磚 → 無敵疊加 → 效果（爆炸、挑色環、選中閃光、傳送疊加）→ 球光暈 → 球本體

    已決定（使用者，已寫進上方規則；不再列為待決定）：
    - 彩虹磚只能用 1 次，用完就破壞（珍珠白破壞幀）
    - 彩虹挑色只從畫面上現有的多層磚顏色挑；寶箱、金幣、圓形磚、魔王、功能型磚、不可破壞磚都不會被挑；同色不論有沒有數字都算同色
    - 爆炸 3×3 範圍內只破壞可破壞磚（不論層數）；魔王、其他功能型磚、不可破壞磚都不受影響
    - 爆炸連鎖引爆（2026-10-26）：範圍內的另一顆爆炸磚會被引爆，以它為中心再爆一次 3×3，可一直連鎖；每顆爆炸磚只觸發 1 次
    - 畫面上沒有多層磚時，彩虹磚直接破壞（珍珠白破壞幀），不播挑色環與選中閃光，不產生白色版
    - 雷射磚的光束、擋板槍的子彈打到任何功能型磚（雷射、閃電、死神、爆炸、彩虹、傳送），磚都不受影響（不扣次數、不發動、不破壞），並被擋下（同不可破壞磚）（使用者 2026-10-26）
    - 傳送磚不套無敵外框；不會被任何東西破壞（雷射、爆炸、彩虹、槍都不會）
    - 傳送出口噴出效果用吸入 4 幀倒播，不另外畫
    - 傳送球約 480 ms 不在畫面上可以接受，實測後再調

    實作時確認、不需使用者決定：
    - 爆炸連鎖的時間差（被引爆後多久開始爆）：實作時確認，本稿不定數值
    - 傳送球不在場時間 480 ms：實測後再調，太長可改成吸入與噴出兩段重疊

    待使用者決定：
    - 爆炸磚、彩虹磚的破壞幀仍然要用：爆炸磚引爆後、彩虹磚用完後都會自己破壞

19. [D19] 槍的雷射子彈與效果（使用者已確認）：
    - 依據 D13 槍端（`paddle_gun_left/right`，8 寬 × 12 高；砲管在第 2~5 欄、砲口閃光在第 3~4 欄；欄列從 0 起算）；顏色全部沿用 D01，**不新增顏色、不新增符號**
    - 使用者已決定的玩法規則（本項遵守）：
      - 玩家點一下螢幕，左右兩門砲同時各發 1 發；子彈從砲口往上飛，打到第一顆磚就消失
      - 打到可破壞磚（多層磚、寶箱、金幣、圓形、魔王）：扣 1 層，固定扣 1，不吃強化、fever、火焰、一擊必殺等加成；磚本身沿用 D12 被擊中 1 幀，不另畫
      - 打到不可破壞磚或任何功能型磚（雷射、閃電、死神、爆炸、彩虹、傳送）：磚不受影響、不觸發，子彈被擋下
      - 子彈飛到關卡區頂端就消失（不播效果）
    - 設計取捨：
      - 子彈用 D13 槍端的黃色系（`A B Y C D`），與珍珠白圓球（D15）、洋紅光束（D17）、電青閃電（D17）、七色磚都分得開；形狀是細長 4×8，球是圓的
      - 子彈寬 4 = 砲管寬（第 2~5 欄，`K` 描邊 2 欄＋內部 2 欄），所以 1 px `K` 描邊不需例外；**碰撞寬只算內部 2 欄**（見位置規則）
      - 命中與擋下的區別：命中＝黃色、向四面放射的星形（有東西被打到）；擋下＝灰白（鋼灰色階）、貼著磚底的平直橫條加往下掉的碎片（被擋住、無效）；顏色之外形狀也不同（放射 vs 平直）
      - 砲口閃光需要另外畫：D13 的砲口只有靜態黃色 2 px，發射瞬間沒有回饋會像沒開槍；閃光只畫 2 幀、共 100 ms，疊在子彈根部上方
      - 效果圖（閃光、火花）不加 `K` 描邊（例外）：它們是 1~2 幀的短暫亮光，加黑邊會變成髒點；子彈本體有描邊

    | 圖 | id | 尺寸 | 幀數 | 每幀時間 | 說明 |
    |---|---|---|---|---|---|
    | 子彈本體 | `bullet_laser_f1`、`bullet_laser_f2` | 4×8 | 2，循環播放 | 50 ms | 飛行中；兩幀只差高光位置，產生閃爍感 |
    | 砲口閃光 | `gun_muzzle_flash_f1`、`gun_muzzle_flash_f2` | 8×4 | 2，播一次 | 50 ms | 每次發射，左右砲口各疊一份 |
    | 命中火花 | `bullet_hit_f1`、`bullet_hit_f2` | 8×8 | 2，播一次 | 60 ms | 打到可破壞磚（與 D12 小磚破壞每幀 60 ms 一致） |
    | 被擋下 | `bullet_block_f1`、`bullet_block_f2` | 8×3 | 2，播一次 | 80 ms | 打到不可破壞磚或功能型磚；稍慢，讓玩家看得出「沒效果」 |

    圖寬：4　圖高：8
    子彈 F1（id: bullet_laser_f1）：
    ```text
    .KK.
    KAAK
    KAYK
    KBYK
    KBYK
    KYCK
    KCDK
    .KK.
    ```

    圖寬：4　圖高：8
    子彈 F2（高光下移）（id: bullet_laser_f2）：
    ```text
    .KK.
    KAAK
    KBYK
    KAAK
    KBYK
    KYCK
    KCDK
    .KK.
    ```

    圖寬：8　圖高：4
    砲口閃光 F1（id: gun_muzzle_flash_f1）：
    ```text
    ...AA...
    .YBAABY.
    ..YAAY..
    ...YY...
    ```

    圖寬：8　圖高：4
    砲口閃光 F2（id: gun_muzzle_flash_f2）：
    ```text
    ........
    ...BB...
    ..YBBY..
    ...YY...
    ```

    圖寬：8　圖高：8
    命中火花 F1（id: bullet_hit_f1）：
    ```text
    ...YY...
    .Y.BB.Y.
    ..BAAB..
    YBAAAABY
    YBAAAABY
    ..BAAB..
    .Y.BB.Y.
    ...YY...
    ```

    圖寬：8　圖高：8
    命中火花 F2（碎光散開）（id: bullet_hit_f2）：
    ```text
    ........
    .Y....Y.
    ..Y..Y..
    ...BB...
    ...BB...
    ..Y..Y..
    .Y....Y.
    ........
    ```

    圖寬：8　圖高：3
    被擋下 F1（id: bullet_block_f1）：
    ```text
    .iiiiii.
    ie.ee.ei
    f..gg..f
    ```

    圖寬：8　圖高：3
    被擋下 F2（碎片掉落）（id: bullet_block_f2）：
    ```text
    .eeeeee.
    .f....f.
    g......g
    ```

    位置規則（給工程師；座標單位為內部解析度像素，欄列從 0 起算；`gun_top` ＝ 槍端圖第 0 列的 y，`gun_left` ＝ 槍端圖第 0 欄的 x）：

    | 項目 | 規則 |
    |---|---|
    | 左砲 | `gun_left` ＝ 擋板最左欄 x（槍左端圖 `paddle_gun_left`） |
    | 右砲 | `gun_left` ＝ 擋板最右欄 x − 7（槍右端圖 `paddle_gun_right`，寬 8） |
    | 子彈生成 | 子彈圖左上角 ＝ (`gun_left` + 2，`gun_top` − 4)；即子彈與砲管（第 2~5 欄）左右對齊，子彈下半 4 列藏在槍端圖底下，上半 4 列露在砲管上方，看起來從砲口射出 |
    | 子彈碰撞 | 只算內部 2 欄（子彈圖第 1~2 欄，即 `gun_left` + 3 與 `gun_left` + 4）；判定點取最上面一列（子彈圖第 0 列）的這 2 個像素；兩側 `K` 描邊不參與碰撞 |
    | 子彈移動 | 只往上直飛，x 不變；每幀依速度移動，需用掃掠判定（從上一幀位置到本幀位置之間有沒有碰到磚），不可只看終點，避免高速穿過磚 |
    | 閃光位置 | 左右砲口各一份；閃光圖左上角 ＝ (`gun_left`，`gun_top` − 4)；閃光第 3~4 欄對齊砲口第 3~4 欄；閃光在子彈生成的同一幀開始播放 |
    | 接觸點 | 子彈碰到磚的那一幀，子彈判定點的位置：x ＝ 子彈圖左上角 x（記為 `bx`），y ＝ 子彈圖第 0 列的 y（記為 `by`）；方形磚（32×16、魔王）把 `by` 修正為磚底邊下方第一列（避免子彈已嵌進磚內才播效果）；圓形磚用實際碰到圓的位置 |
    | 命中火花位置 | 左上角 ＝ (`bx` − 2，`by` − 3)；火花第 3~4 欄對準子彈內部 2 欄（`bx` + 1、`bx` + 2 之間的中心），第 3 列對準 `by` |
    | 被擋下位置 | 左上角 ＝ (`bx` − 2，`by`)；橫條第 0 列緊貼磚的下緣，向下延伸 3 列，不蓋到磚 |
    | 效果期間 | 子彈碰到磚的那一幀就從畫面移除（子彈不再畫），只留火花或被擋下效果，播完 2 幀移除；效果與磚是否在播破壞動畫無關，兩者可同時存在 |
    | 一發一效果 | 一發子彈只會產生一個效果；左右兩發各自獨立，可能一發命中、一發被擋下 |
    | 飛出頂端 | 子彈判定點越過關卡區頂端（y < 0）就移除，不播效果 |
    | 繪製順序（由下到上） | 磚（含數字）→ D14 無敵疊加 → 命中火花、被擋下效果 → 子彈 → 擋板（含槍端）→ 砲口閃光 → 球光暈 → 球本體；子彈畫在擋板下面，才能產生「從砲管射出」的效果；砲口閃光畫在擋板上面 |
    | 被擊中閃白 | 擋板被擊中閃白（D13）只影響擋板；子彈與效果不套閃白規則 |
    | 對比 | 子彈 `K` 描邊在深色背景最清楚；打到黃色磚時以 `K` 描邊保持輪廓；火花與被擋下效果在亮色磚上對比較低，屬短暫效果，可接受（未用色盲模擬器驗證，請 QA 或使用者複核） |

    數值（建議值，實作時調整）：

    | 項目 | 建議值 | 理由 |
    |---|---|---|
    | 子彈速度 | 600 px/s（約每幀 10 px，60 fps） | 關卡區高 640，約 1 秒穿過整個畫面，比球快一點才有「子彈」感；磚高 16，需用掃掠判定 |
    | 兩次發射最短間隔 | 300 ms（每秒最多 3.3 次） | 比一個閃光＋火花（100~120 ms）長，視覺不糊；避免連點洗屏。間隔內的點擊不發射 |
    | 子彈同時存在數 | 不設上限（受間隔 300 ms 與速度自然限制，約最多 4 組） | 不需額外規則 |

    給工程師的需求：
    - 不需要新的後端資料或 API
    - 不需要轉檔工具新增規則：所有圖都直接畫成網格，尺寸不同於磚，依各圖「圖寬：…　圖高：…」輸出，不套任何磚的自動規則（換色、被擊中白色版、破壞幀都不產生）
    - 遊戲程式要處理：左右兩門同時各發 1 發；打到可破壞磚固定扣 1 層、不吃任何加成；打到不可破壞磚與功能型磚不觸發、被擋下；方形磚底邊修正與圓形磚實際接觸點；掃掠判定；發射間隔 300 ms
    - 無障礙：命中與被擋下已用「顏色＋形狀」區分；若之後加音效，建議兩者用不同音（本項不涵蓋音效）

    待使用者決定：
    - 目前無（使用者已決定：子彈 4×8、速度 600 px/s、最短間隔 300 ms；實作時仍可依手感調整）

20. [D20] 增益道具掉落圖示（使用者已確認，2026-10-26）：
    - 範圍：增益道具第 1 批，共 13 個道具圖示、2 張增益底板、3 幀拾取效果；減益道具是第 2 批，本項不含；掉出底部不畫效果
    - 依據：README 玩法第 3 點（道具）；調色盤 D01；風格 D02；球 D15；HUD 圖示 D16；槍的子彈 D19
    - 風格沿用 D01、D02：光源左上、1 px `K` 描邊、5 階色階、不用抖色、漸層、隨機點；欄、列從 0 起算
    - 顏色：全部沿用 D01，**不新增顏色、不新增符號**（D01 不需更新）；底板用電青 `+ = ~ *`（D17 閃電磚也用這組色，但形狀不同），標記字用 `K`
    - 使用者已決定（本項遵守）：16×16 正方形（底板加 12×12 內容框，同 D16）；增益與減益外框形狀相同、只靠底板顏色分（增益亮、減益暗紫）；掉落時 2 幀呼吸，只換底板，內容不動；穿透、火焰、炸彈沿用 D16 的 12×12 圖案（強化、減速改為 SP/ATK 文字畫法，與 D16 一致）；擋板長度 3 種同圖案、右上角標 `+`、`++`、`max`；拾取畫約 3 幀；外形各不相同
    - 底板（`item_plate_buff_f1`、`item_plate_buff_f2`）：

    | 部位 | F1（亮） | F2（暗） | 灰階 Y（F1 → F2） |
    |---|---|---|---|
    | 最外圈 | `K` | `K` | 29 |
    | 內圈 上緣、左緣（含第 1 列第 1~13 欄、第 1 欄第 2~13 列） | `+` | `~` | 237 → 144 |
    | 內圈 下緣、右緣、右上與左下轉角 | `=` | 下緣、右緣 `*`；右上、左下轉角 `~` | 202 → 102 / 144 |
    | 底板面（第 2~13 欄、第 2~13 列的透明處） | `~` | `~` | 144（兩幀相同） |

    - 道具圖 F1 = 把內容畫在 F1 底板上；底板面 `~` 兼作內容的透明處
    - **F2 規則（寫死在轉檔工具）**：F2 = 把道具 F1 圖的底板換成 `item_plate_buff_f2`；做法：逐像素比對，凡與 `item_plate_buff_f1` 同位置、同代號的像素，改成 `item_plate_buff_f2` 同位置的像素，其餘（內容）不動；所有道具共用，所以 13 個道具不再另畫 F2 圖；內容不使用 `+ = ~ *`，不會被誤換
    - 呼吸：F1、F2 各 400 ms，一輪 800 ms（與 D15 光暈一致）；所有掉落中的道具共用同一個時鐘；玩家開啟系統「減少動態」時固定顯示 F1
    - 增益底板為什麼選電青（取捨）：
      - 與七色磚、魔王暗紫灰（Y 52~80）、珍珠白球（Y 210）、鋼灰擋板、黃色子彈、洋紅光束都不同色相
      - 面 `~` 的 Y 為 144，比預計的減益暗紫面（建議 `p`，Y 73）亮 71；相對亮度對比約 4.1:1；F1 亮圈 `+` `=` 更亮，灰階下仍分得開
      - 面不選更亮的 `=`（Y 202）：D16 炸彈的黃火花 `Y`（209）、`W` 會幾乎消失
    - 預計減益底板（第 2 批，僅供對照，本項不畫）：同樣的外框結構，面 `p`（Y 73）、亮邊 `V`（104）、暗邊 `q`（46）；呼吸時 F2 亮邊不比 F1 亮

    各道具外形與顏色（外形各不相同，不靠顏色辨識；內容都在底板的 12×12 內容框內）：

    | 道具 | 圖 id | 外形記號 | 主要顏色（D01 代號） | 來源 |
    |---|---|---|---|---|
    | 擋板小幅增加 + | `item_paddle_len_1` | 全寬擋板加底下量尺括弧；右上 K 色小十字 1 個 | 擋板：青 `w` `x`、鋼灰 `e`；標記 `K` | 新畫 |
    | 擋板大幅增加 ++ | `item_paddle_len_2` | 同上；右上 K 色小十字 2 個 | 同上 | 新畫 |
    | 擋板最大化 max | `item_paddle_len_max` | 同上；右上 K 色 3×5 字形 MAX | 同上 | 新畫 |
    | 穿透 | `item_pierce` | 向上的箭穿過橫板 | 青 `w` `x`、鋼灰 `e` `f` | D16 照抄 |
    | 火焰 | `item_flame` | 水滴狀火焰、頂端尖 | 橙 `a` `O` `d` `b`、黃 `A` `B`、紅 `R` `t` | D16 照抄 |
    | 炸彈 | `item_bomb` | 圓炸彈加右上引信火花 | 鋼灰 `f` `g` `j`、`v`、引信 `G`、火花 `Y` `W` | D16 照抄 |
    | 減速 | `item_slow` | 珍珠白球加左上 SP、右上 − | `K`（文字）、珍珠白 `W` `1`~`4` | 使用者已確認（SP/ATK 畫法），與 D16 同 |
    | 分裂 | `item_split` | 1 顆 6×6 珍珠白球（同 `item_slow`），右上文字 x2 | `K`（文字）、珍珠白 `W` `1`~`4` | 2026-10-26 使用者要求改為 1 球 + x2 |
    | 強化 | `item_reinforce` | 文字 ATK 加右上 +（ATK 在 + 下方，無球） | `K`（文字） | 使用者已確認（SP/ATK 畫法），與 D16 同 |
    | 吸附 | `item_sticky` | 6×6 珍珠白球直接貼在擋板上緣 | 珍珠白 `W` `1`~`4`、擋板 `w` `e`、`K` | 新畫；2026-10-26 使用者要求移除綠色黏液 |
    | 金球 | `item_golden_ball` | 12×12 圓形金球（四角削圓）、球面中央一個 K 色「$」（5×7）、左上白高光 | 黃 `A` `B` `Y` `C` `D`、`$` 用 `K` | 新畫；2026-10-26 使用者要求 ? 改為 $ |
    | 擋板移動速度增加 | `item_paddle_speed` | 擋板加左上 SP、右上 + | `K`（文字）、擋板青 `w` `x`、鋼灰 `e` `f` | 使用者已確認（SP/ATK 畫法，取代翅膀） |
    | 槍 | `item_gun` | 擋板上兩根直砲管，管口各一發子彈 | 鋼灰 `e` `f`、黃 `A` `B` `Y` `C`（子彈沿用 D19 色） | 新畫 |

    - 色盲照顧：外形輪廓互異（橫條＋括弧、箭、火焰、圓炸彈、SP−加球、球加 x2、ATK 字樣、球貼擋板、帶 $ 的大球、SP+加擋板、雙砲管）；顏色只是輔助；SP/ATK 是文字記號，辨識靠字，不靠色
    - 金球為什麼分得開：D15 球是 8×8 珍珠白、沒有標記；金幣磚是 32×16 的錢幣；金球是 12×12 黃色大球（四角削圓、左上高光），球面有 K 色「$」（2026-10-26 使用者要求，取代「?」）；與金幣磚的差別是外形（12×12 圓球對 32×16 長方磚）與電青亮邊底板，見回報比較
    - 擋板長度 3 款共用同一個圖案，只有右上標記不同；標記全部在內容框內（第 11~13 欄為止、第 2~6 列內），沒有超出 16×16；「max」字形只有 3×5，已是這個空間的極限；max 佔滿上緣，使用者已決定可以（2026-10-26），見「已知限制」
    - 2026-10-26 使用者已確認（SP/ATK 畫法；適用 `item_slow`、`item_paddle_speed`、`item_reinforce`）：速度與攻擊類改為文字畫法；文字為 3×5 像素字、1 px 筆畫，全在 12×12 內容框內
      - 球速（`item_slow`）與擋板速度（`item_paddle_speed`）：左上 SP（內容框第 0~6 欄、第 0~4 列），右上符號在第 9~11 欄（− 在第 2 列；+ 在第 1~3 列），SP 與符號之間空第 7、8 欄
      - `item_slow`：下方 6×6 珍珠白球（第 3~8 欄、第 6~11 列）；`item_paddle_speed`：下方 12 欄寬、4 列高擋板（第 7~10 列）
      - `item_reinforce`：右上 +（第 9~11 欄、第 0~2 列），下方 ATK（第 1~11 欄、第 5~9 列），不畫球；大幅增加用 ++、減少用 −（通則，與 `item_paddle_len_2` 一致）
      - 文字對比：`K` 對底板面 `~` 約 9:1；D16 的 `W` 對面 `g` 約 6.2:1
      - 限制：字形 3×5，SP、ATK 在小螢幕上要靠近看；球縮成 6×6；D16 加速的黃色三角已不存在，加速與減速只差右上 +／−（1 px 筆畫），色盲與小螢幕下較易混淆

    拾取效果（`item_pickup_f1`~`f3`）：

    | 幀 | 圖 id | 內容 | 尺寸 | 幀時間 |
    |---|---|---|---|---|
    | F1 | `item_pickup_f1` | 實心白色圓盤（12×12），邊緣淺電青 `+` | 20×20 | 60 ms |
    | F2 | `item_pickup_f2` | 擴大的 1 px 圓環（18×18）、中間縮小的 6×6 亮核、四個斜角各 2×2 白火花 | 20×20 | 60 ms |
    | F3 | `item_pickup_f3` | 只剩 8 個散開的小點 | 20×20 | 60 ms |
    | 合計 | - | 全程 180 ms | - | 與 D12 小磚破壞（60 ms）一致 |

    - 觸發：擋板碰到道具的那一幀，道具圖立刻移除，改播效果；播一次，播完移除
    - 位置：效果圖左上角 = 道具圖左上角 − (2, 2)，即中心對齊道具中心；效果留在碰到的位置，不跟著擋板移動
    - 效果不加 `K` 描邊（例外，同 D19 效果圖）：1~3 幀的短暫亮光，加黑邊會變髒點
    - 增益與減益共用同一組拾取效果（減益在第 2 批沿用，不另畫；若使用者想要減益專用效果，第 2 批再提）
    - 掉出畫面底部：不播任何效果，直接移除

    已知限制：
    - **HUD 炸彈圖案在亮底板上的火花對比低**：引信 `G`（Y 189）與火花 `Y`（209）、`W`（255）沒有 `K` 描邊，放在面 `~`（Y 144）上，對比約 1.6:1（`Y`）、2.2:1（`W`）；炸彈本體有 `K` 描邊，仍清楚。使用者已知並接受（2026-10-26），維持現狀不改圖案
    - 其他 4 個沿用的圖案（穿透、火焰、強化、減速）都有完整 `K` 描邊，與底板分得開；但減速的綠、穿透的青與底板同為冷色，色盲玩家要靠 `K` 描邊與形狀
    - 「max」字形只有 3×5、筆畫 1 px 的 `K`，約 9×15 手機像素一個字，戶外可能要靠近看；「+」「++」在小螢幕也只有 3×3；使用者已知並接受（2026-10-26），含 max 佔滿上緣
    - 電青底板與 D17 閃電磚同色系：磚是 32×16 的長方磚、道具是 16×16 的方塊且有亮邊，形狀不同；使用者已決定用電青底板並接受此限制（2026-10-26）；未用色盲模擬器驗證，請 QA 或使用者複核
    - 對比數字為手算近似值，背景色未實測

    需工具支援（規則寫死在轉檔工具；要修改請通知 PM，由工程師改工具）：
    - 所有 `item_` 圖直接輸出，不套磚的自動規則（不換色、不產被擊中白色版、不產破壞幀）
    - 道具 F2 圖自動產生：依上方「F2 規則」，由 F1 圖與兩張底板產生（輸出 id 建議 `<道具 id>_f2`）

    給工程師的需求：
    - 不需要新的後端資料或 API
    - 遊戲程式處理：道具 F1、F2 的 400 ms 輪播與共用時鐘；碰到擋板時改播拾取效果；掉出底部直接移除；道具掉落速度、碰撞範圍不在本項

    使用者已決定（2026-10-26）：
    - 增益底板用電青：可以
    - 炸彈火花在亮底板上的對比：維持現狀（方案 A），不改圖案
    - `item_paddle_len_max` 的 max 佔滿上緣：可以

    使用者已決定（2026-10-26，續）：
    - 減益拾取效果不另畫，共用 D20 `item_pickup_f1`~`f3`

    圖寬：16　圖高：16
    增益底板 F1（亮）（id: item_plate_buff_f1）：
    ```text
    KKKKKKKKKKKKKKKK
    K+++++++++++++=K
    K+~~~~~~~~~~~~=K
    K+~~~~~~~~~~~~=K
    K+~~~~~~~~~~~~=K
    K+~~~~~~~~~~~~=K
    K+~~~~~~~~~~~~=K
    K+~~~~~~~~~~~~=K
    K+~~~~~~~~~~~~=K
    K+~~~~~~~~~~~~=K
    K+~~~~~~~~~~~~=K
    K+~~~~~~~~~~~~=K
    K+~~~~~~~~~~~~=K
    K+~~~~~~~~~~~~=K
    K==============K
    KKKKKKKKKKKKKKKK
    ```

    圖寬：16　圖高：16
    增益底板 F2（暗）（id: item_plate_buff_f2）：
    ```text
    KKKKKKKKKKKKKKKK
    K~~~~~~~~~~~~~~K
    K~~~~~~~~~~~~~*K
    K~~~~~~~~~~~~~*K
    K~~~~~~~~~~~~~*K
    K~~~~~~~~~~~~~*K
    K~~~~~~~~~~~~~*K
    K~~~~~~~~~~~~~*K
    K~~~~~~~~~~~~~*K
    K~~~~~~~~~~~~~*K
    K~~~~~~~~~~~~~*K
    K~~~~~~~~~~~~~*K
    K~~~~~~~~~~~~~*K
    K~~~~~~~~~~~~~*K
    K~*************K
    KKKKKKKKKKKKKKKK
    ```

    圖寬：16　圖高：16
    擋板小幅增加 +（id: item_paddle_len_1）：
    ```text
    KKKKKKKKKKKKKKKK
    K+++++++++++++=K
    K+~~~~~~~~~~K~=K
    K+~~~~~~~~~KKK=K
    K+~~~~~~~~~~K~=K
    K+~~~~~~~~~~~~=K
    K+~~~~~~~~~~~~=K
    K+~~~~~~~~~~~~=K
    K+KKKKKKKKKKKK=K
    K+KweeeeeeeexK=K
    K+KKKKKKKKKKKK=K
    K+~~~~~~~~~~~~=K
    K+K~~~~~~~~~~K=K
    K+KKKKKKKKKKKK=K
    K==============K
    KKKKKKKKKKKKKKKK
    ```

    圖寬：16　圖高：16
    擋板大幅增加 ++（id: item_paddle_len_2）：
    ```text
    KKKKKKKKKKKKKKKK
    K+++++++++++++=K
    K+~~~~~~K~~~K~=K
    K+~~~~~KKK~KKK=K
    K+~~~~~~K~~~K~=K
    K+~~~~~~~~~~~~=K
    K+~~~~~~~~~~~~=K
    K+~~~~~~~~~~~~=K
    K+KKKKKKKKKKKK=K
    K+KweeeeeeeexK=K
    K+KKKKKKKKKKKK=K
    K+~~~~~~~~~~~~=K
    K+K~~~~~~~~~~K=K
    K+KKKKKKKKKKKK=K
    K==============K
    KKKKKKKKKKKKKKKK
    ```

    圖寬：16　圖高：16
    擋板最大化 max（id: item_paddle_len_max）：
    ```text
    KKKKKKKKKKKKKKKK
    K+++++++++++++=K
    K+~K~K~~K~~K~K=K
    K+~KKK~K~K~K~K=K
    K+~KKK~KKK~~K~=K
    K+~K~K~K~K~K~K=K
    K+~K~K~K~K~K~K=K
    K+~~~~~~~~~~~~=K
    K+KKKKKKKKKKKK=K
    K+KweeeeeeeexK=K
    K+KKKKKKKKKKKK=K
    K+~~~~~~~~~~~~=K
    K+K~~~~~~~~~~K=K
    K+KKKKKKKKKKKK=K
    K==============K
    KKKKKKKKKKKKKKKK
    ```

    圖寬：16　圖高：16
    穿透（id: item_pierce）：
    ```text
    KKKKKKKKKKKKKKKK
    K+++++++++++++=K
    K+~~~~~KK~~~~~=K
    K+~~~~KwxK~~~~=K
    K+~~~KwwxxK~~~=K
    K+~~KwwwxxxK~~=K
    K+~KKKKwxKKKK~=K
    K+~~~~KwxK~~~~=K
    K+KKKKKKKKKKKK=K
    K+KeeeeeeeeeeK=K
    K+KffffffffffK=K
    K+KKKKKKKKKKKK=K
    K+~~~~KwxK~~~~=K
    K+~~~~KKKK~~~~=K
    K==============K
    KKKKKKKKKKKKKKKK
    ```

    圖寬：16　圖高：16
    火焰（id: item_flame）：
    ```text
    KKKKKKKKKKKKKKKK
    K+++++++++++++=K
    K+~~~~~KK~~~~~=K
    K+~~~~KaaK~~~~=K
    K+~~~KaOOdK~~~=K
    K+~~KaOBBdbK~~=K
    K+~KaOBAABdbK~=K
    K+KOOBAAAABbbK=K
    K+KdOBAAAABbbK=K
    K+KdOBBAABBbbK=K
    K+KRdBBBBBBbRK=K
    K+~KRRdBBbRRK~=K
    K+~~KtRRRRtK~~=K
    K+~~~KKKKKK~~~=K
    K==============K
    KKKKKKKKKKKKKKKK
    ```

    圖寬：16　圖高：16
    炸彈（id: item_bomb）：
    ```text
    KKKKKKKKKKKKKKKK
    K+++++++++++++=K
    K+~~~~~~~~~~Y~=K
    K+~~~~~~~~GYWY=K
    K+~~~~~~~G~~Y~=K
    K+~~~KKKK~~~~~=K
    K+~KWWfggjK~~~=K
    K+KWfffgggjK~~=K
    K+KWfffggjjK~~=K
    K+KffgggjjjK~~=K
    K+KfggggjjvK~~=K
    K+KgggggjjvK~~=K
    K+~KgjjvvvK~~~=K
    K+~~~KKKK~~~~~=K
    K==============K
    KKKKKKKKKKKKKKKK
    ```

    圖寬：16　圖高：16
    減速（id: item_slow）：
    ```text
    KKKKKKKKKKKKKKKK
    K+++++++++++++=K
    K+KKK~KKK~~~~~=K
    K+K~~~K~K~~~~~=K
    K+KKK~KKK~~KKK=K
    K+~~K~K~~~~~~~=K
    K+KKK~K~~~~~~~=K
    K+~~~~~~~~~~~~=K
    K+~~~~KKKK~~~~=K
    K+~~~KW122K~~~=K
    K+~~~K1223K~~~=K
    K+~~~K2233K~~~=K
    K+~~~K2334K~~~=K
    K+~~~~KKKK~~~~=K
    K==============K
    KKKKKKKKKKKKKKKK
    ```

    圖寬：16　圖高：16
    分裂（id: item_split）：
    ```text
    KKKKKKKKKKKKKKKK
    K+++++++++++++=K
    K+~~~~~~~~~KKK=K
    K+~~~~~K~K~~~K=K
    K+~~~~~~K~~KKK=K
    K+~~~~~K~K~K~~=K
    K+~~~~~~~~~KKK=K
    K+~~~~~~~~~~~~=K
    K+~~~~KKKK~~~~=K
    K+~~~KW122K~~~=K
    K+~~~K1223K~~~=K
    K+~~~K2233K~~~=K
    K+~~~K2334K~~~=K
    K+~~~~KKKK~~~~=K
    K==============K
    KKKKKKKKKKKKKKKK
    ```

    圖寬：16　圖高：16
    強化（id: item_reinforce）：
    ```text
    KKKKKKKKKKKKKKKK
    K+++++++++++++=K
    K+~~~~~~~~~~K~=K
    K+~~~~~~~~~KKK=K
    K+~~~~~~~~~~K~=K
    K+~~~~~~~~~~~~=K
    K+~~~~~~~~~~~~=K
    K+~~K~~KKK~K~K=K
    K+~K~K~~K~~K~K=K
    K+~KKK~~K~~KK~=K
    K+~K~K~~K~~K~K=K
    K+~K~K~~K~~K~K=K
    K+~~~~~~~~~~~~=K
    K+~~~~~~~~~~~~=K
    K==============K
    KKKKKKKKKKKKKKKK
    ```

    圖寬：16　圖高：16
    吸附（id: item_sticky）：
    ```text
    KKKKKKKKKKKKKKKK
    K+++++++++++++=K
    K+~~~~~~~~~~~~=K
    K+~~~~~~~~~~~~=K
    K+~~~~~~~~~~~~=K
    K+~~~~KKKK~~~~=K
    K+~~~KW122K~~~=K
    K+~~~K1223K~~~=K
    K+~~~K2233K~~~=K
    K+~~~K2334K~~~=K
    K+~~~~KKKK~~~~=K
    K+KKKKKKKKKKKK=K
    K+KweeeeeeeexK=K
    K+KKKKKKKKKKKK=K
    K==============K
    KKKKKKKKKKKKKKKK
    ```

    圖寬：16　圖高：16
    金球（id: item_golden_ball）：
    ```text
    KKKKKKKKKKKKKKKK
    K+++++++++++++=K
    K+~~~KKKKKK~~~=K
    K+~KKAABYYYKK~=K
    K+~KWABYYYYCK~=K
    K+KAABYYKYYYCK=K
    K+KABYYKKKKYCK=K
    K+KBYYKYKYYYCK=K
    K+KYYYYKKKYYCK=K
    K+KYYYYYKYKYCK=K
    K+KYYYKKKKYCCK=K
    K+~KYYYYKCCCK~=K
    K+~KKCCCDDDKK~=K
    K+~~~KKKKKK~~~=K
    K==============K
    KKKKKKKKKKKKKKKK
    ```

    圖寬：16　圖高：16
    擋板移動速度增加（id: item_paddle_speed）：
    ```text
    KKKKKKKKKKKKKKKK
    K+++++++++++++=K
    K+KKK~KKK~~~~~=K
    K+K~~~K~K~~~K~=K
    K+KKK~KKK~~KKK=K
    K+~~K~K~~~~~K~=K
    K+KKK~K~~~~~~~=K
    K+~~~~~~~~~~~~=K
    K+~~~~~~~~~~~~=K
    K+KKKKKKKKKKKK=K
    K+KweeeeeeeewK=K
    K+KxffffffffxK=K
    K+KKKKKKKKKKKK=K
    K+~~~~~~~~~~~~=K
    K==============K
    KKKKKKKKKKKKKKKK
    ```

    圖寬：16　圖高：16
    槍（id: item_gun）：
    ```text
    KKKKKKKKKKKKKKKK
    K+++++++++++++=K
    K+~~KK~~~~KK~~=K
    K+~KAAK~~KAAK~=K
    K+~KAYK~~KAYK~=K
    K+~KYCK~~KYCK~=K
    K+~KKKK~~KKKK~=K
    K+~KefK~~KefK~=K
    K+~KefK~~KefK~=K
    K+~KefK~~KefK~=K
    K+~KefK~~KefK~=K
    K+KKKKKKKKKKKK=K
    K+KweeeeeeeexK=K
    K+KKKKKKKKKKKK=K
    K==============K
    KKKKKKKKKKKKKKKK
    ```

    圖寬：20　圖高：20
    拾取 F1（閃光）（id: item_pickup_f1）：
    ```text
    ....................
    ....................
    ....................
    ....................
    .......++++++.......
    .....++WWWWWW++.....
    .....+WWWWWWWW+.....
    ....+WWWWWWWWWW+....
    ....+WWWWWWWWWW+....
    ....+WWWWWWWWWW+....
    ....+WWWWWWWWWW+....
    ....+WWWWWWWWWW+....
    ....+WWWWWWWWWW+....
    .....+WWWWWWWW+.....
    .....++WWWWWW++.....
    .......++++++.......
    ....................
    ....................
    ....................
    ....................
    ```

    圖寬：20　圖高：20
    拾取 F2（圓環擴大）（id: item_pickup_f2）：
    ```text
    ....................
    .......++++++.......
    .....++......==.....
    ....+..........=....
    ...+WW........WW=...
    ..+.WW........WW.=..
    .+................~.
    .+......++++......~.
    .+.....++++++.....~.
    .+.....++++++.....~.
    .+.....++++++.....~.
    .+.....++++++.....~.
    .+......++++......~.
    .+................~.
    ..=.WW........WW.~..
    ...=WW........WW~...
    ....=..........~....
    .....==......~~.....
    .......~~~~~~.......
    ....................
    ```

    圖寬：20　圖高：20
    拾取 F3（散點）（id: item_pickup_f3）：
    ```text
    ....................
    .........++.........
    ....................
    ....................
    ....+..........=....
    ....................
    ....................
    ....................
    ....................
    .+................=.
    .+................=.
    ....................
    ....................
    ....................
    ....................
    ....=..........~....
    ....................
    ....................
    .........~~.........
    ....................
    ```

21. [D21] 減益道具掉落圖示（使用者已確認，2026-10-26）：
    - 範圍：減益道具（第 2 批），共 14 個道具圖示、2 張減益底板；拾取效果共用 D20 的 `item_pickup_f1`~`f3`（使用者已決定），不另畫；掉出底部不畫效果
    - 規格全部沿用 D20：16×16；底板加 12×12 內容框（內容在底板第 2~13 欄、第 2~13 列）；呼吸 2 幀只換底板，各 400 ms；道具只畫 F1；**F2 規則同 D20**（逐像素比對，與 `item_plate_debuff_f1` 同位置同代號的像素改成 `item_plate_debuff_f2` 的對應像素，內容不動；內容不使用 `_ < > ,`）；位置從 0 起算
    - 文字：3×5 像素字、1 px 筆畫、全部在內容框內；**暗底板上文字用白 `W`**
    - 新增顏色 4 色（符號 `_ < > ,`，已加入 D01 並標「D21 用」，色數統計為 82 色）：

    | 代號 | HEX | 用途 | 灰階 Y |
    |---|---|---|---|
    | `_` | #B85CB0 | F1 上緣、左緣內圈 | 129 |
    | `<` | #8C3F86 | F1 下緣、右緣內圈與轉角 | 94 |
    | `>` | #6A2166 | 底板面（內容透明處） | 63 |
    | `,` | #45143F | F2 下緣、右緣內圈 | 40 |

    - 底板結構同 D20：最外圈 `K`；F1 = 上、左內圈 `_`、下、右內圈與兩個轉角 `<`；F2 = 上、左內圈與轉角同面 `>`、下、右內圈 `,`、下左轉角 `>`；呼吸時內圈在 F1 亮、F2 暗
    - 暗紫底板為什麼這樣選（取捨）：
      - 色相偏洋紅的暗紫（約 300°），與多層磚紫（`m n V p q`，偏藍紫約 265°）、魔王暗紫灰（`u Q Z z v`，低飽和）有色相與飽和度差
      - 亮度：面 `>` Y 63，比 D20 電青面 `~`（Y 144）暗 81；相對亮度比約 4.7:1；整塊平均也明顯更暗
      - **如實說明：灰階上面 `>`（Y 63）與紫磚 `p`（73）、`q`（46）、魔王 `Z`（80）、`z`（52）落在同一段，差 10~17，分辨主要靠色相、飽和度、正方形外形與亮邊內圈，不靠灰階**
    - 內容在暗底板上的處理：
      - `K` 描邊對面 `>` 只有約 1.6:1，所以擋板、球的外框不用 `K`：擋板外框改 `i`（淺鋼灰）、球外框改 `3`（珍珠白 T4）、黑球外框用 `e`（鋼灰亮面）；磚與小偷臉有亮色填色，保留 `K` 描邊
      - 文字 `W` 對面 `>` 約 10.4:1

    各道具外形與顏色（外形各不相同；內容都在 12×12 內容框內）：

    | 道具 | 圖 id | 外形記號 | 主要顏色（D01 代號） |
    |---|---|---|---|
    | 擋板小幅減少 | `item_paddle_len_down_1` | 同 D20 擋板長度圖案（擋板加下方量尺括弧），右上 −（3×1，第 9~11 欄、第 1 列） | 擋板：外框 `i`、青 `w` `x`、鋼灰 `e`；括弧 `i`；−：`W` |
    | 擋板大幅減少 | `item_paddle_len_down_2` | 同上，右上 −−（第 5~7、9~11 欄、第 1 列） | 同上 |
    | 擋板最短化 | `item_paddle_len_min` | 同上，右上 3×5 字形 MIN（佔滿上緣，同 max 作法，第 1~11 欄、第 0~4 列） | 同上 |
    | 加速 | `item_fast` | 6×6 珍珠白球加左上 SP、右上 +（同 D16 `hud_icon_fast`；球第 3~8 欄、第 6~11 列） | 珍珠白 `W` `1`~`4`、外框 `3`；文字 `W` |
    | 擋板移動速度減少 | `item_paddle_speed_down` | 擋板加左上 SP、右上 −（對應 D20 `item_paddle_speed`；擋板第 7~10 列） | 擋板外框 `i`、青 `w` `x`、鋼灰 `e` `f`；文字 `W` |
    | 融合 | `item_merge` | 1 顆球加右上 ÷2（對應 D20 `item_split` 的 x2；球位置相同；÷ 在第 5~7 欄、2 在第 9~11 欄、第 0~4 列） | 珍珠白球、外框 `3`；文字 `W` |
    | 回血 | `item_heal` | 一塊綠磚（12×6，第 6~11 列）加左上 HP、右上 + | 綠 `E` `F` `L` `H` `J`、`K` 描邊；文字 `W` |
    | 範圍回血 | `item_heal_area` | 三塊綠磚向右下階梯疊在一起（各 8×4），加左上 HP、右上 + | 綠 `F` `L` `H` `J`、`K` 描邊；文字 `W` |
    | 黑洞 | `item_blackhole` | 黑色圓核加一圈橘黃吸積環（10×10，第 0~9 欄、第 2~11 列），右上留空 | 環：黃 `A` `B` `Y`、橙 `O` `d`；核 `K` |
    | 大黑洞 | `item_blackhole_big` | 與黑洞同圖案，右上角（第 9~11 欄、第 0~2 列）加白色 + | 同黑洞；+：`W` |
    | 無敵 | `item_invincible` | 兩塊磚交錯：左下多層磚、右上不可破壞磚（蓋在多層磚上）；2026-10-26 使用者要求移除箭頭；2026-10-26 使用者要求兩塊磚整體上移 1 列（磚佔第 2~10 列，第 11 列為底板面） | 多層磚用藍（`M` `N` `U` `P` `S`）；不可破壞磚用 D14 鋼板（`i` `e` `f` `g` `j` 邊、`s` `y` 面）；描邊 `K` |
    | 隱形 | `item_invisible` | 虛線外框的擋板，內部透明（露出底板面）；上、下緣各一列為 WW>WW>>WW>WW；2026-10-26 試過括號旁空 2 格的版本，使用者選回原版 | 虛線 `W` |
    | 小偷 | `item_thief` | 蒙面小偷的臉：紅白條紋小帽、黑色眼罩加兩個白眼、皮膚、一抹嘴 | 帽：紅 `R` `t`、白 `W`；眼罩 `K`；膚 `?` `-`（D18 褐） |
    | 黑球 | `item_black_ball` | 與 D20 金球同外形（12×12 圓球），球面黑色系，中央白色「?」，外框銀灰 | 球面：`u` `Q` `Z` `z` `v`（魔王色階，當黑球用）；外框 `i` `e` `f`；「?」`W` |

    - 磚塊在 12×12 內縮小時保留的特徵：
      - 多層磚：用藍色階（與 D14 的範例同為藍）；無數字，因為 12×12 放不下
      - 不可破壞磚：D14 的鋼灰框、深槍金屬面 `s` 與斜紋 `y`；省略中央螺栓
      - 回血的綠磚：沿用 D12 的斜面概念（上、左亮，下、右暗），無裂痕、無數字
    - 色盲照顧：14 個外形輪廓互異（擋板加括弧、球加 SP、擋板加 SP、球加 ÷2、單磚、疊磚、黑洞環、兩磚交錯、虛線擋板、人臉、帶「?」的大球）；SP/HP/MIN/÷2 為文字記號，靠字辨識，不靠色
    - 整批的對應（文字記號系統）：SP＝速度、HP＝血量、ATK＝攻擊；右上 + 加、− 減、++ 與 −− 大幅；增益在 D20、減益在 D21

    容易混淆的組合（如實寫出）：
    - 加速（`item_fast`）與 D20 減速（`item_slow`）、D16 `hud_icon_fast`/`hud_icon_slow`：只差右上 +／−（1 px 筆畫）
    - 擋板小幅減少、大幅減少只差 −／−−；與 D20 擋板長度三款只差右上符號與底板顏色
    - 回血與範圍回血：磚的數量（1 對 3），小螢幕下要看清楚；範圍回血使用者已接受（2026-10-26）
    - 黑洞與大黑洞：只差右上的 +
    - 黑球與 D20 金球：外形相同，靠底板（暗紫對電青）與球色（黑對黃）分；灰階下球面較暗但有銀灰外框
    - 暗紫底板與魔王、紫磚在灰階下接近（見上）；使用者已知並接受（2026-10-26）；未用色盲模擬器驗證，請 QA 或使用者複核
    - 「K」描邊在暗底板上不顯眼：磚與小偷臉的輪廓靠亮色填色辨識

    給工程師的需求：
    - 不需要新的後端資料或 API
    - 轉檔：與 D20 同規則，`item_` 圖直接輸出，道具 F2 由兩張底板自動產生（`<道具 id>_f2`）
    - 遊戲程式：呼吸 400 ms 共用時鐘；拾取時播 D20 的 `item_pickup_f1`~`f3`

    使用者已決定（2026-10-26）：
    - 小偷的臉（`item_thief`）：接受現在的設計
    - 暗紫底板在灰階下與紫磚、魔王接近：接受（主要靠色相分辨）
    - 範圍回血（`item_heal_area`）：接受現在的設計

    圖寬：16　圖高：16
    減益底板 F1（亮）（id: item_plate_debuff_f1）：
    ```text
    KKKKKKKKKKKKKKKK
    K_____________<K
    K_>>>>>>>>>>>><K
    K_>>>>>>>>>>>><K
    K_>>>>>>>>>>>><K
    K_>>>>>>>>>>>><K
    K_>>>>>>>>>>>><K
    K_>>>>>>>>>>>><K
    K_>>>>>>>>>>>><K
    K_>>>>>>>>>>>><K
    K_>>>>>>>>>>>><K
    K_>>>>>>>>>>>><K
    K_>>>>>>>>>>>><K
    K_>>>>>>>>>>>><K
    K<<<<<<<<<<<<<<K
    KKKKKKKKKKKKKKKK
    ```

    圖寬：16　圖高：16
    減益底板 F2（暗）（id: item_plate_debuff_f2）：
    ```text
    KKKKKKKKKKKKKKKK
    K>>>>>>>>>>>>>>K
    K>>>>>>>>>>>>>,K
    K>>>>>>>>>>>>>,K
    K>>>>>>>>>>>>>,K
    K>>>>>>>>>>>>>,K
    K>>>>>>>>>>>>>,K
    K>>>>>>>>>>>>>,K
    K>>>>>>>>>>>>>,K
    K>>>>>>>>>>>>>,K
    K>>>>>>>>>>>>>,K
    K>>>>>>>>>>>>>,K
    K>>>>>>>>>>>>>,K
    K>>>>>>>>>>>>>,K
    K>,,,,,,,,,,,,,K
    KKKKKKKKKKKKKKKK
    ```

    圖寬：16　圖高：16
    擋板小幅減少 −（id: item_paddle_len_down_1）：
    ```text
    KKKKKKKKKKKKKKKK
    K_____________<K
    K_>>>>>>>>>>>><K
    K_>>>>>>>>>WWW<K
    K_>>>>>>>>>>>><K
    K_>>>>>>>>>>>><K
    K_>>>>>>>>>>>><K
    K_>>>>>>>>>>>><K
    K_iiiiiiiiiiii<K
    K_iweeeeeeeexi<K
    K_iiiiiiiiiiii<K
    K_>>>>>>>>>>>><K
    K_i>>>>>>>>>>i<K
    K_iiiiiiiiiiii<K
    K<<<<<<<<<<<<<<K
    KKKKKKKKKKKKKKKK
    ```

    圖寬：16　圖高：16
    擋板大幅減少 −−（id: item_paddle_len_down_2）：
    ```text
    KKKKKKKKKKKKKKKK
    K_____________<K
    K_>>>>>>>>>>>><K
    K_>>>>>WWW>WWW<K
    K_>>>>>>>>>>>><K
    K_>>>>>>>>>>>><K
    K_>>>>>>>>>>>><K
    K_>>>>>>>>>>>><K
    K_iiiiiiiiiiii<K
    K_iweeeeeeeexi<K
    K_iiiiiiiiiiii<K
    K_>>>>>>>>>>>><K
    K_i>>>>>>>>>>i<K
    K_iiiiiiiiiiii<K
    K<<<<<<<<<<<<<<K
    KKKKKKKKKKKKKKKK
    ```

    圖寬：16　圖高：16
    擋板最短化 min（id: item_paddle_len_min）：
    ```text
    KKKKKKKKKKKKKKKK
    K_____________<K
    K_>W>W>WWW>WWW<K
    K_>WWW>>W>>W>W<K
    K_>WWW>>W>>W>W<K
    K_>W>W>>W>>W>W<K
    K_>W>W>WWW>W>W<K
    K_>>>>>>>>>>>><K
    K_iiiiiiiiiiii<K
    K_iweeeeeeeexi<K
    K_iiiiiiiiiiii<K
    K_>>>>>>>>>>>><K
    K_i>>>>>>>>>>i<K
    K_iiiiiiiiiiii<K
    K<<<<<<<<<<<<<<K
    KKKKKKKKKKKKKKKK
    ```

    圖寬：16　圖高：16
    加速（id: item_fast）：
    ```text
    KKKKKKKKKKKKKKKK
    K_____________<K
    K_WWW>WWW>>>>><K
    K_W>>>W>W>>>W><K
    K_WWW>WWW>>WWW<K
    K_>>W>W>>>>>W><K
    K_WWW>W>>>>>>><K
    K_>>>>>>>>>>>><K
    K_>>>>3333>>>><K
    K_>>>3W1223>>><K
    K_>>>312233>>><K
    K_>>>322333>>><K
    K_>>>323343>>><K
    K_>>>>3333>>>><K
    K<<<<<<<<<<<<<<K
    KKKKKKKKKKKKKKKK
    ```

    圖寬：16　圖高：16
    擋板移動速度減少（id: item_paddle_speed_down）：
    ```text
    KKKKKKKKKKKKKKKK
    K_____________<K
    K_WWW>WWW>>>>><K
    K_W>>>W>W>>>>><K
    K_WWW>WWW>>WWW<K
    K_>>W>W>>>>>>><K
    K_WWW>W>>>>>>><K
    K_>>>>>>>>>>>><K
    K_>>>>>>>>>>>><K
    K_iiiiiiiiiiii<K
    K_iweeeeeeeewi<K
    K_ixffffffffxi<K
    K_iiiiiiiiiiii<K
    K_>>>>>>>>>>>><K
    K<<<<<<<<<<<<<<K
    KKKKKKKKKKKKKKKK
    ```

    圖寬：16　圖高：16
    融合（id: item_merge）：
    ```text
    KKKKKKKKKKKKKKKK
    K_____________<K
    K_>>>>>>W>>WWW<K
    K_>>>>>>>>>>>W<K
    K_>>>>>WWW>WWW<K
    K_>>>>>>>>>W>><K
    K_>>>>>>W>>WWW<K
    K_>>>>>>>>>>>><K
    K_>>>>3333>>>><K
    K_>>>3W1223>>><K
    K_>>>312233>>><K
    K_>>>322333>>><K
    K_>>>323343>>><K
    K_>>>>3333>>>><K
    K<<<<<<<<<<<<<<K
    KKKKKKKKKKKKKKKK
    ```

    圖寬：16　圖高：16
    回血（id: item_heal）：
    ```text
    KKKKKKKKKKKKKKKK
    K_____________<K
    K_W>W>WWW>>>>><K
    K_W>W>W>W>>>W><K
    K_WWW>WWW>>WWW<K
    K_W>W>W>>>>>W><K
    K_W>W>W>>>>>>><K
    K_>>>>>>>>>>>><K
    K_KKKKKKKKKKKK<K
    K_KEEEFFFFFFFK<K
    K_KFLLLLLLLLHK<K
    K_KLLLLLLLLHHK<K
    K_KHHHHHHHHHJK<K
    K_KKKKKKKKKKKK<K
    K<<<<<<<<<<<<<<K
    KKKKKKKKKKKKKKKK
    ```

    圖寬：16　圖高：16
    範圍回血（id: item_heal_area）：
    ```text
    KKKKKKKKKKKKKKKK
    K_____________<K
    K_W>W>WWW>>>>><K
    K_W>W>W>W>>>W><K
    K_WWW>WWW>>WWW<K
    K_W>W>W>>>>>W><K
    K_W>W>W>>>>>>><K
    K_>>>>>>>>>>>><K
    K_KKKKKKKK>>>><K
    K_KHKKKKKKKK>><K
    K_KJKLKKKKKKKK<K
    K_KKKHKFFFFFFK<K
    K_>>KKKLLLLLLK<K
    K_>>>>KKKKKKKK<K
    K<<<<<<<<<<<<<<K
    KKKKKKKKKKKKKKKK
    ```

    圖寬：16　圖高：16
    黑洞（id: item_blackhole）：
    ```text
    KKKKKKKKKKKKKKKK
    K_____________<K
    K_>>>>>>>>>>>><K
    K_>>>>>>>>>>>><K
    K_>>>AAAA>>>>><K
    K_>AAOOOOBB>>><K
    K_>AOOKKOdY>>><K
    K_AOOKKKKddY>><K
    K_AOKKKKKKdY>><K
    K_AOKKKKKKdY>><K
    K_AOOKKKKddY>><K
    K_>BddKKddY>>><K
    K_>BYddddYY>>><K
    K_>>>YYYY>>>>><K
    K<<<<<<<<<<<<<<K
    KKKKKKKKKKKKKKKK
    ```

    圖寬：16　圖高：16
    大黑洞（id: item_blackhole_big）：
    ```text
    KKKKKKKKKKKKKKKK
    K_____________<K
    K_>>>>>>>>>>W><K
    K_>>>>>>>>>WWW<K
    K_>>>AAAA>>>W><K
    K_>AAOOOOBB>>><K
    K_>AOOKKOdY>>><K
    K_AOOKKKKddY>><K
    K_AOKKKKKKdY>><K
    K_AOKKKKKKdY>><K
    K_AOOKKKKddY>><K
    K_>BddKKddY>>><K
    K_>BYddddYY>>><K
    K_>>>YYYY>>>>><K
    K<<<<<<<<<<<<<<K
    KKKKKKKKKKKKKKKK
    ```

    圖寬：16　圖高：16
    無敵（id: item_invincible）：
    ```text
    KKKKKKKKKKKKKKKK
    K_____________<K
    K_>>>>>>>>>>>><K
    K_>>>>>>>>>>>><K
    K_>>>KKKKKKKKK<K
    K_>>>KiiiiiieK<K
    K_>>>KesysysgK<K
    K_KKKKeysysygK<K
    K_KMNKfgggggjK<K
    K_KNUKKKKKKKKK<K
    K_KUUUUUUPK>>><K
    K_KPPPPPPSK>>><K
    K_KKKKKKKKK>>><K
    K_>>>>>>>>>>>><K
    K<<<<<<<<<<<<<<K
    KKKKKKKKKKKKKKKK
    ```

    圖寬：16　圖高：16
    隱形（id: item_invisible）：
    ```text
    KKKKKKKKKKKKKKKK
    K_____________<K
    K_>>>>>>>>>>>><K
    K_>>>>>>>>>>>><K
    K_>>>>>>>>>>>><K
    K_>>>>>>>>>>>><K
    K_WW>WW>>WW>WW<K
    K_W>>>>>>>>>>W<K
    K_W>>>>>>>>>>W<K
    K_WW>WW>>WW>WW<K
    K_>>>>>>>>>>>><K
    K_>>>>>>>>>>>><K
    K_>>>>>>>>>>>><K
    K_>>>>>>>>>>>><K
    K<<<<<<<<<<<<<<K
    KKKKKKKKKKKKKKKK
    ```

    圖寬：16　圖高：16
    小偷（id: item_thief）：
    ```text
    KKKKKKKKKKKKKKKK
    K_____________<K
    K_>>>KKKKKK>>><K
    K_>KWRWRWRWRK><K
    K_>KttttttttK><K
    K_>K??????--K><K
    K_>KKKKKKKKKK><K
    K_>KKWWKKWWKK><K
    K_>KKKKKKKKKK><K
    K_>K??????--K><K
    K_>K???KK?--K><K
    K_>>K?????-K>><K
    K_>>>KKKKKK>>><K
    K_>>>>>>>>>>>><K
    K<<<<<<<<<<<<<<K
    KKKKKKKKKKKKKKKK
    ```

    圖寬：16　圖高：16
    黑球（id: item_black_ball）：
    ```text
    KKKKKKKKKKKKKKKK
    K_____________<K
    K_>>>iiiiie>>><K
    K_>iiQQZzzzee><K
    K_>iuQZzzzzve><K
    K_iQQZzzzzzzve<K
    K_iQZzzWWzzzvf<K
    K_iZzzzzzWzzvf<K
    K_izzzzzWzzzvf<K
    K_izzzzzzzzzvf<K
    K_ezzzzzWzzvvf<K
    K_>ezzzzzvvvf><K
    K_>eevvvvvvff><K
    K_>>>efffff>>><K
    K<<<<<<<<<<<<<<K
    KKKKKKKKKKKKKKKK
    ```

22. [D22] 遊戲中整體版面（使用者已確認，2026-10-26；僅「瀏海」仍待確認）：
    - 範圍：時間、分數、魔王血量條、暫停鈕、HUD 球狀態列（D16）的位置與尺寸，加上整體由上而下的分區；不含暫停選單、商城；數字與圖示的細圖在第 2 批畫
    - 座標：螢幕內部像素，寬 360、**設計基準高 800**；位置與尺寸一律「x, y, 寬, 高」，從 0 起算
    - 新版（本段到「給工程師的需求」之前的「新版」各段）為準；標「舊版」的段落（方案比較、高 640／800 座標表、延伸規則、layout_640、layout_800）保留供對照，不再採用

    **已決定（使用者 2026-10-26）**

    | 事項 | 決定 | 新版如何落實 |
    |---|---|---|
    | UI 排法 | 時間左上、分數右上、暫停鈕最右、球狀態列在第 2 排左、魔王血條在其右：可以 | 沿用，座標見下表 |
    | 磚塊區 | 可以更高，超過畫面一半也可以 | 最多 22 排，下緣 y 435（見「磚塊區」） |
    | 邊框 | 只要左、右、上三邊，下方不要 | 新增上邊框（D23），底端開放 |
    | UI 位置 | 放在上邊框的上方，不疊在關卡區 | UI 區 y 0~47 |
    | 手機高度 | 現在不考慮高 640 | 基準高 800；低於 800 只寫原則 |
    | 時間 | 倒數；快結束時閃爍並播音效 | 見「時間倒數與閃爍」 |
    | UI 疊在球路上 | 可以 | 新版 UI 在上邊框之上，**球不會進入 UI 區，沒有重疊** |
    | 魔王血條 | 114 寬、不顯示數字：可以 | 已由 D27 取代（2026-10-26 使用者提議：移除 UI 區血條與魔王臉，改用魔王舌頭；待確認）；UI 區座標見 D27 的 v3 表 |
    | 22 排 | 先這樣（22 排） | 沿用，最多 22 排，下緣 y 435 |
    | 閃爍時機 | 剩餘 30 秒開始閃爍（不是 10 秒） | 見「時間倒數與閃爍」 |
    | 閃爍節奏 | 兩段式（2026-10-26 使用者同意）：30~11 秒每 2 秒閃一次、無聲；10~1 秒每秒閃一次、有提示音 | 見「時間倒數與閃爍」 |
    | UI 區底 | 實心深色底 | **2026-10-26 改為實心 `K`（#1B1A2E）**（原 `j` 與 D16 線段條外框同色，外框看不見），不露出背景（D24 景觀區因此取消） |
    | 分數星形位置 | 星形緊貼分數最左一位 | 2026-10-26 依使用者看圖後要求（待再確認）：星形 x = 292 − 6 × 位數，與數字間距 3 px，位數變動時跟著移動；見座標表 |
    | 低於 800 高 | 原則可以 | 沿用「低於 800 高的手機怎麼處理」 |
    | 暫停觸控區 | 48×24 可以 | 沿用 x 308~355、y 0~23 |
    | 瀏海 | 之後再確認 | 記為待確認，本稿不處理 |

    **新版分區（高 800，由上而下）**

    | 區 | y 範圍 | 高 | 內容 |
    |---|---|---|---|
    | UI 區 | 0~47 | 48 | 時間、分數、暫停鈕、HUD 球狀態列、魔王血條；全寬 360 |
    | 上邊框 | 48~67 | 20 | 全寬 360；左右各 20×20 為轉角（D23） |
    | 關卡區 | 68~799 | 732 | 左右邊框 x 0~19 與 340~359 一路到螢幕底端；底端沒有邊框，球掉出底端即漏球 |

    **座標表（高 800，新版）**

    | 元素 | x | y | 寬 | 高 | 說明 |
    |---|---|---|---|---|---|
    | UI 區底 | 0 | 0 | 360 | 48 | 實心 `K`（#1B1A2E，已修改，待再確認）；下緣緊貼上邊框頂端的 `K` 線；球不會進來 |
    | 時間 | 8 | 4 | 56 | 16 | 左：時鐘圖示 9×9（x 8~16、y 7~15），右接數字 MM:SS，靠左 |
    | 分數 | 208 | 4 | 97 | 16 | x 208~304；數字靠右對齊到 x 304，最多 14 位；星形圖示 9×9（y 7~15）緊貼最左一位，x = 292 − 6 × 位數（1 位 x 286~294；14 位 x 208~216），與數字間隔 3 px（已修改，待再確認） |
    | 暫停鈕圖 | 332 | 4 | 16 | 16 | 兩條直線，離右緣 12 px |
    | 暫停觸控區 | 308 | 0 | 48 | 24 | x 308~355、y 0~23；圖示外擴；3 倍放大約 144×72 實體像素 |
    | HUD 球狀態列（D16） | 8 | 24 | 178 | 22 | x 8~185、y 24~45；7 格固定格位照 D16（位置已由 D28 取代，待確認） |
    | 魔王臉圖示 | 222 | 30 | 10 | 10 | 只在第 10 的倍數關（**已由 D27 取代**：2026-10-26 使用者提議移除，改用魔王嘴裡的舌頭當血條；待確認） |
    | 魔王血量條 | 238 | 30 | 114 | 10 | x 238~351；外框 1 px `K`（實為 `j`；該圖 D26 `hud_boss_bar_*` 已刪除），內 112×8；只在第 10 的倍數關（**已由 D27 取代**，同上；座標也已由 D28 v5 取代） |
    | UI 區下緣留白 | 0 | 46 | 360 | 2 | HUD 下緣 y 45 與上邊框 y 48 之間 |
    | 上邊框 | 0 | 48 | 360 | 20 | D23；含左上轉角 x 0~19、右上轉角 x 340~359 |
    | 左邊框（轉角以下） | 0 | 68 | 20 | 732 | y 68~799；樣本拼接起點 y 67，與轉角下緣重疊 1 px（D23） |
    | 右邊框（轉角以下） | 340 | 68 | 20 | 732 | 同上 |
    | 關卡區 | 20 | 68 | 320 | 732 | 球的活動範圍：左界 x 20、右界 x 339、上界 y 68；背景（D24）在最底層 |
    | 磚塊區（上限） | 20 | 84 | 320 | 352 | y 84~435；22 排 × 16 px |
    | 魔王位置 | 116 | 84 | 128 | 48 | 第 3~6 欄、磚塊區最上 3 排；只在第 10 的倍數關 |
    | 球的飛行空間 | 20 | 436 | 320 | 284 | y 436~719；無磚、無 UI、無手指（22 排排滿時） |
    | 手指區 | 20 | 720 | 320 | 80 | y 720~799；**零 UI** |
    | 擋板 | - | 763 | 64 | 8 | y 763~770；擋板下方空白 y 771~799（29 px） |

    **磚塊區（加高）**

    | 項目 | 數值 | 理由 |
    |---|---|---|
    | 磚塊起點 | y 84 | 上邊框下緣 y 67 之下留 16 px 空帶，球可從磚塊上方通過；舊版的 49 px 是為了 UI，新版 UI 已移走 |
    | 磚塊尺寸 | 32×16，10 欄（假設沿用 D12，未重新量測） | 10 欄 × 32 = 320 剛好填滿關卡區寬 |
    | **最多排數** | **22 排（352 px），y 84~435** | 下緣超過畫面一半（y 400）35 px；球的飛行空間 327 px（磚塊下緣到擋板上緣 y 436~762） |
    | 規則 | 磚塊下緣到擋板上緣至少 320 px | 排數上限 = 向下取整（（擋板 y 763 − 磚塊起點 84 − 320）÷ 16）= 22 |
    | 與舊版比較 | 舊版 10 排、下緣 208、飛行空間 394 | 排數 ×2.2；飛行空間少 67 px（約 17%），球從磚塊回到擋板的時間變短 |
    | 風險 | 球速未知 | 22 排的反應時間要靠實機測；每少 1 排多 16 px 飛行空間，上限可再調 |

    **手指區（依新版重算）**

    | 項目 | 舊版（高 640 關卡區內） | 新版（高 800 螢幕） |
    |---|---|---|
    | 手指區 | 關卡區 y 560~639（底端 80 px） | 螢幕 y 720~799（底端 80 px，同樣高度） |
    | 擋板 | 約 y 603（距手指區頂 43 px） | y 763（距手指區頂 43 px，相對位置不變） |
    | 手指區頂到磚塊下緣 | 約 351 px | 284 px（22 排滿時）；排數少時更多 |
    | UI | 零 | 零；UI 全部在 y 0~47，離手指區 672 px 以上 |

    **低於 800 高的手機怎麼處理（只寫原則）**

    - 寬度固定 360；UI 區 48、上邊框 20、左右邊框、磚塊區位置（y 84 起）、擋板距底端 37 px、手指區 80 px 都**不縮放、不裁切**（像素圖不縮放）
    - 少的高度全部由「球的飛行空間」吸收：飛行空間 = H − 473（22 排滿時）；H = 800 → 327；H = 760 → 287
    - 飛行空間建議不低於 250 px，對應最低支援高度約 H = 724；低於這個高度的手機本稿不處理（640 已決定暫不考慮）
    - 關卡的磚塊排數不隨手機高度改變，避免同一關在不同手機難度不同；所以不依手機高度縮減排數
    - 若之後要支援低於 724 的手機，可選：下調全部關卡的排數上限、或整體等比縮放；屬待決定，本稿不設計
    - 高於 800 不在本次範圍

    **時間倒數與閃爍**

    | 剩餘秒數 | 時間數字與時鐘圖示 | 音效（音效另有負責人；這裡只記需求） |
    |---|---|---|
    | > 30 | `W` 白字加 `K` 描邊 | 無 |
    | 30 ~ 11 | 剩餘秒數為偶數的那一秒，前 500 ms 為紅 `r`（#E8696B）加 `K` 描邊，後 500 ms 為白 `W`；其餘秒全白；**每 2 秒閃 1 次** | 無（我的提案，待確認） |
    | 10 ~ 1 | 每秒前 500 ms 為紅 `r`，後 500 ms 為白 `W`；**每秒閃 1 次** | 每秒 1 聲提示音，與紅色同時開始 |
    | 0 | 停在紅 `r` | 時間到音效 |

    - 使用者決定：**剩餘 30 秒開始閃爍**
    - 兩段節奏使用者已同意（2026-10-26）：30 秒內每秒都閃會有 30 次，太吵；前段每 2 秒一次提醒、最後 10 秒加快到每秒一次，越接近越急
    - 時鐘圖示與數字同色同步變紅（換色規則見 D27 第十段；D26 原規則已搬走）
    - 最快每秒 1 次，遠低於每秒 3 次的光敏安全上限；不靠顏色單獨傳達（同時有閃動，最後 10 秒另有聲音）
    - 紅 `r` 對 `K` 描邊約 5.5:1（手算近似），描邊內的字在 `j` 底上看得清

    **舊版（高 640／800；使用者 2026-10-26 已改為上方新版，保留供對照）**

    - 範圍：時間、分數、魔王血量條、暫停鈕、HUD 球狀態列（D16）的位置與尺寸；不含暫停選單、商城；數字與圖示的細圖在第 2 批畫
    - 座標：螢幕內部像素，寬 360、高 H（640~800）；位置與尺寸一律「x, y, 寬, 高」，從 0 起算；H = 640 + e，e 為多出的高度（0~160）
    - 基準（來自 D01、D02 與盤面預覽圖，後者為我由 3 倍圖估計，未量測）：邊框 x 0~19 與 x 340~359；關卡區 x 20~339、高 640；磚塊從關卡區頂端往下約 49 px 才開始；擋板約在關卡區第 603 列；擋板下約 33 px 空白
    - 關卡區頂端 0~48 px 沒有磚塊，球可以飛進去；本版面就是把 UI 放在這條空帶（640 高）或其上方的面板（高螢幕）
    - 手指區：關卡區 y 560~639（整個寬度）；UI 全部放在關卡區頂端，**手指區內零 UI**；暫停鈕在右上，離手指區最遠，降低誤觸
    - 數字：沿用 D12 數字風格（白字 `W` 加 1 px `K` 描邊，5×7 加描邊後 7×9），字距 6 px（含描邊）；實際字形第 2 批畫
    - 使用者已決定的相關事項：遊戲中 UI 只用自繪像素數字與圖示，不用字型、不放中文

    **方案比較**

    | 方案 | 做法 | 優點 | 缺點 |
    |---|---|---|---|
    | 1（建議） | 640 高：UI 疊在關卡區頂端空帶；高螢幕（e ≥ 80）：UI 放在關卡區上方的獨立面板 | 手指區零 UI；高螢幕 UI 完全不在球路上；640 也放得下 | 兩套座標；640 時 UI 在球路上（球與子彈畫在 UI 之上，球經過時會短暫蓋住數字） |
    | 2 | 所有高度都用面板，640 高時把球的天花板降到 y = 48 | 一套版面、UI 永不被球蓋住 | 640 高的可玩高度變 592，磚塊緊貼天花板，與高螢幕玩法不一致；違反「關卡區固定 640」 |
    | 3 | HUD 球狀態列放擋板下方空白 | 離球與擋板最近 | 手指拖擋板會整個蓋住；否決 |
    | 4 | HUD 放進左右邊框 | 不占空間 | 邊框只有 20 px 寬，放不下 22×22 圖示；否決 |

    **座標表：高 640（e = 0）**

    | 元素 | x | y | 寬 | 高 | 說明 |
    |---|---|---|---|---|---|
    | 左邊框 | 0 | 0 | 20 | 640 | D23 |
    | 右邊框 | 340 | 0 | 20 | 640 | D23 |
    | 關卡區 | 20 | 0 | 320 | 640 | 背景（D24）疊在整個螢幕底層 |
    | 時間 | 24 | 2 | 56 | 16 | 左：時鐘圖示 9×9（x 24~32），右接數字，格式 MM:SS，靠左 |
    | 分數 | 196 | 2 | 97 | 16 | 左：星形圖示 9×9（x 196~204），數字靠右對齊到 x 292，最多 14 位 |
    | 暫停鈕圖 | 316 | 2 | 16 | 16 | 圖示（兩條直線） |
    | 暫停觸控區 | 300 | 0 | 40 | 24 | 圖示外擴；右側貼到關卡區右緣 |
    | HUD 球狀態列（D16） | 24 | 24 | 178 | 22 | x 24~201、y 24~45；7 格固定格位照 D16 |
    | 魔王臉圖示 | 208 | 30 | 10 | 10 | 只在第 10 的倍數關 |
    | 魔王血量條 | 222 | 30 | 114 | 10 | x 222~335；外框 1 px `K`，內 112×8；只在第 10 的倍數關 |
    | 磚塊起點 | 20 | 49 | 320 | - | HUD 下緣 y 45 與磚塊間留 3 px |
    | 擋板 | - | 約 603 | - | - | 不屬 UI；UI 與擋板相距 550 px 以上 |

    **座標表：高 800（e = 160）**

    | 元素 | x | y | 寬 | 高 | 說明 |
    |---|---|---|---|---|---|
    | 左邊框 | 0 | 0 | 20 | 800 | 與背景景觀區、面板、關卡區並排，全高連續 |
    | 右邊框 | 340 | 0 | 20 | 800 | 同上 |
    | 背景景觀區 | 20 | 0 | 320 | 104 | 只有 D24 背景；上方 24 px 兼作狀態列／瀏海安全區（假設，未實測） |
    | UI 面板 | 20 | 104 | 320 | 56 | 實心深色板（`j` 面，1 px `K` 外框）；球不會進來 |
    | 時間 | 24 | 108 | 56 | 16 | 內容同 640 版 |
    | 分數 | 196 | 108 | 97 | 16 | 同上 |
    | 暫停鈕圖 | 316 | 108 | 16 | 16 | 同上 |
    | 暫停觸控區 | 300 | 104 | 40 | 32 | y 104~135；魔王血量條在其下方，不重疊 |
    | HUD 球狀態列（D16） | 24 | 130 | 178 | 22 | x 24~201、y 130~151 |
    | 魔王臉圖示 | 208 | 136 | 10 | 10 | 只在第 10 的倍數關 |
    | 魔王血量條 | 222 | 136 | 114 | 10 | x 222~335 |
    | 面板下緣留白 | 20 | 152 | 320 | 8 | 面板緊貼關卡區頂端（y 160） |
    | 關卡區 | 20 | 160 | 320 | 640 | 磚塊起點 y 209；擋板約 y 763；手指區 y 720~799 |

    **640~800 之間怎麼延伸（e = H − 640）**

    | e 的範圍 | 版面 | 多出的 e 給誰 |
    |---|---|---|
    | 0 ≤ e < 80（H 640~719） | 緊湊版：640 版的元素 y 全部加 e；UI 疊在關卡區頂端空帶，沒有面板 | 最上方 e px 給背景；e < 24 時瀏海可能遮住 UI，見問題 |
    | 80 ≤ e ≤ 160（H 720~800） | 面板版：面板 (20, e − 56, 320, 56) 緊貼關卡區上方；內容 y = 800 版的 y − (160 − e) | 面板上方 e − 56 px（24~104）給背景景觀區 |

    - 為什麼 80：面板版最少要留 24 px 給背景景觀區，兼作狀態列／瀏海安全區（24 + 56 = 80）；多出的空間再給背景景觀
    - 水平方向永遠固定：寬 360，其他整數倍放大規則照既有規格；邊框一律全高
    - 手機不是整數倍時的黑邊處理不在本稿

    **元素狀態**

    | 元素 | 狀態 | 樣子 |
    |---|---|---|
    | 時間 | 一般 | `W` 白字加 `K` 描邊 |
    | 時間 | 剩餘 30 秒以內 | 紅白閃爍，見上方「時間倒數與閃爍」 |
    | 分數 | 數字變動 | 直接換數字，不加動態 |
    | 暫停鈕 | 預設 | 16×16 兩條直線，`W` 加 `K` 描邊 |
    | 暫停鈕 | 按下 | 圖示向右下偏 1 px，直到放開 |
    | 暫停鈕 | 停用（倒數開始前、已暫停） | 圖示改 `8` 灰，不回應 |
    | 魔王血量條 | 非魔王關 | 臉圖示與血條都不顯示，位置留空，不挪動 HUD |
    | 魔王血量條 | 一般 | 底色 `v`；填色：上 1 列 `r`、中 5 列 `R`、下 2 列 `t`；填色長度 = 向上取整（112 × 目前血量 ÷ 本關血量上限） |
    | 魔王血量條 | 受傷 | 剛失去的那一段先顯示 `W` 100 ms 再消失 |
    | 魔王血量條 | 血量 0 | 填色清空；之後交給魔王破壞動畫（D12） |
    | HUD 球狀態列 | 全部 | 規則照 D16，不變 |

    - 血量上限 = 關卡數 × 5，最高 1000（PM 提供）；填色最小單位 1 px 約 9 血，所以不顯示數字
    - 對比：`W` 字對 UI 區底 `K`（#1B1A2E）約 17:1（手算近似）；其他元件在 `K` 底上的對比見 D27 第十段的對比表（D26 原表已刪除）

    **舊版線框圖例（給 layout_640、layout_800 用；新版圖例在 layout_800_v2 之前）**（1 字元 = 4 px；90 字元 = 360 px；只用 D01 顏色；線框以 4 px 為單位取近似，精確位置以座標表為準）

    | 字元 | 代表 |
    |---|---|
    | `g` | 左右邊框（各 5 字元 = 20 px） |
    | `K` | 關卡區（背景，球可飛行；本區無 UI 的部分） |
    | `l` | 背景景觀區（只有高 800 版） |
    | `j` | UI 面板（只有高 800 版） |
    | `x` | 時間 |
    | `Y` | 分數 |
    | `t` | 暫停觸控區 |
    | `R` | 暫停鈕圖示 |
    | `U` | HUD 球狀態列 |
    | `Z` | 魔王臉圖示 |
    | `V` | 魔王血量條（只在第 10 的倍數關） |
    | `b` | 磚塊區示意（約 y 49 起 10 排） |
    | `Q` | 魔王位置示意（只在第 10 的倍數關，第 3~6 欄） |
    | `s` | 手指區（y 560 起，不放 UI） |
    | `e` | 擋板（約 y 603，寬 64） |

    layout_640 說明：舊版，使用者 2026-10-26 改為 layout_800_v2；640 暫不考慮。

    圖寬：90　圖高：160
    高 640 版線框（id: layout_640）：
    ```text
    gggggKxxxxxxxxxxxxxxKKKKKKKKKKKKKKKKKKKKKKKKKKKKKYYYYYYYYYYYYYYYYYYYYYYYYYKttttRRRRttggggg
    gggggKxxxxxxxxxxxxxxKKKKKKKKKKKKKKKKKKKKKKKKKKKKKYYYYYYYYYYYYYYYYYYYYYYYYYKttttRRRRttggggg
    gggggKxxxxxxxxxxxxxxKKKKKKKKKKKKKKKKKKKKKKKKKKKKKYYYYYYYYYYYYYYYYYYYYYYYYYKttttRRRRttggggg
    gggggKxxxxxxxxxxxxxxKKKKKKKKKKKKKKKKKKKKKKKKKKKKKYYYYYYYYYYYYYYYYYYYYYYYYYKttttRRRRttggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKttttttttttggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKttttttttttggggg
    gggggKUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUKZZZVVVVVVVVVVVVVVVVVVVVVVVVVVVVVKggggg
    gggggKUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUKZZZVVVVVVVVVVVVVVVVVVVVVVVVVVVVVKggggg
    gggggKUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUKZZZVVVVVVVVVVVVVVVVVVVVVVVVVVVVVKggggg
    gggggKUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggsssssssssssssssssssssssssssssssseeeeeeeeeeeeeeeessssssssssssssssssssssssssssssssggggg
    gggggsssssssssssssssssssssssssssssssseeeeeeeeeeeeeeeessssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    ```

    layout_800 說明：舊版，使用者 2026-10-26 改為 layout_800_v2；640 暫不考慮。

    圖寬：90　圖高：200
    高 800 版線框（id: layout_800）：
    ```text
    gggggllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllggggg
    gggggllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllggggg
    gggggllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllggggg
    gggggllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllggggg
    gggggllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllggggg
    gggggllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllggggg
    gggggllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllggggg
    gggggllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllggggg
    gggggllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllggggg
    gggggllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllggggg
    gggggllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllggggg
    gggggllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllggggg
    gggggllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllggggg
    gggggllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllggggg
    gggggllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllggggg
    gggggllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllggggg
    gggggllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllggggg
    gggggllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllggggg
    gggggllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllggggg
    gggggllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllggggg
    gggggllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllggggg
    gggggllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllggggg
    gggggllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllggggg
    gggggllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllggggg
    gggggllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllggggg
    gggggllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllggggg
    gggggjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjttttttttttggggg
    gggggjxxxxxxxxxxxxxxjjjjjjjjjjjjjjjjjjjjjjjjjjjjjYYYYYYYYYYYYYYYYYYYYYYYYYjttttRRRRttggggg
    gggggjxxxxxxxxxxxxxxjjjjjjjjjjjjjjjjjjjjjjjjjjjjjYYYYYYYYYYYYYYYYYYYYYYYYYjttttRRRRttggggg
    gggggjxxxxxxxxxxxxxxjjjjjjjjjjjjjjjjjjjjjjjjjjjjjYYYYYYYYYYYYYYYYYYYYYYYYYjttttRRRRttggggg
    gggggjxxxxxxxxxxxxxxjjjjjjjjjjjjjjjjjjjjjjjjjjjjjYYYYYYYYYYYYYYYYYYYYYYYYYjttttRRRRttggggg
    gggggjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjttttttttttggggg
    gggggjUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUjjjjjjjjjjjjjjjjjjjjjjjjttttttttttggggg
    gggggjUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUjjjjjjjjjjjjjjjjjjjjjjjjttttttttttggggg
    gggggjUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUjZZZVVVVVVVVVVVVVVVVVVVVVVVVVVVVVjggggg
    gggggjUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUjZZZVVVVVVVVVVVVVVVVVVVVVVVVVVVVVjggggg
    gggggjUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUjZZZVVVVVVVVVVVVVVVVVVVVVVVVVVVVVjggggg
    gggggjUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjggggg
    gggggjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjggggg
    gggggjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggsssssssssssssssssssssssssssssssseeeeeeeeeeeeeeeessssssssssssssssssssssssssssssssggggg
    gggggsssssssssssssssssssssssssssssssseeeeeeeeeeeeeeeessssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    ```

    **新版線框圖例（layout_800_v2）**（1 字元 = 4 px；90 字元 = 360 px，200 列 = 800 px；只用 D01 顏色；以 4 px 為單位取近似，精確位置以座標表為準）

    | 字元 | 代表 | 對應 y 範圍 |
    |---|---|---|
    | `j` | UI 區底（實心深色；實際色已改為 `K`，且本圖例已由 D28 v5 取代） | 列 0~11（y 0~47） |
    | `x` | 時間 | 列 1~4 |
    | `Y` | 分數 | 列 1~4 |
    | `t` | 暫停觸控區 | 列 0~5（y 0~23） |
    | `R` | 暫停鈕圖示 | 列 1~4 |
    | `U` | HUD 球狀態列 | 列 6~11（y 24~47；實際到 y 45） |
    | `Z` | 魔王臉圖示（只在第 10 的倍數關） | 列 7~9 |
    | `V` | 魔王血量條（只在第 10 的倍數關） | 列 7~9 |
    | `c` | 上邊框左右轉角（各 20×20） | 列 12~16（y 48~67） |
    | `h` | 上邊框 | 列 12~16 |
    | `g` | 左右邊框（轉角以下，到螢幕底端） | 列 17~199 |
    | `K` | 關卡區：磚塊上方空帶（y 68~83）與球的飛行空間（y 436~719） | 列 17~20 與 109~179 |
    | `b` | 磚塊區（最多 22 排：y 84~435） | 列 21~108 |
    | `Q` | 魔王位置（第 3~6 欄、最上 3 排；只在第 10 的倍數關） | 列 21~32 |
    | `s` | 手指區（y 720~799，零 UI） | 列 180~199 |
    | `e` | 擋板（y 763、寬 64） | 列 190~191 |

    圖寬：90　圖高：200
    高 800 新版線框（id: layout_800_v2）：
    ```text
    jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjttttttttttttj
    jjxxxxxxxxxxxxxxjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjYYYYYYYYYYYYYYYYYYYYYYYYjttttttRRRRttj
    jjxxxxxxxxxxxxxxjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjYYYYYYYYYYYYYYYYYYYYYYYYjttttttRRRRttj
    jjxxxxxxxxxxxxxxjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjYYYYYYYYYYYYYYYYYYYYYYYYjttttttRRRRttj
    jjxxxxxxxxxxxxxxjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjYYYYYYYYYYYYYYYYYYYYYYYYjttttttRRRRttj
    jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjttttttttttttj
    jjUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
    jjUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUjjjjjjjjZZZjjVVVVVVVVVVVVVVVVVVVVVVVVVVVVjj
    jjUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUjjjjjjjjZZZjjVVVVVVVVVVVVVVVVVVVVVVVVVVVVjj
    jjUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUjjjjjjjjZZZjjVVVVVVVVVVVVVVVVVVVVVVVVVVVVjj
    jjUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
    jjUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
    ccccchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhccccc
    ccccchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhccccc
    ccccchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhccccc
    ccccchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhccccc
    ccccchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhccccc
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggsssssssssssssssssssssssssssssssseeeeeeeeeeeeeeeessssssssssssssssssssssssssssssssggggg
    gggggsssssssssssssssssssssssssssssssseeeeeeeeeeeeeeeessssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    ```

    給工程師的需求（由 PM 轉達）：
    - 依上方「新版」座標表排版，基準高 800；低於 800 依「低於 800 高的手機怎麼處理」，不再有緊湊版與面板版之分
    - 繪製層級由下到上：背景 → UI 區底 → 邊框 → 磚塊 → UI 數字與 HUD → 球、子彈與特效；球不會進入 UI 區
    - 球的碰撞邊界：左 x = 20、右 x = 339、上 y = 68；下方沒有邊界，球越過 y = 799 即漏球
    - 磚塊從 y 84 起、每排 16 px、最多 22 排；擋板 y 763；手指區 y 720~799 不放任何 UI
    - 時間倒數：剩餘 30 秒起紅白閃（30~11 秒每 2 秒一次、10~1 秒每秒一次）；剩餘 10~1 秒在每個紅色開始時送出「提示音」事件；0 秒送出「時間到」事件（音效由他人負責，工程師只需發出事件）
    - 瀏海安全區：待使用者確認，暫不實作（UI 區 y 0~47 貼著螢幕上緣）
    - 魔王臉圖示與血量條只在第 10 的倍數關顯示；其他關這個位置留空，HUD 不挪動
    - 暫停觸控區比圖示大（座標表），觸控區內任何點都算按下

    已決定（D22）：
    - 時間倒數、剩餘不多時閃爍並播音效（原問題 1）
    - UI 疊在球路上可以；新版 UI 已在上邊框之上，沒有重疊（原問題 2）
    - 魔王血量條 114 px 寬、不顯示數字（原問題 4）
    - 瀏海：使用者要之後再確認，記為待確認，本稿不處理（原問題 3）
    - 22 排先這樣（原問題 1）
    - 閃爍改為剩餘 30 秒開始（原問題 2）；兩段節奏（30~11 秒每 2 秒一次無聲、10~1 秒每秒一次有提示音）使用者已同意，見「時間倒數與閃爍」
    - UI 區底用實心深色底（原問題 3；原為 `j`，2026-10-26 因 D16 線段條外框同為 `j` 看不見，改為 `K`）；D24 景觀區因此取消，D24 已同步更新
    - 低於 800 高的手機：只寫原則，可以（原問題 4）
    - 暫停觸控區 48×24 可以（原問題 5）；高度略小於常見的 48 dp 建議，已接受

    待使用者確認（D22）：
    - 瀏海（之後再談）：UI 區貼著螢幕上緣，有瀏海的手機可能遮到
    - D27（魔王舌頭血條與 UI 區 v3）若獲確認，本項座標表中的魔王臉、魔王血條、暫停觸控區、時間、分數列以 D27 的 v3 表為準
    - **已由 D28 v5 取代**（使用者 2026-10-26）：本項新版座標表中的 UI 區（高 48）、上邊框、關卡區、磚塊區、魔王位置、球的飛行空間、HUD 位置，全部改以 D28 第七段「v5 座標總表」為準（UI 區縮成 32、其餘上移 16 px、HUD 移入關卡區）；本項原表保留供對照

23. [D23] 關卡區邊框材質方案（使用者已確認，2026-10-26；含上邊框、轉角、依主題換色與主題對應表、工具自動換色）：
    - 使用者決定（2026-10-26）：邊框只要左、右、上三邊；邊框依主題製作（每個主題有自己的邊框）；A、B 尚未選
    - 範圍：左右邊框各 20 px 寬，從上邊框下緣一路到螢幕底端；上邊框高 20 px、全寬 360；本項只給材質與可重複拼接的樣本；使用者已決定「由我提 2~3 個材質方案」，我提 2 案（見「為什麼只有 2 案」）
    - 依據：D02 畫風（左上光源、1 px `K` 描邊、5 階色階、材質紋理、不用抖色漸層）
    - 欄、列編號從 0 起算；左右邊框樣本為 20×32，**可重複的單位高度 = 32 px**，拼接起點 y = 67（樣本第 0 列與轉角最後一列重疊，兩者都是 `K` 線），一塊接一塊往下拼；到螢幕底端 y = 799 裁掉多出的部分
    - **位置已由 D28 v5 取代**：上邊框 y 32~51、轉角 y 32~51、左右邊框 y 52~799、樣本拼接起點 y 51（樣式與網格不變）；以下為原位置（高 800，見 D22）：上邊框 x 0~359、y 48~67；左上轉角 x 0~19、y 48~67；右上轉角 x 340~359、y 48~67；上邊框樣本拼接起點 x = 19（樣本第 0 欄與左轉角最後一欄重疊），到 x = 340 為止被右轉角蓋住；底端沒有邊框
    - 左右兩邊用同一張圖、不鏡像（光源一致：左上）；每邊最外與最內都有 1 px `K`，所以與關卡區、螢幕邊緣交界清楚
    - 為什麼只有 2 案：D01 當時剩下的未用符號只有 7 個，一案苔石就用掉 5 個（現在只剩 `'`、`"` 2 個）；另一案木材沿用既有色階、零新色；第 3 種（例如純鋼灰）會與擋板、不可破壞磚塊混淆，故不提

    | 項目 | 方案 A：苔石牆 | 方案 B：橡木桁架 |
    |---|---|---|
    | 材質 | 3 塊厚石板疊成（高 10、12、10，縫在 y 0、10、22），石面有凹坑與裂痕 | 兩條直木板並排，各 9 px 寬；木板接頭錯開 16 px；銅釘 2 顆；木紋為直向短線 |
    | 使用顏色 | 苔石 5 階（新增 `( ) [ ] {`，標「D23 用」，已加入 D01） | 炸藥褐 5 階（`? - / ; :`，沿用）加黃銅 `B Y C D`（沿用） |
    | 新增顏色 | 5 色（D01 合計 87 色） | 0 色 |
    | 明度範圍（灰階 Y） | 46~147；主色 90 | 43~209；主色 108 |
    | 與不可破壞磚（D14，深藍灰鋼板 Y 71）分得開？ | 明度接近（67~90），靠色相（橄欖綠 vs 藍灰）與板縫紋路；中等 | 色相不同（暖褐 vs 冷灰）；分得開 |
    | 與擋板（D13，亮鋼灰加青燈） | 較暗、偏綠；分得開 | 暖色；分得開 |
    | 與七色磚 | 暗、低飽和，與亮綠磚（Y 135~207）差別在飽和度與明度；分得開 | 主色 `/` 與炸藥磚（D18）完全相同，且接近橙磚；**最外一欄磚貼著邊框時容易黏在一起** |
    | 與魔王（紫灰） | 分得開（綠 vs 紫） | 分得開 |
    | 與球（珍珠白 Y 210） | 最亮只有 147，不搶球 | 最亮 `?` Y 209，與球接近；只有各板左緣 1 px，影響不大但球貼牆時要留意 |
    | 與背景（D24，Y ≤ 40） | 最暗 46 比背景亮，邊界清楚 | 最暗 43，邊界清楚 |
    | 風險 | 與 D14 明度接近 | 與炸藥磚、橙磚色相接近；T1 偏亮 |
    | 我的建議 | **建議 A** | 備案 |

    苔石 5 階（方案 A 用）：

    | 階 | 代號 | HEX | Y |
    |---|---|---|---|
    | T1 | `(` | #8F9A78 | 147 |
    | T2 | `)` | #6F7B5C | 116 |
    | T3（主色） | `[` | #55604A | 90 |
    | T4 | `]` | #3E4837 | 67 |
    | T5 | `{` | #2A3226 | 46 |

    收邊（兩案相同）：
    - 底端：左右邊框隨螢幕底緣直接裁掉，不加端帽，下方沒有邊框
    - 與 UI 區相接：上邊框頂端的 `K` 線（y 48）就是 UI 區的下緣，UI 區底（D22）不畫在邊框上
    - 與關卡區相接：邊框內緣 1 px `K` 就是關卡區的邊界；球碰撞邊界在 x = 20、x = 339、y = 68
    - 轉角：左右轉角各是一塊 20×20 的獨立石板（或木塊），自帶 `K` 外框；**右上轉角直接用左上轉角同一張圖，不鏡像**——鏡像會讓光源跑到右上，與左右邊框（光源左上）不一致；這與「左右兩邊用同一張圖」的規則相同
    - 轉角與邊框相接處：兩個樣本的 `K` 線重疊，成 1 px 線；轉角內部是完整的石板／木塊，所以接縫看起來像一塊獨立的角石
    - 背景（D24）不畫在邊框上

    圖寬：20　圖高：32
    方案 A 苔石牆樣本（id: border_moss_tile）：
    ```text
    KKKKKKKKKKKKKKKKKKKK
    K(((((((((((((((()[K
    K()))))))))))))))[]K
    K()[[[[[[[[[[[{[[]{K
    K()[[[]]][[[[{[[[]{K
    K()[[[[))[[[{[[[[]{K
    K()[[[[[[[[{[[[[[]{K
    K()[[[[[[[{[[[[[[]{K
    K)[]]]]]]]]]]]]]]]{K
    K[]{{{{{{{{{{{{{{{{K
    KKKKKKKKKKKKKKKKKKKK
    K(((((((((((((((()[K
    K()))))))))))))))[]K
    K()[[[[[[[[[[[[[[]{K
    K()[]]][[[[[[[[[[]{K
    K()[[))[[[[[[[[[[]{K
    K()[[[[[{[[[[[[[[]{K
    K()[[[[{[[[[]]][[]{K
    K()[[[{[[[[[[))[[]{K
    K()[[{[[[[[[[[[[[]{K
    K)[]]]]]]]]]]]]]]]{K
    K[]{{{{{{{{{{{{{{{{K
    KKKKKKKKKKKKKKKKKKKK
    K(((((((((((((((()[K
    K()))))))))))))))[]K
    K()[[[[[[[[[]]][[]{K
    K()[[[[[[[[[[))[[]{K
    K()[[[[[[[[[[[[[[]{K
    K()[]]][[[[[[[[[[]{K
    K()[[))[[[[[[[[[[]{K
    K)[]]]]]]]]]]]]]]]{K
    K[]{{{{{{{{{{{{{{{{K
    ```

    圖寬：20　圖高：32
    方案 B 橡木桁架樣本（id: border_oak_tile）：
    ```text
    KKKKKKKKKK?-/////;:K
    K???????-;?-/////;:K
    K?------/;?-///-/;:K
    K?-/////;:?-///-/;:K
    K?-/;///;:?-/////;:K
    K?-/;///;:?-/////;:K
    K?-/;///;:?-/////;:K
    K?-/////;:?-/-///;:K
    K?-/BY//;:?-/-///;:K
    K?-/CD//;:?-/-///;:K
    K?-/////;:?-/////;:K
    K?-/////;:?-///;/;:K
    K?-/-///;:?-/////;:K
    K?-/-///;:?-/////;:K
    K?-/////;:-/;;;;;;:K
    K?-/////;:/::::::::K
    K?-/////;:KKKKKKKKKK
    K?-/////;:???????-;K
    K?-///;/;:?------/;K
    K?-///;/;:?-/////;:K
    K?-///;/;:?-///;/;:K
    K?-/////;:?-///;/;:K
    K?-/////;:?-/////;:K
    K?-/////;:?-/////;:K
    K?-/////;:?-/BY//;:K
    K?-///-/;:?-/CD//;:K
    K?-///-/;:?-/////;:K
    K?-/////;:?-/////;:K
    K?-/////;:?-/;///;:K
    K?-/////;:?-/;///;:K
    K-/;;;;;;:?-/////;:K
    K/::::::::?-/////;:K
    ```

    **新增樣本：上邊框與左上轉角**（座標與拼接規則見上方「位置」與「收邊」）

    | 項目 | 方案 A：苔石牆 | 方案 B：橡木桁架 |
    |---|---|---|
    | 上邊框樣本 | 40×20，可水平重複的單位寬度 = 40 px | 32×20，可水平重複的單位寬度 = 32 px |
    | 結構 | 兩層石板：上層 y 1~9（9 列）、下層 y 11~18（8 列），橫縫在 y 0、10、19；上層直縫在 x 0、20，下層直縫在 x 10、30（錯開 10 px） | 兩條橫向木板：y 1~9 與 y 10~18；板端接頭錯開 16 px；銅釘 2 顆（2×2：x 8~9、y 4~5 與 x 24~25、y 13~14）；由左右邊框樣本 border_oak_tile **轉置**（列與欄互換）而來 |
    | 光源 | 每塊石板上緣、左緣亮，下緣、右緣暗，與左右邊框的石板相同（左上） | 轉置不改變左上光源；木板上緣 `?` 亮、下緣 `:` 暗 |
    | 左上轉角 | 20×20 一整塊石板，自帶 `K` 外框，上緣左緣亮、下緣右緣暗，1 個凹坑、1 條裂痕 | 20×20 一整塊木塊，自帶 `K` 外框，上緣左緣亮、下緣右緣暗，銅釘 1 顆 |
    | 右上轉角 | 直接用左上轉角同一張圖，**不鏡像** | 同左 |
    | 為什麼右上轉角不鏡像 | 鏡像後亮面在右上，與左右邊框、上邊框（光源左上）矛盾；轉角是自帶外框的獨立方塊，同一張圖放右邊不會有接縫問題 | 同左 |
    | 使用顏色 | 苔石 5 階 + `K`，零新色 | 炸藥褐 5 階 + 黃銅 `B Y C D` + `K`，零新色 |

    圖寬：40　圖高：20
    方案 A 苔石牆上邊框樣本（id: border_moss_top_tile）：
    ```text
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    K((((((((((((((((()[K((((((((((((((((()[
    K())))))))))))))))[]K())))))))))))))))[]
    K()[[[[[[[[[[[[[[[]{K()[[[[[[[[[[[[[[[]{
    K()[[[[))[[[[[[[[[]{K()[[[[[[[[[[[[[[[]{
    K()[[[[[[[[[[[[[[[]{K()[[[[[[[[[[[[[[[]{
    K()[[[[[[[[[[[[[[[]{K()[[[[[[[[{[[[[[[]{
    K()[[[[[[[[[[[[[[[]{K()[[[[[[[[[[[[[[[]{
    K)[]]]]]]]]]]]]]]]]{K)[]]]]]]]]]]]]]]]]{
    K[]{{{{{{{{{{{{{{{{{K[]{{{{{{{{{{{{{{{{{
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    (((((((()[K((((((((((((((((()[K(((((((((
    ))))))))[]K())))))))))))))))[]K())))))))
    [[[[[[[[]{K()[[[[[[[[[[[[[[[]{K()[[[[[[[
    [[[[[[[[]{K()[[[[[[]]][[[[[[]{K()[[[[[[[
    [[[[[[[[]{K()[[[[[[[[[[[[[[[]{K()[[[[[[[
    [[[[[[[[]{K()[[[[[[[[[[[[[[[]{K()[[[[[[[
    ]]]]]]]]]{K)[]]]]]]]]]]]]]]]]{K)[]]]]]]]
    {{{{{{{{{{K[]{{{{{{{{{{{{{{{{{K[]{{{{{{{
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    ```

    圖寬：20　圖高：20
    方案 A 苔石牆左上轉角（id: border_moss_corner_tl）：
    ```text
    KKKKKKKKKKKKKKKKKKKK
    K(((((((((((((((()[K
    K()))))))))))))))[]K
    K()[[[[[[[[[[[[[[]{K
    K()[[[[[[[[[[[[[[]{K
    K()[[[[[[[[[[[[[[]{K
    K()[[[[))[[[[[[[[]{K
    K()[[[[[[[[[[[[[[]{K
    K()[[[[[[[[[[[[[[]{K
    K()[[[[[[[[[[[[[[]{K
    K()[[[[[[[[[[[[[[]{K
    K()[[[[[[[[[[[[[[]{K
    K()[[[[[[[[{[[[[[]{K
    K()[[[[[[[[[[[[[[]{K
    K()[[[[[[[[[[[[[[]{K
    K()[[[[[[[[[[[[[[]{K
    K()[[[[[[[[[[[[[[]{K
    K)[]]]]]]]]]]]]]]]{K
    K[]{{{{{{{{{{{{{{{{K
    KKKKKKKKKKKKKKKKKKKK
    ```

    圖寬：32　圖高：20
    方案 B 橡木桁架上邊框樣本（id: border_oak_top_tile）：
    ```text
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    K?????????????????????????????-/
    K?----------------------------/:
    K?-///////////////////////////;:
    K?-/;;;/BC//--////////////////;:
    K?-/////YD////////////////////;:
    K?-///////////////;;;////--///;:
    K?-///////////////////////////;:
    K-/;;;;;;;;;;;;;;;;;;;;;;;;;;;;:
    K;;:::::::::::::::::::::::::::::
    ??????????????-/K???????????????
    --------------/:K?--------------
    //////////////;:K?-/////////////
    ///////---////;:K?-/////BC//;;//
    //////////////;:K?-/////YD//////
    //--///////;//;:K?-/;;//////////
    //////////////;:K?-/////////////
    ;;;;;;;;;;;;;;;:K-/;;;;;;;;;;;;;
    ::::::::::::::::K;;:::::::::::::
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    ```

    圖寬：20　圖高：20
    方案 B 橡木桁架左上轉角（id: border_oak_corner_tl）：
    ```text
    KKKKKKKKKKKKKKKKKKKK
    K????????????????-;K
    K?---------------/;K
    K?-//////////////;:K
    K?-//////////////;:K
    K?-//////////////;:K
    K?-//////////////;:K
    K?-//////////////;:K
    K?-//////////////;:K
    K?-//////BY//////;:K
    K?-//////CD//////;:K
    K?-//////////////;:K
    K?-//////////////;:K
    K?-//////////////;:K
    K?-//////////////;:K
    K?-//////////////;:K
    K?-//////////////;:K
    K-/;;;;;;;;;;;;;;;:K
    K/:::::::::::::::::K
    KKKKKKKKKKKKKKKKKKKK
    ```

    **B 橡木與炸藥磚同色的問題在新版面是否仍存在**

    | 位置 | 是否仍存在 | 原因與處理 |
    |---|---|---|
    | 上邊框與磚塊 | **不存在** | 磚塊從 y 84 起，與上邊框下緣 y 67 之間有 16 px 空帶，兩者不相鄰 |
    | 左右邊框與最外一欄磚（x 20~51、x 308~339） | **仍存在** | 炸藥磚主色 `/` 與橡木主色 `/` 相同，且橙磚（`d`）也接近；隔著邊框內緣 `K` 加磚自己的 `K` 描邊共 2 px 黑線，能分開，但顏色相近的面積仍大 |
    | 處理 1（建議） | 橡木只給一個主題 | 本稿主題表只有「地下礦坑」用橡木（木支架符合主題）；影響第 11~20 關 |
    | 處理 2（備案） | 礦坑也改用苔石換色 | 若實機仍分不清，礦坑改用苔石樣本換成岩壁褐灰（見主題表）；橡木整個不用，不需新增任何東西 |
    | 處理 3（不建議） | 關卡設計避開 | 禁止炸藥磚出現在最外一欄；限制關卡設計，不建議 |
    | 與球 | 無新問題 | 橡木最亮 `?`（Y 209）只有各板左緣 1 px 與上邊框上緣；球貼牆時仍要留意（沿用原備註） |

    **邊框依主題：顏色限制與做法**

    - 限制：D01 新增色可用的符號只剩 `'` 和 `"` 兩個；20 個主題各要一組 5 階色，用新符號做不到
    - 借用既有色階也不行：D01 既有 5 階色組只有魔王紫灰、鋼灰、靛、骨白、電青等，不是與磚塊、擋板、魔王相混（鋼灰＝擋板、靛＝靛磚、魔王紫灰＝魔王），就是太亮（骨白、電青）
    - **替代做法（建議）：同一張網格，由轉檔工具依主題換色**
      - 網格只用 5 個「槽位」符號 `( ) [ ] {`（槽位 1~5＝T1~T5）加 `K`；符號不變，不新增符號
      - 每個主題提供 1 個 HEX（T3 主色）；其他 4 階由工具推算：T1、T2、T4、T5 = T3 逐通道乘以 147÷90、116÷90、67÷90、46÷90（四捨五入；T3 最大通道不超過 156 就不會超過 255，下表都符合）。這樣每階的明度與原苔石相同（Y 147、116、90、67、46）
      - 每個主題輸出一張自己的 PNG（檔名含主題代號）；沒有換色的主題（暮色草原用原苔石、礦坑用橡木）照原網格轉檔
      - 需要工具支援：轉檔工具新增「主題換色表」輸入（主題代號、網格 id、T3 HEX），並對這幾張邊框網格略過「只能用 D01 顏色」的檢查，改檢查「5 個槽位以外不得出現其他字元」
      - 衍生色只用在邊框，不進 D01 調色盤；新增 0 個符號，約 90 個衍生 HEX（18 個主題 × 5 階）
    - 換色規則（工具可驗收）：T3 灰階 Y 在 80~95；T3 三通道最大減最小 ≤ 45（低飽和，與七色磚的高飽和分開）；不得與七色磚主色（T3）、魔王主色 `Z` #5A4A6E 太接近（HEX 距離由工程師複核）
    - 新材質只有 2 種要另畫（第 2 批之後再畫，不在本次）：金屬鉚接板（太空站、機械工廠、霓虹夜街）、晶體（冰洞、水晶洞、星雲）；它們同樣只用 5 個槽位符號加 `K`；若需要鉚釘高光等小亮點，可用 `'`、`"` 兩個新符號，屆時再提

    **邊框依主題對照表**（D24 主題內容不變；T3 為手算近似，Y 約 85~95，請工程師用工具複核）

    | 序 | 主題 | 邊框材質 | 做法 | T3 主色（名稱） | 理由 |
    |---|---|---|---|---|---|
    | 1 | 暮色草原 | A 苔石 | 原色 | #55604A（苔綠） | 草原與苔石相合；也是第 2 批先畫的主題 |
    | 2 | 地下礦坑 | B 橡木 | 原色 | 原橡木褐 | 木支架符合礦坑；全表唯一用橡木，限制炸藥磚同色的影響範圍 |
    | 3 | 雨夜城市 | A 苔石 | 換色 | #4D586A（藍灰石） | 城市石牆，冷色與雨夜一致 |
    | 4 | 深海 | A 苔石 | 換色 | #3F6068（青藍珊瑚岩） | 石面凹坑像珊瑚孔洞 |
    | 5 | 沙漠夜 | A 苔石 | 換色 | #5E5A4E（砂岩灰） | 低飽和砂色，避免與橙磚、炸藥磚相混 |
    | 6 | 冰洞 | 新材質：晶體 | 換色 | #4E6074（冰藍灰） | 冰是塊狀晶體，不是石板 |
    | 7 | 深林 | A 苔石 | 換色 | #4A5A42（深苔） | 比第 1 個更暗更綠；與第 1 個相近，是相似度最高的一組 |
    | 8 | 火山洞穴 | A 苔石 | 換色 | #62504A（玄武岩暗紅灰） | 裂痕像岩縫；低飽和，避免與紅磚相混 |
    | 9 | 古代遺跡 | A 苔石 | 換色 | #5C5868（風化灰紫） | 石板厚重，最像遺跡石牆 |
    | 10 | 機械工廠 | 新材質：金屬鉚接板 | 換色 | #5A5C60（鐵灰） | 鉚接牆板；注意與不可破壞磚（D14）明度相近 |
    | 11 | 雲海夜空 | A 苔石 | 換色 | #50587A（夜藍灰） | 冷藍與夜空一致 |
    | 12 | 墓園 | A 苔石 | 換色 | #5A5E58（墓碑灰） | 墓碑石材 |
    | 13 | 水晶洞 | 新材質：晶體 | 換色 | #5E4E7A（紫水晶） | 晶簇洞壁 |
    | 14 | 太空站 | 新材質：金屬鉚接板 | 換色 | #4A5C66（冷青灰） | 艙壁格板；注意與擋板（D13）、不可破壞磚（D14）分開 |
    | 15 | 沼澤 | A 苔石 | 換色 | #58593F（泥綠） | 濕泥石 |
    | 16 | 城堡地牢 | A 苔石 | 換色 | #54545C（地牢灰） | 石磚牆，最像原本的石板 |
    | 17 | 霓虹夜街 | 新材質：金屬鉚接板 | 換色 | #5A4C70（暗紫） | 街邊鐵皮；沒有霓虹光（沒有可用的亮色） |
    | 18 | 星雲 | 新材質：晶體 | 換色 | #6A4E70（星雲紫） | 晶體面像星雲結晶 |
    | 19 | 黑暗神殿 | A 苔石 | 換色 | #544C62（黑曜紫灰） | 神殿石柱 |
    | 20 | 魔王城 | A 苔石 | 換色 | #6A4A56（暗莓紅石） | 暗紅帶紫；刻意避開魔王主色 `Z`；與紅磚的區別靠低飽和 |

    - 統計：A 原色 1、B 原色 1、A 換色 12、新材質 6（金屬鉚接板 3、晶體 3）；共 20
    - 相似風險：第 1、7、15、12 的綠灰色相近；第 3、11、14 的藍灰色相近；差別小，使用者若在意，可改其中幾個主題的 T3
    - 若使用者不接受換色：退回「全部用 A 或 B 原色」或「只做少數幾個主題的專屬邊框」，由使用者決定

    - 已知限制：
      - 樣本只在 20×32 內重複，垂直方向每 32 px 會看出週期（兩案都刻意把裂痕、木紋放在不同位置以減輕）；若使用者覺得重複感強，可加第 2 塊變體
      - 方案 A 與 D14 明度接近；方案 B 與炸藥磚同色（新版面仍存在於左右邊框，見上方表）；兩者都沒有用色盲模擬器驗證
      - 上邊框、轉角樣本是我手排的 ASCII，尚未轉成 PNG 看過；接縫（轉角與邊框重疊的 1 px 線、上邊框與右轉角的裁切處）需看 PNG 才能確認
      - 上邊框 B 樣本由左右邊框樣本轉置而來，木板接頭與銅釘位置跟著轉置，沒有重新設計；若看起來不自然可重畫
      - 主題換色的 T3 色碼為我手算，沒有實際看過色；T1~T5 由工具推算，亮邊在低飽和色上可能偏灰白，需看 PNG 調整
      - 20 個主題的邊框對應是我的提案；12 個主題共用苔石形狀，只靠顏色區別，單調感待使用者判斷
      - D24 的景觀區（y 0~103）被 UI 區與上邊框蓋住，D24 本次未改，見 D22 問題 3

24. [D24] 背景主題清單（暫定：使用者 2026-10-27 決定「先暫定，實機測試再確認」；2026-10-26 範圍改為只在關卡區；主題 1、8 的圖見 D25）：
    - 範圍：每 10 關換一個主題，200 關共 20 個主題；第 N 關的主題 = 第 ⌈N ÷ 10⌉ 個；主題切換在關卡開始時直接換，不加轉場
    - 背景是關卡區的最底層圖，靜態、不動；畫在磚塊、球之下
    - **可見範圍（D22 新版，使用者已確認 UI 區用實心深色底，現為 `K`）：只有關卡區 x 20~339、y 68~799，共 320×732**；UI 區（y 0~47）與上邊框（y 48~67）蓋住的區域不再有背景，**景觀區取消**
    - 低於 800 高的手機：背景左上對齊 (20, 68)，底端多出的部分裁掉
    - **已由 D28 v5 取代**：可見範圍改為 x 20~339、y 52~799（320×748），原點對齊關卡區左上 (20, 52)；其餘規則不變；以下為原文
    - 實作方式：以底圖單元（例 64×64）上下左右重複鋪滿 320×732，原點對齊關卡區左上 (20, 68)，再疊裝飾圖；範例見 D25

    **亮度與對比規則**（工具與使用者可驗收）：

    | 規則 | 數值 | 原因 |
    |---|---|---|
    | 關卡區背景每個像素的灰階 Y | 8 ≤ Y ≤ 40（比 D01 的 `K` Y 29 略深到略淺） | 球主色 `2`（Y 210）對背景約 9:1 以上 |
    | 關卡區背景內任兩個相鄰像素的 Y 差 | ≤ 12 | 沒有硬邊，不會被誤認為磚塊或道具輪廓 |
    | 關卡區背景內 32×32 範圍內最亮與最暗像素的 Y 差 | ≤ 24 | 景物只是氛圍 |
    | 色彩飽和度 | 同一像素的 R、G、B 最大值減最小值 ≤ 40 | 不與七色磚及道具搶色 |
    | 禁用顏色 | 不得使用 D01 的任何一色（磚塊、擋板、球、道具色皆不用） | 辨識不被背景色干擾 |
    | 景物密度 | 關卡區背景中，非底色像素 ≤ 25% | 留白給球與磚塊 |
    | 景觀區 | 已取消（被 UI 區與上邊框蓋住，使用者確認 UI 區實心）；原「3% 像素到 Y ≤ 90」的例外**不再保留**，全部像素一律 Y ≤ 40 | 可見範圍只有關卡區，亮點會干擾球 |
    | 動態 | 無 | 球與特效是唯一會動的東西 |
    | 文字 | 不放任何文字、招牌字 | 使用者決定：不放中文 |
    - 驗收方式：轉出背景圖後，工具逐像素檢查 Y、相鄰像素差、飽和度；超出的列出座標
    - 磚塊最暗主色（靛 `I`，Y 66）對背景對比低，靠磚塊 1 px `K` 描邊與斜面分辨；這是已知限制
    - HEX 與 Y 為我手算近似，請工程師用工具複核；「底色」為整體基底，「景物色」為景物與紋路用，兩者 Y 都在規則內

    | 序 | 關卡 | 主題 | 底色（Y） | 景物色（Y） | 主要元素 |
    |---|---|---|---|---|---|
    | 1 | 1~10 | 暮色草原 | #0E1A16（22） | #1A2E26（39） | 遠丘剪影、零星草叢；景觀區有一彎淡月 |
    | 2 | 11~20 | 地下礦坑 | #17130F（20） | #2B241C（37） | 木支架、礦車軌、岩壁紋 |
    | 3 | 21~30 | 雨夜城市 | #0D1220（18） | #1C273A（38） | 樓房剪影、小窗點（每點 ≤ 2×2 px）、極淡的斜雨線 |
    | 4 | 31~40 | 深海 | #09171F（20） | #112D38（38） | 海草、氣泡圈、遠處魚影 |
    | 5 | 41~50 | 沙漠夜 | #1A1410（21） | #2E2518（38） | 沙丘、仙人掌剪影、景觀區星點 |
    | 6 | 51~60 | 冰洞 | #0F1822（22） | #1B2937（38） | 冰柱、霜紋、冰晶 |
    | 7 | 61~70 | 深林 | #0B140D（17） | #1A2B1C（36） | 樹幹、蕨葉、微光孢子（單點） |
    | 8 | 71~80 | 火山洞穴 | #1A0F0D（18） | #3A1D14（37） | 岩縫與暗紅裂紋、遠處熔岩河、石筍 |
    | 9 | 81~90 | 古代遺跡 | #14131C（20） | #272534（39） | 石柱、符文刻痕（無字）、碎磚 |
    | 10 | 91~100 | 機械工廠 | #10161C（21） | #202830（39） | 齒輪、管線、鉚接牆板（第 100 關魔王之後換主題） |
    | 11 | 101~110 | 雲海夜空 | #0C0F26（17） | #1E2244（37） | 雲層帶、星點、遠方浮島 |
    | 12 | 111~120 | 墓園 | #111613（20） | #222925（39） | 墓碑、枯樹、低霧帶 |
    | 13 | 121~130 | 水晶洞 | #150E22（18） | #2A1E44（38） | 晶簇、洞壁、微光折面 |
    | 14 | 131~140 | 太空站 | #080A14（11） | #1D2336（35） | 艙壁格板、舷窗星點、管道 |
    | 15 | 141~150 | 沼澤 | #12150B（19） | #272B16（39） | 蘆葦、枯枝、水面反光帶 |
    | 16 | 151~160 | 城堡地牢 | #15151A（22） | #27262C（39） | 石磚牆、鐵窗、無火焰的火把座 |
    | 17 | 161~170 | 霓虹夜街 | #0A0B12（12） | #2A1840（34）、#0F312F（39） | 無字招牌輪廓、電線、暗色霓虹線條 |
    | 18 | 171~180 | 星雲 | #0D0817（11） | #2B1646（34） | 雲狀色塊、星點、環狀行星 |
    | 19 | 181~190 | 黑暗神殿 | #0F0B12（13） | #2A1F33（37） | 立柱、符文圈（無字）、門拱 |
    | 20 | 191~200 | 魔王城 | #0C0A10（11） | #2D2038（39） | 尖塔、王座剪影、裂開的夜空 |

    - 表中「景觀區」「月亮」「星點」「招牌光」等字眼：景觀區已取消，這些元素若要保留，改畫進關卡區背景，並遵守上方亮度規則（Y ≤ 40，不可更亮）；主題 1 的月亮已不畫（D25 未使用）
    - 主題順序的想法：由亮處（草原）一路走到暗處（魔王城），關卡越後面底色越冷、越深；冷暖交錯避免連續三個主題同色
    - 暖色主題（礦坑、沙漠、火山）的景物色都壓在 Y ≤ 39 且低飽和，以免與紅、橙、黃磚相混；這是風險最高的三個
    - **建議第 2 批先畫 2 個**：
      - 第 1 個 暮色草原：玩家最先看到；偏綠，用來測「背景綠」會不會干擾綠磚
      - 第 2 個 火山洞穴：暖紅褐，是最容易與紅橙磚相混的；兩個畫完就能驗證亮度規則的兩個極端
    - 已知限制：
      - 20 個主題的名稱與元素是我的提案，沒有使用者研究；使用者可換、可刪
      - 景觀區取消後，主題辨識度只靠關卡區背景的低對比景物（Y ≤ 40）；與磚塊重疊的上半部看不太到，可見度靠球的飛行空間（y 436~719）

25. [D25] 背景圖：主題 1 暮色草原、主題 8 火山洞穴（使用者已確認，2026-10-27；主題 1、8 的背景圖定案）：
    - 範圍：D24 的主題 1（關卡 1~10）與主題 8（關卡 71~80）；每個主題 1 張可無縫重複的**底圖單元** 64×64 + 3 張**裝飾圖**；不畫邊框（主題 1 用苔石原色、主題 8 由工具換色，D23）
    - 為什麼不畫整張：關卡區 320×732 太大；64×64 單元重複 5 欄 × 12 列（最後一列裁掉），再疊少量裝飾，檔案小、容易改
    - 為什麼是 64×64：320 剛好 5 欄；紋理單元夠大，看不出明顯的格子重複，又不會大到手排出錯
    - **已由 D28 v5 更新**：關卡區原點改為螢幕 (20, 52)，關卡區 x 0~319、y 0~747；本項的擺放座標（關卡區座標）與底圖、裝飾圖都不變，螢幕上整體上移 16 px；底圖鋪設 748 = 11 × 64 + 44（最後一列只用前 44 列）
    - 座標一律用「關卡區座標」：(0, 0) = 螢幕 (20, 68)；螢幕座標 = 關卡區座標 + (20, 68)；關卡區 x 0~319、y 0~731（v5 前的原文）
    - 顏色：依 D24「禁用 D01 顏色」，不使用 D01 任何一色，每個主題用自己的**區塊調色盤**；調色盤寫在每張網格的「圖寬」行正上方，同主題各張共用同一組；`.` 為透明、`K` 不可定義、本項沒有使用 `K`
    - 工具提醒：工具尚未支援區塊調色盤，轉檔須等工程師完成；在那之前我沒有看過這些圖，下方格子與色值皆為手排、手算

    **無縫規則與畫法**

    | 項目 | 規則 |
    |---|---|
    | 底圖單元無縫 | 所有紋理圖案都完整落在單元內，第 0 列、第 63 列、第 0 欄、第 63 欄**全部是底色 `a`**；上下左右相接時只會接到底色，沒有接縫 |
    | 紋理不排成格子 | 圖案位置錯開，不以 8 或 16 的倍數排成整齊陣列 |
    | 底色 | 兩個主題的 `a` 都等於 D24 表的「底色」 |
    | 裝飾圖 | 背景透明 `.`，疊在底圖上；邊緣色與底色的灰階差都在 12 以內，不會出現硬邊 |
    | 疊放順序 | 底圖 → 遠景（丘、河）→ 中景（灌木、岩池）→ 近景（花、石筍） |

    **D24 亮度規則自查（Y = 0.299R + 0.587G + 0.114B，手算近似，請工程師用工具複核）**

    主題 1 暮色草原，`區塊調色盤：e #0A1410；a #0E1A16；b #11201A；c #152620；f #282236`

    | 符號 | HEX | Y | 飽和度（最大−最小） | 用途 |
    |---|---|---|---|---|
    | e | #0A1410 | 16.6 | 10 | 最暗：土丘本體、岩坑、灌木底影 |
    | a | #0E1A16 | 22.0 | 12 | 底色（等於 D24） |
    | b | #11201A | 26.8 | 15 | 草葉暗部、土丘邊、灌木本體 |
    | c | #152620 | 32.2 | 17 | 草葉亮部、灌木頂 |
    | f | #282236 | 38.1 | 20 | 花心（暮紫，全圖最亮點，只有 1 px） |

    - 全部 Y 在 16.6~38.1，落在 8~40 內；飽和度最大 20，≤ 40
    - 相鄰像素差（含斜角）用到的組合：e–a 5.4、a–b 4.9、b–c 5.4、a–c 10.3、b–e 10.3、c–f 5.8，全部 ≤ 12；刻意**不相鄰**的組合：c–e 15.7、a–f 16.1（花心四周一圈是 `c`，把 `f` 與 `a` 隔開）
    - 任意 32×32 內最亮與最暗的差最大 f–e = 21.5，≤ 24
    - 非底色像素：底圖約 6%，加裝飾約 8%（手算估計），≤ 25%

    主題 8 火山洞穴，`區塊調色盤：e #140B09；a #1A0F0D；b #20120F；c #28160F；d #2F1911；f #361C13`

    | 符號 | HEX | Y | 飽和度 | 用途 |
    |---|---|---|---|---|
    | e | #140B09 | 13.5 | 11 | 最暗：暗裂縫、石筍陰面 |
    | a | #1A0F0D | 18.1 | 13 | 底色（等於 D24） |
    | b | #20120F | 21.8 | 17 | 岩塊、石筍本體 |
    | c | #28160F | 26.6 | 25 | 裂紋外緣、岩塊亮點、熔岩岸 |
    | d | #2F1911 | 30.7 | 30 | 裂紋中心、熔岩次層 |
    | f | #361C13 | 34.8 | 35 | 熔岩核心（全圖最亮，仍低於 D24 景物色 Y 37） |

    - 全部 Y 在 13.5~34.8，落在 8~40 內；飽和度最大 35，≤ 40
    - 相鄰差用到的組合：e–a 4.6、a–b 3.8、a–c 8.5、b–c 4.7、b–d 8.8、c–d 4.1、c–f 8.2、d–f 4.1、b–e 8.4，全部 ≤ 12；刻意不相鄰：a–d 12.6、c–e 13.1（裂紋中心 `d` 外圈包 `c`；暗縫 `e` 只接 `a` 或 `b`）
    - 任意 32×32 最大差 f–e = 21.3，≤ 24
    - 非底色像素：底圖約 6%，加裝飾約 7%（手算估計），≤ 25%
    - 暖色風險：D24 已列為高風險；f 的 R 只有 54，與紅磚主色 `R`（Y 88）差很多，但仍請在實機看是否把紅磚「染暖」

    **擺放規則（關卡區座標；裝飾位置可依實機微調，但保持 Y 範圍與間距）**

    | 主題 | 圖 | 尺寸 | 數量 | 位置（x, y 為圖左上角） | y 範圍 | 規則 |
    |---|---|---|---|---|---|---|
    | 1 | meadow_tile | 64×64 | 鋪滿 | 原點 (0, 0)，每 64 px 重複 | 0~731 | 底層，最後一列只用前 28 列 |
    | 1 | meadow_mound | 48×12 | 5 | (16,392) (144,452) (248,524) (40,596) (176,668) | 392~679 | 只放在 y ≥ 372（球的飛行空間，磚塊區之下）；兩兩相距 ≥ 48 px |
    | 1 | meadow_bush | 20×9 | 6 | (272,380) (100,500) (8,540) (228,610) (120,700) (290,690) | 380~708 | 不與土丘重疊 |
    | 1 | meadow_flowers | 12×7 | 6 | (96,388) (210,470) (150,560) (20,640) (260,650) (90,712) | 388~718 | 最上層；不與土丘、灌木重疊 |
    | 8 | volcano_tile | 64×64 | 鋪滿 | 原點 (0, 0)，每 64 px 重複 | 0~731 | 底層，最後一列只用前 28 列 |
    | 8 | volcano_river | 40×9 | 3 | (24,400) (200,520) (60,640) | 400~648 | 遠景；只放在 y ≥ 372；兩條之間 ≥ 100 px |
    | 8 | volcano_pool | 16×7 | 4 | (140,410) (260,560) (100,590) (250,690) | 410~696 | 中景 |
    | 8 | volcano_stalagmite | 12×12 | 6 | (8,384) (280,430) (120,470) (230,600) (30,690) (180,700) | 384~711 | 近景；不與河、池重疊 |

    - 磚塊區（關卡區 y 16~367）只有底圖單元，不放裝飾，避免被磚塊切碎
    - 手機高度低於 800 時，下方裝飾被一起裁掉（D24）；不重新排列
    - 全圖不放任何文字、招牌（D24）

    區塊調色盤：e #0A1410；a #0E1A16；b #11201A；c #152620；f #282236
    圖寬：64　圖高：64
    暮色草原底圖單元（id: meadow_tile）：
    ```text
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacacaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacbcaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbcbbaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaacccaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaacfcaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaacccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaeeeaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaeeeeeaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaeeeaaaaaaaaaaaaaaaaaaaaaaaaaaaacaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacbcbcaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaacacaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaacbcaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaabbcbbaaaaaaaaaaaaaaaaaaaaaaaaacccaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaabbbaaaaaaaaaaaaaaaaaaaaaaaaaacfcaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaacaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaacccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaacbcbcaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaabbbbbbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaeeeaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaeeeeeaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaeeeaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaacacaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaacbcaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaabbcbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaabbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaacfcaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacbcbcaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbaaaaaaaaaaa
    aaaaaaaaaaaaaaeeeaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaeeeeeaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaeeeaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacacaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacbcaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbcbbaaaaaaaaaaaaaaaaacccaaaaa
    aaaaaaaaaaaaaaaaaaaaacaaaaaaaaaaaaabbbaaaaaaaaaaaaaaaaaacfcaaaaa
    aaaaaaaaaaaaaaaaaaaacccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccaaaaa
    aaaaaaaaaaaaaaaaaaacbcbcaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaabbbbbbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    ```

    區塊調色盤：e #0A1410；a #0E1A16；b #11201A；c #152620；f #282236
    圖寬：48　圖高：12
    暮色草原土丘（id: meadow_mound）：
    ```text
    ...................bbbbbbbbbb...................
    ...............bbbbeeeeeeeeeebbbb...............
    ............bbbeeeeeeeeeeeeeeeeeebbb............
    .........bbbeeeeeeeeeeeeeeeeeeeeeeeebbb.........
    .......bbeeeeeeeeeeeeeeeeeeeeeeeeeeeeeebb.......
    .....bbeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeebb.....
    ....beeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeb....
    ...beeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeb...
    ..beeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeb..
    .beeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeb.
    beeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeb
    eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
    ```

    區塊調色盤：e #0A1410；a #0E1A16；b #11201A；c #152620；f #282236
    圖寬：20　圖高：9
    暮色草原灌木（id: meadow_bush）：
    ```text
    ......cccccccc......
    ....ccbbbbbbbbbb....
    ..ccbbbbbbbbbbbbbb..
    .cbbbbbbbbbbbbbbbbb.
    cbbbbbbbbbbbbbbbbbbb
    bbbbbbbbbbbbbbbbbbbb
    bbbbbbbbbbbbbbbbbbbb
    .eeeeeeeeeeeeeeeeee.
    ..eeeeeeeeeeeeeeee..
    ```

    區塊調色盤：e #0A1410；a #0E1A16；b #11201A；c #152620；f #282236
    圖寬：12　圖高：7
    暮色草原花叢（id: meadow_flowers）：
    ```text
    ..ccc..ccc..
    ..cfc..cfc..
    ..ccc..ccc..
    .bbcbbbbcbb.
    bbbbbcbbbbbb
    bbbbbbbbbbbb
    .eeeeeeeeee.
    ```

    區塊調色盤：e #140B09；a #1A0F0D；b #20120F；c #28160F；d #2F1911；f #361C13
    圖寬：64　圖高：64
    火山洞穴底圖單元（id: volcano_tile）：
    ```text
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbaaaaaaaaa
    aaaaaacccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbcbbaaaaaaaa
    aaaaaacdccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbaaaaaaaa
    aaaaaaccdcccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbaaaaaaaaa
    aaaaaaaccddccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaacccdccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaccdcaaaaaaaaaaaaaaaaaaaaeeeaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaacccaaaaaaaaaaaaaaaaaaaaaaaeeeaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaeeeaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaeeaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaabbcbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaabbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaabbcbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaabbbbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccaaaaaaaaaaaa
    aaaaaaaaaaaaaabbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaccdcaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccdccaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaccddccaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaccdcccaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacdccaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaeeeaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaeeeaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaeeeaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaeeaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaccdcaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccdccaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaccddccaaaaaaa
    aaaacccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaccdcccaaaaaaaa
    aaaacdccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacdccaaaaaaaaaa
    aaaaccdcccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccaaaaaaaaaaa
    aaaaaccddccaaaaaaaaaaaaaaaaaaaaaaaaaaabbbaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaacccdccaaaaaaaaaaaaaaaaaaaaaaaaabbcbbaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaccdcaaaaaaaaaaaaaaaaaaaaaaaaabbbbbaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaacccaaaaaaaaaaaaaaaaaaaaaaaaaabbbaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbaaaaaaaaa
    aaaaaaaaaaaaaaeeeaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbcbbaaaaaaaa
    aaaaaaaaaaaaaaaaaeeeaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaeeeaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaeeaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    ```

    區塊調色盤：e #140B09；a #1A0F0D；b #20120F；c #28160F；d #2F1911；f #361C13
    圖寬：40　圖高：9
    火山洞穴熔岩河（id: volcano_river）：
    ```text
    ...cccccccccccccccccccccccccccccccccc...
    ..cddddddddddddddddddddddddddddddddddc..
    .cdffffffffffffffffffffffffffffffffffdc.
    cdffffffffffffffffffffffffffffffffffffdc
    cdffffffffffffffffffffffffffffffffffffdc
    cdffffffffffffffffffffffffffffffffffffdc
    .cdffffffffffffffffffffffffffffffffffdc.
    ..cddddddddddddddddddddddddddddddddddc..
    ...cccccccccccccccccccccccccccccccccc...
    ```

    區塊調色盤：e #140B09；a #1A0F0D；b #20120F；c #28160F；d #2F1911；f #361C13
    圖寬：12　圖高：12
    火山洞穴石筍（id: volcano_stalagmite）：
    ```text
    .....cb.....
    .....cb.....
    ....cbbe....
    ....cbbe....
    ...cbbbbe...
    ...cbbbbe...
    ..cbbbbbbe..
    ..cbbbbbbe..
    .cbbbbbbbbe.
    .cbbbbbbbbe.
    cbbbbbbbbbbe
    cbbbbbbbbbbe
    ```

    區塊調色盤：e #140B09；a #1A0F0D；b #20120F；c #28160F；d #2F1911；f #361C13
    圖寬：16　圖高：7
    火山洞穴岩池（id: volcano_pool）：
    ```text
    ...cccccccccc...
    ..cddddddddddc..
    .cdffffffffffdc.
    cdffffffffffffdc
    .cdffffffffffdc.
    ..cddddddddddc..
    ...cccccccccc...
    ```

26. [D26] 遊戲中 UI 元件圖（部分已刪除，2026-10-27，見 D27）：
    - 已刪除（使用者 2026-10-27 決定；已被 D27 取代）：網格 `hud_digit_0`~`hud_digit_9`、`hud_colon`、`hud_pause_normal`、`hud_pause_pressed`、`hud_boss_face`、`hud_boss_bar_empty`、`hud_boss_bar_full`，以及只描述它們的文字
    - 仍適用的規則（閃爍紅色版 `W`→`r`、暫停鈕按下與停用、數字重疊與對齊、分數位數）已搬到 D27 第十段
    - 原版 9×9 `hud_icon_clock`、`hud_icon_star` 也已刪除（使用者 2026-10-27 確認放大版後）
    - **D26 已全部刪除（2026-10-27），見 D27**（圖在 D27，座標在 D28 v5 總表）


27. [D27] 魔王舌頭血條與 UI 區 v3（使用者已確認，2026-10-27：舌頭血條、下巴少 1 列、低血量不閃爍、暫停觸控區 56×32；放大版時鐘與星形 `hud_icon_clock_l`、`hud_icon_star_l` 亦已確認（2026-10-27），原 9×9 版已刪除；2026-10-26 提議：移除 UI 區魔王血條與魔王臉，改用魔王牙齒下方的紅舌頭當血條，省出空間放大分數與暫停鈕）：
    - 取代關係：D22 的魔王臉、魔王血量條，D26 的 `hud_boss_face`、`hud_boss_bar_empty`、`hud_boss_bar_full`，改由本項取代；D26 的這些網格已於 2026-10-27 刪除
    - **座標已由 D28 v5 取代**：本項的 UI 區 v3 座標表與魔王位置 (116, 84)、舌頭血條 (130, 124)，改為 v5：UI 區高 32、魔王 (116, 68)、舌頭血條 (130, 108)；HUD 見 D28；圖與網格不變
    - 座標：魔王圖內部座標（128×48）與螢幕座標都從 0 起算；魔王螢幕位置 (116, 84)（D22）
    - 只用 D01 現有顏色，沒有新增顏色

    **一、現有舌頭評估（`boss_normal`，D12）**

    | 項目 | 現況 | 評估 |
    |---|---|---|
    | 嘴巴範圍 | 外框第 13~114 欄、第 36~43 列；內寬 100（第 14~113 欄） | 嘴本身夠寬 |
    | 牙齒 | 第 37~39 列：`W`、`W`、`G` | 在舌頭正上方，保留 |
    | 舌頭 | 第 23~104 欄（82 px 寬）、第 40~42 列（`r`、`R`、`t` 各 1 列，共 3 px 高）；兩端第 13~22、105~114 欄是 `K` | 82 px 可當血條，但只有 3 px 高，3 倍放大後約 9 px，偏細；兩端 20 px 的 `K` 浪費了嘴寬 |
    | 結論 | 勉強可用，建議加大 | 畫新版 `boss_normal_v2`：舌頭撐滿嘴內寬 100 px、高 4 px，1 px ＝ 1% 血量 |

    **二、新版魔王 `boss_normal_v2`（只改嘴巴與舌頭區）**

    | 項目 | 規則 |
    |---|---|
    | 做法 | 不整張重畫：新增補丁疊加圖 `boss_mouth_v2_patch`（128×48，只有第 40~44 列有像素，其餘 `.`），**疊在 `boss_normal` 上**（非 `.` 蓋過原像素，規則同 D12 裂痕疊加）得到 `boss_normal_v2`；其他像素必然與原圖相同 |
    | 舌頭（滿血） | 第 14~113 欄（100 px 寬）、第 40~43 列（4 px 高）：第 40 列 `r`、第 41~42 列 `R`、第 43 列 `t`；左右緊貼嘴外框 `K`（第 13、114 欄） |
    | 嘴外框下緣 | 由第 43 列下移到第 44 列（`K`，第 13~114 欄）；第 44 列左右兩側（第 3~12、115~124 欄）改 `Z`（原為下巴暗色 `z`） |
    | 下巴 | 原第 44 列的下巴暗色被嘴外框取代，下巴只剩原第 45~46 列（2 px）；第 45~47 列不動 |
    | 嘴內其他部分 | 牙齒（第 37~39 列）不動 |
    | 空的部分 | 另一張 `boss_tongue_empty_v2`（100×4，全 `v` #241C30），畫在舌頭上蓋掉失去的部分 |
    | 為什麼用「滿舌頭 + 空條蓋上」 | 魔王被擊中的全白幀（D12 自動規則）與其他自動產生圖都以 `boss_normal_v2` 為底，不必為每個血量各畫一張 |

    **三、血條規則**

    | 項目 | 規則 |
    |---|---|
    | 血條範圍 | 螢幕 x 130~229、y 124~127（魔王內第 14~113 欄、第 40~43 列），100×4 |
    | 滿血 | 舌頭完整（`boss_normal_v2` 原樣） |
    | 扣血 | 舌頭**由右端往左縮**，左端固定；失去的部分顯示 `v` 空條 |
    | fill_px | 向上取整（100 × 目前血量 ÷ 本關血量上限），限制在 0~100；血量 > 0 時至少 1；血量 0 時為 0（只剩空條，隨即進入魔王破壞動畫） |
    | 裁切畫法 | 先畫 `boss_normal_v2`；再把 `boss_tongue_empty_v2` 的來源矩形（x 從 fill_px 到 99、全部 4 列）畫到螢幕 (130 + fill_px, 124)；fill_px = 100 時不畫 |
    | 解析度 | 血量上限最高 1000，1 px 約 10 血；仍不顯示數字 |
    | 非魔王關 | 不畫，與一般磚無關 |

    **四、與其他圖的關係**

    | 項目 | 關係與解法 |
    |---|---|
    | 被擊中（全白 1 幀） | D12 規則把非 `K`、`.` 的像素全變 `W`，舌頭也變白，沒有衝突；需要 `boss_hit_v2`（由工具對 `boss_normal_v2` 產生）；空條 `boss_tongue_empty_v2` 照常畫在白色魔王上（失去的部分保持暗色），該幀只有 100 ms；D22 原「失去的那段先 `W` 100 ms」由全白幀取代，不另做 |
    | 裂痕疊加（F1） | 裂痕 `K` 直線在第 63~65 欄穿過舌頭（第 40~43 列），舌頭被切開 1 px 的暗縫；血條仍可讀，**不改裂痕圖**；繪製順序：`boss_normal_v2` → 空條 → 裂痕 → 炸彈標記 |
    | 炸彈標記 `bomb_mark_boss_overlay` | 在第 109~123 欄、第 3~14 列（右眉附近），與舌頭（第 40~43 列）相隔很遠，**沒有衝突**，圖不改 |
    | 無敵外框 | 魔王不受「無敵」影響（D14），不套外框，**沒有衝突** |
    | 破壞幀 F2~F4 | 它們是另畫的圖，沒有舌頭（Grep 確認無長串紅色像素）；血量 0 時舌頭已空，接 F2 不會出現紅舌頭，**不需要 v2 版**；唯一差別是 F2 的下巴比 v2 多 1 列，1 幀 100 ms 內看不出 |
    | 舌頭與紅磚混淆 | 舌頭在魔王嘴內、四周有 `K` 外框與白色牙齒，位置固定；紅磚是 32×16 的磚，離魔王嘴有 20 px 以上；玩家混淆風險低。血條空的部分是暗紫 `v`，與磚的紅差異大 |
    | 血量低時提示 | **不閃爍**（使用者 2026-10-27 決定）：舌頭只靠長度表示血量，不加任何低血量提示 |

    **五、UI 區 v3（高 800，UI 區 y 0~47，底色 `K`）**

    | 決定 | 內容 | 理由 |
    |---|---|---|
    | 移除 | 魔王臉、魔王血條（UI 區第 2 排右側整塊空出） | 改用舌頭血條 |
    | 數字放大 | 時間與分數**共用同一組大數字** `hud_digit_l_0`~`_9`、`hud_colon_l`：D12 的 5×7 字形 2 倍放大（10×14 白字）加 1 px `K` 描邊，每格 **12×16**；冒號格 6×16 | 與多層磚數字風格一致；整數倍放大不失真；時間也放大，因為要與分數同一套（使用者要求） |
    | 字距 | 相鄰格起點相差：數字 +11、冒號 +5（描邊重疊 1 px，字間仍有 1 px 空隙，規則見第十段） | 同第十段 |
    | 時鐘、星形 | （2026-10-27 已改）**保留並畫放大版** `hud_icon_clock_l`、`hud_icon_star_l`（14×14，見第九段）；原 9×9 版已刪除 | 使用者 2026-10-27 決定保留並已確認放大版 |
    | 暫停鈕 | 放大為 24×24：`hud_pause_l_normal`、`hud_pause_l_pressed`（兩條各 6×16 填色加 `K` 描邊；按下偏右下 1 px、填色變灰，見第十段） | 約 1.5 倍；右側空間夠 |
    | 暫停觸控區 | 56×48（x 304~359、y 0~47，貼右緣到 UI 區下緣），3 倍放大約 168×144 實體像素 | 原 48×24 偏小；整個右欄都能按，圖示在正中 |
    | HUD 球狀態列（D16） | 位置不變 (8, 24, 178, 22) | 沒有理由移動 |
    | 第 2 排右側 | x 190~303、y 24~47 留空 | 可留給之後的功能；不放元件（**已由 D28 v5 取代**：HUD 已移出，分數已用到此區，UI 區縮成 32） |

    **UI 區 v3 座標表（新增，不覆寫 D22 舊表；螢幕座標，x, y, 寬, 高）**

    | 元素 | x | y | 寬 | 高 | 說明 |
    |---|---|---|---|---|---|
    | UI 區底 | 0 | 0 | 360 | 48 | `K` |
    | 時鐘圖示 | 8 | 7 | 9 | 9 | 舊版 9×9（已刪除，改為放大版 `hud_icon_clock_l`，座標見 D28 v5） |
    | 時間數字（`MM:SS`） | 20 | 4 | 12 | 16 | 格起點 x：20、31、42（冒號 6 寬）、47、58；最右到 x 69 |
    | 時間數字（`M:SS`） | 20 | 4 | 12 | 16 | 格起點 x：20、31（冒號）、36、47；最右到 x 58 |
    | 分數數字（已修改，待再確認） | 見說明 | 16 | 12 | 16 | 在暫停鈕正左邊，與暫停鈕垂直置中（鈕 y 12~35，中心 23.5；數字 y 16~31，中心 23.5）；靠右：最右格起點 x = 286（x 286~297），往左每位 −11；**最多 8 位**，最左格起點 x = 209 |
    | 星形圖示（已修改，待再確認） | 285 − 11 × 位數 | 19 | 9 | 9 | 緊貼最左一位，間隔 3 px，y 19 使星形與數字同一水平線；1 位 x 274；8 位 x 197；舊版 9×9（已刪除，改為放大版 `hud_icon_star_l`，座標見 D28 v5） |
    | 暫停鈕圖 | 332 | 12 | 24 | 24 | x 332~355、y 12~35，在觸控區正中 |
    | 暫停觸控區 | 304 | 0 | 56 | 48 | x 304~359、y 0~47 |
    | HUD 球狀態列（D16） | 8 | 24 | 178 | 22 | 位置已由 D28 取代（待確認）；D28 把 HUD 移到關卡區內，本表分數與時間位置亦以 D28 的 v4 表為準 |
    | 魔王舌頭血條（螢幕） | 130 | 124 | 100 | 4 | 在魔王嘴內，不在 UI 區；只在第 10 的倍數關 |

    - 分數靠右的右端 x 297，離觸控區 x 304 留 6 px
    - 時間維持在 y 4（x 8~69）、不跟著下移：分數下移到 y 16~31 後，時間若也下移會與 HUD 球狀態列（x 8~185、y 24~45）重疊；時間在上排、分數與暫停鈕在右側同高，兩者不在同一水平線，是為避開 HUD 的取捨（待使用者確認）
    - 分數位數上限改為 8 位（99,999,999）：分數下移後，星形左端 x 197 才與 HUD 右端 x 185 留 12 px；超過 8 位的星形會與 HUD（y 24~27 重疊段）相撞；不加千分位逗號、0 分顯示單一 `0`（規則見第十段）；v4 起已恢復 14 位
    - 閃爍紅色版：見第十段，大數字與冒號、時鐘的 `W` 換成 `r`
    - 對比：大數字仍是 `W` 對 `K` 底，約 17:1，不變

    **六、給工程師的需求（由 PM 轉達）**

    - 工具：新增 `boss_normal_v2` ＝ `boss_normal` 疊 `boss_mouth_v2_patch`（規則同裂痕疊加）；由 `boss_normal_v2` 產生 `boss_hit_v2`（D12 全白規則）；轉出 `boss_tongue_empty_v2`
    - 程式：魔王關改用舌頭血條，依「血條規則」裁切；繪製順序 `boss_normal_v2` → `boss_tongue_empty_v2` → 裂痕 → 炸彈標記；被擊中幀用 `boss_hit_v2`；UI 區依 v3 座標表排版（移除魔王臉與血條）
    - 舊圖：`hud_boss_face`、`hud_boss_bar_*` 已於 2026-10-27 刪除（不再轉檔）

    圖寬：12　圖高：16
    大數字 0（id: hud_digit_l_0）：
    ```text
    ..KKKKKKKK..
    ..KWWWWWWK..
    KKKWWWWWWKKK
    KWWKKKKKKWWK
    KWWK....KWWK
    KWWK....KWWK
    KWWK....KWWK
    KWWK....KWWK
    KWWK....KWWK
    KWWK....KWWK
    KWWK....KWWK
    KWWK....KWWK
    KWWKKKKKKWWK
    KKKWWWWWWKKK
    ..KWWWWWWK..
    ..KKKKKKKK..
    ```

    圖寬：12　圖高：16
    大數字 1（id: hud_digit_l_1）：
    ```text
    ....KKKK....
    ....KWWK....
    ..KKKWWK....
    ..KWWWWK....
    ..KWWWWK....
    ..KKKWWK....
    ....KWWK....
    ....KWWK....
    ....KWWK....
    ....KWWK....
    ....KWWK....
    ....KWWK....
    ..KKKWWKKK..
    ..KWWWWWWK..
    ..KWWWWWWK..
    ..KKKKKKKK..
    ```

    圖寬：12　圖高：16
    大數字 2（id: hud_digit_l_2）：
    ```text
    ..KKKKKKKK..
    ..KWWWWWWK..
    KKKWWWWWWKKK
    KWWKKKKKKWWK
    KWWK....KWWK
    KKKK....KWWK
    ......KKKWWK
    ......KWWKKK
    ....KKKWWK..
    ....KWWKKK..
    ..KKKWWK....
    ..KWWKKK....
    KKKWWKKKKKKK
    KWWWWWWWWWWK
    KWWWWWWWWWWK
    KKKKKKKKKKKK
    ```

    圖寬：12　圖高：16
    大數字 3（id: hud_digit_l_3）：
    ```text
    KKKKKKKKKK..
    KWWWWWWWWK..
    KWWWWWWWWKKK
    KKKKKKKKKWWK
    ........KWWK
    ........KWWK
    ..KKKKKKKWWK
    ..KWWWWWWKKK
    ..KWWWWWWKKK
    ..KKKKKKKWWK
    ........KWWK
    ........KWWK
    KKKKKKKKKWWK
    KWWWWWWWWKKK
    KWWWWWWWWK..
    KKKKKKKKKK..
    ```

    圖寬：12　圖高：16
    大數字 4（id: hud_digit_l_4）：
    ```text
    ......KKKK..
    ......KWWK..
    ....KKKWWK..
    ....KWWWWK..
    ..KKKWWWWK..
    ..KWWKKWWK..
    KKKWWKKWWK..
    KWWKKKKWWK..
    KWWKKKKWWKKK
    KWWWWWWWWWWK
    KWWWWWWWWWWK
    KKKKKKKWWKKK
    ......KWWK..
    ......KWWK..
    ......KWWK..
    ......KKKK..
    ```

    圖寬：12　圖高：16
    大數字 5（id: hud_digit_l_5）：
    ```text
    KKKKKKKKKKKK
    KWWWWWWWWWWK
    KWWWWWWWWWWK
    KWWKKKKKKKKK
    KWWKKKKKKK..
    KWWWWWWWWK..
    KWWWWWWWWKKK
    KKKKKKKKKWWK
    ........KWWK
    ........KWWK
    KKKK....KWWK
    KWWK....KWWK
    KWWKKKKKKWWK
    KKKWWWWWWKKK
    ..KWWWWWWK..
    ..KKKKKKKK..
    ```

    圖寬：12　圖高：16
    大數字 6（id: hud_digit_l_6）：
    ```text
    ..KKKKKKKK..
    ..KWWWWWWK..
    KKKWWWWWWK..
    KWWKKKKKKK..
    KWWK........
    KWWK........
    KWWKKKKKKK..
    KWWWWWWWWK..
    KWWWWWWWWKKK
    KWWKKKKKKWWK
    KWWK....KWWK
    KWWK....KWWK
    KWWKKKKKKWWK
    KKKWWWWWWKKK
    ..KWWWWWWK..
    ..KKKKKKKK..
    ```

    圖寬：12　圖高：16
    大數字 7（id: hud_digit_l_7）：
    ```text
    KKKKKKKKKKKK
    KWWWWWWWWWWK
    KWWWWWWWWWWK
    KKKKKKKKKWWK
    ......KKKWWK
    ......KWWKKK
    ....KKKWWK..
    ....KWWKKK..
    ....KWWK....
    ....KWWK....
    ....KWWK....
    ....KWWK....
    ....KWWK....
    ....KWWK....
    ....KWWK....
    ....KKKK....
    ```

    圖寬：12　圖高：16
    大數字 8（id: hud_digit_l_8）：
    ```text
    ..KKKKKKKK..
    ..KWWWWWWK..
    KKKWWWWWWKKK
    KWWKKKKKKWWK
    KWWK....KWWK
    KWWK....KWWK
    KWWKKKKKKWWK
    KKKWWWWWWKKK
    KKKWWWWWWKKK
    KWWKKKKKKWWK
    KWWK....KWWK
    KWWK....KWWK
    KWWKKKKKKWWK
    KKKWWWWWWKKK
    ..KWWWWWWK..
    ..KKKKKKKK..
    ```

    圖寬：12　圖高：16
    大數字 9（id: hud_digit_l_9）：
    ```text
    ..KKKKKKKK..
    ..KWWWWWWK..
    KKKWWWWWWKKK
    KWWKKKKKKWWK
    KWWK....KWWK
    KWWK....KWWK
    KWWKKKKKKWWK
    KKKWWWWWWWWK
    ..KWWWWWWWWK
    ..KKKKKKKWWK
    ........KWWK
    ........KWWK
    ..KKKKKKKWWK
    ..KWWWWWWKKK
    ..KWWWWWWK..
    ..KKKKKKKK..
    ```

    圖寬：6　圖高：16
    大冒號（id: hud_colon_l）：
    ```text
    ......
    ......
    ......
    KKKKKK
    KWWWWK
    KWWWWK
    KWWWWK
    KKKKKK
    KKKKKK
    KWWWWK
    KWWWWK
    KWWWWK
    KKKKKK
    ......
    ......
    ......
    ```

    圖寬：24　圖高：24
    大暫停鈕：正常（id: hud_pause_l_normal）：
    ```text
    ........................
    ........................
    ........................
    ..KKKKKKKK....KKKKKKKK..
    ..KWWWWWGK....KWWWWWGK..
    ..KWWWWWGK....KWWWWWGK..
    ..KWWWWWGK....KWWWWWGK..
    ..KWWWWWGK....KWWWWWGK..
    ..KWWWWWGK....KWWWWWGK..
    ..KWWWWWGK....KWWWWWGK..
    ..KWWWWWGK....KWWWWWGK..
    ..KWWWWWGK....KWWWWWGK..
    ..KWWWWWGK....KWWWWWGK..
    ..KWWWWWGK....KWWWWWGK..
    ..KWWWWWGK....KWWWWWGK..
    ..KWWWWWGK....KWWWWWGK..
    ..KWWWWWGK....KWWWWWGK..
    ..KWWWWWGK....KWWWWWGK..
    ..KWWWWWGK....KWWWWWGK..
    ..KWWWWWGK....KWWWWWGK..
    ..KKKKKKKK....KKKKKKKK..
    ........................
    ........................
    ........................
    ```

    圖寬：24　圖高：24
    大暫停鈕：按下（id: hud_pause_l_pressed）：
    ```text
    ........................
    ........................
    ........................
    ........................
    ...KKKKKKKK....KKKKKKKK.
    ...KGGGGG8K....KGGGGG8K.
    ...KGGGGG8K....KGGGGG8K.
    ...KGGGGG8K....KGGGGG8K.
    ...KGGGGG8K....KGGGGG8K.
    ...KGGGGG8K....KGGGGG8K.
    ...KGGGGG8K....KGGGGG8K.
    ...KGGGGG8K....KGGGGG8K.
    ...KGGGGG8K....KGGGGG8K.
    ...KGGGGG8K....KGGGGG8K.
    ...KGGGGG8K....KGGGGG8K.
    ...KGGGGG8K....KGGGGG8K.
    ...KGGGGG8K....KGGGGG8K.
    ...KGGGGG8K....KGGGGG8K.
    ...KGGGGG8K....KGGGGG8K.
    ...KGGGGG8K....KGGGGG8K.
    ...KGGGGG8K....KGGGGG8K.
    ...KKKKKKKK....KKKKKKKK.
    ........................
    ........................
    ```

    圖寬：100　圖高：4
    魔王空舌頭條（id: boss_tongue_empty_v2）：
    ```text
    vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
    vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
    vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
    vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
    ```

    圖寬：128　圖高：48
    魔王嘴巴補丁疊加圖（疊在 boss_normal 上得 boss_normal_v2）（id: boss_mouth_v2_patch）：
    ```text
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    .............KrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrK.............
    .............KRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRK.............
    .............KRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRK.............
    .............KttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttK.............
    KuQZZZZZZZZZZKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKZZZZZZZZZZzvK
    ................................................................................................................................
    ................................................................................................................................
    ................................................................................................................................
    ```

    **新線框圖例（layout_800_v3）**（1 字元 = 4 px；90 字元 = 360 px，200 列 = 800 px；只用 D01 顏色；以 4 px 為單位取近似，精確位置以 v3 座標表為準）

    | 字元 | 代表 | 對應 y 範圍 |
    |---|---|---|
    | `v` | UI 區底（實際色為 `K`；線框改用 `v` 以和關卡區的 `K` 區分） | 列 0~11（y 0~47） |
    | `x` | 時間（時鐘加大數字，最寬到 x 71） | 列 1~4，欄 2~17 |
    | `Y` | 分數（星形加大數字，8 位時 x 197~299；與暫停鈕垂直置中；座標表算出右端為 x 297，線框以 4 px 取整；**本圖例已由 D28 v5 取代**） | 列 4~7（y 16~31），欄 49~74 |
    | `t` | 暫停觸控區 56×48（x 304~359） | 列 0~11，欄 76~89 |
    | `R` | 暫停鈕圖示 24×24（x 332~355、y 12~35） | 列 3~8，欄 83~88 |
    | `U` | HUD 球狀態列（D16） | 列 6~11 |
    | `c` | 上邊框左右轉角（各 20×20） | 列 12~16（y 48~67） |
    | `h` | 上邊框 | 列 12~16 |
    | `g` | 左右邊框（轉角以下，到螢幕底端） | 列 17~199 |
    | `K` | 關卡區：磚塊上方空帶（y 68~83）與球的飛行空間（y 436~719） | 列 17~20 與 109~179 |
    | `b` | 磚塊區（最多 22 排：y 84~435） | 列 21~108 |
    | `Q` | 魔王位置（第 3~6 欄、最上 3 排；只在第 10 的倍數關；舌頭血條在魔王嘴內，約列 31） | 列 21~32 |
    | `s` | 手指區（y 720~799，零 UI） | 列 180~199 |
    | `e` | 擋板（y 763、寬 64） | 列 190~191 |

    圖寬：90　圖高：200
    高 800 v3 線框（id: layout_800_v3）：
    ```text
    vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvtttttttttttttt
    vvxxxxxxxxxxxxxxxxvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvtttttttttttttt
    vvxxxxxxxxxxxxxxxxvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvtttttttttttttt
    vvxxxxxxxxxxxxxxxxvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvtttttttRRRRRRt
    vvxxxxxxxxxxxxxxxxvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvYYYYYYYYYYYYYYYYYYYYYYYYYYvtttttttRRRRRRt
    vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvYYYYYYYYYYYYYYYYYYYYYYYYYYvtttttttRRRRRRt
    vvUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUvvYYYYYYYYYYYYYYYYYYYYYYYYYYvtttttttRRRRRRt
    vvUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUvvYYYYYYYYYYYYYYYYYYYYYYYYYYvtttttttRRRRRRt
    vvUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUvvvvvvvvvvvvvvvvvvvvvvvvvvvvvtttttttRRRRRRt
    vvUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUvvvvvvvvvvvvvvvvvvvvvvvvvvvvvtttttttttttttt
    vvUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUvvvvvvvvvvvvvvvvvvvvvvvvvvvvvtttttttttttttt
    vvUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUvvvvvvvvvvvvvvvvvvvvvvvvvvvvvtttttttttttttt
    ccccchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhccccc
    ccccchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhccccc
    ccccchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhccccc
    ccccchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhccccc
    ccccchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhccccc
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggsssssssssssssssssssssssssssssssseeeeeeeeeeeeeeeessssssssssssssssssssssssssssssssggggg
    gggggsssssssssssssssssssssssssssssssseeeeeeeeeeeeeeeessssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    ```

    **九、使用者 2026-10-27 的決定**

    | 決定 | 內容 | 落實 |
    |---|---|---|
    | 舌頭血條 | 採用（`boss_normal_v2` 加 `boss_tongue_empty_v2`） | 使用者已確認 |
    | 低血量提示 | **不閃爍** | 取消第四段的「剩 20% 以下切換 `W`」提案；舌頭只靠長度表示血量 |
    | 魔王下巴少 1 列 | 可以 | `boss_normal_v2` 維持現狀 |
    | 暫停觸控區 56×32 | 可以 | 見 D28 v5 總表 |
    | 時鐘與星形 | **保留，並畫放大版** | `hud_icon_clock_l`、`hud_icon_star_l`（14×14，見下；使用者已確認，2026-10-27）；原版 9×9 已刪除 |
    | D26 舊版 | 已被取代的舊元件**刪除** | D26 已刪 `hud_digit_0`~`9`、`hud_colon`、`hud_pause_normal`、`hud_pause_pressed`、`hud_boss_face`、`hud_boss_bar_empty`、`hud_boss_bar_full`；仍適用的規則搬到下面第十段 |

    **放大版圖示（使用者已確認，2026-10-27）**

    | 項目 | 內容 | 理由 |
    |---|---|---|
    | 尺寸 | 14×14 | 16 高大數字（y 8~23）內垂直置中，上下各留 1 px；比 9×9 與大數字比例相稱 |
    | `hud_icon_clock_l` | 白面 `W`、`K` 描邊、粗針（2 px 寬）：分針向上、時針向右 | 畫風同原 9×9 時鐘（已刪除）放大 |
    | `hud_icon_star_l` | 黃 `Y`、`K` 描邊 | 畫風同原 9×9 星形（已刪除）放大 |
    | 顏色 | 只用 `K`、`W`、`Y` | D01 現有 |
    | 閃爍紅色版 | 時鐘的 `W` 換 `r`（規則見第十段）；星形不換色 | 同原規則 |

    | 元素 | v5 座標（螢幕座標，x, y, 寬, 高） | 說明 |
    |---|---|---|
    | 時鐘圖示（放大） | 8, 9, 14, 14 | y 9~22，中心 15.5，與數字（y 8~23）同中心線 |
    | 時間數字（`MM:SS`） | 第 1 格 x 25；格起點 x：25、36、47（冒號）、52、63；y 8 | 時鐘右端 x 21 與第 1 格間隔 3 px；最右到 x 74 |
    | 時間數字（`M:SS`） | 格起點 x：25、36（冒號）、41、52 | 同上 |
    | 星形圖示（放大） | x = 280 − 11 × 位數，y 9，14×14 | 緊貼最左一位，間隔 3 px（星形右端 + 3 = 最左位數起點 297 − 11 × 位數）；14 位時 x 126，不與時間（右端 x 74）相撞 |

    圖寬：14　圖高：14
    放大時鐘圖示（id: hud_icon_clock_l）：
    ```text
    ....KKKKKK....
    ..KKWWWWWWKK..
    .KWWWWWWWWWWK.
    .KWWWWKKWWWWK.
    .KWWWWKKWWWWK.
    .KWWWWKKWWWWK.
    .KWWWWKKWWWWK.
    .KWWWWKKKKKWK.
    .KWWWWKKKKKWK.
    .KWWWWWWWWWWK.
    .KWWWWWWWWWWK.
    .KWWWWWWWWWWK.
    ..KKWWWWWWKK..
    ....KKKKKK....
    ```

    圖寬：14　圖高：14
    放大星形圖示（id: hud_icon_star_l）：
    ```text
    ......KK......
    .....KYYK.....
    .....KYYK.....
    ....KYYYYK....
    KKKKKYYYYKKKKK
    KYYYYYYYYYYYYK
    .KYYYYYYYYYYK.
    ..KYYYYYYYYK..
    ...KYYYYYYK...
    ...KYYYYYYK...
    ..KYYYKKYYYK..
    .KYYYK..KYYYK.
    .KYYK....KYYK.
    .KKK......KKK.
    ```

    **十、由 D26 搬入的規則（D26 舊網格已刪除；本段取代 D26 原文，「同 D26」一律以本段為準）**

    | 項目 | 規則 |
    |---|---|
    | 數字字形 | 大數字 `hud_digit_l_0`~`9`、`hud_colon_l`（本項）；白色填色 `W` 加 `K` 描邊；每格 12×16，冒號格 6×16 |
    | 字格重疊 | 相鄰格起點相差：數字 +11、冒號 +5（描邊重疊 1 px）；重疊的欄只有 `K` 或透明，只畫非透明像素，不會蓋掉 `W` |
    | 位置 | 時間靠左、接在時鐘圖示後（位數少就整串靠左，不置中）；分數靠右對齊，最右格起點 x 286，往左每位 −11 |
    | 時間格式 | `M:SS`（9:59 以下）或 `MM:SS`（最長約 11:40） |
    | 分數位數 | 上限 **14 位**（99,999,999,999,999）；不加千分位逗號；前導零不顯示；0 分顯示單一 `0` |
    | 數字變動 | 直接換圖，不加動態（D22 已定） |
    | 閃爍紅色版 | 把圖裡的 `W` 換成 `r`（#E8696B），`K` 描邊不變；套用時鐘圖示、時間數字、冒號；**不套用**分數、星形、暫停鈕；紅色那 500 ms 依 D22「時間倒數與閃爍」；0 秒停在紅色；程式以顏色映射實作，不需第二套圖檔 |
    | 暫停鈕按下 | 整個圖形向右下偏 1 px（`hud_pause_l_pressed` 已畫好），填色改 `G` 加 `8`（變灰），放開恢復（使用者 2026-10-26 同意） |
    | 暫停鈕停用 | 不另畫圖；D22 的停用狀態（灰 `8`）由程式把 `W`、`G` 換成 `8` |
    | 顏色 | 全部取自 D01：`K` `W` `Y` `G` `8` `r` `j` `v` 等；不新增符號 |

    對比（手算近似；UI 區底 `K`，亮度 L 0.0117）：

    | 元件 | 顏色 | 對 `K` 底 |
    |---|---|---|
    | 數字、冒號、時鐘 | `W` | 約 17:1 |
    | 數字紅色版 | `r` | 約 5.4:1（達 4.5:1） |
    | 星形 | `Y` | 約 12:1 |
    | 暫停鈕正常 | `W`、`G` | 約 17:1、9:1 |
    | 暫停鈕按下 | `G`、`8` | 約 9:1、6.9:1 |

    - 舊的魔王臉與血條外框規則隨 D26 網格一併刪除（已改用舌頭血條，見第三段）；D22 的「受傷白段」規則已由全白幀取代，不再適用

28. [D28] HUD 球狀態列移到關卡區內（半透明懸浮）兩方案與 UI 區 v4（使用者已確認 2026-10-26：方案 B、不透明度 50%、有狀態往上補位、UI 區縮成 32、HUD 整數 2 倍；v5 座標、第 1 格 y 424、維持 22 排皆已確認；唯一待微調：50% 下線段條外框偏淡，見「七、使用者決定與 v5」）：
    - 取代關係：D16 的「HUD 位置」（UI 區第 2 排 x 8、y 24）、D22 座標表的 HUD 列、D27 v3 座標表的 HUD 列與分數／時間位置，改由本項取代；原文保留，標「位置已由 D28 取代（待確認）」
    - 座標：螢幕座標，從 0 起算；格 22×22、格距 4、7 格，與 D16 相同；圖示、線段條、數字、暫停鈕外觀都不改

    **一、兩方案共用規則**

    | 項目 | 決定 | 理由 |
    |---|---|---|
    | 排列順序 | 沿用 D16：強化、fever、減速、加速、穿透、火焰、炸彈；7 個**固定格位**，沒有的狀態該格留空、**不補位** | 玩家憑位置記憶；位置不因別的狀態消失而跳動 |
    | 整組長度 | 7 × 22 + 6 × 4 = 178 px（橫向是寬、垂直是高） | D16 不變 |
    | 不透明度 | **建議 70%**（整組 HUD 一個統一的 alpha，由程式調整，不畫新圖） | 見下方對比；60% 看起來更「透」但外框更淡；100% 就不是懸浮了 |
    | 繪製層級（由下到上） | 背景 → 磚塊、擋板 → **HUD（半透明）** → 掉落道具 → 球光暈 → 球本體 | 球與道具永遠看得見，HUD 絕不蓋住它們 |
    | 球經過時 | 球本體畫在 HUD 之上，不另做避讓、不自動淡出 | 避免 HUD 忽隱忽現；球在 HUD 後面短暫經過仍可辨識 |
    | 道具經過時 | 掉落道具（D20、D21，不透明）畫在 HUD 之上；道具的 12×12 圖案與 HUD 同款，但道具不透明且在掉落，與 HUD 分得開 | 玩家不會把半透明的 HUD 當成可接的道具 |

    對比（手算近似；背景 Y ≈ 22，亮度 L ≈ 0.008；混色＝不透明度 × 圖 + (1 − 不透明度) × 背景）：

    | 元素 | 原色 Y | 70% 後 Y | 對背景 | 60% 後 Y | 對背景 |
    |---|---|---|---|---|---|
    | 白色線段 `W` | 255 | 約 185 | 約 9:1 | 約 162 | 約 7:1 |
    | 圖示底板面 `g` | 95 | 約 73 | 約 2.0:1 | 約 66 | 約 1.8:1 |
    | 線段條外框 `j` | 61 | 約 49 | 約 1.4:1 | 約 45 | 約 1.3:1 |
    | 圖示描邊 `K` | 29 | 約 27 | 與背景幾乎同色（本來就是描邊深色） | 約 26 | 同左 |

    - 白色線段與圖示內容仍清楚；底板靠亮邊 `f`、暗邊 `j` 與內容辨識；**線段條外框 `j` 對背景只有約 1.4:1，比 UI 區底時更淡**（D27 前的問題會回來），是半透明的已知代價
    - 若使用者覺得外框太淡：可把不透明度提高到 80%（外框約 1.5:1），或日後另畫去底板的版本（見第五段）

    **二、方案 A：橫向一排，懸浮在擋板下方**

    | 項目 | 內容 |
    |---|---|
    | 位置 | y 774~795（擋板 y 763~770，下方空白 y 771~799 共 29 px；上留 3 px、下留 4 px）；水平置中於關卡區 x 20~339：x 91~268 |
    | 格 1 強化 | x 91、y 774 |
    | 格 2 fever | x 117、y 774 |
    | 格 3 減速 | x 143、y 774 |
    | 格 4 加速 | x 169、y 774 |
    | 格 5 穿透 | x 195、y 774 |
    | 格 6 火焰 | x 221、y 774 |
    | 格 7 炸彈 | x 247、y 774 |
    | 順序 | 由左到右，同 D16 |

    **三、方案 B：垂直排列在關卡區左下角**

    | 項目 | 內容 |
    |---|---|
    | 位置 | x 24~45（左邊框內緣 x 19 與 HUD 之間留 4 px）、y 574~751；底端離擋板上緣 y 763 有 12 px，**不與擋板重疊**（使用者圈的範圍到 y 780，本方案刻意縮短到 y 751 讓出擋板高度） |
    | 格 1 強化 | x 24、y 574 |
    | 格 2 fever | x 24、y 600 |
    | 格 3 減速 | x 24、y 626 |
    | 格 4 加速 | x 24、y 652 |
    | 格 5 穿透 | x 24、y 678 |
    | 格 6 火焰 | x 24、y 704 |
    | 格 7 炸彈 | x 24、y 730 |
    | 順序 | **由上往下**，同 D16 的由左到右順序；強化、fever 等常駐的在上，限時的在下（離球與擋板較近、較容易被看見） |
    | 格內結構 | 不變：圖示在上、線段條在下（格 22×22），垂直排列時每格仍是「圖示＋下方線段」 |

    **四、問題評估與處理**

    | 問題 | 方案 A（擋板下方橫排） | 方案 B（左下垂直） |
    |---|---|---|
    | 手指拖擋板遮擋 | **嚴重**：擋板正下方就是拇指停的位置（y 771~799），HUD 幾乎一直被手指蓋住；處理：無，位置本身的問題 | 輕微：在左側、擋板上方；左手玩家的拇指在擋板高度以下，不會蓋到 y 574~751；右手拖到最左邊時手背可能蓋到一部分 |
    | 與 D22「手指區 y 720~799 零 UI」 | **違反**（HUD 整排在手指區內）；若採 A，需使用者同意改寫該規則 | 部分違反：y 720~751 在手指區上緣 32 px 內；其餘在手指區之上 |
    | 球與道具看得清楚嗎 | 球掉出擋板下方才經過 HUD，已是漏球，影響小；道具漏接掉過 HUD，道具畫在 HUD 之上，看得清楚 | 球在左邊框附近彈跳時會經過 HUD 後方；球畫在 HUD 之上、半透明 HUD 不蓋球，看得清楚；道具同理 |
    | HUD 是否蓋住球或道具 | 不會（HUD 在球與道具之下） | 不會 |
    | 擋板最長 320（滿寬）時 | 擋板 y 763~770 與 HUD y 774~795 垂直錯開 3 px，**不重疊**；但擋板貼著 HUD 上緣，視覺很擠 | 擋板在 y 763 以下，HUD 到 y 751，不重疊；擋板在最左端時離 HUD 底端 12 px |
    | 與背景對比 | 底部背景最暗、最單純（Y ≤ 40），70% 的 HUD 對比同上表 | 同上；左下角若有 D25 裝飾（灌木、石筍等）會疊在 HUD 後方，只影響外框（本來就淡） |
    | 與左邊框距離 | 不適用 | 左邊框內緣 x 19，HUD 左緣 x 24，留 4 px；球碰左牆彈回時（x 20 起）會從 HUD 上方通過 |
    | 系統手勢區（底部橫條、導覽列） | **衝突**：y 774~799 是常見的系統手勢區，手勢操作可能誤觸；處理：只能整體上移，等於放棄方案 A | 無衝突 |
    | 佔用球的飛行空間 | 不佔（飛行空間 y 436~719 不變） | 佔左側 22 px 寬 × 178 px 高（約 y 574~751，與飛行空間下半重疊）；球可穿過但看起來有東西 |
    | 其他 | 橫排像 D16 原本的樣子，不需要重新習慣 | 垂直排列需要玩家把視線放到左下角；與「球從下往上」的視線動線一致 |

    - **我的建議：方案 B**。理由：A 的位置正好是拇指與系統手勢區，HUD 幾乎看不到；B 避開手指與擋板，代價是左側 22 px 窄條與飛行空間有些重疊，球經過時 HUD 在球後方、不蓋球
    - 若使用者堅持 A：建議把 HUD 整排上移到擋板之上（y 720~741）並放棄「零 UI 手指區」，我另寫座標；本項不處理

    **五、半透明需要的新圖（只列需求，本次不畫）**

    | 圖 | 需要嗎 | 說明 |
    |---|---|---|
    | 去底板的圖示版本 | 不需要 | 半透明由程式整組調整不透明度；現有底板（`g` 面）在 70% 下仍可辨識 |
    | 加深的線段條外框（例如 `K`） | 視實機決定 | 若 70% 下外框 `j`（約 1.4:1）太淡，可畫一版外框改 `K` 的線段條；`hud_timebar_*`、`hud_reinforce_levels`、`hud_slow_fast_levels` 會需要新 id，屬 D16 範圍的新圖 |
    | 垂直專用圖 | 不需要 | 每格結構不變，只是位置不同 |

    **六、UI 區 v4（HUD 移出後；不覆寫 v3 表）**

    | 決定 | 內容 | 理由 |
    |---|---|---|
    | 同一水平線 | 時間、分數、暫停鈕都以中心線 y 23.5 垂直置中（UI 區高度仍 48） | 使用者要求同一水平線；HUD 已移出，不再有重疊問題 |
    | 分數位數上限 | **恢復 14 位**（最左格起點 x 143、星形 x 131）；時間右端 x 69 與星形最左 x 131 之間仍有 62 px，理論上限約 18 位，仍取 14 位（見 D27 第十段） | 不再需要避開 HUD |
    | 暫停觸控區 | 56×48，同 v3 | 不變 |

    | 元素 | x | y | 寬 | 高 | 說明 |
    |---|---|---|---|---|---|
    | UI 區底 | 0 | 0 | 360 | 48 | `K` |
    | 時鐘圖示 | 8 | 19 | 9 | 9 | 舊版 9×9（已刪除）；v5 起為放大版 14×14，見 D28 v5 總表 |
    | 時間數字（`MM:SS`） | 20 | 16 | 12 | 16 | 格起點 x：20、31、42（冒號）、47、58；`M:SS` 同 v3 |
    | 分數數字 | 最右格起點 286 | 16 | 12 | 16 | 靠右，往左每位 −11；最多 14 位，最左格起點 x 143 |
    | 星形圖示 | 285 − 11 × 位數 | 19 | 9 | 9 | 緊貼最左一位；14 位 x 131；舊版 9×9（已刪除）；v5 起為放大版 14×14，見 D28 v5 總表 |
    | 暫停鈕圖 | 332 | 12 | 24 | 24 | y 12~35，中心 23.5 |
    | 暫停觸控區 | 304 | 0 | 56 | 48 | x 304~359 |
    | HUD（方案 A 或 B） | 見第二、三段 | | | | 在關卡區內 |

    **UI 區高度可以縮小（只是建議，不改關卡區座標）**

    | 項目 | 目前 | 建議（UI 區高 32） |
    |---|---|---|
    | UI 區 | y 0~47（48） | y 0~31（32）：暫停鈕 24 加上下各 4 px 剛好 |
    | 數字（y） | 16 | 8（y 8~23） |
    | 時鐘、星形（y） | 19 | 11 |
    | 暫停鈕圖 | (332, 12) | (332, 4) |
    | 暫停觸控區 | (304, 0, 56, 48) | (304, 0, 56, 32)，3 倍約 168×96 實體像素，仍夠大 |
    | 上邊框 | y 48~67 | y 32~51 |
    | 關卡區 | y 68~799（732） | y 52~799（748），多 16 px |
    | 磚塊起點 | y 84 | y 68（或維持 y 84，把多的 16 px 都給球的飛行空間） |
    | 擋板、手指區 | y 763、720~799 | 不變 |

    - 影響：D22 磚塊區、D23 上邊框與轉角位置、D24 背景可見範圍、D25 擺放座標都要整體上移 16 px；本項**不做**，等使用者決定是否縮小 UI 區

    **七、給工程師的需求（由 PM 轉達）**

    - HUD 位置依使用者選定的方案（A 或 B）改用第二、三段座標；整組套統一不透明度 70%（可設定值）；繪製層級見第一段
    - UI 區依 v4 座標表排版（時間、分數、暫停鈕垂直置中；分數上限 14 位）
    - 不新增圖；若使用者要求更深的外框才另開需求

    線框圖例沿用 v3 的字元，加 `U`（HUD 球狀態列，位置因方案而異；方案 A：列 193~198、欄 22~67；方案 B：列 143~187、欄 6~11）。

    圖寬：90　圖高：200
    高 800 v4 方案 A 線框：HUD 橫排在擋板下方（id: layout_800_v4a）：
    ```text
    vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvtttttttttttttt
    vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvtttttttttttttt
    vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvtttttttttttttt
    vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvtttttttRRRRRRt
    vvxxxxxxxxxxxxxxxxvvvvvvvvvvvvvvYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYvtttttttRRRRRRt
    vvxxxxxxxxxxxxxxxxvvvvvvvvvvvvvvYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYvtttttttRRRRRRt
    vvxxxxxxxxxxxxxxxxvvvvvvvvvvvvvvYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYvtttttttRRRRRRt
    vvxxxxxxxxxxxxxxxxvvvvvvvvvvvvvvYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYvtttttttRRRRRRt
    vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvtttttttRRRRRRt
    vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvtttttttttttttt
    vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvtttttttttttttt
    vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvtttttttttttttt
    ccccchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhccccc
    ccccchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhccccc
    ccccchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhccccc
    ccccchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhccccc
    ccccchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhccccc
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggsssssssssssssssssssssssssssssssseeeeeeeeeeeeeeeessssssssssssssssssssssssssssssssggggg
    gggggsssssssssssssssssssssssssssssssseeeeeeeeeeeeeeeessssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggsssssssssssssssssUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUsssssssssssssssssggggg
    gggggsssssssssssssssssUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUsssssssssssssssssggggg
    gggggsssssssssssssssssUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUsssssssssssssssssggggg
    gggggsssssssssssssssssUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUsssssssssssssssssggggg
    gggggsssssssssssssssssUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUsssssssssssssssssggggg
    gggggsssssssssssssssssUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUsssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    ```

    圖寬：90　圖高：200
    高 800 v4 方案 B 線框：HUD 垂直排列在關卡區左下角（id: layout_800_v4b）：
    ```text
    vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvtttttttttttttt
    vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvtttttttttttttt
    vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvtttttttttttttt
    vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvtttttttRRRRRRt
    vvxxxxxxxxxxxxxxxxvvvvvvvvvvvvvvYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYvtttttttRRRRRRt
    vvxxxxxxxxxxxxxxxxvvvvvvvvvvvvvvYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYvtttttttRRRRRRt
    vvxxxxxxxxxxxxxxxxvvvvvvvvvvvvvvYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYvtttttttRRRRRRt
    vvxxxxxxxxxxxxxxxxvvvvvvvvvvvvvvYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYvtttttttRRRRRRt
    vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvtttttttRRRRRRt
    vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvtttttttttttttt
    vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvtttttttttttttt
    vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvtttttttttttttt
    ccccchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhccccc
    ccccchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhccccc
    ccccchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhccccc
    ccccchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhccccc
    ccccchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhccccc
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggsUUUUUUsssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggsUUUUUUsssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggsUUUUUUsssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggsUUUUUUsssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggsUUUUUUsssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggsUUUUUUsssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggsUUUUUUsssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggsUUUUUUsssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggsssssssssssssssssssssssssssssssseeeeeeeeeeeeeeeessssssssssssssssssssssssssssssssggggg
    gggggsssssssssssssssssssssssssssssssseeeeeeeeeeeeeeeessssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    ```

    **七、使用者決定與 v5（2026-10-26；v5 取代前面的 v3、v4 座標；舊表保留不覆寫）**

    | 決定 | 內容 | 落實 |
    |---|---|---|
    | 方案 | 採**方案 B**（左下直排） | 方案 A 與 `layout_800_v4a` 作廢（保留供對照） |
    | 不透明度 | **50%**（不是 70%） | 對比重算見下 |
    | 排列 | **有狀態就往上補位**：依 D16 固定順序、沒有的狀態不佔格，下面的往上補，從最上一格開始排 | 這一點**改寫 D16 的「固定格位、不補位」**（只限這個新位置的 HUD）；順序仍是強化、fever、減速或加速、穿透、火焰、炸彈 |
    | UI 區 | 由 48 縮成 **32**（D28 第六段建議） | 見 v5 總表 |
    | 多出的 16 px | 給**球的飛行空間**：磚塊與上邊框的空帶維持 16 px（磚塊起點 y 68）；擋板、手指區位置不變 | 飛行空間（22 排時）y 420~719＝300 px，原 284 |
    | HUD 大小 | **整數 2 倍**：程式以最近鄰放大 2 倍，不重畫；每格 44×44、格距 8、線段條 44×8 | 圖示底板 32×32、內容 24×24；描邊 2 px |
    | HUD 第 1 格 y 424 | 可以（使用者 2026-10-26 v5 回覆） | 整列 y 424~727，6 格全滿時第 6 格有 8 px 進入手指區，一併接受 |
    | 線段條外框偏淡 | **先這樣，之後再微調**（記為待微調，不畫新圖） | 50% 下外框約 1.2:1；之後可由程式畫亮，或另畫外框改 `K` 的線段條 |
    | 磚塊排數 | **維持 22 排**（原同意增加，但增加會與 HUD y 424 重疊） | 多出的 16 px 全給飛行空間（22 排時 y 420~719） |
    | v5 | **使用者已確認（2026-10-26）** | v5 座標總表生效 |
    | 時鐘與星形（2026-10-27） | 保留並畫放大版（14×14） | 見 D27 第九段；v5 總表中時鐘、星形、時間數字的 x、y 已改（使用者已確認，2026-10-27） |
    | 暫停觸控區 56×32（2026-10-27） | 可以 | v5 總表不變 |

    **HUD 2 倍版座標（方案 B；整列範圍使用者已確認 2026-10-26）**

    | 項目 | 內容 |
    |---|---|
    | 格 | 44×44（圖示 32×32 加下方線段條 44×8，結構同 D16 ×2）；格距 8；步進 52 |
    | x | 24~67（左邊框內緣 x 19 與 HUD 之間留 4 px） |
    | 第 1 格 y | **424**（第 1 格上緣；補位後永遠從這裡開始） |
    | 第 k 格 y（k 從 0 起） | 424 + 52 × k：424、476、528、580、632、684 |
    | 最多格數 | **6**：減速與加速互斥（D16），所以同時最多 6 種狀態 |
    | 6 格整列範圍 | y 424~727（304 高）；少於 6 格時只佔前 k 格 |

    衝突檢查：

    | 對象 | 距離 | 結論 |
    |---|---|---|
    | 磚塊區最下排（22 排，下緣 y 419） | 第 1 格上緣 y 424，隔 4 px | 不重疊；排數少於 22 時空隙更大，HUD 位置不隨排數變 |
    | 擋板上緣 y 763 | 整列下緣 y 727，隔 36 px | 不重疊 |
    | 手指區 y 720~799 | 第 6 格（y 684~727）有 8 px（y 720~727）進入手指區 | 只有 6 格全滿時才發生；使用者 2026-10-26 已確認接受 |
    | 第 7 格（若有） | y 736~779，與擋板 y 763~770 重疊 | 不會發生（減速、加速互斥）；若日後新增第 7 種同時狀態，提案：整列改為由下往上排（第 1 格貼近 y 727）並把上限延伸到磚塊區下緣，另議 |

    - 為什麼是 y 424：上限由「不碰 22 排磚（y ≥ 420）」決定、下限由「離擋板至少 12 px（整列底 ≤ 751）」決定，可選第 1 格 y 在 420~448；取 424 讓整列最靠上，離擋板與手指區最遠
    - 若使用者想離磚塊遠一點：改 y 432（整列 y 432~735，進入手指區 16 px）
    - 2 倍放大規則：圖示 12×12 內容變 24×24、`K` 描邊 1 px 變 2 px；半透明 50% 套整組（含線段條）

    50% 不透明度下的對比（手算近似；背景 Y ≈ 22，L ≈ 0.008）：

    | 元素 | 原色 Y | 50% 後 Y | 對背景 | 說明 |
    |---|---|---|---|---|
    | 白色線段 `W` | 255 | 約 139 | 約 5.2:1 | 仍達 4.5:1 |
    | 圖示底板面 `g` | 95 | 約 59 | 約 1.6:1 | 靠亮邊 `f`、暗邊 `j` 與內容辨識 |
    | 線段條外框 `j` | 61 | 約 42 | 約 1.2:1 | **很淡**；放大 2 倍後外框 2 px 稍醒目，但仍是已知弱點 |
    | 圖示描邊 `K` | 29 | 約 26 | 與背景幾乎同色 | 圖示輪廓靠亮邊與底板 |

    - 若 50% 下外框看不清：可由程式把外框畫更亮，或另畫外框改 `K` 的線段條（屬 D16 範圍新圖，本次不畫）

    **v5 座標總表（螢幕座標，x, y, 寬, 高；高 800；整個 UI 區縮成 32、其餘下方內容上移 16 px）**

    | 元素 | 舊（D22 新版／D23／D24／D27／D28 v4） | v5 |
    |---|---|---|
    | UI 區底 | 0, 0, 360, 48 | 0, 0, 360, **32**（`K`） |
    | 時鐘圖示 | 8, 19（v4） | **使用者已確認（2026-10-27）**：放大版 `hud_icon_clock_l` 8, **9**, **14, 14**（原 9×9 版已刪除） |
    | 時間數字 | y 16 | **25**, **8**, 12, 16；格起點 x（`MM:SS`）：25、36、47（冒號）、52、63，最右到 x 74；`M:SS`：25、36（冒號）、41、52（因放大時鐘，起點由 20 右移到 25，間隔仍 3 px） |
    | 分數數字 | y 16 | x 規則不變（最右格起點 286，往左每位 −11，最多 14 位），y **8**，12×16 |
    | 星形圖示 | y 19 | **使用者已確認（2026-10-27）**：放大版 `hud_icon_star_l`，x = **280 − 11 × 位數**，y **9**，**14×14**（與最左一位數字間隔仍 3 px；14 位時 x 126；保留，使用者 2026-10-27 決定） |
    | 暫停鈕圖 | 332, 12, 24, 24 | 332, **4**, 24, 24 |
    | 暫停觸控區 | 304, 0, 56, 48 | 304, 0, 56, **32**（3 倍約 168×96 實體像素） |
    | 上邊框 | y 48~67 | y **32~51**（全寬 360，高 20） |
    | 左上轉角、右上轉角 | 0, 48 與 340, 48 | 0, **32**, 20, 20 與 340, **32**, 20, 20 |
    | 左、右邊框（轉角以下） | y 68~799（732）；樣本拼接起點 y 67 | y **52~799**（748）；樣本拼接起點 y **51**；x 0~19 與 340~359 |
    | 關卡區 | 20, 68, 320, 732 | 20, **52**, 320, **748** |
    | 球的碰撞邊界 | 左 20、右 339、上 68 | 左 20、右 339、上 **52**；越過 y 799 即漏球 |
    | 磚塊區起點 | y 84 | y **68**（與上邊框之間空帶 16 px 不變：y 52~67） |
    | 磚塊區（22 排） | y 84~435 | y **68~419** |
    | 魔王位置 | 116, 84, 128, 48 | 116, **68**, 128, 48（y 68~115） |
    | 魔王舌頭血條（螢幕） | 130, 124, 100, 4 | 130, **108**, 100, 4（y 108~111） |
    | 球的飛行空間（22 排） | y 436~719（284） | y **420~719**（300） |
    | 手指區 | y 720~799 | 不變（y 720~799，零 UI；HUD 第 6 格有 8 px 進入，見上） |
    | 擋板 | y 763~770 | 不變 |
    | HUD 球狀態列 | D16：8, 24, 178, 22（UI 區內） | 方案 B 2 倍：x 24~67；第 k 格 y = 424 + 52 × k；每格 44×44 |
    | 背景（D24） | 可見 x 20~339、y 68~799（320×732） | 可見 x 20~339、y **52~799**（320×**748**）；底圖單元原點 (20, 52)，748 = 11 × 64 + 44，最後一列只用前 44 列 |
    | 背景裝飾（D25） | 關卡區座標 | **關卡區座標不變**（原點上移 16，所以螢幕上整體上移 16）；磚塊區在關卡區座標仍是 y 16~367，「磚塊區只放底圖」規則不變；飛行空間的裝飾仍放在 y ≥ 372 |
    | 低於 800 高手機 | 飛行空間 = H − 473 | 飛行空間 = H − **457**（22 排滿時）；建議不低於 250 → 最低支援約 H = 707 |

    - 磚塊排數上限仍 22；多出的飛行空間讓球從磚塊回到擋板的時間變長（約 +5%），使用者已決定**維持 22 排**（增加排數會與 HUD y 424 重疊），多出的 16 px 全給飛行空間
    - 本表為 v5：D22 新版座標表、D23 位置段、D24 可見範圍、D25 擺放規則、D27 魔王位置與舌頭血條座標，**在標註處都以本表為準**

    **八、給工程師的需求（v5，由 PM 轉達）**

    - HUD：依方案 B 2 倍版座標；補位邏輯＝依固定順序過濾出目前有的狀態，從第 1 格往下排；半透明 50% 整組套用；繪製層級見第一段
    - UI 區、邊框、關卡區、磚塊、魔王、背景全部依 v5 總表（只是整體位置變，圖不變）
    - 球的邊界上緣改 y 52；磚塊起點 y 68

    圖例沿用 v3；v5 線框中 `v` 為 UI 區底（實際色 `K`）、`U` 為 HUD（方案 B 2 倍）。

    圖寬：90　圖高：200
    高 800 v5 線框：UI 區 32、方案 B 的 HUD 2 倍（id: layout_800_v5）：
    ```text
    vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvtttttttttttttt
    vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvtttttttRRRRRRt
    vvxxxxxxxxxxxxxxxxvvvvvvvvvvvvvvYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYvtttttttRRRRRRt
    vvxxxxxxxxxxxxxxxxvvvvvvvvvvvvvvYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYvtttttttRRRRRRt
    vvxxxxxxxxxxxxxxxxvvvvvvvvvvvvvvYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYvtttttttRRRRRRt
    vvxxxxxxxxxxxxxxxxvvvvvvvvvvvvvvYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYvtttttttRRRRRRt
    vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvtttttttRRRRRRt
    vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvtttttttttttttt
    ccccchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhccccc
    ccccchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhccccc
    ccccchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhccccc
    ccccchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhccccc
    ccccchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhccccc
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbggggg
    gggggKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggKUUUUUUUUUUUKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKggggg
    gggggsUUUUUUUUUUUssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggsUUUUUUUUUUUssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggsssssssssssssssssssssssssssssssseeeeeeeeeeeeeeeessssssssssssssssssssssssssssssssggggg
    gggggsssssssssssssssssssssssssssssssseeeeeeeeeeeeeeeessssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    gggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggg
    ```

    ---

## 七色對應方案比較（舊稿；D12 原採用方案 C）

- **注意：本節為舊稿的方案比較。其中「多層磚層 1~9 固定藍、層 10~14 固定綠」「一般磚」已由 D12 新規則取代：一般磚併入多層磚，顏色代表層數，七色由低到高紅橙黃綠藍靛紫，數字 1~9 代表第幾輪，最多 69 層；寶箱橙、金幣黃、圓形紫維持不變，但不屬於七色，不會被彩虹磚挑中**
- 玩法前提：彩虹磚會從畫面上的顏色中隨機挑一色，把該色的磚全部破壞（多層磚不論層數）
- 本稿網格以**方案 C**繪製

| 項目 | 方案 C（推薦，已繪製） | 方案 A（全隨機色） |
|---|---|---|
| 一般磚 | 七色任一（隨機屬性） | 七色任一 |
| 多層磚 | 層 1~9 固定藍、層 10~14 固定綠 | 七色任一；十位組改用「非顏色」記號（例如角落多一個標記）區分 |
| 寶箱 | 固定橙 + 金屬鎖與金屬柱形狀 | 七色任一 + 金屬鎖與金屬柱形狀 |
| 金幣 | 固定黃 + 錢幣形狀 | 七色任一 + 錢幣形狀 |
| 圓形 | 固定紫 | 七色任一 |
| 魔王 | 不在七色內 | 不在七色內 |
| 優點 | 1. 完全遵守「十層用顏色區分」 2. 特殊磚用顏色加形狀雙重辨識，一眼分得出 3. 圖數量較少（特殊磚各 1 色） | 1. 彩虹磚是純粹的「挑色」玩法，最公平 2. 關卡配色最多變 |
| 缺點 | 1. 彩虹磚挑到橙、黃、紫時，可能一次破壞全部寶箱、金幣或圓形磚，偏獎勵 2. 一般磚與特殊磚共用顏色，需靠形狀分辨 | 1. 違背「十層用顏色區分」的決定，要另做十位記號 2. 圖數量多（每種磚七色，多層磚 14 層 × 7 色 = 98 組） 3. 寶箱、金幣失去固定顏色辨識 |
| 對應衝突 | 見下表 | 見下表 |

衝突處理（方案 C）：

| 衝突 | 處理 |
|---|---|
| 多層磚兩組顏色辨識 | 藍（Y 124）與綠（Y 183）灰階差 59 / 255，色相不同；層數靠單個數字 |
| 寶箱、金幣原本靠金色 | 金色已移除；寶箱固定橙、金幣固定黃，並以金屬鎖、錢幣的形狀記號輔助（黃與橙在紅綠色盲下相近，形狀記號是主要線索） |
| 魔王是否列入七色 | 建議**不列入**，且不受彩虹磚影響：魔王被彩虹磚破壞會直接勝利，等於一道道具秒殺整關；若要列入，建議改為「彩虹磚對魔王只造成固定傷害」，這屬玩法規則，請使用者決定 |
| 彩虹磚本身的外觀 | 屬功能型磚塊，不在本稿範圍；其外觀不得使用單一七色，另案設計 |
