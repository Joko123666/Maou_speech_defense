[CmdletBinding()]
param(
    [string]$GodotPath = "",
    [string]$OutputRoot = "",
    [ValidateRange(1, 600)]
    [int]$TimeoutSeconds = 180
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ProbePath = Join-Path $PSScriptRoot "packed_export_runtime_probe.gd"
$ExpectedMarker = "PACKED EXPORT RUNTIME PASS"
$ForbiddenPattern = '(?im)^\s*(?:SCRIPT ERROR|ERROR)\s*:'

function Resolve-GodotExecutable([string]$RequestedPath) {
    if (-not [string]::IsNullOrWhiteSpace($RequestedPath)) {
        return (Resolve-Path -LiteralPath $RequestedPath).Path
    }
    $preferred = Join-Path ([Environment]::GetFolderPath("Desktop")) "Godot_v4.7-stable_win64_console.exe"
    if (Test-Path -LiteralPath $preferred -PathType Leaf) {
        return (Resolve-Path -LiteralPath $preferred).Path
    }
    foreach ($name in @("godot4", "godot")) {
        $command = Get-Command $name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($null -ne $command) { return $command.Source }
    }
    throw "Godot 4.7 executable was not found. Pass -GodotPath."
}

function Invoke-CheckedProcess([string]$Executable, [string[]]$Arguments, [string]$WorkingDirectory, [int]$LimitSeconds, [bool]$EchoOutput = $true) {
    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $Executable
    $startInfo.WorkingDirectory = $WorkingDirectory
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.CreateNoWindow = $true
    foreach ($argument in $Arguments) { $startInfo.ArgumentList.Add($argument) }
    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    if (-not $process.Start()) { throw "process did not start" }
    $stdout = $process.StandardOutput.ReadToEndAsync()
    $stderr = $process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit($LimitSeconds * 1000)) {
        $process.Kill($true)
        throw "process exceeded $LimitSeconds seconds"
    }
    $process.WaitForExit()
    $text = ($stdout.GetAwaiter().GetResult() + [Environment]::NewLine + $stderr.GetAwaiter().GetResult()).Trim()
    $exitCode = $process.ExitCode
    $process.Dispose()
    if ($EchoOutput -and -not [string]::IsNullOrWhiteSpace($text)) { Write-Host $text }
    return [pscustomobject]@{ ExitCode = $exitCode; Output = $text }
}

try {
    $Godot = Resolve-GodotExecutable $GodotPath
    if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
        $OutputRoot = Join-Path ([System.IO.Path]::GetTempPath()) "td-survival-packed-export-gate"
    }
    $RunDirectory = Join-Path $OutputRoot ("{0}_{1}" -f (Get-Date -Format "yyyyMMdd_HHmmss_fff"), $PID)
    $EmptyWorkingDirectory = Join-Path $RunDirectory "empty-working-directory"
    New-Item -ItemType Directory -Force -Path $EmptyWorkingDirectory | Out-Null
    $PackPath = Join-Path $RunDirectory "runtime-probe.pck"

    Write-Host "PACKED EXPORT GATE: exporting Android resource pack"
    $export = Invoke-CheckedProcess $Godot @("--headless", "--path", $ProjectRoot, "--export-pack", "Android", $PackPath) $ProjectRoot $TimeoutSeconds $false
    if ($export.ExitCode -ne 0 -or $export.Output -match $ForbiddenPattern -or -not (Test-Path -LiteralPath $PackPath -PathType Leaf)) {
        throw "resource-pack export failed"
    }

    Write-Host "PACKED EXPORT GATE: running from an unrelated empty working directory"
    $runtime = Invoke-CheckedProcess $Godot @("--headless", "--audio-driver", "Dummy", "--main-pack", $PackPath, "--script", $ProbePath) $EmptyWorkingDirectory $TimeoutSeconds
    if ($runtime.ExitCode -ne 0 -or $runtime.Output -match $ForbiddenPattern -or -not $runtime.Output.Contains($ExpectedMarker)) {
        throw "packed runtime probe failed"
    }
    Write-Host "PACKED EXPORT GATE PASS: $PackPath"
    exit 0
} catch {
    [Console]::Error.WriteLine("PACKED EXPORT GATE FAIL: $($_.Exception.Message)")
    exit 1
}
