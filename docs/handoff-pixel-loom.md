# 交接文件:pixel-loom 試用評估

- 日期:2026-10-27
- 角色:你是 PM,依 `~/.claude/CLAUDE.md` 運作。專案總交接見 `docs/handoff.md`(本檔只涵蓋 pixel-loom 試用)。
- **任務:PM 自己試用 pixel-loom,評估是否導入美術流程,結果交 JEV 判斷後回報使用者。**

---

## 1. 背景

| 項目 | 內容 |
|---|---|
| 工具 | pixel-loom https://github.com/yangsir2077/pixel-loom |
| 簡介 | Windows 像素/動畫編輯器,AI 透過 MCP 繪圖,人可在 GUI 手修;圖層、影格、時間軸、調色盤、匯出 PNG / 精靈圖 PNG+JSON / GIF |
| 成熟度 | v0.7.19 公開測試版、89 stars、31 commits,作者只測過 Windows;MIT;Python + tkinter 可攜版 |
| 接入 | 使用者自己下載並接入 MCP(PM 不下載、不安裝、不改 `.mcp.json`) |
| 誰試用 | 使用者決定由 **PM 自己試**;不派 designer、不改 designer 權限 |

## 2. 現有美術流程(比較基準)

| 項目 | 內容 |
|---|---|
| 方式 | designer 在 `docs/design/pixel-art-bricks.md` 寫文字網格(一字元一像素)→ `tools/pixelart/` 轉檔 → `game/art/generated/`(262 檔) |
| 調色盤 | D01 共 87 色,工具強制;顏色有玩法意義 |
| 痛點 | 看不到動畫播放(只有靜態 `_x8`);長行網格 Edit 偶爾失敗;使用者不能滑鼠修圖 |
| 細節 | 見 `docs/handoff.md` 第 4 節 |

## 3. 已問過 JEV(導入前)

| 題目 | 結果 |
|---|---|
| 開通 designer 權限會比現在好(noul) | 0.28 |
| 處置方式(choice) | `trial_first` 0.80(confidence 0.73);assist_only 0.17、not_now 0.03、replace 0.0 |
| 導入風險(score 0~3) | 2.7(confidence 0.7),3 = 可能讓已定案素材或轉檔流程失效 |

## 4. 試用項目

| # | 項目 | 判斷方式 |
|---|---|---|
| 1 | 調色盤限制 | 載入 D01 87 色,刻意用表外顏色,看會不會被擋 |
| 2 | 繪圖精準度 | 重畫一張定案圖(建議 D13 擋板),與 `docs/design/preview/` 根目錄對應 PNG 逐像素比對(原 `final/` 為重複檔，已刪除) |
| 3 | 動畫預覽 | 用破壞 4 幀(小磚 60 ms)做 GIF |
| 4 | 精靈圖輸出 | 匯出的 PNG + JSON 格式能否直接給 Godot 用 |
| 5 | 回寫 md 網格 | 能否轉回文字網格(不能則手修圖會被轉檔覆蓋) |

## 5. 規則

| 項目 | 內容 |
|---|---|
| 產出位置 | 只放 scratchpad,不進專案 |
| 不可動 | `game/`、`docs/`(本檔除外)、`tools/`、`.mcp.json` 類檔案(含 token,不可貼進對話) |
| git | 不操作(使用者用 GitHub Desktop) |
| 判斷 | 試完把結果整理成 state 問 JEV(是否導入、導入方式、風險),問題與原值都告訴使用者 |
| 回報 | 每項:做了什麼、結果、證據(檔案路徑/截圖);沒測到的明講 |

## 6. 其他進行中工作

- 任務 B(核心原型,含 D29 金球/黑球)已在原 session 派給 engineer,**不屬本 session**,不要碰 `game/`。
