# Implementation Plan: Integrate UKT, Announcements, and Schedules Modules

## Overview
Integrate 3 new modules (UKT, Announcements, Schedules) by:
1. Creating 3 new Go models
2. Creating 3 new Go handlers with CRUD operations
3. Registering routes in main.go with admin middleware
4. Updating frontend to fetch from API and remove fallback data
5. Verifying the full backend build and React frontend loads

---

## Backend Changes

### 1. Create UKT Model
**What to do**: Create the UKT model file with StudentID (foreign key to User), Semester, Billed, Paid, and DueDate fields. Follow the pattern from Grade/Attendance models.

**Files to create/modify**:
- `backend/models/ukt.go`

**Verify**: `grep -n "type UKT struct" backend/models/ukt.go` — confirm the struct is present with all fields (ID, StudentID, Semester, Billed, Paid, DueDate, CreatedAt, UpdatedAt, Student relation).

---

### 2. Create Announcement Model
**What to do**: Create the Announcement model file with Title, Category, Content, StartDate, EndDate, and Status fields.

**Files to create/modify**:
- `backend/models/announcement.go`

**Verify**: `grep -n "type Announcement struct" backend/models/announcement.go` — confirm the struct is present with all fields (ID, Title, Category, Content, StartDate, EndDate, Status, CreatedAt, UpdatedAt).

---

### 3. Create Schedule Model
**What to do**: Create the Schedule model file with ClassID, CourseID, TeacherID, Day, StartTime, EndTime, and Room fields. Include foreign key relations to Class, Course, and User (Teacher).

**Files to create/modify**:
- `backend/models/schedule.go`

**Verify**: `grep -n "type Schedule struct" backend/models/schedule.go` — confirm the struct is present with all fields and relations (ID, Semester, ClassID, CourseID, TeacherID, Day, StartTime, EndTime, Room, CreatedAt, UpdatedAt, Class, Course, Teacher).

---

### 4. Update main.go AutoMigrate
**What to do**: Add `&models.UKT{}`, `&models.Announcement{}`, and `&models.Schedule{}` to the `db.AutoMigrate(...)` call.

**Files to create/modify**:
- `backend/main.go` (lines ~41-46)

**Verify**: `grep -A 8 "AutoMigrate(" backend/main.go` — confirm all three models are in the list.

---

### 5. Create UKT Handler
**What to do**: Create `backend/handlers/ukt.go` with UKTHandler struct and methods:
- `CreateUKT(w, r)` — POST, JSON decode, insert to DB, return JSONResponse
- `GetAllUKT(w, r)` — GET, Preload("Student"), return all UKT records
- `UpdateUKT(w, r)` — PUT, get id from URL query, update specific fields, save, return JSONResponse
- `DeleteUKT(w, r)` — DELETE, get id from URL query, delete record, return JSONResponse

Follow the exact pattern from `backend/handlers/course.go` and `backend/handlers/class.go`: use query params for ID, decode JSON body, use utils.JSONResponse for all responses.

**Files to create/modify**:
- `backend/handlers/ukt.go`

**Verify**: `grep -n "func (h \*UKTHandler)" backend/handlers/ukt.go` — confirm all 4 methods exist (CreateUKT, GetAllUKT, UpdateUKT, DeleteUKT).

---

### 6. Create Announcement Handler
**What to do**: Create `backend/handlers/announcement.go` with AnnouncementHandler struct and methods:
- `CreateAnnouncement(w, r)` — POST
- `GetAllAnnouncements(w, r)` — GET, no preloading needed
- `UpdateAnnouncement(w, r)` — PUT
- `DeleteAnnouncement(w, r)` — DELETE

Follow the same pattern as UKT handler.

**Files to create/modify**:
- `backend/handlers/announcement.go`

**Verify**: `grep -n "func (h \*AnnouncementHandler)" backend/handlers/announcement.go` — confirm all 4 methods exist.

---

