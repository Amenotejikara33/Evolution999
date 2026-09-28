$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Work = Join-Path $Root '.deps'
$SdlVersion = '2.32.10'
$TtfVersion = '2.24.0'
$SdlUrl = "https://www.libsdl.org/release/SDL2-$SdlVersion.tar.gz"
$TtfUrl = "https://www.libsdl.org/projects/SDL_ttf/release/SDL2_ttf-$TtfVersion.tar.gz"

function Need-Command($name) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
        throw "Required command not found: $name"
    }
}

Need-Command 'curl.exe'
Need-Command 'tar.exe'
Need-Command 'java.exe'

$Sdk = $env:ANDROID_HOME
if (-not $Sdk) { $Sdk = $env:ANDROID_SDK_ROOT }
if (-not $Sdk) { $Sdk = Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
if (-not (Test-Path $Sdk)) { throw "Android SDK not found. Install Android SDK Command-line Tools (no Android Studio required) and set ANDROID_HOME/ANDROID_SDK_ROOT." }

$NdkRoot = Join-Path $Sdk 'ndk'
$Ndk = Get-ChildItem $NdkRoot -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
if (-not $Ndk) { throw "Android NDK not found under $NdkRoot. Install Android NDK 28.0.13004108 with sdkmanager." }

$env:ANDROID_HOME = $Sdk
$env:ANDROID_SDK_ROOT = $Sdk
$env:ANDROID_NDK_HOME = $Ndk.FullName

Remove-Item $Work -Recurse -Force -ErrorAction SilentlyContinue
New-Item $Work -ItemType Directory -Force | Out-Null

$SdlArchive = Join-Path $Work "SDL2-$SdlVersion.tar.gz"
$TtfArchive = Join-Path $Work "SDL2_ttf-$TtfVersion.tar.gz"

curl.exe -L --fail --retry 3 -o $SdlArchive $SdlUrl
curl.exe -L --fail --retry 3 -o $TtfArchive $TtfUrl

tar.exe -xzf $SdlArchive -C $Work
tar.exe -xzf $TtfArchive -C $Work

$SdlDir = Join-Path $Work "SDL2-$SdlVersion"
$TtfDir = Join-Path $Work "SDL2_ttf-$TtfVersion"
if (-not (Test-Path $SdlDir)) { throw "SDL2 source extraction failed." }
if (-not (Test-Path $TtfDir)) { throw "SDL2_ttf source extraction failed." }

$JavaOut = Join-Path $Root 'app/src/main/java/org/libsdl/app'
Remove-Item $JavaOut -Recurse -Force -ErrorAction SilentlyContinue
New-Item $JavaOut -ItemType Directory -Force | Out-Null
Copy-Item (Join-Path $SdlDir 'android-project/app/src/main/java/org/libsdl/app/*') $JavaOut -Recurse -Force

$SdlOut = Join-Path $Root 'app/src/main/cpp/SDL'
$TtfOut = Join-Path $Root 'app/src/main/cpp/SDL2_ttf'
Remove-Item $SdlOut,$TtfOut -Recurse -Force -ErrorAction SilentlyContinue
Copy-Item $SdlDir $SdlOut -Recurse -Force
Copy-Item $TtfDir $TtfOut -Recurse -Force

# SDL2's Java layer expects to load the SDL2 shared library; the custom Activity
# adds SDL2_ttf and main in the same process.
$Gradle = Join-Path $SdlDir 'android-project/gradle'
if (Test-Path $Gradle) { Copy-Item $Gradle (Join-Path $Root 'gradle') -Recurse -Force }
Copy-Item (Join-Path $SdlDir 'android-project/gradlew*') $Root -Force

$WrapperProps = Join-Path $Root 'gradle/wrapper/gradle-wrapper.properties'
if (Test-Path $WrapperProps) {
    (Get-Content $WrapperProps -Raw) -replace 'gradle-[0-9.]+-all.zip', 'gradle-8.13-bin.zip' | Set-Content $WrapperProps -NoNewline
}

Set-Location $Root
& .\gradlew.bat clean assembleDebug --no-daemon
$Apk = Join-Path $Root 'app/build/outputs/apk/debug/app-debug.apk'
if (-not (Test-Path $Apk)) { throw "Gradle completed but APK was not found at $Apk" }
Copy-Item $Apk (Join-Path $Root 'EvolutionLab4-debug.apk') -Force
Write-Host "APK built: $Root\EvolutionLab4-debug.apk"
