[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ApkPath,
    [string]$AndroidSdkRoot = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$Apk = (Resolve-Path -LiteralPath $ApkPath).Path
if ([string]::IsNullOrWhiteSpace($AndroidSdkRoot)) {
    $AndroidSdkRoot = Join-Path $env:LOCALAPPDATA "Android\Sdk"
}
$BuildTools = Get-ChildItem -LiteralPath (Join-Path $AndroidSdkRoot "build-tools") -Directory | Sort-Object Name -Descending | Select-Object -First 1
if ($null -eq $BuildTools) { throw "Android build-tools were not found under $AndroidSdkRoot" }
$Badging = (& (Join-Path $BuildTools.FullName "aapt2.exe") dump badging $Apk | Select-Object -First 1) -join ""
if ($Badging -notmatch "package: name='([^']+)' versionCode='([^']+)' versionName='([^']+)'") {
    throw "APK package metadata could not be parsed"
}
$PackageId = $Matches[1]
$VersionCode = $Matches[2]
$VersionName = $Matches[3]

Add-Type -AssemblyName System.IO.Compression.FileSystem
$Zip = [IO.Compression.ZipFile]::OpenRead($Apk)
try {
    $Entry = $Zip.GetEntry("assets/build_info.json")
    if ($null -eq $Entry) { throw "APK is missing assets/build_info.json" }
    $Reader = [IO.StreamReader]::new($Entry.Open())
    try { $BuildInfo = $Reader.ReadToEnd() | ConvertFrom-Json } finally { $Reader.Dispose() }
} finally {
    $Zip.Dispose()
}

$Item = Get-Item -LiteralPath $Apk
$Manifest = [ordered]@{
    schema_version = 1
    generated_at = (Get-Date).ToString("o")
    artifact = $Item.Name
    bytes = $Item.Length
    sha256 = (Get-FileHash -LiteralPath $Apk -Algorithm SHA256).Hash
    package_id = $PackageId
    version_code = $VersionCode
    version_name = $VersionName
    build = $BuildInfo
}
$ManifestPath = "$Apk.manifest.json"
$Manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $ManifestPath -Encoding utf8
Write-Host "ANDROID ARTIFACT MANIFEST: $ManifestPath"
Write-Host "ANDROID ARTIFACT SHA256: $($Manifest.sha256)"
