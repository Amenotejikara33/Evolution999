# Evolution Lab 4 — Android-Studio-free APK build package

This package builds the current Evolution Lab 4 SDL2 mobile version, including the latest mobile rotation/resize layout fixes.

## What you get

- Evolution Lab 4 native C++17 simulation
- SDL2 2.32.10
- SDL2_ttf 2.24.0
- neuroevolution + recurrent neural controller
- RL + neuroplasticity
- energy-closure auditing
- mutation/speciation/diversity telemetry
- resilience experiments
- live graphs and interpretation
- separate all-graphs analytics window
- Android sensor rotation support
- ABI: `arm64-v8a` and `armeabi-v7a`
- package ID: `com.evolutionlab.app`

## No Android Studio: easiest path

The repository contains a GitHub Actions workflow at:

`.github/workflows/build-apk.yml`

That workflow builds the APK on a GitHub runner. You do **not** need Android Studio on your phone or PC.

### Build with GitHub Actions

1. Create a new GitHub repository.
2. Upload the contents of this folder to the repository.
3. Open the repository's **Actions** tab.
4. Select **Build Evolution Lab APK**.
5. Run the workflow with **Run workflow**.
6. When it finishes, open the workflow run and download the artifact named:

`EvolutionLab4-debug-apk`

7. Extract the artifact. It contains:

`EvolutionLab4-debug.apk`

8. Send that APK to your phone, tap it, and install it.

On Android, you may need to allow installation from the browser/file manager used to open the APK.

## Local command-line build on Windows — still no Android Studio

Install only these command-line components:

- Java 17
- Android SDK Command-line Tools
- Android SDK Platform 35
- Android SDK Build-Tools 35.0.0
- Android NDK 28.0.13004108
- CMake 3.22.1

Set `ANDROID_SDK_ROOT` or `ANDROID_HOME` to the SDK directory, then run:

```powershell
powershell -ExecutionPolicy Bypass -File .\build_apk_windows.ps1
```

The script installs/checks the required SDK packages, downloads the official SDL2/SDL2_ttf source archives, and builds:

`EvolutionLab4-debug.apk`

## Local command-line build on Linux/macOS

```bash
chmod +x ./build_apk_linux.sh
./build_apk_linux.sh
```

## Notes

This is a debug APK and is not Play Store-signed. For direct installation on a personal Android phone, the debug APK is sufficient.

The Android project is built without Android Studio and without adding a third-party Java dependency to the simulation itself.
