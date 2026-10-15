# SafeVege database draft

This folder contains the MySQL schema and the PHP REST API used by the Flutter app. The Flutter app reads and writes shops, accounts, inspection requests, results, and certificates through these endpoints.

On this development computer, the `safevege` database has been rebuilt with prefixed column names. For example, `users.use_id`, `users.use_username`, and `users.use_password`. Local MAMP connection settings are in the ignored `.env` file; keep that file private.

## Files

- `schema.sql` creates the `safevege` database and its tables on MySQL 5.7 or newer.
- `ER.md` shows the relationships.
- `public/index.php` is the only web entry point. Keep `src`, `.env`, and `storage` outside the web document root.
- `column_map.md` lists every column rename.
- The physical tables use prefixed columns. Internal `api_*` views expose the existing API field names, so API clients do not need to change their JSON format.

## Apply to a new local database

Run with a MySQL account that can create a database:

```powershell
Get-Content -Raw .\schema.sql | & 'C:\MAMP\bin\mysql\bin\mysql.exe' --user=<your-user> --password
```

MySQL prompts for the password. Do not put credentials in this repository or commit a populated database dump.

## Design decisions to review

- One shop account may own multiple shops. `shops.owner_user_id` references `users`.
- A request contains multiple vegetables in `inspection_request_items`.
- Each vegetable can have multiple result revisions. Existing results are retained.
- Appointment changes are retained as separate records; the newest record is current.
- A certificate can reference selected result revisions through `certificate_results`.
- Public shops and certificates have explicit visibility flags. The backend must enforce publication rules; the database does not assume that every passing result makes a shop public.
- File contents are stored outside MySQL. `certificates.file_path` is an internal storage reference, not a public URL.
- `audit_events.details` is for nonsecret change metadata only.

No account passwords, API keys, or production data are included. The old `admin`, `shops`, `requests`, and `results` data has not been migrated. Resolve publication criteria, certificate validity, and migration rules before moving old records into this schema.

## Run the API locally

1. On another computer, create the tables and internal views with `schema.sql` on a fresh database. Do not apply this script to a populated older schema without a data migration.
2. On another computer, copy `.env.example` to `.env` and enter the MySQL user and password. Do not commit `.env`.
3. Run PHP 8.1 or newer with the MySQL PDO extension. With MAMP on this machine:

```powershell
& 'C:\MAMP\bin\php\php8.3.1\php.exe' -c 'C:\MAMP\conf\php8.3.1\php.ini' -S 127.0.0.1:8081 -t .\public .\public\index.php
```

Run that command from `bn`. Check `http://127.0.0.1:8081/api/v1/health` after entering database settings. The server binds to the local computer only.

### Connect Flutter web and mobile to the same API

For local development, run the Flutter web app on the origin allowed by `CORS_ORIGIN`:

```powershell
Set-Location ..\fn\safevege
flutter run -d chrome --web-port 3000
```

The web debug build uses `http://127.0.0.1:8081/api/v1`. Android Emulator uses `http://10.0.2.2:8081/api/v1`, which reaches the same API on the development computer. Other local targets use loopback. `CORS_ORIGIN` accepts a comma-separated list of exact origins; include the exact website origin and never use `*`.

For release builds, configure both platforms with the same reachable HTTPS API URL:

```powershell
flutter build web --release --dart-define=API_BASE_URL=https://api.your-domain.example/api/v1
flutter build apk --release --dart-define=API_BASE_URL=https://api.your-domain.example/api/v1
```

Set `CORS_ORIGIN` on the API server to the exact deployed website origin, such as `https://safevege.your-domain.example`. Physical phones must use a LAN-reachable or public HTTPS API URL; emulator and loopback addresses point to the phone itself.

Create the first Inspector Admin or Super Admin with `scripts/create_admin.php` after setting `SAFEVEGE_ADMIN_PASSWORD` in your terminal environment. The password must have at least 12 characters and is stored as a hash. There is no default password and no bootstrap secret in the Flutter app:

```powershell
$env:SAFEVEGE_ADMIN_PASSWORD = '<choose-a-12-plus-character-password>'
& 'C:\MAMP\bin\php\php8.3.1\php.exe' -c 'C:\MAMP\conf\php8.3.1\php.ini' scripts/create_admin.php --role=super_admin root-admin 'SafeVege System Owner'
Remove-Item Env:SAFEVEGE_ADMIN_PASSWORD
```

For an existing database, apply `migrations/2026-10-14-super-admin-access.sql` before using the Super Admin screens. Keep the migration and the server-side creation command on the server; never put the password in source control.

