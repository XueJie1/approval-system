-- Migration: add template launch-role whitelist support
-- Date: 2026-04-15
-- Target: MariaDB / MySQL

USE approval_system;

ALTER TABLE request_template
  ADD COLUMN IF NOT EXISTS launch_role_codes_json TEXT NULL
  AFTER approval_config_json;

UPDATE request_template
SET launch_role_codes_json = '["EMPLOYEE"]'
WHERE launch_role_codes_json IS NULL
   OR TRIM(launch_role_codes_json) = '';

