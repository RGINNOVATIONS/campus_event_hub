# CampusPulse verification gate (Windows) — run this on a machine with
# the Flutter SDK installed. It was NOT run by the assistant that built
# this repo (no SDK in that sandbox — see TASKS.md section 0). Run it
# yourself before treating the app as verified.
#
# Usage: powershell -ExecutionPolicy Bypass -File .\scripts\verify.ps1

$ErrorActionPreference = "Continue"
$pass = 0
$fail = 0

function Invoke-Step {
    param([string]$Name, [string]$Command, [string[]]$Arguments)
    Write-Host ""
    Write-Host "=== $Name ===" -ForegroundColor Cyan
    & $Command @Arguments
    if ($LASTEXITCODE -eq 0) {
        Write-Host "--- PASS: $Name ---" -ForegroundColor Green
        $script:pass++
    } else {
        Write-Host "--- FAIL: $Name (exit $LASTEXITCODE) ---" -ForegroundColor Red
        $script:fail++
    }
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: flutter is not on PATH. Install the Flutter SDK first (flutter.dev)." -ForegroundColor Red
    exit 127
}

flutter --version

Invoke-Step "flutter pub get" "flutter" @("pub", "get")
Invoke-Step "dart format (check only)" "dart" @("format", "--output=none", "--set-exit-if-changed", ".")
Invoke-Step "flutter analyze" "flutter" @("analyze")
Invoke-Step "flutter test" "flutter" @("test")
Invoke-Step "flutter build apk --debug" "flutter" @("build", "apk", "--debug")
Invoke-Step "flutter build web" "flutter" @("build", "web")

Write-Host ""
Write-Host "================================"
Write-Host " Verification summary: $pass passed, $fail failed"
Write-Host "================================"

if ($fail -gt 0) { exit 1 }
