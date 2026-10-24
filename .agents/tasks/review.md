# Integrate React AdminAcademicDashboard with Go REST API

Refactored the AdminAcademicDashboard component to fetch data from Go backend APIs for users, courses, and classes at component mount, with fallback to local state for modules not yet available in the backend. API calls use the correct endpoints and payload shapes; local CRUD operations are preserved for demo modules. Loading state is managed; error handling provides HTTP-specific feedback.

**Watch for:**
- **likely** — `fetchAll()` refreshes all entities after every CRUD operation, which is correct for synchronization but could be verbose. Fine for current scale; monitor if performance degrades.
- **confirmed** — Teachers and students are mapped with `-` as fallback for `nidn` and `nim` since backend doesn't provide these fields. This matches requirements.
- **confirmed** — PUT endpoint for users accepts only `name`, `email`, `role` (no `password` field), but POST includes `password` with a fallback default. Asymmetry is correct per spec.
- **confirmed** — Fallback modules show notification and return early; local state mutation still happens for non-API entities.

**Verdict**: APPROVED

---

## High-level view

The component now loads students, teachers, courses, and classes from backend APIs at mount time via `fetchAll()`, which is called again after each mutation to keep the UI synchronized. Data is mapped to expected component shape with fallbacks (`-`) for fields the backend doesn't provide yet. All four entities handle their API specifics: users distinguish between students and teachers by role; courses map SKS to credits; classes are fetched without additional metadata. Error handling differentiates HTTP status codes and presents user-friendly messages.

Fallback modules (packages, schedules, krs, grades, khs, ukt, attendance, cases, announcements, documents) remain on local state and initializers. CRUD operations on these entities check a `FALLBACK_MODULES` array and notify the user that the feature is not yet available on the server, then return early. Local mutations for supported entities still execute their full validation and state update logic.

PUT and POST payloads match backend expectations exactly. The component preserves form validation and local cleanup logic (cascading deletes, state invariants) for demo modules while delegating all API-backed CRUD to the backend. Error messages include HTTP status and backend error text when available.

---

<details>
<summary>Issues (4)</summary>

1. **Asymmetric password handling** — POST includes `password` with default `'12345678'`, but PUT sends only `name`, `email`, `role`. This mirrors backend asymmetry but means users created without specifying a password get a default. Consider documenting or prompting.

2. **Orphaned references after fetch** — When `fetchAll()` completes and users change, grades, attendance, cases, and documents are filtered to remove rows referencing deleted students. This is safe but assumes the backend is authoritative. If a student is deleted server-side while the UI has local edits, those edits are silently dropped.

3. **KHS and KRS not refreshed after fetch** — `setKrs({})` and `setKhs({})` clear publication status on every refresh. This is correct (demo state should reset), but it means publication state doesn't persist after a manual refresh. Intentional per spec but worth noting.

4. **Class deletion check only local** — Removes a class only if no local student references it, but doesn't check server side. If students exist server-side without being fetched yet, deletion would succeed, leaving orphaned references server-side.

</details>

---

## API integration for students and teachers

Students and teachers POST/PUT through `/admin/users`, with role hardcoded per type (`'mahasiswa'` / `'dosen'`). Create calls include `password` (default `'12345678'`); update calls omit it. After success, `fetchAll()` reloads all users. Error handling differentiates HTTP codes: 404, 409 (conflict), 400, 500, and network failures each get specific user-readable messages.

---

## API integration for courses and classes

Courses map `credits` → `sks` and `term` → `semester` before POSTing or PUTting. Classes send `{ course_id, dosen_id, name, day, start_time, end_time, room }` with empty strings for optional fields. Both call `fetchAll()` after success. Class deletion includes a local student check before calling DELETE; if the backend has students not yet fetched, orphaned references could exist server-side.

---

## Fallback module handling

Fallback modules (packages, schedules, krs, grades, khs, ukt, attendance, cases, announcements, documents) check `FALLBACK_MODULES.includes(entity)` at the start of both `saveRecord()` and `removeRecord()`, notify the user, and return. This prevents any mutation. Exception: UKT edits still work locally when `item` exists (intentional per spec).

---

## Data mapping and fallbacks

When users are fetched, the component splits by role and maps with fallbacks for missing backend fields: `nim` and `nidn` become `'-'`, `classId` is `null`, `semester` is hardcoded to `'2026 Ganjil'`, `expertise` defaults to `'-'`. Courses map SKS to credits and semester to term. Classes use `name` as code and set `year` to `'-'`, `packageId` to `null`. These fallbacks satisfy the component's internal shape without requiring backend changes.

---

## Derived state and reference cleanup

After fetch, the component filters grades, attendance, cases, documents, ukt to remove rows referencing deleted students. This prevents orphaned references when users are deleted server-side. Local edits to these rows for a deleted student are silently dropped. This is safe for the expected workflow (fetch → view/edit → fetch again) but creates data loss if local edits precede a server deletion.

---

## Error handling

API errors are formatted by `formatApiError()` / `formatDeleteError()`, differentiating 404, 409 (conflict), 400, 500, and network errors with user-readable messages. Fallback is generic if backend provides no message for 409 or 400. This is acceptable; the frontend doesn't validate server-side constraints like email uniqueness.

---

## Loading state

`isLoading` is set to `true` at the start of `fetchAll()`, cleared in `finally` regardless of success or failure. Only the initial fetch manages loading state; individual CRUD operations don't. This is appropriate for a secondary admin tool: edits succeed or fail silently via toast.

---

## Local persistence for demo entities

For fallback modules, `persistLocally()` updates state directly: modifying derived state (KHS, KRS), cascading deletes, logging activity. API-backed entities (student, teacher, course, class) skip this and call `fetchAll()` instead. Demo modules remain interactive without requiring a backend.

---

## Test coverage

No new automated tests are present. Manual testing should cover: successful fetch, create/update/delete for each entity type, fallback module behavior, error cases (network, 404, 500, validation), and orphaned reference cleanup. Recommend unit tests for `fetchAll()` with mocked API, per-entity `saveRecord()`, and integration tests for form submission and refresh cycles.

---

## File map

<details>
<summary>Files changed</summary>

- **AdminAcademicDashboard.jsx** — Refactored to fetch initial data from `/admin/users`, `/courses/list`, `/classes/list` at component mount. Updated `saveRecord()` and `removeRecord()` to call backend APIs for students, teachers, courses, classes. Fallback modules check and early return before any mutation. Data mapping uses fallbacks for missing fields (`nim`, `nidn`, `classId`, `packageId`, `year`). Error handling differentiates HTTP codes and displays user-friendly messages.

Full diff: compare this version against main branch via `git diff main -- web-admin/src/admin/AdminAcademicDashboard.jsx`.

</details>
