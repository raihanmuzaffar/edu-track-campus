package handlers_test

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/raihanmuzaffar/edu-track-campus/backend/handlers"
	"github.com/raihanmuzaffar/edu-track-campus/backend/middlewares"
	"github.com/raihanmuzaffar/edu-track-campus/backend/models"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

var testDB *gorm.DB
var adminID, dosenID, mhsID, ortuID uint

func TestMain(m *testing.M) {
	// Tests must use an explicitly provisioned, disposable PostgreSQL database.
	dsn := os.Getenv("EDUTRACK_TEST_DATABASE_DSN")
	if dsn == "" {
		_, _ = os.Stderr.WriteString("EDUTRACK_TEST_DATABASE_DSN must point to a dedicated disposable test database\n")
		os.Exit(1)
	}
	if !strings.Contains(dsn, "dbname=edutrack_test") {
		_, _ = os.Stderr.WriteString("Refusing to run tests: database name must be edutrack_test\n")
		os.Exit(1)
	}
	var err error
	testDB, err = gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		_, _ = os.Stderr.WriteString("Gagal koneksi DB testing: " + err.Error() + "\n")
		os.Exit(1)
	}

	// Create all schema objects before truncating so this also works on a fresh CI database.
	if err := testDB.AutoMigrate(
		&models.User{}, &models.Course{}, &models.Class{}, &models.Enrollment{},
		&models.Grade{}, &models.Attendance{}, &models.UKT{}, &models.Announcement{},
		&models.Schedule{}, &models.Package{}, &models.Case{}, &models.Document{},
		&models.KHSRecord{}, &models.ParentStudent{}, &models.QRSession{},
	); err != nil {
		_, _ = os.Stderr.WriteString("Gagal migrasi database testing: " + err.Error() + "\n")
		os.Exit(1)
	}

	// Reset only the isolated test database after confirming its schema exists.
	if err := testDB.Exec(`TRUNCATE TABLE users, courses, classes, enrollments, grades, attendances, qr_sessions, ukts, announcements, schedules, packages, cases, documents, khs_records, parent_students CASCADE;`).Error; err != nil {
		_, _ = os.Stderr.WriteString("Gagal membersihkan database testing: " + err.Error() + "\n")
		os.Exit(1)
	}

	// Buat Akun Dummy untuk Testing
	hash, _ := bcrypt.GenerateFromPassword([]byte("password123"), bcrypt.DefaultCost)
	pass := string(hash)

	admin := models.User{Name: "Admin", Email: "admin@test.com", Password: pass, Role: "admin"}
	dosen := models.User{Name: "Dosen", Email: "dosen@test.com", Password: pass, Role: "dosen"}
	mhs := models.User{Name: "Mhs", Email: "mhs@test.com", Password: pass, Role: "mahasiswa"}
	ortu := models.User{Name: "Ortu", Email: "ortu@test.com", Password: pass, Role: "orangtua"}

	_ = testDB.Create(&admin).Error
	_ = testDB.Create(&dosen).Error
	_ = testDB.Create(&mhs).Error
	_ = testDB.Create(&ortu).Error

	adminID = admin.ID
	dosenID = dosen.ID
	mhsID = mhs.ID
	ortuID = ortu.ID

	// Jalankan semua tes
	code := m.Run()
	_ = testDB.Exec(`TRUNCATE TABLE users, courses, classes, enrollments, grades, attendances, qr_sessions, ukts, announcements, schedules, packages, cases, documents, khs_records, parent_students CASCADE;`).Error
	os.Exit(code)
}

// --- HELPER FUNCTIONS ---
func newRequest(method, path string, body interface{}) *http.Request {
	var buf bytes.Buffer
	if body != nil {
		// PERBAIKAN: Menambahkan _ = untuk errcheck
		_ = json.NewEncoder(&buf).Encode(body)
	}
	req, _ := http.NewRequest(method, path, &buf)
	req.Header.Set("Content-Type", "application/json")
	return req
}

func withUserID(req *http.Request, userID uint) *http.Request {
	ctx := context.WithValue(req.Context(), middlewares.UserIDKey, userID)
	return req.WithContext(ctx)
}

func withRole(req *http.Request, role string) *http.Request {
	ctx := context.WithValue(req.Context(), middlewares.RoleKey, role)
	return req.WithContext(ctx)
}

