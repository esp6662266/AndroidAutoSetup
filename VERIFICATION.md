# v1.0.0 검증 기록 — 2026-10-06

- macOS 기본 Bash 3.2: 기기 선택·실패 경로 모의 검사 11개 통과.
- PowerShell 7.6.6 / macOS: Windows 스크립트의 동일한 모의 검사 11개 통과. Windows 5.1 실제 실행과 구분한다.
- Mac 도구 prepare-only: Google ADB 37.0.1과 KingInstaller 2.3 / AABrowser 1.9 원본 다운로드, 고정 SHA-256 일치, ADB 실행 성공. 휴대폰에 변경을 가하지 않음.
- Mac check-only: 기기가 없는 상태에서 오류 종료. 설치 성공으로 보고하지 않음.
- PowerShell: Windows ADB 원본 다운로드와 고정 SHA-256 일치, 압축 해제 및 adb.exe/AdbWinApi.dll/AdbWinUsbApi.dll 존재 확인.
- Google Windows/Mac ZIP: SHA-1이 공식 repository2-3.xml의 platform-tools 37.0.1 체크섬과 일치. SHA-256은 downloads.tsv에 기록.
- APK: 각각의 GitHub 원본 release asset digest와 고정 SHA-256 일치.
- 배포 ZIP: APK·ADB·과거 휴대폰 캡처/설정·인증 키 미포함. 원본 배포처에서 첫 실행 시 다운로드.

미검증: Windows PowerShell 5.1 실기 실행, Windows PC에서 폴드3 USB 연결, 폴드3에서 실제 앱 설치/Android Auto 설정 저장/차량 화면 실행.

GitHub Actions 템플릿은 ci/validate.yml에 제공한다. 현재 GitHub OAuth 인증의 workflow 권한 부족으로 자동 검사 등록/실행은 하지 않았다. 템플릿은 Windows 5.1과 macOS 검사 및 실제 다운로드·ADB 실행 단계로 구성된다.
