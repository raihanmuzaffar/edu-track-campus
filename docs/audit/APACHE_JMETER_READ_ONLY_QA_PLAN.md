# Apache JMeter — Read-only Backend QA Plan

## Status and safety boundary

**Runtime status: `BLOCKED / NOT RUN`.** This package is a prepared test plan only.
The server previously identified by the owner is production and is explicitly
blocked by the JMX. The JMX does not contain an approved staging hostname;
`staging_load` therefore fails closed until an independently verified hostname
is supplied through configuration. A production smoke profile is defined only
for review and still requires explicit, target-specific production permission.
No JMeter process, login, HTTP request, database access, or application runtime
was started while preparing this update.

The existing runtime readiness checklist
([`RUNTIME_E2E_READINESS_CHECKLIST.md`](./RUNTIME_E2E_READINESS_CHECKLIST.md))
still has pending target, isolation, account, fixture, readback, cleanup, and
runtime-authorization gates. The product approval in
[`INTEGRATION_DECISIONS_AND_E2E_PLAN.md`](./INTEGRATION_DECISIONS_AND_E2E_PLAN.md)
does not grant permission to execute this plan.

## Purpose and scope

Measure read-only backend response behavior for the existing Mobile role flows:
Mahasiswa, Dosen, and Orang Tua/Wali. The plan makes authenticated `GET`
requests only. It does not call login/refresh/logout, mutate data, seed fixtures,
or run cleanup. Each role has a separate JMeter Thread Group and separate bearer
token property.

The test plan checks:

- HTTP status is `200`;
- the JSON response has a top-level `data` field;
- `users/me` reports the expected role and a numeric user ID;
- class listing uses the backend pagination envelope;
- list endpoints return arrays and academic summary endpoints return objects.

These are source-contract assertions; they do not prove database persistence,
environment isolation, UI behavior, or authorization security at runtime.

## Profiles and safety bounds

The `profile` property defaults to `disabled`; every role's virtual-user count
also defaults to zero. Those defaults send no HTTP requests; only a local
preflight sampler runs.

| Profile | Eligible target | Requests | Users and loops | Duration and pacing |
|---|---|---|---|---|
| `production_smoke` | Explicitly authorized HTTPS target only; the known production hosts listed below are blocked; **not authorized currently** | Only `GET /users/me` | At most one total virtual user and one iteration | Maximum 60 seconds; at most one HTTP request; 10-second minimum interval |
| `staging_load` | Exact owner-approved, independently verified staging/disposable hostname only; **BLOCKED until supplied** | All role endpoints in the matrix; fixture-dependent endpoints are skipped if approved IDs are absent | At least one and at most five total users across all roles; repeat until duration | Maximum 3,600 seconds; ramp-up maximum 3,600 seconds; at most one request/second per virtual user and five requests/second aggregate |
| `disabled` | None | None | JMX forces zero role users | No HTTP requests; local preflight only |

Runnable profiles default to a 10-second ramp-up and 60-second duration. The
JMX preflight rejects more than one total user for production smoke and more
than five total users across all profiles; it also rejects staging without the
approved hostname. Production smoke uses one loop. Staging load repeats until
the configured duration, capped at one hour. Both active profiles require a
1–3,600 second ramp-up (production smoke is additionally capped at 60 seconds).
`request_interval_ms` is clamped to at least 10,000 ms for production smoke and
1,000 ms for staging load. The hard five-user cap and one-request/second
per-user floor bound staging traffic at **five requests/second aggregate**.
These are safety caps, not performance targets; the owner must approve a lower
load profile if required.

Production smoke performs only the current-user identity check; it does not
read academic, child, class, or financial data. The production server mentioned
in the audit is not authorized by this document and is rejected by the JMX
preflight. Staging load remains blocked until its exact hostname, fixture,
accounts, profile, and authorization are verified.

### Preflight and fail-closed target guards

A JMeter `setUp Thread Group` runs a local preflight before the role Thread
Groups. Any invalid active-profile target, missing staging hostname, or
virtual-user limit violation records a generic `CONFIG` failure and calls
JMeter's immediate-stop operation; no HTTP sampler should start. The
`disabled` profile passes this local check but starts zero role threads and
sends no HTTP request. Run the complete test plan; do not disable the preflight
group or start a role Thread Group by itself, as doing so bypasses this guard.

Every active profile requires an HTTPS `api_base_url` without URL user-info,
query, or fragment. The staging profile additionally requires
`approved_staging_hostname`, which must be the exact hostname only (no scheme,
port, or path) and must exactly match the hostname in `api_base_url`. The
property is intentionally blank by default; no staging hostname has been
provided, so staging remains `BLOCKED`.

