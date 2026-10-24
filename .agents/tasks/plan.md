# Implementation Plan

## Overview
Add Package (Paket Semester) and Admin KRS (Enrollment) support to the EduTrack project. This involves backend Go API development and frontend React integration.

## Technical Context
- **Backend**: Go 1.26 with GORM, PostgreSQL, JWT auth
- **Frontend**: React with Vite, uses Axios for API calls
- **Patterns**: Follow existing handler patterns (ukt.go, announcement.go)
- **Auth**: Admin middleware protects `/api/v1/admin/*` routes
- **Response format**: `utils.JSONResponse(w, status, message, data)`

## Plan

### Backend Changes

#### 1. Create Package Model
**What**: Create `/home/raihan/Documents/edutrack/backend/models/package.go` with Package struct containing ID, Name, Term, Status, CreatedAt, UpdatedAt, and two Many-to-Many relationships: Courses (via package_courses pivot table) and Classes (via package_classes pivot table).

**Rationale**: Following existing model patterns (course.go, class.go). Many-to-many relationships allow a package to contain multiple courses and be assigned to multiple classes.

**Files**: `/home/raihan/Documents/edutrack/backend/models/package.go`

**Verify**: Go compilation succeeds: `cd /home/raihan/Documents/edutrack/backend && go build ./models`

---

#### 2. Create Package Handler
**What**: Create `/home/raihan/Documents/edutrack/backend/handlers/package.go` with PackageHandler struct and four methods:
- `CreatePackage`: Parse JSON input with `name`, `term`, `status`, `course_ids[]`, `class_ids[]`, create Package, then use `db.Model(&pkg).Association("Courses").Replace(courses)` and `db.Model(&pkg).Association("Classes").Replace(classes)`.
- `GetAllPackages`: `db.Preload("Courses").Preload("Classes").Find(&packages)`.
- `UpdatePackage`: Read ID from query param, load package, update fields, replace associations.
- `DeletePackage`: Read ID from query param, `db.Delete`.

**Rationale**: Follows exact patterns from ukt.go and announcement.go handlers. Uses GORM associations for many-to-many relationships.

**Files**: `/home/raihan/Documents/edutrack/backend/handlers/package.go`

**Verify**: Go compilation succeeds: `cd /home/raihan/Documents/edutrack/backend && go build ./handlers`

---

#### 3. Update Enrollment Handler for Admin KRS
**What**: Update `/home/raihan/Documents/edutrack/backend/handlers/enrollment.go` to add `GetAllEnrollments` method for admin that does `db.Preload("Mahasiswa").Preload("Class.Course").Find(&enrollments)` and returns via `utils.JSONResponse`.

**Rationale**: Existing enrollment handler only has student-specific methods. Need admin endpoint to view all enrollments (KRS).

**Files**: `/home/raihan/Documents/edutrack/backend/handlers/enrollment.go`

**Verify**: Go compilation succeeds: `cd /home/raihan/Documents/edutrack/backend && go build ./handlers`

---

#### 4. Update Main.go
**What**: Update `/home/raihan/Documents/edutrack/backend/main.go`:
#### 4a. Add `&models.Package{}` to `db.AutoMigrate(...)` list.
#### 4b. Initialize `packageHandler := &handlers.PackageHandler{DB: db}`.
#### 4c. Register routes under admin middleware:
- `POST /api/v1/admin/packages` → `packageHandler.CreatePackage`
- `GET /api/v1/admin/packages/list` → `packageHandler.GetAllPackages`
- `PUT /api/v1/admin/packages/update` → `packageHandler.UpdatePackage`
- `DELETE /api/v1/admin/packages/delete` → `packageHandler.DeletePackage`
- `GET /api/v1/admin/krs/list` → `enrollmentHandler.GetAllEnrollments`

**Rationale**: Consistent with existing route patterns (ukt, announcement, schedule). All admin routes use same auth middleware.

**Files**: `/home/raihan/Documents/edutrack/backend/main.go`

**Verify**: Go compilation succeeds: `cd /home/raihan/Documents/edutrack/backend && go build`

---

### Frontend Changes

#### 5. Remove Package/KRS from Fallback Modules
**What**: Update `/home/raihan/Documents/edutrack/web-admin/src/admin/AdminAcademicDashboard.jsx`:
#### 5a. Remove `'packages'` and `'krs'` from `FALLBACK_MODULES` array.
#### 5b. Change initial state: `packages → []` (was `initialPackages`), `krs → []` (was `initialKrs`).
#### 5c. Remove imports of `initialPackages` and `initialKrs` from constants.

**Rationale**: Packages and KRS now have real API endpoints, so they should no longer be fallback modules.

**Files**: `/home/raihan/Documents/edutrack/web-admin/src/admin/AdminAcademicDashboard.jsx`

**Verify**: React app compiles: `cd /home/raihan/Documents/edutrack/web-admin && npm run build` (no errors)

---

