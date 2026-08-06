#!/usr/bin/env bash
set -euo pipefail

PACKAGE="com.example.p3l_mobile"
APK="build/app/outputs/flutter-apk/app-debug.apk"
OUT="runtime/screenshots"

mkdir -p "$OUT"
adb wait-for-device
adb shell input keyevent 82 || true
adb shell settings put global window_animation_scale 0
adb shell settings put global transition_animation_scale 0
adb shell settings put global animator_duration_scale 0
adb shell wm size 430x932
adb shell wm density 160
adb install -r "$APK"
adb shell am force-stop "$PACKAGE"
adb shell monkey -p "$PACKAGE" -c android.intent.category.LAUNCHER 1 >/dev/null
sleep 5

adb exec-out screencap -p > "$OUT/p3l-capture-menu.png"

capture_screen() {
  local name="$1"
  local y="$2"
  local wait_seconds="$3"

  adb shell input tap 215 "$y"
  sleep "$wait_seconds"
  adb exec-out screencap -p > "$OUT/$name.png"
  adb shell input keyevent 4
  sleep 2
}

# Fixed coordinates are based on the temporary capture menu at 430x932 and 160 dpi.
capture_screen "p3l-login-mobile" 128 4
capture_screen "p3l-register-mobile" 196 4
capture_screen "p3l-pembeli-mobile" 264 9
capture_screen "p3l-penitip-mobile" 332 5
capture_screen "p3l-hunter-mobile" 400 9
capture_screen "p3l-kurir-mobile" 468 9

adb logcat -d > runtime/android-logcat.txt
adb shell wm size reset || true
adb shell wm density reset || true