### 7. Create Schedule Handler
**What to do**: Create `backend/handlers/schedule.go` with ScheduleHandler struct and methods:
- `CreateSchedule(w, r)` — POST
- `GetAllSchedules(w, r)` — GET, **Preload("Class")**, **Preload("Course")**, **Preload("Teacher")**
- `UpdateSchedule(w, r)` — PUT
- `DeleteSchedule(w, r)` — DELETE

Follow the same pattern as UKT handler but include the three Preload calls in GetAllSchedules.

**Files to create/modify**:
- `backend/handlers/schedule.go`

**Verify**: `grep -n "func (h \*ScheduleHandler)" backend/handlers/schedule.go` — confirm all 4 methods exist.

---

### 8. Initialize Handlers in main.go
**What to do**: Add three new handler variable declarations after the existing handlers (around line 50):
- `uktHandler := &handlers.UKTHandler{DB: db}`
- `announcementHandler := &handlers.AnnouncementHandler{DB: db}`
- `scheduleHandler := &handlers.ScheduleHandler{DB: db}`

**Files to create/modify**:
- `backend/main.go` (lines ~50-52)

**Verify**: `grep -n "uktHandler\|announcementHandler\|scheduleHandler" backend/main.go` — confirm all three are initialized.

---

### 9. Register Routes in main.go
**What to do**: Add 12 route registrations at the end of the protected routes section (before "6. Jalankan Server" comment). Use the exact pattern from existing routes:
- `/api/v1/admin/ukt` (POST, admin only)
- `/api/v1/admin/ukt/list` (GET, admin only)
- `/api/v1/admin/ukt/update` (PUT, admin only)
- `/api/v1/admin/ukt/delete` (DELETE, admin only)
- `/api/v1/admin/announcements` (POST, admin only)
- `/api/v1/admin/announcements/list` (GET, admin only)
- `/api/v1/admin/announcements/update` (PUT, admin only)
- `/api/v1/admin/announcements/delete` (DELETE, admin only)
- `/api/v1/admin/schedules` (POST, admin only)
- `/api/v1/admin/schedules/list` (GET, admin only)
- `/api/v1/admin/schedules/update` (PUT, admin only)
- `/api/v1/admin/schedules/delete` (DELETE, admin only)

Each route uses `http.Handle()`, middleware `middlewares.AuthMiddleware("admin")()`, and calls the appropriate handler method.

**Files to create/modify**:
- `backend/main.go` (add ~20 lines before the final comment)

**Verify**: `grep "/api/v1/admin/ukt\|/api/v1/admin/announcements\|/api/v1/admin/schedules" backend/main.go` — confirm all 12 routes are registered.

---

## Frontend Changes

### 10. Update AdminAcademicDashboard.jsx State Initialization
**What to do**: Update the initial state for `schedules`, `ukt`, and `announcements`:
- Change `const [schedules, setSchedules] = useState(initialSchedules)` to `const [schedules, setSchedules] = useState([])`
- Change `const [ukt, setUkt] = useState(initialUkt)` to `const [ukt, setUkt] = useState([])`
- Change `const [announcements, setAnnouncements] = useState(initialAnnouncements)` to `const [announcements, setAnnouncements] = useState([])`

**Files to create/modify**:
- `web-admin/src/admin/AdminAcademicDashboard.jsx` (lines ~33-35)

**Verify**: `grep -A 1 "const \[schedules," web-admin/src/admin/AdminAcademicDashboard.jsx | head -1` — confirm it shows `useState([])`

---

### 11. Update FALLBACK_MODULES Array
**What to do**: Remove `'schedules'`, `'ukt'`, and `'announcements'` from the FALLBACK_MODULES array. The array should contain: `['packages', 'krs', 'khs', 'cases', 'documents']`

**Files to create/modify**:
- `web-admin/src/admin/AdminAcademicDashboard.jsx` (lines ~38-39)

**Verify**: `grep "FALLBACK_MODULES = " web-admin/src/admin/AdminAcademicDashboard.jsx` — confirm `'schedules'`, `'ukt'`, `'announcements'` are not present and exactly 5 modules remain.

