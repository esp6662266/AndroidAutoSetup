Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/../scripts/setup-windows.ps1" -LibraryOnly
$script:Listing = "List of devices attached`nWATCH:5555 device model:SM_L505N`nFOLD6 device model:SM_F956N`nemulator-5556 device model:SM_F926N`nFOLD3 device product:q2q model:SM_F926N device:q2q"
$script:Model = 'SM-F926N'; $script:Sdk = '35'; $script:Packages = ''
$script:Checks = 0
function Invoke-Adb([string[]]$Arguments) {
    switch ($Arguments -join ' ') {
        'start-server' { return '' }
        'devices -l' { return $script:Listing }
        '-s FOLD3 shell getprop ro.product.model' { return $script:Model }
        '-s FOLD6 shell getprop ro.product.model' { return $script:Model }
        '-s FOLD3 shell getprop ro.build.version.sdk' { return $script:Sdk }
        '-s FOLD3 shell getprop ro.build.version.release' { return '15' }
        default {
            if (($Arguments -join ' ') -like '*shell pm list packages --user 0 *') { return $script:Packages }
            if (($Arguments -join ' ') -like '*shell dumpsys package *') { return "versionName=1.9`ninstallerPackageName=com.android.vending" }
            throw "Unexpected ADB invocation: $($Arguments -join ' ')"
        }
    }
}
function Pass([string]$Label) { $script:Checks++; Write-Host "PASS: $Label" }
function Reject([scriptblock]$Action, [string]$Label) {
    $failed = $false
    try { & $Action | Out-Null } catch { $failed = $true }
    if (-not $failed) { throw "Unexpected success: $Label" }
    Pass $Label
}
Select-Fold3 ''
if ($script:TargetSerial -ne 'FOLD3') { throw 'Wrong selected device' }
Pass 'Fold3 selected; watch, Fold6, emulator excluded'
$script:Listing = 'FOLD3 unauthorized model:SM_F926N'; Reject { Select-Fold3 '' } 'unauthorized rejected'
$script:Listing = 'FOLD3 offline model:SM_F926N'; Reject { Select-Fold3 '' } 'offline rejected'
$script:Listing = "FOLD3 device model:SM_F926N`nSECOND device model:SM_F926B"
Reject { Select-Fold3 '' } 'multiple Fold3 devices rejected'
Select-Fold3 'FOLD3'; if ($script:TargetSerial -ne 'FOLD3') { throw 'Wrong explicit serial' }; Pass 'explicit serial selects one Fold3'
$script:Listing = 'FOLD6 device model:SM_F956N'; $script:Model = 'SM-F956N'
Reject { Select-Fold3 'FOLD6' } 'explicit serial cannot bypass model check'
$script:Listing = 'FOLD3 device model:SM_F926N'; $script:Model = 'SM-F926N'; $script:Sdk = '28'
Reject { Select-Fold3 '' } 'SDK below 29 rejected'
$script:Sdk = '35'; Select-Fold3 ''
$script:Packages = 'package:com.example.kinginstaller.debug'
if (Test-Package 'com.example.kinginstaller') { throw 'Package prefix matched' }; Pass 'package prefix is not an exact install match'
$script:Packages = "package:com.example.kinginstaller`npackage:com.fcaronte.aabrowser"
Confirm-Packages; Pass 'both installed packages verified'
$script:Packages = 'package:com.example.kinginstaller'; Reject { Confirm-Packages } 'missing browser is not reported complete'
$temp = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString())
try {
    $script:Root = $temp; New-Item -ItemType Directory -Path "$temp/cache" -Force | Out-Null
    Set-Content -LiteralPath "$temp/cache/fake.apk" -Value 'tampered'
    Set-Content -LiteralPath "$temp/downloads.tsv" -Value "id`tfilename`turl`tsha256`nking`tfake.apk`thttps://example.invalid/fake.apk`t0000"
    Reject { Get-VerifiedDownload 'king' } 'tampered cached APK rejected without executing/downloading'
} finally { Remove-Item -LiteralPath $temp -Recurse -Force }
Write-Host "$script:Checks checks passed"
