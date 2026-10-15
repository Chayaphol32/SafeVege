# SafeVege API Integration Plan

## Authorization and scope

The user has explicitly asked to connect the Flutter app to the PHP API. This replaces the earlier UI-only/mock-data phase. Implement the existing REST contract in `bn/README.md` and `bn/src/routes`; do not change MySQL table naming or invent endpoints without a concrete UI/API gap.

## Verified current state

- PHP API health responds `{"status":"ok"}` at `http://127.0.0.1:8081/api/v1/health`.
- API routes cover public shop search/detail/certificates, shop registration/login/session/profile/requests, and admin shops/requests/appointments/results/certificate upload/publication.
- Flutter already has the `http` dependency but has no API client; `AppConfig` points to a placeholder host.
- Guest, shop, and admin screens currently consume seeded mock records. Login actions still enter demo mode, and registration/request/admin actions mutate `AppState` locally.
- The backend's admin shop-create endpoint requires an existing `owner_user_id`; the current admin UI's add-shop behavior must be checked before adapting it. Do not silently submit incomplete account data.

## Intended design

1. Add a typed REST client/repository under `lib/data/` using the existing `http` package. It must support JSON, bearer tokens, multipart certificate uploads, authenticated downloads, request timeouts, and consistent user-safe errors.
2. Store the session token through platform secure storage; keep credentials out of app state, logs, source, and preferences. Restore sessions with `GET /me`; log out through the API and clear the token.
3. Make `AppState` the UI-facing source of remote data. Remove seeded shop/request records. Add loading/error state and async refresh/login/register/profile/request/admin actions; parse server IDs and statuses without inventing results.
4. Wire the existing screens to the endpoints: public shop search and details; shop register/login/profile/request list/create; admin login/shop list/request list/detail/scheduling/results/certificate upload/publication/history. A guest certificate file is opened through its public file endpoint; protected files use bearer-authenticated download.
5. Make API base URL configurable with `--dart-define=API_BASE_URL=...`. Default local Android emulator runs to `http://10.0.2.2:8081/api/v1`; document host/browser and physical-device overrides. Do not add secrets to the config.
6. Write failing tests first for JSON mapping, request headers and bodies, error decoding, auth/session behavior, and server-status mapping; then implement and run Flutter tests/analyzer/build. Run PHP schema and integration tests if the configured local PHP runtime is available.

## API-to-app mappings

- `submitted` → pending; `scheduled` → scheduled; `inspected` and `published` → completed; `cancelled` needs an explicit cancelled state in the app model so it remains visible in admin history.
- `passed`/`failed`/`inconclusive` → true/false/null while preserving the raw outcome for display and resubmission safety.
- Backend integer IDs are represented as strings in existing Flutter models.
- Backend timestamps are parsed as UTC and displayed in local time; appointment timestamps are sent as UTC `YYYY-MM-DD HH:MM:SS`.
- Admin recording is a sequence supported by the API: save results, upload the certificate with the resulting passing revision IDs, then publish. If the certificate is absent, preserve the `inspected` state instead of showing a false publication.

## Constraints and open API/UI gap

- The current `CORS_ORIGIN` example is `http://localhost:3000`; verify the active local origin before relying on Flutter Web. Android emulator requests use `10.0.2.2` to reach the host PHP server.
- Registration requires coordinates and a 12-character password. Replace the form's fixed sample coordinates with a real map selection or location result; never submit mock coordinates.
- The current admin shop-create UI does not appear to have an owner account ID. Inspect it before implementation. If it cannot express the existing endpoint contract, either adapt the UI to select an existing owner or add a separately tested, secure admin account-creation API route with required username/password fields.

## Delivery phases

1. REST client, secure token store, DTO mapping, and unit tests.
2. Guest and authentication flows.
3. Shop profile and inspection requests.
4. Admin request lifecycle, certificate upload/publish, and shop management.
5. Error/loading/empty states and end-to-end verification against the running local API.