// ==========================================
// 1. AUTH TESTS
// ==========================================
func TestAuth_Register_Success(t *testing.T) {
	handler := &handlers.AuthHandler{DB: testDB}
	body := map[string]string{"name": "Budi", "email": "budi@test.com", "password": "password123", "role": "mahasiswa"}
	req := newRequest("POST", "/register", body)
	w := httptest.NewRecorder()
	handler.Register(w, req)
	if w.Code != http.StatusCreated {
		t.Errorf("Expected 201, got %d", w.Code)
	}
}

func TestAuth_Login_Success(t *testing.T) {
	handler := &handlers.AuthHandler{DB: testDB}
	body := map[string]string{"email": "admin@test.com", "password": "password123"}
	req := newRequest("POST", "/login", body)
	w := httptest.NewRecorder()
	handler.Login(w, req)
	if w.Code != http.StatusOK {
		t.Errorf("Expected 200, got %d", w.Code)
	}
}

// ==========================================
// 2. ADMIN TESTS
// ==========================================
func TestAuth_UpdateProfile_DoesNotChangeAdminManagedFields(t *testing.T) {
	user := models.User{
		Name: "Profil Lama", Email: "profile-self@test.com", Password: "not-used",
		Role: "mahasiswa", NIM: "NIM-OLD", ProgramStudi: "PRODI-OLD",
	}
	if err := testDB.Create(&user).Error; err != nil {
		t.Fatalf("create profile fixture: %v", err)
	}

	handler := &handlers.AuthHandler{DB: testDB}
	body := map[string]string{
		"name": "Profil Baru", "email": user.Email,
		"nim": "NIM-HACK", "program_studi": "PRODI-HACK",
	}
	req := withRole(withUserID(newRequest(http.MethodPut, "/users/me", body), user.ID), "mahasiswa")
	w := httptest.NewRecorder()
	handler.UpdateProfile(w, req)
	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", w.Code, w.Body.String())
	}

	var updated models.User
	if err := testDB.First(&updated, user.ID).Error; err != nil {
		t.Fatalf("read updated profile: %v", err)
	}
	if updated.Name != "Profil Baru" {
		t.Fatalf("name was not updated: %q", updated.Name)
	}
	if updated.NIM != "NIM-OLD" || updated.ProgramStudi != "PRODI-OLD" {
		t.Fatalf("self-service profile changed admin-managed fields: NIM=%q ProgramStudi=%q", updated.NIM, updated.ProgramStudi)
	}
}

func TestAdmin_CreateUser_Success(t *testing.T) {
	handler := &handlers.AdminHandler{DB: testDB}
	body := map[string]string{"name": "User Baru", "email": "userbaru@test.com", "password": "password123", "role": "mahasiswa"}
	req := newRequest("POST", "/admin/users/create", body)
	w := httptest.NewRecorder()
	handler.CreateUser(w, req)
	if w.Code != http.StatusCreated {
		t.Errorf("Expected 201, got %d", w.Code)
	}
}

func TestAdmin_UpdateUser_CanClearOptionalFieldsAndPreserveOmittedFields(t *testing.T) {
	user := models.User{
		Name: "Mahasiswa Update", Email: "update-fields@test.com", Password: "not-used",
		Role: "mahasiswa", NIM: "202600002", NIDN: "NIDN-KEEP", NIP: "NIP-KEEP", ProgramStudi: "TRKJ",
	}
	if err := testDB.Create(&user).Error; err != nil {
		t.Fatalf("create user fixture: %v", err)
	}

	handler := &handlers.AdminHandler{DB: testDB}
	body := map[string]string{
		"name": "Mahasiswa Update", "email": user.Email, "role": "mahasiswa",
		"nim": "", "program_studi": "",
	}
	req := withRole(newRequest(http.MethodPut, "/admin/users/update?id="+strconv.FormatUint(uint64(user.ID), 10), body), "admin")
	w := httptest.NewRecorder()
	handler.UpdateUser(w, req)
	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", w.Code, w.Body.String())
	}

	var updated models.User
	if err := testDB.First(&updated, user.ID).Error; err != nil {
		t.Fatalf("read updated user: %v", err)
	}
	if updated.NIM != "" || updated.ProgramStudi != "" {
		t.Fatalf("explicitly empty optional fields were not cleared: NIM=%q ProgramStudi=%q", updated.NIM, updated.ProgramStudi)
	}
	if updated.NIDN != "NIDN-KEEP" || updated.NIP != "NIP-KEEP" {
		t.Fatalf("omitted optional fields were overwritten: NIDN=%q NIP=%q", updated.NIDN, updated.NIP)
	}
}