---

### 12. Expand fetchAll() to Include 3 New Modules
**What to do**: In the `fetchAll()` async function, add 3 new API calls to `Promise.all()`:
- Add `api.get('/admin/ukt/list')` as the 6th call
- Add `api.get('/admin/announcements/list')` as the 7th call
- Add `api.get('/admin/schedules/list')` as the 8th call

Then add mapping blocks for each:

**UKT Mapping**: Extract from response and map:
```
const uktData = response?.data?.data?.data || []
setUkt(
  uktData.map((item) => ({
    id: item.id,
    studentId: item.student_id,
    nim: students.find((s) => s.id === item.student_id)?.nim || '—',
    student: item.Student?.name || 'Unknown',
    semester: item.semester,
    billed: item.billed,
    paid: item.paid,
    due: item.due_date,
    debt: Math.max(0, item.billed - item.paid),
    status: item.paid >= item.billed ? 'Lunas' : 'Belum lunas',
  }))
)
```

**Announcements Mapping**: Extract from response and map:
```
const announcementsData = response?.data?.data?.data || []
setAnnouncements(
  announcementsData.map((item) => ({
    id: item.id,
    title: item.title,
    category: item.category,
    content: item.content,
    start: item.start_date,
    end: item.end_date,
    status: item.status,
  }))
)
```

**Schedules Mapping**: Extract from response and map:
```
const schedulesData = response?.data?.data?.data || []
setSchedules(
  schedulesData.map((item) => ({
    id: item.id,
    semester: item.semester,
    classId: item.class_id,
    class: item.Class?.name || 'Unknown',
    courseId: item.course_id,
    course: item.Course?.name || 'Unknown',
    teacherId: item.teacher_id,
    teacher: item.Teacher?.name || 'Unknown',
    day: item.day,
    start: item.start_time,
    end: item.end_time,
    room: item.room,
  }))
)
```

**Files to create/modify**:
- `web-admin/src/admin/AdminAcademicDashboard.jsx` (fetchAll function, around lines ~150-200)

**Verify**: `grep -n "api.get('/admin/ukt/list')" web-admin/src/admin/AdminAcademicDashboard.jsx` — confirm the call is in fetchAll().

---

### 13. Update saveRecord() for UKT, Announcements, and Schedules
**What to do**: Add API integration blocks in `saveRecord()` before the final `persistLocally()` call:

**For UKT**:
```javascript
if (entity === 'ukt') {
  const payload = {
    student_id: values.studentId,
    semester: values.semester,
    billed: values.billed,
    paid: values.paid,
    due_date: values.due,
  }
  const apiCall = item
    ? api.put(`/admin/ukt/update?id=${item.id}`, payload)
    : api.post('/admin/ukt', payload)
  apiCall
    .then(() => {
      fetchAll()
      log(config.activity, `${item ? 'Memperbarui' : 'Menambahkan'} ${config.singular}`)
      setDialog(null)
      notify(`${config.singular} berhasil ${item ? 'diperbarui' : 'ditambahkan'}.`)
    })
    .catch((error) => notify(`Gagal menyimpan data: ${formatApiError(error)}`))
  return
}
```

**For Announcements**:
```javascript
if (entity === 'announcement') {
  const payload = {
    title: values.title,
    category: values.category,
    content: values.content,
    start_date: values.start,
    end_date: values.end,
    status: values.status,
  }
  const apiCall = item
    ? api.put(`/admin/announcements/update?id=${item.id}`, payload)
    : api.post('/admin/announcements', payload)
  apiCall
    .then(() => {
      fetchAll()
      log(config.activity, `${item ? 'Memperbarui' : 'Menambahkan'} ${config.singular}`)
      setDialog(null)
      notify(`${config.singular} berhasil ${item ? 'diperbarui' : 'ditambahkan'}.`)
    })
    .catch((error) => notify(`Gagal menyimpan data: ${formatApiError(error)}`))
  return
}
```

