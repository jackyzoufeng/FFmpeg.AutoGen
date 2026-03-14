# Local publish script for FFmpeg.AutoGen
# This script is for maintainer use only
# For automated publishing, use GitHub Actions workflow

$ErrorActionPreference = "Stop"

Write-Host "FFmpeg.AutoGen - Local Publish Script" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

# Get version from Directory.Build.props
$version = (Select-Xml -Path Directory.Build.props -XPath '/Project/PropertyGroup/Version').Node.'#text'

# NuGet normalizes version by removing trailing zero segments
# For example: X.Y.Z.0 becomes X.Y.Z, but X.Y.Z.W (where W != 0) stays as is
$versionParts = $version.Split('.')
$packageVersion = $version
if ($versionParts.Length -eq 4 -and $versionParts[3] -eq '0') {
    $packageVersion = "$($versionParts[0]).$($versionParts[1]).$($versionParts[2])"
    Write-Host "`nNote: Version $version will be normalized to $packageVersion in package names" -ForegroundColor Yellow
}

Write-Host "`nVersion: $version" -ForegroundColor Yellow
Write-Host "Package Version: $packageVersion" -ForegroundColor Yellow

# Check if we're on the correct branch
$currentBranch = git rev-parse --abbrev-ref HEAD
Write-Host "Current branch: $currentBranch" -ForegroundColor Yellow

if ($currentBranch -ne "main") {
    $continue = Read-Host "Warning: You are not on 'main' branch. Continue? (y/n)"
    if ($continue -ne 'y') {
        Write-Host "Aborted." -ForegroundColor Red
        exit 1
    }
}

# Check for uncommitted changes
$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Host "`nWarning: You have uncommitted changes:" -ForegroundColor Red
    git status --short
    $continue = Read-Host "Continue anyway? (y/n)"
    if ($continue -ne 'y') {
        Write-Host "Aborted. Please commit your changes first." -ForegroundColor Red
        exit 1
    }
}

# Check if tag already exists
$tagExists = git tag -l "v$version"
if ($tagExists) {
    Write-Host "`nWarning: Tag v$version already exists!" -ForegroundColor Red
    $continue = Read-Host "Continue? This may cause issues. (y/n)"
    if ($continue -ne 'y') {
        Write-Host "Aborted." -ForegroundColor Red
        exit 1
    }
}

Write-Host "`nBuilding..." -ForegroundColor Green
dotnet build --configuration Release
if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "`nRunning tests..." -ForegroundColor Green
dotnet test --configuration Release --no-build
if ($LASTEXITCODE -ne 0) {
    Write-Host "Tests failed!" -ForegroundColor Red
    exit 1
}

Write-Host "`nCreating packages..." -ForegroundColor Green
dotnet pack --configuration Release --no-build
if ($LASTEXITCODE -ne 0) {
    Write-Host "Pack failed!" -ForegroundColor Red
    exit 1
}

Write-Host "`nPackages to be published:" -ForegroundColor Cyan
$packages = @(
    ".\FFmpeg.AutoGen\bin\Release\FFmpeg.AutoGen.$packageVersion.nupkg",
    ".\FFmpeg.AutoGen.Abstractions\bin\Release\FFmpeg.AutoGen.Abstractions.$packageVersion.nupkg",
    ".\FFmpeg.AutoGen.Bindings.DynamicallyLinked\bin\Release\FFmpeg.AutoGen.Bindings.DynamicallyLinked.$packageVersion.nupkg",
    ".\FFmpeg.AutoGen.Bindings.DynamicallyLoaded\bin\Release\FFmpeg.AutoGen.Bindings.DynamicallyLoaded.$packageVersion.nupkg",
    ".\FFmpeg.AutoGen.Bindings.StaticallyLinked\bin\Release\FFmpeg.AutoGen.Bindings.StaticallyLinked.$packageVersion.nupkg"
)

foreach ($pkg in $packages) {
    if (Test-Path $pkg) {
        Write-Host "  ✓ $pkg" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $pkg NOT FOUND" -ForegroundColor Red
        exit 1
    }
}

$confirmation = Read-Host "`nAre you sure you want to push nuget packages v$version to nuget.org? (y/n)"
if ($confirmation -ne 'y') {
    Write-Host "Aborted." -ForegroundColor Yellow
    exit 0
}

# Check for API key
$apiKey = $Env:NUGET_API_KEY
if ([string]::IsNullOrWhiteSpace($apiKey)) {
    Write-Host "`nNUGET_API_KEY environment variable is not set!" -ForegroundColor Red
    Write-Host "Please set it first: `$Env:NUGET_API_KEY = 'your-key'" -ForegroundColor Yellow
    exit 1
}

Write-Host "`nPublishing to NuGet.org..." -ForegroundColor Green
foreach ($pkg in $packages) {
    Write-Host "Publishing $(Split-Path $pkg -Leaf)..." -ForegroundColor Cyan
    dotnet nuget push $pkg --source https://api.nuget.org/v3/index.json --api-key $apiKey --skip-duplicate
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to publish $pkg" -ForegroundColor Red
        exit 1
    }
}

Write-Host "`nCreating git tag v$version..." -ForegroundColor Green
git tag v$version
git push origin v$version

Write-Host "`n✓ Successfully published version $version!" -ForegroundColor Green
Write-Host "Packages are now available on NuGet.org" -ForegroundColor Green