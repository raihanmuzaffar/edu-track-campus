package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/redis/go-redis/v9"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

// Model sederhana untuk tes database
type HealthCheck struct {
	ID        uint      `gorm:"primaryKey"`
	Status    string    `gorm:"type:varchar(50)"`
	CreatedAt time.Time
}

var (
	db  *gorm.DB
	rdb *redis.Client
	ctx = context.Background()
)

func main() {
	// 1. Ambil Environment Variables dari Docker Compose
	dbHost := os.Getenv("DB_HOST")
	dbUser := os.Getenv("DB_USER")
	dbPass := os.Getenv("DB_PASSWORD")
	dbName := os.Getenv("DB_NAME")
	dbPort := os.Getenv("DB_PORT")

	redisHost := os.Getenv("REDIS_HOST")
	redisPort := os.Getenv("REDIS_PORT")

	// 2. Koneksi ke PostgreSQL
	dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=disable TimeZone=Asia/Jakarta",
		dbHost, dbUser, dbPass, dbName, dbPort)
	
	var err error
	db, err = gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatalf("Gagal koneksi ke PostgreSQL: %v", err)
	}
	fmt.Println("✅ Berhasil terhubung ke PostgreSQL!")

	// Auto Migrate (Membuat tabel otomatis)
	db.AutoMigrate(&HealthCheck{})

	// 3. Koneksi ke Redis
	rdb = redis.NewClient(&redis.Options{
		Addr:     fmt.Sprintf("%s:%s", redisHost, redisPort),
		Password: "", // Tidak ada password untuk local dev
		DB:       0,  // Default DB
	})

	// Tes koneksi Redis
	_, err = rdb.Ping(ctx).Result()
	if err != nil {
		log.Fatalf("Gagal koneksi ke Redis: %v", err)
	}
	fmt.Println("✅ Berhasil terhubung ke Redis!")

	// 4. Setup Routes
	http.HandleFunc("/api/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, `{"status": "OK", "message": "Edu-Track Backend is running!"}`)
	})

	// Route tes database (menyimpan data ke Postgres)
	http.HandleFunc("/api/test-db", func(w http.ResponseWriter, r *http.Request) {
		data := HealthCheck{Status: "Healthy"}
		db.Create(&data)
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, `{"status": "OK", "message": "Berhasil simpan data ke PostgreSQL!"}`)
	})

	// Route tes redis (menyimpan data ke Cache)
	http.HandleFunc("/api/test-redis", func(w http.ResponseWriter, r *http.Request) {
		err := rdb.Set(ctx, "test_key", "Hello from Redis!", 10*time.Minute).Err()
		if err != nil {
			http.Error(w, "Gagal simpan ke Redis", http.StatusInternalServerError)
			return
		}
		val, _ := rdb.Get(ctx, "test_key").Result()
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, `{"status": "OK", "message": "Berhasil simpan ke Redis: %s"}`, val)
	})

	fmt.Println("🚀 Server berjalan di port 8080")
	http.ListenAndServe(":8080", nil)
}