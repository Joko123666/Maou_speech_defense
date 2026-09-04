[CmdletBinding()]
param(
    [ValidateSet("preflight", "build", "deploy", "collect", "full")]
    [string]$Mode = "preflight",
    [string]$DeviceSerial = "",
    [ValidatePattern("^[A-Za-z0-9._]+$")]
    [string]$Label = "startup",
    [ValidateRange(5, 3600)]
    [int]$SampleSeconds = 120,
    [string]$GodotPath = "C:\Users\USER\Desktop\Godot_v4.7-stable_win64_console.exe",
    [string]$AndroidSdkPath = "C:\Users\USER\AppData\Local\Android\Sdk",
    [string]$OutputRoot = "C:\Users\USER\Documents\GodotGames\Output"
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$AdbPath = Join-Path $AndroidSdkPath "platform-tools\adb.exe"
$BuildToolsRoot = Join-Path $AndroidSdkPath "build-tools"
$BuildTools = Get-ChildItem -LiteralPath $BuildToolsRoot -Directory -ErrorAction SilentlyContinue |
    Sort-Object { [version]$_.Name } -Descending |
    Select-Object -First 1
if ($null -eq $BuildTools) {
    throw "Android build-tools were not found under $BuildToolsRoot"
}
$AaptPath = Join-Path $BuildTools.FullName "aapt.exe"
$ApkSignerPath = Join-Path $BuildTools.FullName "apksigner.bat"
$ApkPath = Join-Path $OutputRoot "TD_survival_v019_character_m7_debug.apk"

function Assert-File([string]$Path, [string]$Description) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "$Description was not found: $Path"
    }
}

function Invoke-Adb([string[]]$Arguments, [switch]$AllowFailure) {
    $serialArguments = @()
    if (-not [string]::IsNullOrWhiteSpace($script:SelectedSerial)) {
        $serialArguments = @("-s", $script:SelectedSerial)
    }
    $output = & $AdbPath @serialArguments @Arguments 2>&1
    if ($LASTEXITCODE -ne 0 -and -not $AllowFailure) {
        throw "adb failed ($LASTEXITCODE): adb $($Arguments -join ' ')`n$($output -join [Environment]::NewLine)"
    }
    return $output
}

function Get-ConnectedDeviceSerial {
    $deviceLines = & $AdbPath devices -l 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "adb devices failed: $($deviceLines -join [Environment]::NewLine)"
    }
    $ready = @($deviceLines | Where-Object { $_ -match "^([^\s]+)\s+device(?:\s|$)" })
    if (-not [string]::IsNullOrWhiteSpace($DeviceSerial)) {
        $match = $ready | Where-Object { $_ -match "^$([regex]::Escape($DeviceSerial))\s" } | Select-Object -First 1
        if ($null -eq $match) {
            throw "Requested Android device is not connected and authorized: $DeviceSerial"
        }
        return $DeviceSerial
    }
    if ($ready.Count -eq 0) {
        return ""
    }
    if ($ready.Count -gt 1) {
        throw "Multiple Android devices are connected. Pass -DeviceSerial explicitly."
    }
    return ([regex]::Match($ready[0], "^([^\s]+)")).Groups[1].Value
}

function Build-DebugApk {
    New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null
    Write-Host "M7 BUILD: exporting Android arm64 debug APK"
    & $GodotPath --headless --path $ProjectRoot --export-debug Android $ApkPath
    if ($LASTEXITCODE -ne 0) {
        throw "Godot Android debug export failed with exit code $LASTEXITCODE"
    }
    Assert-File $ApkPath "Exported debug APK"
    & $ApkSignerPath verify --verbose --print-certs $ApkPath
    if ($LASTEXITCODE -ne 0) {
        throw "APK signature verification failed with exit code $LASTEXITCODE"
    }
    # Godot 4.7's generated optional Vulkan feature can make legacy aapt return
    # code 1 after it has already emitted valid package metadata. Treat the
    # parsed package record as authoritative; apksigner owns archive validity.
    $badging = & $AaptPath dump badging $ApkPath 2>&1
    $packageMatch = [regex]::Match(($badging -join "`n"), "package: name='([^']+)'"
    )
    if (-not $packageMatch.Success) {
        throw "Unable to read the package name from the APK"
    }
    $script:PackageId = $packageMatch.Groups[1].Value
    $apk = Get-Item -LiteralPath $ApkPath
    Write-Host ("M7 BUILD PASS: {0} bytes ({1:N2} MiB), package {2}" -f $apk.Length, ($apk.Length / 1MB), $script:PackageId)
}

