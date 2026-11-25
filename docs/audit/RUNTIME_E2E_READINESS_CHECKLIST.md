# Runtime E2E Readiness Checklist

Status: **BLOCKED / NOT RUN**. This document is a preparation checklist, not evidence that a runtime test was authorized or executed.

## Approved product decisions

The owner-provided decisions for A/B/C are **APPROVED**. These approvals authorize the product behavior described below, but do not prove implementation, permit runtime access, authorize production access, or authorize deployment.

| Decision | Approved behavior | Implementation and runtime boundary |
|---|---|---|
| A — Kaprodi scope | Kaprodi may access only resources belonging to the program of study assigned to the authenticated user. Enforce scope server-side for every read/write operation, including direct-ID requests. No cross-program exceptions. Missing or invalid assignment denies access. | This approval is not evidence that current models/handlers enforce scope. Runtime Kaprodi tests remain blocked by environment/account/data gates. |
| B — Flutter KRS | Students may create and drop only their own KRS. Backend remains authoritative for registration period, ownership, schedule conflicts, capacity and SKS limit. Drop preserves enrollment history. Reactivation is allowed only if current backend rules permit it and all validations run. | This approval does not prove Flutter wiring or backend behavior. Do not bypass server validation or claim runtime persistence. |
| C — Flutter documents | Parents may read metadata for linked children only. Backend must verify the parent-child relation on every request and deny unlinked child IDs. Student self-service, file upload/download, and deletion are not approved. | This approval does not authorize file operations or new student self-service endpoints. Runtime remains blocked pending all environment gates. |

Product approval is separate from runtime approval. It is not permission to log in, send application requests, access production, mutate data, or deploy. Do not mark an environment gate `VERIFIED` based on product approval alone.

## Worktree baseline and safety boundary

- Repository: EduTrack Campus; branch `main`, `HEAD` `cb4e5a6` at inspection.
- Worktree already contains extensive modified and untracked files. Preserve them; do not reset, clean, or overwrite unrelated changes.
- No production/staging request, login, database connection, container, seeder, reset, cleanup, commit, push, or deployment was performed for this checklist.
- Runtime runner currently covers only API-level announcement scenarios. It does not drive Admin/Kaprodi browsers or Flutter, and it does not inspect the database directly.
- Do not invoke runtime against an application target until every gate below is explicitly satisfied. A guard-only CLI check with all E2E environment variables removed may verify fail-closed behavior; it must return `BLOCKED` before login/request.

## Admission gates

| Gate | Evidence required before runtime | Current status | If missing |
|---|---|---|---|
| Product decision: Kaprodi scope | **APPROVED**: per-assigned-program access only; authenticated identity is the scope source; no cross-program exceptions; missing/invalid assignment and direct-ID out-of-scope access must be denied. | `APPROVED` — source changes added; database-backed handler authorization and validity of non-empty program assignments remain unverified. | Do not claim complete authorization or runtime enforcement. |
| Product decision: Flutter KRS | **APPROVED**: students may create/drop their own KRS; backend validates period, ownership, schedule conflict, capacity and SKS limit; drop preserves history; reactivation only under backend rules and validation. | `APPROVED` — create/drop API wiring and mock widget tests added; backend persistence remains unverified. | Do not bypass backend validation or claim runtime behavior. |
| Product decision: Flutter documents | **APPROVED**: parents may read metadata for linked children only; server-side relation check required; no student self-service, file upload/download, or delete. | `APPROVED` — linked-child metadata API wiring and mock tests added; runtime access checks remain unverified. | Do not add or test unapproved document operations. |
| Environment owner approval | Explicit staging/disposable classification, owner/reference, exact API base URL, expiration, and approval for each role/scenario. Environment names alone are not evidence. | `PENDING` — no approved target supplied. | Runner must return `BLOCKED`; no login/request. |
| Database isolation | Verifiable identity of the database behind that target and evidence it is disposable and not production; separate from application URL approval. | `PENDING` — no target DB evidence supplied. | No runtime test, seeder, reset, or cleanup. |
| Reset and cleanup | Owner-approved procedure with scope, expected record IDs, who may execute it, and evidence of completion. Runner cleanup is limited to its own announcement ID; it does not reset or truncate a database. | `PENDING` — no approved procedure supplied; attendance has no delete API. | Do not run mutating scenario. |
| Official test accounts | Role-specific official account references and explicit approval in a secret manager; inject credentials only through the approved secret mechanism/environment. Never put values in source, shell history, reports, screenshots, or logs. | `PENDING` — no account approval/reference supplied. | No login. |
| Role and fixture matrix | Approved account role, program scope/linked child/class, permitted operations, expected allow/deny result, and non-PII test record plan. | `PENDING` — fixture, role matrix and expected access/denial evidence not supplied. | Do not infer access from hidden UI controls. |
| Database readback | Approved, read-only mechanism and query/operator to verify the exact test record and relationships without exposing unrelated personal data. | `PENDING` — no readback mechanism approved. | API response/readback alone is not DB persistence evidence. |
| Runtime execution authorization | Explicit approval to run API, browser and/or Flutter runtime tests on the named target after other gates pass. Product approval alone does not satisfy this gate. | `PENDING` — no runtime permission supplied. | Do not run runtime E2E. |
| Browser and Flutter automation | Approved staging app builds, stable selectors/test entry points, device/emulator target and diagnostics policy. Current runner is API-only. | `NOT IMPLEMENTED / NOT RUN` | Do not report UI or Flutter runtime PASS. |

