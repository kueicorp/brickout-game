# 交接文件

更新日期:2026-11-07(商城實作 + 綠色九宮格按鈕 + 頁面頂部捷徑列完成、QA 通過、使用者實機測試通過之後;前一版：商城設計 D01~D29 確認)

## 目前階段
- Godot 專案在 `game/`(Godot 4.7.2,執行檔 `E:\Godot 4\Godot_v4.7.2-stable_win64.exe`、`_console.exe`)
- 已完成並通過 QA:載入畫面、首頁(完整互動 + 假資料)、Android 圖示設定、長螢幕版面延伸、活動頁(列表、每日簽到、首次儲值;假活動服務)、**商城(4 分頁 + 購買流程;假商城服務)、綠色九宮格按鈕、頁面頂部捷徑列**(2026-11-07,使用者實機測試通過)
- **2026-11-07:設計基準改為 360×800**(比 800 矮等比縮留白),首頁與活動頁已改並實機確認
- **2026-11-05~06 完成:10 個主題背景 + 牆壁全部換新**(Pixen 180×420 → 整數放大 2 倍，2 px 一格)
- **2026-11-06 完成：首頁 AdMob banner(測試 ID)、D20 底部列黑底、首頁黑底統一 alpha 160**;QA 通過，使用者實體手機測試成功
- 所有已定案內容以 `README.md` 為準;圖片原檔在 `art/`,用到的圖複製到 `game/assets/`(保留子路徑)

## 待接續(新 session 從這裡開始)

| 優先 | 項目 | 內容 |
|---|---|---|
| 1 | commit | 全部尚未 commit(使用者用 GitHub Desktop 操作，使用者說之後會 commit) |
| 2 | 安全檢查 | 程式都完成後由使用者另開 session。範圍：首頁(觸控輸入、VIBRATE 權限);AdMob(第三方 SDK Poing 外掛 / Google ads-mobile-sdk、INTERNET 權限、廣告 ID 收集、外掛自動下載);活動頁(金流：首儲、補發訂單;外部輸入：伺服器活動資料);商城(金流：金塊包、移除廣告、補發訂單、金塊扣款;看廣告獎勵;外部輸入：伺服器商城資料) |
| 3 | 商城規格缺漏 3 項 | 待使用者決定:(1) 卡片整張按下時價格鈕用 pressed 圖或跟卡片一起變暗(目前 pressed 圖)(2) 按下時文字位移(目前 (1,5))(3) D13 道具分頁在資料到之前先顯示(目前沒做) |
| 4 | 商城設計稿 D01~D28 | 已實作、QA 通過、實機 OK;使用者決定先保留，第 3 項決定後再請設計師刪。當初派工是讓工程師直接讀設計稿(全文沒放進指令),刪之前先確認規格已在 README / 程式裡 |
| 5 | 接真服務時要處理 | 看廣告沒有逾時(SDK 不回應會卡在商城;JEV later 0.68);App 在付款結果回來前被殺 → 訂單停在 `_paid`(啟動時用 queryPurchases 補發，屬後端設計);真 Google Play 計費、AdMob 獎勵廣告、後端都還沒接 |
| 6 | AdMob 正式 ID | 使用者申請 App ID 與 banner unit ID 後交給 PM,派工程師替換 |
| 7 | 實機看對比 | 各主題磚塊、資源列、牆壁是否看得清楚;最需注意：主題 10 浮島像磚塊、主題 8 黃色電光(背景閃電 + 牆壁電光)、主題 3 大石柱、主題 9/10 牆壁偏亮、主題 7 牆與下方冰原對比弱 |
| 8 | 主題 1~5 牆壁對比 | 這 5 個是在「牆壁要跟背景對比」規則之前做的;可能有問題：主題 2(深棕樹根 vs 深棕樹幹)、主題 5(黑岩 vs 黑岩壁)。**使用者尚未決定是否回頭檢查** |
| 9 | 牆壁進遊戲 | 程式目前沒用到牆壁;做關卡畫面時再把 `art/borders/game/` 複製到 `game/assets/`,並寫進工程師指令(見「主題、背景、牆壁」) |
| 10 | 其他畫面 | 成長、設定、關卡畫面以 360×800 設計;頁面頂部捷徑列元件 `page_shortcut_bar.gd` 可直接套用(傳入目前頁);載入畫面未納入 screen-size-800.md(現況正常) |

## 商城、綠色按鈕、頁面頂部捷徑列(2026-11-07 完成;QA 通過;使用者實機測試通過)

