#!/usr/bin/env bash
# kotlinc compile gate for the Android plugin.
#
# Why: the plugin is a vendor Flutter package without an example app, so
# `flutter build apk` cannot be used to validate Kotlin sources. This
# script wraps `kotlinc` with the same classpath the consumer app uses
# (Lepu AAR + ICDeviceManager AAR + LiveEventBus + AndroidX + Flutter
# engine) and fails the build on either errors or unchecked-cast
# warnings. It catches signature drift between the SDK AAR and our
# native bridge before the consumer app does.
#
# Usage:
#   ./tools/kotlinc_check.sh           # uses caches under ~/.gradle
#   STRICT=1 ./tools/kotlinc_check.sh  # also fails on any non-cosmetic warning
#
# Requirements (CI installs them):
#   - kotlinc 2.x  (`brew install kotlin` / SDKMAN)
#   - JDK 17+
#   - Android SDK platform 33+
#   - A `~/.gradle/caches/...` populated by at least one full Gradle
#     build of a consumer Flutter app that depends on this plugin
#     (`flutter build apk` of `doctorsapp` does that). CI does the same
#     by checking out the consumer-app repo and running its build first.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KT_FILES=(
    "$REPO_ROOT/android/src/main/kotlin/com/wecodelife/flutter_ble_devices/FlutterBleDevicesPlugin.kt"
)
JAVA_SRC="$REPO_ROOT/android/src/main/java"

# ── Locate kotlinc ──────────────────────────────────────────────────
if ! command -v kotlinc >/dev/null 2>&1; then
    echo "ERROR: kotlinc not found. Install with 'brew install kotlin' or via SDKMAN." >&2
    exit 2
fi

# ── Locate Android SDK ──────────────────────────────────────────────
ANDROID_HOME="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
ANDROID_JAR=$(ls "$ANDROID_HOME"/platforms/android-3*/android.jar 2>/dev/null | sort -V | tail -1)
if [ -z "$ANDROID_JAR" ]; then
    echo "ERROR: no android.jar under $ANDROID_HOME/platforms/. Install platform 33+ via sdkmanager." >&2
    exit 2
fi

# ── Locate Lepu / iComon AARs ──────────────────────────────────────
# Prefer Gradle's exploded transformed runtime jars (built when a
# consumer app was last compiled). Fall back to extracting classes.jar
# from the AAR ourselves into a tmp dir.
LEPU_JAR=$(find "$HOME/.gradle/caches/transforms-4" -name 'lepu-blepro-*-runtime.jar' 2>/dev/null | sort | tail -1)
if [ -z "$LEPU_JAR" ]; then
    TMP_LEPU=$(mktemp -d)
    unzip -p "$REPO_ROOT/android/libs/lepu-blepro-1.2.0.aar" classes.jar > "$TMP_LEPU/lepu.jar"
    LEPU_JAR="$TMP_LEPU/lepu.jar"
fi
ICOMON_JAR=$(find "$HOME/.gradle/caches/transforms-4" -name 'classes.jar' -path '*ICDeviceManager*' 2>/dev/null | head -1)
if [ -z "$ICOMON_JAR" ]; then
    TMP_IC=$(mktemp -d)
    unzip -p "$REPO_ROOT/android/libs/ICDeviceManager.aar" classes.jar > "$TMP_IC/ic.jar"
    ICOMON_JAR="$TMP_IC/ic.jar"
fi

# ── Locate Flutter engine.jar ──────────────────────────────────────
FLUTTER_BIN=$(command -v flutter || true)
FLUTTER_ROOT="${FLUTTER_ROOT:-${FLUTTER_BIN%/bin/flutter}}"
FLUTTER_JAR=$(ls "$FLUTTER_ROOT"/bin/cache/artifacts/engine/android-arm*/flutter.jar 2>/dev/null | head -1)
if [ -z "$FLUTTER_JAR" ]; then
    echo "ERROR: cannot find Flutter engine flutter.jar. Run 'flutter precache --android' first." >&2
    exit 2
fi

