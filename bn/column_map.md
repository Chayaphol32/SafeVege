# Database column names

Each physical table column has its table prefix. `users.use_password` stores a password hash.

## users

- `id` → `use_id`
- `username` → `use_username`
- `password_hash` → `use_password`
- `display_name` → `use_display_name`
- `role` → `use_role`
- `is_active` → `use_is_active`
- `created_at` → `use_created_at`
- `updated_at` → `use_updated_at`

## api_tokens

- `id` → `tok_id`
- `user_id` → `tok_user_id`
- `token_hash` → `tok_hash`
- `expires_at` → `tok_expires_at`
- `created_at` → `tok_created_at`

## shops

- `id` → `shop_id`
- `owner_user_id` → `shop_owner_user_id`
- `name` → `shop_name`
- `owner_first_name` → `shop_owner_first_name`
- `owner_last_name` → `shop_owner_last_name`
- `phone` → `shop_phone`
- `house_number` → `shop_house_number`
- `moo` → `shop_moo`
- `street` → `shop_street`
- `subdistrict` → `shop_subdistrict`
- `district` → `shop_district`
- `province` → `shop_province`
- `postal_code` → `shop_postal_code`
- `latitude` → `shop_latitude`
- `longitude` → `shop_longitude`
- `is_public` → `shop_is_public`
- `created_at` → `shop_created_at`
- `updated_at` → `shop_updated_at`

## inspection_requests

- `id` → `req_id`
- `shop_id` → `req_shop_id`
- `request_no` → `req_no`
- `status` → `req_status`
- `address_snapshot` → `req_address_snapshot`
- `latitude_snapshot` → `req_latitude_snapshot`
- `longitude_snapshot` → `req_longitude_snapshot`
- `submitted_at` → `req_submitted_at`
- `updated_at` → `req_updated_at`

## inspection_request_items

- `id` → `item_id`
- `request_id` → `item_request_id`
- `vegetable_name` → `item_vegetable_name`
- `created_at` → `item_created_at`

## inspection_appointments

- `id` → `apt_id`
- `request_id` → `apt_request_id`
- `appointment_at` → `apt_appointment_at`
- `note` → `apt_note`
- `scheduled_by` → `apt_scheduled_by`
- `created_at` → `apt_created_at`

## inspection_results

- `id` → `res_id`
- `request_item_id` → `res_request_item_id`
- `revision_no` → `res_revision_no`
- `outcome` → `res_outcome`
- `inspected_at` → `res_inspected_at`
- `recorded_by` → `res_recorded_by`
- `note` → `res_note`
- `created_at` → `res_created_at`

## certificates

- `id` → `cert_id`
- `request_id` → `cert_request_id`
- `certificate_no` → `cert_no`
- `file_path` → `cert_file_path`
- `mime_type` → `cert_mime_type`
- `issued_at` → `cert_issued_at`
- `expires_at` → `cert_expires_at`
- `is_public` → `cert_is_public`
- `uploaded_by` → `cert_uploaded_by`
- `created_at` → `cert_created_at`

## certificate_results

- `certificate_id` → `cr_certificate_id`
- `result_id` → `cr_result_id`

## audit_events

- `id` → `aud_id`
- `actor_user_id` → `aud_actor_user_id`
- `entity_type` → `aud_entity_type`
- `entity_id` → `aud_entity_id`
- `action` → `aud_action`
- `details` → `aud_details`
- `created_at` → `aud_created_at`

## app_settings

- `setting_key` → `set_key`
- `setting_value` → `set_value`
- `setting_updated_by` → `set_updated_by`
- `setting_updated_at` → `set_updated_at`
