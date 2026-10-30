package handlers_test

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"

	
	"github.com/raihanmuzaffar/edu-track-campus/backend/handlers"
	"github.com/raihanmuzaffar/edu-track-campus/backend/middlewares"
	"github.com/raihanmuzaffar/edu-track-campus/backend/models"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

var testDB *gorm.DB
var adminToken, dosenToken, mhsToken, ortuToken string
var adminID, dosenID, mhsID, ortuID uint

func TestMain(m *testing.M) {
	// Setup Koneksi Database
	dsn := "host=localhost user=admin_edutrack password=supersecretpassword123 dbname=edutrack_db port=5432 sslmode=disable TimeZone=Asia/Jakarta"
	var err error
	testDB, err = gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		panic("Gagal koneksi DB testing")
	}

	// Bersihkan semua tabel
	testDB.Exec(`TRUNCATE TABLE users, courses, classes, enrollments, grades, attendances, ukts, announcements, schedules, packages, cases, documents, khs_records, parent_students CASCADE;`)

	// Migrate
	testDB.AutoMigrate(
		&models.User{}, &models.Course{}, &models.Class{}, &models.Enrollment{},
		&models.Grade{}, &models.Attendance{}, &models.UKT{}, &models.Announcement{},
		&models.Schedule{}, &models.Package{}, &models.Case{}, &models.Document{},
		&models.KHSRecord{}, &models.ParentStudent{},
	)

	// Buat Akun Dummy untuk Testing
	hash, _ := bcrypt.GenerateFromPassword([]byte("password123"), bcrypt.DefaultCost)
	pass := string(hash)

	admin := models.User{Name: "Admin", Email: "admin@test.com", Password: pass, Role: "admin"}
	dosen := models.User{Name: "Dosen", Email: "dosen@test.com", Password: pass, Role: "dosen"}
	mhs := models.User{Name: "Mhs", Email: "mhs@test.com", Password: pass, Role: "mahasiswa"}
	ortu := models.User{Name: "Ortu", Email: "ortu@test.com", Password: pass, Role: "orangtua"}

	testDB.Create(&admin)
	testDB.Create(&dosen)
	testDB.Create(&mhs)
	testDB.Create(&ortu)

	adminID = admin.ID
	dosenID = dosen.ID
	mhsID = mhs.ID
	ortuID = ortu.ID

	// Jalankan semua tes
	code := m.Run()
	testDB.Exec(`TRUNCATE TABLE users, courses, classes, enrollments, grades, attendances, ukts, announcements, schedules, packages, cases, documents, khs_records, parent_students CASCADE;`)
	os.Exit(code)
}

// --- HELPER FUNCTIONS ---
func newRequest(method, path string, body interface{}) *http.Request {
	var buf bytes.Buffer
	if body != nil {
		json.NewEncoder(&buf).Encode(body)
	}
	req, _ := http.NewRequest(method, path, &buf)
	req.Header.Set("Content-Type", "application/json")
	return req
}

func withUserID(req *http.Request, userID uint) *http.Request {
	ctx := context.WithValue(req.Context(), middlewares.UserIDKey, userID)
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
	req := newRequest("POST", "/admin/ukt", body)
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
	req := newRequest("POST", "/admin/cases", body)
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
	req := newRequest("POST", "/admin/documents", body)
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
	req := newRequest("POST", "/admin/khs/update", body)
	w := httptest.NewRecorder()
	handler.UpdateKHStatus(w, req)
	if w.Code != http.StatusOK {
		t.Errorf("Expected 200, got %d", w.Code)
	}
}