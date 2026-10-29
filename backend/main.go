package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/raihanmuzaffar/edu-track-campus/backend/handlers"
	"github.com/raihanmuzaffar/edu-track-campus/backend/middlewares"
	"github.com/raihanmuzaffar/edu-track-campus/backend/models"
	"github.com/raihanmuzaffar/edu-track-campus/backend/utils"
	"github.com/redis/go-redis/v9"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

var rdb *redis.Client

func main() {
	// ==========================================
	// 1. KONEKSI DATABASE POSTGRESQL (LOKAL)
	// ==========================================
	dbHost := os.Getenv("DB_HOST")
	dbUser := os.Getenv("DB_USER")
	dbPass := os.Getenv("DB_PASSWORD")
	dbName := os.Getenv("DB_NAME")
	dbPort := os.Getenv("DB_PORT")

	dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=disable TimeZone=Asia/Jakarta",
		dbHost, dbUser, dbPass, dbName, dbPort)

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatalf("Gagal koneksi ke PostgreSQL: %v", err)
	}
	fmt.Println("✅ Berhasil terhubung ke PostgreSQL Lokal!")

	// ==========================================
	// 2. KONEKSI REDIS (LOKAL)
	// ==========================================
	rdb = redis.NewClient(&redis.Options{
		Addr:     "redis:6379", // Menggunakan nama service 'redis' dari docker-compose
		Password: "",            // Tanpa password untuk lokal
		DB:       0,
	})

	ctx := context.Background()
	_, err = rdb.Ping(ctx).Result()
	if err != nil {
		log.Printf("⚠️ Peringatan: Gagal terhubung ke Redis Lokal: %v", err)
	} else {
		fmt.Println("✅ Berhasil terhubung ke Redis Lokal!")
	}

	// ==========================================
	// 3. AUTO MIGRATE MODEL
	// ==========================================
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
		&models.Package{},
		&models.Case{},
		&models.Document{},
		&models.KHSRecord{},
	); err != nil {
		log.Fatalf("Gagal melakukan migrasi database: %v", err)
	}
	fmt.Println("✅ Berhasil melakukan migrasi database!")

	// ==========================================
	// 4. INISIALISASI HANDLER
	// ==========================================
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
	packageHandler := &handlers.PackageHandler{DB: db}
	caseHandler := &handlers.CaseHandler{DB: db}
	documentHandler := &handlers.DocumentHandler{DB: db}
	khsHandler := &handlers.KHSHandler{DB: db}

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

	// --- FITUR ADMIN & KAPRODI ---
	http.Handle("/api/v1/admin/stats", middlewares.AuthMiddleware("admin")(http.HandlerFunc(adminHandler.GetDashboardStats)))
	
	// Users (Mahasiswa/Dosen)
	http.Handle("/api/v1/admin/users", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(adminHandler.GetAllUsers)))
	http.Handle("/api/v1/admin/users/create", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(adminHandler.CreateUser)))
	http.Handle("/api/v1/admin/users/update", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(adminHandler.UpdateUser)))
	http.Handle("/api/v1/admin/users/delete", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(adminHandler.DeleteUser)))

	// Course (Mata Kuliah)
	http.Handle("/api/v1/courses", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(courseHandler.CreateCourse)))
	http.Handle("/api/v1/courses/list", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(courseHandler.GetCourses)))
	http.Handle("/api/v1/courses/update", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(courseHandler.UpdateCourse)))
	http.Handle("/api/v1/courses/delete", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(courseHandler.DeleteCourse)))

	// Class (Kelas)
	http.Handle("/api/v1/classes", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(classHandler.CreateClass)))
	http.Handle("/api/v1/classes/list", middlewares.AuthMiddleware("admin", "kaprodi", "dosen", "mahasiswa", "orangtua")(http.HandlerFunc(classHandler.GetClasses)))
	http.Handle("/api/v1/classes/update", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(classHandler.UpdateClass)))
	http.Handle("/api/v1/classes/delete", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(classHandler.DeleteClass)))

	// Enrollment (KRS)
	http.Handle("/api/v1/enrollments", middlewares.AuthMiddleware("mahasiswa")(http.HandlerFunc(enrollmentHandler.EnrollClass)))
	http.Handle("/api/v1/enrollments/my", middlewares.AuthMiddleware("mahasiswa")(http.HandlerFunc(enrollmentHandler.GetMyKRS)))
	http.Handle("/api/v1/admin/krs/list", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(enrollmentHandler.GetAllEnrollments)))

	// Grades (Nilai)
	http.Handle("/api/v1/grades", middlewares.AuthMiddleware("dosen")(http.HandlerFunc(gradeHandler.InputGrade)))
	http.Handle("/api/v1/grades/my", middlewares.AuthMiddleware("mahasiswa")(http.HandlerFunc(gradeHandler.GetMyGrades)))
	http.Handle("/api/v1/admin/grades/list", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(gradeHandler.GetAllGrades)))

	// Attendance (Absensi)
	http.Handle("/api/v1/attendances", middlewares.AuthMiddleware("dosen")(http.HandlerFunc(attendanceHandler.InputAttendance)))
	http.Handle("/api/v1/attendances/my", middlewares.AuthMiddleware("mahasiswa")(http.HandlerFunc(attendanceHandler.GetMyAttendance)))
	http.Handle("/api/v1/admin/attendances/list", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(attendanceHandler.GetAllAttendance)))

	// UKT
	http.Handle("/api/v1/admin/ukt", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(uktHandler.CreateUKT)))
	http.Handle("/api/v1/admin/ukt/list", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(uktHandler.GetAllUKT)))
	http.Handle("/api/v1/admin/ukt/update", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(uktHandler.UpdateUKT)))
	http.Handle("/api/v1/admin/ukt/delete", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(uktHandler.DeleteUKT)))

	// Announcements
	http.Handle("/api/v1/admin/announcements", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(announcementHandler.CreateAnnouncement)))
	http.Handle("/api/v1/admin/announcements/list", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(announcementHandler.GetAllAnnouncements)))
	http.Handle("/api/v1/admin/announcements/update", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(announcementHandler.UpdateAnnouncement)))
	http.Handle("/api/v1/admin/announcements/delete", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(announcementHandler.DeleteAnnouncement)))

	// Schedules
	http.Handle("/api/v1/admin/schedules", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(scheduleHandler.CreateSchedule)))
	http.Handle("/api/v1/admin/schedules/list", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(scheduleHandler.GetAllSchedules)))
	http.Handle("/api/v1/admin/schedules/update", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(scheduleHandler.UpdateSchedule)))
	http.Handle("/api/v1/admin/schedules/delete", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(scheduleHandler.DeleteSchedule)))

	// Packages
	http.Handle("/api/v1/admin/packages", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(packageHandler.CreatePackage)))
	http.Handle("/api/v1/admin/packages/list", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(packageHandler.GetAllPackages)))
	http.Handle("/api/v1/admin/packages/update", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(packageHandler.UpdatePackage)))
	http.Handle("/api/v1/admin/packages/delete", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(packageHandler.DeletePackage)))

	// Cases (SP)
	http.Handle("/api/v1/admin/cases", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(caseHandler.CreateCase)))
	http.Handle("/api/v1/admin/cases/list", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(caseHandler.GetAllCases)))
	http.Handle("/api/v1/admin/cases/update", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(caseHandler.UpdateCase)))
	http.Handle("/api/v1/admin/cases/delete", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(caseHandler.DeleteCase)))

	// Documents
	http.Handle("/api/v1/admin/documents", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(documentHandler.CreateDocument)))
	http.Handle("/api/v1/admin/documents/list", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(documentHandler.GetAllDocuments)))
	http.Handle("/api/v1/admin/documents/update", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(documentHandler.UpdateDocument)))
	http.Handle("/api/v1/admin/documents/delete", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(documentHandler.DeleteDocument)))

	// KHS
	http.Handle("/api/v1/admin/khs/list", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(khsHandler.GetAllKHS)))
	http.Handle("/api/v1/admin/khs/update", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(khsHandler.UpdateKHStatus)))

	// ==========================================
	// 5. JALANKAN SERVER (LOKAL)
	// ==========================================
	corsHandler := middlewares.EnableCORS(http.DefaultServeMux)

	fmt.Println("🚀 Server berjalan di port 8080 (Mode Lokal)")
	if err := http.ListenAndServe(":8080", corsHandler); err != nil {
		log.Fatal(err)
	}
}