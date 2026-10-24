# 驗證 docs/design/preview/ 的輸出是否與設計稿一致(獨立於 md_to_png.gd 的第二套實作)。
# 檢查項目：
#   1. 單張 PNG:區塊數 = PNG 數、尺寸、每像素顏色與 D01 HEX 完全相同、`.` 的 alpha 為 0、×8 為最近鄰
#   2. 精靈圖：尺寸、所有像素都在 D01 內、正常幀與破壞幀依換色表換色後與設計稿一致、
#      被擊中幀符合規則、多層磚數字位置與 D12 範例一致、魔王 F1 = 正常圖疊上裂痕層、×6 為最近鄰
#   3. 示意盤面：尺寸 360×640、左右邊框、×3 為最近鄰
# 為了獨立，本腳本不沿用 md_to_png.gd 的檔名與規則解析：區塊依標題開頭查找，
# 磚種色階、層與數字對應、數字位置依 PM 交付的 D12 規格寫在下方常數。
# 用法:powershell -ExecutionPolicy Bypass -File tools\pixelart\verify.ps1 [-OutDir <輸出資料夾>]
#   -OutDir 預設為 docs\design\preview;反向測試時可指向複製出來的資料夾
param([string]$OutDir = '')
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

// 像素讀取與比對(PowerShell 迴圈太慢，逐像素工作放在這裡)
public class Img {
    public int W, H; public int[] P;
    public static Img Load(string path) {
        using (var bmp = new Bitmap(path)) {
            var img = new Img { W = bmp.Width, H = bmp.Height, P = new int[bmp.Width * bmp.Height] };
            var d = bmp.LockBits(new Rectangle(0, 0, img.W, img.H), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
            Marshal.Copy(d.Scan0, img.P, 0, img.P.Length);
            bmp.UnlockBits(d);
            return img;
        }
    }
    public int At(int x, int y) { return P[y * W + x]; }

    // 以 (ox, oy) 為左上角比對網格;'.' 只要求 alpha 0。回傳 "" 表示相符
    public string Compare(string[] grid, int ox, int oy, Dictionary<char, int> pal) {
        for (int y = 0; y < grid.Length; y++)
            for (int x = 0; x < grid[y].Length; x++) {
                char c = grid[y][x];
                int got = At(ox + x, oy + y);
                if (c == '.') { if (((got >> 24) & 0xFF) != 0) return string.Format("({0},{1}) 應透明", ox + x, oy + y); }
                else if (got != pal[c]) return string.Format("({0},{1}) 期望 {2:X8}({3}) 實際 {4:X8}", ox + x, oy + y, pal[c], c, got);
            }
        return "";
    }

    // big 是否為本圖的 f 倍最近鄰放大
    public string IsScaledBy(Img big, int f) {
        if (big.W != W * f || big.H != H * f) return string.Format("放大版尺寸 {0}x{1} 應為 {2}x{3}", big.W, big.H, W * f, H * f);
        for (int y = 0; y < big.H; y++)
            for (int x = 0; x < big.W; x++)
                if (big.At(x, y) != At(x / f, y / f)) return string.Format("放大版 ({0},{1}) 非最近鄰", x, y);
        return "";
    }

    // 所有像素都在調色盤內(透明像素算在內)
    public string AllInPalette(HashSet<int> colors) {
        for (int i = 0; i < P.Length; i++) {
            int v = P[i];
            if (((v >> 24) & 0xFF) == 0) continue;
            if (!colors.Contains(v)) return string.Format("({0},{1}) 顏色 {2:X8} 不在 D01", i % W, i / W, v);
        }
        return "";
    }

    // 被擊中規則：正常幀的 K 與透明保留，其餘像素在被擊中幀為 W
    public string CheckHit(int nx, int hx, int oy, int w, int h, int k, int white) {
        for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++) {
                int n = At(nx + x, oy + y), t = At(hx + x, oy + y);
                bool keep = n == k || ((n >> 24) & 0xFF) == 0;
                if (keep ? t != n : t != white) return string.Format("被擊中幀 ({0},{1}) 不符規則", x, y);
            }
        return "";
    }