| 項目 | 內容 |
|---|---|
| 狀態 | `game/tests/run_tests.ps1` 24 檔 0 失敗;尚未做安全檢查 |
| 設計稿 | `docs/design/shop/shop-screen.md` D01~D18、`shop-purchase-flows.md` D19~D29(D29 出圖清單已全部完成);捷徑列 `docs/design/layout/page-shortcuts.md`(P01~P11 已刪，只剩決定紀錄;既有稿指向 P 編號處已補註);規格摘要在 README「商城」段落與「活動」第 5、7 點 |
| 程式 | `shop_logic.gd`(商品表、紅點條件、D28 說明文字)、`shop_service.gd`(假服務，日後只換這層;與 EventService 共用錢包)、`shop_screen.gd`、`ui/shop_page.gd`、`ui/shop_dialog.gd`;`ui/green_button.gd`(九宮格綠鈕);`ui/page_shortcut_bar.gd`(捷徑列);`home.gd` 開關商城、切頁、紅點 |
| 圖示 | `art/ui/shop/` 16 張 36×36(已複製到 `game/assets/ui/shop/`):remove_ads(I02)、bundle_all_items(I03)、item_extra_hp / extra_life / swap / assassinate / coating / weaken / typhoon / armor_break / greed / skill_pack(I04~I13)、free_heart_ad(I14)、chest_coin(I15)、chest_silver(I16)、chest_item(I17,直接複製簽到藍禮物 `icon_random_item_36.png`);36 版愛心 `art/ui/resource/heart_x2.png`。圖案一律畫滿 36×36 |
| 綠色按鈕 | 不出圖，用首頁 `start_normal` / `start_pressed` / `start_disabled` 做九宮格(邊界左 22、右 12、上 20、下 11;中段重複貼不縮放);pressed 中段改用原圖 x 92~169 + 175~199(避開淺色斑點與深色短線);按下下沉 (1,5);商城價格鈕 146 → 148×44、卡內 x 7;活動頁與商城的綠鈕、重試鈕都用 GreenButton |
| 捷徑列 | 返回鈕 (8,80) 44×44 加底板 + 4 個文字捷徑 70×44(x 60/134/208/282,y 80,黑 alpha 160、圓角 6、白字 14px、目前頁內側金框);切頁取代、返回回首頁;成長、設定點了沒反應;處理中(購買、領取含簽到、Google Play、看廣告載入中)捷徑與返回鈕停用、Android 返回鍵也無效(活動頁與商城一致);紅點只顯示在其他頁的捷徑 |
| 修過的 bug | 商城 B1 看廣告中返回 → 沒「已獲得」框;B2 付款中返回 → 訂單卡 `_paid`;B3 按下圖平面下緣深色短線;捷徑同一幀內漏擋 |
| D28 文字 | 強化塗層第 1 行改「抵擋 10 次敵方攻擊或負面效果」(206px);所有道具說明行去句號 |
| 預覽 | `art/mockups/shop/shop800_full_x2.png`(色塊稿 + 全部圖示 + 九宮格鈕);實作截圖 `impl_800_screens.png`、`impl_800_dialogs.png`;購買流程預覽 `shop-p0*-preview.png` |
| shortcut | 捲動無慣性;資料只在記憶體;每日次數不在 00:00 重置;沒有道具庫存;toast 樣式工程師自訂 |
| 品質備註(未處理) | `flat_button.gd` 的 `set_active`、`GREEN`/`GRAY` 已無人使用(JEV 0.25,之後順便清);`shop_screen.gd` `handle_back` 與 `_is_busy()` 條件分開維護;`pixel_button.gd:8` 註解寫不做鍵盤，但捷徑列開了焦點;處理結束那一幀點擊可能沒反應;`test_shop_logic` 只強制強化塗層那行 ≤ 252px;`test_page_shortcuts` 只驗屬性、畫面靠 `qa_capture_shortcuts.gd`;QA 曾遇一次測試結束時當掉(兩個 Godot 同時跑，重跑無法重現) |
| QA 手動腳本 | `game/tests/qa_capture_shop.gd`、`qa_capture_event_retry.gd`、`qa_capture_shortcuts.gd`、`qa_capture_d28.gd`(需非 headless 執行，不在 run_tests 內) |
| 圖示做法摘要 | I02 PM 用字型畫原稿 → `image_to_pixelart` → Pro Flash 加禁止符號;I03 沿用活動禮物，Pro Flash inpaint 去問號、補緞帶;I04~I13 Pixen 36 畫布 + 填滿畫布提示詞;I06 依使用者參考圖，PM 加粗原稿 → `edit_image_pixen`;I08 PM 畫概念草圖 → `edit_image_pixen`;I13 改成 2 個卷軸避免像蘿蔔;I14 `heart_x2` + `plus_badge` 程式合成;I15/I16 同一個 Pixen 紅寶箱用 `edit_image_pixen` 加金幣 / 銀錠(會重畫整張，約 850 像素不同但款式一致);過程檔已刪 |

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
| 未做 | 成長、設定畫面;插頁、獎勵廣告、UMP、真購買系統;載入失敗不重試(shortcut);APK 92 MB 原因未查 |

