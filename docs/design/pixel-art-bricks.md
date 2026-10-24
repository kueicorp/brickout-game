# 可破壞磚塊像素美術規格

- 狀態：剩 D01、D02、D12、D13、D14 待使用者確認；D15、D16 使用者已確認；D03~D11 舊稿已依使用者決定刪除（代號不重新編號）
- 依據：README.md「磚塊種類」與「基本數值」；尺寸：內部解析度寬 360、關卡區高 640，一排 10 塊磚（磚 32×16，磚區寬 320，左右邊框各 20）
- 圖用文字網格表示：一字元 = 一像素；`.` = 透明；其他字元見 D01 調色盤；之後由工程師轉成 PNG
- 本文不含程式碼、不含圖檔
- 使用者已決定（本稿遵守）：採路線 B（細緻像素風，D12 母版）；磚 32×16；可破壞磚塊配色為彩虹七色；圓形 16×16 且碰撞為圓形；魔王 128×48；破壞動畫每幀小磚 60 ms、魔王 100 ms；多層磚剩 1 層用「1」那張；多層磚數字用個位數，以 10 層為單位用顏色區分；不加橫向磚縫

## 視覺方向

| 項目 | 內容 |
|---|---|
| 主題 | 直式打磚塊 Roguelike（Android），給休閒手機玩家；玩家要在小螢幕上一眼分辨磚塊種類、顏色與剩餘層數；彩虹磚會依顏色一次破壞同色磚，所以「顏色」是玩法資訊 |
| 色彩 | 深藍黑描邊 `K`；可破壞磚塊主色限定彩虹七色（紅橙黃綠藍靛紫）；魔王用獨立的暗紫灰（不在七色內）；完整色碼見 D01 |
| 字型 | 無字型。多層磚的數字用自繪 5×7 像素字（D12），非外部素材，無授權問題 |
| 版面 | 磚塊格 32×16；圓形 16×16 置中；魔王 128×48（= 4 欄 × 3 列格）；各磚種的精靈圖排版由轉檔工具依 D12 規則產生 |
| 原則 | 1. 顏色是玩法資訊：同一個顏色只代表「同色」，磚種靠形狀記號辨識 2. 顏色之外一定有第二線索（數字、圖案、形狀） 3. 七色在灰階下亮度盡量拉開 |

自我檢查（已換掉的通用預設）：
- 不用漸層與抖色，用 5 階色階的斜面與凹坑表現立體
- 不用「統一圓角卡片」語彙；磚塊是直角、寶箱有鎖、金幣有錢幣、圓形磚是圓、魔王有臉
- 多層磚的編號有真實順序（層數），不是裝飾

---

