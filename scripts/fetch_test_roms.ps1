# コミットと ROM 一覧は既存のスクリプトを共有する。
$ErrorActionPreference = 'Stop'
$git = (Get-Command git -ErrorAction Stop).Source
$bash = Join-Path (Split-Path (Split-Path $git)) 'bin/bash.exe'
if (!(Test-Path -LiteralPath $bash)) { throw 'Git for Windows の Bash が見つかりません。' }
Push-Location (Join-Path $PSScriptRoot '..')
try {
    & $bash scripts/fetch_test_roms.sh
    if ($LASTEXITCODE -ne 0) { throw 'テスト ROM の取得に失敗しました。' }
} finally { Pop-Location }
