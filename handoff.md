# 交接文件

更新日期:2026-11-06(首頁 AdMob banner、D20 底部列黑底完成，使用者實機測試成功之後)

## 目前階段
- Godot 專案在 `game/`(Godot 4.7.2,執行檔 `E:\Godot 4\Godot_v4.7.2-stable_win64.exe`、`_console.exe`)
- 已完成並通過 QA:載入畫面、首頁(完整互動 + 假資料)、Android 圖示設定、長螢幕版面延伸
- **2026-11-05~06 完成:10 個主題背景 + 牆壁全部換新**(Pixen 180×420 → 整數放大 2 倍，2 px 一格)
- **2026-11-06 完成：首頁 AdMob banner(測試 ID)、D20 底部列黑底、首頁黑底統一 alpha 160**;QA 通過，使用者實體手機測試成功
- 所有已定案內容以 `README.md` 為準;圖片原檔在 `art/`,用到的圖複製到 `game/assets/`(保留子路徑)

## 待接續(新 session 從這裡開始)

| 優先 | 項目 | 內容 |
|---|---|---|
| 1 | ~~Godot import~~ | **2026-11-06 已完成**(headless `--import`;smoke_main_scene、test_home_tall 562 通過) |
| 2 | 實機看對比 | 各主題磚塊、資源列、牆壁是否看得清楚;最需注意：主題 10 浮島像磚塊、主題 8 黃色電光(背景閃電 + 牆壁電光)、主題 3 大石柱、主題 9/10 牆壁偏亮、主題 7 牆與下方冰原對比弱 |
| 3 | 主題 1~5 牆壁對比 | 這 5 個是在「牆壁要跟背景對比」規則之前做的;可能有問題：主題 2(深棕樹根 vs 深棕樹幹)、主題 5(黑岩 vs 黑岩壁)。**使用者尚未決定是否回頭檢查** |
| 4 | 牆壁進遊戲 | 程式目前沒用到牆壁;做關卡畫面時再把 `art/borders/game/` 複製到 `game/assets/`,並寫進工程師指令(見「主題、背景、牆壁」) |
| 5 | ~~設計稿整理~~ | **2026-11-06 已完成**:`tall-screen.md` 刪除 T05、T08、T09、Q10~Q12,新增「背景現況」,307 → 59 行 |
| 6 | commit | 全部尚未 commit(使用者用 GitHub Desktop 操作;使用者說之後會 commit) |
| 7 | 安全檢查 | AdMob 改動尚未做:第三方 SDK(Poing 外掛、Google ads-mobile-sdk)、INTERNET 權限、廣告 ID 收集、外掛自動下載;使用者自己另開 session |
| 8 | AdMob 正式 ID | 使用者申請 App ID 與 banner unit ID 後交給 PM,派工程師替換 |

## 首頁 AdMob banner(2026-11-06)

| 項目 | 內容 |
|---|---|
| 狀態 | 已實作,QA 通過(已知問題 3 項在 `test_ad_manager_states` 標為 KNOWN);**2026-11-06 使用者實體手機測試成功**;尚未做安全檢查 |
| 匯出 | headless:`--headless --path game --install-android-build-template --export-debug Android <路徑>`;Gradle daemon 會讓指令不結束，產出後用 `gradlew --stop`;debug APK 約 92 MB |
| 外掛 | Poing Studios godot-admob-plugin v5.1.0(`game/addons/admob/`,Android 4.7.2 binaries);JEV 選定 |
| 程式 | Autoload `AdManager`(`game/scripts/ad_manager.gd`)單一 banner,自訂 dp 座標對齊 D10;首頁進入 show、離開 hide;`FakeData.ads_removed` |
| ID | 目前用 Google 測試 ID;上架前使用者申請 AdMob App ID 與 banner unit ID,換 `ad_manager.gd` 常數與專案設定 `admob/general/android/app_id`;正式 ID 測試時要登記測試裝置 |
| gradle | 已開啟;`game/android/build/` 在 .gitignore;`game/android/.build_version` 會進版控,clone 後可能要重跑 `--install-android-build-template` |
| iOS 檔 | 外掛開編輯器會自動下載 iOS binaries(約 3 MB),使用者已接受保留 |
| 已知問題 | 手機 dp 寬 < 360(輔助功能放大顯示大小)時 banner 超出 D10;使用者決定先不處理。已查證可改 `GodotApp.java` 覆寫 density(有條件可行，未實作) |
| 未做 | 其他 4 個畫面(活動、商城、成長、設定)、插頁、獎勵、UMP、購買系統;載入失敗不重試(shortcut);APK 92 MB 原因未查 |

