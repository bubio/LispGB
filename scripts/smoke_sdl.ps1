$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot '..')
$previousAction = $env:LISPGB_ACTION
$previousRom = $env:LISPGB_SDL_ROM
$previousPath = $env:PATH
try {
    New-Item -ItemType Directory -Force build/smoke | Out-Null
    Copy-Item -LiteralPath tests/roms/acid2/cgb-acid2.gbc -Destination build/smoke/gui.gbc -Force
    $env:LISPGB_ACTION = 'sdl'
    $env:LISPGB_SDL_ROM = (Resolve-Path build/smoke/gui.gbc).Path
    $env:PATH = (Resolve-Path build).Path + ';' + $env:PATH
    & sbcl --noinform --non-interactive --load scripts/run.lisp
    if ($LASTEXITCODE -ne 0) { throw 'SDL 動作検証に失敗しました。' }
} finally {
    $env:LISPGB_ACTION = $previousAction
    $env:LISPGB_SDL_ROM = $previousRom
    $env:PATH = $previousPath
    Pop-Location
}
