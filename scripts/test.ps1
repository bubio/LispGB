$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot '..')
$previous = $env:LISPGB_ACTION
try {
    $env:LISPGB_ACTION = 'test'
    & sbcl --noinform --non-interactive --load scripts/run.lisp
    if ($LASTEXITCODE -ne 0) { throw 'テストに失敗しました。' }
    # CI の必須モードでは、実際の Git Bash でも取得と CRLF の回帰を検証する。
    if ($env:LISPGB_REQUIRE_TEST_ROMS -eq '1') {
        $testGit = (Get-Command git -ErrorAction Stop).Source
        $testBash = Join-Path (Split-Path (Split-Path $testGit)) 'bin/bash.exe'
        if (!(Test-Path -LiteralPath $testBash)) { throw '取得の回帰検証用 Git Bash が見つかりません。' }
        & $testBash tests/scripts/fetch-test.sh
        if ($LASTEXITCODE -ne 0) { throw 'ROM 取得の回帰検証に失敗しました。' }
    }
} finally { $env:LISPGB_ACTION = $previous; Pop-Location }
