# Bug Fix Report

Date: November 13, 2025

This file summarizes the bug fixes and code/documentation changes applied to the SafeCopy repository up to this point in the session.

## Summary (short)

- Applied secure RSA-OAEP usage and implemented AES-256-GCM decryption logic (desktop) — requires dependency verification at runtime.
- Fixed multiple Flutter UI crashes and lifecycle issues (mounted checks, typed models, syntax fixes).
- Hardened backend transaction handling (added ROLLBACK on migration failures).
- Replaced insecure logging and removed committed secrets; added `.env.example` and `.gitignore` improvements.
- Added CI workflow to run tests and upload coverage as artifacts; removed coverage files from VCS via .gitignore recommendations.
- Fixed numerous API client issues (malformed async methods, incorrect parameter lists) and improved error handling.

## Files Changed (high-level)

- backend/
  - `scripts/migrate.js` — added transaction rollback handling and improved error logging.
  - `.gitignore` & root `.gitignore` — ignore `.env`, `backend/coverage/`, `lcov.info`, `.nyc_output/`, and `lcov-report/`.
  - `server.js` — validated critical envs such as `ENCRYPTION_KEY` at startup.
  - `routes/auth.js` — updated refresh-token flow to update a single session row (rotate only the matched session).
  - `routes/owners.js` — avoid printing full error objects; sanitize logs.

- desktop_app/
  - `lib/services/file_decryption_service.dart` — switched RSA decryption to OAEP and implemented AES-256-GCM decryption using `GCMBlockCipher`. Added input validation.
  - `lib/services/owner_api_service.dart` — fixed malformed `loginOwner` and related API calls; corrected async handling and error reporting.
  - `lib/screens/owner_login_screen.dart` — removed redundant nested `if (mounted)` guard.
  - `lib/screens/print_jobs_screen.dart` — added typed `PrintJob` model, converted jobs list to `List<PrintJob>`, and updated UI to use typed fields.

- mobile_app/
  - `lib/screens/file_list_screen.dart` — fixed misplaced `onTap` syntax, validated files list from API, and added safer ID formatting helper.

- workspace and docs
  - `.vscode/*` — workspace tasks and settings to enable ESLint auto-fix on save for backend.
  - `.github/workflows/ci.yml` — added CI job to run backend tests, upload coverage artifact, and optionally send to Codecov with secret.
  - `PHASE_3_INDEX.md`, `PHASE_3_COMPLETION.md`, `PROJECT_STATUS.md` — updated to reflect current blockers, verification steps, and that smoke tests ran against test/local DB.

## Notable Fix Details

- RSA padding: replaced PKCS#1 v1.5 usage with RSA-OAEP to mitigate padding oracle vulnerabilities.

- AES-GCM: implemented authenticated decryption by feeding ciphertext + tag into `GCMBlockCipher` with `AEADParameters`. Note: ensure `pointycastle` package version in `pubspec.yaml` matches the API used.

- Transactions: in `migrate.js`, wrapped the `BEGIN`/`COMMIT` in an inner try/catch and `await client.query('ROLLBACK')` on error. If rollback fails, the rollback error is logged separately.

- Sessions: refresh-token rotation previously updated all sessions for a user; patch now targets the specific session row by ID to avoid cross-session token invalidation.

- UI safety: replaced `!mounted` checks and unsafe `!` casts with `context.mounted` and null-aware fallbacks; added typed models for print jobs to avoid runtime map access errors.

- API client hygiene: fixed malformed method signatures, ensured `async`/`await` usage and proper JSON decoding/error propagation.

## Remaining / Follow-up Items

1. auth.js duplicate-declaration cleanup: during edits AMD static checks reported duplicate variable declarations in `backend/routes/auth.js` that should be consolidated.
2. Run `flutter pub get` and verify `pointycastle` API compatibility for desktop AES-GCM code; adjust imports or package version as needed.
3. Run migrations on a live Postgres instance and re-run the backend smoke tests.
4. Validate Windows printing on an actual Windows environment (or Windows CI runner).
5. Remove any remaining committed coverage artifacts with:

```powershell
git rm -r --cached backend/coverage
git commit -m "Remove generated coverage files"
git push origin master
```

## How to verify fixes locally

- To verify migration rollback behavior:

```powershell
node backend/scripts/migrate.js
```

- To run backend tests and generate coverage:

```powershell
npm --prefix backend test
```

- To test desktop decryption (after updating `pubspec.yaml` and running `flutter pub get`):

1. Add a unit test using a known AES-GCM vector (ciphertext, key, iv, tag, plaintext).
2. Run `flutter test` in the desktop app package.

---

If you'd like, I can now:

- (A) Run a repo-wide pass to apply similar safety/type fixes to remaining Flutter screens.
- (B) Clean up `backend/routes/auth.js` to remove duplicate declarations and re-run static checks.
- (C) Produce unit tests for AES-GCM decryption and for the migration script rollback.

Tell me which follow-up you want and I'll proceed.
