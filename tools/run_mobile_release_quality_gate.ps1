[CmdletBinding()]
param([string]$GodotPath = "")

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot

& (Join-Path $PSScriptRoot "run_headless_quality_gate.ps1") -Mode full -GodotPath $GodotPath
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& (Join-Path $PSScriptRoot "run_mobile_input_runtime_gate.ps1") -GodotPath $GodotPath
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& (Join-Path $PSScriptRoot "run_packed_export_runtime_gate.ps1") -GodotPath $GodotPath
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host "MOBILE RELEASE QUALITY GATE PASS"
exit 0
