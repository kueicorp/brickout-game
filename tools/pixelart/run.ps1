# 重新產生磚塊像素圖預覽(docs/design/preview/),並把遊戲要用的原尺寸檔輸出到 game/art/generated/。
# 用 Godot headless 執行 md_to_png.gd,不需要 project.godot。
# 用法:powershell -ExecutionPolicy Bypass -File tools\pixelart\run.ps1 [-Godot <Godot console exe 路徑>] [-Md <設計稿路徑>] [-OutDir <輸出資料夾>] [-GameDir <遊戲輸出資料夾>] [-NoGame]
#   -Md、-OutDir 預設為 docs\design\pixel-art-bricks.md 與 docs\design\preview;
#   測試設計稿副本時可指向暫存目錄，不會動到正式輸出
#   -GameDir 預設為 game\art\generated;給空字串或加 -NoGame 時只輸出預覽，不動遊戲資料夾
param(
    [string]$Godot = "E:\Godot 4\Godot_v4.7.2-stable_win64_console.exe",
    [string]$Md = '',
    [string]$OutDir = '',
    [string]$GameDir = '',
    [switch]$NoGame
)

$root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$md = if ($Md -ne '') { $Md } else { Join-Path $root "docs\design\pixel-art-bricks.md" }
$out = if ($OutDir -ne '') { $OutDir } else { Join-Path $root "docs\design\preview" }
# 有傳 -GameDir 就照傳入值(含空字串 = 不輸出);沒傳才用預設路徑
$game = if ($NoGame) { '' } elseif ($PSBoundParameters.ContainsKey('GameDir')) { $GameDir } else { Join-Path $root "game\art\generated" }
$script = Join-Path $PSScriptRoot "md_to_png.gd"

if (-not (Test-Path $Godot)) {
    Write-Error "找不到 Godot:$Godot(用 -Godot 指定路徑)"
    exit 1
}
if (-not (Test-Path $md)) {
    Write-Error "找不到設計稿:$md"
    exit 1
}

# PowerShell 5.1 傳給外部程式時會丟掉空字串參數，所以不輸出遊戲檔時乾脆不傳第三個參數
if ($game -ne '') {
    & $Godot --headless --script $script -- $md $out $game
} else {
    & $Godot --headless --script $script -- $md $out
}
exit $LASTEXITCODE