    // 換色:from 第 i 個字元換成 to 第 i 個字元
    public static string[] Swap(string[] grid, string from, string to) {
        var o = new string[grid.Length];
        for (int y = 0; y < grid.Length; y++) {
            var cs = grid[y].ToCharArray();
            for (int x = 0; x < cs.Length; x++) { int i = from.IndexOf(cs[x]); if (i >= 0) cs[x] = to[i]; }
            o[y] = new string(cs);
        }
        return o;
    }

    // 疊加:top 的非 '.' 像素蓋到 base 上
    // 只比對網格中不透明的像素(用於疊在背景上的圖，例如盤面上的擋板)
    public string CompareOpaque(string[] grid, int ox, int oy, Dictionary<char, int> pal) {
        for (int y = 0; y < grid.Length; y++)
            for (int x = 0; x < grid[y].Length; x++) {
                char c = grid[y][x];
                if (c == '.') continue;
                int got = At(ox + x, oy + y);
                if (got != pal[c]) return string.Format("({0},{1}) 期望 {2:X8}({3}) 實際 {4:X8}", ox + x, oy + y, pal[c], c, got);
            }
        return "";
    }

    // 第 y0 列起 h 列內，最右邊不透明像素的欄號 + 1(即可見寬度);全透明回傳 0
    public int OpaqueWidth(int y0, int h) {
        int best = 0;
        for (int y = y0; y < y0 + h; y++)
            for (int x = W - 1; x >= best; x--)
                if (((At(x, y) >> 24) & 0xFF) != 0) { best = x + 1; break; }
        return best;
    }

    // 被擊中規則(任意位置):(nx,ny) 的正常區域與 (hx,hy) 的被擊中區域比對
    public string CheckHitAt(int nx, int ny, int hx, int hy, int w, int h, int k, int white) {
        for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++) {
                int n = At(nx + x, ny + y), t = At(hx + x, hy + y);
                bool keep = n == k || ((n >> 24) & 0xFF) == 0;
                if (keep ? t != n : t != white) return string.Format("被擊中 ({0},{1}) 不符規則", x, y);
            }
        return "";
    }

    public static string[] Overlay(string[] b, string[] top) {
        var o = new string[b.Length];
        for (int y = 0; y < b.Length; y++) {
            var cs = b[y].ToCharArray();
            for (int x = 0; x < cs.Length; x++) if (top[y][x] != '.') cs[x] = top[y][x];
            o[y] = new string(cs);
        }
        return o;
    }
}
'@

$root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$md = Join-Path $root "docs\design\pixel-art-bricks.md"
$out = if ($OutDir -ne '') { $OutDir } else { Join-Path $root "docs\design\preview" }
$spr = Join-Path $out "sprites"
$lines = [IO.File]::ReadAllLines($md, [Text.Encoding]::UTF8)

# ---- PM 交付的 D12 規格(驗證基準，刻意不從設計稿解析)
$CW = 32; $CH = 16; $BW = 128; $BH = 48
$colorOrder = '紅', '橙', '黃', '綠', '藍', '靛', '紫'
$digitX = 13; $digitY = 4                     # 依 D12 範例網格，0 起算
$fail = 0
function Fail($msg) { $script:fail++; Write-Output "FAIL $msg" }

# ---- D01 調色盤:代號 -> ARGB(Dictionary 區分大小寫)
$pal = New-Object 'System.Collections.Generic.Dictionary[char,int]'
$colors = New-Object 'System.Collections.Generic.HashSet[int]'
$section = ''
foreach ($l in $lines) {
    if ($l -match '\[(D\d+)\]') { $section = $Matches[1] }
    if ($section -eq 'D01' -and $l.Trim() -match '^\|\s*`(.)`\s*\|\s*#([0-9A-Fa-f]{6})\s*\|') {
        $v = [Convert]::ToInt32("FF" + $Matches[2], 16)
        $pal[[char]$Matches[1]] = $v; [void]$colors.Add($v)
    }
}
# PowerShell 變數不分大小寫，迴圈變數 $k 會蓋掉 $K,所以取較長的名稱
$COLOR_K = $pal[[char]'K']; $WHITE = $pal[[char]'W']

