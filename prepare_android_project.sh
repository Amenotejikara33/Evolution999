#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Evolution Lab 4 - Android project preparation/build script
# Android Studio is NOT required.
# ============================================================

ROOT="$(cd "$(dirname "$0")" && pwd)"
WORK="$ROOT/.deps"

SDL_VERSION="2.32.10"
TTF_VERSION="2.24.0"

SDL_URL="https://www.libsdl.org/release/SDL2-${SDL_VERSION}.tar.gz"
TTF_URL="https://www.libsdl.org/projects/SDL_ttf/release/SDL2_ttf-${TTF_VERSION}.tar.gz"

echo "=============================================="
echo " Evolution Lab 4 Android Build"
echo "=============================================="
echo "Project root: $ROOT"
echo ""

# ------------------------------------------------------------
# Check required command-line tools
# ------------------------------------------------------------

command -v curl >/dev/null 2>&1 || {
    echo "ERROR: curl is required."
    exit 1
}

command -v tar >/dev/null 2>&1 || {
    echo "ERROR: tar is required."
    exit 1
}

command -v java >/dev/null 2>&1 || {
    echo "ERROR: Java 17+ is required."
    exit 1
}

# ------------------------------------------------------------
# Find Android SDK
# ------------------------------------------------------------

SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}}"

if [ ! -d "$SDK" ]; then
    echo "ERROR: Android SDK not found."
    echo "ANDROID_HOME=$SDK"
    exit 1
fi

export ANDROID_HOME="$SDK"
export ANDROID_SDK_ROOT="$SDK"

echo "Android SDK:"
echo "  $SDK"
echo ""

# ------------------------------------------------------------
# Find Android NDK
# ------------------------------------------------------------

if [ -z "${ANDROID_NDK_HOME:-}" ]; then
    if [ -d "$SDK/ndk" ]; then
        ANDROID_NDK_HOME="$(
            find "$SDK/ndk" \
                -mindepth 1 \
                -maxdepth 1 \
                -type d \
                | sort -V \
                | tail -n 1
        )"

        export ANDROID_NDK_HOME
    fi
fi

if [ -z "${ANDROID_NDK_HOME:-}" ] || [ ! -d "$ANDROID_NDK_HOME" ]; then
    echo "ERROR: Android NDK not found."
    echo "ANDROID_NDK_HOME=$ANDROID_NDK_HOME"
    exit 1
fi

echo "Android NDK:"
echo "  $ANDROID_NDK_HOME"
echo ""

# ------------------------------------------------------------
# Prepare dependency directory
# ------------------------------------------------------------

rm -rf "$WORK"
mkdir -p "$WORK"

echo "Downloading SDL2..."
curl -L \
    --fail \
    --retry 3 \
    --retry-delay 2 \
    -o "$WORK/SDL2.tar.gz" \
    "$SDL_URL"

echo ""

echo "Downloading SDL2_ttf..."
curl -L \
    --fail \
    --retry 3 \
    --retry-delay 2 \
    -o "$WORK/SDL2_ttf.tar.gz" \
    "$TTF_URL"

echo ""

# ------------------------------------------------------------
# Extract SDL libraries
# ------------------------------------------------------------

echo "Extracting SDL2..."
tar -xzf "$WORK/SDL2.tar.gz" -C "$WORK"

echo "Extracting SDL2_ttf..."
tar -xzf "$WORK/SDL2_ttf.tar.gz" -C "$WORK"

SDL_DIR="$WORK/SDL2-${SDL_VERSION}"
TTF_DIR="$WORK/SDL2_ttf-${TTF_VERSION}"

if [ ! -d "$SDL_DIR" ]; then
    echo "ERROR: SDL2 extraction failed."
    exit 1
fi

if [ ! -d "$TTF_DIR" ]; then
    echo "ERROR: SDL2_ttf extraction failed."
    exit 1
fi

echo "SDL2:"
echo "  $SDL_DIR"

echo "SDL2_ttf:"
echo "  $TTF_DIR"

echo ""

# ------------------------------------------------------------
# IMPORTANT:
# Make sure Android source directories exist BEFORE copying.
# This fixes:
#
# cp: cannot create directory
# '/.../app/src/main/cpp/SDL':
# No such file or directory
# ------------------------------------------------------------

APP_MAIN="$ROOT/app/src/main"
APP_JAVA="$APP_MAIN/java"
APP_CPP="$APP_MAIN/cpp"

mkdir -p "$APP_MAIN"
mkdir -p "$APP_JAVA"
mkdir -p "$APP_CPP"

# ------------------------------------------------------------
# Copy SDL Android Java glue
# ------------------------------------------------------------

echo "Installing SDL Android Java files..."