function Get-PackageIdFromApk {
    Assert-File $ApkPath "M7 debug APK"
    $badging = & $AaptPath dump badging $ApkPath 2>&1
    $packageMatch = [regex]::Match(($badging -join "`n"), "package: name='([^']+)'"
    )
    if (-not $packageMatch.Success) {
        throw "Unable to read the package name from the APK"
    }
    return $packageMatch.Groups[1].Value
}

function Save-DeviceScreenshot([string]$Destination, [string]$Suffix) {
    $remotePath = "/sdcard/td_survival_m7_$($Label)_$Suffix.png"
    Invoke-Adb @("shell", "screencap", "-p", $remotePath) | Out-Null
    Invoke-Adb @("pull", $remotePath, $Destination) | Out-Null
    Invoke-Adb @("shell", "rm", $remotePath) -AllowFailure | Out-Null
}

function Get-FirstInteger([string[]]$Lines, [string]$Pattern) {
    $match = [regex]::Match(($Lines -join "`n"), $Pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if (-not $match.Success) {
        return $null
    }
    return [long](($match.Groups[1].Value) -replace ",", "")
}

function Get-GfxFrameSummary([string[]]$Lines) {
    $headerIndex = -1
    for ($index = 0; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index] -like "Flags,IntendedVsync,*") {
            $headerIndex = $index
            break
        }
    }
    if ($headerIndex -lt 0) {
        return [ordered]@{ available = $false; frame_count = 0 }
    }
    $headers = $Lines[$headerIndex].Split(',')
    $flagsIndex = [Array]::IndexOf($headers, "Flags")
    $startIndex = [Array]::IndexOf($headers, "IntendedVsync")
    $completeIndex = [Array]::IndexOf($headers, "FrameCompleted")
    if ($flagsIndex -lt 0 -or $startIndex -lt 0 -or $completeIndex -lt 0) {
        return [ordered]@{ available = $false; frame_count = 0 }
    }
    $durations = [System.Collections.Generic.List[double]]::new()
    for ($index = $headerIndex + 1; $index -lt $Lines.Count; $index++) {
        $line = $Lines[$index].Trim()
        if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith("---")) {
            continue
        }
        $values = $line.Split(',')
        if ($values.Count -le $completeIndex) {
            continue
        }
        try {
            if ([long]$values[$flagsIndex] -ne 0) {
                continue
            }
            $duration = (([double]$values[$completeIndex]) - ([double]$values[$startIndex])) / 1000000.0
            if ($duration -gt 0.0 -and $duration -lt 5000.0) {
                $durations.Add($duration)
            }
        } catch {
            continue
        }
    }
    if ($durations.Count -eq 0) {
        return [ordered]@{ available = $false; frame_count = 0 }
    }
    $average = ($durations | Measure-Object -Average).Average
    $worst = ($durations | Measure-Object -Maximum).Maximum
    $over16 = @($durations | Where-Object { $_ -gt 16.667 }).Count
    $over33 = @($durations | Where-Object { $_ -gt 33.333 }).Count
    return [ordered]@{
        available = $true
        frame_count = $durations.Count
        average_frame_ms = [Math]::Round($average, 3)
        worst_frame_ms = [Math]::Round($worst, 3)
        frames_over_16_ms = $over16
        frames_over_33_ms = $over33
        over_33_ms_ratio = [Math]::Round($over33 / $durations.Count, 6)
    }
}