# ---- 區塊：依出現順序，記下所屬 D 項目與標題
$blocks = @()
$section = ''; $title = ''
for ($i = 0; $i -lt $lines.Count; $i++) {
    $s = $lines[$i].Trim()
    if ($s -match '\[(D\d+)\]') { $section = $Matches[1] }
    if ($s -eq '```text') {
        $g = New-Object System.Collections.Generic.List[string]; $i++
        while ($lines[$i].Trim() -ne '```') { $g.Add($lines[$i].Trim()); $i++ }
        $blocks += [pscustomobject]@{ Item = $section; Title = $title; Grid = [string[]]$g.ToArray() }
    } elseif ($s -ne '') { $title = $s }
}
function Get-Grid($prefix) {
    $m = @($blocks | Where-Object { $_.Item -eq 'D12' -and $_.Title.StartsWith($prefix) })
    if ($m.Count -ne 1) { Fail "D12 標題以「$prefix」開頭的區塊有 $($m.Count) 個"; return $null }
    return $m[0].Grid
}

# ---- 換色對照表(D12):顏色名 -> 5 個代號字串
$tiers = @{}; $inTable = $false
foreach ($l in $lines) {
    $s = $l.Trim()
    if ($s -match '^\|\s*目標\s*\|') { $inTable = $true; continue }
    if ($inTable) {
        if (-not $s.StartsWith('|')) { $inTable = $false; continue }
        $cells = $s.Trim('|').Split('|') | ForEach-Object { $_.Trim() }
        if ($cells[0] -match '^-+$') { continue }
        $tiers[$cells[0]] = (($cells[1..5] | ForEach-Object { $_.Trim('`') }) -join '')
    }
}
$red = $tiers['紅']

# ================================================================ 1. 單張 PNG
$files = @(Get-ChildItem $out -Filter 'D*.png' | Where-Object { $_.Name -notmatch '_x\d+\.png$' })
if ($files.Count -ne $blocks.Count) { Fail "區塊數 $($blocks.Count) 與單張 PNG 數 $($files.Count) 不一致" }
$used = @{}
foreach ($f in $files) {
    $img = [Img]::Load($f.FullName)
    $matched = $false
    for ($k = 0; $k -lt $blocks.Count; $k++) {
        $g = $blocks[$k].Grid
        if ($used[$k] -or $img.W -ne $g[0].Length -or $img.H -ne $g.Count) { continue }
        if ($img.Compare($g, 0, 0, $pal) -eq '') {
            $big = $f.FullName -replace '\.png$', '_x8.png'
            $r = if (Test-Path $big) { $img.IsScaledBy([Img]::Load($big), 8) } else { '缺少 _x8 放大版' }
            if ($r -ne '') { Fail "$($f.Name) x8: $r" }
            $used[$k] = $true; $matched = $true; break
        }
    }
    if (-not $matched) { Fail "殘留或錯誤的單張圖 $($f.Name):設計稿中找不到內容相符的區塊" }
}
for ($k = 0; $k -lt $blocks.Count; $k++) { if (-not $used[$k]) { Fail "設計稿 $($blocks[$k].Item)「$($blocks[$k].Title)」的區塊沒有對應的單張圖" } }
# 殘留判斷不寫死項目代號：檔名的項目代號必須出現在設計稿裡;放大版必須有對應的原尺寸檔
$items = @{}; foreach ($b in $blocks) { $items[$b.Item] = $true }
foreach ($f in Get-ChildItem $out -Filter 'D*.png') {
    if ($f.Name -match '^(D\d+)_' -and -not $items[$Matches[1]]) { Fail "殘留的舊圖 $($f.Name):設計稿中沒有項目 $($Matches[1])" }
    if ($f.Name -match '^(.+)_x\d+\.png$' -and -not (Test-Path (Join-Path $out "$($Matches[1]).png"))) { Fail "殘留的放大圖 $($f.Name):沒有對應的原尺寸檔" }
}
"單張 PNG:$($files.Count) 張"

# ================================================================ 2. 精靈圖
$master = Get-Grid '一般磚正常'
$f = @((Get-Grid 'F1'), (Get-Grid 'F2'), (Get-Grid 'F3'), (Get-Grid 'F4'))
$digits = @(0..9 | ForEach-Object { , (Get-Grid "數字 $_") })
$crackFree = [string[]]$master.Clone()
# 多層磚去裂痕(D12:第 25~27 欄、第 3~7 列的 T5 換成 T3);這裡只用來比對範例以外的列
for ($y = 3; $y -le 7; $y++) { $cs = $crackFree[$y].ToCharArray(); for ($x = 25; $x -le 27; $x++) { if ($cs[$x] -ceq $red[4]) { $cs[$x] = $red[2] } }; $crackFree[$y] = New-Object string (, $cs) }

