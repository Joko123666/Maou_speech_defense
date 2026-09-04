[CmdletBinding()]
param([string]$GodotPath = "")

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($GodotPath)) {
    $GodotPath = Join-Path ([Environment]::GetFolderPath("Desktop")) "Godot_v4.7-stable_win64_console.exe"
}
$Godot = (Resolve-Path -LiteralPath $GodotPath).Path
& (Join-Path $PSScriptRoot "run_mobile_release_quality_gate.ps1") -GodotPath $Godot
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $Godot --headless --path $ProjectRoot --export-debug Android
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$ApkPath = Join-Path (Split-Path -Parent $ProjectRoot) "Output\TD_survival_0.04.apk"
& (Join-Path $PSScriptRoot "write_android_artifact_manifest.ps1") -ApkPath $ApkPath
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host "ANDROID DEBUG BUILD PASS: $ApkPath"
exit 0
