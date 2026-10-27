# 驗證 docs/design/preview/ 的輸出是否與設計稿一致(獨立於 md_to_png.gd 的第二套實作)。
# 檢查項目：
#   1. 單張 PNG:區塊數 = PNG 數、尺寸、每像素顏色與 D01 HEX 完全相同、`.` 的 alpha 為 0、×8 為最近鄰
#       有「區塊調色盤」的網格以 D01 + 區塊調色盤比對
#   1b. 道具 F2(D20 13 張、D21 14 張):依底板 F1/F2 獨立重算後逐像素比對、×8 為最近鄰
#   1c. D23 主題邊框：依對照表獨立推算 5 階後逐像素比對、×8 為最近鄰;T3 灰階 Y 與飽和度檢查
#   2. 精靈圖：尺寸、所有像素都在 D01 內、正常幀與破壞幀依換色表換色後與設計稿一致、
#      被擊中幀符合規則、魔王 F1 = 正常圖疊上裂痕層、×6 為最近鄰;
#      多層磚(D12 新規則)70 列、與 4 張範例逐像素一致;D17 功能型磚 5 種 × 數字 1~9、與 3 張 _n5 範例一致;
#      垂直光束 6 張(旋轉、鏡射);D18 爆炸、彩虹磚與挑色環 7 色 × 3 幀;抽樣像素;sprites/ 沒有多餘檔案;
#      layer_map.json 層 1~69 對照
#   3. 示意盤面：尺寸 360×640、左右邊框、×3 為最近鄰
#   4. 資訊(不計失敗):D12 對比表(七色 T3 對 `W`、`K`)以 WCAG 公式重算，與設計稿手算值並列;
#      D23 各主題 T3 與七色 T3、魔王 `Z` 的 RGB 歐氏距離
#   5. laser_beam_layout.json 的 file 路徑(相對於 json 所在資料夾)全小寫、都指到實際存在的檔案(預覽與遊戲輸出各查一次);
#      預覽工具產生的檔案與遊戲輸出的實際檔名都必須全小寫(區分大小寫比對);
#      遊戲輸出：檔案集合 = 預覽的原尺寸檔(不含 _x6、_x8、overview、board_sample)扣掉排除規則($gameExclude)、
#      內容逐位元組相同、.import 必須有對應的 PNG、清單檔 .generated_files.txt 與檔案集合一致且不列排除的檔案
# 為了獨立，本腳本不沿用 md_to_png.gd 的檔名與規則解析：區塊依標題開頭或 id 查找，
# 層數對應、數字位置、描邊、裂痕範圍依 PM 交付的 D12、D17 規格寫在下方常數。
# 用法:powershell -ExecutionPolicy Bypass -File tools\pixelart\verify.ps1 [-OutDir <輸出資料夾>] [-Md <設計稿路徑>]
#   -OutDir 預設為 docs\design\preview;反向測試時可指向複製出來的資料夾
#   -Md 預設為 docs\design\pixel-art-bricks.md;驗證設計稿副本的輸出時指定
#   -GameDir 預設為 game\art\generated;給空字串或加 -NoGame 時不檢查遊戲輸出
param([string]$OutDir = '', [string]$Md = '', [string]$GameDir = '', [switch]$NoGame)
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
$md = if ($Md -ne '') { $Md } else { Join-Path $root "docs\design\pixel-art-bricks.md" }
$out = if ($OutDir -ne '') { $OutDir } else { Join-Path $root "docs\design\preview" }
$spr = Join-Path $out "sprites"
$lines = [IO.File]::ReadAllLines($md, [Text.Encoding]::UTF8)

# ---- PM 交付的 D12 規格(驗證基準，刻意不從設計稿解析)
$CW = 32; $CH = 16; $BW = 128; $BH = 48
$colorOrder = '紅', '橙', '黃', '綠', '藍', '靛', '紫'
$digitX = 13; $digitY = 4                     # D12 多層磚數字左上角，0 起算
$funcDigitX = 21; $funcDigitY = 4             # D17 功能型磚數字左上角，0 起算
$LAYERS = 69                                  # 實際使用的最高層數;圖產生到 70(紫 9)
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