function Collect-DeviceSample {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $reportDirectory = Join-Path $OutputRoot "m7_device_reports\${timestamp}_$Label"
    New-Item -ItemType Directory -Force -Path $reportDirectory | Out-Null

    Invoke-Adb @("logcat", "-c") | Out-Null
    Invoke-Adb @("shell", "dumpsys", "gfxinfo", $script:PackageId, "reset") -AllowFailure | Out-Null
    Save-DeviceScreenshot (Join-Path $reportDirectory "screen_start.png") "start"

    $deviceProperties = @(Invoke-Adb @("shell", "getprop"))
    $batteryStart = @(Invoke-Adb @("shell", "dumpsys", "battery"))
    $memoryStart = @(Invoke-Adb @("shell", "dumpsys", "meminfo", $script:PackageId))
    $deviceProperties | Set-Content -LiteralPath (Join-Path $reportDirectory "device_properties.txt") -Encoding utf8
    $batteryStart | Set-Content -LiteralPath (Join-Path $reportDirectory "battery_start.txt") -Encoding utf8
    $memoryStart | Set-Content -LiteralPath (Join-Path $reportDirectory "memory_start.txt") -Encoding utf8

    $elapsed = 0
    while ($elapsed -lt $SampleSeconds) {
        $step = [Math]::Min(5, $SampleSeconds - $elapsed)
        Start-Sleep -Seconds $step
        $elapsed += $step
        Write-Host "M7 SAMPLE ${Label}: ${elapsed}/${SampleSeconds}s"
    }

    Save-DeviceScreenshot (Join-Path $reportDirectory "screen_end.png") "end"
    $batteryEnd = @(Invoke-Adb @("shell", "dumpsys", "battery"))
    $memoryEnd = @(Invoke-Adb @("shell", "dumpsys", "meminfo", $script:PackageId))
    $gfxInfo = @(Invoke-Adb @("shell", "dumpsys", "gfxinfo", $script:PackageId, "framestats") -AllowFailure)
    $thermalEnd = @(Invoke-Adb @("shell", "dumpsys", "thermalservice") -AllowFailure)
    $logcat = @(Invoke-Adb @("logcat", "-d", "-v", "threadtime"))
    $batteryEnd | Set-Content -LiteralPath (Join-Path $reportDirectory "battery_end.txt") -Encoding utf8
    $memoryEnd | Set-Content -LiteralPath (Join-Path $reportDirectory "memory_end.txt") -Encoding utf8
    $gfxInfo | Set-Content -LiteralPath (Join-Path $reportDirectory "gfxinfo_framestats.txt") -Encoding utf8
    $thermalEnd | Set-Content -LiteralPath (Join-Path $reportDirectory "thermal_end.txt") -Encoding utf8
    $logcat | Set-Content -LiteralPath (Join-Path $reportDirectory "logcat.txt") -Encoding utf8

    $summary = [ordered]@{
        schema_version = 1
        label = $Label
        sample_seconds = $SampleSeconds
        collected_at = (Get-Date).ToString("o")
        device_serial = $script:SelectedSerial
        package_id = $script:PackageId
        apk_path = $ApkPath
        device_metrics = [ordered]@{
            gfxinfo = Get-GfxFrameSummary $gfxInfo
            total_pss_start_kb = Get-FirstInteger $memoryStart "TOTAL PSS:\s*([0-9,]+)"
            total_pss_end_kb = Get-FirstInteger $memoryEnd "TOTAL PSS:\s*([0-9,]+)"
            battery_level_start = Get-FirstInteger $batteryStart "level:\s*([0-9]+)"
            battery_level_end = Get-FirstInteger $batteryEnd "level:\s*([0-9]+)"
        }
        required_manual_assertions = @(
            "ally faces right and official intrusion art faces left",
            "faction and role remain identifiable at 48, 64, and 96 pixels",
            "no texture pop-in or clipped character art",
            "reduced-motion mode preserves character and faction identification"
        )
    }
    $summary | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $reportDirectory "summary.json") -Encoding utf8
    Write-Host "M7 DEVICE SAMPLE PASS: $reportDirectory"
}

Assert-File $GodotPath "Godot executable"
Assert-File $AdbPath "Android Debug Bridge"
Assert-File $AaptPath "Android Asset Packaging Tool"
Assert-File $ApkSignerPath "Android APK signer"

$script:SelectedSerial = Get-ConnectedDeviceSerial
$script:PackageId = ""
Write-Host "M7 PREFLIGHT: Godot 4.7, Android build-tools $($BuildTools.Name), connected device '$($script:SelectedSerial)'"

if ($Mode -in @("build", "full")) {
    Build-DebugApk
}

if ($Mode -in @("deploy", "collect")) {
    $script:PackageId = Get-PackageIdFromApk
}

if ($Mode -in @("deploy", "collect", "full") -and [string]::IsNullOrWhiteSpace($script:SelectedSerial)) {
    Write-Error "M7 DEVICE BLOCKED: no authorized Android device is connected"
    exit 2
}

if ($Mode -in @("deploy", "full")) {
    Invoke-Adb @("install", "-r", $ApkPath) | Write-Host
    Invoke-Adb @("shell", "monkey", "-p", $script:PackageId, "-c", "android.intent.category.LAUNCHER", "1") | Write-Host
    Start-Sleep -Seconds 5
    Write-Host "M7 DEPLOY PASS: $script:PackageId on $script:SelectedSerial"
}

if ($Mode -in @("collect", "full")) {
    Collect-DeviceSample
}

if ($Mode -eq "preflight" -and [string]::IsNullOrWhiteSpace($script:SelectedSerial)) {
    Write-Warning "M7 DEVICE BLOCKED: build tools are ready, but no authorized Android device is connected"
    exit 2
}

Write-Host "M7 $($Mode.ToUpperInvariant()) PASS"
exit 0