`APPROVED` denotes a product decision, not an implementation or runtime result. `PENDING` in an environment gate means its required evidence/approval has not been supplied; the associated runtime scenario remains `BLOCKED`. `NOT RUN` denotes no applicable test execution has occurred, and `NOT IMPLEMENTED` denotes missing automation.

## Final runtime admission checklist

Re-verify these gates immediately before any runtime execution. Every applicable item must have current, reviewable evidence and be marked `VERIFIED`; a submitted answer, environment label, or runner configuration alone is not evidence. Current status for every item below is `PENDING`.

- [ ] **Target is safe:** exact application/API target and owner are documented; independent evidence confirms staging/disposable and not production; target approval is current and unexpired.
- [ ] **Database is isolated:** the database identity behind the target is verified independently, confirmed disposable/non-production, and isolated from production and other shared data.
- [ ] **Accounts are official:** role-specific test accounts are authorized and retrieved only via the approved secret manager. Record secret references only—never secret values.
- [ ] **Product scope and test data are approved:** relevant A/B/C decisions are explicit and unambiguous; role × resource × operation × data scope, fixtures, expected allow/deny outcomes, and prohibited scenarios are agreed.
- [ ] **Persistence readback is safe:** an approved read-only method can verify the exact test records/relations without exposing unrelated data; operator and evidence format are identified.
- [ ] **Cleanup is bounded:** owner-approved teardown addresses every mutation, names its exact scope/records and responsible operator, and cannot delete unrelated data. If a flow has no exact-ID cleanup (including attendance), use only an approved one-use disposable target and owner-controlled teardown.
- [ ] **Runtime authorization is explicit:** separate permission identifies which of API, Admin browser, Kaprodi browser, and Flutter runtime may run, on which target/build/device, for which scenarios/roles, and until when.
- [ ] **Evidence handling is approved:** capture only sanitized statuses, non-PII run/record identifiers, and required assertion results; do not capture credentials, tokens, cookies, QR tokens, personal data, raw payloads, or unredacted screenshots.

If any applicable item is missing, ambiguous, conflicting, expired, or unverifiable, stop before login or any application request and report `BLOCKED`. Do not fall back to another URL or environment. Runtime approval does not authorize an unapproved product behavior, and product approval does not authorize runtime execution.

## Cleanup and data strategy

1. Provision a separate, one-use disposable database/environment through its owner; verify its identity and isolation before tests. Do not infer disposability from a service name, port, or environment label.
2. The test owner prepares only approved fixtures and records their non-PII IDs. Runtime create operations must use a unique run ID.
3. Use the runner's exact-ID announcement cleanup only for an announcement returned by that run's create response. If create response is ambiguous or cleanup fails, stop and mark `MANUAL_REVIEW_REQUIRED`; do not search-and-delete broadly.
4. QR attendance has no delete endpoint. Do not use attendance mutation unless a one-use database teardown or another narrowly scoped cleanup procedure is explicitly approved. Any teardown is performed by the environment owner only after confirming the dedicated target and scope—not by test code.
5. No database reset, `TRUNCATE`, seeder, or broad cleanup is part of the current runner.

