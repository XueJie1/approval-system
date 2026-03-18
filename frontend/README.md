# Approval System Frontend

Vite + Vue3 + TypeScript frontend for the approval system.

## Tech stack

- Vue 3 + Vue Router
- Pinia
- Element Plus
- Axios
- Vitest

## Scripts

```bash
npm install
npm run dev
npm run build
npm run preview
npm run test
```

## Local development

1. Start backend service at `http://localhost:8080`.
2. Run frontend dev server in this directory:

```bash
npm run dev
```

Vite proxy forwards `/api/*` requests to `http://localhost:8080`.

## Current scope (MVP)

- `/login` Login + 2FA challenge flow
- `/bootstrap` Admin bootstrap page
- `/start` Start request with dynamic form loading/validation
- `/tasks` Task list + claim/approve/delegate/reassign/return/cancel + AI suggestion
- `/requests` Request list + process list + logs
- `/profile` User profile + 2FA operations
