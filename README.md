# AndroidAutoSetup — 폴드3 Mac / Windows 설치 도우미

KingInstaller와 AABrowser는 **Android 앱**이다. 이 저장소는 Windows·Mac에서 폴드3로 APK를 준비·전송하고 휴대폰 설치 및 설정을 안내하는 PC 도구다.

- Windows: `Setup-Windows.cmd` / PowerShell 5.1, Windows 10·11.
- Mac: `Setup-Mac.command` / 기본 Bash 3.2, Intel·Apple Silicon.
- 공통: 폴드3 SM-F926 계열만 선택, Android 버전 확인, 고정된 공식 배포 파일 SHA-256 검사, 설치 결과 확인.
- 기본 조합: **KingInstaller 2.3 + AABrowser 1.9**. 2026-10-04에 사용자의 폴드6에서 사용한 조합에 맞춘다. 2026-10-06 확인 시 AABrowser 최신 배포는 2.1이지만 이 도구는 자동으로 버전을 바꾸지 않는다.
- 주차/정차 상태의 테스트용. 운전 중 영상·브라우저 사용이나 차량 안전 제한 해제 절차는 제공하지 않는다.

[한국어 설치 안내](GUIDE-KO.md)를 따라 GitHub Releases의 OS별 ZIP을 받아 압축을 풀어 실행한다. 첫 다운로드에 인터넷과 Google SDK 약관 동의가 필요하다. PC 스크립트는 관리자 권한·Python·Android Studio를 요구하지 않는다. Windows 삼성 USB 드라이버 설치는 별도다.

## 실행과 확인의 구분

PC가 자동으로 처리하는 것: 공식 파일 다운로드/해시 확인, 폴드3 모델·SDK 확인, KingInstaller 설치, AABrowser 파일 전송, 앱 설치 여부·버전·설치 출처 조회, Android Auto 설정 화면 열기.

휴대폰에서 마치는 것: USB 디버깅 RSA 허용, 설치 출처/파일 접근 허용, KingInstaller를 통한 AABrowser 설치, 초기 설정과 기능 권한, Android Auto 개발자 모드/알 수 없는 소스/런처 표시 확인.

PC가 “설치 확인”을 출력해도 Android Auto 개발자 설정 저장이나 차량 화면 실행을 확인한 것은 아니다. 루팅, Shizuku 자동 설정, 모든 권한 일괄 허용, 재부팅, 다른 앱 삭제, 보안 경고 자동 무시는 수행하지 않는다.

## 검증

`tests/test-mac.sh`와 `tests/test-windows.ps1`은 실제 휴대폰을 사용하지 않고 연결 목록/패키지 결과를 모의한다. 워치·폴드6·에뮬레이터 제외, 모델 재확인, unauthorized/여러 기기/낮은 SDK 실패, 패키지명 정확 일치 및 설치 누락 실패를 검증한다. 자동 검사 템플릿 `ci/validate.yml`은 Windows PowerShell 5.1과 macOS에서 이 검사와 공식 파일 다운로드·해시 검사·ADB 실행을 수행하도록 작성했다. 현재 GitHub 인증에 workflow 권한이 없어 실제 Actions 등록/실행은 하지 않았다. 필요하면 GitHub 웹에서 이 파일을 `.github/workflows/validate.yml`로 등록할 수 있다.

2026-10-06: Mac Bash 3.2의 모의 검사 11개, PowerShell 7.6.6(macOS)에서 Windows 스크립트 모의 검사 11개 통과. Mac의 실제 공식 파일 다운로드/해시 검사/ADB 실행을 확인했고, PowerShell의 Windows 파일 다운로드/해시 검사/압축 해제도 확인했다. Windows 5.1 실제 실행과 폴드3 USB 연결·휴대폰 설치·차량 실행은 아직 검증하지 않았다. 과거 폴드6의 기기 캡처·개인 설정은 저장소와 배포 파일에 포함하지 않는다. `cache/`, `runtime/`, `artifacts/`는 Git에서 제외한다.

## 원본 출처

- [KingInstaller 2.3 원본](https://github.com/fcaronte/KingInstaller/releases/tag/2.3), [소스](https://github.com/fcaronte/KingInstaller/tree/2.3) — GPL-3.0.
- [AABrowser 1.9 원본](https://github.com/fcaronte/AABrowser/releases/tag/1.9), [소스](https://github.com/fcaronte/AABrowser/tree/1.9) — MIT.
- [Google SDK Platform-Tools](https://developer.android.com/tools/releases/platform-tools) — 37.0.1, Google SDK 약관 및 포함된 NOTICE 적용. Windows/Mac ZIP SHA-1을 공식 SDK 저장소 메타데이터와 대조한 후 SHA-256을 `downloads.tsv`에 고정했다.
- [삼성 공식 Windows USB 드라이버](https://developer.samsung.com/galaxy/others/android-usb-driver-for-windows).

APK/Google SDK 바이너리는 이 저장소의 소스나 배포 ZIP에 포함하지 않는다. 각 PC가 원본 배포처에서 직접 다운로드한다. 이 도우미의 자체 작성 스크립트·문서에는 [MIT 라이선스](LICENSE)를 적용하며 외부 앱·SDK의 라이선스는 그대로 유지된다.