func TestDeleteHandlers_ReturnConflictForReferencedRows(t *testing.T) {
	teacher := models.User{Name: "Dosen Referensi", Email: "referenced-teacher@test.com", Password: "not-used", Role: "dosen"}
	course := models.Course{Code: "REF-101", Name: "Referenced Course", SKS: 3, Semester: 1}
	if err := testDB.Create(&teacher).Error; err != nil {
		t.Fatalf("create teacher fixture: %v", err)
	}
	if err := testDB.Create(&course).Error; err != nil {
		t.Fatalf("create course fixture: %v", err)
	}
	class := models.Class{
		CourseID: course.ID, DosenID: teacher.ID, Name: "Referenced Class",
		Day: "Senin", StartTime: "08:00", EndTime: "10:00", Room: "Lab 1",
	}
	if err := testDB.Create(&class).Error; err != nil {
		t.Fatalf("create class fixture: %v", err)
	}
	schedule := models.Schedule{
		Semester: "2026 Ganjil", ClassID: class.ID, CourseID: course.ID,
		TeacherID: teacher.ID, Day: "Senin", StartTime: "08:00", EndTime: "10:00", Room: "Lab 1",
	}
	if err := testDB.Create(&schedule).Error; err != nil {
		t.Fatalf("create schedule fixture: %v", err)
	}
	t.Cleanup(func() {
		testDB.Delete(&models.Schedule{}, schedule.ID)
		testDB.Delete(&models.Class{}, class.ID)
		testDB.Delete(&models.Course{}, course.ID)
		testDB.Delete(&models.User{}, teacher.ID)
	})

	courseHandler := &handlers.CourseHandler{DB: testDB}
	courseResponse := httptest.NewRecorder()
	courseHandler.DeleteCourse(courseResponse, newRequest(http.MethodDelete, "/courses/delete?id="+strconv.FormatUint(uint64(course.ID), 10), nil))
	if courseResponse.Code != http.StatusConflict {
		t.Fatalf("course delete status = %d, want %d: %s", courseResponse.Code, http.StatusConflict, courseResponse.Body.String())
	}

	classHandler := &handlers.ClassHandler{DB: testDB}
	classResponse := httptest.NewRecorder()
	classHandler.DeleteClass(classResponse, newRequest(http.MethodDelete, "/classes/delete?id="+strconv.FormatUint(uint64(class.ID), 10), nil))
	if classResponse.Code != http.StatusConflict {
		t.Fatalf("class delete status = %d, want %d: %s", classResponse.Code, http.StatusConflict, classResponse.Body.String())
	}

	adminHandler := &handlers.AdminHandler{DB: testDB}
	userResponse := httptest.NewRecorder()
	userRequest := withRole(newRequest(http.MethodDelete, "/admin/users/delete?id="+strconv.FormatUint(uint64(teacher.ID), 10), nil), "admin")
	adminHandler.DeleteUser(userResponse, userRequest)
	if userResponse.Code != http.StatusConflict {
		t.Fatalf("user delete status = %d, want %d: %s", userResponse.Code, http.StatusConflict, userResponse.Body.String())
	}

	for _, row := range []struct {
		model interface{}
		id    uint
	}{
		{&models.Course{}, course.ID},
		{&models.Class{}, class.ID},
		{&models.User{}, teacher.ID},
	} {
		var count int64
		if err := testDB.Model(row.model).Where("id = ?", row.id).Count(&count).Error; err != nil {
			t.Fatalf("verify referenced row remains: %v", err)
		}
		if count != 1 {
			t.Fatalf("referenced row %d was removed after failed delete", row.id)
		}
	}
}

