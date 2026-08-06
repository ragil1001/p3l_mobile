#!/usr/bin/env bash
set -euo pipefail

PACKAGE="com.example.p3l_mobile"
ACTIVITY="$PACKAGE/.MainActivity"
APK="build/app/outputs/flutter-apk/app-debug.apk"
OUT="runtime/screenshots"

mkdir -p "$OUT"
adb wait-for-device
adb shell input keyevent 82 || true
adb shell settings put global window_animation_scale 0
adb shell settings put global transition_animation_scale 0
adb shell settings put global animator_duration_scale 0
adb shell wm size reset || true
adb shell wm density reset || true
adb install -r "$APK"

assert_foreground() {
  if ! adb shell dumpsys activity activities | grep -E 'mResumedActivity|topResumedActivity' | grep -q "$PACKAGE"; then
    echo "Expected $PACKAGE to be foreground" >&2
    adb shell dumpsys activity activities | grep -E 'mResumedActivity|topResumedActivity' || true
    exit 1
  fi
}

capture_screen() {
  local screen="$1"
  local name="$2"
  local wait_seconds="$3"

  adb shell am force-stop "$PACKAGE"
  adb shell am start -S -n "$ACTIVITY" --es capture_screen "$screen" >/dev/null
  sleep "$wait_seconds"
  assert_foreground
  adb exec-out screencap -p > "$OUT/$name.png"
}

capture_screen "login" "p3l-login-mobile" 14
capture_screen "register" "p3l-register-mobile" 14
capture_screen "pembeli" "p3l-pembeli-mobile" 17
capture_screen "penitip" "p3l-penitip-mobile" 14
capture_screen "hunter" "p3l-hunter-mobile" 17
capture_screen "kurir" "p3l-kurir-mobile" 17

adb logcat -d > runtime/android-logcat.txt