# ── Build the rest of the classpath from Gradle caches ─────────────
# These are pulled in transitively by the plugin's build.gradle when a
# consumer app builds — we just glob the cached transforms.
collect() {
    local pattern="$1"
    find "$HOME/.gradle/caches" \( -path '*transforms-4*' -o -path '*modules-2/files-2.1*' \) \
        -name "$pattern" 2>/dev/null
}

CP="$ANDROID_JAR:$FLUTTER_JAR:$LEPU_JAR:$ICOMON_JAR"
add() { for j in "$@"; do test -f "$j" && CP="$CP:$j"; done; }

# Find every transformed AAR's classes.jar, then pick the ones we need
# by directory name. find -name 'core-1.*' returns *directories* under
# transforms-4 — we need the classes.jar inside their /jars/ folder.
ALL_TRANSFORMED_JARS=$(find "$HOME/.gradle/caches/transforms-4" -path '*/transformed/*/jars/classes.jar' 2>/dev/null)

pick() {
    # Sort by the artifact-version directory (path component before /jars/),
    # not by the full path — otherwise the random Gradle hash dominates.
    local pattern="$1"
    echo "$ALL_TRANSFORMED_JARS" \
        | grep -E "$pattern" \
        | awk -F/ '{ printf "%s\t%s\n", $(NF-2), $0 }' \
        | sort -V \
        | tail -1 \
        | cut -f2
}
pick_all() {
    local pattern="$1"
    echo "$ALL_TRANSFORMED_JARS" | grep -E "$pattern"
}

# LiveEventBus is published as a top-level runtime.jar (no /jars/ folder)
add $(collect 'LiveEventBus-*-runtime.jar' | head -1)
# AndroidX core (newest available)
add $(pick '/transformed/core-1\.[0-9]+\.[0-9]+/')
# AndroidX lifecycle (every variant)
for j in $(pick_all '/transformed/lifecycle-[a-z-]+-2\.[0-9]+\.[0-9]+/'); do add "$j"; done
# AndroidX annotation
add $(collect 'annotation-jvm-*.jar' | head -1)
# Kotlinx coroutines
add $(collect 'kotlinx-coroutines-*.jar' | head -10)
# Nordic BLE library (transitively by Lepu)
add $(pick '/transformed/ble-2\.[0-9]+\.[0-9]+/')
# Stream-log (used by Lepu internally)
for j in $(pick_all '/transformed/stream-log[a-z-]*-[0-9]'); do add "$j"; done

OUT_DIR=$(mktemp -d)
trap 'rm -rf "$OUT_DIR"' EXIT

echo "==> kotlinc $(kotlinc -version 2>&1 | head -1 | sed 's/^info: //')"
echo "==> classpath: $(echo "$CP" | tr ':' '\n' | wc -l | tr -d ' ') jars"

LOG="$OUT_DIR/kotlinc.log"
set +e
kotlinc -cp "$CP" -d "$OUT_DIR/out" "${KT_FILES[@]}" "$JAVA_SRC" 2>&1 | tee "$LOG"
RC=${PIPESTATUS[0]}
set -e

ERRORS=$(grep -c 'error:' "$LOG" || true)
UNCHECKED=$(grep -ic 'unchecked' "$LOG" || true)
TOTAL_WARN=$(grep -c 'warning:' "$LOG" || true)

echo ""
echo "==> result: $ERRORS errors, $TOTAL_WARN warnings ($UNCHECKED unchecked-cast)"

# Always fail on errors or unchecked-cast.
if [ "$RC" -ne 0 ] || [ "$ERRORS" -gt 0 ] || [ "$UNCHECKED" -gt 0 ]; then
    echo "FAIL: kotlinc reported errors or unchecked-cast warnings — see log above." >&2
    exit 1
fi

# Optionally fail on any warning (CI strict mode).
if [ "${STRICT:-0}" = "1" ] && [ "$TOTAL_WARN" -gt 0 ]; then
    echo "FAIL (STRICT=1): $TOTAL_WARN kotlinc warnings present." >&2
    exit 1
fi

echo "OK"