1. [D01] 調色盤（已改寫，待再確認；七色各 5 階，共 60 色（含 D13 擋板用 2 色、D14 不可破壞磚塊用 2 色、D15 球用 6 色、D16 HUD 用 2 色），不受 32 色限制）：
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
   | `W` | #FFFFFF | 白 | 255 | 被擊中閃白、高光、牙齒 |
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
   | `E` | #D6F7BC | 綠 T1 | 230 | 綠色階（多層磚層 10~14） |
   | `F` | #B0EC8E | 綠 T2 | 207 | 綠色階 |
   | `L` | #8EDB6A | 綠 T3（主色） | 183 | 綠色階 |
   | `H` | #5FA848 | 綠 T4 | 135 | 綠色階 |
   | `J` | #2F6A2C | 綠 T5 | 81 | 綠色階 |
   | `M` | #A8CEFF | 藍 T1 | 200 | 藍色階（多層磚層 1~9） |
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
   | `5` | #FF6FB5 | 品紅（亮） | 162 | D16 用：強化圖示（`hud_icon_reinforce`）亮面（原 D15 外圍記號用，該方案已刪除） |
   | `6` | #B02A78 | 品紅（暗） | 91 | D16 用：強化圖示（`hud_icon_reinforce`）暗面（原 D15 外圍記號用，該方案已刪除） |
   | `7` | #DDE0EA | 淺灰 | 224 | D16 用：強化線段第 2 階 |
   | `8` | #9EA4B6 | 中灰 | 164 | D16 用：強化線段第 4 階 |
   | `u` | #B4A6C8 | 魔王 T1 | 174 | 魔王最亮邊 |
   | `Q` | #8A7AA0 | 魔王 T2 | 128 | 魔王亮面 |
   | `Z` | #5A4A6E | 魔王 T3（主色） | 80 | 魔王主色（不在七色內） |
   | `z` | #3A2F4A | 魔王 T4 | 52 | 魔王暗面 |
   | `v` | #241C30 | 魔王 T5 | 33 | 魔王最暗 |

   - 灰階亮度 Y = 0.299R + 0.587G + 0.114B，手算近似值，請工程師用工具複核
   - 七色主色（T3）灰階由亮到暗：黃 209、綠 183、橙 143、藍 124、紫 104、紅 88、靛 66；相鄰最小差 16 / 255（紫與紅）
   - 數字與底色對比（近似）：`K` 字在藍底（T3）約 4.8:1、在綠底（T3）約 11:1
   - 色數統計：`K`、`W`、`G` 共 3 + 七色 7×5 = 35 + 鋼灰 5 + 魔王 5 = 48 色；加 D13 擋板用的青色 2 色（`w`、`x`）、D14 不可破壞磚塊用的槍金屬 2 色（`s`、`y`）共 52 色；再加 D15 球用的珍珠白 4 色（`1`~`4`，T1 沿用 `W`）、品紅 2 色（`5`、`6`）共 58 色；D15 方案 C 沒有新增顏色；再加 D16 HUD 強化線段用的淺灰 `7`、中灰 `8` 共 60 色
   - 靛色階（`T X I k l`）在 D12 的網格中沒有出現，但一般磚的七色換色對照表需要它，所以保留
   - 本表為全檔唯一調色盤
   - 色彩來源為本稿自訂，無外部取色來源
   - 色盲：七色紅橙黃綠藍靛紫在紅綠色盲下會有混淆（紅、橙、綠）；本稿以亮度差加形狀記號補強，未用色盲模擬器驗證，請 QA 或使用者複核

2. [D02] 風格指南（已改寫為路線 B 正式規範，待再確認）：
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
   | 數字預留區 | 位置、尺寸與數字組合方式以 D12 為準（D12「多層磚組合」）；風格上不放紋理、不加亮影、多層磚不放裂痕 |
   | 木紋（寶箱） | 橫向 2~4 px 短段（T4 或 T1），板上緣 T1、板下緣 T4；板與板之間 T5 接縫；右側 3 px 加深 |
   | 金屬（寶箱） | 鋼灰 5 階；柱體左亮右暗；鉚釘 2×2（左上亮、右下暗）；鎖有輪廓、高光、暗面 |
   | 抖色 (dithering) | 不用 |
   | 被擊中 | 規則以 D12 為準（D12「被擊中（1 幀）」） |
   | 破壞動畫 | 幀數、幀時間以 D12 為準（小磚 60 ms、魔王 100 ms） |
   | 以 D12 為準 | 本表與 D12 若有任何不一致（位置、尺寸、被擊中、自動產生規則等），一律以 D12 為準；D12 的欄、列編號從 0 起算 |

