package main

import (
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/raihanmuzaffar/edu-track-campus/backend/handlers"
	"github.com/raihanmuzaffar/edu-track-campus/backend/middlewares"
	"github.com/raihanmuzaffar/edu-track-campus/backend/models"
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

	// 3. Auto Migrate Model (User & Course)
	db.AutoMigrate(&models.User{}, &models.Course{})

	// 4. Inisialisasi Handler
	authHandler := &handlers.AuthHandler{DB: db}
	courseHandler := &handlers.CourseHandler{DB: db} // Tambahan CourseHandler

	// ==========================================
	// --- PUBLIC ROUTES (Bisa diakses tanpa login) ---
	// ==========================================
	http.HandleFunc("/api/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, `{"status": "OK", "message": "Edu-Track Backend is running!"}`)
	})

	http.HandleFunc("/api/v1/register", authHandler.Register)
	http.HandleFunc("/api/v1/login", authHandler.Login)

	// ==========================================
	// --- PROTECTED ROUTES (Wajib Login / Punya JWT) ---
	// ==========================================

	// 1. Route Khusus Mobile (Mahasiswa, Dosen, Orang Tua)
	mobileDashboardHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		role := r.Context().Value("role").(string)
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, `{"message": "Selamat datang di Mobile Dashboard", "role_anda": "%s"}`, role)
	})
	http.Handle("/api/v1/mobile/dashboard", middlewares.AuthMiddleware("mahasiswa", "dosen", "orangtua")(mobileDashboardHandler))

	// 2. Route Khusus Web Admin & Kaprodi
	webAdminHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		role := r.Context().Value("role").(string)
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, `{"message": "Selamat datang di Web Admin Dashboard", "role_anda": "%s"}`, role)
	})
	http.Handle("/api/v1/admin/dashboard", middlewares.AuthMiddleware("admin", "kaprodi")(webAdminHandler))

	// 3. Route Manajemen Mata Kuliah (Course)
	// Hanya Admin yang bisa Create
	http.Handle("/api/v1/courses", middlewares.AuthMiddleware("admin")(http.HandlerFunc(courseHandler.CreateCourse)))
	
	// Admin dan Kaprodi bisa melihat daftar mata kuliah
	http.Handle("/api/v1/courses/list", middlewares.AuthMiddleware("admin", "kaprodi")(http.HandlerFunc(courseHandler.GetCourses)))


	// 5. Jalankan Server
	fmt.Println("🚀 Server berjalan di port 8080")
	if err := http.ListenAndServe(":8080", nil); err != nil {
		log.Fatal(err)
	}
}