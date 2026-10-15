# SafeVege ER diagram (draft)

```mermaid
erDiagram
    users ||--o{ shops : owns
    users ||--o{ api_tokens : authenticates
    shops ||--o{ inspection_requests : submits
    inspection_requests ||--|{ inspection_request_items : contains
    inspection_requests ||--o{ inspection_appointments : schedules
    inspection_request_items ||--o{ inspection_results : records
    inspection_requests ||--o{ certificates : receives
    certificates ||--o{ certificate_results : covers
    inspection_results ||--o{ certificate_results : referenced_by
    users ||--o{ audit_events : performs
```

An admin is a `users` row with `role = 'admin'`. The admin user is also referenced by appointment, result, and certificate records to preserve who performed each action.
