param([int]$Frames = 3000)
$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot '..')
$keys = @('LISPGB_ACTION', 'LISPGB_BENCH_ROM', 'LISPGB_BENCH_FRAMES')
$previous = @{}
foreach ($key in $keys) { $previous[$key] = [Environment]::GetEnvironmentVariable($key, 'Process') }
try {
    $env:LISPGB_ACTION = 'bench'
    $env:LISPGB_BENCH_ROM = (Resolve-Path tests/roms/blargg/cpu_instrs/cpu_instrs.gb).Path
    $env:LISPGB_BENCH_FRAMES = "$Frames"
    & sbcl --noinform --non-interactive --load scripts/run.lisp
    if ($LASTEXITCODE -ne 0) { throw '性能測定に失敗しました。' }
} finally {
    foreach ($key in $keys) { [Environment]::SetEnvironmentVariable($key, $previous[$key], 'Process') }
    Pop-Location
}
