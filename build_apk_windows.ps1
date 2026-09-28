$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

function Require-Command([string]$Name) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command not found: $Name"
    }
}

Require-Command 'java.exe'
Require-Command 'curl.exe'
Require-Command 'tar.exe'

$Sdk = $env:ANDROID_SDK_ROOT
if (-not $Sdk) { $Sdk = $env:ANDROID_HOME }
if (-not $Sdk) { $Sdk = Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
if (-not (Test-Path $Sdk)) {
    throw "Android SDK not found. Install Android Command-line Tools (not Android Studio) and set ANDROID_SDK_ROOT or ANDROID_HOME."
}

$SdkManager = Join-Path $Sdk 'cmdline-tools\latest\bin\sdkmanager.bat'
if (-not (Test-Path $SdkManager)) {
    throw "sdkmanager.bat not found at $SdkManager. Install Android SDK Command-line Tools first."
}

$env:ANDROID_HOME = $Sdk
$env:ANDROID_SDK_ROOT = $Sdk
$env:ANDROID_NDK_HOME = Join-Path $Sdk 'ndk\28.0.13004108'

Write-Host 'Accepting Android SDK licenses...'
cmd.exe /c "(for /f %%%%i in ('echo y') do @echo %%%%i) | \"$SdkManager\" --licenses" | Out-Null

Write-Host 'Installing/verifying SDK packages...'
& $SdkManager 'platform-tools' 'platforms;android-35' 'build-tools;35.0.0' 'ndk;28.0.13004108' 'cmake;3.22.1'
if ($LASTEXITCODE -ne 0) { throw 'sdkmanager failed.' }

Set-Location $Root
& powershell.exe -ExecutionPolicy Bypass -File (Join-Path $Root 'prepare_android_project.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Android project build failed.' }

$Apk = Join-Path $Root 'EvolutionLab4-debug.apk'
if (-not (Test-Path $Apk)) { throw "APK not found: $Apk" }

Write-Host ''
Write-Host 'BUILD COMPLETE'
Write-Host $Apk
