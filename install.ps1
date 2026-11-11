# Windows entry point. Claude Code on Windows already needs Git for Windows, so reuse its bash.
# Usage:  powershell -ExecutionPolicy Bypass -File .\install.ps1 [install.sh options]
$ErrorActionPreference = 'Stop'
$bash = (Get-Command bash.exe -ErrorAction SilentlyContinue).Source
if (-not $bash) {
  $candidate = Join-Path $env:ProgramFiles 'Git\bin\bash.exe'
  if (Test-Path $candidate) { $bash = $candidate }
}
if (-not $bash) { throw 'Git Bash not found. Install Git for Windows (https://git-scm.com), then re-run.' }
& $bash (Join-Path $PSScriptRoot 'install.sh') @args
exit $LASTEXITCODE
