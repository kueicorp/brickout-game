# 可破壞磚塊像素美術規格

- 狀態：剩 D01、D02、D12、D13、D14 待使用者確認；D03~D11 舊稿已依使用者決定刪除（代號不重新編號）
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

1. [D01] 調色盤（已改寫，待再確認；七色各 5 階，共 52 色（含 D13 擋板用 2 色、D14 不可破壞磚塊用 2 色），不受 32 色限制）：
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
   | `u` | #B4A6C8 | 魔王 T1 | 174 | 魔王最亮邊 |
   | `Q` | #8A7AA0 | 魔王 T2 | 128 | 魔王亮面 |
   | `Z` | #5A4A6E | 魔王 T3（主色） | 80 | 魔王主色（不在七色內） |
   | `z` | #3A2F4A | 魔王 T4 | 52 | 魔王暗面 |
   | `v` | #241C30 | 魔王 T5 | 33 | 魔王最暗 |

   - 灰階亮度 Y = 0.299R + 0.587G + 0.114B，手算近似值，請工程師用工具複核
   - 七色主色（T3）灰階由亮到暗：黃 209、綠 183、橙 143、藍 124、紫 104、紅 88、靛 66；相鄰最小差 16 / 255（紫與紅）
   - 數字與底色對比（近似）：`K` 字在藍底（T3）約 4.8:1、在綠底（T3）約 11:1
   - 色數統計：`K`、`W`、`G` 共 3 + 七色 7×5 = 35 + 鋼灰 5 + 魔王 5 = 48 色；加 D13 擋板用的青色 2 色（`w`、`x`）、D14 不可破壞磚塊用的槍金屬 2 色（`s`、`y`）共 52 色
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