// ==========================================
// 3. COURSE TESTS
// ==========================================
func TestCourse_Create_Success(t *testing.T) {
	handler := &handlers.CourseHandler{DB: testDB}
	body := map[string]interface{}{"code": "CS-101", "name": "Pemrograman", "sks": 3, "semester": 1}
	req := newRequest("POST", "/courses", body)
	w := httptest.NewRecorder()
	handler.CreateCourse(w, req)
	if w.Code != http.StatusCreated {
		t.Errorf("Expected 201, got %d", w.Code)
	}
}

// ==========================================
// 4. CLASS TESTS
// ==========================================
func TestClass_Create_Success(t *testing.T) {
	var course models.Course
	testDB.First(&course)

	handler := &handlers.ClassHandler{DB: testDB}
	body := map[string]interface{}{
		"course_id": course.ID, "dosen_id": dosenID, "name": "Kelas A",
		"day": "Senin", "start_time": "08:00", "end_time": "10:00", "room": "Lab 1",
	}
	req := newRequest("POST", "/classes", body)
	w := httptest.NewRecorder()
	handler.CreateClass(w, req)
	if w.Code != http.StatusCreated {
		t.Errorf("Expected 201, got %d", w.Code)
	}
}

func TestClass_ListScopesDosenToAssignedClasses(t *testing.T) {
	course := models.Course{
		Code: "AUDIT-CLASS", Name: "Mata Kuliah Uji", SKS: 2, Semester: 1,
	}
	if err := testDB.Create(&course).Error; err != nil {
		t.Fatal(err)
	}
	otherLecturer := models.User{
		Name: "Dosen Lain", Email: "other-lecturer@test.com",
		Password: "test-hash", Role: "dosen",
	}
	if err := testDB.Create(&otherLecturer).Error; err != nil {
		t.Fatal(err)
	}
	ownClass := models.Class{
		CourseID: course.ID, DosenID: dosenID, Name: "AUDIT-OWN",
		Day: "Senin", StartTime: "08:00", EndTime: "10:00", Room: "Ruang Uji",
		Year: "2025/2026", Semester: "Ganjil", Status: "Aktif",
	}
	otherClass := models.Class{
		CourseID: course.ID, DosenID: otherLecturer.ID, Name: "AUDIT-OTHER",
		Day: "Selasa", StartTime: "10:00", EndTime: "12:00", Room: "Ruang Uji",
		Year: "2025/2026", Semester: "Ganjil", Status: "Aktif",
	}
	if err := testDB.Create(&[]models.Class{ownClass, otherClass}).Error; err != nil {
		t.Fatal(err)
	}

	handler := &handlers.ClassHandler{DB: testDB}
	req := withRole(
		withUserID(newRequest("GET", "/classes/list", nil), dosenID),
		"dosen",
	)
	recorder := httptest.NewRecorder()
	handler.GetClasses(recorder, req)
	if recorder.Code != http.StatusOK {
		t.Fatalf("GetClasses() status = %d, want %d", recorder.Code, http.StatusOK)
	}

	var response struct {
		Data struct {
			Data []models.Class `json:"data"`
		} `json:"data"`
	}
	if err := json.Unmarshal(recorder.Body.Bytes(), &response); err != nil {
		t.Fatal(err)
	}
	names := make(map[string]bool)
	for _, class := range response.Data.Data {
		names[class.Name] = true
		if class.DosenID != dosenID {
			t.Fatalf("dosen received class for another lecturer: %s", class.Name)
		}
	}
	if !names["AUDIT-OWN"] {
		t.Fatal("dosen response does not include the lecturer's class")
	}
	if names["AUDIT-OTHER"] {
		t.Fatal("dosen response includes another lecturer's class")
	}
}

// ==========================================
// 5. ENROLLMENT TESTS
// ==========================================
func TestEnrollment_Enroll_Success(t *testing.T) {
	var class models.Class
	testDB.First(&class)

	handler := &handlers.EnrollmentHandler{DB: testDB}
	body := map[string]interface{}{"class_id": class.ID}
	req := newRequest("POST", "/enrollments", body)
	req = withUserID(req, mhsID)
	w := httptest.NewRecorder()
	handler.EnrollClass(w, req)
	if w.Code != http.StatusCreated {
		t.Errorf("Expected 201, got %d", w.Code)
	}
}

