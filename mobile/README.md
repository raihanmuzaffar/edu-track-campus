# mobile

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

## Student Demo

Run the integrated student app in Chrome without login or a backend:

```powershell
flutter run -d chrome -t lib/mahasiswa_demo.dart
```

The demo uses local illustrative data and marks demo-only interactions. The
normal app entry point and API-backed feature screens remain unchanged.

## API configuration

The app reads `EDUTRACK_API_BASE_URL` at build time. Debug Android emulator
builds default to the local development API at
`http://10.0.2.2:8080/api/v1`; release builds have no default API URL and fail
closed unless a valid URL is supplied. For another approved environment, pass
its API URL explicitly:

```sh
flutter run --dart-define=EDUTRACK_API_BASE_URL="$EDUTRACK_API_BASE_URL"
```

For local development on a physical Android device, use the development
machine's reachable LAN API URL. HTTP is allowed only in debug builds. Release
builds require HTTPS and reject URL credentials, query strings, and fragments.
Cleartext HTTP is enabled only in the Android debug manifest; production builds
do not inherit that setting.
`10.0.2.2` is Android-emulator-specific and is not a valid iOS or physical-device
address.

## Android release prerequisites

The Gradle release build refuses to run unless the approved application ID and
all signing variables below are supplied through the build environment. The
API service refuses to send requests unless the release API URL is explicitly
provided and passes its HTTPS validation:

- `EDUTRACK_API_BASE_URL`: the owner-approved HTTPS API base URL ending in
  `/api/v1`, passed to Flutter with `--dart-define`.
- `EDUTRACK_ANDROID_APPLICATION_ID`: the approved, unique Android application
  ID (not `com.example.mobile`).
- `EDUTRACK_ANDROID_KEYSTORE_PATH`, `EDUTRACK_ANDROID_KEYSTORE_PASSWORD`,
  `EDUTRACK_ANDROID_KEY_ALIAS`, and `EDUTRACK_ANDROID_KEY_PASSWORD`: release
  signing configuration. Keep the keystore outside the repository and provide
  passwords only through a protected environment or CI secret store.

No production URL, application ID, keystore, or signing value is included in
this repository. These owner-provided prerequisites must be configured before
building or distributing a release APK. A release build made without the API
define cannot reach the backend and must not be distributed.

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