## 首頁黑底統一(2026-11-06)
- 新增 D20 底部列共用半透明黑底(x 8、y 488、344×80,跟底部列一起貼下移動);首頁黑底一律 #000000 alpha 160(D15 由 120 改);QA 通過，使用者實體手機測試成功;實際畫面 `art/mockups/home/d20_impl_640.png`;設計稿 D20 已刪除(規格在 README 與 `home.gd`)
- 品質備註(未處理,JEV 0.32 不交回):「黑 alpha 160」常數重複在 home.gd、level_map.gd、resource_bar.gd、theme_bar_button.gd 4 處

其他待使用者決定(沿用):
| 項目 | 內容 |
|---|---|
| 愛心按鈕 | 手指移出再移回、500 ms 內放開仍會去商城;D14 未定義此情況;JEV 判斷問使用者(0.78),尚未回答 |
| Android package name | 仍是 `com.example.$genname`,上架前要決定 |
| 設計稿 D 項目 | branding D01~D10、首頁 D02/D04/D06/D15 已實作，待使用者確認畫面後請設計師刪除/整理 |
| 安全檢查 | 範圍見「待接續」第 2 項;使用者尚未進行 |

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
- 2026-11-06 使用者已用 APK 實體手機測試成功(首頁 banner、D20);2026-11-07 商城、九宮格按鈕、捷徑列實機測試通過;以下細項未逐項回報
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

## 共用資源圖示(2026-11-06)

| 項目 | 內容 |
|---|---|
| 決定 | 金幣、金塊、愛心、銀塊全 APP 統一(含關卡內掉落金幣、撿起動畫、金幣磚塊);圖示不帶 +,首頁資源列的 + 由程式疊上(README 已寫) |
| 檔案 | `art/ui/resource/`:coin、gold、silver、heart、heart_empty(各 25×25,無 +)、plus_badge 12×12(疊在 (13,13)) |
| 尚未做 | 首頁資源列改用這套 + 程式疊 plus_badge(工程師 → QA);關卡內金幣統一(使用者 2026-11-06 說先不做;已停止設計師規劃，未產出檔案);尚未複製到 game/assets |

## 活動頁與 800 基準改版(2026-11-06~07 完成;QA 通過;使用者實機確認位置正確)

| 項目 | 內容 |
|---|---|
| 程式 | 假活動服務 `game/scripts/event_service.gd`(日後只換這層接後端);規則 `event_logic.gd`;活動頁 `event_screen.gd` 疊在首頁上(不換場景);`ui/checkin_page.gd`、`topup_page.gd`、`reward_popup.gd`、`flat_button.gd`、`event_list_item.gd` |
| 測試 | `game/tests/run_tests.ps1` 跑全部測試(結束碼、SCRIPT ERROR、缺 PASSED 行、逾時都算失敗);2026-11-07 最後一次 24 檔 0 失敗(含商城、捷徑列) |
| 修過的問題 | B1 補發通知改為關框才標記已看過;B2 安全區重疊;切頁收起 toast;失敗回應晚到不在新畫面顯示 toast |
| 畫面基準 | 設計 360×800;比 800 矮採「等比縮留白」(S03);活動頁多出高度全給面板;toast 跟著長高 0.4E、讀取失敗 / 重試置中於面板(S08);規格 `docs/design/layout/screen-size-800.md`;README 第 9 行 |
| Godot 設定 | `viewport_height=640`(expand 的最小高度,改成 800 會讓矮手機整頁縮小)+ `window_height_override=800`(只影響桌機視窗) |
| 使用者決定維持 | toast 在 640 高時蓋住累積卡「累積 N 次」標題 2 秒;avail < 584 時返回鈕與資源列仍重疊;QA 品質備註(測試小缺口、註解)不處理 |
| shortcut | 假資料只在記憶體、不跨日跨月;商城道具未入庫存;列表捲動未做;全域 set_quit_on_go_back(false);toast 樣式為工程師自訂 |
| 實機 | 2026-11-07 使用者實機測試，位置正確 |
| 未做 | 安全檢查(金流:首儲、補發訂單;外部輸入：伺服器活動資料;第三方 SDK:AdMob);真後端與 Google Play 計費 |
| 已刪除(2026-11-07) | 淘汰方案與過時圖:B2 比較圖、800 方案 S04/S05、`event-screen-layout.svg`、`event_screen_preview.png`/`_x2.png`、活動圖示候選預覽 e01/e03/e04/list_icons |