**For Schedules**:
```javascript
if (entity === 'schedule') {
  const payload = {
    semester: values.semester,
    class_id: values.classId,
    course_id: values.courseId,
    teacher_id: values.teacherId,
    day: values.day,
    start_time: values.start,
    end_time: values.end,
    room: values.room,
  }
  const apiCall = item
    ? api.put(`/admin/schedules/update?id=${item.id}`, payload)
    : api.post('/admin/schedules', payload)
  apiCall
    .then(() => {
      fetchAll()
      log(config.activity, `${item ? 'Memperbarui' : 'Menambahkan'} ${config.singular}`)
      setDialog(null)
      notify(`${config.singular} berhasil ${item ? 'diperbarui' : 'ditambahkan'}.`)
    })
    .catch((error) => notify(`Gagal menyimpan data: ${formatApiError(error)}`))
  return
}
```

**Files to create/modify**:
- `web-admin/src/admin/AdminAcademicDashboard.jsx` (saveRecord function, add 3 new blocks before `persistLocally()`)

**Verify**: `grep -n "entity === 'ukt'" web-admin/src/admin/AdminAcademicDashboard.jsx` — confirm the UKT API block exists.

---

### 14. Update removeRecord() for UKT, Announcements, and Schedules
**What to do**: Add API deletion calls in `removeRecord()` for UKT, Announcements, and Schedules. Each should follow the pattern:

```javascript
if (entity === 'ukt') {
  api.delete(`/admin/ukt/delete?id=${row.id}`)
    .then(() => {
      fetchAll()
      log('Data', `Menghapus ${names[entity]}`)
      setDialog(null)
      notify(`${names[entity]} berhasil dihapus.`)
    })
    .catch((error) => notify(`Gagal menghapus data: ${formatDeleteError(error)}`))
  return
}
```

Do the same for 'announcement' and 'schedule' entities.

**Files to create/modify**:
- `web-admin/src/admin/AdminAcademicDashboard.jsx` (removeRecord function, add 3 new blocks in the API integration section)

**Verify**: `grep -n "entity === 'ukt'" web-admin/src/admin/AdminAcademicDashboard.jsx | grep delete` — confirm deletion blocks exist.

---

## Verification Steps

### 15. Verify Backend Build
**What to do**: Build the Go backend to ensure all model imports, handlers, and routes compile correctly.

**Verify**: From `/home/raihan/Documents/edutrack/backend`, run `go build -o edu-track-backend 2>&1`. Confirm exit code is 0 and binary is created. Alternatively, run `docker compose build backend` from `/home/raihan/Documents/edutrack/docker` if using Docker.

---

### 16. Verify Frontend Loads
**What to do**: Ensure the React frontend code has no syntax errors by running the development build.

**Verify**: From `/home/raihan/Documents/edutrack/web-admin`, run `npm run build 2>&1` or similar (check package.json for build script). Confirm no critical errors in the build output and `dist/` or build output is created.

---

## Summary of Design Decisions

1. **Model Structure**: Each model follows the existing pattern (ID as primary key, timestamps, relations via gorm tags).

2. **Handler Pattern**: All handlers use the same CRUD structure as Course/Class handlers (query params for ID, JSON body for data, utils.JSONResponse for all responses).

3. **Route Registration**: All routes use `http.Handle()` with `middlewares.AuthMiddleware("admin")` to restrict to admin users only, matching the existing security model.

4. **Frontend Integration**: Data is fetched in `fetchAll()` via `Promise.all()` for parallelism, mapped to match the frontend schema, and integrated into `saveRecord()`/`removeRecord()` with API calls that refresh data on success. Removed from FALLBACK_MODULES so form guards no longer apply.

5. **Error Handling**: Backend returns standard `utils.JSONResponse` with status codes. Frontend uses existing error formatting functions (`formatApiError`, `formatDeleteError`) for consistency.

6. **Data Mapping**: Frontend maps API responses to existing local state schema, preserving the component's display logic without modification.
