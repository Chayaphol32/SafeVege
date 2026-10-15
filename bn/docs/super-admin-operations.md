# SafeVege Super Admin operations

## Bootstrap the first Super Admin

The role is granted by the API database, not by a hidden password or gesture in Flutter. Run the server-side utility from `bn` with a password supplied only through the current shell:

```powershell
$env:SAFEVEGE_ADMIN_PASSWORD = '<choose-a-12-plus-character-password>'
& 'C:\MAMP\bin\php\php8.3.1\php.exe' -c 'C:\MAMP\conf\php8.3.1\php.ini' scripts/create_admin.php --role=super_admin root-admin 'SafeVege System Owner'
Remove-Item Env:SAFEVEGE_ADMIN_PASSWORD
```

Use a unique production password manager-generated password. Do not commit the command with a real password, set a default password, or copy the password into the mobile/web bundle.

For an existing installation, apply the migration first:

```powershell
Get-Content -Raw .\migrations\2026-10-14-super-admin-access.sql |
  & 'C:\MAMP\bin\mysql\bin\mysql.exe' --user=<your-user> --password safevege
```

Fresh databases receive the same role and `app_settings` definitions from `schema.sql`.

## What the console can do

- Open the Super Admin console after a successful `super_admin` login.
- Link to the existing inspection dashboard, which includes all shops, requests, results, certificates, appointments, and publishing actions allowed to administrators.
- Create Inspector Admin accounts with passwords of at least 12 characters.
- List shops, Inspector Admins, and Super Admins; enable or disable accounts.
- Reset another shop or admin password. The target's existing sessions are revoked, so the target must log in again.
- Review audit events for account, password, and settings mutations.
- Update only the allow-listed settings: maintenance mode, public app base URL, and default certificate expiry days.

The API repeats the role check on every privileged endpoint. Flutter only decides which screen to show after the server returns the role. The last active Super Admin cannot be demoted or deactivated, and a Super Admin cannot reset their own password from the user list; they use the normal signed-in password-change flow instead.

## Account recovery policy

OTP recovery endpoints and recovery screens are removed. There is no OTP bypass or magic password. If a shop or Inspector Admin forgets its password, a Super Admin uses the user-management screen to set a new one. If every Super Admin loses access, use the server-side database/bootstrap procedure under the deployment team's access controls.

## API quick reference

All requests require the normal bearer token. Only `super_admin` may use the first group:

| Method | Path | Notes |
| --- | --- | --- |
| GET | `/admin/users` | Sanitized account list; password hashes are never returned |
| POST | `/admin/users` | `username`, `display_name`, `password`, and `role` (`admin` or `super_admin`) |
| PATCH | `/admin/users/{id}` | `display_name`, `role`, and/or boolean `is_active` |
| POST | `/admin/users/{id}/password` | `new_password`; minimum 12 characters; revokes target tokens |
| GET | `/admin/audit` | Optional `actor_id`, `action`, `entity_type`, `limit`, and `offset` |
| GET | `/admin/settings` | Returns persisted allow-listed settings |
| PATCH | `/admin/settings` | Accepts `values` with validated allow-listed settings |

The ordinary `/admin/*` inspection endpoints remain available to both `admin` and `super_admin`. OTP routes are intentionally absent and return not found.