#### 6. Add Package and KRS API Calls to fetchAll
**What**: Update `fetchAll()` function in `/home/raihan/Documents/edutrack/web-admin/src/admin/AdminAcademicDashboard.jsx`:
#### 6a. Add to the `Promise.all` two new `api.get` calls: `'/admin/packages/list'` and `'/admin/krs/list'`.
#### 6b. Map package response: Transform API data to match frontend format with `courseIds`, `courses` (string), `classIds`, `classes` (string).
#### 6c. Map KRS response: Transform enrollment API data to match frontend KRS format.

**Rationale**: Integrate real API data into existing fetchAll pattern. Follow mapping patterns used for other entities (ukt, announcements, schedules).

**Files**: `/home/raihan/Documents/edutrack/web-admin/src/admin/AdminAcademicDashboard.jsx`

**Verify**: Manual test: Check browser console for successful API calls and correct data mapping.

---

#### 7. Update saveRecord for Package and KRS
**What**: Update `saveRecord()` function in `/home/raihan/Documents/edutrack/web-admin/src/admin/AdminAcademicDashboard.jsx`:
#### 7a. For `entity === 'package'`: Call `POST /admin/packages` (create) or `PUT /admin/packages/update?id=` (update) with payload `{name, term, status, course_ids, class_ids}`, then `fetchAll()`.
#### 7b. For `entity === 'krs'`: Notify `'KRS dikelola oleh mahasiswa'` and return (read-only for admin).

**Rationale**: Follow existing API integration pattern (ukt, announcement, schedule). KRS is read-only for admin as per requirements.

**Files**: `/home/raihan/Documents/edutrack/web-admin/src/admin/AdminAcademicDashboard.jsx`

**Verify**: Manual test: Create/update package via UI, verify API calls succeed.

---

#### 8. Update removeRecord for Package and KRS
**What**: Update `removeRecord()` function in `/home/raihan/Documents/edutrack/web-admin/src/admin/AdminAcademicDashboard.jsx`:
#### 8a. For `entity === 'package'`: Call `DELETE /admin/packages/delete?id=` then `fetchAll()`.
#### 8b. For `entity === 'krs'`: Notify `'KRS dikelola oleh mahasiswa'` and return.

**Rationale**: Follow existing delete pattern. KRS remains read-only for admin.

**Files**: `/home/raihan/Documents/edutrack/web-admin/src/admin/AdminAcademicDashboard.jsx`

**Verify**: Manual test: Delete package via UI, verify API call succeeds.

---

#### 9. Update Package Rows Derivation
**What**: Update `packageRows` derivation in `/home/raihan/Documents/edutrack/web-admin/src/admin/AdminAcademicDashboard.jsx` to use `row.courses` and `row.classes` directly (already mapped in step 6b) instead of recalculating from courseIds.

**Rationale**: Simplifies code since mapping already done in fetchAll.

**Files**: `/home/raihan/Documents/edutrack/web-admin/src/admin/AdminAcademicDashboard.jsx`

**Verify**: Packages display correctly in UI with course and class names.

---

#### 10. Update KRS Rows Derivation
**What**: Update `getRows('krs')` or KRS table logic in `/home/raihan/Documents/edutrack/web-admin/src/admin/AdminAcademicDashboard.jsx` to return the `krs` array directly as rows (since we now have actual enrollment records).

**Rationale**: KRS data now comes from API, not derived state.

**Files**: `/home/raihan/Documents/edutrack/web-admin/src/admin/AdminAcademicDashboard.jsx`

**Verify**: KRS table displays real enrollment data.

---

#### 11. Clean Up Dummy Data Imports
**What**: Remove `initialPackages` and `initialKrs` from import list at top of `/home/raihan/Documents/edutrack/web-admin/src/admin/AdminAcademicDashboard.jsx`.

**Rationale**: Clean up unused imports.

**Files**: `/home/raihan/Documents/edutrack/web-admin/src/admin/AdminAcademicDashboard.jsx`

**Verify**: No import errors after removal.

---

### Verification Steps
1. **Backend Compilation**: `cd /home/raihan/Documents/edutrack/backend && go build`
2. **Frontend Build**: `cd /home/raihan/Documents/edutrack/web-admin && npm run build`
3. **API Testing**: Use curl or Postman to test new endpoints:
   - `GET /api/v1/admin/packages/list` (returns empty array initially)
   - `POST /api/v1/admin/packages` (creates package)
   - `GET /api/v1/admin/krs/list` (returns enrollments)
4. **UI Testing**: Start dev server, navigate to admin dashboard, verify:
   - Packages tab loads without errors
   - Can create/update/delete packages
   - KRS tab displays enrollment data
   - No console errors

## Dependencies Order
1. Backend changes (1-4) must be completed before frontend can work
2. Frontend changes 5 (remove fallback) depends on backend being ready
3. Frontend changes 6-11 can be done in parallel after step 5
4. Verification requires both backend and frontend to be complete