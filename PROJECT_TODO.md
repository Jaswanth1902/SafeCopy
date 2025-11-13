# PROJECT_TODO — SafeCopy

This file consolidates action items discovered from the repository markdowns and quick code inspection. Priorities are ordered top→down for a minimal working MVP.

## Immediate (High Priority)

- [ ] Set environment variables: create `backend/.env` from `.env.example` and set `DATABASE_URL`/`DB_*`, `JWT_SECRET`, `JWT_REFRESH_SECRET`.
- [ ] Install backend dependencies: run `npm install` in `backend`.
- [ ] Run DB migrations: `npm run migrate` (creates required tables in Postgres).
  - Tip: You can start a local Postgres quickly with `docker-compose -f backend/docker-compose.yml up -d`.
- [ ] Verify `files` table schema vs `backend/routes/files.js` expectations. If migration creates FK constraints, ensure uploads include `user_id` and `owner_id` (routes currently expect these from JWT or client).
- [ ] Start backend server: `npm run dev` and confirm `/health` responds `OK`.

## Backend (Next)

- [ ] Add missing role-based protections on routes (use `backend/middleware/auth.js`).
- [x] Implement `auth` routes for users (`/api/auth/*`).
- [x] Implement `owners` routes for owners (`/api/owners/*`).
- [ ] Review `backend/routes/files.js` to use `req.user` (from JWT) and store `user_id` and `owner_id` correctly.
- [ ] Add input validation for file uploads and ensure binary data writes to `BYTEA` columns succeed.
- [ ] Add basic unit tests for auth and file endpoints (use `supertest` + `jest`).

## Mobile & Desktop (MVP features)

- [ ] Implement `mobile_app/lib/services/user_service.dart` to store JWT in secure storage.
- [ ] Implement mobile login/register screens and wire `upload_screen.dart` to `api_service` and `encryption_service`.
- [ ] Implement desktop owner login and key management screens.

## Testing & CI

- [ ] Add basic smoke tests: register → login → upload → list → download → delete.
- [ ] Add CI workflow to run `npm test` and lint on PRs.

## Notes & Risks

- Database schema contains FK constraints (files.user_id, files.owner_id). Upload endpoint must supply those or migrations must be adjusted.
- The owners registration currently returns the private RSA key in the response once. Owner must be instructed to store it securely.
- If a developer machine does not have Postgres, consider adding a `docker-compose.yml` for a local Postgres instance.

---

Last automated scan: November 13, 2025

Next action I will take: verify `backend` starts locally without crashing (will run `npm install` and start server if you permit). If you want me to proceed running commands, allow and I will run them; otherwise I will continue implementing code-only fixes.
