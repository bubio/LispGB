$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot '..')
try {
    $version = [regex]::Match((Get-Content lispgb.asd -Raw), ':version\s+"([^"]+)"').Groups[1].Value
    $actual = & ./build/lispgb.exe --version
    if ($LASTEXITCODE -ne 0 -or $actual -ne "LispGB $version") { throw '実行ファイルのバージョンが不正です。' }
    $files = @('build/lispgb.exe', 'build/SDL2.dll', 'build/SDL2-LICENSE.txt', 'build/README-SDL.txt', 'README.md', 'README.ja.md', 'LICENSE')
    foreach ($file in $files) { if (!(Test-Path -LiteralPath $file)) { throw "配布物が不足しています: $file" } }
    New-Item -ItemType Directory -Force dist | Out-Null
    $zip = "dist/LispGB-$version-windows-x64.zip"
    Compress-Archive -LiteralPath $files -DestinationPath $zip -Force
    Write-Output "配布物: $zip"
} finally { Pop-Location }