The `super_admin` account is the real system administrator. It can open the special console, see all inspection/shop data, create Inspector Admin accounts, enable or disable accounts, reset shop or Inspector Admin passwords, review audit events, and update the allow-listed system settings. The existing `admin` role remains the Inspector Admin who performs inspection work. OTP recovery has been removed; an authenticated Super Admin resets another account's password through the console, while each signed-in user can change their own password.

## Load local demo data

With the local API and `safevege` MySQL database configured, run this from `bn`:

```powershell
& 'C:\MAMP\bin\php\php8.3.1\php.exe' -c 'C:\MAMP\conf\php8.3.1\php.ini' scripts/seed_demo.php --local-demo
```

The seeder only runs from CLI against a loopback database named `safevege`. It is safe to run again: it updates its own marked demo rows without adding duplicates and refuses to overwrite accounts that are not identified as SafeVege demo users. It creates three demo accounts, three public shops, five requests across review states, two published demo certificates, and a sample PDF visibly marked as invalid for real certification.

Demo login password: `DemoSafeVege!2026`. Usernames: `demo_admin`, `demo_shop`, and `demo_market`. Search the public API for `DEMO` to see the sample shops. Keep these accounts and records for local testing only.

Run `tests/demo_seed_test.php` to verify seeding is idempotent and the demo accounts, shops, requests, certificate directory, and sample PDF are available through the API.

## Main endpoints

All paths start with `/api/v1`. JSON requests use `Content-Type: application/json`. Private endpoints use `Authorization: Bearer <token>`.

| Method | Path | Access | Purpose |
| --- | --- | --- | --- |
| GET | `/health` | Public | Database readiness |
| POST | `/auth/register` | Public | Create shop account and shop |
| POST | `/auth/login`, `/auth/logout` | Public / signed in | Start or end a session |
| GET | `/me` | Signed in | Current account |
| GET | `/shops?q=&lat=&lng=&radius_km=` | Public | Search and nearby public shops |
| GET | `/shops/{id}`, `/shops/{id}/certificates` | Public | Shop details and public certificates |
| GET | `/certificates` | Public | Directory of valid published certificates |
| GET | `/certificates/{id}/file` | Public if published; otherwise owner or admin | View PDF/JPG |
| GET | `/my/shops`, `/my/requests`, `/my/requests/{id}` | Shop | Own data |
| PATCH | `/my/shops/{id}` | Shop | Edit own shop |
| POST | `/my/shops/{id}/requests` | Shop | Submit multiple vegetables |
| GET | `/admin/shops`, `/admin/requests`, `/admin/requests/{id}` | Admin | Review records |
| GET | `/admin/users`, `/admin/audit` | Super Admin | View all accounts and administrator activity |
| POST | `/admin/users` | Super Admin | Create an Inspector Admin or another Super Admin (with current-password confirmation) |
| PATCH | `/admin/users/{id}` | Super Admin | Edit display name, role, or active state |
| POST | `/admin/users/{id}/password` | Super Admin | Reset a shop or admin password and revoke its sessions |
| GET / PATCH | `/admin/settings` | Super Admin | Read or update allow-listed system settings |
| POST / PATCH / DELETE | `/admin/shops` / `/admin/shops/{id}` | Admin | Create shop accounts, edit shops, or remove shops without inspection history |
| POST | `/admin/requests/{id}/appointment` | Admin | Set appointment |
| POST | `/admin/requests/{id}/results` | Admin | Record result revisions |
| POST | `/admin/requests/{id}/certificates` | Admin | Upload PDF/JPG, multipart form |
| POST | `/admin/requests/{id}/publish` | Admin | Publish verified records |

Example request body for `POST /my/shops/{id}/requests`:

```json
{"address_snapshot":"อ.เมืองเชียงราย จ.เชียงราย","vegetables":["คะน้า","ผักกาดหอม"],"latitude":19.9100000,"longitude":99.8300000}
```

Admin dates use UTC `YYYY-MM-DD HH:MM:SS`; the UI should convert to the user's local timezone. Certificate upload accepts `certificate_no`, `issued_at` (`YYYY-MM-DD`), optional `expires_at`, `result_ids` as a JSON array string, and `file` as PDF or JPG up to 5 MB.

Flutter uses the API base URL in `API_BASE_URL`. Local MySQL endpoint tests require database credentials in `.env` and an imported schema.

With the local development server running on port 8081, run the end-to-end test with `php -c <php.ini> tests/integration.php` from `bn`. It creates temporary shop/admin records, exercises the workflow, and removes those records and its temporary certificate file afterward.

Run `tests/schema_naming.php` to confirm every physical table column uses its table prefix. `use_password` holds a password hash, not a plain password.