# ---- 區塊：依出現順序，記下所屬 D 項目、標題與該區塊用的調色盤
# PM 交付的區塊調色盤規格:「圖寬」行正上方「區塊調色盤：a #RRGGBB；b #RRGGBB」,只對下一個網格有效，
# 疊在 D01 上(同名覆蓋),不可定義 `.`、`K`;不加入 $pal(不影響調色盤色數)
$blocks = @()
$section = ''; $title = ''; $region = $null
for ($i = 0; $i -lt $lines.Count; $i++) {
    $s = $lines[$i].Trim()
    if ($s -match '\[(D\d+)\]') { $section = $Matches[1] }
    if ($s -eq '```text') {
        $g = New-Object System.Collections.Generic.List[string]; $i++
        while ($lines[$i].Trim() -ne '```') { $g.Add($lines[$i].Trim()); $i++ }
        $bp = if ($null -ne $region) { $region } else { $pal }
        $blocks += [pscustomobject]@{ Item = $section; Title = $title; Grid = [string[]]$g.ToArray(); Pal = $bp }
        $region = $null
    } elseif ($s.StartsWith('區塊調色盤')) {
        $region = New-Object 'System.Collections.Generic.Dictionary[char,int]' $pal
        if ($i + 1 -ge $lines.Count -or -not $lines[$i + 1].Trim().StartsWith('圖寬')) { Fail "設計稿第 $($i + 1) 行的區塊調色盤不在「圖寬」行正上方" }
        if ($s -notmatch '^區塊調色盤：(.+)$') { Fail "設計稿第 $($i + 1) 行的區塊調色盤格式錯誤"; continue }
        $seen = @{}
        foreach ($part in $Matches[1].Split('；')) {
            # -cmatch:字元區分大小寫，才能分辨 `K` 與 `k`
            if ($part.Trim() -cnotmatch '^([!-~]) #([0-9A-Fa-f]{6})$' -or $Matches[1] -ceq '.' -or $Matches[1] -ceq 'K' -or $seen.ContainsKey([int][char]$Matches[1])) { Fail "設計稿第 $($i + 1) 行的區塊調色盤項目「$part」不合規格"; continue }
            $seen[[int][char]$Matches[1]] = $true
            $region[[char]$Matches[1]] = [Convert]::ToInt32("FF" + $Matches[2], 16)
        }
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

# 依 id 找區塊(標題含「(id: 代號)」)
function Get-ById($item, $id) {
    $m = @($blocks | Where-Object { $_.Item -eq $item -and $_.Title -match ('id\s*[:：]\s*' + [regex]::Escape($id) + '\s*[)）]') })
    if ($m.Count -ne 1) { Fail "$item 標題含 id「$id」的區塊有 $($m.Count) 個"; return $null }
    return , $m[0].Grid
}

# ---- PM 交付的 D20、D21 道具 F2 規格：道具 = id 以 item_ 開頭、不是 item_plate_* 與 item_pickup_*;
#      F2 逐像素：道具 F1 與底板 F1 同代號 → 底板 F2 的代號，否則保留 F1;道具數 D20 13 個、D21 14 個
$itemSpec = [ordered]@{ 'D20' = @('item_plate_buff_f1', 'item_plate_buff_f2', 13); 'D21' = @('item_plate_debuff_f1', 'item_plate_debuff_f2', 14) }
$itemF2 = [ordered]@{}   # 輸出檔名(不含 .png)-> 期望網格
foreach ($it in $itemSpec.Keys) {
    $p1 = Get-ById $it $itemSpec[$it][0]; $p2 = Get-ById $it $itemSpec[$it][1]
    $n = 0
    foreach ($b in $blocks) {
        if ($b.Item -ne $it -or $b.Title -notmatch 'id\s*[:：]\s*(item_[a-z0-9_]+)\s*[)）]') { continue }
        $id = $Matches[1]
        if ($id -match '^item_(plate|pickup)_') { continue }
        $n++
        $g = $b.Grid
        if ($null -eq $p1 -or $null -eq $p2 -or $g.Count -ne 16 -or $g[0].Length -ne 16) { Fail "$it $id 或其底板不是 16x16,無法驗證 F2"; continue }
        # 字元比較須區分大小寫(調色盤代號大小寫有別),所以用 -ceq
        $itemF2["${it}_${id}_f2".ToLower()] = [string[]]@(0..15 | ForEach-Object { $y = $_; -join @(0..15 | ForEach-Object { if ($g[$y][$_] -ceq $p1[$y][$_]) { $p2[$y][$_] } else { $g[$y][$_] } }) })
    }
    if ($n -ne $itemSpec[$it][2]) { Fail "$it 道具數 $n,應為 $($itemSpec[$it][2])" }
}

# ---- PM 交付的 D23 主題邊框規格：對照表(表頭第一欄「序」)中「邊框材質」含「A 苔石」且「做法」=「換色」的列，
#      以 T3 推算 T1~T5 = T3 逐通道 × 147、116、90、67、46 ÷ 90(四捨五入，上限 255),替換 3 張苔石網格的槽位 ( ) [ ] {;
#      T3 灰階 Y(0.299R + 0.587G + 0.114B)在 80~95、三通道最大減最小 ≤ 45;輸出 d23_<id>_t<序號兩位>(檔名全小寫)
$mossIds = 'border_moss_tile', 'border_moss_top_tile', 'border_moss_corner_tl'
$mossGrids = @{}; foreach ($id in $mossIds) { $mossGrids[$id] = Get-ById 'D23' $id }
$themeOut = [ordered]@{}   # 輸出檔名(不含 .png)-> 期望網格與調色盤
$themeT3 = [ordered]@{}    # 序號 -> T3 ARGB(資訊用)
$themeSkip = 0
$section = ''; $hdr = $null
foreach ($l in $lines) {
    $s = $l.Trim()
    if ($s -match '\[(D\d+)\]') { $section = $Matches[1] }
    if ($section -ne 'D23') { $hdr = $null; continue }
    if ($s -match '^\|\s*序\s*\|') { $hdr = @($s.Trim('|').Split('|') | ForEach-Object { $_.Trim() }); continue }
    if ($null -eq $hdr) { continue }
    if (-not $s.StartsWith('|')) { $hdr = $null; continue }
    $c = @($s.Trim('|').Split('|') | ForEach-Object { $_.Trim() })
    if ($c[0] -match '^-+$') { continue }
    $iT3 = @(0..($hdr.Count - 1) | Where-Object { $hdr[$_].StartsWith('T3') })[0]
    if (-not ($c[[array]::IndexOf($hdr, '邊框材質')].Contains('A 苔石') -and $c[[array]::IndexOf($hdr, '做法')] -eq '換色')) { $themeSkip++; continue }
    if ($c[$iT3] -notmatch '^#([0-9A-Fa-f]{6})(?![0-9A-Za-z])') { Fail "D23 主題 $($c[0]) 的 T3 HEX 格式錯誤: $($c[$iT3])"; continue }
    $hex = $Matches[1]; $seq = [int]$c[0]
    $rgb = @(0, 2, 4 | ForEach-Object { [Convert]::ToInt32($hex.Substring($_, 2), 16) })
    # 以 ×1000 的整數比較：浮點會把正好 80 的值(如 #454F72)算成 79.999… 而誤擋
    $y1000 = 299 * $rgb[0] + 587 * $rgb[1] + 114 * $rgb[2]
    if ($y1000 -lt 80000 -or $y1000 -gt 95000) { Fail "D23 主題 $seq T3 #$hex 灰階 Y $(($y1000 / 1000).ToString('F3')) 不在 80~95" }
    $spread = ($rgb | Measure-Object -Maximum -Minimum); if ($spread.Maximum - $spread.Minimum -gt 45) { Fail "D23 主題 $seq T3 #$hex 飽和度(最大減最小)超過 45" }
    # 鍵用字串：[ordered] 以整數索引時會被當成位置
    $themeT3["$seq"] = [Convert]::ToInt32("FF$hex", 16)
    $tp = New-Object 'System.Collections.Generic.Dictionary[char,int]' $pal
    $ratio = 147, 116, 90, 67, 46; $slots = '()[]{'
    for ($t = 0; $t -lt 5; $t++) {
        # 浮點除法後 +0.5 取 Floor = .5 進位(PowerShell [math]::Round 預設是銀行家捨入，不能用)
        # 變數名不可用 $ch:PowerShell 不分大小寫，會蓋掉 $CH
        $chan = @($rgb | ForEach-Object { [math]::Min(255, [int][math]::Floor($_ * $ratio[$t] / 90 + 0.5)) })
        $tp[$slots[$t]] = [Convert]::ToInt32(('FF{0:X2}{1:X2}{2:X2}' -f $chan[0], $chan[1], $chan[2]), 16)
    }
    foreach ($id in $mossIds) { if ($null -ne $mossGrids[$id]) { $themeOut[('d23_{0}_t{1:D2}' -f $id, $seq)] = [pscustomobject]@{ Grid = $mossGrids[$id]; Pal = $tp } } }
}
if ($themeT3.Count + $themeSkip -eq 0) { Fail 'D23 邊框依主題對照表解析不到任何列' }

# ================================================================ 1. 單張 PNG
# 道具 F2、D23 主題邊框不是設計稿區塊，另在 1b、1c 驗證
$files = @(Get-ChildItem $out -Filter 'D*.png' | Where-Object { $_.Name -notmatch '_x\d+\.png$' -and -not $itemF2.Contains($_.BaseName) -and -not $themeOut.Contains($_.BaseName) })
if ($files.Count -ne $blocks.Count) { Fail "區塊數 $($blocks.Count) 與單張 PNG 數 $($files.Count) 不一致" }
$used = @{}
foreach ($f in $files) {
    $img = [Img]::Load($f.FullName)
    $matched = $false
    for ($k = 0; $k -lt $blocks.Count; $k++) {
        $g = $blocks[$k].Grid
        if ($used[$k] -or $img.W -ne $g[0].Length -or $img.H -ne $g.Count) { continue }
        if ($img.Compare($g, 0, 0, $blocks[$k].Pal) -eq '') {
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
    if ($f.Name -match '^(D\d+)_' -and -not $items[$Matches[1].ToUpper()]) { Fail "殘留的舊圖 $($f.Name):設計稿中沒有項目 $($Matches[1])" }
    if ($f.Name -match '^(.+)_x\d+\.png$' -and -not (Test-Path (Join-Path $out "$($Matches[1]).png"))) { Fail "殘留的放大圖 $($f.Name):沒有對應的原尺寸檔" }
}
"單張 PNG:$($files.Count) 張"

# ================================================================ 1b. 道具 F2(D20、D21)
foreach ($name in $itemF2.Keys) {
    $path = Join-Path $out "$name.png"
    if (-not (Test-Path $path)) { Fail "缺少 $name.png"; continue }
    $img = [Img]::Load($path)
    if ($img.W -ne 16 -or $img.H -ne 16) { Fail "$name 尺寸 $($img.W)x$($img.H),應為 16x16"; continue }
    $r = $img.Compare($itemF2[$name], 0, 0, $pal); if ($r -ne '') { Fail "${name}: $r" }
    $big = Join-Path $out "${name}_x8.png"
    $r = if (Test-Path $big) { $img.IsScaledBy([Img]::Load($big), 8) } else { '缺少 _x8 放大版' }
    if ($r -ne '') { Fail "$name x8: $r" }
}
"道具 F2:$($itemF2.Count) 張"

# ================================================================ 1c. D23 主題邊框
foreach ($name in $themeOut.Keys) {
    $path = Join-Path $out "$name.png"
    if (-not (Test-Path $path)) { Fail "缺少 $name.png"; continue }
    $img = [Img]::Load($path); $e = $themeOut[$name]
    if ($img.W -ne $e.Grid[0].Length -or $img.H -ne $e.Grid.Count) { Fail "$name 尺寸 $($img.W)x$($img.H) 與網格不符"; continue }
    $r = $img.Compare($e.Grid, 0, 0, $e.Pal); if ($r -ne '') { Fail "${name}: $r" }
    $big = Join-Path $out "${name}_x8.png"
    $r = if (Test-Path $big) { $img.IsScaledBy([Img]::Load($big), 8) } else { '缺少 _x8 放大版' }
    if ($r -ne '') { Fail "$name x8: $r" }
}
"D23 主題邊框：$($themeOut.Count) 張(苔石換色 $($themeT3.Count) 個主題，略過 $themeSkip 列)"

# ================================================================ 2. 精靈圖
$master = Get-Grid '一般磚正常'
$f = @((Get-Grid 'F1'), (Get-Grid 'F2'), (Get-Grid 'F3'), (Get-Grid 'F4'))
$digits = @(0..9 | ForEach-Object { , (Get-Grid "數字 $_") })
function To-Grid($cs) { return , [string[]]@($cs | ForEach-Object { New-Object string (, $_) }) }

# 每張精靈圖的期望：列 -> 6 格網格;$null 表示該格只做被擊中規則檢查
function Generic($color) { $tt = $tiers[$color]; return @($f | ForEach-Object { , [Img]::Swap($_, $red, $tt) }) }

# D12 多層磚新規則(獨立寫法：以「鄰格是否有筆畫」判斷描邊，而非把描邊蓋上去)
#   層 n:顏色 = (n − 1) mod 7、數字 = (n − 1) div 7;數字 0 = 母版換色(保留裂痕)
#   數字 1~9:裂痕(第 25~27 欄、第 3~7 列 T5)與磨損(第 12 列第 16~17 欄 T2)改 T3,
#   再把第 12~18 欄、第 3~11 列內：字形筆畫 → W;非筆畫但 8 鄰格有筆畫 → K
function Multi-Normal($layer) {
    $ci = ($layer - 1) % 7; $d = [math]::Floor(($layer - 1) / 7)
    $tt = $tiers[$colorOrder[$ci]]
    $n = [Img]::Swap($master, $red, $tt)
    if ($d -eq 0) { return , $n }
    $cs = @($n | ForEach-Object { , $_.ToCharArray() })
    for ($y = 3; $y -le 7; $y++) { for ($x = 25; $x -le 27; $x++) { if ($cs[$y][$x] -ceq $tt[4]) { $cs[$y][$x] = $tt[2] } } }
    for ($x = 16; $x -le 17; $x++) { if ($cs[12][$x] -ceq $tt[1]) { $cs[12][$x] = $tt[2] } }
    $glyph = $digits[$d]
    $isInk = { param($gx, $gy) $gx -ge 0 -and $gx -lt 5 -and $gy -ge 0 -and $gy -lt 7 -and $glyph[$gy][$gx] -ne '.' }
    for ($y = $digitY - 1; $y -le $digitY + 7; $y++) {
        for ($x = $digitX - 1; $x -le $digitX + 5; $x++) {
            $gx = $x - $digitX; $gy = $y - $digitY
            if (& $isInk $gx $gy) { $cs[$y][$x] = 'W'; continue }
            $near = $false
            foreach ($dy in -1, 0, 1) { foreach ($dx in -1, 0, 1) { if (& $isInk ($gx + $dx) ($gy + $dy)) { $near = $true } } }
            if ($near) { $cs[$y][$x] = 'K' }
        }
    }
    return To-Grid $cs
}
# D17:底圖在第 21 欄、第 4 列疊上 `K` 數字(只蓋筆畫)
function Func-Normal($base, $d) {
    $cs = @($base | ForEach-Object { , $_.ToCharArray() })
    for ($y = 0; $y -lt 7; $y++) { for ($x = 0; $x -lt 5; $x++) { if ($digits[$d][$y][$x] -ne '.') { $cs[$funcDigitY + $y][$funcDigitX + $x] = 'K' } } }
    return To-Grid $cs
}

$boss = Get-Grid '魔王正常'
$expect = [ordered]@{
    'bricks_normal' = @{ W = $CW; H = $CH; Rows = @($colorOrder | ForEach-Object { , (@(, [Img]::Swap($master, $red, $tiers[$_])) + @($null) + (Generic $_)) }) }
    'bricks_multi'  = @{ W = $CW; H = $CH; Rows = @(1..70 | ForEach-Object { , (@(, (Multi-Normal $_)) + @($null) + (Generic $colorOrder[($_ - 1) % 7])) }) }
    'brick_chest'   = @{ W = $CW; H = $CH; Rows = @(, (@(, (Get-Grid '寶箱正常')) + @($null) + (Generic '橙'))) }
    'brick_coin'    = @{ W = $CW; H = $CH; Rows = @(, (@(, (Get-Grid '金幣正常')) + @($null) + (Generic '黃'))) }
    'brick_round'   = @{ W = $CW; H = $CH; Rows = @(, (@((Get-Grid '圓形正常'), $null, (Get-Grid '圓形 F1'), (Get-Grid '圓形 F2')) + @((Generic '紫')[2..3]))) }
    'brick_boss'    = @{ W = $BW; H = $BH; Rows = @(, @($boss, $null, [Img]::Overlay($boss, (Get-Grid '魔王裂痕疊加')), (Get-Grid '魔王 F2'), (Get-Grid '魔王 F3'), (Get-Grid '魔王 F4'))) }
}
# D17 功能型磚：5 種 × 數字 1~9;破壞幀依 D17 換色表
$funcSpec = [ordered]@{ 'brick_laser_h' = @('laser_brick_h', '雷射（洋紅）'); 'brick_laser_v' = @('laser_brick_v', '雷射（洋紅）'); 'brick_laser_x' = @('laser_brick_x', '雷射（洋紅）')
                        'brick_lightning' = @('lightning_brick', '閃電（電青）'); 'brick_reaper' = @('reaper_brick', '死神（骨白）') }
foreach ($name in $funcSpec.Keys) {
    $base = Get-ById 'D17' $funcSpec[$name][0]; $tierName = $funcSpec[$name][1]
    if (-not $tiers.ContainsKey($tierName)) { Fail "設計稿找不到換色表列「$tierName」"; continue }
    $expect[$name] = @{ W = $CW; H = $CH; Rows = @(1..9 | ForEach-Object { , (@(, (Func-Normal $base $_)) + @($null) + (Generic $tierName)) }) }
}
# D18 爆炸、彩虹磚
foreach ($p in @(@('brick_explosion', 'explosion_brick', '爆炸（炸藥褐）'), @('brick_rainbow', 'rainbow_brick', '彩虹（珍珠白）'))) {
    if (-not $tiers.ContainsKey($p[2])) { Fail "設計稿找不到換色表列「$($p[2])」"; continue }
    $expect[$p[0]] = @{ W = $CW; H = $CH; Rows = @(, (@(, (Get-ById 'D18' $p[1])) + @($null) + (Generic $p[2]))) }
}

$sheetImg = @{}
foreach ($name in $expect.Keys) {
    $e = $expect[$name]; $path = Join-Path $spr "$name.png"
    if (-not (Test-Path $path)) { Fail "缺少 sprites/$name.png"; continue }
    $img = [Img]::Load($path); $sheetImg[$name] = $img
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
    "精靈圖 ${name}: $($img.W)x$($img.H)(正常 $rows、被擊中 $rows)"
}

# 範例網格必須與本腳本的期望(也就是與輸出)逐像素相同:D12 四張多層磚範例、D17 三張數字 5 範例
$layerExamples = [ordered]@{ 'layer_example_red1' = 8; 'layer_example_indigo2' = 20; 'layer_example_blue8' = 61; 'layer_example_yellow3' = 24 }
foreach ($id in $layerExamples.Keys) {
    $g = Get-ById 'D12' $id; $layer = $layerExamples[$id]
    if ($null -eq $g) { continue }
    if (((Multi-Normal $layer) -join "`n") -cne ($g -join "`n")) { Fail "驗證腳本依新規則算出的層 $layer 與範例 $id 不同" }
    if ($sheetImg['bricks_multi']) { $r = $sheetImg['bricks_multi'].Compare($g, 0, ($layer - 1) * $CH, $pal); if ($r -ne '') { Fail "bricks_multi 層 $layer 與範例 $id 不同: $r" } }
}
foreach ($p in @(@('brick_laser_h', 'laser_brick_h_n5'), @('brick_laser_v', 'laser_brick_v_n5'), @('brick_laser_x', 'laser_brick_x_n5'))) {
    $g = Get-ById 'D17' $p[1]
    if ($null -eq $g -or -not $sheetImg[$p[0]]) { continue }
    $r = $sheetImg[$p[0]].Compare($g, 0, 4 * $CH, $pal); if ($r -ne '') { Fail "$($p[0]) 數字 5 與範例 $($p[1]) 不同: $r" }
}
"範例比對：多層磚 $($layerExamples.Count) 張、功能型磚 3 張"

# 垂直光束：逆時針轉 90 度(新[r][c] = 原[c][15 − r]);往下端點 = 往上端點上下鏡射
function Rot-Ccw($g) { $n = $g.Count; return , [string[]]@(0..($n - 1) | ForEach-Object { $rr = $_; -join @(0..($n - 1) | ForEach-Object { $g[$_][$n - 1 - $rr] }) }) }
$beams = [ordered]@{}
foreach ($k in 'thin', 'full') {
    $beams["laser_beam_v_mid_$k"] = Rot-Ccw (Get-ById 'D17' "laser_beam_mid_$k")
    $up = Rot-Ccw (Get-ById 'D17' "laser_beam_block_$k")
    $beams["laser_beam_v_block_up_$k"] = $up
    $beams["laser_beam_v_block_down_$k"] = [string[]]@($up[($up.Count - 1)..0])
}
foreach ($name in $beams.Keys) {
    $path = Join-Path $spr "$name.png"
    if (-not (Test-Path $path)) { Fail "缺少 sprites/$name.png"; continue }
    $img = [Img]::Load($path)
    if ($img.W -ne 16 -or $img.H -ne 16) { Fail "$name 尺寸 $($img.W)x$($img.H),應為 16x16"; continue }
    $r = $img.Compare($beams[$name], 0, 0, $pal); if ($r -ne '') { Fail "${name}: $r" }
    $r = $img.IsScaledBy([Img]::Load((Join-Path $spr "${name}_x6.png")), 6); if ($r -ne '') { Fail "$name x6: $r" }
}
"垂直光束：$($beams.Count) 張"

# 彩虹挑色環：7 列(紅橙黃綠藍靛紫)× 3 幀(48×32),依 D12 換色表;沒有白色版(高度剛好 7 列)
$pick = @(1..3 | ForEach-Object { , (Get-ById 'D18' "rainbow_pick_f$_") })
$path = Join-Path $spr 'rainbow_pick.png'
if (-not (Test-Path $path)) { Fail '缺少 sprites/rainbow_pick.png' } else {
    $img = [Img]::Load($path); $sheetImg['rainbow_pick'] = $img
    if ($img.W -ne 48 * 3 -or $img.H -ne 32 * 7) { Fail "rainbow_pick 尺寸 $($img.W)x$($img.H),應為 144x224(7 色 × 3 幀，不含白色版)" } else {
        for ($ci = 0; $ci -lt 7; $ci++) { for ($k = 0; $k -lt 3; $k++) {
            $r = $img.Compare([Img]::Swap($pick[$k], $red, $tiers[$colorOrder[$ci]]), $k * 48, $ci * 32, $pal)
            if ($r -ne '') { Fail "rainbow_pick $($colorOrder[$ci]) F$($k + 1): $r" }
        } }
        $r = $img.IsScaledBy([Img]::Load((Join-Path $spr 'rainbow_pick_x6.png')), 6); if ($r -ne '') { Fail "rainbow_pick x6: $r" }
        "精靈圖 rainbow_pick: $($img.W)x$($img.H)(7 色 × 3 幀 = 21 張)"
    }
}

# 抽樣像素(依 PM 交付規格直接寫出座標與期望代號;sheet、列、欄、x、y、代號)
$samples = @(
    @('bricks_multi', 0, 0, 27, 3, 'o'),    # 層 1 紅(第 0 輪)保留裂痕
    @('bricks_multi', 7, 0, 27, 3, 'R'),    # 層 8 紅 1:裂痕改 T3
    @('bricks_multi', 7, 0, 16, 12, 'R'),   # 層 8:第 12 列磨損改 T3
    @('bricks_multi', 0, 0, 16, 12, 'r'),   # 層 1:磨損保留
    @('bricks_multi', 7, 0, 15, 4, 'W'),    # 層 8:數字 1 頂端白字
    @('bricks_multi', 7, 0, 14, 4, 'K'),    # 層 8:描邊
    @('bricks_multi', 60, 1, 13, 4, 'K'),   # 層 61 藍 8 被擊中：描邊仍為 K
    @('bricks_multi', 60, 1, 20, 8, 'W'),   # 層 61 被擊中：磚面全白
    @('bricks_multi', 60, 2, 3, 3, 'U'),    # 層 61 F1:藍色階 T3
    @('bricks_multi', 69, 0, 15, 4, 'W'),   # 層 70 紫 9 有產生
    @('brick_laser_h', 0, 0, 23, 4, 'K'),   # 數字 1 頂端 `K`(第 21 + 2 欄)
    @('brick_laser_h', 0, 0, 21, 4, '#'),   # 數字 1 左上角不是筆畫，維持底色
    @('brick_lightning', 8, 2, 3, 3, '~'),  # 閃電 F1:電青 T3
    @('brick_reaper', 8, 2, 3, 3, '$'),     # 死神 F1:骨白 T3
    @('brick_laser_v', 0, 2, 3, 3, '#'),    # 雷射 F1:洋紅 T3
    @('brick_explosion', 0, 2, 1, 2, '-'),  # 爆炸 F1:褐 T2
    @('brick_rainbow', 0, 2, 1, 2, '1'),    # 彩虹 F1:珍珠白 T2
    @('brick_rainbow', 0, 2, 1, 1, 'W')     # 彩虹 F1:珍珠白 T1 = W
)
$sampleN = 0
foreach ($s in $samples) {
    $img = $sheetImg[$s[0]]; if ($null -eq $img) { continue }
    $cw = $CW; $ch = $CH
    $got = $img.At($s[2] * $cw + $s[3], $s[1] * $ch + $s[4])
    if ($got -ne $pal[[char]$s[5]]) { Fail "抽樣 $($s[0]) 第 $($s[1]) 列第 $($s[2]) 格 ($($s[3]),$($s[4])) 應為 $($s[5])" }
    $sampleN++
}
# 挑色環抽樣：藍色 F1 左上角環(第 5 欄第 4 列)= 藍 T1 `M`;F2 中央亮點(第 23 欄第 1 列)= `W` 不換色
if ($sheetImg['rainbow_pick']) {
    if ($sheetImg['rainbow_pick'].At(5, 4 * 32 + 4) -ne $pal[[char]'M']) { Fail '抽樣 rainbow_pick 藍 F1 (5,4) 應為 M' }
    if ($sheetImg['rainbow_pick'].At(48 + 23, 4 * 32 + 1) -ne $WHITE) { Fail '抽樣 rainbow_pick 藍 F2 (23,1) 應為 W' }
    $sampleN += 2
}
"抽樣像素：$sampleN 點"

# 層數對照表：層 1~69 → (顏色, 數字),列號 = 層 − 1
$lmPath = Join-Path $spr 'layer_map.json'
if (-not (Test-Path $lmPath)) { Fail '缺少 sprites/layer_map.json' } else {
    $lm = [IO.File]::ReadAllText($lmPath, [Text.Encoding]::UTF8) | ConvertFrom-Json
    $slug = @{ '紅' = 'red'; '橙' = 'orange'; '黃' = 'yellow'; '綠' = 'green'; '藍' = 'blue'; '靛' = 'indigo'; '紫' = 'violet' }
    if ($lm.max_layer -ne $LAYERS -or @($lm.layers).Count -ne $LAYERS) { Fail "layer_map.json 應有層 1~$LAYERS" } else {
        for ($n = 1; $n -le $LAYERS; $n++) {
            $e = $lm.layers[$n - 1]; $cn = $colorOrder[($n - 1) % 7]
            if ($e.layer -ne $n -or $e.color -ne $slug[$cn] -or $e.color_name -ne $cn -or $e.digit -ne [math]::Floor(($n - 1) / 7) -or $e.row -ne $n - 1) { Fail "layer_map.json 層 $n 對應錯誤" }
        }
    }
    # 設計稿「層數對應」表的例子
    foreach ($p in @(@(1, 'red', 0), @(7, 'violet', 0), @(8, 'red', 1), @(14, 'violet', 1), @(20, 'indigo', 2), @(24, 'yellow', 3), @(61, 'blue', 8), @(69, 'indigo', 9))) {
        $e = $lm.layers[$p[0] - 1]; if ($e.color -ne $p[1] -or $e.digit -ne $p[2]) { Fail "layer_map.json 層 $($p[0]) 應為 $($p[1]) $($p[2])" }
    }
    "層數對照表：$(@($lm.layers).Count) 層"
}

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

# sprites/ 只能有上面驗過的檔案(含 _x6 放大版與兩個 JSON),舊產物或多餘的版本(如挑色環白色版)都算失敗
$allowed = @{ 'layer_map.json' = $true; 'laser_beam_layout.json' = $true }
foreach ($n in @($expect.Keys) + @($beams.Keys) + @('rainbow_pick') + @($psets.Keys)) { $allowed["$n.png"] = $true; $allowed["${n}_x6.png"] = $true }
$sprFiles = @(Get-ChildItem $spr -File)
foreach ($file in $sprFiles) { if (-not $allowed[$file.Name]) { Fail "sprites/ 有多餘或殘留的檔案 $($file.Name)" } }
"sprites/ 檔案：$($sprFiles.Count) 個(PNG $(@($sprFiles | Where-Object { $_.Extension -eq '.png' -and $_.Name -notmatch '_x\d+\.png$' }).Count) 張 + 放大版 + JSON)"

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

# ================================================================ 4. 資訊:D12 對比表複核(不計失敗)
# WCAG 2 相對亮度：通道 c/255 ≤ 0.03928 時 /12.92,否則 ((c + 0.055)/1.055)^2.4;對比 = (亮 + 0.05)/(暗 + 0.05)
function Lum([int]$argb) {
    $sum = 0.0
    foreach ($p in @(@(16, 0.2126), @(8, 0.7152), @(0, 0.0722))) {
        $c = (($argb -shr $p[0]) -band 0xFF) / 255.0
        $lin = if ($c -le 0.03928) { $c / 12.92 } else { [math]::Pow(($c + 0.055) / 1.055, 2.4) }
        $sum += $p[1] * $lin
    }
    return $sum
}
function Ratio($a, $b) { $la = Lum $a; $lb = Lum $b; return ([math]::Max($la, $lb) + 0.05) / ([math]::Min($la, $lb) + 0.05) }
# 設計稿 D12「對比數值」表的手算值(`W` 對底、`K` 對底)
$stated = [ordered]@{ 'R' = @(5.72, 2.97); 'd' = @(3.01, 5.65); 'Y' = @(1.41, 12.06); 'L' = @(1.68, 10.12); 'U' = @(3.63, 4.68); 'I' = @(9.46, 1.80); 'V' = @(5.63, 3.02) }
"D12 對比複核(工具算 / 設計稿):"
foreach ($c in $stated.Keys) {
    $w = Ratio $WHITE $pal[[char]$c]; $kk = Ratio $COLOR_K $pal[[char]$c]
    $note = if ([math]::Abs([math]::Round($w, 2) - $stated[$c][0]) -gt 0.005 -or [math]::Abs([math]::Round($kk, 2) - $stated[$c][1]) -gt 0.005) { '  <- 與設計稿不同' } else { '' }
    "  {0}  W {1:N3} / {2:N2}   K {3:N3} / {4:N2}   較高 {5:N3}{6}" -f $c, $w, $stated[$c][0], $kk, $stated[$c][1], [math]::Max($w, $kk), $note
}
"  W 對 K {0:N3} / 17.02" -f (Ratio $WHITE $COLOR_K)

# ---- D23 主題 T3 與七色磚 T3、魔王 `Z` 的 RGB 歐氏距離(資訊，不計失敗;是否「太接近」由 PM 判斷)
function Dist([int]$a, [int]$b) { $sq = 0; foreach ($sh in 16, 8, 0) { $d = (($a -shr $sh) -band 0xFF) - (($b -shr $sh) -band 0xFF); $sq += $d * $d }; return [math]::Sqrt($sq) }
"D23 主題 T3 距離(七色取最近者 / 魔王 Z):"
foreach ($seq in $themeT3.Keys) {
    $t3v = $themeT3[$seq]
    $near = @($colorOrder | ForEach-Object { [pscustomobject]@{ N = $_; D = (Dist $t3v $pal[$tiers[$_][2]]) } } | Sort-Object D)[0]
    $yy = 0.299 * (($t3v -shr 16) -band 0xFF) + 0.587 * (($t3v -shr 8) -band 0xFF) + 0.114 * ($t3v -band 0xFF)
    "  主題 {0,2}  #{1:X6}  Y {2:N1}  最近七色 {3} {4:N1}  Z {5:N1}" -f $seq, ($t3v -band 0xFFFFFF), $yy, $near.N, $near.D, (Dist $t3v $pal[[char]'Z'])
}

# ================================================================ 5. 光束路徑與遊戲輸出
# laser_beam_layout.json 的 file 相對於 json 所在資料夾(sprites/)
function Check-BeamPaths($dir, $label) {
    $sd = Join-Path $dir 'sprites'; $jp = Join-Path $sd 'laser_beam_layout.json'
    if (-not (Test-Path $jp)) { Fail "$label 缺少 sprites/laser_beam_layout.json"; return }
    $j = [IO.File]::ReadAllText($jp, [Text.Encoding]::UTF8) | ConvertFrom-Json
    $props = @($j.pieces.PSObject.Properties)
    if ($props.Count -eq 0) { Fail "$label laser_beam_layout.json 沒有任何分段" }
    # Test-Path 不分大小寫，所以另查路徑必須全小寫(磁碟上的實際檔名由下方的大小寫檢查負責)
    foreach ($pc in $props) { if ($pc.Value.file -cmatch '[A-Z]') { Fail "$label laser_beam_layout.json 的 $($pc.Name) 路徑 $($pc.Value.file) 含大寫" } }
    foreach ($pc in $props) { if (-not (Test-Path -LiteralPath (Join-Path $sd $pc.Value.file) -PathType Leaf)) { Fail "$label laser_beam_layout.json 的 $($pc.Name) 路徑 $($pc.Value.file) 找不到檔案" } }
    "$label laser_beam_layout.json:$($props.Count) 個路徑已檢查"
}
Check-BeamPaths $out '預覽'

# 輸出檔名必須全小寫:Windows 不分大小寫，-match / Test-Path 都看不出差別，所以用 -cmatch 查磁碟上的實際檔名
function Check-Lowercase($names, $label) {
    $bad = @($names | Where-Object { $_ -cmatch '[A-Z]' })
    foreach ($n in $bad) { Fail "$label 檔名含大寫 $n" }
    "$label 檔名大小寫:$(@($names).Count) 個已檢查，含大寫 $($bad.Count) 個"
}
# 預覽頂層只查工具產生的檔名格式(與 md_to_png.gd 清檔規則相同,-match 不分大小寫才抓得到舊的 D12_*);final/ 等子資料夾不查
Check-Lowercase @(Get-ChildItem $out -File | Where-Object { $_.Name -match '^(d\d+_.+|overview|board_sample(_x\d+)?)\.png$' } | ForEach-Object { $_.Name }) '預覽'
Check-Lowercase @(Get-ChildItem $spr -File | ForEach-Object { "sprites/$($_.Name)" }) '預覽'

# PM 交付的遊戲排除規則：只給設計參考的版面線框(layout_)、範例圖(_example)、D14 無敵疊加的兩張範例;
# 這些圖預覽照舊輸出，但不可出現在遊戲輸出與清單檔
$gameExclude = 'layout_|_example|^d14_invincible_a_(blue7|red)\.png$'

$game = if ($NoGame) { '' } elseif ($PSBoundParameters.ContainsKey('GameDir')) { $GameDir } else { Join-Path $root 'game\art\generated' }
if ($game -ne '') {
    if (-not (Test-Path $game)) { Fail "找不到遊戲輸出資料夾 $game" } else {
        # 期望 = 預覽的原尺寸檔扣掉排除規則;相對路徑用 / 分隔，與清單檔一致
        $want = [ordered]@{}; $excluded = @()
        foreach ($x in Get-ChildItem $out -File -Filter '*.png') { if ($x.Name -notmatch '_x\d+\.png$' -and $x.Name -notmatch '^(overview|board_sample)') { $want[$x.Name] = $x.FullName } }
        foreach ($x in Get-ChildItem $spr -File) { if ($x.Name -match '\.(png|json)$' -and $x.Name -notmatch '_x\d+\.png$') { $want["sprites/$($x.Name)"] = $x.FullName } }
        foreach ($rel in @($want.Keys)) { if ($rel -match $gameExclude) { $excluded += $rel; $want.Remove($rel) } }
        "遊戲排除(預覽有、遊戲不放):$($excluded.Count) 個 — $($excluded -join ', ')"
        $have = @{}
        foreach ($x in Get-ChildItem $game -Force) {
            if ($x.PSIsContainer) { if ($x.Name -ne 'sprites') { Fail "遊戲輸出有多餘的資料夾 $($x.Name)" }; continue }
            $have[$x.Name] = $x.FullName
        }
        if (Test-Path (Join-Path $game 'sprites')) {
            foreach ($x in Get-ChildItem (Join-Path $game 'sprites') -Force) {
                if ($x.PSIsContainer) { Fail "遊戲輸出有多餘的資料夾 sprites/$($x.Name)"; continue }
                $have["sprites/$($x.Name)"] = $x.FullName
            }
        }
        Check-Lowercase @($have.Keys) '遊戲'
        foreach ($rel in $have.Keys) {
            if ($rel -match $gameExclude) { Fail "遊戲輸出不應有排除清單的檔案 $rel"; continue }
            if ($want.Contains($rel)) { continue }
            if ($rel -eq '.generated_files.txt') { continue }
            if ($rel -match '^(.+)\.import$') { if (-not $want.Contains($Matches[1])) { Fail "遊戲輸出有殘留的 $rel(沒有對應的檔案)" }; continue }
            if ($rel -match '(_x\d+\.png|^overview\.png|^board_sample.*\.png)$') { Fail "遊戲輸出不應有放大版、總覽或盤面圖 $rel" } else { Fail "遊戲輸出有多餘或殘留的檔案 $rel" }
        }
        $same = 0
        foreach ($rel in $want.Keys) {
            if (-not $have.ContainsKey($rel)) { Fail "遊戲輸出缺少 $rel"; continue }
            if ((Get-FileHash -LiteralPath $have[$rel] -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $want[$rel] -Algorithm SHA256).Hash) { Fail "遊戲輸出 $rel 與預覽內容不同" } else { $same++ }
        }
        $mf = Join-Path $game '.generated_files.txt'
        if (-not (Test-Path $mf)) { Fail '遊戲輸出缺少清單檔 .generated_files.txt' } else {
            $listed = @([IO.File]::ReadAllLines($mf) | Where-Object { $_ -ne '' } | Sort-Object)
            foreach ($l in $listed) { if ($l -match $gameExclude) { Fail "清單檔列出排除清單的檔案 $l" } }
            # -cne:清單項目大小寫不同也算不一致(sync 只接受全小寫項目)
            if (($listed -join '|') -cne ((@($want.Keys) | Sort-Object) -join '|')) { Fail '清單檔 .generated_files.txt 與應有的檔案集合不一致' }
        }
        Check-BeamPaths $game '遊戲'
        "遊戲輸出:應有 $($want.Count) 個檔案，逐位元組相同 $same 個(另有 .import $(@($have.Keys | Where-Object { $_ -match '\.import$' }).Count) 個)"
    }
}

"檢查完成：區塊 $($blocks.Count) 個，調色盤 $($pal.Count) 色，失敗 $fail 項"
exit [int]($fail -ne 0)
