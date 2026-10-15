# Cross-Platform API Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make web and mobile use the same SafeVege API capabilities, with safe platform-specific local development defaults and one explicit backend URL for release builds.

**Architecture:** Flutter resolves `API_BASE_URL` first, then uses loopback for browser/iOS/desktop development and Android Emulator host routing for Android development. Release builds fail clearly if the shared API URL is missing. The PHP API keeps exact-origin CORS and accepts a comma-separated origin allowlist.

**Tech Stack:** Flutter/Dart, PHP 8.1+, Flutter unit tests, standalone PHP tests.

## Global Constraints

- All app data continues to flow through the existing `ApiClient` and shared `AppState`.
- Do not use wildcard CORS; allow only exact configured origins.
- Production web and mobile builds use the same HTTPS API URL through `--dart-define=API_BASE_URL=...`.
- Local development defaults must not be treated as production endpoints.

---

### Task 1: Resolve the API endpoint per platform

**Files:**
- Create: `fn/safevege/test/config/api_endpoint_test.dart`
- Create: `fn/safevege/lib/config/api_endpoint.dart`
- Modify: `fn/safevege/lib/config/app_config.dart`

**Interfaces:**
- Produces `resolveApiBaseUrl({required String configuredUrl, required bool isWeb, required bool isAndroid, required bool isRelease}) -> String`.
- `AppConfig.apiBaseUrl` remains the shared API entry used by `AppState`.

- [x] **Step 1: Write failing resolver tests** for the web loopback default, Android Emulator default, shared explicit override, and release failure without configuration.
- [x] **Step 2: Run `flutter test test/config/api_endpoint_test.dart`** from `fn/safevege`; it failed because the resolver did not exist.
- [x] **Step 3: Implement the resolver** so a trimmed nonempty override wins; otherwise release mode throws a clear `StateError`; otherwise web and non-Android use `http://127.0.0.1:8081/api/v1`, while Android uses `http://10.0.2.2:8081/api/v1`.
- [x] **Step 4: Wire `AppConfig.apiBaseUrl`** to `String.fromEnvironment('API_BASE_URL')`, `kIsWeb`, Android platform detection, and `kReleaseMode`.
- [x] **Step 5: Run the focused Flutter test** and confirm all endpoint-selection cases pass.

### Task 2: Make the PHP CORS allowlist configurable for both app origins

**Files:**
- Create: `bn/tests/cors_policy_test.php`
- Modify: `bn/src/helpers.php`
- Modify: `bn/public/index.php`
- Modify: `bn/.env.example`

**Interfaces:**
- Produces `cors_allowed_origin(?string $origin, ?string $configuredOrigins): ?string`.
- `CORS_ORIGIN` accepts one or more exact comma-separated origins and remains compatible with a single existing origin.

- [x] **Step 1: Write failing PHP policy tests** for a matching origin, a second matching origin in a list, an unlisted origin, a missing request origin, and an empty allowlist.
- [x] **Step 2: Run `php tests/cors_policy_test.php`** from `bn`; it failed because the policy function did not exist.
- [x] **Step 3: Implement exact-origin matching** in `helpers.php`; do not reflect unlisted origins and do not permit `*`.
- [x] **Step 4: Use the policy in `public/index.php`** before normal route handling so preflight and API responses include the allow headers only for approved origins.
- [x] **Step 5: Update `.env.example`** with local web origins `http://localhost:3000,http://127.0.0.1:3000` and document the production web origin setting.
- [x] **Step 6: Run the PHP policy test** and verify preflight returns `Access-Control-Allow-Origin` for approved origins only.

### Task 3: Document shared release configuration and verify both builds

**Files:**
- Modify: `bn/README.md`
- Modify: `fn/safevege/README.md` if present; otherwise do not create a second setup document.

- [x] **Step 1: Document local development** using `flutter run -d chrome --web-port=3000` and the Android Emulator defaults.
- [x] **Step 2: Document shared production configuration** with the same `API_BASE_URL` HTTPS value for both web and mobile builds, plus the exact website origin in backend `CORS_ORIGIN`.
- [x] **Step 3: Run focused Dart and PHP tests**, then the full Flutter test suite and analyzer.
- [x] **Step 4: Build both targets with an API URL**: web release with `http://127.0.0.1:8081/api/v1` and Android debug with `http://10.0.2.2:8081/api/v1`.
- [x] **Step 5: Report that the real production API URL/origin must still be supplied at release build/deployment time because none is configured in the workspace.**
