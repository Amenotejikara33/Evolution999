#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
SDK="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$HOME/Android/Sdk}}"
SDKMANAGER="$SDK/cmdline-tools/latest/bin/sdkmanager"

command -v java >/dev/null || { echo 'Java 17+ is required.' >&2; exit 1; }
command -v curl >/dev/null || { echo 'curl is required.' >&2; exit 1; }
command -v tar >/dev/null || { echo 'tar is required.' >&2; exit 1; }

[ -x "$SDKMANAGER" ] || { echo "sdkmanager not found: $SDKMANAGER" >&2; exit 1; }

export ANDROID_HOME="$SDK"
export ANDROID_SDK_ROOT="$SDK"
export ANDROID_NDK_HOME="$SDK/ndk/28.0.13004108"

yes | "$SDKMANAGER" --licenses >/dev/null || true
"$SDKMANAGER" 'platform-tools' 'platforms;android-35' 'build-tools;35.0.0' 'ndk;28.0.13004108' 'cmake;3.22.1'

cd "$ROOT"
chmod +x ./prepare_android_project.sh
./prepare_android_project.sh

test -s "$ROOT/EvolutionLab4-debug.apk"
echo "BUILD COMPLETE: $ROOT/EvolutionLab4-debug.apk"
