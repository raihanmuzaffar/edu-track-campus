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

	// 3. Auto Migrate Model (Tambahkan models.Grade{})
	if err := db.AutoMigrate(
		&models.User{}, 
		&models.Course{}, 
		&models.Class{}, 
		&models.Enrollment{}, 
		&models.Grade{}, // Tambahan
	); err != nil {
		log.Fatalf("Gagal melakukan migrasi database: %v", err)
	}
	fmt.Println("✅ Berhasil melakukan migrasi database!")

	// 4. Inisialisasi Handler
	authHandler := &handlers.AuthHandler{DB: db}
	courseHandler := &handlers.CourseHandler{DB: db}
	classHandler := &handlers.ClassHandler{DB: db}
	enrollmentHandler := &handlers.EnrollmentHandler{DB: db}
	gradeHandler := &handlers.GradeHandler{DB: db} // Tambahan

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

	// Course
	http.Handle("/api/v1/courses", middlewares.AuthMiddleware("admin")(http.HandlerFunc(courseHandler.CreateCourse)))
	http.Handle("/api/v1/courses/list", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(courseHandler.GetCourses)))

	// Class
	http.Handle("/api/v1/classes", middlewares.AuthMiddleware("admin")(http.HandlerFunc(classHandler.CreateClass)))
	http.Handle("/api/v1/classes/list", middlewares.AuthMiddleware("admin", "kaprodi", "dosen", "mahasiswa", "orangtua")(http.HandlerFunc(classHandler.GetClasses)))

	// Enrollment (KRS)
	http.Handle("/api/v1/enrollments", middlewares.AuthMiddleware("mahasiswa")(http.HandlerFunc(enrollmentHandler.EnrollClass)))
	http.Handle("/api/v1/enrollments/my", middlewares.AuthMiddleware("mahasiswa")(http.HandlerFunc(enrollmentHandler.GetMyKRS)))

	// Grades (Nilai)
	http.Handle("/api/v1/grades", middlewares.AuthMiddleware("dosen")(http.HandlerFunc(gradeHandler.InputGrade)))
	http.Handle("/api/v1/grades/my", middlewares.AuthMiddleware("mahasiswa")(http.HandlerFunc(gradeHandler.GetMyGrades)))

	// 6. Jalankan Server
	fmt.Println("🚀 Server berjalan di port 8080")
	if err := http.ListenAndServe(":8080", nil); err != nil {
		log.Fatal(err)
	}
}