package main

import (
	"fmt"
	"log"
	"os"
	"time"

	"github.com/raihanmuzaffar/edu-track-campus/backend/models"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func main() {
	// 1. Koneksi ke Database
	// Jika dijalankan di luar Docker, hostnya adalah 'localhost'
	dbHost := os.Getenv("DB_HOST")
	if dbHost == "" {
		dbHost = "localhost"
	}
	dbUser := os.Getenv("DB_USER")
	if dbUser == "" {
		dbUser = "admin_edutrack"
	}
	dbPass := os.Getenv("DB_PASSWORD")
	if dbPass == "" {
		dbPass = "supersecretpassword123"
	}
	dbName := os.Getenv("DB_NAME")
	if dbName == "" {
		dbName = "edutrack_db"
	}
	dbPort := os.Getenv("DB_PORT")
	if dbPort == "" {
		dbPort = "5432"
	}

	dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=disable TimeZone=Asia/Jakarta",
		dbHost, dbUser, dbPass, dbName, dbPort)

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatalf("Gagal koneksi ke PostgreSQL: %v", err)
	}
	fmt.Println("✅ Terhubung ke Database.")

	// 2. Bersihkan Data Lama (TRUNCATE CASCADE)
	fmt.Println("🧹 Membersihkan data lama...")
	err = db.Exec(`
		TRUNCATE TABLE users, courses, classes, packages, schedules, enrollments, grades, attendances, ukts, announcements, package_courses, package_classes CASCADE;
	`).Error
	if err != nil {
		log.Println("Peringatan saat truncate (mungkin tabel belum ada):", err)
	}

	// 3. Hash Password
	hashedPassword, _ := bcrypt.GenerateFromPassword([]byte("password123"), bcrypt.DefaultCost)
	passStr := string(hashedPassword)

	// 4. Seed Users
	fmt.Println("👥 Membuat data Users...")
	users := []models.User{
		{Name: "Super Admin", Email: "admin@edutrack.com", Password: passStr, Role: "admin"},
		{Name: "Dr. Arman Wijaya", Email: "kaprodi@edutrack.com", Password: passStr, Role: "kaprodi"},
		{Name: "Budi Santoso, M.Kom", Email: "dosen1@edutrack.com", Password: passStr, Role: "dosen"},
		{Name: "Siti Aminah, M.T", Email: "dosen2@edutrack.com", Password: passStr, Role: "dosen"},
		{Name: "Raihan Muzakkar", Email: "mhs1@edutrack.com", Password: passStr, Role: "mahasiswa"},
		{Name: "Andi Saputra", Email: "mhs2@edutrack.com", Password: passStr, Role: "mahasiswa"},
		{Name: "Bunga Lestari", Email: "mhs3@edutrack.com", Password: passStr, Role: "mahasiswa"},
		{Name: "Citra Dewi", Email: "mhs4@edutrack.com", Password: passStr, Role: "mahasiswa"},
		{Name: "Dedi Kurniawan", Email: "mhs5@edutrack.com", Password: passStr, Role: "mahasiswa"},
	}
	db.Create(&users)

	// Simpan ID untuk relasi
	var dosen1, dosen2 models.User
	db.Where("email = ?", "dosen1@edutrack.com").First(&dosen1)
	db.Where("email = ?", "dosen2@edutrack.com").First(&dosen2)

	var mahasiswas []models.User
	db.Where("role = ?", "mahasiswa").Find(&mahasiswas)

	// 5. Seed Courses
	fmt.Println("📚 Membuat data Mata Kuliah...")
	courses := []models.Course{
		{Code: "IF-101", Name: "Pemrograman Dasar", SKS: 3, Semester: 1},
		{Code: "IF-102", Name: "Jaringan Komputer", SKS: 3, Semester: 1},
		{Code: "IF-201", Name: "Basis Data", SKS: 4, Semester: 3},
		{Code: "IF-202", Name: "Pemrograman Web", SKS: 3, Semester: 3},
		{Code: "IF-301", Name: "Keamanan Informasi", SKS: 3, Semester: 5},
	}
	db.Create(&courses)

	// 6. Seed Classes
	fmt.Println("🏫 Membuat data Kelas...")
	classes := []models.Class{
		{Name: "TRKJ 1A", CourseID: courses[0].ID, DosenID: dosen1.ID, Day: "Senin", StartTime: "08:00", EndTime: "10:30", Room: "Lab 1"},
		{Name: "TRKJ 1B", CourseID: courses[1].ID, DosenID: dosen2.ID, Day: "Selasa", StartTime: "13:00", EndTime: "15:30", Room: "Lab 2"},
		{Name: "TRKJ 3A", CourseID: courses[2].ID, DosenID: dosen1.ID, Day: "Rabu", StartTime: "10:00", EndTime: "12:30", Room: "Ruang 301"},
	}
	db.Create(&classes)

	// 7. Seed Packages (Relasi Many-to-Many)
	fmt.Println("📦 Membuat data Paket Semester...")
	pkg1 := models.Package{Name: "Paket Semester 1", Term: 1, Status: "Siap", Courses: []models.Course{courses[0], courses[1]}, Classes: []models.Class{classes[0], classes[1]}}
	pkg2 := models.Package{Name: "Paket Semester 3", Term: 3, Status: "Draf", Courses: []models.Course{courses[2], courses[3]}, Classes: []models.Class{classes[2]}}
	db.Create(&pkg1)
	db.Create(&pkg2)

	// 8. Seed Schedules
	fmt.Println("📅 Membuat data Jadwal...")
	schedules := []models.Schedule{
		{Semester: "2026 Ganjil", ClassID: classes[0].ID, CourseID: courses[0].ID, TeacherID: dosen1.ID, Day: "Senin", StartTime: "08:00", EndTime: "10:30", Room: "Lab 1"},
		{Semester: "2026 Ganjil", ClassID: classes[1].ID, CourseID: courses[1].ID, TeacherID: dosen2.ID, Day: "Selasa", StartTime: "13:00", EndTime: "15:30", Room: "Lab 2"},
	}
	db.Create(&schedules)

	// 9. Seed Enrollments (KRS)
	fmt.Println("📝 Membuat data KRS...")
	var enrollments []models.Enrollment
	for i, mhs := range mahasiswas {
		// Daftarkan mahasiswa ke kelas secara bergantian
		classID := classes[i%len(classes)].ID
		enrollments = append(enrollments, models.Enrollment{
			MahasiswaID: mhs.ID,
			ClassID:     classID,
			Status:      "active",
		})
	}
	db.Create(&enrollments)

	// 10. Seed Grades (Nilai)
	fmt.Println("💯 Membuat data Nilai...")
	var grades []models.Grade
	scores := []float64{85.5, 90.0, 78.5, 88.0, 95.5}
	letters := []string{"A", "A", "B", "A", "A"}
	for i, enr := range enrollments {
		grades = append(grades, models.Grade{
			MahasiswaID: enr.MahasiswaID,
			ClassID:     enr.ClassID,
			Score:       scores[i],
			Letter:      letters[i],
		})
	}
	db.Create(&grades)

	// 11. Seed Attendances (Absensi)
	fmt.Println("✅ Membuat data Absensi...")
	var attendances []models.Attendance
	for i, mhs := range mahasiswas {
		status := "hadir"
		if i == 2 {
			status = "alpa"
		}
		attendances = append(attendances, models.Attendance{
			ClassID:     classes[i%len(classes)].ID,
			MahasiswaID: mhs.ID,
			Date:        time.Now().AddDate(0, 0, -i),
			Status:      status,
		})
	}
	db.Create(&attendances)

	// 12. Seed UKT
	fmt.Println("💰 Membuat data UKT...")
	var ukts []models.UKT
	for i, mhs := range mahasiswas {
		paid := 5000000.0
		if i%2 != 0 {
			paid = 2500000.0 // Sebagian belum lunas
		}
		ukts = append(ukts, models.UKT{
			StudentID: mhs.ID,
			Semester:  "2026 Ganjil",
			Billed:    5000000.0,
			Paid:      paid,
			DueDate:   time.Now().AddDate(0, 1, 0), // Jatuh tempo 1 bulan lagi
		})
	}
	db.Create(&ukts)

	// 13. Seed Announcements
	fmt.Println("📢 Membuat data Pengumuman...")
	announcements := []models.Announcement{
		{Title: "Jadwal UTS Semester Ganjil", Category: "Akademik", Content: "Ujian Tengah Semester akan dilaksanakan pada bulan depan.", StartDate: time.Now(), EndDate: time.Now().AddDate(0, 1, 0), Status: "Aktif"},
		{Title: "Pembayaran UKT", Category: "Administrasi", Content: "Batas akhir pembayaran UKT adalah tanggal 30.", StartDate: time.Now(), EndDate: time.Now().AddDate(0, 0, 10), Status: "Aktif"},
	}
	db.Create(&announcements)

	fmt.Println("🎉 SEEDING DATABASE BERHASIL!")
	fmt.Println("Silakan login menggunakan:")
	fmt.Println("Email Admin: admin@edutrack.com")
	fmt.Println("Email Kaprodi: kaprodi@edutrack.com")
	fmt.Println("Password: password123")
}