## 首頁黑底統一(2026-11-06)
- 新增 D20 底部列共用半透明黑底(x 8、y 488、344×80,跟底部列一起貼下移動);首頁黑底一律 #000000 alpha 160(D15 由 120 改);QA 通過，使用者實體手機測試成功;實際畫面 `art/mockups/home/d20_impl_640.png`;設計稿 D20 已刪除(規格在 README 與 `home.gd`)
- 品質備註(未處理,JEV 0.32 不交回):「黑 alpha 160」常數重複在 home.gd、level_map.gd、resource_bar.gd、theme_bar_button.gd 4 處

其他待使用者決定(沿用):
| 項目 | 內容 |
|---|---|
| 愛心按鈕 | 手指移出再移回、500 ms 內放開仍會去商城;D14 未定義此情況;JEV 判斷問使用者(0.78),尚未回答 |
| Android package name | 仍是 `com.example.$genname`,上架前要決定 |
| 設計稿 D 項目 | branding D01~D10、首頁 D02/D04/D06/D15 已實作，待使用者確認畫面後請設計師刪除/整理 |
| 安全檢查 | 首頁與載入畫面已通過 QA,已告知可做安全檢查(觸控輸入、VIBRATE 權限，加上 2026-11-06 的 AdMob,見待接續 7);使用者尚未進行 |

## 本輪決策紀錄(2026-11-05~06)

| 順序 | 決定 |
|---|---|
| 1 | 長螢幕背景補到總高 840(補 200 列) |
| 2 | 補頂試過多種做法都不理想(程式漸層、複製雲、鏡射刪枝、Pixflux 修順/延伸、Pro Flash 分塊 inpaint),最後使用者改成「**整張重畫**」 |
| 3 | 背景新做法(使用者提出):Pixen 原生 180×420 → 程式整數放大 2 倍成 360×840 → 切成下 640 + 上 200;10 個主題全部採用，統一 2 px 一格 |
| 4 | 牆壁新做法(使用者提出):每主題 Pixen 180×420 牆面 → 整數放大 2 倍 → **直接裁外框**(左/右 20×840、上 360×20),不再小塊重複拼貼 |
| 5 | 牆壁不一定要是磚(使用者說);**牆壁主色要跟該主題背景有明顯對比**(主題 6 深藍牆配藍背景被退件，已寫進 README 與記憶) |
| 6 | 舊背景、舊牆壁、`art/not-in-use/` 全部移到資源回收筒(見「已刪除紀錄」) |

各主題採用版本(job ID 留作追查):
| 主題 | 背景 | 牆壁 |
|---|---|---|
| 1 晴空草原 | 7e81aba9 | 綠籬 8f8f2547 |
| 2 迷霧森林 | f7388b89 | 樹根盤結 653b3496 |
| 3 烈日荒漠 | b25a76f9 | 暖橘金砂岩磚 9d205e5e |
| 4 劇毒沼澤 | 5d046d28 | 枯木樁泥岩毒液 95b7c121 |
| 5 熔岩火山 | 6fde581b | 火山岩岩漿縫 7c852a83 |
| 6 幽暗深海 | 82fa9ca1(比原設定亮，使用者接受) | 暖棕船板藤壺珊瑚 66056ae4 |
| 7 極夜冰原 | 6f2e0c91 + Pro Flash 冰面去裂紋 c99acb42 | 淺白冰磚積雪 d288eb1c |
| 8 雷暴雲海 | 4a53bf0b | 炭黑石塊鏽鐵框電光 53b7463b |
| 9 魔王古堡 | cf648e14(中央多了王座，使用者接受) | 暖灰石磚金紋骷髏 8b0e451f |
| 10 虛空深淵 | 55f70b44 | 淺灰米碎石紅裂縫 d77a5019 |

## 實機未驗證
- 2026-11-06 使用者已用 APK 實體手機測試成功(首頁 banner、D20);以下細項未逐項回報
- S26+ 上的安全區實際值、immersive / edge_to_edge、觸控手感、震動、圖示
- 新背景在遊戲內的效果(含 640 高螢幕裁掉頂部後的樣子)
- 建議裝機時請工程師在畫面印出實際 viewport 尺寸，確認是 360×780