12. [D12] 路線 B 正式母版（新增，待確認）：
    - 使用者已確認：採路線 B；內部解析度寬 360、關卡區高 640；一排 10 塊磚；磚 32×16；磚區寬 320，左右邊框各 20（邊框不在本稿）；魔王 128×48（4×3 格，置中於關卡格的第 3~6 欄，欄編號從 0 起算，即 1 起算的第 4~7 欄）；圓形磚 16×16 置中於 32×16 格內，碰撞範圍為圓形；不加橫向磚縫；七色方案 C（一般磚七色任一；多層磚層 1~9 藍、層 10~14 綠；寶箱橙；金幣黃；圓形紫；魔王不在七色內）；多層磚為個位數字加十位顏色，層 1 用「1」；破壞動畫每幀小磚 60 ms、魔王 100 ms
    - 本項只畫「母版」；七色換色版本、多層磚各層、各色破壞幀由轉檔工具依下列規則自動產生
    - 母版色階一律使用 D01 的代號；母版的色階對照紅色階 `h r R t o`（T1~T5）
    - 網格尺寸為 32×16（磚、圓形所在的格）、128×48（魔王）、5×7（數字）
    - **欄、列編號一律從 0 起算**：左上角像素為第 0 欄、第 0 列，與網格的字元索引一致；本項所有「第 N 欄、第 N 列」皆依此（例：數字左上角在第 13 欄、第 4 列；裂痕在第 25~27 欄、第 3~7 列）

    自動產生規則：

    | 項目 | 規則 |
    |---|---|
    | 被擊中（1 幀） | 母版中除 `K`、`.` 以外的像素全部改成 `W`；魔王同規則 |
    | 魔王裂痕疊加（F1） | 裂痕層的非 `.` 像素覆蓋「魔王正常」圖的對應像素，`.` 的位置不變；兩張同為 128×48，逐像素對齊（此規則寫死在轉檔工具中；要修改請通知 PM，由工程師改工具） |
    | 一般磚七色 | 把母版紅色階換成目標色階（見下方換色對照表）；`K`、`W`、`G`、`.` 不變 |
    | 通用破壞 F1~F4 | 以紅色階 `h r R t o` 繪製；套用到一般磚、寶箱（橙）、金幣（黃）、圓形（紫）、多層磚（藍或綠）時，用該磚的色階換色；寶箱、金幣的鎖與錢幣細節不保留 |
    | 圓形專用 | 圓形的 F1（裂開）、F2（四塊散開）為專用網格（紫色階）；F3、F4 用通用幀（此規則寫死在轉檔工具中；要修改請通知 PM，由工程師改工具） |
    | 多層磚組合 | 一般磚母版（含紋理）換成藍（層 1~9）或綠（層 10~14）色階，再在預留區疊上數字：數字墨色 `K`，字形 5×7，左上角放在第 13 欄、第 4 列（欄列從 0 起算）；數字佔第 13~17 欄、第 4~10 列；母版第 11~20 欄、第 4~11 列不放任何紋理（預留區）；不加亮影（第 2 輪自檢：亮影會讓「7」像多一道筆畫）；母版右上的裂痕（第 25~27 欄、第 3~7 列的 T5 像素）換成 T3，多層磚不放裂痕（裂痕像斜線，會被誤讀成數字的一部分），範例網格已照此繪製 |
    | 數字與層對應 | 層 1~9 顯示 1~9（藍）；層 10~14 顯示 0~4（綠）；層 1 用「1」 |
    | 多層磚破壞 | 通用 F1~F4，換成藍或綠色階，數字不保留（此規則寫死在轉檔工具中；要修改請通知 PM，由工程師改工具） |
    | 扣層 | 切換為下一低層的多層磚正常圖（層 10 → 層 9 時從綠換回藍），並先播 1 幀被擊中（此規則寫死在轉檔工具中；要修改請通知 PM，由工程師改工具） |

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

    層 7 藍範例：
    ```text
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    KMMMWWWWMMMMMMMMMNNNMMMMMMMMMNUK
    KNNNNNNNNNNNNNNNNNNNNNNNNNNNNUPK
    KMNUUUUUUUUUUUUPPUUUUUUUUUUUUPSK
    KMNUPPPUUUUUUKKKKKUUUUPPPUUUUPSK
    KMNUUNNUUUUUUUUUUKUUUUUNNUUUUPSK
    KMNUUUUUUUUUUUUUKUUUUUUUUUUUUPSK
    KMNUUUUUUUUUUUUKUUUUUUUUUUUUUPSK
    KMNUUUPPPUUUUUUKUUUUUUUUPPPUUPSK
    KMNUUUUNNUUUUUUKUUUUUUUUUNNUUPSK
    KMNUUUUUUUUUUUUKUUUUUUUUUUUUUPSK
    KMNPPPUUUUUUUUUUUUUUUPPPUUUUUPSK
    KMNUNNUUUUUUUUUUNNUUUUNNUUUUUPSK
    KNUPPPPPPPPPPPPPPPPPPPPPPPPPPPSK
    KUPSSSSSSSSSSSSSSSSSSSSSSSSSSSSK
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    ```

    層 3 綠範例（第 13 層）：
    ```text
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    KEEEWWWWEEEEEEEEEFFFEEEEEEEEEFLK
    KFFFFFFFFFFFFFFFFFFFFFFFFFFFFLHK
    KEFLLLLLLLLLLLLHHLLLLLLLLLLLLHJK
    KEFLHHHLLLLLLKKKKLLLLLHHHLLLLHJK
    KEFLLFFLLLLLLLLLLKLLLLLFFLLLLHJK
    KEFLLLLLLLLLLLLLLKLLLLLLLLLLLHJK
    KEFLLLLLLLLLLLKKKLLLLLLLLLLLLHJK
    KEFLLLHHHLLLLLLLLKLLLLLLHHHLLHJK
    KEFLLLLFFLLLLLLLLKLLLLLLLFFLLHJK
    KEFLLLLLLLLLLKKKKLLLLLLLLLLLLHJK
    KEFHHHLLLLLLLLLLLLLLLHHHLLLLLHJK
    KEFLFFLLLLLLLLLLFFLLLLFFLLLLLHJK
    KFLHHHHHHHHHHHHHHHHHHHHHHHHHHHJK
    KLHJJJJJJJJJJJJJJJJJJJJJJJJJJJJK
    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    ```
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


