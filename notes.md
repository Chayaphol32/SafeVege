# SafeVege Manuals Research Notes

วันที่ตรวจ: 17 ตุลาคม 2026

## Verified repository facts

- Repository root: `C:/Users/Chaya/verse/y4.1/wap/code/Flutter/SafeVege`
- Flutter app: `fn/safevege`
- PHP/MySQL backend: `bn`
- Flutter entry point: `fn/safevege/lib/main.dart`
- App state: `fn/safevege/lib/state/remote_app_state.dart`
- API client: `fn/safevege/lib/data/api/api_client.dart`
- Repository layer: `fn/safevege/lib/data/repositories/safevege_repository.dart`
- Backend entry point: `bn/public/index.php`
- Schema: `bn/schema.sql`
- ER diagram: `bn/ER.md`
- Backend setup and endpoint notes: `bn/README.md`
- Safe Admin operations: `bn/docs/super-admin-operations.md`
- Thai font asset: `fn/safevege/assets/fonts/NotoSansThai-Variable.ttf`
- App version in `fn/safevege/pubspec.yaml`: `1.0.0+1`

## Product behavior evidence

- Public users can browse public shops, inspect shop details, view published certificates, and use map/route features.
- Shop users can register/login, edit shop data, choose a location, submit multiple vegetables for inspection, and track requests.
- Inspector Admin handles requests, appointments, results, certificate upload, publication, and shop management.
- Super Admin handles user accounts, role/active state, password resets, audit events, and allow-listed settings.
- API paths are prefixed with `/api/v1`; private calls use `Authorization: Bearer <token>`.
- The schema uses MySQL 5.7+, InnoDB, `utf8mb4`, prefixed physical column names, and compatibility views with API-shaped names.
- Certificate files are stored outside MySQL; `certificates.file_path` is an internal storage reference.
- Map tiles use OpenStreetMap and route calculation uses OSRM; the app configuration documents no API key requirement for those services.

## Evidence boundaries

- The manuals describe the current repository state, not a promise of production readiness.
- Existing README content says schema changes must be reviewed before applying to populated older data.
- Local demo credentials may be described only as development-only sample data; no secret from a real `.env` is included.
- Fresh Flutter analyzer/test/build execution is not required to author the manuals, but the developer manual must point to the repository's available test commands and distinguish documented commands from commands run during this task.
