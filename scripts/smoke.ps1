# SBCL と SDL2 を探索できない環境でも単体で動作することを確認する。
$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot '..')
$keys = @('APPDATA', 'PATH', 'SBCL_HOME', 'SDL_VIDEODRIVER', 'SDL_AUDIODRIVER')
$previous = @{}
foreach ($key in $keys) { $previous[$key] = [Environment]::GetEnvironmentVariable($key, 'Process') }
try {
    New-Item -ItemType Directory -Force build/smoke | Out-Null
    $env:APPDATA = (Resolve-Path build/smoke).Path
    $env:PATH = "$env:SystemRoot/system32"
    $env:SBCL_HOME = $null
    $env:SDL_VIDEODRIVER = 'invalid'
    $env:SDL_AUDIODRIVER = 'invalid'
    $version = [regex]::Match((Get-Content lispgb.asd -Raw), ':version\s+"([^"]+)"').Groups[1].Value
    if ((& ./build/lispgb.exe --version) -ne "LispGB $version" -or $LASTEXITCODE -ne 0) { throw 'バージョン検証に失敗しました。' }
    & ./build/lispgb.exe --headless --frames 120 --screenshot build/smoke/cgb.bmp tests/roms/acid2/cgb-acid2.gbc
    if ($LASTEXITCODE -ne 0 -or (Get-Item build/smoke/cgb.bmp).Length -ne 69174) { throw 'ヘッドレス検証に失敗しました。' }
    $help = (& ./build/lispgb.exe --help) -join "`n"
    if ($LASTEXITCODE -ne 0 -or $help -notmatch '使い方: lispgb') { throw 'ヘルプ検証に失敗しました。' }
    $ErrorActionPreference = 'Continue'
    & ./build/lispgb.exe --headless tests/roms/acid2/cgb-acid2.gbc 2> build/smoke/usage.txt
    $ErrorActionPreference = 'Stop'
    if ($LASTEXITCODE -ne 2) { throw '使用方法の終了コードが不正です。' }
    Write-Output '実行ファイルの検証合格'
} finally {
    foreach ($key in $keys) { [Environment]::SetEnvironmentVariable($key, $previous[$key], 'Process') }
    Pop-Location
}
