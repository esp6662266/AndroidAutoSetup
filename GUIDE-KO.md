# 폴드3 설치 안내

## 1. PC와 휴대폰 준비

- 대상: Galaxy Z Fold3, 모델 SM-F926 계열 / Android 10(API 29) 이상. 실제 Android 버전은 실행 시 표시된다. 하위 SDK 요구조건 충족이 차량 호환성을 보장하지는 않는다.
- 인터넷이 연결된 Windows 10/11 PC 또는 Mac. 관리자 실행·Python·Android Studio 설치는 필요하지 않다.
- 휴대폰 설정 → 휴대전화 정보 → 소프트웨어 정보 → 빌드번호 7회 → 개발자 옵션 → USB 디버깅 켜기.
- 데이터 전송 가능한 USB 케이블로 연결하고 잠금 해제. “USB 디버깅을 허용하시겠습니까?”는 휴대폰에서 허용한다.
- Windows에서 폰이 인식되지 않으면 [삼성 공식 USB 드라이버](https://developer.samsung.com/galaxy/others/android-usb-driver-for-windows)를 설치한다. 드라이버 설치에는 관리자 권한이 필요할 수 있다. Mac은 이 드라이버가 필요 없다.

## 2. PC 도구 실행

GitHub Releases에서 OS에 맞는 ZIP을 내려받고 **압축을 모두 풀어** 실행한다. GitHub 저장소가 비공개이므로 소유자 계정으로 로그인해야 한다.

- Windows: `Setup-Windows.cmd` 더블클릭. PowerShell 5.1 사용.
- Mac: `Setup-Mac.command` 더블클릭. 실행 권한 메시지가 나오면 터미널에서 `bash /파일이있는폴더/Setup-Mac.command`로 실행한다. 공백이 있는 경로는 따옴표로 감싼다.

처음 실행하면 Google SDK 약관 안내가 표시된다. 동의 시 Google의 ADB와 원저자의 APK를 직접 내려받아 SHA-256을 확인한다. APK/ADB 원본은 이 ZIP에 재배포하지 않는다. 파일이 변경됐거나 손상됐으면 설치를 중단한다.

이 도구는 USB로 인증된 폴드3를 선택하고 KingInstaller를 설치하며 AABrowser APK를 Download 폴더로 전송한다. 폴드6·워치·에뮬레이터·무선 연결은 선택하지 않는다. 폴드3가 여러 대면 아래 명령으로 한 대를 지정한다.

```powershell
.\Setup-Windows.cmd -Serial 대상일련번호
```

```sh
bash Setup-Mac.command --serial 대상일련번호
```

## 3. 휴대폰 설치

PC 안내에 맞춰 휴대폰에서 진행한다.

1. KingInstaller의 **이 출처 허용**을 켠다.
2. KingInstaller에서 필요한 파일 접근 설정을 확인한다.
3. KingInstaller → APK 선택 → Download → **AABrowser-v1.9.apk** → 일반 설치.
4. 기존 AABrowser가 더 최신이면 다운그레이드하지 않는다. 앱 데이터를 삭제하거나 이전 앱을 자동으로 제거하지 않는다.
5. 설치 경고가 표시되면 내용을 확인하고 휴대폰에서 결정한다. 도구는 경고를 자동으로 무시하거나 Play Protect/삼성 자동 차단 기능을 해제하지 않는다.
6. AABrowser를 열어 초기 설정을 마치고, 필요한 기능에 해당하는 권한만 선택한다. 예: 음성 입력에 마이크, 위치 기능에 위치.
7. PC에서 Enter를 누르면 두 앱의 실제 설치 여부·버전·설치 출처를 확인한다. KingInstaller에서 설치하지 않은 AABrowser는 설치 출처가 다를 수 있다.

## 4. Android Auto 확인

1. 휴대폰 설정에서 **Android Auto**를 검색하거나 PC가 연 설정 화면으로 들어간다.
2. 하단 버전 항목을 펼쳐 **버전 및 권한 정보**를 10회 눌러 개발자 모드 안내를 확인한다. 이미 활성화됐다면 다시 켤 필요 없다.
3. 우측 상단 더보기 → **개발자 설정** → **알 수 없는 소스**를 켠다. 다른 디버깅·오디오/GPS 저장 옵션을 모두 켤 필요는 없다.
4. Android Auto → **런처 맞춤설정**에서 AABrowser/AAB Media가 표시되는지 확인한다. 개발자 설정도 나갔다 다시 들어가 체크가 유지되는지 확인한다.
5. 차량이 정차한 상태에서 연결해 실제 실행을 확인한다. 이 PC 도구가 차량 호환성이나 차량 화면 실행을 검증하는 것은 아니다.

KingInstaller의 설치 결과 진단과 Android Auto 앱 표시 결과는 별도다. 목록에 나오지 않는다고 앱 삭제·시스템 초기화·루팅을 자동으로 수행하지 않는다.

## 5. 재부팅과 재확인

KingInstaller는 매번 실행할 필요가 없다. Android Auto 개발자 설정은 보통 유지되지만 폴드3에서는 실제 저장 상태를 확인한다. 재부팅 후 휴대폰 잠금을 한 번 해제하고 연결한다. 이 기본 설치 도구는 Shizuku를 설치·시작하지 않는다. 별도로 Shizuku를 쓰는 기능이 있다면 그 기능의 재시작 절차는 따로 적용한다.

설치 여부만 다시 확인할 때:

```powershell
.\Setup-Windows.cmd -CheckOnly
```

```sh
bash Setup-Mac.command --check-only
```

PC 다운로드만 준비하고 휴대폰은 건드리지 않을 때:

```powershell
.\Setup-Windows.cmd -PrepareOnly
```

```sh
bash Setup-Mac.command --prepare-only
```

ADB 실패, unauthorized/offline, 여러 폴드3 연결, 다른 모델, 해시 불일치, 앱 설치 미완료는 오류로 종료한다. 서명 충돌·버전 다운그레이드 오류가 나면 기존 앱을 자동 삭제하지 않는다. 폴드3 실기 설치와 차량 테스트는 아직 미검증이다.
