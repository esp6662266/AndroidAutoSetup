[CmdletBinding()]
param([switch]$PrepareOnly, [switch]$CheckOnly, [string]$Serial = '', [switch]$AcceptSdkLicense, [switch]$LibraryOnly)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:Root = Split-Path $PSScriptRoot -Parent
$script:Adb = ''
$script:TargetSerial = ''
function Get-VerifiedDownload([string]$Id) {
    $rows = @(Import-Csv -LiteralPath (Join-Path $script:Root 'downloads.tsv') -Delimiter "`t" | Where-Object { $_.id -eq $Id })
    if ($rows.Count -ne 1) { throw "다운로드 항목 없음: $Id" }
    $item = $rows[0]
    $cache = Join-Path $script:Root 'cache'
    New-Item -ItemType Directory -Force -Path $cache | Out-Null
    $file = Join-Path $cache $item.filename
    if (-not (Test-Path -LiteralPath $file)) {
        Write-Host "다운로드: $($item.filename)"
        $part = "$file.part"
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -UseBasicParsing -Uri $item.url -OutFile $part -TimeoutSec 180
            if ((Get-FileHash -LiteralPath $part -Algorithm SHA256).Hash.ToLowerInvariant() -ne $item.sha256) { throw '해시 불일치. 실행하지 않습니다.' }
            Move-Item -LiteralPath $part -Destination $file -Force
        } finally { if (Test-Path -LiteralPath $part) { Remove-Item -LiteralPath $part -Force } }
    }
    if ((Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant() -ne $item.sha256) { throw "$($item.filename) 해시 불일치. cache 파일을 삭제하고 다시 받으세요." }
    return $file
}
function Initialize-Tools([bool]$Accept) {
    $marker = Join-Path $script:Root 'cache/sdk-license-accepted'
    if (-not $Accept -and -not (Test-Path -LiteralPath $marker)) {
        Write-Host "ADB는 Google Android SDK 약관에 따라 사용합니다.`nhttps://developer.android.com/tools/releases/platform-tools#downloads"
        if ((Read-Host '약관을 확인하고 동의하면 Y') -notmatch '^[Yy]$') { throw '동의하지 않아 다운로드를 중지했습니다.' }
    }
    New-Item -ItemType Directory -Force -Path (Join-Path $script:Root 'cache') | Out-Null
    Set-Content -LiteralPath $marker -Value 'accepted' -Encoding ASCII
    $archive = Get-VerifiedDownload 'windows'
    $runtime = Join-Path $script:Root 'runtime'
    Expand-Archive -LiteralPath $archive -DestinationPath $runtime -Force
    $script:Adb = Join-Path $runtime 'platform-tools/adb.exe'
    Get-VerifiedDownload 'king' | Out-Null
    Get-VerifiedDownload 'browser' | Out-Null
    Invoke-Adb @('version') | Write-Host
}
function Invoke-Adb([string[]]$Arguments) {
    $previous = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = @(& $script:Adb @Arguments 2>&1)
        $code = $LASTEXITCODE
    } finally { $ErrorActionPreference = $previous }
    if ($code -ne 0) { throw "ADB 실패 ($code): $($output -join '`n')" }
    return ($output -join "`n")
}
function Invoke-Phone([string[]]$Arguments) { Invoke-Adb (@('-s', $script:TargetSerial) + $Arguments) }
function Select-Fold3([string]$Wanted) {
    Invoke-Adb @('start-server') | Out-Null
    $listing = Invoke-Adb @('devices', '-l')
    $eligible = @()
    foreach ($line in ($listing -split "`r?`n")) {
        if ($line -notmatch '^(\S+)\s+device\s+(.*)$') { continue }
        $candidate = $Matches[1]; $details = $Matches[2]
        if ($candidate -like 'emulator-*' -or $candidate.Contains(':')) { continue }
        if ($Wanted) { if ($candidate -ne $Wanted) { continue } }
        elseif ($details -notmatch 'model:SM[_-]F926[A-Za-z0-9]*($|\s)') { continue }
        $eligible += $candidate
    }
    if ($eligible.Count -ne 1) { throw '인증된 폴드3 한 대만 USB로 연결하세요. USB 디버깅/RSA 허용과 삼성 드라이버를 확인하세요. 여러 대면 -Serial SERIAL을 사용하세요.' }
    $script:TargetSerial = $eligible[0]
    $model = (Invoke-Phone @('shell','getprop','ro.product.model')).Trim()
    if ($model -notmatch '^SM[_-]F926[A-Za-z0-9]+$') { throw "대상이 폴드3가 아닙니다: $model" }
    $apiText = (Invoke-Phone @('shell','getprop','ro.build.version.sdk')).Trim()
    $api = 0
    if (-not [int]::TryParse($apiText, [ref]$api) -or $api -lt 29) { throw 'Android 10(API 29) 이상이 필요합니다.' }
    $android = (Invoke-Phone @('shell','getprop','ro.build.version.release')).Trim()
    Write-Host "대상: $model / Android $android (API $api)"
}
function Test-Package([string]$Package) {
    $listing = Invoke-Phone @('shell','pm','list','packages','--user','0',$Package)
    return (($listing -split "`r?`n") -contains "package:$Package")
}
function Confirm-Packages {
    foreach ($package in @('com.example.kinginstaller','com.fcaronte.aabrowser')) {
        if (-not (Test-Package $package)) { throw "$package 미설치. KingInstaller에서 설치를 마친 다음 다시 확인하세요." }
        $info = Invoke-Phone @('shell','dumpsys','package',$package)
        Write-Host "`n$package"
        $info -split "`r?`n" | Where-Object { $_ -match 'versionName=|installerPackageName=|initiatingPackageName=|originatingPackageName=' } | ForEach-Object { Write-Host $_ }
    }
    Write-Host "`n휴대폰 앱 설치를 확인했습니다. Android Auto 설정과 차량 화면 실행 확인은 별도입니다."
}
function Install-Fold3 {
    $king = Get-VerifiedDownload 'king'; $browser = Get-VerifiedDownload 'browser'
    Invoke-Phone @('install','-r',$king) | Write-Host
    if (-not (Test-Package 'com.example.kinginstaller')) { throw 'KingInstaller 설치 결과를 확인하지 못했습니다.' }
    Invoke-Phone @('push',$browser,'/sdcard/Download/AABrowser-v1.9.apk') | Write-Host
    Invoke-Phone @('shell','am','start','-a','android.settings.MANAGE_UNKNOWN_APP_SOURCES','-d','package:com.example.kinginstaller') | Out-Null
    Write-Host "`n휴대폰: KingInstaller의 이 출처 허용을 켜 주세요."
    Read-Host '허용 후 Enter' | Out-Null
    Invoke-Phone @('shell','am','start','-n','com.example.kinginstaller/.MainActivity') | Out-Null
    Write-Host "`n휴대폰: KingInstaller → APK 선택 → Download/AABrowser-v1.9.apk → 일반 설치.`n모든 파일 접근을 요청하면 필요한 설정을 확인하세요. 기존 AABrowser가 더 최신이면 다운그레이드하지 마세요.`n설치 경고가 나오면 내용을 확인하고 휴대폰에서 결정하세요."
    Read-Host '휴대폰 설치 완료 후 Enter' | Out-Null
    Confirm-Packages
    if (Test-Package 'com.google.android.projection.gearhead') {
        try { Invoke-Phone @('shell','am','start','-a','com.google.android.projection.gearhead.SETTINGS','-p','com.google.android.projection.gearhead') | Out-Null }
        catch { Write-Host '휴대폰 설정에서 Android Auto를 검색해 여세요.' }
    } else { Write-Host 'Android Auto를 Play Store에서 설치/업데이트하세요.' }
    Write-Host "`n마지막 휴대폰 설정은 GUIDE-KO.md의 4번을 따라 확인하세요.`nPC 도구는 Android Auto 개발자 설정의 저장 여부를 판정하지 않습니다."
}
if (-not $LibraryOnly) {
    try {
        if ($env:OS -ne 'Windows_NT') { throw 'Windows용 스크립트입니다.' }
        if ($PrepareOnly -and $CheckOnly) { throw '-PrepareOnly와 -CheckOnly는 함께 사용할 수 없습니다.' }
        Initialize-Tools ([bool]$AcceptSdkLicense)
        if ($PrepareOnly) { Write-Host '준비 완료. 휴대폰은 변경하지 않았습니다.'; exit 0 }
        Select-Fold3 $Serial
        if ($CheckOnly) { Confirm-Packages } else { Install-Fold3 }
    } catch { Write-Host "오류: $($_.Exception.Message)" -ForegroundColor Red; exit 1 }
}