13. [D13] 擋板（新增，待確認）：
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
    | 吸附 | 把左端、中段、右端三個圖塊全部換成吸附版；拼接規則不變（上緣兩列改為綠色黏液，其餘與正常相同） |
    | 同時有槍與吸附 | 左端、右端用槍版，中段用吸附版（槍的端帽與吸附的上緣黏液可並存；如使用者要不同組合，請通知 PM） |
    | 被擊中（1 幀） | 對「組好的整條擋板」套用：除 `K` 與 `.` 以外的像素全部改成 `W`（與 D12 同規則） |
    | 隱形 | 由程式調整透明度，不畫圖 |

    取捨說明：
    - 吸附只改上緣兩列（綠色黏液），不另畫整組新造型：球黏在上緣，顏色一眼可分，且中段、端帽的細節不用重畫
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
    KFFFFFFF
    KFLLLLLL
    Kifwwfff
    Kifxxfff
    Kggggggg
    Kjjjjjjj
    .KKKKKKK
    ```

    吸附中段（id: paddle_sticky_mid）：
    ```text
    KKKKKKKKKKKKKKKK
    FFFFFFFFFFFFFFFF
    LLLLLLLLLLLLLLLL
    fffffffieffeefff
    ffggfffgjfffffff
    gggggggggggggggg
    jjjjjjjjjjjjjjjj
    KKKKKKKKKKKKKKKK
    ```

    吸附右端（id: paddle_sticky_right）：
    ```text
    KKKKKKK.
    FFFFFFLK
    LLLLLLHK
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
    KFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFLK
    KFLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLHK
    KifwwffffffffffieffeeffffffffffieffeeffffffffffieffeeffffffwwfgK
    KifxxfffffggfffgjfffffffffggfffgjfffffffffggfffgjffffffffffxxfgK
    KgggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggjK
    KjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjK
    .KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK.
    ```

14. [D14] 不可破壞磚塊（新增，待確認）：
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
    - 顏色：珍珠白 `1`~`4`（T1 沿用 `W`）標「D15 用」，已加入 D01；品紅 `5`、`6` 原為已刪除的外圍記號方案所用，D01 保留，目前改由 D16 強化圖示使用；色數統計為 58 色

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
    - **需程式支援：被標記的多層磚改用沒有數字的底圖**：D12「多層磚組合」少做「疊上數字」那一步，其餘（藍或綠色階、預留區不放紋理、不放裂痕）不變；標記存在期間顯示這個版本，標記移除（效果結束、磚塊爆炸）前都不顯示數字；層數仍由磚的資料記錄，只是不畫出來；十位的藍、綠顏色仍保留（規則寫死在轉檔工具中；要修改請通知 PM，由工程師改工具）

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
    - 範圍：只做 5 種狀態圖示、圖示下方的線段條與排列；時間、分數、魔王血量等其他 HUD 元素不在本次範圍
    - 風格沿用 D01、D02：1 px `K` 描邊、左上光源；新增顏色 2 色（淺灰 `7`、中灰 `8`，標「D16 用」，已加入 D01），色數統計為 60 色
    - 欄、列編號一律從 0 起算
    - 使用者回饋（第 2 版）：1. 5 個圖示要一樣大、都是正方形 2. 下方提示全部改為線段，不再用 +N 數字和 ∞ 記號，5 格的線段尺寸、位置、高度完全一致
    - **正方形的做法：統一的 16×16 底板加固定內容框**
      - 5 個圖示共用同一塊 16×16 的正方形底板：最外圈 1 px `K` 描邊；內側上緣、左緣 1 px `f`（亮邊），下緣、右緣 1 px `j`（暗邊），右上與左下轉角用 `g`；底板面用 `g`（左上光源，與 D02 一致）
      - 圖示內容全部畫在 12×12 的內容框內（底板的第 2~13 欄、第 2~13 列），內容的外形都**頂到內容框的四邊**，所以 5 個看起來一樣大；內容框外不再有突出物（上一版炸彈與 fever 的火花會突出，已改掉：炸彈的引信與火花收進框內，fever 取消火花）
      - 內容框內沒畫到的透明處，會露出底板面（網格中以 `g` 表示，不用 `.`）
    - 色盲照顧：5 種圖示的**外形各不相同**（箭穿過橫板、水滴火焰、有引信的圓炸彈、雙層向上箭頭、三顆球成堆），不靠顏色辨識；顏色只是輔助
    - 圖示內容縮到 12×12 的代價：筆畫細節比上一版（16×16 內容）少，見「已知限制」

    各狀態圖示（16×16，底板加 12×12 內容）：

    | 狀態 | 圖示 | 外形記號 | 主要顏色（D01 代號） | 圖 id |
    |---|---|---|---|---|
    | 穿透 | 向上的箭穿過一塊橫板 | 箭頭加橫板，橫板頂到左右兩邊 | 青 `w` `x`、鋼灰 `e` `f` | `hud_icon_pierce` |
    | 火焰 | 火焰 | 水滴狀、頂端尖 | 橙 `a` `O` `d` `b`、黃 `A` `B`、紅 `R` `t` | `hud_icon_flame` |
    | 炸彈 | 圓炸彈加引信火花 | 圓形加右上引信（火花收進內容框） | 鋼灰 `f` `g` `j`、魔王最暗 `v`、引信 `G`、火花 `Y` `W` | `hud_icon_bomb` |
    | 強化 | 雙層向上箭頭 | 兩個疊起的 V 形 | 品紅 `5` `6`、白 `W` | `hud_icon_reinforce` |
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
    | 減速 | 龜殼（側面，有頭、腿） | 圓頂加頭加兩條腿，左右不對稱 | 綠 `F` `L` `H` `J` | `hud_icon_slow` |
    | 加速 | 向右的雙層實心箭頭 | 兩個並排的向右三角形 | 黃 `A` `B` `Y` | `hud_icon_fast` |

    - 為什麼這兩個外形不會和既有的混淆：穿透是向上的箭穿橫板、強化是向上的雙 V 形（空心）、加速是向右的實心三角、減速是有頭有腿的圓頂；方向、實心或空心、整體輪廓都不同
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
      - 加速的黃色與火焰的橙色、減速的綠色與其他圖示的色相不同，但色盲玩家仍要靠形狀（龜殼、雙三角）分辨
      - 加速圖示的實心三角在 12×12 內每個只有 6 欄寬，細節很少
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
    - 強化圖示（品紅）與火焰（橙紅）色相接近，色盲玩家要靠形狀；底板（灰）讓各圖示的底色一致，但品紅在灰底上對比不高
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
    KfgggggKKgggggjK
    KfggggKW6KggggjK
    KfgggK5566KgggjK
    KfggK55KK66KggjK
    KfgK55KggK66KgjK
    KfKKKKggggKKKKjK
    KfgggggKKgggggjK
    KfggggKW6KggggjK
    KfgggK5566KgggjK
    KfggK55KK66KggjK
    KfgK55KggK66KgjK
    KfKKKKggggKKKKjK
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
    KfgggggKKKKgggjK
    KfgggKKFLLLKKgjK
    KfggKFLHLLHLLKjK
    KfKKKFLLHHLLLKjK
    KfKLKLHLLLLHJKjK
    KfKLKLLLHHLLJKjK
    KfKKKLLHLLHJJKjK
    KfggKKKKKKKKKKjK
    KfgggKLLKgKLLKjK
    KfgggKLLKgKLLKjK
    KfgggKJJKgKJJKjK
    KfgggKKKKgKKKKjK
    KgjjjjjjjjjjjjjK
    KKKKKKKKKKKKKKKK
    ```

    加速圖示（id: hud_icon_fast）：
    ```text
    KKKKKKKKKKKKKKKK
    KfffffffffffffgK
    KfKgggggKgggggjK
    KfKKggggKKggggjK
    KfKBKgggKBKgggjK
    KfKBBKggKBBKggjK
    KfKABBKgKABBKgjK
    KfKABBBKKABBBKjK
    KfKBBYYKKBBYYKjK
    KfKBYYKgKBYYKgjK
    KfKYYKggKYYKggjK
    KfKYKgggKYKgggjK
    KfKKggggKKggggjK
    KfKgggggKgggggjK
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
    ...KfgggggKKgggggjK..........KfggggKKKKggggjK..........KfgggggKKKKgggjK..........KfKgggggKgggggjK..........KfgggggKKgggggjK..........KfgggggKKgggggjK..........KfggggggggggYgjK...
    ...KfggggKW6KggggjK..........KfgggKW122KgggjK..........KfgggKKFLLLKKgjK..........KfKKggggKKggggjK..........KfggggKwxKggggjK..........KfggggKaaKggggjK..........KfggggggggGYWYjK...
    ...KfgggK5566KgggjK..........KfgggK1223KgggjK..........KfggKFLHLLHLLKjK..........KfKBKgggKBKgggjK..........KfgggKwwxxKgggjK..........KfgggKaOOdKgggjK..........KfgggggggGggYgjK...
    ...KfggK55KK66KggjK..........KfgggK2233KgggjK..........KfKKKFLLHHLLLKjK..........KfKBBKggKBBKggjK..........KfggKwwwxxxKggjK..........KfggKaOBBdbKggjK..........KfgggKKKKgggggjK...
    ...KfgK55KggK66KgjK..........KfgggK2334KgggjK..........KfKLKLHLLLLHJKjK..........KfKABBKgKABBKgjK..........KfgKKKKwxKKKKgjK..........KfgKaOBAABdbKgjK..........KfgKWWfggjKgggjK...
    ...KfKKKKggggKKKKjK..........KfggggKKKKggggjK..........KfKLKLLLHHLLJKjK..........KfKABBBKKABBBKjK..........KfggggKwxKggggjK..........KfKOOBAAAABbbKjK..........KfKWfffgggjKggjK...
    ...KfgggggKKgggggjK..........KfgKKKKggKKKKgjK..........KfKKKLLHLLHJJKjK..........KfKBBYYKKBBYYKjK..........KfKKKKKKKKKKKKjK..........KfKdOBAAAABbbKjK..........KfKWfffggjjKggjK...
    ...KfggggKW6KggggjK..........KfKW122KKW122KjK..........KfggKKKKKKKKKKjK..........KfKBYYKgKBYYKgjK..........KfKeeeeeeeeeeKjK..........KfKdOBBAABBbbKjK..........KfKffgggjjjKggjK...
    ...KfgggK5566KgggjK..........KfK1223KK1223KjK..........KfgggKLLKgKLLKjK..........KfKYYKggKYYKggjK..........KfKffffffffffKjK..........KfKRdBBBBBBbRKjK..........KfKfggggjjvKggjK...
    ...KfggK55KK66KggjK..........KfK2233KK2233KjK..........KfgggKLLKgKLLKjK..........KfKYKgggKYKgggjK..........KfKKKKKKKKKKKKjK..........KfgKRRdBBbRRKgjK..........KfKgggggjjvKggjK...
    ...KfgK55KggK66KgjK..........KfK2334KK2334KjK..........KfgggKJJKgKJJKjK..........KfKKggggKKggggjK..........KfggggKwxKggggjK..........KfggKtRRRRtKggjK..........KfgKgjjvvvKgggjK...
    ...KfKKKKggggKKKKjK..........KfgKKKKggKKKKgjK..........KfgggKKKKgKKKKjK..........KfKgggggKgggggjK..........KfggggKKKKggggjK..........KfgggKKKKKKgggjK..........KfgggKKKKgggggjK...
    ...KgjjjjjjjjjjjjjK..........KgjjjjjjjjjjjjjK..........KgjjjjjjjjjjjjjK..........KgjjjjjjjjjjjjjK..........KgjjjjjjjjjjjjjK..........KgjjjjjjjjjjjjjK..........KgjjjjjjjjjjjjjK...
    ...KKKKKKKKKKKKKKKK..........KKKKKKKKKKKKKKKK..........KKKKKKKKKKKKKKKK..........KKKKKKKKKKKKKKKK..........KKKKKKKKKKKKKKKK..........KKKKKKKKKKKKKKKK..........KKKKKKKKKKKKKKKK...
    ..................................................................................................................................................................................
    ..................................................................................................................................................................................
    jjjjjjjjjjjjjjjjjjjjjj....jjjjjjjjjjjjjjjjjjjjjj....jjjjjjjjjjjjjjjjjjjjjj....jjjjjjjjjjjjjjjjjjjjjj....jjjjjjjjjjjjjjjjjjjjjj....jjjjjjjjjjjjjjjjjjjjjj....jjjjjjjjjjjjjjjjjjjjjj
    jWWj77jGGj88jffjvvjvvj....jWWWWWWWWWWWWWWWWWWWWj....jWWWWWWj888888jvvvvvvj....jWWWWWjGGGGjffffjvvvvj....jWWWWWWWWWWWWWWWWWWWWj....jWWWWWWWWWWWWvvvvvvvvj....jWWWWWWvvvvvvvvvvvvvvj
    jWWj77jGGj88jffjvvjvvj....jWWWWWWWWWWWWWWWWWWWWj....jWWWWWWj888888jvvvvvvj....jWWWWWjGGGGjffffjvvvvj....jWWWWWWWWWWWWWWWWWWWWj....jWWWWWWWWWWWWvvvvvvvvj....jWWWWWWvvvvvvvvvvvvvvj
    jjjjjjjjjjjjjjjjjjjjjj....jjjjjjjjjjjjjjjjjjjjjj....jjjjjjjjjjjjjjjjjjjjjj....jjjjjjjjjjjjjjjjjjjjjj....jjjjjjjjjjjjjjjjjjjjjj....jjjjjjjjjjjjjjjjjjjjjj....jjjjjjjjjjjjjjjjjjjjjj
    ```

---

## 七色對應方案比較（D12 採用方案 C）

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