The preflight explicitly rejects `sistemkampus.fs.kg`,
`www.sistemkampus.fs.kg`, `16.178.252.47`, and subdomains of
`sistemkampus.fs.kg` for active profiles. This prevents those known production
targets from being used by either smoke or load profiles. It does not prove
that an arbitrary other hostname is staging: the owner/operator must verify
the target independently and supply the approved hostname.

## Verified read-only endpoint matrix

All paths below are under the configured API base URL (normally ending in
`/api/v1`). Route and role registration were checked in `backend/main.go`;
response shapes were checked in the listed handlers. Every request in the JMX
is `GET`.

| Profile | Thread Group | Endpoint | Role allowed by route | Expected `data` shape |
|---|---|---|---|---|
| Both | Mahasiswa | `/users/me` | All authenticated roles | Object; numeric `id` and `role == mahasiswa` |
| `staging_load` | Mahasiswa | `/student/academic/summary` | `mahasiswa` | Object with numeric `student_id` |
| `staging_load` | Mahasiswa | `/schedules/my` | `mahasiswa` | Array |
| `staging_load` | Mahasiswa | `/enrollments/my` | `mahasiswa` | Array |
| `staging_load` | Mahasiswa | `/grades/my` | `mahasiswa` | Array |
| `staging_load` | Mahasiswa | `/attendances/my` | `mahasiswa` | Array |
| `staging_load` | Mahasiswa | `/admin/announcements/list` | `admin`, `dosen`, `mahasiswa`, `orangtua` | Array |
| `staging_load` | Mahasiswa | `/notifications` | `admin`, `dosen`, `mahasiswa`, `orangtua` | Array |
| Both | Dosen | `/users/me` | All authenticated roles | Object; numeric `id` and `role == dosen` |
| `staging_load` | Dosen | `/classes/list` | `admin`, `dosen`, `mahasiswa` | Pagination object with `data` array and numeric `total_data` |
| `staging_load` (optional fixture) | Dosen | `/classes/students?class_id={dosen_class_id}` | `admin`, `dosen` | Array; handler checks class ownership |
| Both | Orang Tua/Wali | `/users/me` | All authenticated roles | Object; numeric `id` and `role == orangtua` |
| `staging_load` | Orang Tua/Wali | `/parent/children` | `orangtua` | Array of linked Mahasiswa |
| `staging_load` | Orang Tua/Wali | `/parent/announcements` | `orangtua` | Array |
| `staging_load` (optional fixture) | Orang Tua/Wali | `/parent/child/profile?child_id={parent_child_id}` | `orangtua` | Object for a linked child |
| `staging_load` (optional fixture) | Orang Tua/Wali | `/parent/child/summary?child_id={parent_child_id}` | `orangtua` | Object with numeric `student_id` |
| `staging_load` (optional fixture) | Orang Tua/Wali | `/parent/child/attendances?child_id={parent_child_id}` | `orangtua` | Array |
| `staging_load` (optional fixture) | Orang Tua/Wali | `/parent/child/schedules?child_id={parent_child_id}` | `orangtua` | Array |
| `staging_load` (optional fixture) | Orang Tua/Wali | `/parent/child/ukt?child_id={parent_child_id}` | `orangtua` | Array |
| `staging_load` (optional fixture) | Orang Tua/Wali | `/parent/child/documents?child_id={parent_child_id}` | `orangtua` | Array of metadata; no file content/download route |

The `dosen_class_id` and `parent_child_id` values are intentionally not supplied.
Their optional JMX controllers skip those specific requests when the approved
fixture ID is blank. They must be populated only with owner-approved fixture IDs
belonging to the associated test account. The backend still performs ownership
and parent-child relationship checks.

### Source evidence

- Route methods and role middleware: `backend/main.go` (`/users/me`,
  `/classes/list`, `/classes/students`, Student routes, Parent routes, and
  `/notifications`).
- Current user, class listing, and response envelopes:
  `backend/handlers/auth.go`, `backend/handlers/class.go`.
- Student summary, schedules, and notifications:
  `backend/handlers/academic.go`.
- Enrollment, grade, attendance, and class-student responses:
  `backend/handlers/enrollment.go`, `backend/handlers/grade.go`,
  `backend/handlers/attendance.go`.
- Parent link scoping and child response shapes:
  `backend/handlers/parent.go`.

No mutation routes are included. In particular, this plan does not test
`POST /login`, enrollment create/drop, grade/attendance input, QR generation or
scan, profile update, announcements CRUD, or document/UKT CRUD.

## Preconditions — all currently pending

Do not run until every applicable prerequisite is independently verified and
explicitly approved. The server previously supplied is production, not a
staging target; this document does not grant permission to access it.

1. **Target and isolation:** owner supplies the exact staging/disposable API
   base URL, the exact approved hostname for `approved_staging_hostname`, and
   verifiable evidence it is not production/shared. Verify the backend and
   database identity independently; do not infer safety from a
   service/environment name. The hostname setting is a guard value, not proof
   of environment identity.