## 測試指令(在 repo 根目錄執行)
```
& "E:\Godot 4\Godot_v4.7.2-stable_win64_console.exe" --headless --path game --script res://tests/<名稱>.gd
```
- `test_layout`(126)、`test_home_logic`(110)、`test_home_interaction`(137)、`test_home_tall`(736)、`test_ad_manager`(41)、`test_ad_manager_states`(1165 + KNOWN 3)、`test_home_d20`(182)、`smoke_main_scene`;首頁畫面截圖可用 `--path game --resolution 360x640 --write-movie <路徑>.png --quit-after 240`(只能輸出 640 高);結束時的「ObjectDB leaked」是引擎背景載入造成，不是專案 bug

## 已定案(重點摘要，細節見 README)

| 主題 | 內容 |
|---|---|
| 環境 | 遊戲名稱 Bricklite(只有英文);Godot 4、Android 限定、像素風、暫定 200 關、每 20 關一個主題 |
| 版面 | 寬 360、高度依手機(640~840 完整支援);關卡內牆壁左右上三面各 20 px、球會反彈，遊戲區寬 320 px;磚塊區 y68~508,最多 22 排;警戒線 y508;擋板上緣 y558 |
| 基礎值 | 擋板血量 100、速度 235 px/s;球攻擊 5、球速 300 px/s;敵方子彈 100 px/s |
| 節奏 | 初始 3 排、每格 20% 空格;全體每 10 秒下移 1 排並生成 1 排;突進每 5 秒 |
| 勝敗 | 一般關撐 5 分鐘勝利;磚塊低於警戒線、血量歸 0、無法補球為失敗 |
| 狂暴 | 球速 ×3 |
| 技能 | 攻擊 12 個、被動 12 個;規則已定，數值為試填版 |
| 商城/道具/愛心/廣告 | 已定案，以台幣 8 檔定價 |
| 無障礙 | 整個遊戲都不做 |

技能規則補充(2026-11-03 ~ 04):
| 項目 | 規則 |
|---|---|
| 電弧 | 每 30 秒 +1 球，球數上限 Lv1~3 為 2、Lv4~6 為 3、Lv7~9 為 4、Lv10 為 5 |
| 輔助大師 | 持續 5~8 秒，結束後才開始冷卻 |
| 麻痺專家 | 被延遲的那一欄與其他欄錯開，不追回 |
| 暴擊 | 2 倍，基礎 0%;追擊暴擊率 = 追擊 + 被動 3 |
| 射程 | 滾木、槍手、弓箭手從擋板開始算 |
| 飛行速度 | 分裂 350、槍手 500、弓箭手 500、滾木 200、擲彈手 300 px/s |
| 傷害加成 | 被動 1 與輔助大師為百分比，與成長相乘 |

## 主題、背景、牆壁

| 項目 | 內容 |
|---|---|
| 規則 | 每 20 關一個主題，共 10 個;只換外觀;風格與牆壁材質見 `docs/design/home/image/background/themes.md`(T01 晴空草原 → T10 虛空深淵) |
| 背景 | `art/backgrounds/home/bg_themeNN.png` 360×640 + `top/bg_themeNN_top.png` 360×200(皆已複製到 `game/assets/`);首頁與關卡共用;貼下對齊，螢幕較矮裁頂部 |
| 牆壁 | `art/borders/game/wall_themeNN_full.png` 360×840(來源)、`_left` 20×840(x0~19)、`_right` 20×840(x340~359)、`_top` 360×20(y0~19,含兩角);**尚未複製到 game/assets**。做關卡時：左右牆與背景一樣貼下對齊，上牆放在遊戲區頂端 |
| 程式 | `game/scripts/home.gd` 讀 `res://assets/backgrounds/home/bg_themeNN.png` 與 `top/bg_themeNN_top.png`;檔名未變，換圖不用改程式 |

主題待決定:Q4(10 個主題是否全部確認)、Q5(主題是否對應解鎖磚塊)、Q8(首頁背景鋪滿或只在 D04)、200 關以後怎麼辦。

## 品牌圖(2026-11-05 定稿並已實作)

