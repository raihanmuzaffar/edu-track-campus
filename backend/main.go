package main

import (
	"context"
	"crypto/tls"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/raihanmuzaffar/edu-track-campus/backend/config"
	"github.com/raihanmuzaffar/edu-track-campus/backend/handlers"
	"github.com/raihanmuzaffar/edu-track-campus/backend/middlewares"
	"github.com/raihanmuzaffar/edu-track-campus/backend/models"
	"github.com/raihanmuzaffar/edu-track-campus/backend/utils"
	"github.com/redis/go-redis/v9"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"

	_ "github.com/raihanmuzaffar/edu-track-campus/backend/docs"
	"github.com/swaggo/http-swagger"
)

var rdb *redis.Client

func newDatabaseLogger(output io.Writer) logger.Interface {
	return logger.New(log.New(output, "\r\n", log.LstdFlags), logger.Config{
		SlowThreshold:             200 * time.Millisecond,
		LogLevel:                  logger.Warn,
		IgnoreRecordNotFoundError: false,
		ParameterizedQueries:      true,
	})
}

func databaseModels() []interface{} {
	return []interface{}{
		&models.User{}, &models.Course{}, &models.Class{}, &models.Enrollment{},
		&models.Grade{}, &models.Attendance{}, &models.UKT{}, &models.Announcement{},
		&models.Schedule{}, &models.Package{}, &models.Case{}, &models.Document{},
		&models.KHSRecord{}, &models.ParentStudent{}, &models.QRSession{},
	}
}

// @Summary Dashboard mobile
// @Description Endpoint sambutan untuk role mahasiswa, dosen, dan orang tua.
// @Tags Dashboard
// @Produce json
// @Security BearerAuth
// @Success 200 {object} utils.Response
// @Router /mobile/dashboard [get]
func mobileDashboard(w http.ResponseWriter, r *http.Request) {
	role, _ := r.Context().Value(middlewares.RoleKey).(string)
	utils.JSONResponse(w, http.StatusOK, "Selamat datang di mobile dashboard", map[string]string{"role": role})
}

// @Summary Dashboard web admin
// @Description Endpoint sambutan untuk role admin dan kaprodi.
// @Tags Dashboard
// @Produce json
// @Security BearerAuth
// @Success 200 {object} utils.Response
// @Router /admin/dashboard [get]
func adminDashboard(w http.ResponseWriter, r *http.Request) {
	role, _ := r.Context().Value(middlewares.RoleKey).(string)
	utils.JSONResponse(w, http.StatusOK, "Selamat datang di web admin dashboard", map[string]string{"role": role})
}

// @title EduTrack Campus API
// @version 1.0
// @description Sistem Informasi Tracking Akademik (Backend)
// @termsOfService http://swagger.io/terms/

// @contact.name Raihan Muzaffar
// @contact.email admin@edutrack.com

// @host localhost:8080
// @BasePath /api/v1

// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization
// @description Masukkan token dengan format: Bearer <token_anda>
func main() {
	if err := config.ValidateEnvironmentMode(); err != nil {
		log.Fatal(err)
	}
	production := config.IsProductionEnvironment()
	if production {
		if err := config.ValidateProductionEnvironment(); err != nil {
			log.Fatal(err)
		}
	}

	dbHost := os.Getenv("DB_HOST")
	dbUser := os.Getenv("DB_USER")
	dbPass := os.Getenv("DB_PASSWORD")
	dbName := os.Getenv("DB_NAME")
	dbPort := os.Getenv("DB_PORT")
	sslMode := os.Getenv("DB_SSLMODE")
	if sslMode == "" {
		sslMode = "disable"
	}

	dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=%s TimeZone=Asia/Jakarta",
		dbHost, dbUser, dbPass, dbName, dbPort, sslMode)
	if production {
		dsn = config.ProductionPostgresDSN()
	}
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{Logger: newDatabaseLogger(os.Stdout)})
	if err != nil {
		if production {
			log.Fatal("Tidak dapat terhubung ke database production")
		}
		log.Fatalf("Gagal koneksi ke PostgreSQL: %v", err)
	}
	fmt.Println("Berhasil terhubung ke PostgreSQL")

	sqlDB, err := db.DB()
	if err != nil {
		log.Fatal("Tidak dapat menyiapkan koneksi database")
	}
	dbPingContext, cancelDBPing := context.WithTimeout(context.Background(), 5*time.Second)
	err = sqlDB.PingContext(dbPingContext)
	cancelDBPing()
	if err != nil {
		if production {
			log.Fatal("Database production tidak siap")
		}
		log.Fatalf("Gagal memeriksa koneksi PostgreSQL: %v", err)
	}

	redisHost := os.Getenv("REDIS_HOST")
	if redisHost == "" {
		redisHost = "redis"
	}
	redisPort := os.Getenv("REDIS_PORT")
	if redisPort == "" {
		redisPort = "6379"
	}
	var redisTLS *tls.Config
	if strings.EqualFold(strings.TrimSpace(os.Getenv("REDIS_TLS")), "true") {
		redisTLS = &tls.Config{MinVersion: tls.VersionTLS12}
	}
	rdb = redis.NewClient(&redis.Options{
		Addr:      redisHost + ":" + redisPort,
		Password:  os.Getenv("REDIS_PASSWORD"),
		DB:        0,
		TLSConfig: redisTLS,
	})
	redisPingContext, cancelRedisPing := context.WithTimeout(context.Background(), 5*time.Second)
	_, redisPingErr := rdb.Ping(redisPingContext).Result()
	cancelRedisPing()
	if redisPingErr != nil {
		if production {
			log.Fatal("Redis production tidak tersedia; penyimpanan sesi bersama wajib digunakan")
		}
		log.Printf("Peringatan: gagal terhubung ke Redis, sesi menggunakan penyimpanan proses: %v", redisPingErr)
	} else {
		config.SessionRedis = rdb
		fmt.Println("Berhasil terhubung ke Redis")
	}

	if production {
		for _, model := range databaseModels() {
			if !db.Migrator().HasTable(model) {
				log.Fatal("Skema database production belum lengkap; migrasi terkontrol wajib dilakukan sebelum startup")
			}
		}
	} else if err := db.AutoMigrate(databaseModels()...); err != nil {
		log.Fatalf("Gagal melakukan migrasi database: %v", err)
	} else {
		fmt.Println("Berhasil melakukan migrasi database")
	}

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
	parentHandler := &handlers.ParentHandler{DB: db}
	qrHandler := &handlers.QRHandler{DB: db}
	academicHandler := &handlers.AcademicHandler{DB: db}

	allRoles := []string{"admin", "kaprodi", "dosen", "mahasiswa", "orangtua"}
	adminRoles := []string{"admin", "kaprodi"}
	adminOnly := []string{"admin"}
	sharedRolesWithoutKaprodi := []string{"admin", "dosen", "mahasiswa", "orangtua"}
	register := func(path, method string, roles []string, handler http.HandlerFunc) {
		var wrapped http.Handler = handler
		if len(roles) > 0 {
			wrapped = middlewares.AuthMiddleware(roles...)(wrapped)
		}
		http.Handle(path, utils.MethodRouter(map[string]http.Handler{method: wrapped}))
	}

	register("/api/health", http.MethodGet, nil, func(w http.ResponseWriter, r *http.Request) {
		utils.JSONResponse(w, http.StatusOK, "Proses backend aktif", map[string]string{
			"version": "1.0",
		})
	})
	register("/api/ready", http.MethodGet, nil, func(w http.ResponseWriter, r *http.Request) {
		ctx, cancel := context.WithTimeout(r.Context(), 3*time.Second)
		defer cancel()

		sqlDB, err := db.DB()
		if err != nil || sqlDB.PingContext(ctx) != nil {
			utils.JSONResponse(w, http.StatusServiceUnavailable, "Dependency belum siap", nil)
			return
		}
		if production && (config.SessionRedis == nil || config.SessionRedis.Ping(ctx).Err() != nil) {
			utils.JSONResponse(w, http.StatusServiceUnavailable, "Dependency belum siap", nil)
			return
		}
		utils.JSONResponse(w, http.StatusOK, "Dependency siap", nil)
	})
	register("/api/v1/register", http.MethodPost, nil, authHandler.Register)
	register("/api/v1/login", http.MethodPost, nil, authHandler.Login)
	register("/api/v1/forgot-password", http.MethodPost, nil, authHandler.ForgotPassword)
	register("/api/v1/reset-password", http.MethodPost, nil, authHandler.ResetPassword)
	register("/api/v1/refresh-token", http.MethodPost, nil, authHandler.RefreshToken)
	register("/api/v1/logout", http.MethodPost, allRoles, authHandler.Logout)
	register("/api/v1/change-password", http.MethodPost, allRoles, authHandler.ChangePassword)
	if !production {
		register("/swagger/", http.MethodGet, nil, httpSwagger.WrapHandler)
	}

	var meHandler http.Handler = middlewares.AuthMiddleware(allRoles...)(http.HandlerFunc(authHandler.GetMe))
	var updateMeHandler http.Handler = middlewares.AuthMiddleware(allRoles...)(http.HandlerFunc(authHandler.UpdateProfile))
	http.Handle("/api/v1/users/me", utils.MethodRouter(map[string]http.Handler{
		http.MethodGet: meHandler, http.MethodPut: updateMeHandler,
	}))

	register("/api/v1/mobile/dashboard", http.MethodGet, []string{"mahasiswa", "dosen", "orangtua"}, mobileDashboard)
	register("/api/v1/admin/dashboard", http.MethodGet, adminOnly, adminDashboard)

	register("/api/v1/admin/stats", http.MethodGet, []string{"admin"}, adminHandler.GetDashboardStats)
	register("/api/v1/admin/users", http.MethodGet, adminRoles, adminHandler.GetAllUsers)
	register("/api/v1/admin/users/create", http.MethodPost, adminRoles, adminHandler.CreateUser)
	register("/api/v1/admin/users/update", http.MethodPut, adminRoles, adminHandler.UpdateUser)
	register("/api/v1/admin/users/delete", http.MethodDelete, adminRoles, adminHandler.DeleteUser)

	register("/api/v1/courses", http.MethodPost, adminOnly, courseHandler.CreateCourse)
	register("/api/v1/courses/list", http.MethodGet, adminOnly, courseHandler.GetCourses)
	register("/api/v1/courses/update", http.MethodPut, adminOnly, courseHandler.UpdateCourse)
	register("/api/v1/courses/delete", http.MethodDelete, adminOnly, courseHandler.DeleteCourse)

	register("/api/v1/classes", http.MethodPost, adminOnly, classHandler.CreateClass)
	register("/api/v1/classes/list", http.MethodGet, []string{"admin", "dosen", "mahasiswa"}, classHandler.GetClasses)
	register("/api/v1/classes/update", http.MethodPut, adminOnly, classHandler.UpdateClass)
	register("/api/v1/classes/delete", http.MethodDelete, adminOnly, classHandler.DeleteClass)

	register("/api/v1/enrollments", http.MethodPost, []string{"mahasiswa"}, enrollmentHandler.EnrollClass)
	register("/api/v1/enrollments/drop", http.MethodPost, []string{"mahasiswa"}, enrollmentHandler.DropClass)
	register("/api/v1/enrollments/my", http.MethodGet, []string{"mahasiswa"}, enrollmentHandler.GetMyKRS)
	register("/api/v1/admin/krs/list", http.MethodGet, adminRoles, enrollmentHandler.GetAllEnrollments)
	register("/api/v1/classes/students", http.MethodGet, []string{"admin", "dosen"}, enrollmentHandler.GetStudentsByClass)

	register("/api/v1/grades", http.MethodPost, []string{"dosen"}, gradeHandler.InputGrade)
	register("/api/v1/grades/my", http.MethodGet, []string{"mahasiswa"}, gradeHandler.GetMyGrades)
	register("/api/v1/admin/grades/list", http.MethodGet, adminRoles, gradeHandler.GetAllGrades)

	register("/api/v1/attendances", http.MethodPost, []string{"dosen"}, attendanceHandler.InputAttendance)
	register("/api/v1/attendances/my", http.MethodGet, []string{"mahasiswa"}, attendanceHandler.GetMyAttendance)
	register("/api/v1/admin/attendances/list", http.MethodGet, adminRoles, attendanceHandler.GetAllAttendance)

	register("/api/v1/admin/ukt", http.MethodPost, adminRoles, uktHandler.CreateUKT)
	register("/api/v1/admin/ukt/list", http.MethodGet, adminRoles, uktHandler.GetAllUKT)
	register("/api/v1/admin/ukt/update", http.MethodPut, adminRoles, uktHandler.UpdateUKT)
	register("/api/v1/admin/ukt/delete", http.MethodDelete, adminRoles, uktHandler.DeleteUKT)

	register("/api/v1/admin/announcements", http.MethodPost, adminOnly, announcementHandler.CreateAnnouncement)
	register("/api/v1/admin/announcements/list", http.MethodGet, sharedRolesWithoutKaprodi, announcementHandler.GetAllAnnouncements)
	register("/api/v1/admin/announcements/update", http.MethodPut, adminOnly, announcementHandler.UpdateAnnouncement)
	register("/api/v1/admin/announcements/delete", http.MethodDelete, adminOnly, announcementHandler.DeleteAnnouncement)

	register("/api/v1/admin/schedules", http.MethodPost, adminOnly, scheduleHandler.CreateSchedule)
	register("/api/v1/admin/schedules/list", http.MethodGet, adminOnly, scheduleHandler.GetAllSchedules)
	register("/api/v1/admin/schedules/update", http.MethodPut, adminOnly, scheduleHandler.UpdateSchedule)
	register("/api/v1/admin/schedules/delete", http.MethodDelete, adminOnly, scheduleHandler.DeleteSchedule)

	register("/api/v1/admin/packages", http.MethodPost, adminOnly, packageHandler.CreatePackage)
	register("/api/v1/admin/packages/list", http.MethodGet, adminOnly, packageHandler.GetAllPackages)
	register("/api/v1/admin/packages/update", http.MethodPut, adminOnly, packageHandler.UpdatePackage)
	register("/api/v1/admin/packages/delete", http.MethodDelete, adminOnly, packageHandler.DeletePackage)

	register("/api/v1/admin/cases", http.MethodPost, adminRoles, caseHandler.CreateCase)
	register("/api/v1/admin/cases/list", http.MethodGet, adminRoles, caseHandler.GetAllCases)
	register("/api/v1/admin/cases/update", http.MethodPut, adminRoles, caseHandler.UpdateCase)
	register("/api/v1/admin/cases/delete", http.MethodDelete, adminRoles, caseHandler.DeleteCase)

	register("/api/v1/admin/documents", http.MethodPost, adminRoles, documentHandler.CreateDocument)
	register("/api/v1/admin/documents/list", http.MethodGet, adminRoles, documentHandler.GetAllDocuments)
	register("/api/v1/admin/documents/update", http.MethodPut, adminRoles, documentHandler.UpdateDocument)
	register("/api/v1/admin/documents/delete", http.MethodDelete, adminRoles, documentHandler.DeleteDocument)

	register("/api/v1/admin/khs/list", http.MethodGet, adminRoles, khsHandler.GetAllKHS)
	register("/api/v1/admin/khs/update", http.MethodPut, adminRoles, khsHandler.UpdateKHStatus)
	register("/api/v1/admin/academic/period-reconciliation", http.MethodGet, adminOnly, academicHandler.GetPeriodReconciliation)

	register("/api/v1/admin/parents/link", http.MethodPost, []string{"admin"}, parentHandler.LinkParent)
	register("/api/v1/parent/children", http.MethodGet, []string{"orangtua"}, parentHandler.GetChildren)
	register("/api/v1/parent/child/profile", http.MethodGet, []string{"orangtua"}, parentHandler.GetChildProfile)
	register("/api/v1/parent/child/grades", http.MethodGet, []string{"orangtua"}, parentHandler.GetChildGrades)
	register("/api/v1/parent/child/attendances", http.MethodGet, []string{"orangtua"}, parentHandler.GetChildAttendance)
	register("/api/v1/parent/child/summary", http.MethodGet, []string{"orangtua"}, parentHandler.GetChildSummary)
	register("/api/v1/parent/child/schedules", http.MethodGet, []string{"orangtua"}, parentHandler.GetChildSchedule)
	register("/api/v1/parent/child/ukt", http.MethodGet, []string{"orangtua"}, parentHandler.GetChildUKT)
	register("/api/v1/parent/child/documents", http.MethodGet, []string{"orangtua"}, parentHandler.GetChildDocuments)
	register("/api/v1/parent/announcements", http.MethodGet, []string{"orangtua"}, parentHandler.GetAnnouncements)

	register("/api/v1/student/academic/summary", http.MethodGet, []string{"mahasiswa"}, academicHandler.GetMySummary)
	register("/api/v1/student/khs", http.MethodGet, []string{"mahasiswa"}, academicHandler.GetMyKHS)
	register("/api/v1/student/transcript", http.MethodGet, []string{"mahasiswa"}, academicHandler.GetMyTranscript)
	register("/api/v1/student/ukt/my", http.MethodGet, []string{"mahasiswa"}, academicHandler.GetMyUKT)
	register("/api/v1/schedules/my", http.MethodGet, []string{"mahasiswa"}, academicHandler.GetMySchedule)
	register("/api/v1/calendar", http.MethodGet, adminOnly, academicHandler.GetCalendar)
	register("/api/v1/notifications", http.MethodGet, sharedRolesWithoutKaprodi, academicHandler.GetNotifications)

	register("/api/v1/qr/generate", http.MethodPost, []string{"dosen"}, qrHandler.GenerateQR)
	register("/api/v1/qr/scan", http.MethodPost, []string{"mahasiswa"}, qrHandler.ScanQR)
	register("/api/v1/qr/validate", http.MethodPost, []string{"mahasiswa"}, qrHandler.ValidateQR)
	register("/api/v1/qr/close", http.MethodPost, []string{"dosen"}, qrHandler.CloseQR)
	register("/api/v1/qr/session", http.MethodGet, []string{"dosen"}, qrHandler.GetSessionStatus)
	register("/api/v1/admin/qr/active", http.MethodGet, adminOnly, qrHandler.GetActiveQRs)

	corsHandler, err := middlewares.EnableCORS(http.DefaultServeMux)
	if err != nil {
		log.Fatal("Konfigurasi CORS production tidak valid")
	}
	if !production {
		fmt.Println("Server berjalan di port 8080")
	}
	if err := http.ListenAndServe(":8080", corsHandler); err != nil {
		log.Fatal(err)
	}
}