2. **Official role accounts:** owner supplies approved test-account references
   for Mahasiswa, Dosen, and Orang Tua/Wali. Obtain short-lived access tokens
   through the approved secret mechanism; do not put credentials in this
   repository or on the command line.
3. **Fixture ownership:** provide the Dosen's assigned `dosen_class_id` and an
   actually linked `parent_child_id` if those optional scenarios are to run.
   Never use arbitrary IDs or personal data as aliases.
4. **Profile and rate approval:** for staging, owner/operator approves each
   role's virtual-user count, ramp-up, duration, per-user interval, resulting
   aggregate request-rate ceiling, and resource guardrails. For any production
   smoke, obtain separate written authorization for the exact target, role,
   one-user/one-request scope, time window, and operator.
5. **Performance objectives:** owner supplies latency thresholds by endpoint or
   role (including percentile), minimum throughput if relevant, and acceptable
   error rate. No performance target is assumed in this package.
6. **Execution permission:** explicit, unexpired permission names the target,
   JMeter/API scope, roles, load profile, time window, operator, and stop
   conditions. Product approval alone is insufficient.
7. **Monitoring/stop plan:** identify the service/database owner and monitoring
   signals; the operator must be able to stop immediately on the conditions in
   the stop section below.

Because this plan is read-only, it has no cleanup operation. That does not
remove the requirement to verify the target is isolated and authorized.

## Configuration and secret handling

The JMX has no embedded credentials or target URL. It reads:

- `profile` — `disabled` (default), `production_smoke`, or `staging_load`;
- `api_base_url` — approved API root URL, including its API prefix, with no
-  embedded credentials, query, or fragment; active profiles require HTTPS;
- `approved_staging_hostname` — exact, owner-approved staging DNS hostname
  only, required by `staging_load`, with no default value;
- `student_access_token`, `dosen_access_token`, `parent_access_token` — approved
  bearer tokens for those roles;
- `student_users`, `dosen_users`, `parent_users` — approved virtual-user counts
  (each defaults to `0`; total must be `1–5` for an active profile and
  production smoke permits only one total user);
- `ramp_up_seconds`, `duration_seconds` — defaults are 10 and 60 seconds;
  production smoke is capped at 60 seconds and staging at 3,600 seconds;
- `request_interval_ms` — minimum 10,000 ms for production smoke and 1,000 ms
  for staging, per virtual user (defaults to 10,000 ms);
- HTTP connect and response timeouts are fixed at 3,000 ms and 5,000 ms,
  respectively;
- `dosen_class_id`, `parent_child_id` — optional approved fixture IDs.

Store these properties only in a local, access-restricted file outside the
repository (for example, mode `0600`). Do not supply tokens/passwords as
`-J...` command-line arguments, commit them, log them, or paste them into
reports. The plan does not perform login or refresh. Access tokens must remain
valid for the approved run; if they expire, stop and obtain a newly authorized
token rather than enabling a login sampler.

All three role Thread Groups are independent. The `disabled` profile forces
every role to zero users. Production smoke permits only one total user, one
iteration, and its only HTTP sampler is `GET /users/me`; staging-only endpoints
are skipped. A blank or invalid active-profile target fails in preflight before
role samplers; a blank role token records the existing local `CONFIG BLOCKED`
sample and sends no HTTP request for that role. A zero-sample role is **not a
pass**; it means that role was not exercised. Hostname equality and the block
list are safeguards, not proof that an arbitrary configured target is truly
staging or that an account is approved.

## Load and execution procedure (not executed)

After all preconditions pass, create the private property file locally and
review the target, role mapping, IDs, load settings, expiry, and stop procedure
with the owner/operator. Configure the JMeter output paths outside the
repository.

These command templates are for future authorized runs only. The production
template runs one role and one current-user request; repeat separately for other
roles only if each has explicit approval. The staging template requires the
approved per-role load profile. Neither command is authorization to run.