# 每張精靈圖的期望：列 -> 6 格網格;$null 表示該格只做被擊中規則檢查
function Generic($color) { $t = $tiers[$color]; return @($f | ForEach-Object { , [Img]::Swap($_, $red, $t) }) }
function Multi($layer) {
    if ($layer -le 9) { $c = '藍'; $d = $layer } else { $c = '綠'; $d = $layer - 10 }
    $n = [Img]::Swap($crackFree, $red, $tiers[$c])
    $cs = @($n | ForEach-Object { , $_.ToCharArray() })
    for ($y = 0; $y -lt 7; $y++) { for ($x = 0; $x -lt 5; $x++) { if ($digits[$d][$y][$x] -ne '.') { $cs[$digitY + $y][$digitX + $x] = 'K' } } }
    $n = [string[]]@($cs | ForEach-Object { New-Object string (, $_) })
    return , (@(, $n) + @($null) + (Generic $c))
}
$boss = Get-Grid '魔王正常'
$expect = [ordered]@{
    'bricks_normal' = @{ W = $CW; H = $CH; Rows = @($colorOrder | ForEach-Object { , (@(, [Img]::Swap($master, $red, $tiers[$_])) + @($null) + (Generic $_)) }) }
    'bricks_multi'  = @{ W = $CW; H = $CH; Rows = @(1..14 | ForEach-Object { Multi $_ }) }
    'brick_chest'   = @{ W = $CW; H = $CH; Rows = @(, (@(, (Get-Grid '寶箱正常')) + @($null) + (Generic '橙'))) }
    'brick_coin'    = @{ W = $CW; H = $CH; Rows = @(, (@(, (Get-Grid '金幣正常')) + @($null) + (Generic '黃'))) }
    'brick_round'   = @{ W = $CW; H = $CH; Rows = @(, (@((Get-Grid '圓形正常'), $null, (Get-Grid '圓形 F1'), (Get-Grid '圓形 F2')) + @((Generic '紫')[2..3]))) }
    'brick_boss'    = @{ W = $BW; H = $BH; Rows = @(, @($boss, $null, [Img]::Overlay($boss, (Get-Grid '魔王裂痕疊加')), (Get-Grid '魔王 F2'), (Get-Grid '魔王 F3'), (Get-Grid '魔王 F4'))) }
}

foreach ($name in $expect.Keys) {
    $e = $expect[$name]; $path = Join-Path $spr "$name.png"
    if (-not (Test-Path $path)) { Fail "缺少 sprites/$name.png"; continue }
    $img = [Img]::Load($path)
    $rows = $e.Rows.Count
    if ($img.W -ne $e.W * 6 -or $img.H -ne $e.H * $rows) { Fail "$name 尺寸 $($img.W)x$($img.H),應為 $($e.W * 6)x$($e.H * $rows)"; continue }
    $r = $img.AllInPalette($colors); if ($r -ne '') { Fail "$name $r" }
    for ($row = 0; $row -lt $rows; $row++) {
        for ($col = 0; $col -lt 6; $col++) {
            $g = $e.Rows[$row][$col]
            if ($null -eq $g) { continue }
            $r = $img.Compare($g, $col * $e.W, $row * $e.H, $pal)
            if ($r -ne '') { Fail "$name 第 $($row + 1) 列第 $($col + 1) 格: $r" }
        }
        $r = $img.CheckHit(0, $e.W, $row * $e.H, $e.W, $e.H, $COLOR_K, $WHITE)
        if ($r -ne '') { Fail "$name 第 $($row + 1) 列: $r" }
    }
    $r = $img.IsScaledBy([Img]::Load((Join-Path $spr "${name}_x6.png")), 6); if ($r -ne '') { Fail "$name x6: $r" }
    "精靈圖 ${name}: $($img.W)x$($img.H)"
}

