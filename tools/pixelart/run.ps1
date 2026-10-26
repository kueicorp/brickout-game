# 重新產生磚塊像素圖預覽(docs/design/preview/)。
# 用 Godot headless 執行 md_to_png.gd,不需要 project.godot。
# 用法:powershell -ExecutionPolicy Bypass -File tools\pixelart\run.ps1 [-Godot <Godot console exe 路徑>] [-Md <設計稿路徑>] [-OutDir <輸出資料夾>]
#   -Md、-OutDir 預設為 docs\design\pixel-art-bricks.md 與 docs\design\preview;
#   測試設計稿副本時可指向暫存目錄，不會動到正式輸出
param(
    [string]$Godot = "E:\Godot 4\Godot_v4.7.2-stable_win64_console.exe",
    [string]$Md = '',
    [string]$OutDir = ''
)

$root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$md = if ($Md -ne '') { $Md } else { Join-Path $root "docs\design\pixel-art-bricks.md" }
$out = if ($OutDir -ne '') { $OutDir } else { Join-Path $root "docs\design\preview" }
$script = Join-Path $PSScriptRoot "md_to_png.gd"

if (-not (Test-Path $Godot)) {
    Write-Error "找不到 Godot:$Godot(用 -Godot 指定路徑)"
    exit 1
}
if (-not (Test-Path $md)) {
    Write-Error "找不到設計稿:$md"
    exit 1
}

& $Godot --headless --script $script -- $md $out
exit $LASTEXITCODE
