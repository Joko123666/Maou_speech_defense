[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ApkPath,
    [string]$AndroidSdkPath = "C:\Users\USER\AppData\Local\Android\Sdk",
    [string]$ReportPath = ""
)

$ErrorActionPreference = "Stop"

function Assert-Condition([bool]$Condition, [string]$Message) {
    if (-not $Condition) {
        throw $Message
    }
}

function Read-ZipEntryText($Entry) {
    $stream = $Entry.Open()
    try {
        $reader = [System.IO.StreamReader]::new($stream)
        try {
            return $reader.ReadToEnd()
        } finally {
            $reader.Dispose()
        }
    } finally {
        $stream.Dispose()
    }
}

$resolvedApk = [System.IO.Path]::GetFullPath($ApkPath)
Assert-Condition (Test-Path -LiteralPath $resolvedApk -PathType Leaf) "APK was not found: $resolvedApk"
if ([string]::IsNullOrWhiteSpace($ReportPath)) {
    $ReportPath = [System.IO.Path]::ChangeExtension($resolvedApk, ".audit.json")
}
$resolvedReport = [System.IO.Path]::GetFullPath($ReportPath)

$buildTools = Get-ChildItem -LiteralPath (Join-Path $AndroidSdkPath "build-tools") -Directory |
    Sort-Object { [version]$_.Name } -Descending |
    Select-Object -First 1
Assert-Condition ($null -ne $buildTools) "Android build-tools were not found under $AndroidSdkPath"
$apkSigner = Join-Path $buildTools.FullName "apksigner.bat"
$zipAlign = Join-Path $buildTools.FullName "zipalign.exe"
$aapt = Join-Path $buildTools.FullName "aapt.exe"
foreach ($tool in @($apkSigner, $zipAlign, $aapt)) {
    Assert-Condition (Test-Path -LiteralPath $tool -PathType Leaf) "Android audit tool was not found: $tool"
}

$signatureOutput = @(& $apkSigner verify --verbose --print-certs $resolvedApk 2>&1)
Assert-Condition ($LASTEXITCODE -eq 0) "apksigner verification failed"
$signatureText = $signatureOutput -join "`n"
Assert-Condition ($signatureText -match "Verified using v2 scheme .*: true") "APK Signature Scheme v2 was not verified"
Assert-Condition ($signatureText -match "Verified using v3 scheme .*: true") "APK Signature Scheme v3 was not verified"

$alignmentOutput = @(& $zipAlign -c -P 16 4 $resolvedApk 2>&1)
Assert-Condition ($LASTEXITCODE -eq 0) "zipalign verification failed: $($alignmentOutput -join [Environment]::NewLine)"

$badging = @(& $aapt dump badging $resolvedApk 2>&1)
$badgingText = $badging -join "`n"
$packageMatch = [regex]::Match($badgingText, "package: name='([^']+)'.*versionName='([^']+)'", [System.Text.RegularExpressions.RegexOptions]::Singleline)
$sdkMatch = [regex]::Match($badgingText, "sdkVersion:'([^']+)'")
$targetSdkMatch = [regex]::Match($badgingText, "targetSdkVersion:'([^']+)'")
Assert-Condition $packageMatch.Success "Unable to parse package name and versionName from APK badging"
Assert-Condition ($sdkMatch.Success -and $targetSdkMatch.Success) "Unable to parse min/target SDK from APK badging"