| 項目 | 內容 |
|---|---|
| 設計稿 | `docs/design/event/event-screen.md`:D01~D17 使用者已確認(D08 已移除);640 以外高度見 `screen-size-800.md` |
| 預覽 | 640:`docs/design/event/event-screen-preview.svg`(截圖 `art/mockups/event_screen_preview_final.png`);800:`docs/design/layout/screen-size-800-base.svg`、`-option-s03.svg`、`-toast.svg`(截圖 `art/mockups/screen_size_800_*.png`);截圖指令 `msedge --headless=new --disable-gpu --allow-file-access-from-files --window-size=<寬>,<高> --screenshot=<png> file:///<svg>` |
| 圖 | `art/ui/event/`:icon_checkin、icon_first_topup(48×48,列表用)、icon_random_item_36(36×36,首儲列與 28 次卡用)、icon_signed(24×24);首儲金塊、銀塊用 `art/ui/resource/gold_x2.png`、`silver_x2.png`;按鈕、紅點、格子都由程式畫,不出圖 |
| 首頁稿 | `bottom-buttons-confirmed.md` 第 38 行已補註:活動按鈕例外有紅點(見 D16) |

本輪定案(README「活動」「每日簽到」「首次儲值活動」「免費商城道具寶箱」已全部寫入):
| 項目 | 決定 |
|---|---|
| 簽到 | 只算次數,不對應星期與日期;每天 1 次;每月 1 日 00:00(UTC+8)歸零 |
| 簽滿 28 次 | 之後每天仍可簽,每次 1500 金幣 + 2 愛心;累積獎勵只到 28 次;28 格全部已簽、無金框;摘要 >28 次不顯示分母 |
| 累積獎勵 | 手動領取;月初歸零時,上月已達成未領的自動補發(直接入帳)並跳 D15 |
| 首儲 | 10 種商城道具各 1 個;付款成功未發放 → 下次連線自動向 Google Play 查詢並補發 |
| 隨機道具 | 10 種等機率,後端抽(28 次獎勵與免費商城道具寶箱相同) |
| 紅點 | 列表「每日簽到」(今天未簽或有可領累積獎勵)、首頁「活動」按鈕;首儲不亮;資料未到或失敗不亮 |
| 列表排序 | 固定,新增活動由使用者決定位置 |
| 提示框 | D17「已獲得」共用框(簽到、領取、首儲、補發訂單);D15 同框換標題;多個依序:補發訂單 → 月初補發 → 玩家操作 |
| 按鈕 | 2026-11-07 起改用綠色九宮格按鈕 GreenButton(見「商城、綠色按鈕、頁面頂部捷徑列」);頁面標題改為捷徑列 |

