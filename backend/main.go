package main

import (
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/raihanmuzaffar/edu-track-campus/backend/handlers"
	"github.com/raihanmuzaffar/edu-track-campus/backend/middlewares"
	"github.com/raihanmuzaffar/edu-track-campus/backend/models"
	"github.com/raihanmuzaffar/edu-track-campus/backend/utils"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func main() {
	// 1. Ambil Environment Variables
	dbHost := os.Getenv("DB_HOST")
	dbUser := os.Getenv("DB_USER")
	dbPass := os.Getenv("DB_PASSWORD")
	dbName := os.Getenv("DB_NAME")
	dbPort := os.Getenv("DB_PORT")

	// 2. Koneksi ke Database PostgreSQL
	dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=disable TimeZone=Asia/Jakarta",
		dbHost, dbUser, dbPass, dbName, dbPort)

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatalf("Gagal koneksi ke PostgreSQL: %v", err)
	}
	fmt.Println("✅ Berhasil terhubung ke PostgreSQL!")

	// 3. Auto Migrate Model
	if err := db.AutoMigrate(
		&models.User{}, 
		&models.Course{}, 
		&models.Class{}, 
		&models.Enrollment{}, 
		&models.Grade{}, 
		&models.Attendance{},
		&models.UKT{},
		&models.Announcement{},
		&models.Schedule{},
	); err != nil {
		log.Fatalf("Gagal melakukan migrasi database: %v", err)
	}
	fmt.Println("✅ Berhasil melakukan migrasi database!")

	// 4. Inisialisasi Handler
	authHandler := &handlers.AuthHandler{DB: db}
	courseHandler := &handlers.CourseHandler{DB: db}
	classHandler := &handlers.ClassHandler{DB: db}
	enrollmentHandler := &handlers.EnrollmentHandler{DB: db}
	gradeHandler := &handlers.GradeHandler{DB: db}
	attendanceHandler := &handlers.AttendanceHandler{DB: db}
	adminHandler := &handlers.AdminHandler{DB: db}
	uktHandler := &handlers.UKTHandler{DB: db}
	announcementHandler := &handlers.AnnouncementHandler{DB: db}
	scheduleHandler := &handlers.ScheduleHandler{DB: db}

	// ==========================================
	// --- PUBLIC ROUTES ---
	// ==========================================
	http.HandleFunc("/api/health", func(w http.ResponseWriter, r *http.Request) {
		utils.JSONResponse(w, http.StatusOK, "Edu-Track Backend is running!", nil)
	})

	http.HandleFunc("/api/v1/register", authHandler.Register)
	http.HandleFunc("/api/v1/login", authHandler.Login)

	// ==========================================
	// --- PROTECTED ROUTES ---
	// ==========================================

	// Mobile & Web Dashboard
	http.Handle("/api/v1/mobile/dashboard", middlewares.AuthMiddleware("mahasiswa", "dosen", "orangtua")(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		role, _ := r.Context().Value(middlewares.RoleKey).(string)
		utils.JSONResponse(w, http.StatusOK, "Selamat datang di Mobile Dashboard", map[string]string{"role_anda": role})
	})))
	
	http.Handle("/api/v1/admin/dashboard", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		role, _ := r.Context().Value(middlewares.RoleKey).(string)
		utils.JSONResponse(w, http.StatusOK, "Selamat datang di Web Admin Dashboard", map[string]string{"role_anda": role})
	})))

	// --- FITUR ADMIN PRO ---
	http.Handle("/api/v1/admin/stats", middlewares.AuthMiddleware("admin")(http.HandlerFunc(adminHandler.GetDashboardStats)))
	http.Handle("/api/v1/admin/users", middlewares.AuthMiddleware("admin")(http.HandlerFunc(adminHandler.GetAllUsers)))
	
	// Admin CRUD Users
	http.Handle("/api/v1/admin/users/create", middlewares.AuthMiddleware("admin")(http.HandlerFunc(adminHandler.CreateUser)))
	http.Handle("/api/v1/admin/users/update", middlewares.AuthMiddleware("admin")(http.HandlerFunc(adminHandler.UpdateUser)))
	http.Handle("/api/v1/admin/users/delete", middlewares.AuthMiddleware("admin")(http.HandlerFunc(adminHandler.DeleteUser)))

	// Course
	http.Handle("/api/v1/courses", middlewares.AuthMiddleware("admin")(http.HandlerFunc(courseHandler.CreateCourse)))
	http.Handle("/api/v1/courses/list", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(courseHandler.GetCourses)))
	// Tambahan Baru (Course Update & Delete)
	http.Handle("/api/v1/courses/update", middlewares.AuthMiddleware("admin")(http.HandlerFunc(courseHandler.UpdateCourse)))
	http.Handle("/api/v1/courses/delete", middlewares.AuthMiddleware("admin")(http.HandlerFunc(courseHandler.DeleteCourse)))

	// Class
	http.Handle("/api/v1/classes", middlewares.AuthMiddleware("admin")(http.HandlerFunc(classHandler.CreateClass)))
	http.Handle("/api/v1/classes/list", middlewares.AuthMiddleware("admin", "kaprodi", "dosen", "mahasiswa", "orangtua")(http.HandlerFunc(classHandler.GetClasses)))
	// Tambahan Baru (Class Update & Delete)
	http.Handle("/api/v1/classes/update", middlewares.AuthMiddleware("admin")(http.HandlerFunc(classHandler.UpdateClass)))
	http.Handle("/api/v1/classes/delete", middlewares.AuthMiddleware("admin")(http.HandlerFunc(classHandler.DeleteClass)))

	// Enrollment (KRS)
	http.Handle("/api/v1/enrollments", middlewares.AuthMiddleware("mahasiswa")(http.HandlerFunc(enrollmentHandler.EnrollClass)))
	http.Handle("/api/v1/enrollments/my", middlewares.AuthMiddleware("mahasiswa")(http.HandlerFunc(enrollmentHandler.GetMyKRS)))

	// Grades (Nilai)
	http.Handle("/api/v1/grades", middlewares.AuthMiddleware("dosen")(http.HandlerFunc(gradeHandler.InputGrade)))
	http.Handle("/api/v1/grades/my", middlewares.AuthMiddleware("mahasiswa")(http.HandlerFunc(gradeHandler.GetMyGrades)))

	// Attendance (Absensi)
	http.Handle("/api/v1/attendances", middlewares.AuthMiddleware("dosen")(http.HandlerFunc(attendanceHandler.InputAttendance)))
	http.Handle("/api/v1/attendances/my", middlewares.AuthMiddleware("mahasiswa")(http.HandlerFunc(attendanceHandler.GetMyAttendance)))

	// Admin: All Grades & Attendance
	http.Handle("/api/v1/admin/grades/list", middlewares.AuthMiddleware("admin")(http.HandlerFunc(gradeHandler.GetAllGrades)))
	http.Handle("/api/v1/admin/attendances/list", middlewares.AuthMiddleware("admin")(http.HandlerFunc(attendanceHandler.GetAllAttendance)))

	// UKT (Admin)
	http.Handle("/api/v1/admin/ukt", middlewares.AuthMiddleware("admin")(http.HandlerFunc(uktHandler.CreateUKT)))
	http.Handle("/api/v1/admin/ukt/list", middlewares.AuthMiddleware("admin")(http.HandlerFunc(uktHandler.GetAllUKT)))
	http.Handle("/api/v1/admin/ukt/update", middlewares.AuthMiddleware("admin")(http.HandlerFunc(uktHandler.UpdateUKT)))
	http.Handle("/api/v1/admin/ukt/delete", middlewares.AuthMiddleware("admin")(http.HandlerFunc(uktHandler.DeleteUKT)))

	// Announcements (Admin)
	http.Handle("/api/v1/admin/announcements", middlewares.AuthMiddleware("admin")(http.HandlerFunc(announcementHandler.CreateAnnouncement)))
	http.Handle("/api/v1/admin/announcements/list", middlewares.AuthMiddleware("admin")(http.HandlerFunc(announcementHandler.GetAllAnnouncements)))
	http.Handle("/api/v1/admin/announcements/update", middlewares.AuthMiddleware("admin")(http.HandlerFunc(announcementHandler.UpdateAnnouncement)))
	http.Handle("/api/v1/admin/announcements/delete", middlewares.AuthMiddleware("admin")(http.HandlerFunc(announcementHandler.DeleteAnnouncement)))

	// Schedules (Admin)
	http.Handle("/api/v1/admin/schedules", middlewares.AuthMiddleware("admin")(http.HandlerFunc(scheduleHandler.CreateSchedule)))
	http.Handle("/api/v1/admin/schedules/list", middlewares.AuthMiddleware("admin")(http.HandlerFunc(scheduleHandler.GetAllSchedules)))
	http.Handle("/api/v1/admin/schedules/update", middlewares.AuthMiddleware("admin")(http.HandlerFunc(scheduleHandler.UpdateSchedule)))
	http.Handle("/api/v1/admin/schedules/delete", middlewares.AuthMiddleware("admin")(http.HandlerFunc(scheduleHandler.DeleteSchedule)))

	// 6. Jalankan Server
	fmt.Println("🚀 Server berjalan di port 8080")
	if err := http.ListenAndServe(":8080", nil); err != nil {
		log.Fatal(err)
	}
}