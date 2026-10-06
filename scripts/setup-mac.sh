#!/bin/bash
# Compatible with the /bin/bash 3.2 shipped by macOS; no Python/Homebrew needed.
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ADB=''; SERIAL=''
fail() { printf '오류: %s\n' "$*" >&2; return 1; }
fetch_verified() {
  local id="$1" key filename url digest found=0 actual target temp
  while IFS=$'\t' read -r key filename url digest; do
    [[ "$key" == "$id" ]] || continue
    found=1; mkdir -p "$ROOT/cache"; target="$ROOT/cache/$filename"; temp="$target.part"
    if [[ ! -f "$target" ]]; then
      printf '다운로드: %s\n' "$filename" >&2
      curl --fail --location --proto '=https' --tlsv1.2 --connect-timeout 20 --max-time 180 --retry 2 "$url" -o "$temp" >&2 || { rm -f "$temp"; return 1; }
      actual=$(shasum -a 256 "$temp"); actual=${actual%% *}
      [[ "$actual" == "$digest" ]] || { rm -f "$temp"; fail "$filename 해시 불일치. 실행하지 않습니다."; return 1; }
      mv "$temp" "$target"
    fi
    actual=$(shasum -a 256 "$target"); actual=${actual%% *}
    [[ "$actual" == "$digest" ]] || { fail "$filename 해시 불일치. cache 파일을 삭제하고 다시 받으세요."; return 1; }
    printf '%s\n' "$target"; return 0
  done < "$ROOT/downloads.tsv"
  [[ "$found" == 1 ]] || fail "다운로드 항목 없음: $id"
}
prepare() {
  local accept="$1" answer archive
  if [[ "$accept" != yes && ! -f "$ROOT/cache/sdk-license-accepted" ]]; then
    printf 'ADB는 Google Android SDK 약관에 따라 사용합니다.\nhttps://developer.android.com/tools/releases/platform-tools#downloads\n'
    read -r -p '약관을 확인하고 동의하면 Y: ' answer
    [[ "$answer" == Y || "$answer" == y ]] || { fail '동의하지 않아 다운로드를 중지했습니다.'; return 1; }
  fi
  mkdir -p "$ROOT/cache"; touch "$ROOT/cache/sdk-license-accepted"
  archive=$(fetch_verified mac)
  mkdir -p "$ROOT/runtime"; unzip -oq "$archive" -d "$ROOT/runtime"
  ADB="$ROOT/runtime/platform-tools/adb"; chmod +x "$ADB"
  fetch_verified king >/dev/null; fetch_verified browser >/dev/null
  "$ADB" version
}
adb_call() { "$ADB" "$@"; }
phone() { adb_call -s "$SERIAL" "$@"; }
select_device() {
  local wanted="$1" listing line candidate='' count=0 model sdk serial state rest
  adb_call start-server >/dev/null
  listing=$(adb_call devices -l)
  while read -r serial state rest; do
    [[ "$state" == device ]] || continue
    [[ "$serial" != emulator-* && "$serial" != *:* ]] || continue
    if [[ -n "$wanted" ]]; then [[ "$serial" == "$wanted" ]] || continue
    else [[ "$rest" =~ model:SM[_-]F926[A-Za-z0-9]*([[:space:]]|$) ]] || continue; fi
    candidate="$serial"; count=$((count+1))
  done <<< "$listing"
  [[ "$count" == 1 ]] || { fail '인증된 폴드3 한 대만 USB로 연결하세요. USB 디버깅/RSA 허용 및 Windows 삼성 드라이버를 확인하세요. 여러 대면 --serial SERIAL을 사용하세요.'; return 1; }
  SERIAL="$candidate"
  model=$(phone shell getprop ro.product.model | tr -d '\r')
  [[ "$model" =~ ^SM[_-]F926[A-Za-z0-9]+$ ]] || { fail "대상이 폴드3가 아닙니다: $model"; return 1; }
  sdk=$(phone shell getprop ro.build.version.sdk | tr -d '\r')
  [[ "$sdk" =~ ^[0-9]+$ ]] && [[ "$sdk" -ge 29 ]] || { fail 'Android 10(API 29) 이상이 필요합니다.'; return 1; }
  printf '대상: %s / Android %s (API %s)\n' "$model" "$(phone shell getprop ro.build.version.release | tr -d '\r')" "$sdk"
}
package_exists() {
  local result line; result=$(phone shell pm list packages --user 0 "$1" | tr -d '\r')
  while IFS= read -r line; do [[ "$line" != "package:$1" ]] || return 0; done <<< "$result"
  return 1
}
verify_packages() {
  local p info
  for p in com.example.kinginstaller com.fcaronte.aabrowser; do
    package_exists "$p" || { fail "$p 미설치. KingInstaller에서 설치를 마친 다음 다시 확인하세요."; return 1; }
    info=$(phone shell dumpsys package "$p")
    printf '\n%s\n' "$p"
    printf '%s\n' "$info" | sed -n -E '/versionName=|installerPackageName=|initiatingPackageName=|originatingPackageName=/p'
  done
  printf '\n휴대폰 앱 설치를 확인했습니다. Android Auto 설정과 차량 화면 실행 확인은 별도입니다.\n'
}
setup_phone() {
  local king browser ignored
  king=$(fetch_verified king); browser=$(fetch_verified browser)
  phone install -r "$king"
  package_exists com.example.kinginstaller || { fail 'KingInstaller 설치 결과를 확인하지 못했습니다.'; return 1; }
  phone push "$browser" /sdcard/Download/AABrowser-v1.9.apk
  phone shell am start -a android.settings.MANAGE_UNKNOWN_APP_SOURCES -d package:com.example.kinginstaller >/dev/null
  printf '\n휴대폰: KingInstaller의 이 출처 허용을 켜 주세요.\n'
  read -r -p '허용 후 Enter: ' ignored
  phone shell am start -n com.example.kinginstaller/.MainActivity >/dev/null
  printf '\n휴대폰: KingInstaller → APK 선택 → Download/AABrowser-v1.9.apk → 일반 설치.\n모든 파일 접근을 요청하면 필요한 설정을 확인하세요. 기존 AABrowser가 더 최신이면 다운그레이드하지 마세요.\n설치 경고가 나오면 내용을 확인하고 휴대폰에서 결정하세요.\n'
  read -r -p '휴대폰 설치 완료 후 Enter: ' ignored
  verify_packages
  if package_exists com.google.android.projection.gearhead; then
    phone shell am start -a com.google.android.projection.gearhead.SETTINGS -p com.google.android.projection.gearhead >/dev/null || printf '휴대폰 설정에서 Android Auto를 검색해 여세요.\n'
  else printf 'Android Auto를 Play Store에서 설치/업데이트하세요.\n'; fi
  printf '\n마지막 휴대폰 설정은 GUIDE-KO.md의 4번을 따라 확인하세요.\nPC 도구는 Android Auto 개발자 설정의 저장 여부를 판정하지 않습니다.\n'
}
main() {
  local mode=setup wanted='' accept=no
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --prepare-only) mode=prepare;; --check-only) mode=check;; --accept-sdk-license) accept=yes;;
      --serial) [[ $# -ge 2 ]] || { fail '--serial 뒤에 기기 일련번호가 필요합니다.'; return 1; }; wanted="$2"; shift;;
      --help) printf '%s\n' '사용: Setup-Mac.command [--prepare-only | --check-only] [--serial SERIAL] [--accept-sdk-license]'; return;;
      *) fail "알 수 없는 옵션: $1"; return 1;;
    esac; shift
  done
  [[ "$(uname -s)" == Darwin ]] || { fail 'Mac용 스크립트입니다.'; return 1; }
  prepare "$accept"
  if [[ "$mode" == prepare ]]; then printf '준비 완료. 휴대폰은 변경하지 않았습니다.\n'; return; fi
  select_device "$wanted"
  if [[ "$mode" == check ]]; then verify_packages; else setup_phone; fi
}
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then main "$@"; fi
