# 2026-03-18 2FA Secret Rotation Fix Note

## Background

After enabling 2FA, users reported that logging out and logging back in could fail with `invalid 2FA code`.

## Root cause

Two auth endpoints could overwrite `two_factor_secret` unexpectedly:

1. `POST /api/auth/2fa/setup`
2. `POST /api/auth/2fa/recovery/generate`

This invalidated authenticator apps that were still using the previous secret.

## Backend changes

### `AuthService.setupTwoFactor`

- Before: always generated and persisted a new secret.
- After: reuses existing secret when present; only generates a new secret when missing.

### `AuthService.enableTwoFactorWithRecovery`

- Before: generated a new secret while creating recovery codes.
- After: keeps existing secret and only refreshes recovery codes.
- Falls back to generating a secret only if none exists.

### `TotpService.generateRecoveryCode`

- Fixed formatting bug where a separator `-` was appended twice.

## Frontend changes

In profile page (`frontend/src/views/ProfileView.vue`):

- Disable "获取 2FA 配置" when 2FA is already enabled, to avoid accidental secret reset workflows.
- Prevent generating recovery codes before 2FA is enabled.

## Regression tests

Updated integration test:

- `AuthControllerIntegrationTests#authenticatedUser_canSetupEnableGenerateRecoveryCodes_andDisableTwoFactor`
  - Asserts recovery generation does not rotate secret.
  - Asserts disable operation still accepts TOTP generated from original secret.

Validation command used:

```bash
./mvnw -q -Dtest=AuthControllerIntegrationTests,SecurityServiceTests test
```

## Runtime note

For local preview in this session, backend was run with in-memory H2 arguments to avoid external MariaDB dependency. This means data is not persisted across restarts.
