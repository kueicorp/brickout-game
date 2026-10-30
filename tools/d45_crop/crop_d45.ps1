# 依 crop_table.csv 把 D45 首頁的整層 PNG 裁成小檔,輸出到 game/art/home/。
# 像素原樣複製(32bpp ARGB,不縮放、不重新取樣、不改色),跑完重新讀取輸出檔逐像素比對來源。
#
# CSV 欄位:name, source(相對專案根目錄), x, y, w, h, mode
#   mode = fixed:直接裁 x,y,w,h
#   mode = bbox :在 x,y,w,h 範圍內找不透明像素(alpha > 0)的最小外框再裁;
#                 若外框碰到範圍邊緣,代表內容可能超出範圍,直接中止,避免默默截掉。
#
# 用法:powershell -ExecutionPolicy Bypass -File tools\d45_crop\crop_d45.ps1
# 結束碼:0 = 全部通過;1 = 有錯誤或比對差異。

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$outDir = Join-Path $root 'game\art\home'
$rows = Import-Csv (Join-Path $PSScriptRoot 'crop_table.csv')

# 讀整張圖成 32bpp ARGB 位元組陣列(BGRA 順序),回傳 @{ W; H; Bytes; Stride }。
function Read-Argb([string]$path) {
    $bmp = New-Object System.Drawing.Bitmap $path
    try {
        $rect = New-Object System.Drawing.Rectangle 0, 0, $bmp.Width, $bmp.Height
        $data = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
            $bytes = New-Object byte[] ($data.Stride * $bmp.Height)
            [System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $bytes, 0, $bytes.Length)
            return @{ W = $bmp.Width; H = $bmp.Height; Bytes = $bytes; Stride = $data.Stride }
        } finally { $bmp.UnlockBits($data) }
    } finally { $bmp.Dispose() }
}

# 在指定範圍內找 alpha > 0 的最小外框;全透明時回傳 $null。
function Get-OpaqueBBox($img, [int]$x, [int]$y, [int]$w, [int]$h) {
    $minX = [int]::MaxValue; $minY = [int]::MaxValue; $maxX = -1; $maxY = -1
    for ($yy = $y; $yy -lt $y + $h; $yy++) {
        for ($xx = $x; $xx -lt $x + $w; $xx++) {
            if ($img.Bytes[$yy * $img.Stride + $xx * 4 + 3] -ne 0) {
                if ($xx -lt $minX) { $minX = $xx }; if ($xx -gt $maxX) { $maxX = $xx }
                if ($yy -lt $minY) { $minY = $yy }; if ($yy -gt $maxY) { $maxY = $yy }
            }
        }
    }
    if ($maxX -lt 0) { return $null }
    return @($minX, $minY, ($maxX - $minX + 1), ($maxY - $minY + 1))
}

$cache = @{}
$results = @()
$failed = 0

foreach ($r in $rows) {
    $srcPath = Join-Path $root $r.source
    if (-not $cache.ContainsKey($srcPath)) { $cache[$srcPath] = Read-Argb $srcPath }
    $src = $cache[$srcPath]
    $x = [int]$r.x; $y = [int]$r.y; $w = [int]$r.w; $h = [int]$r.h

    if ($x -lt 0 -or $y -lt 0 -or $w -le 0 -or $h -le 0 -or $x + $w -gt $src.W -or $y + $h -gt $src.H) {
        throw "$($r.name):矩形 $x,$y,$w,$h 超出來源 $($r.source)($($src.W)x$($src.H))"
    }
    if ($r.mode -eq 'bbox') {
        $bb = Get-OpaqueBBox $src $x $y $w $h
        if ($null -eq $bb) { throw "$($r.name):範圍內沒有不透明像素" }
        if ($bb[0] -eq $x -or $bb[1] -eq $y -or $bb[0] + $bb[2] -eq $x + $w -or $bb[1] + $bb[3] -eq $y + $h) {
            throw "$($r.name):最小外框 $($bb -join ',') 碰到搜尋範圍邊緣,內容可能超出範圍,請放寬 CSV 的矩形"
        }
        $x, $y, $w, $h = $bb
    } elseif ($r.mode -ne 'fixed') {
        throw "$($r.name):未知的 mode '$($r.mode)'"
    }

    # 逐列複製原始 BGRA 位元組到新點陣圖,避開 DrawImage 可能的混色或重新取樣。
    $out = New-Object System.Drawing.Bitmap $w, $h, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    try {
        $lock = $out.LockBits((New-Object System.Drawing.Rectangle 0, 0, $w, $h), [System.Drawing.Imaging.ImageLockMode]::WriteOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
            for ($row = 0; $row -lt $h; $row++) {
                $dst = [IntPtr]::Add($lock.Scan0, $row * $lock.Stride)
                [System.Runtime.InteropServices.Marshal]::Copy($src.Bytes, ($y + $row) * $src.Stride + $x * 4, $dst, $w * 4)
            }
        } finally { $out.UnlockBits($lock) }
        $outPath = Join-Path $outDir $r.name
        $out.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally { $out.Dispose() }

    # 自我檢查:從磁碟重新讀輸出檔,每個像素(含 alpha)都要等於來源對應像素。
    $chk = Read-Argb $outPath
    $diff = 0
    if ($chk.W -ne $w -or $chk.H -ne $h) { $diff = -1 } else {
        for ($row = 0; $row -lt $h; $row++) {
            for ($i = 0; $i -lt $w * 4; $i++) {
                if ($chk.Bytes[$row * $chk.Stride + $i] -ne $src.Bytes[($y + $row) * $src.Stride + $x * 4 + $i]) { $diff++ }
            }
        }
    }
    if ($diff -ne 0) { $failed++ }
    $results += [pscustomobject]@{
        File   = $r.name
        Size   = "${w}x${h}"
        Source = [IO.Path]::GetFileName($r.source)
        Rect   = "$x,$y,$w,$h"
        Mode   = $r.mode
        Check  = if ($diff -eq 0) { 'OK' } elseif ($diff -lt 0) { 'FAIL size' } else { "FAIL $diff bytes" }
    }
}

$results | Format-Table -AutoSize | Out-String -Width 200 | Write-Output
Write-Output "Total: $($results.Count)  Failed: $failed"
if ($failed -gt 0) { exit 1 }
