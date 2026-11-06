# 執行 game/tests 下全部測試,並把「結束碼 0 但其實出錯」的情況也算失敗。
# 用法(Windows PowerShell 5.1):
#   powershell -ExecutionPolicy Bypass -File game\tests\run_tests.ps1
#   powershell -ExecutionPolicy Bypass -File game\tests\run_tests.ps1 -Godot "E:\Godot 4\Godot_v4.7.2-stable_win64_console.exe" -TimeoutSec 300
# 判定為失敗的情況(任一):
#   1. 結束碼不是 0
#   2. 輸出含 SCRIPT ERROR / Parse Error / Failed to load script / Compile Error
#      (Godot --script 模式下,依賴腳本編譯失敗或 coroutine 內的執行期錯誤,結束碼仍可能是 0)
#   3. test_*.gd 沒有印出最後一行「PASSED n, FAILED 0」(例如測試中途被 quit() 結束、或錯誤讓 _run 提早結束)
#   4. 超過 TimeoutSec 沒結束(執行期錯誤讓 _run 中斷,永遠不會呼叫 quit())
# home_sim.gd 是測試共用的首頁替身,不是測試,不執行。
param(
    [string]$Godot = "E:\Godot 4\Godot_v4.7.2-stable_win64_console.exe",
    [int]$TimeoutSec = 300
)

$testsDir = $PSScriptRoot
$gameDir = Split-Path $testsDir -Parent
$tmp = Join-Path ([IO.Path]::GetTempPath()) ("godot_tests_" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tmp | Out-Null

$files = @(Get-ChildItem $testsDir -Filter "test_*.gd") + @(Get-ChildItem $testsDir -Filter "smoke_*.gd")
$bad = 0
foreach ($f in $files) {
    $outFile = Join-Path $tmp ($f.BaseName + ".out")
    $errFile = Join-Path $tmp ($f.BaseName + ".err")
    $argList = @("--headless", "--path", "`"$gameDir`"", "--script", "res://tests/$($f.Name)")
    $p = Start-Process -FilePath $Godot -ArgumentList $argList -NoNewWindow -PassThru `
        -RedirectStandardOutput $outFile -RedirectStandardError $errFile
    $null = $p.Handle  # 先取 Handle,之後才讀得到 ExitCode
    $reasons = @()
    if (-not $p.WaitForExit($TimeoutSec * 1000)) {
        $p.Kill()
        $reasons += "timeout ${TimeoutSec}s"
    } else {
        $p.WaitForExit()
        if ($p.ExitCode -ne 0) { $reasons += "exit $($p.ExitCode)" }
    }
    $text = (Get-Content $outFile, $errFile -Encoding UTF8 -ErrorAction SilentlyContinue) -join "`n"
    if ($text -match "SCRIPT ERROR|Parse Error|Failed to load script|Compile Error") { $reasons += "script error in output" }
    if ($f.Name -like "test_*") {
        $last = ([regex]::Matches($text, "PASSED (\d+), FAILED (\d+)") | Select-Object -Last 1)
        if ($null -eq $last) { $reasons += "no PASSED/FAILED line" }
        elseif ($last.Groups[2].Value -ne "0") { $reasons += "FAILED $($last.Groups[2].Value)" }
        $summary = if ($last) { $last.Value } else { "-" }
    } else {
        $summary = "-"
    }
    if ($reasons.Count -gt 0) {
        $bad++
        Write-Output ("FAIL  {0,-28} {1}  ({2})" -f $f.BaseName, $summary, ($reasons -join "; "))
        Get-Content $outFile, $errFile -Encoding UTF8 -ErrorAction SilentlyContinue |
            Where-Object { $_ -cmatch "FAIL |ERROR|at: " } | Select-Object -First 20 | ForEach-Object { "      $_" }
    } else {
        Write-Output ("ok    {0,-28} {1}" -f $f.BaseName, $summary)
    }
}
Remove-Item -Recurse -Force $tmp
Write-Output ("{0} files, {1} failed" -f $files.Count, $bad)
if ($bad -gt 0) { exit 1 } else { exit 0 }