# 多層磚數字位置：數字區(第 13~17 欄、第 4~10 列)只有筆畫是 K;並與 D12 兩張範例逐像素相同
$multi = [Img]::Load((Join-Path $spr 'bricks_multi.png'))
for ($layer = 1; $layer -le 14; $layer++) {
    $d = if ($layer -le 9) { $layer } else { $layer - 10 }
    for ($y = 0; $y -lt 7; $y++) { for ($x = 0; $x -lt 5; $x++) {
        $isK = $multi.At($digitX + $x, ($layer - 1) * $CH + $digitY + $y) -eq $COLOR_K
        if ($isK -ne ($digits[$d][$y][$x] -ne '.')) { Fail "多層磚層 $layer 數字 ($x,$y) 位置不符" }
    } }
}
$r = $multi.Compare((Get-Grid '層 7 藍範例'), 0, 6 * $CH, $pal); if ($r -ne '') { Fail "多層磚層 7 與「層 7 藍範例」不同: $r" }
$r = $multi.Compare((Get-Grid '層 3 綠範例'), 0, 12 * $CH, $pal); if ($r -ne '') { Fail "多層磚層 13 與「層 3 綠範例」不同: $r" }

# ================================================================ 2b. 擋板(D13)
# PM 交付的規格(第 2 版):本體高 8、兩端各寬 8、中段圖塊寬 16、槍左右端 8×12、各段底部對齊、長度清單、最大 320
$PEND = 8; $PTILE = 16; $PMAX = 320
$segSize = @{ normal_left = '8x8'; normal_mid = '16x8'; normal_right = '8x8'; gun_left = '8x12'; gun_right = '8x12'
              sticky_left = '8x8'; sticky_mid = '16x8'; sticky_right = '8x8'; normal_64 = '64x8'; gun_64 = '64x12'; sticky_64 = '64x8' }
