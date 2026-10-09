$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot '..')
$previousPath = $env:PATH
$previousHome = $env:SBCL_HOME
$previousAppdata = $env:APPDATA
try {
    $version = [regex]::Match((Get-Content lispgb.asd -Raw), ':version\s+"([^"]+)"').Groups[1].Value
    Expand-Archive -LiteralPath "dist/LispGB-$version-windows-x64.zip" -DestinationPath build/package-check -Force
    $exe = (Resolve-Path build/package-check/lispgb.exe).Path
    $rom = (Resolve-Path tests/roms/acid2/cgb-acid2.gbc).Path
    $bmp = Join-Path (Resolve-Path build/package-check).Path 'frame.bmp'
    $env:APPDATA = (Resolve-Path build/package-check).Path
    $env:PATH = "$env:SystemRoot/system32"
    $env:SBCL_HOME = $null
    if ((& $exe --version) -ne "LispGB $version" -or $LASTEXITCODE -ne 0) { throw '展開後の実行に失敗しました。' }
    & $exe --headless --frames 120 --screenshot $bmp $rom
    if ($LASTEXITCODE -ne 0 -or (Get-Item -LiteralPath $bmp).Length -ne 69174) { throw '展開後の描画に失敗しました。' }
    $bytes = [IO.File]::ReadAllBytes($exe)
    $offset = [BitConverter]::ToInt32($bytes, 60)
    if ([BitConverter]::ToUInt16($bytes, $offset + 4) -ne 0x8664) { throw 'x64 の実行ファイルではありません。' }
    Write-Output 'Windows x64 ZIP 展開後の検証合格'
} finally {
    $env:PATH = $previousPath
    $env:SBCL_HOME = $previousHome
    $env:APPDATA = $previousAppdata
    Pop-Location
}
