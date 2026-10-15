# Connect SafeVege to the local PHP API

The PHP server documented in `../../../bn/README.md` listens on the host computer at `127.0.0.1:8081`. The Flutter debug build defaults to the Android emulator bridge URL `http://10.0.2.2:8081/api/v1`.

For an Android emulator, run Flutter with the default or pass the URL explicitly:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8081/api/v1
```

For Flutter Web or a Windows desktop build on the same computer, use:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8081/api/v1
```

For a physical phone, use the computer's LAN address instead of `10.0.2.2` and allow that port through the local firewall. Flutter Web also requires the PHP API's `CORS_ORIGIN` setting to match the exact browser origin.

The Android clear-text HTTP exception exists only in the debug manifest. Release builds must use an HTTPS API URL. Do not put database credentials, bearer tokens, or Longdo API keys in this file or in Dart source.
