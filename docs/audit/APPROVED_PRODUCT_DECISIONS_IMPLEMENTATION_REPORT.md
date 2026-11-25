# Approved Product Decisions — Implementation Report

## Status

**Overall implementation: `PARTIAL / BLOCKED`.** A1 is partially implemented because the backend has no canonical program catalog or structured program assignment to validate a non-empty Kaprodi assignment, and several resources have no program relation. B2 and C2 have local Flutter API wiring and mock tests, but backend policy gaps and runtime persistence/access remain unverified.

**Runtime API, database, browser, and Flutter E2E: `BLOCKED / NOT RUN`.** No application login/request, database access, migration, seed, reset, cleanup, deployment, commit, or push was performed.

The approved behavior is recorded in [INTEGRATION_DECISIONS_AND_E2E_PLAN.md](./INTEGRATION_DECISIONS_AND_E2E_PLAN.md). Product approval is not runtime authorization. Environment evidence and runtime gates remain outstanding in [RUNTIME_E2E_READINESS_CHECKLIST.md](./RUNTIME_E2E_READINESS_CHECKLIST.md).

## A1 — Kaprodi program scope

### Implemented in source

- Added `currentProgramScope`, which obtains the Kaprodi identity from authenticated request context, re-reads the role and `program_studi` from the backend user record, and denies missing, blank, or role-mismatched assignments. Database lookup failures return an explicit server error.
- Added server-side row scoping for student-linked users, enrollments, grades, attendance, UKT, KHS, cases, and documents. Lists are filtered before results are returned; ID-based update/delete lookups include the same scope before resolving the ID.
- Kaprodi-created student-linked records are assigned the authenticated Kaprodi's program scope, and supplied student IDs are checked against that scope. Updates cannot move a record to a student outside the assigned program.
- User create/update/delete is limited to student and lecturer accounts in the assigned program. Kaprodi cannot change account role or move an account to another program. Self-profile updates cannot change the Kaprodi program assignment.
- Admin role access remains unrestricted by the Kaprodi scope helper.
- Global resources without a provable program relationship are denied to Kaprodi by route policy. The Kaprodi dashboard now avoids those requests and explains that scope is unavailable instead of treating denied responses as empty data.
- Student class listing is available to the student role for KRS selection. The server enforces the active academic year/semester and active/legacy-compatible class status; the search predicate is grouped so it cannot bypass these filters.

### Actual source and contracts reviewed

- Authenticated identity: middleware `UserIDKey` and `RoleKey`; scope is reloaded from `models.User.ProgramStudi`.
- `ProgramStudi` is currently a string, not a foreign key or validated program assignment. The inspected Course, Class, Package, Schedule, and Announcement models have no program relation.
- Scoped endpoints: `/admin/users*`, `/admin/krs/list`, `/admin/grades/list`, `/admin/attendances/list`, `/admin/ukt*`, `/admin/khs*`, `/admin/cases*`, and `/admin/documents*`.
- Kaprodi access was removed for global course/class/package/schedule/announcement, dashboard statistics, period reconciliation, and active QR listing endpoints where the current data model cannot enforce an assigned-program scope.
- Errors use the existing JSON response envelope. Out-of-scope direct-ID lookups return not found; denied creates and missing assignments return forbidden.

### Tests and remaining A1 gap

- Added `backend/utils/access_test.go` cases for own-program match, cross-program rejection, blank assignment/resource, non-Kaprodi rejection, and unchanged Admin access.
- Added `backend/handlers/program_scope_test.go` for scoped list/create behavior, cross-program create rejection, direct-ID update/delete denial, missing assignment, and role-mismatched identity.
- The handler tests were **compiled but not run**. `backend/handlers/all_test.go` has a `TestMain` that requires an explicitly disposable PostgreSQL DSN, migrates it, and executes `TRUNCATE`; no such target was verified. Therefore the database-backed assertions are not test results.
- A non-empty but invalid program string cannot be recognized as invalid without a canonical catalog/assignment source. This remains a blocker; no schema or identity source was invented.
- Courses, classes, packages, schedules, and announcements cannot be safely exposed to Kaprodi until the project supplies program ownership relations and a verified backfill/mapping. They remain denied rather than globally visible.

## B2 — Flutter KRS create/drop

### Implemented

- Reused the existing backend contract: `GET /enrollments/my`, `GET /classes/list`, `POST /enrollments` with `EnrollmentInput{class_id}`, and `POST /enrollments/drop` with the same input.
- Flutter presents available classes, submits only `class_id`, confirms drops, surfaces backend validation errors, and refetches KRS and class data after a successful mutation. It does not update KRS state optimistically or determine the owner, period, capacity, schedule conflict, or SKS limit.
- The existing backend uses the authenticated student ID for enrollment ownership. Create checks that the class matches the active academic year/semester and validates class status, duplicate enrollment, schedule conflicts, capacity, and maximum SKS. A dropped enrollment is reactivated only after those validations pass. Drop preserves the enrollment record by changing its status.
- Added mock widget tests for successful create/drop and backend refresh, initial loading, and validation failure without a success-shaped state.