$setH = @{ paddle_normal = 8; paddle_gun = 12; paddle_sticky = 8; paddle_gun_sticky = 12 }
$PLEN = 16, 26, 51, 64, 77, 102, 320
function Get-Paddle($id) {
    $m = @($blocks | Where-Object { $_.Item -eq 'D13' -and $_.Title -match ('id\s*[:：]\s*' + [regex]::Escape($id) + '\s*[)）]') })
    if ($m.Count -ne 1) { Fail "D13 標題含 id「$id」的區塊有 $($m.Count) 個"; return $null }
    return , $m[0].Grid
}
# 依 D13 拼接規則重建：左端 + 中段圖塊 × n + 中段最左 r 欄 + 右端
# 參數名刻意不用 $l / $L:PowerShell 變數不分大小寫
# 各段底部對齊：整條高 = 三段最大高，較矮的段上方補透明
function Build-Paddle($left, $mid, $right, $len) {
    $h = @($left.Count, $mid.Count, $right.Count | Sort-Object)[-1]
    $segs = @($left, $mid, $right) | ForEach-Object { $seg = $_; , [string[]]@(@(1..($h - $seg.Count) | Where-Object { $h -gt $seg.Count } | ForEach-Object { '.' * $seg[0].Length }) + $seg) }
    $w = $len - 2 * $PEND; $n = [int][math]::Floor($w / $PTILE); $rem = $w % $PTILE
    return , [string[]]@(0..($h - 1) | ForEach-Object { $segs[0][$_] + ($segs[1][$_] * $n) + $segs[1][$_].Substring(0, $rem) + $segs[2][$_] })
}
$pp = @{}
foreach ($id in $segSize.Keys) {
    $pp[$id] = Get-Paddle "paddle_$id"
    if ($null -ne $pp[$id]) { $sz = "$($pp[$id][0].Length)x$($pp[$id].Count)"; if ($sz -ne $segSize[$id]) { Fail "paddle_$id 尺寸 $sz,應為 $($segSize[$id])" } }
}
$psets = [ordered]@{
    'paddle_normal'     = @($pp['normal_left'], $pp['normal_mid'], $pp['normal_right'])
    'paddle_gun'        = @($pp['gun_left'], $pp['normal_mid'], $pp['gun_right'])
    'paddle_sticky'     = @($pp['sticky_left'], $pp['sticky_mid'], $pp['sticky_right'])
    'paddle_gun_sticky' = @($pp['gun_left'], $pp['sticky_mid'], $pp['gun_right'])
}
# 規則拼出的 64 px 必須與設計稿的完整圖逐像素(逐字元)相同
foreach ($k in 'normal', 'gun', 'sticky') {
    $s3 = $psets["paddle_$k"]
    $built = (Build-Paddle $s3[0] $s3[1] $s3[2] 64) -join "`n"
    $ref = (Get-Paddle "paddle_${k}_64") -join "`n"
    if ($built -cne $ref) { Fail "依規則拼出的 paddle_$k 64 px 與完整圖 paddle_${k}_64 不同" }
}
foreach ($name in $psets.Keys) {
    $path = Join-Path $spr "$name.png"
    if (-not (Test-Path $path)) { Fail "缺少 sprites/$name.png"; continue }
    $img = [Img]::Load($path)
    $rowsN = $PLEN.Count * 2; $PH = $setH[$name]
    if ($img.W -ne $PMAX -or $img.H -ne $PH * $rowsN) { Fail "$name 尺寸 $($img.W)x$($img.H),應為 ${PMAX}x$($PH * $rowsN)"; continue }
    $r = $img.AllInPalette($colors); if ($r -ne '') { Fail "$name $r" }
    $s3 = $psets[$name]
    for ($k = 0; $k -lt $PLEN.Count; $k++) {
        $L = $PLEN[$k]
        $g = Build-Paddle $s3[0] $s3[1] $s3[2] $L
        $padded = [string[]]@($g | ForEach-Object { $_ + ('.' * ($PMAX - $L)) })
        $r = $img.Compare($padded, 0, $k * $PH, $pal); if ($r -ne '') { Fail "$name 長度 $L 正常版: $r" }
        foreach ($row in $k, ($k + $PLEN.Count)) { $ow = $img.OpaqueWidth($row * $PH, $PH); if ($ow -ne $L) { Fail "$name 第 $row 列寬度 $ow,應為 $L" } }
        $r = $img.CheckHitAt(0, $k * $PH, 0, ($k + $PLEN.Count) * $PH, $PMAX, $PH, $COLOR_K, $WHITE); if ($r -ne '') { Fail "$name 長度 $L $r" }
    }
    $r = $img.IsScaledBy([Img]::Load((Join-Path $spr "${name}_x6.png")), 6); if ($r -ne '') { Fail "$name x6: $r" }
    "精靈圖 ${name}: $($img.W)x$($img.H)"
}

# ================================================================ 3. 示意盤面
foreach ($n in 'overview.png', 'board_sample.png', 'board_sample_x3.png') { if (-not (Test-Path (Join-Path $out $n))) { Fail "缺少 $n" } }
$b1 = [Img]::Load((Join-Path $out 'board_sample.png'))
if ($b1.W -ne 360 -or $b1.H -ne 640) { Fail "board_sample 尺寸 $($b1.W)x$($b1.H),應為 360x640" }
$border = $b1.At(0, 0)
for ($y = 0; $y -lt $b1.H; $y += 1) { foreach ($x in 0, 19, 340, 359) { if ($b1.At($x, $y) -ne $border) { Fail "盤面邊框 ($x,$y) 非單色"; break } } }
if ($b1.At(20, 0) -eq $border) { Fail "盤面第 20 欄應已是磚區" }
$r = $b1.IsScaledBy([Img]::Load((Join-Path $out 'board_sample_x3.png')), 3); if ($r -ne '') { Fail "board x3: $r" }
# 盤面擋板:64 px 正常版，水平置中(x = (360 − 64) / 2 = 148),上緣 y = 600(PM 指示由工程師選定)
$r = $b1.CompareOpaque((Build-Paddle $pp['normal_left'] $pp['normal_mid'] $pp['normal_right'] 64), 148, 600, $pal); if ($r -ne '') { Fail "盤面擋板: $r" }
foreach ($old in Get-ChildItem $out -Filter 'board_sample_x*.png') { if ($old.Name -ne 'board_sample_x3.png') { Fail "殘留舊檔 $($old.Name)" } }

"檢查完成：區塊 $($blocks.Count) 個，調色盤 $($pal.Count) 色，失敗 $fail 項"
exit [int]($fail -ne 0)