// ==========================================
// 6. GRADE TESTS
// ==========================================
func TestGrade_Input_Success(t *testing.T) {
	var class models.Class
	testDB.First(&class)

	handler := &handlers.GradeHandler{DB: testDB}
	body := map[string]interface{}{
		"mahasiswa_id": mhsID, "class_id": class.ID, "score": 85.5, "letter": "A",
	}
	req := newRequest("POST", "/grades", body)
	req = withUserID(req, dosenID)
	w := httptest.NewRecorder()
	handler.InputGrade(w, req)
	if w.Code != http.StatusOK {
		t.Errorf("Expected 200, got %d", w.Code)
	}
}

// ==========================================
// 7. ATTENDANCE TESTS
// ==========================================
func TestAttendance_Input_Success(t *testing.T) {
	var class models.Class
	testDB.First(&class)

	handler := &handlers.AttendanceHandler{DB: testDB}
	body := map[string]interface{}{
		"mahasiswa_id": mhsID, "class_id": class.ID, "date": "2026-10-30", "status": "hadir",
	}
	req := newRequest("POST", "/attendances", body)
	req = withUserID(req, dosenID)
	w := httptest.NewRecorder()
	handler.InputAttendance(w, req)
	if w.Code != http.StatusCreated {
		t.Errorf("Expected 201, got %d", w.Code)
	}
}

// ==========================================
// 8. PARENT TESTS
// ==========================================
func TestParent_Link_Success(t *testing.T) {
	handler := &handlers.ParentHandler{DB: testDB}
	body := map[string]interface{}{"parent_id": ortuID, "student_id": mhsID}
	req := newRequest("POST", "/admin/parents/link", body)
	w := httptest.NewRecorder()
	handler.LinkParent(w, req)
	if w.Code != http.StatusCreated {
		t.Errorf("Expected 201, got %d", w.Code)
	}
}

// ==========================================
// 9. UKT TESTS
// ==========================================
func TestUKT_Create_Success(t *testing.T) {
	handler := &handlers.UKTHandler{DB: testDB}
	body := map[string]interface{}{
		"student_id": mhsID, "semester": "2026 Ganjil", "billed": 5000000, "paid": 2500000, "due_date": "2026-12-31",
	}
	req := withRole(newRequest("POST", "/admin/ukt", body), "admin")
	w := httptest.NewRecorder()
	handler.CreateUKT(w, req)
	if w.Code != http.StatusCreated {
		t.Errorf("Expected 201, got %d", w.Code)
	}
}

// ==========================================
// 10. ANNOUNCEMENT TESTS
// ==========================================
func TestAnnouncement_Create_Success(t *testing.T) {
	handler := &handlers.AnnouncementHandler{DB: testDB}
	body := map[string]interface{}{
		"title": "Info UTS", "category": "Akademik", "content": "Ujian minggu depan",
		"start_date": "2026-10-30", "end_date": "2026-11-05", "status": "Aktif",
	}
	req := newRequest("POST", "/admin/announcements", body)
	w := httptest.NewRecorder()
	handler.CreateAnnouncement(w, req)
	if w.Code != http.StatusCreated {
		t.Errorf("Expected 201, got %d", w.Code)
	}
}