待補:首儲以外的儲值補發內容,待商城儲值規格定案再補(D17 只寫通用排法)

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
| 小圖要跟舊圖一致(如 24×24 勾) | Pixen 兩次都畫成黃綠細勾;改 Pro Flash + style_image 成功。**style_image 不可大於畫布**,先從舊圖裁出 ≤ 畫布的區塊(不縮放)再上傳;24×24 約 5 generations |
| 去掉圖內角標(如資源 icon 的 +) | Pro Flash inpaint 最小 32×32、需 4 的倍數:把 25×25 原圖平移放進 32×32 透明畫布(不縮放)+ 遮罩,inpaint 後裁回;5 generations,遮罩外逐像素不變 |
| 圖示畫滿畫布 | Pixen 提示詞加「large, filling the entire canvas edge to edge」有效(E02 37→46 px) |
| 圖示內要寫英文字(如 AD) | Pixen 兩次:一次畫成漢字「孜」、一次字黏在一起;**有效做法**:PM 用電腦字型(Arial Black)畫 4 倍大原稿(144×144,透明底)→ `image_to_pixelart` faithful=true、強度 200、輸出 36×36(1 generation,但背景會變不透明灰)→ Pro Flash 編輯去背(可順便加元素,約 $0.023) |
| 36×36 小圖去掉局部物件 | `inpaint_image_pro_flash` 可直接用 36×36 原圖 + 同尺寸逐像素黑白遮罩(白=重畫,遮罩只蓋物件 + 外圍 1 px);5 generations,遮罩外逐像素不變。直接用 edit 改提示詞去不掉(I04 金屬條) |
| 沿用舊圖去掉局部圖案 | 去掉後要檢查原本被擋住的結構是否接得上(I03 去問號後左側面緞帶斷掉);可再用一次逐像素遮罩 inpaint 補畫,約 $0.023 |
| 圖示要畫滿 36×36 | Pixen 36 畫布 + 「large, filling the entire canvas edge to edge」:I04 得 35×30(有效);Pixen 40 畫布會畫到 40 寬(超出不能用);Pro Flash 編輯「畫大到碰邊」會切掉邊緣黑框。Pixen 小細節(小箭頭)容易漏畫 |
| Pixen 假透明格 | Pixen 偶爾把透明棋盤格畫成不透明深灰格(I05);下載後要檢查邊緣像素，PM 可用程式從四邊 flood fill 把相連灰格改透明(免費) |
| 傳圖給 PixelLab | **一律不要讓設計師轉貼 base64**(1.2~2 KB 的 PNG 都走樣被拒過 2 次)。PM 用 `get_upload_url`(免費)+ `curl.exe -F "file=@路徑"` 上傳，拿到 `upload:<id>` 給設計師填 `image_url`;或用上一個 job 的下載網址 |
| 照參考圖畫圖示 | Pixen 純文字對多物件構圖常畫錯(I06 畫成角色臉);改用 `edit_image_pixen`:輸入 144×144 原稿、輸出 36×36,會照原稿外形重畫。Pixen 編輯改得了顏色、改不了粗細/外形,要改外形先由 PM 用程式改原稿 |
| 設計師自檢 | 會只看縮圖就說「已移除 / 符合」,不可信;PM 一律下載放大 8 倍再判斷 |
| 尺寸 | Pixen 每邊 16~768、面積 ≤512²、4 的倍數;Pixflux 每邊 ≤400;Pro Flash ≤256 |
| 同款系列圖(如三種寶箱) | 先出一張乾淨的基底，之後都用 `edit_image_pixen` + 基底的下載網址「只加箱上物件」;會整張重畫(約 850 像素不同)但款式一致;每張約 $0.008~0.01 |
| 多種尺寸的按鈕 | 不要每種尺寸各出一張:拿現有按鈕圖做九宮格(程式處理，免費、尺寸精確、外觀一致);設計尺寸要配合 Pixen 時寬高取 4 的倍數 |

做法與注意:
- 像素圖**不可非整數倍放大**,也不可放大舊圖再修;整數倍放大可以(使用者已採用)
- 模型常不聽否定詞，盡量用正面描述(例：「平滑鏡面」取代「沒有裂紋」)
- 設計師沒有存檔工具、常把目測當量測:PM 一律下載後自己量尺寸並合成預覽
- 大圖用 `get_upload_url` 上傳傳 `upload:id`,不要傳大段 base64
- PowerShell 腳本：參數名與變數名不分大小寫，別重名;腳本別寫中文字串;陣列裡的 `a + b, c` 要加括號
- 預覽、裁切、合成腳本都在 scratchpad,會隨 session 消失(本輪的 `wall_process.ps1`、`wall_install.ps1` 需要時重寫：下載 → 2 倍 → 裁外框 → 合成預覽 / 舊檔移走 → 複製新檔)

## PixelLab 額度
- 2026-11-07 本輪結束:credits **$5.33**(本輪約 $0.53,商城圖示 I02~I17);訂閱 generations 已用完(65/40),每日額度用完直接扣 credits
- 2026-11-06:credits 約 $5.86
- 參考:Pixen 約 $0.007~0.01;Pixflux 約 $0.008;Pro Flash 256 級約 $0.04(9 generations)

## 工作流程備忘
- 判斷性問題交給 JEV(`~/.claude/jev/ask.ps1`),請求檔放 scratchpad;confidence 偏低時問使用者
- 定案後直接更新 README,不必再問
- git 由使用者用 GitHub Desktop 操作，不要執行 git 指令
- 圖片交給設計師用 PixelLab 產生，每張都要使用者先同意、一次一張(使用者說「做主題 N」即視為同意出 1 張;**1 次同意 = 1 張 = 1 次請求,不出 3 選 1**,2026-11-07 使用者重申);圖片不經 QA
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

| 2026-11-07 | 54 個:`art/mockups/shop/` 商城圖示過程檔 i02_*~i17_* 46 個與 `item_icons_strip_x4.png`、過時預覽 `shop800_icons_x2.png`、`shop_preview_640/800/800_alt.png`、`docs/design/shop/shop-screen-preview-640.svg`、`shop-screen-preview-800-alt.svg`(未採用方案 B)、`art/mockups/page_shortcuts_preview.png`;設計稿 `page-shortcuts.md` P01~P11 刪除(內容已寫進工程師派工指令) |