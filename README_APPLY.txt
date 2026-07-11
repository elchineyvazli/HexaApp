HEXA — FIREBASE WEB DEPENDENCY FIX

WHY THIS PATCH EXISTS
The current lockfile resolves an old mixed FlutterFire web stack:
- firebase_auth_web 5.8.13
- firebase_storage_web 3.6.22
- firebase_core_web 2.24.0

On Flutter 3.38 / Dart 3.10 this produces PromiseJsImpl, handleThenable,
dartify and jsify compilation errors.

FILES
1. pubspec.yaml
2. FIX_FIREBASE_WEB.ps1
3. README_APPLY.txt

APPLY
1. Copy pubspec.yaml to the project root and replace the existing file.
2. Copy FIX_FIREBASE_WEB.ps1 to the project root.
3. Open PowerShell in the project root.
4. Run:

   Set-ExecutionPolicy -Scope Process Bypass
   .\FIX_FIREBASE_WEB.ps1

5. Then run:

   flutter run -d chrome

IMPORTANT
- Do not copy the old pubspec.lock back.
- The script creates pubspec.lock.before_flutterfire_fix.bak and then
  regenerates a fresh pubspec.lock.
- Do not edit Pub Cache package source files manually.
- No Firebase Console action is required for this dependency repair.
- google_sign_in stays on 6.3.0 intentionally so the current AuthService
  keeps compiling without an API migration.

IF PUB GET FAILS
Run and send the complete output:

   flutter pub get -v

IF CHROME BUILDS BUT GOOGLE LOGIN FAILS
Send only the browser console error and the current:
- lib/features/auth/application/auth_service.dart
- web/index.html
- lib/firebase_options.dart
