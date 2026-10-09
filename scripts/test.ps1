$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot '..')
$previous = $env:LISPGB_ACTION
try {
    $env:LISPGB_ACTION = 'test'
    & sbcl --noinform --non-interactive --load scripts/run.lisp
    if ($LASTEXITCODE -ne 0) { throw 'テストに失敗しました。' }
} finally { $env:LISPGB_ACTION = $previous; Pop-Location }
