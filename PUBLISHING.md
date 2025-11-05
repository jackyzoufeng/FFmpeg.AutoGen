# Publishing Guide for FFmpeg.AutoGen

This guide is for maintainers only.

## Prerequisites

- Maintainer access to the repository
- NuGet API key with push permissions
- All tests passing on CI

## Publishing Process

### Option 1: Automated (Recommended)

1. **Update version** in `Directory.Build.props`
   ```xml
   <Version>8.0.1.0</Version>
   ```

2. **Commit and push changes**
   ```bash
   git add Directory.Build.props
   git commit -m "Bump version to 8.0.1.0"
   git push origin 8.0
   ```

3. **Create a GitHub Release**
   - Go to https://github.com/Ruslan-B/FFmpeg.AutoGen/releases/new
   - Create a new tag: `v8.0.1.0`
   - Target: `8.0` branch
   - Title: `FFmpeg.AutoGen 8.0.1.0`
   - Add release notes
   - Click "Publish release"

4. **Automated workflow runs**
   - GitHub Actions will automatically build, test, and publish to NuGet.org
   - Monitor at: https://github.com/Ruslan-B/FFmpeg.AutoGen/actions

### Option 2: Manual (Local)

1. **Update version** in `Directory.Build.props`

2. **Set NuGet API key**
   ```powershell
   $Env:NUGET_API_KEY = "your-api-key-here"
   ```

3. **Run publish script**
   ```powershell
   .\publish.ps1
   ```

4. **Verify on NuGet.org**
   - Check https://www.nuget.org/packages/FFmpeg.AutoGen/

## Encrypted API Key

If you're using an encrypted `.enc` file for your NuGet API key:

```powershell
# Decrypt (you need the decryption method)
$apiKey = Decrypt-ApiKey "path/to/key.enc"
$Env:NUGET_API_KEY = $apiKey
```

## Packages Published

The following packages are published:
- `FFmpeg.AutoGen`
- `FFmpeg.AutoGen.Abstractions`
- `FFmpeg.AutoGen.Bindings.DynamicallyLinked`
- `FFmpeg.AutoGen.Bindings.DynamicallyLoaded`
- `FFmpeg.AutoGen.Bindings.StaticallyLinked`

## Rollback

If something goes wrong:
1. Unlist the bad version on NuGet.org (cannot delete)
2. Fix the issue
3. Increment version and republish

## GitHub Secrets Setup

For automated publishing, ensure the following secret is set in GitHub:
- `NUGET_API_KEY` - Your NuGet.org API key with push permissions

Go to: Settings ? Secrets and variables ? Actions ? New repository secret

## Version Numbering

Follow semantic versioning aligned with FFmpeg:
- `MAJOR.MINOR.PATCH.BUILD`
- `8.0.0.0` - Matches FFmpeg 8.0
- `8.0.1.0` - Patch release for FFmpeg 8.0
- MAJOR.MINOR synced with FFmpeg, PATCH for API-compatible updates
