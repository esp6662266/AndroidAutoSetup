#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../scripts/setup-mac.sh"
LISTING=$'List of devices attached\nWATCH:5555 device model:SM_L505N\nFOLD6 device model:SM_F956N\nemulator-5556 device model:SM_F926N\nFOLD3 device product:q2q model:SM_F926N device:q2q'
MODEL=SM-F926N; SDK=35; PACKAGES='package:com.example.kinginstaller'; checks=0
adb_call() {
  case "$*" in
    start-server) :;; 'devices -l') printf '%s\n' "$LISTING";;
    '-s FOLD3 shell getprop ro.product.model'|'-s FOLD6 shell getprop ro.product.model') printf '%s\n' "$MODEL";;
    '-s FOLD3 shell getprop ro.build.version.sdk') printf '%s\n' "$SDK";;
    '-s FOLD3 shell getprop ro.build.version.release') printf '15\n';;
    *'shell pm list packages --user 0 '*) printf '%s\n' "$PACKAGES";;
    *'shell dumpsys package '*) printf 'versionName=1.9\ninstallerPackageName=com.android.vending\n';;
    *) printf 'unexpected ADB invocation: %s\n' "$*" >&2; return 1;;
  esac
}
pass() { checks=$((checks+1)); printf 'PASS: %s\n' "$1"; }
reject() { if "$@" >/dev/null 2>&1; then printf 'Unexpected success\n' >&2; exit 1; fi; }
select_device '' >/dev/null
[[ "$SERIAL" == FOLD3 ]]; pass 'Fold3 selected; watch, Fold6, emulator excluded'
LISTING=$'FOLD3 unauthorized model:SM_F926N'; reject select_device ''; pass 'unauthorized rejected'
LISTING=$'FOLD3 offline model:SM_F926N'; reject select_device ''; pass 'offline rejected'
LISTING=$'FOLD3 device model:SM_F926N\nSECOND device model:SM_F926B'; reject select_device ''; pass 'multiple Fold3 devices rejected'
select_device FOLD3 >/dev/null; [[ "$SERIAL" == FOLD3 ]]; pass 'explicit serial selects one Fold3'
LISTING=$'FOLD6 device model:SM_F956N'; MODEL=SM-F956N; reject select_device FOLD6; pass 'explicit serial cannot bypass model check'
LISTING=$'FOLD3 device model:SM_F926N'; MODEL=SM-F926N; SDK=28; reject select_device ''; pass 'SDK below 29 rejected'
SDK=35; select_device '' >/dev/null
PACKAGES='package:com.example.kinginstaller.debug'; reject package_exists com.example.kinginstaller; pass 'package prefix is not an exact install match'
PACKAGES=$'package:com.example.kinginstaller\npackage:com.fcaronte.aabrowser'; verify_packages >/dev/null; pass 'both installed packages verified'
PACKAGES='package:com.example.kinginstaller'; reject verify_packages; pass 'missing browser is not reported complete'
TEMP=$(mktemp -d); trap 'rm -rf "$TEMP"' EXIT
ROOT="$TEMP"; mkdir -p "$ROOT/cache"; printf 'tampered' > "$ROOT/cache/fake.apk"
printf 'id\tfilename\turl\tsha256\nking\tfake.apk\thttps://example.invalid/fake.apk\t0000\n' > "$ROOT/downloads.tsv"
reject fetch_verified king; pass 'tampered cached APK rejected without executing/downloading'
printf '%s checks passed\n' "$checks"