func TestAnnouncement_ListHidesInactiveRecordsFromNonAdminRoles(t *testing.T) {
	now := time.Now()
	fixtures := []models.Announcement{
		{
			Title: "AUDIT-active", Category: "Akademik", Content: "active",
			Status: "Aktif", StartDate: now.Add(-time.Hour), EndDate: now.Add(time.Hour),
		},
		{
			Title: "AUDIT-draft", Category: "Akademik", Content: "draft",
			Status: "Draf", StartDate: now.Add(-time.Hour), EndDate: now.Add(time.Hour),
		},
		{
			Title: "AUDIT-expired", Category: "Akademik", Content: "expired",
			Status: "Aktif", StartDate: now.Add(-2 * time.Hour), EndDate: now.Add(-time.Hour),
		},
		{
			Title: "AUDIT-future", Category: "Akademik", Content: "future",
			Status: "Aktif", StartDate: now.Add(time.Hour), EndDate: now.Add(2 * time.Hour),
		},
	}
	if err := testDB.Create(&fixtures).Error; err != nil {
		t.Fatal(err)
	}

	handler := &handlers.AnnouncementHandler{DB: testDB}
	readTitles := func(role string) []string {
		req := withRole(newRequest("GET", "/admin/announcements/list", nil), role)
		recorder := httptest.NewRecorder()
		handler.GetAllAnnouncements(recorder, req)
		if recorder.Code != http.StatusOK {
			t.Fatalf("GetAllAnnouncements() status = %d, want %d", recorder.Code, http.StatusOK)
		}
		var response struct {
			Data []models.Announcement `json:"data"`
		}
		if err := json.Unmarshal(recorder.Body.Bytes(), &response); err != nil {
			t.Fatal(err)
		}
		titles := make([]string, 0)
		for _, announcement := range response.Data {
			if strings.HasPrefix(announcement.Title, "AUDIT-") {
				titles = append(titles, announcement.Title)
			}
		}
		return titles
	}

	studentTitles := readTitles("mahasiswa")
	if len(studentTitles) != 1 || studentTitles[0] != "AUDIT-active" {
		t.Fatalf("student announcement titles = %v, want only AUDIT-active", studentTitles)
	}

	adminTitles := readTitles("admin")
	if len(adminTitles) != len(fixtures) {
		t.Fatalf("admin audit announcement count = %d, want %d", len(adminTitles), len(fixtures))
	}
	kaprodiTitles := readTitles("kaprodi")
	if len(kaprodiTitles) != len(fixtures) {
		t.Fatalf("kaprodi audit announcement count = %d, want %d", len(kaprodiTitles), len(fixtures))
	}

	parentHandler := &handlers.ParentHandler{DB: testDB}
	parentResponse := httptest.NewRecorder()
	parentHandler.GetAnnouncements(
		parentResponse,
		newRequest("GET", "/parent/announcements", nil),
	)
	if parentResponse.Code != http.StatusOK {
		t.Fatalf("GetAnnouncements() status = %d, want %d", parentResponse.Code, http.StatusOK)
	}
	var parentEnvelope struct {
		Data []models.Announcement `json:"data"`
	}
	if err := json.Unmarshal(parentResponse.Body.Bytes(), &parentEnvelope); err != nil {
		t.Fatal(err)
	}
	parentTitles := make([]string, 0)
	for _, announcement := range parentEnvelope.Data {
		if strings.HasPrefix(announcement.Title, "AUDIT-") {
			parentTitles = append(parentTitles, announcement.Title)
		}
	}
	if len(parentTitles) != 1 || parentTitles[0] != "AUDIT-active" {
		t.Fatalf("parent announcement titles = %v, want only AUDIT-active", parentTitles)
	}
}

// ==========================================
// 11. SCHEDULE TESTS
// ==========================================
func TestSchedule_Create_Success(t *testing.T) {
	var class models.Class
	testDB.First(&class)

	handler := &handlers.ScheduleHandler{DB: testDB}
	body := map[string]interface{}{
		"semester": "2026 Ganjil", "class_id": class.ID, "course_id": class.CourseID,
		"teacher_id": dosenID, "day": "Senin", "start_time": "08:00", "end_time": "10:00", "room": "Lab 1",
	}
	req := newRequest("POST", "/admin/schedules", body)
	w := httptest.NewRecorder()
	handler.CreateSchedule(w, req)
	if w.Code != http.StatusCreated {
		t.Errorf("Expected 201, got %d", w.Code)
	}
}

// ==========================================
// 12. PACKAGE TESTS
// ==========================================
func TestPackage_Create_Success(t *testing.T) {
	var course models.Course
	testDB.First(&course)
	var class models.Class
	testDB.First(&class)

	handler := &handlers.PackageHandler{DB: testDB}
	body := map[string]interface{}{
		"name": "Paket Sem 1", "term": 1, "status": "Siap",
		"course_ids": []uint{course.ID}, "class_ids": []uint{class.ID},
	}
	req := newRequest("POST", "/admin/packages", body)
	w := httptest.NewRecorder()
	handler.CreatePackage(w, req)
	if w.Code != http.StatusCreated {
		t.Errorf("Expected 201, got %d", w.Code)
	}
}

