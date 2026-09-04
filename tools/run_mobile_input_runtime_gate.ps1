[CmdletBinding()]
param([string]$GodotPath = "")

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($GodotPath)) {
    $GodotPath = Join-Path ([Environment]::GetFolderPath("Desktop")) "Godot_v4.7-stable_win64_console.exe"
}
$Godot = (Resolve-Path -LiteralPath $GodotPath).Path
$output = & $Godot --path $ProjectRoot --audio-driver Dummy --rendering-method gl_compatibility --script (Join-Path $PSScriptRoot "mobile_input_runtime_probe.gd") 2>&1 | Out-String
Write-Host $output.Trim()
if ($LASTEXITCODE -ne 0 -or -not $output.Contains("MOBILE INPUT RUNTIME PASS") -or $output -match '(?im)^\s*(?:SCRIPT ERROR|ERROR)\s*:') {
    [Console]::Error.WriteLine("MOBILE INPUT RUNTIME GATE FAIL")
    exit 1
}
Write-Host "MOBILE INPUT RUNTIME GATE PASS"
exit 0
