package handlers_test

import (
	
	"log"
	"os"
	"testing"

	"github.com/raihanmuzaffar/edu-track-campus/backend/config"
	"github.com/raihanmuzaffar/edu-track-campus/backend/models"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

var testDB *gorm.DB
var adminToken string

func TestMain(m *testing.M) {
	// 1. Setup Koneksi Database (Menggunakan database lokal Docker)
	// ⚠️ PERINGATAN: Script ini akan menghapus (TRUNCATE) tabel users dan courses di database lokal Anda.
	dsn := "host=localhost user=admin_edutrack password=supersecretpassword123 dbname=edutrack_db port=5432 sslmode=disable TimeZone=Asia/Jakarta"
	
	var err error
	testDB, err = gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatalf("Gagal koneksi DB testing: %v", err)
	}

	// 2. Bersihkan Data Lama & Migrasi
	testDB.Exec("TRUNCATE TABLE users, courses CASCADE")
	testDB.AutoMigrate(&models.User{}, &models.Course{})

	// 3. Buat Akun Admin Default untuk Testing
	hashed, _ := bcrypt.GenerateFromPassword([]byte("password123"), bcrypt.DefaultCost)
	admin := models.User{Name: "Test Admin", Email: "testadmin@test.com", Password: string(hashed), Role: "admin"}
	testDB.Create(&admin)

	// 4. Generate Token Admin
	adminToken, _ = config.GenerateToken(admin.ID, admin.Role)

	// Jalankan semua file tes
	code := m.Run()

	// 5. Bersihkan data setelah tes selesai
	testDB.Exec("TRUNCATE TABLE users, courses CASCADE")
	os.Exit(code)
}