| 項目 | 內容 |
|---|---|
| 設計稿 | `docs/design/branding/branding.md`(D01~D10,待使用者確認後刪 D 項目;D01 漏寫圓角擋板要補) |
| 檔案 | `art/branding/`:Logo 256×64、Play 圖示 512×512、自適應前景 432×432、進度條外框 256×32(透明窗口 x20~235、y8~21)、填充 16×16;自適應背景純色 #192331 |
| 載入畫面 | 360×640 依 D09:底色 #192331、Logo 放大 1.25 倍、金磚填充 + 外框 |
| 未決 | 216 不是 16 的倍數，100% 時最後一塊金磚只露一半;載入失敗畫面未設計 |

## 首頁 UI

| 項目 | 內容 |
|---|---|
| 已確認規格 | `docs/design/home/home-screen-confirmed.md`(派工時整段放進指令) |
| 設計稿 | `docs/design/home/home-screen.md`:D02、D04、D06、D15 已確認但**還沒搬進 confirmed 檔**(confirmed 裡的舊版以設計稿為準) |
| 底部按鈕 | `docs/design/home/bottom-buttons-confirmed.md`:活動、商城、成長、設定;icon 64×64、文字 Cubic 11 15px |
| icon 清單 | `docs/design/home/image/icon/home-icons.md`:只剩 I07 魔王標記未出圖 |
| 參考圖 | `docs/design/home/home-screen-layout.svg` 是 48 格線舊版，寫 confirmed 時要更新 |
| 字型 | Cubic 11(`art/fonts/`,OFL 1.1);12px 用於資源列，11px 會缺筆畫 |
| 版面 | 資源列 → D02 選擇主題 → D15 關卡地圖 → D06 開始 → 底部 4 按鈕 → banner;資源列與地圖底圓角 6px |
| 圖檔 | `art/ui/home/`(resource 25×25、theme-arrow 24×24、level-map 76×76 + pawn 52×64 + road/t01、start-button 216×80、bottom-button 64×64);示意圖 `art/mockups/home/`(home_board_map_road、d06_*) |

D15 地圖：一次 10 關、每主題 2 組、左右滑動;蛇形 3+4+3;格子中心第 1 排 (91,199)(180,199)(269,199)、第 2 排 (314,266)(224,266)(136,266)(46,266)、第 3 排 (91,332)(180,332)(269,332);觸控 66×66;棋子在格子圖 (14,-22);泥土路 16px,沒走過乘 #909090;只做 T01 的路。

首頁待決定:Q55/Q33/Q18/Q22(先不做)、Q16 免費寶箱位置、Q17 看廣告入口、Q9/Q6 商城停在哪區與商品、Q10 數字縮寫、Q14 活動與設定內容、Q19/Q23/Q24(寫 confirmed 前要清)、I07 魔王標記、空愛心何時顯示。

## 其他待處理

| 項目 | 狀態 |
|---|---|
| 首頁 confirmed | D02、D04、D06、D15 搬進 confirmed;更新 svg;D01 底框 alpha 改 160(Q31) |
| 其他主題的路 | T02~T10 各 3 張，尚未出圖 |
| I07 魔王標記 | 尚未出圖 |
| 技能數值 | 24 個技能 PM 試填，JEV 評估 0.74 仍失衡;使用者決定留到原型實測(可能過強：分裂、擲彈手;可能過弱：麻痺專家、蓄力) |
| 彗星冷卻、槍手射程 | 實測確認 |
| 突進磚塊 | 「前方磚塊中間隔空格也算」未確認，未寫入 README |
| 魔王擴充 | 超過 200 關要一起加新成長，否則約第 450 關打不過 |
| 商城 | 上架前在 Google Play Console 確認實際價位 |
| Server/DB | 方案 P4 待確認(MySQL、不用 AWS、約 100 DAU、預算 NT$1000) |

## 實作注意事項(派工給工程師時要寫進指令)
- 球要用**連續碰撞偵測**:狂暴 ×3 加球速成長，每幀移動接近磚塊高度 20 px
- 傷害計算保留小數，畫面顯示整數
- 關卡中不顯示技能圖示，暫停時查看
- 像素圖一律 nearest 取樣;Logo 在載入畫面放大 1.25 倍
- 牆壁：左右牆貼下對齊、上牆放遊戲區頂端;牆壁圖要先從 `art/borders/game/` 複製到 `game/assets/`

## 出圖經驗(給下次派工)