// ==========================================
// 13. CASE TESTS
// ==========================================
func TestCase_Create_Success(t *testing.T) {
	handler := &handlers.CaseHandler{DB: testDB}
	body := map[string]interface{}{
		"student_id": mhsID, "level": "SP 1", "reason": "Sering absen", "followup": "Panggil ortu", "status": "Draf",
	}
	req := withRole(newRequest("POST", "/admin/cases", body), "admin")
	w := httptest.NewRecorder()
	handler.CreateCase(w, req)
	if w.Code != http.StatusCreated {
		t.Errorf("Expected 201, got %d", w.Code)
	}
}

// ==========================================
// 14. DOCUMENT TESTS
// ==========================================
func TestDocument_Create_Success(t *testing.T) {
	handler := &handlers.DocumentHandler{DB: testDB}
	body := map[string]interface{}{
		"student_id": mhsID, "type": "KRS", "semester": "2026 Ganjil", "status": "Draf", "date": "2026-10-30",
	}
	req := withRole(newRequest("POST", "/admin/documents", body), "admin")
	w := httptest.NewRecorder()
	handler.CreateDocument(w, req)
	if w.Code != http.StatusCreated {
		t.Errorf("Expected 201, got %d", w.Code)
	}
}

// ==========================================
// 15. KHS TESTS
// ==========================================
func TestKHS_Update_Success(t *testing.T) {
	handler := &handlers.KHSHandler{DB: testDB}
	body := map[string]interface{}{
		"student_id": mhsID, "semester": "2026 Ganjil", "status": "Siap dipublikasikan",
	}
	req := withRole(newRequest("PUT", "/admin/khs/update", body), "admin")
	w := httptest.NewRecorder()
	handler.UpdateKHStatus(w, req)
	if w.Code != http.StatusOK {
		t.Errorf("Expected 200, got %d", w.Code)
	}
}

// ==========================================
// 16. QR ATTENDANCE TESTS
// ==========================================
func TestQR_GenerateScanAndRejectDuplicate(t *testing.T) {
	var class models.Class
	if err := testDB.First(&class).Error; err != nil {
		t.Fatalf("class fixture unavailable: %v", err)
	}

	handler := &handlers.QRHandler{DB: testDB}
	generateReq := withUserID(newRequest("POST", "/qr/generate", map[string]interface{}{
		"class_id": class.ID,
	}), dosenID)
	generateW := httptest.NewRecorder()
	handler.GenerateQR(generateW, generateReq)
	if generateW.Code != http.StatusCreated {
		t.Fatalf("expected QR generation status 201, got %d: %s", generateW.Code, generateW.Body.String())
	}

	var generated struct {
		Data struct {
			Token string `json:"token"`
		} `json:"data"`
	}
	if err := json.Unmarshal(generateW.Body.Bytes(), &generated); err != nil {
		t.Fatalf("decode generated QR response: %v", err)
	}
	if generated.Data.Token == "" {
		t.Fatal("generated QR token must not be empty")
	}

	scan := func() *httptest.ResponseRecorder {
		req := withUserID(newRequest("POST", "/qr/scan", map[string]string{
			"token": generated.Data.Token,
		}), mhsID)
		recorder := httptest.NewRecorder()
		handler.ScanQR(recorder, req)
		return recorder
	}

	firstScan := scan()
	if firstScan.Code != http.StatusCreated {
		t.Fatalf("expected first scan status 201, got %d: %s", firstScan.Code, firstScan.Body.String())
	}
	secondScan := scan()
	if secondScan.Code != http.StatusConflict {
		t.Fatalf("expected duplicate scan status 409, got %d: %s", secondScan.Code, secondScan.Body.String())
	}
}

func TestQR_GenerateForbiddenForOtherLecturer(t *testing.T) {
	var class models.Class
	if err := testDB.First(&class).Error; err != nil {
		t.Fatalf("class fixture unavailable: %v", err)
	}

	handler := &handlers.QRHandler{DB: testDB}
	req := withUserID(newRequest("POST", "/qr/generate", map[string]interface{}{
		"class_id": class.ID,
	}), adminID)
	recorder := httptest.NewRecorder()
	handler.GenerateQR(recorder, req)
	if recorder.Code != http.StatusForbidden {
		t.Fatalf("expected status 403, got %d: %s", recorder.Code, recorder.Body.String())
	}
}