rm -rf "$APP_JAVA/org/libsdl/app"

mkdir -p "$APP_JAVA/org/libsdl/app"

if [ -d "$SDL_DIR/android-project/app/src/main/java/org/libsdl/app" ]; then

    cp -a \
        "$SDL_DIR/android-project/app/src/main/java/org/libsdl/app/." \
        "$APP_JAVA/org/libsdl/app/"

else

    echo "ERROR: SDL Android Java glue was not found."
    echo "Expected:"
    echo "  $SDL_DIR/android-project/app/src/main/java/org/libsdl/app"

    exit 1

fi

# ------------------------------------------------------------
# Copy SDL native libraries
# ------------------------------------------------------------

echo "Installing SDL2 native source..."

rm -rf "$APP_CPP/SDL"
rm -rf "$APP_CPP/SDL2_ttf"

# Make absolutely sure destination parent exists.
mkdir -p "$APP_CPP"

cp -a \
    "$SDL_DIR" \
    "$APP_CPP/SDL"

echo "SDL2 copied."

# ------------------------------------------------------------
# Copy SDL_ttf
# ------------------------------------------------------------

echo "Installing SDL2_ttf native source..."

mkdir -p "$APP_CPP"

cp -a \
    "$TTF_DIR" \
    "$APP_CPP/SDL2_ttf"

echo "SDL2_ttf copied."

echo ""

# ------------------------------------------------------------
# Install Gradle wrapper from SDL Android project
# ------------------------------------------------------------

if [ -d "$SDL_DIR/android-project/gradle" ]; then

    echo "Installing Gradle wrapper..."

    rm -rf "$ROOT/gradle"

    cp -a \
        "$SDL_DIR/android-project/gradle" \
        "$ROOT/gradle"

fi

if [ -f "$SDL_DIR/android-project/gradlew" ]; then

    cp \
        "$SDL_DIR/android-project/gradlew" \
        "$ROOT/gradlew"

fi

if [ -f "$SDL_DIR/android-project/gradlew.bat" ]; then

    cp \
        "$SDL_DIR/android-project/gradlew.bat" \
        "$ROOT/gradlew.bat"

fi

chmod +x "$ROOT/gradlew"

# ------------------------------------------------------------
# Adjust Gradle distribution
# ------------------------------------------------------------

WRAPPER="$ROOT/gradle/wrapper/gradle-wrapper.properties"

if [ -f "$WRAPPER" ]; then

    echo "Configuring Gradle wrapper..."

    sed -i -E \
        's#gradle-[0-9.]+-(all|bin)\.zip#gradle-8.13-bin.zip#g' \
        "$WRAPPER"

fi

# ------------------------------------------------------------
# Verify important project files
# ------------------------------------------------------------

echo ""
echo "Checking Android project..."

REQUIRED_FILES=(
    "$ROOT/settings.gradle"
    "$ROOT/build.gradle"
    "$ROOT/app/build.gradle"
    "$ROOT/app/src/main/AndroidManifest.xml"
    "$ROOT/app/src/main/cpp/CMakeLists.txt"
    "$ROOT/app/src/main/cpp/src/EvolutionLab4.cpp"
)

for FILE in "${REQUIRED_FILES[@]}"; do

    if [ ! -f "$FILE" ]; then
        echo "ERROR: Missing required file:"
        echo "  $FILE"
        exit 1
    fi

done

echo "Project files OK."

if [ ! -d "$APP_CPP/SDL" ]; then
    echo "ERROR: SDL directory was not created."
    exit 1
fi

if [ ! -d "$APP_CPP/SDL2_ttf" ]; then
    echo "ERROR: SDL2_ttf directory was not created."
    exit 1
fi

echo "SDL directories OK."

# ------------------------------------------------------------
# Build APK
# ------------------------------------------------------------

echo ""
echo "=============================================="
echo " Building Evolution Lab APK..."
echo "=============================================="
echo ""

cd "$ROOT"

./gradlew clean assembleDebug --no-daemon

# ------------------------------------------------------------
# Copy final APK to project root
# ------------------------------------------------------------

APK="$ROOT/app/build/outputs/apk/debug/app-debug.apk"
OUTPUT="$ROOT/EvolutionLab4-debug.apk"

if [ ! -f "$APK" ]; then

    echo ""
    echo "ERROR: APK was not produced."
    echo "Expected:"
    echo "  $APK"

    exit 1

fi

cp "$APK" "$OUTPUT"

echo ""
echo "=============================================="
echo " BUILD SUCCESSFUL"
echo "=============================================="
echo ""
echo "APK:"
echo "  $OUTPUT"
echo ""
echo "You can now download EvolutionLab4-debug.apk"
echo ""
