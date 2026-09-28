#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
WORK="$ROOT/.deps"
SDL_VERSION=2.32.10
TTF_VERSION=2.24.0
SDL_URL="https://www.libsdl.org/release/SDL2-${SDL_VERSION}.tar.gz"
TTF_URL="https://www.libsdl.org/projects/SDL_ttf/release/SDL2_ttf-${TTF_VERSION}.tar.gz"

command -v curl >/dev/null || { echo "curl is required" >&2; exit 1; }
command -v tar >/dev/null || { echo "tar is required" >&2; exit 1; }
command -v java >/dev/null || { echo "Java 17+ is required" >&2; exit 1; }

SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}}"
[ -d "$SDK" ] || { echo "Android SDK not found. Install it and set ANDROID_HOME/ANDROID_SDK_ROOT." >&2; exit 1; }
export ANDROID_HOME="$SDK"
export ANDROID_SDK_ROOT="$SDK"

if [ -z "${ANDROID_NDK_HOME:-}" ]; then
  if [ -d "$SDK/ndk" ]; then
    export ANDROID_NDK_HOME="$(find "$SDK/ndk" -mindepth 1 -maxdepth 1 -type d | sort -V | tail -n1)"
  fi
fi
[ -n "${ANDROID_NDK_HOME:-}" ] && [ -d "$ANDROID_NDK_HOME" ] || { echo "Android NDK not found." >&2; exit 1; }

rm -rf "$WORK"
mkdir -p "$WORK"
curl -L --fail --retry 3 -o "$WORK/SDL2.tar.gz" "$SDL_URL"
curl -L --fail --retry 3 -o "$WORK/SDL2_ttf.tar.gz" "$TTF_URL"
tar -xzf "$WORK/SDL2.tar.gz" -C "$WORK"
tar -xzf "$WORK/SDL2_ttf.tar.gz" -C "$WORK"

SDL_DIR="$WORK/SDL2-${SDL_VERSION}"
TTF_DIR="$WORK/SDL2_ttf-${TTF_VERSION}"
[ -d "$SDL_DIR" ] || { echo "SDL2 extraction failed" >&2; exit 1; }
[ -d "$TTF_DIR" ] || { echo "SDL2_ttf extraction failed" >&2; exit 1; }

rm -rf "$ROOT/app/src/main/java/org/libsdl/app"
mkdir -p "$ROOT/app/src/main/java/org/libsdl/app"
cp -a "$SDL_DIR/android-project/app/src/main/java/org/libsdl/app/." "$ROOT/app/src/main/java/org/libsdl/app/"

rm -rf "$ROOT/app/src/main/cpp/SDL" "$ROOT/app/src/main/cpp/SDL2_ttf"
cp -a "$SDL_DIR" "$ROOT/app/src/main/cpp/SDL"
cp -a "$TTF_DIR" "$ROOT/app/src/main/cpp/SDL2_ttf"

if [ -d "$SDL_DIR/android-project/gradle" ]; then
  rm -rf "$ROOT/gradle"
  cp -a "$SDL_DIR/android-project/gradle" "$ROOT/gradle"
fi
cp "$SDL_DIR/android-project/gradlew" "$ROOT/gradlew"
cp "$SDL_DIR/android-project/gradlew.bat" "$ROOT/gradlew.bat"
chmod +x "$ROOT/gradlew"

WRAPPER="$ROOT/gradle/wrapper/gradle-wrapper.properties"
if [ -f "$WRAPPER" ]; then
  sed -i -E 's#gradle-[0-9.]+-all\.zip#gradle-8.13-bin.zip#g' "$WRAPPER"
fi

cd "$ROOT"
./gradlew clean assembleDebug --no-daemon
cp "$ROOT/app/build/outputs/apk/debug/app-debug.apk" "$ROOT/EvolutionLab4-debug.apk"
echo "APK built: $ROOT/EvolutionLab4-debug.apk"
