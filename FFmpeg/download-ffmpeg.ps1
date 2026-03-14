<#
.SYNOPSIS
    Downloads FFmpeg shared libraries for development and code generation.

.DESCRIPTION
    Downloads the latest FFmpeg release-full-shared build from gyan.dev
    and extracts the required DLLs to FFmpeg/bin/x64/.

.EXAMPLE
    .\download-ffmpeg.ps1
#>

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BinDir = Join-Path $ScriptDir "bin\x64"
$TempDir = Join-Path $ScriptDir "temp"
$Url = "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-full-shared.7z"

# Check if DLLs already exist
if (Test-Path (Join-Path $BinDir "avcodec-*.dll")) {
    Write-Host "FFmpeg DLLs already exist in $BinDir"
    Write-Host "Delete the bin directory to re-download."
    exit 0
}

Write-Host "Downloading FFmpeg from gyan.dev..."

# Create directories
New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
New-Item -ItemType Directory -Force -Path $TempDir | Out-Null

$ArchivePath = Join-Path $TempDir "ffmpeg-release-full-shared.7z"

# Download
try {
    Invoke-WebRequest -Uri $Url -OutFile $ArchivePath -UseBasicParsing
} catch {
    Write-Error "Failed to download FFmpeg. Check your internet connection. URL: $Url"
    exit 1
}

Write-Host "Extracting DLLs..."

# Extract using 7z (try common locations)
$7zPaths = @(
    "7z",
    "C:\Program Files\7-Zip\7z.exe",
    "C:\Program Files (x86)\7-Zip\7z.exe"
)

$7zExe = $null
foreach ($path in $7zPaths) {
    if (Get-Command $path -ErrorAction SilentlyContinue) {
        $7zExe = $path
        break
    }
}

if (-not $7zExe) {
    Write-Error "7-Zip not found. Install it from https://www.7-zip.org/ or via: winget install 7zip.7zip"
    Remove-Item -Recurse -Force $TempDir
    exit 1
}

# Extract
& $7zExe x $ArchivePath -o"$TempDir" -y | Out-Null

# Find the extracted directory (name includes version)
$ExtractedDir = Get-ChildItem -Path $TempDir -Directory | Where-Object { $_.Name -like "ffmpeg-*" } | Select-Object -First 1
if (-not $ExtractedDir) {
    Write-Error "Could not find extracted FFmpeg directory in $TempDir"
    Remove-Item -Recurse -Force $TempDir
    exit 1
}

$DllSource = Join-Path $ExtractedDir.FullName "bin"
if (-not (Test-Path $DllSource)) {
    Write-Error "Expected bin directory not found: $DllSource"
    Remove-Item -Recurse -Force $TempDir
    exit 1
}

# Copy DLLs
Copy-Item "$DllSource\*.dll" -Destination $BinDir -Force

# Cleanup
Remove-Item -Recurse -Force $TempDir

$DllCount = (Get-ChildItem "$BinDir\*.dll").Count
Write-Host "Done! $DllCount DLLs extracted to $BinDir"