## Runtime scenario evidence matrix

| Scenario | Required assertions and evidence | Current status |
|---|---|---|
| Admin → backend → Kaprodi/Flutter announcement readback | Admin create response/envelope; read-only DB verification; Kaprodi web/API visibility per approved scope; real student Flutter refresh/readback; sanitized console/network/errors; exact-ID cleanup. | Runtime `BLOCKED`; mock API flow `PASS` only. |
| Kaprodi → backend → Admin/Flutter | Approved Kaprodi create/update, API and DB readback, Admin/Flutter readback, direct out-of-scope request denied. | Product scope `APPROVED`; runtime `BLOCKED` by absent environment/accounts and unverified enforcement. |
| Flutter KRS → web | First verify current read-only KRS on Flutter and web. Add create/drop only if implemented and approved; validate backend periods/ownership/capacity/schedule rules and readback after refresh/login. | Product mutation `APPROVED`; local Flutter wiring/mock tests added; runtime and persistence `BLOCKED`. |
| Flutter documents | Exercise approved parent role and metadata only; verify server-side parent-child relationship and denied unlinked IDs. | Product behavior `APPROVED`; local metadata wiring/mock tests added; runtime `BLOCKED`. File operations and student self-service are not approved. |
| Dosen QR → Mahasiswa scan → web attendance | Verify assigned-class ownership, active period, QR expiry, scan result, attendance API/DB readback, refresh, session close and `/qr/session` after local-session restoration. Never capture the QR token. | Candidate identified from code, but runtime `BLOCKED`; no safe attendance cleanup/API and no approved disposable target. |
| Update/delete and negative role/scope | Assert exact HTTP status/envelope, no success-shaped fallback, direct-ID access denial as decided, DB state before/after, and limited cleanup. | `BLOCKED`; scenarios not implemented in runner; no runtime evidence. |

Evidence must be stored per layer and per scenario:

| Layer | Evidence needed | Must not be presented as |
|---|---|---|
| Source/contract inspection | Endpoint, DTO, role and relationship mapping with file/line references. | Runtime integration or persistence proof. |
| Mock fixture | Assertions, simulated failures, safe cleanup behavior. | Backend/API/database/browser/Flutter PASS. |
| Runtime API | Sanitized status/envelope and response readback under an approved target. | Browser UI or Flutter runtime proof; by itself, not direct DB proof. |
| Database | Approved read-only verification of the exact test record/relations. | Authorization enforcement in the UI. |
| Browser UI | Actual role login, network/console results, rendered data after refresh/navigation. | Flutter runtime proof. |
| Flutter runtime | Actual approved build/device, network/API result and rendered data after refresh/navigation. | Admin/Kaprodi UI proof. |

For each run, record `PASS`, `FAIL`, `BLOCKED`, or `NOT RUN` per assertion/layer; timestamp, scenario ID, role, run ID and sanitized record ID; API status; DB readback result; UI readback; cleanup result; and untested limitations. Never record passwords, access/refresh tokens, cookies, QR tokens, personal data, raw payloads or unredacted screenshots.

## Safe local validation already available

- `cd web-admin && npm test`: local Node tests; mock transport only.
- `cd web-admin && npm run e2e:mock`: in-memory announcement flow only.
- `cd web-admin && npm run lint && npm run build`: local source validation/build.
- `cd mobile && flutter test && flutter analyze`: local unit tests/analyzer, not a device/runtime API test.
- `cd backend && go test . ./config ./utils && go build ./...`: safe packages/build. Do not run handler tests without independently verified disposable DB; handler `TestMain` can execute `TRUNCATE`.
- A runtime CLI guard-only check with URL, approval, role-account and run configuration variables unset: expected `BLOCKED`/exit 2 before any application request. This is not a runtime E2E result.

At this inspection no runtime admission gate is satisfied by supplied evidence. The product decisions above are approved, but environment/account/fixture/readback/cleanup and runtime-authorization evidence remain pending. Continue only with these local checks and source/doc work until those runtime prerequisites are supplied and verified.
