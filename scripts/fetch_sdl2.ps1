# 公式 x64 配布物を固定バージョンと SHA256 で検証する。
$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot '..')
try {
    New-Item -ItemType Directory -Force build/sdl2 | Out-Null
    $archive = 'build/sdl2.zip'
    $hash = '6CF9706EEFD0A4A06DC764007934D428AFAF029FABDD408A9E646048C91E18FB'
    if (!(Test-Path -LiteralPath $archive)) {
        Invoke-WebRequest -UseBasicParsing -Uri 'https://libsdl.org/release/SDL2-2.32.10-win32-x64.zip' -OutFile $archive
    }
    if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -ne $hash) {
        throw 'SDL2 の SHA256 が一致しません。build/sdl2.zip を削除して再取得してください。'
    }
    Expand-Archive -LiteralPath $archive -DestinationPath build/sdl2 -Force
    Copy-Item -LiteralPath build/sdl2/SDL2.dll -Destination build/SDL2.dll -Force
    Copy-Item -LiteralPath build/sdl2/README-SDL.txt -Destination build/README-SDL.txt -Force
    Invoke-WebRequest -UseBasicParsing -Uri 'https://raw.githubusercontent.com/libsdl-org/SDL/release-2.32.10/LICENSE.txt' -OutFile build/SDL2-LICENSE.txt
} finally { Pop-Location }
