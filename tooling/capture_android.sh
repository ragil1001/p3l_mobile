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
adb shell wm size reset || true
adb shell wm density reset || true
adb install -r "$APK"

launch_menu() {
  adb shell am force-stop "$PACKAGE"
  adb shell monkey -p "$PACKAGE" -c android.intent.category.LAUNCHER 1 >/dev/null
  sleep 4
}

assert_foreground() {
  if ! adb shell dumpsys activity activities | grep -E 'mResumedActivity|topResumedActivity' | grep -q "$PACKAGE"; then
    echo "Expected $PACKAGE to be foreground" >&2
    adb shell dumpsys activity activities | grep -E 'mResumedActivity|topResumedActivity' || true
    exit 1
  fi
}

launch_menu
assert_foreground
adb exec-out screencap -p > "$OUT/p3l-capture-menu.png"

capture_screen() {
  local name="$1"
  local y="$2"
  local wait_seconds="$3"

  launch_menu
  assert_foreground
  adb shell input tap 540 "$y"
  sleep "$wait_seconds"
  assert_foreground
  adb exec-out screencap -p > "$OUT/$name.png"
}

# Pixel 6 physical resolution is 1080x2400. Button centers were measured from
# the temporary menu at the emulator's native resolution.
capture_screen "p3l-login-mobile" 330 5
capture_screen "p3l-register-mobile" 505 5
capture_screen "p3l-pembeli-mobile" 680 10
capture_screen "p3l-penitip-mobile" 855 6
capture_screen "p3l-hunter-mobile" 1030 10
capture_screen "p3l-kurir-mobile" 1205 10

adb logcat -d > runtime/android-logcat.txt