| 情況 | 建議 |
|---|---|
| 背景、牆面 | **Pixen 原生 180×420 → 程式整數放大 2 倍**;每張約 $0.008~0.01 |
| 牆面材質 | 要細碎均勻、點綴平均分布(含左右邊緣)、主色跟背景對比;Pixen 在 180 寬畫布上磚塊最小約 28×11,寫更小也畫不出來 |
| 地面比例 | Pixen 常把地面壓到最底，提示詞要寫「佔下方約 1/4」 |
| 中段磚塊區 | 避免太暗(主題 5 第 1 張)或太搶眼的大元素(主題 7 第 1 張極光);提示詞指定中段要平靜/有光 |
| 去掉某個細節 | 改提示詞常去不掉(冰面裂紋);用 Pro Flash `inpaint_image_pro_flash` 局部重畫有效，遮罩外像素保證不變;上限 256×256,約 $0.04 |
| Pixflux | 不會在空白處長出新東西(主題 1 補雲、主題 2 延伸都失敗);strength 300 左右可「修順」已有內容 |
| 精確文字、數量、構圖 | Pixen 常不聽;改用 Pro Flash,或以 Pixen 候選當 style_image |
| 很扁的長條、16×16 無縫 | Pixen 畫不出來;長條改 Pro Flash 修改，無縫紋理改程式畫或改設計 |
| 尺寸 | Pixen 每邊 16~768、面積 ≤512²、4 的倍數;Pixflux 每邊 ≤400;Pro Flash ≤256 |

做法與注意:
- 像素圖**不可非整數倍放大**,也不可放大舊圖再修;整數倍放大可以(使用者已採用)
- 模型常不聽否定詞，盡量用正面描述(例：「平滑鏡面」取代「沒有裂紋」)
- 設計師沒有存檔工具、常把目測當量測:PM 一律下載後自己量尺寸並合成預覽
- 大圖用 `get_upload_url` 上傳傳 `upload:id`,不要傳大段 base64
- PowerShell 腳本：參數名與變數名不分大小寫，別重名;腳本別寫中文字串;陣列裡的 `a + b, c` 要加括號
- 預覽、裁切、合成腳本都在 scratchpad,會隨 session 消失(本輪的 `wall_process.ps1`、`wall_install.ps1` 需要時重寫：下載 → 2 倍 → 裁外框 → 合成預覽 / 舊檔移走 → 複製新檔)

## PixelLab 額度
- 2026-11-06 本輪結束:credits 約 **$5.86**(本輪約 $0.36);訂閱 generations 已用完(49/40),每日額度用完扣 credits
- 參考:Pixen 約 $0.007~0.01;Pixflux 約 $0.008;Pro Flash 256 級約 $0.04(9 generations)

## 工作流程備忘
- 判斷性問題交給 JEV(`~/.claude/jev/ask.ps1`),請求檔放 scratchpad;confidence 偏低時問使用者
- 定案後直接更新 README,不必再問
- git 由使用者用 GitHub Desktop 操作，不要執行 git 指令
- 圖片交給設計師用 PixelLab 產生，每張都要使用者先同意、一次一張(使用者說「做主題 N」即視為同意出 1 張);圖片不經 QA
- 回報圖片時每張都寫實際像素尺寸;放大預覽註明原圖尺寸與倍率
- 設計師無法存圖，由 PM 下載後複製到專案;檔名不加 dNN_ 代號
- PM 不親自出圖(程式合成、裁切、放大不算出圖)
- 刪除檔案一律移到資源回收筒

## 已刪除紀錄(可從資源回收筒或 git 還原)

| 日期 | 內容 |
|---|---|
| 2026-11-04 | 舊背景 20 張、舊牆壁、`art/not-in-use/` d23_border 39 張、`art/source/home/export/` border 來源 |
| 2026-11-05 | `art/ui/home/` 舊首頁圖 33 張、底板 2 張、32×32 底部 icon 4 張;另 185 個:`art/mockups/home/candidates/`(129)、首頁過程示意圖 33、`art/mockups/` 根目錄舊版面 7、`art/source/home/` 12、`art/backgrounds/game/` meadow 4 |
| 2026-11-06 | 122 張:`art/not-in-use/` 整個資料夾(舊主題背景 12、舊牆壁 40、舊玩法圖 d12~d28 共 69)、`art/mockups/home/d14_tooltip_theme01.png` |