### Remaining B2 policy gap

- `AcademicPeriodNow()` identifies the active academic year/semester; no separate registration-window or student-eligibility source was found. In particular, the existing drop handler checks ownership but does not check a registration window. The approved decision requires that policy to be enforced by the backend. No registration-window behavior was inferred or added; backend policy clarification/implementation is required before B2 can be considered complete.
- No live API, database persistence, refresh-after-login, or web readback was tested.

## C2 — Parent access to linked-child document metadata

### Implemented

- Reused `GET /parent/child/documents?child_id=...`. `ParentHandler.GetChildDocuments` resolves the child from the authenticated parent's relationship before querying documents; an unlinked child is rejected server-side.
- Flutter requests documents only for a child returned by `/parent/children`, maps only the available `type`, `semester`, `status`, and `date` metadata, and shows an explicit empty state. No file URL, upload, download, delete, or student self-service UI/API was added.
- Added mock tests for a linked child request, no child-linked request, endpoint error, empty metadata UI, and metadata mapping.

### Actual response contract

The existing endpoint returns `models.Document` metadata associated with `student_id`; the Flutter mapper does not retain or render the ID or any file data. The parent-child relation is rechecked by the backend on every document request.

## Files changed for this implementation

- Backend: `backend/main.go`, `backend/handlers/{program_scope.go,program_scope_test.go,admin.go,auth.go,enrollment.go,class.go,case.go,document.go,grade.go,attendance.go,ukt.go,khs.go}`, `backend/utils/{access.go,access_test.go}`.
- Kaprodi web: `web-admin/src/prodi/ProdiDashboard.jsx`.
- Flutter: `mobile/lib/screens/mahasiswa/krs_tab.dart`, `mobile/lib/data/{orang_tua_preview_data.dart,orang_tua_api_mapper.dart}`, `mobile/lib/screens/orang_tua/{orang_tua_dashboard.dart,informasi_tab.dart}`.
- Tests: `mobile/test/{krs_api_test.dart,orang_tua_documents_test.dart,orang_tua_api_mapper_test.dart}`.
- Audit documents: this report, [RUNTIME_E2E_READINESS_CHECKLIST.md](./RUNTIME_E2E_READINESS_CHECKLIST.md), and a superseding implementation note in [WEB_ADMIN_CRUD_API_REPAIR_REPORT.md](./WEB_ADMIN_CRUD_API_REPAIR_REPORT.md). Earlier sections remain historical evidence.

No database migration or new dependency was added.

## Validation

| Check | Result |
|---|---|
| `go -C backend test ./utils` | **PASS** — policy helper tests only; no database access. |
| `go -C backend test -c ./handlers -o /tmp/edutrack-handlers.test` | **PASS** — handlers and DB-backed tests compile; test binary was not run. |
| `go -C backend build ./...` | **PASS** — compile/build only; no runtime connection. |
| `cd mobile && flutter test` | **PASS** — all 14 local unit/widget tests, using mock HTTP transports. |
| `cd mobile && flutter analyze` | **PASS** — no issues found. |
| `cd web-admin && npm test` | **PASS** — 18 tests; mock-only. |
| `cd web-admin && npm run lint` | **PASS**. |
| `cd web-admin && npm run build` | **PASS**. |
| `git diff --check` | **PASS** after source and documentation edits. |

### Not run

- Handler tests, because their package-level `TestMain` can migrate and truncate a database and no explicitly disposable database was verified.
- Any API/database runtime request, login, browser E2E, Flutter runtime, persistence readback, or cross-application refresh test. Runtime authorization and persistence remain unverified.
- Migration/seeder/reset/cleanup or tests that may mutate a database.

## Blockers and required follow-up

1. Provide a canonical, server-verifiable Kaprodi-to-program assignment and a program ownership mapping for global academic resources; define/backfill it before enabling those resources for Kaprodi.
2. Define the authoritative KRS registration window and student eligibility source, then enforce them for both create and drop in the backend. Preserve existing reactivation validations.
3. After the above schema/policy gaps are addressed, run the compiled handler authorization tests only against an explicitly disposable database.
4. Runtime E2E remains `BLOCKED / NOT RUN` until every admission gate is evidenced: non-production target, isolated disposable DB, official account references through secret manager, approved role/fixture/scenarios, read-only persistence verification, bounded cleanup, and explicit runtime authorization.

Until blockers 1–3 are resolved, the implementation is **partial**, not complete. Nothing in this report establishes runtime integration or database persistence.