$permissionOutput = @(& $aapt dump permissions $resolvedApk 2>&1)
$permissionCount = @($permissionOutput | Where-Object { $_ -match '^uses-permission' }).Count

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::OpenRead($resolvedApk)
try {
    $entryByName = @{}
    foreach ($entry in $archive.Entries) {
        $entryByName[$entry.FullName] = $entry
    }

    $expectedAssets = [ordered]@{
        candidate_intrusion_sd = @("partason", "jiane", "kasuha", "irelai", "judaginda")
        retainer_intrusion_sd = @("kanda", "given", "jeomujeom", "jugdied", "death_vanguard")
        guard_intrusion_sd = @("partason_faction", "jiane_faction", "kasuha_faction", "irelai_faction", "judaginda_faction")
    }
    $importEntries = [System.Collections.Generic.List[string]]::new()
    $ctexEntries = [System.Collections.Generic.List[string]]::new()
    foreach ($category in $expectedAssets.Keys) {
        foreach ($contentId in $expectedAssets[$category]) {
            $importName = "assets/assets/graphics/$category/$contentId.png.import"
            Assert-Condition $entryByName.ContainsKey($importName) "Missing official intrusion import entry: $importName"
            $importEntries.Add($importName)
            $importText = Read-ZipEntryText $entryByName[$importName]
            $pathMatch = [regex]::Match($importText, 'path="res://([^\"]+\.ctex)"')
            Assert-Condition $pathMatch.Success "Unable to resolve CTEX from $importName"
            $ctexName = "assets/$($pathMatch.Groups[1].Value)"
            Assert-Condition $entryByName.ContainsKey($ctexName) "Missing CTEX referenced by $importName`: $ctexName"
            $ctexEntries.Add($ctexName)
        }
    }

    $excludedPatterns = [ordered]@{
        style_refresh_staging = '^assets/assets/graphics/style_refresh_v019/'
        tests = '^assets/tests/'
        tools = '^assets/tools/'
        reference = '^assets/reference/'
        data_art = '^assets/data/art/'
    }
    $excludedCounts = [ordered]@{}
    foreach ($label in $excludedPatterns.Keys) {
        $excludedCounts[$label] = @($archive.Entries | Where-Object { $_.FullName -match $excludedPatterns[$label] }).Count
        Assert-Condition ($excludedCounts[$label] -eq 0) "APK contains excluded $label entries"
    }

    $arm64Godot = @($archive.Entries | Where-Object { $_.FullName -eq "lib/arm64-v8a/libgodot_android.so" }).Count
    $otherAbi = @($archive.Entries | Where-Object { $_.FullName -match '^lib/(armeabi-v7a|x86|x86_64)/' }).Count
    Assert-Condition ($arm64Godot -eq 1 -and $otherAbi -eq 0) "APK must contain one arm64 Godot library and no other ABI libraries"

    Assert-Condition $entryByName.ContainsKey("assets/build_info.json") "APK is missing build_info.json"
    $buildInfo = Read-ZipEntryText $entryByName["assets/build_info.json"] | ConvertFrom-Json
    Assert-Condition ($buildInfo.version -eq "0.03" -and $buildInfo.target -eq "android" -and $buildInfo.mode -eq "debug") "APK build_info.json does not identify the expected Android debug build"

    $apk = Get-Item -LiteralPath $resolvedApk
    $report = [ordered]@{
        schema_version = 1
        status = "pass"
        audited_at = (Get-Date).ToString("o")
        apk_path = $resolvedApk
        apk_bytes = $apk.Length
        apk_sha256 = (Get-FileHash -LiteralPath $resolvedApk -Algorithm SHA256).Hash.ToLowerInvariant()
        package_id = $packageMatch.Groups[1].Value
        version_name = $packageMatch.Groups[2].Value
        min_sdk = [int]$sdkMatch.Groups[1].Value
        target_sdk = [int]$targetSdkMatch.Groups[1].Value
        build_id = $buildInfo.build_id
        signature = "v2_v3_verified"
        zipalign = "verified_4_byte_and_16_byte_shared_library_alignment"
        permission_count = $permissionCount
        abi = "arm64-v8a"
        official_intrusion = [ordered]@{
            expected_assets = 15
            import_entries = $importEntries.Count
            ctex_entries = @($ctexEntries | Select-Object -Unique).Count
            categories = $expectedAssets
        }
        excluded_entry_counts = $excludedCounts
    }
    Assert-Condition ($report.official_intrusion.import_entries -eq 15 -and $report.official_intrusion.ctex_entries -eq 15) "Official intrusion package entries must resolve to 15 unique imports and CTEX files"
    $reportDirectory = Split-Path -Parent $resolvedReport
    if (-not [string]::IsNullOrWhiteSpace($reportDirectory)) {
        New-Item -ItemType Directory -Force -Path $reportDirectory | Out-Null
    }
    $report | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath $resolvedReport -Encoding utf8
    Write-Host "OFFICIAL INTRUSION APK AUDIT PASS: 15 imports / 15 CTEX / arm64 / v2+v3 / zipalign"
    Write-Host "OFFICIAL INTRUSION APK REPORT: $resolvedReport"
} finally {
    $archive.Dispose()
}
