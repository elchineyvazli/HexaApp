$ErrorActionPreference = "Stop"

Write-Host "Hexa FlutterFire dependency cleanup starting..." -ForegroundColor Magenta

if (-not (Test-Path "pubspec.yaml")) {
  throw "Run this script from the Flutter project root (the folder containing pubspec.yaml)."
}

if (Test-Path "pubspec.lock") {
  Copy-Item "pubspec.lock" "pubspec.lock.before_flutterfire_fix.bak" -Force
  Remove-Item "pubspec.lock" -Force
}

if (Test-Path ".dart_tool") {
  Remove-Item ".dart_tool" -Recurse -Force
}

if (Test-Path "build") {
  Remove-Item "build" -Recurse -Force
}

flutter clean
flutter pub get

Write-Host ""
Write-Host "Resolved FlutterFire packages:" -ForegroundColor Cyan
flutter pub deps --style=compact |
  Select-String -Pattern "firebase_core |firebase_auth |cloud_firestore |firebase_storage "

Write-Host ""
Write-Host "Running analyzer..." -ForegroundColor Cyan
flutter analyze

Write-Host ""
Write-Host "Dependency cleanup completed." -ForegroundColor Green
Write-Host "Next command: flutter run -d chrome" -ForegroundColor Yellow