```sh
# Production smoke: one approved role, one GET /users/me, never a load test.
jmeter -n \
  -t docs/audit/apache_jmeter_read_only_roles.jmx \
  -q "$JMETER_PRIVATE_PROPERTIES" \
  -Jprofile=production_smoke \
  -Jstudent_users=1 -Jdosen_users=0 -Jparent_users=0 \
  -Jramp_up_seconds=10 -Jduration_seconds=60 \
  -Jrequest_interval_ms=10000 \
  -l "$PRIVATE_RESULTS_DIR/production-smoke.jtl" \
  -j "$PRIVATE_RESULTS_DIR/production-smoke.log"

# Staging load: values must exactly match the approved load profile.
jmeter -n \
  -t docs/audit/apache_jmeter_read_only_roles.jmx \
  -q "$JMETER_PRIVATE_PROPERTIES" \
  -Jprofile=staging_load \
  -Jstudent_users="$APPROVED_STUDENT_USERS" \
  -Jdosen_users="$APPROVED_DOSEN_USERS" \
  -Jparent_users="$APPROVED_PARENT_USERS" \
  -Jramp_up_seconds="$APPROVED_RAMP_UP_SECONDS" \
  -Jduration_seconds="$APPROVED_DURATION_SECONDS" \
  -Jrequest_interval_ms="$APPROVED_MIN_REQUEST_INTERVAL_MS" \
  -Jjmeter.save.saveservice.response_data=false \
  -Jjmeter.save.saveservice.response_data.on_error=false \
  -Jjmeter.save.saveservice.samplerData=false \
  -Jjmeter.save.saveservice.requestHeaders=false \
  -Jjmeter.save.saveservice.responseHeaders=false \
  -l "$PRIVATE_RESULTS_DIR/staging-load.jtl" \
  -j "$PRIVATE_RESULTS_DIR/staging-load.log" \
  -e -o "$PRIVATE_RESULTS_DIR/html-report"
```

Use unique output paths for each run. Do not enable View Results Tree, debug
logging, request/response-header capture, or response-body capture. Keep JTL,
JMeter logs, and HTML reports private; review and redact before sharing.

## Metrics and interpretation

Read Aggregate Report / generated HTML Dashboard by endpoint label and by role;
do not combine roles if their approved profiles differ.

- **Response time:** average, median/p50, p90, p95, p99, minimum, and maximum.
- **Throughput:** completed requests per second, with the run duration and
  virtual-user profile attached.
- **Error rate:** failed samples divided by total samples. Assertion failures,
  non-200 status, invalid JSON, incorrect envelope/shape, or role mismatch count
  as failed samples.
- **Latency breakdown:** JMeter latency and connect time help distinguish
  server response delay from connection setup; use backend/database monitoring
  for resource attribution.
- **Sample count:** verify every expected role and endpoint has samples. A
  skipped optional endpoint or zero-user role is reported as `NOT RUN`, not
  `PASS`.

## Pass/fail criteria

**Functional contract pass:** all executed requests return HTTP 200 and pass the
JMX JSON envelope, role, and response-shape assertions; there are no assertion
failures or unexpected skipped roles/endpoints.

**Performance pass:** only assess after the owner has approved explicit
per-endpoint/role response-time percentiles, throughput expectations, acceptable
error rate, load profile, and resource guardrails. Compare measured p50/p90/p95/
p99 and throughput against those approved values. Until supplied, performance
acceptance is `PENDING`; do not invent thresholds or declare a performance
pass.

## Stop criteria

These are conservative operational stops, not performance acceptance targets.
For production smoke, stop after the first timeout, connection error, HTTP
401/403, any other non-200 status, invalid response, role mismatch, or service
degradation. Do not retry automatically.

For staging load, stop immediately on any failed sample, including an
authentication/authorization failure (401/403), other non-200 status, assertion
failure, timeout, connection error, target/fixture mismatch, or owner-defined
resource/service-health guardrail breach. This deliberately uses a zero-failure
run criterion while no error-rate threshold has been approved; do not relax it
without explicit owner approval. If monitoring or an operator able to stop
promptly is unavailable, do not start.

The JMX assertions distinguish HTTP 401 authentication/token failure and HTTP
403 role authorization denial from other non-200 responses, and mark all as
failed samples. They do not automatically stop a run at the error-rate
threshold; the operator must monitor the run and stop it. Keep only sanitized
evidence and notify the named owner.

**Fail:** any unexpected status or response shape, role mismatch, target or
fixture mismatch, approved error-rate limit exceeded, resource guardrail breach,
or out-of-scope effect.

## JMeter availability in this environment

The JMX declares Apache JMeter **5.6.3**. At review time, `jmeter` was not
installed/on `PATH`; OpenJDK 17 was available on Fedora 44. No package or system
configuration was changed.

For a future approved setup, first check whether the Fedora repository provides
the package (`dnf info jmeter`); if available, an operator may install it with
`sudo dnf install jmeter`. Alternatively, download the official Apache JMeter
binary distribution from [jmeter.apache.org](https://jmeter.apache.org/download_jmeter.cgi),
verify its published checksum/signature, and extract it to an operator-owned
location. Do not install it automatically as part of this QA preparation.

The JMX was parsed as XML and checked statically for role groups, request
methods, profile gating, timeout/rate limits, and absence of the production
target literals. It was not loaded or executed by JMeter because JMeter is
unavailable. XML parsing does not verify JMeter component semantics or Groovy
function execution; that remains pending a safe, offline JMeter review.
