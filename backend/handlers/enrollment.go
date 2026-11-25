package handlers

import (
	"encoding/json"
	"errors"
	"net/http"
	"strconv"
	"strings"

	"github.com/raihanmuzaffar/edu-track-campus/backend/config"
	"github.com/raihanmuzaffar/edu-track-campus/backend/middlewares"
	"github.com/raihanmuzaffar/edu-track-campus/backend/models"
	"github.com/raihanmuzaffar/edu-track-campus/backend/utils"
	"gorm.io/gorm"
)

type EnrollmentHandler struct {
	DB *gorm.DB
}

type EnrollmentInput struct {
	ClassID uint `json:"class_id" validate:"required,gt=0"`
}

func timeToMinutes(value string) int {
	parts := strings.Split(strings.TrimSpace(value), ":")
	if len(parts) < 2 {
		return 0
	}
	hour, errHour := strconv.Atoi(parts[0])
	minute, errMinute := strconv.Atoi(parts[1])
	if errHour != nil || errMinute != nil {
		return 0
	}
	return hour*60 + minute
}

func activeEnrollmentFilter(db *gorm.DB) *gorm.DB {
	return db.Where("(status = 'active' OR status = '' OR status IS NULL)")
}

func (h *EnrollmentHandler) resolveClass(input EnrollmentInput) (models.Class, error) {
	var class models.Class
	err := h.DB.Preload("Course").First(&class, input.ClassID).Error
	return class, err
}

func (h *EnrollmentHandler) validateEnrollment(class models.Class, mahasiswaID uint) (string, bool, error) {
	period := config.AcademicPeriodNow()
	if strings.TrimSpace(class.Year) == "" || strings.TrimSpace(class.Semester) == "" {
		return "Periode kelas belum diisi. Hubungi admin untuk memperbaiki data kelas.", false, nil
	}
	if class.Year != period.Year || class.Semester != period.Semester {
		return "Kelas ini tidak tersedia untuk periode aktif " + period.Year + " " + period.Semester, false, nil
	}
	if class.Status != "" && class.Status != "Aktif" {
		return "Kelas tidak aktif", false, nil
	}

	var active []models.Enrollment
	if err := activeEnrollmentFilter(h.DB.Preload("Class")).Where("mahasiswa_id = ?", mahasiswaID).Find(&active).Error; err != nil {
		return "", false, err
	}
	totalSKS := 0
	for _, item := range active {
		if item.ClassID == class.ID {
			return "Anda sudah mengambil kelas ini", false, nil
		}
		if item.Class.ID == 0 {
			continue
		}
		if item.Class.Year != class.Year || item.Class.Semester != class.Semester {
			continue
		}
		if item.Class.Day == class.Day &&
			timeToMinutes(class.StartTime) < timeToMinutes(item.Class.EndTime) &&
			timeToMinutes(item.Class.StartTime) < timeToMinutes(class.EndTime) {
			return "Jadwal kelas bertabrakan dengan kelas yang sudah diambil", false, nil
		}
		totalSKS += item.Class.Course.SKS
	}
	if class.Capacity > 0 {
		var taken int64
		if err := activeEnrollmentFilter(h.DB.Model(&models.Enrollment{})).
			Where("class_id = ?", class.ID).Count(&taken).Error; err != nil {
			return "", false, err
		}
		if int(taken) >= class.Capacity {
			return "Kuota kelas sudah penuh", false, nil
		}
	}
	if totalSKS+class.Course.SKS > config.MaxSKS() {
		return "Beban SKS melebihi batas maksimum " + strconv.Itoa(config.MaxSKS()), false, nil
	}
	return "", true, nil
}

// @Summary Ambil Kelas (Mahasiswa)
// @Description Mahasiswa mendaftar ke kelas yang tersedia pada periode aktif
// @Tags Enrollment
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body EnrollmentInput true "ID Kelas"
// @Success 201 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Router /enrollments [post]
func (h *EnrollmentHandler) EnrollClass(w http.ResponseWriter, r *http.Request) {
	mahasiswaID, ok := r.Context().Value(middlewares.UserIDKey).(uint)
	if !ok {
		utils.JSONResponse(w, http.StatusUnauthorized, "Gagal mengambil data user", nil)
		return
	}

	var input EnrollmentInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}
	if err := utils.Validate.Struct(input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, utils.FormatValidationError(err), nil)
		return
	}

	class, err := h.resolveClass(input)
	if errors.Is(err, gorm.ErrRecordNotFound) {
		utils.JSONResponse(w, http.StatusNotFound, "Kelas tidak ditemukan", nil)
		return
	}
	if utils.RespondQueryError(w, err, "Gagal mengambil data kelas") {
		return
	}
	reason, valid, validationErr := h.validateEnrollment(class, mahasiswaID)
	if validationErr != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal memvalidasi KRS", nil)
		return
	}
	if !valid {
		utils.JSONResponse(w, http.StatusBadRequest, reason, nil)
		return
	}

	var existing models.Enrollment
	err = h.DB.Where("mahasiswa_id = ? AND class_id = ?", mahasiswaID, input.ClassID).First(&existing).Error
	if err == nil {
		if existing.Status == "dropped" {
			existing.Status = "active"
			if err := h.DB.Save(&existing).Error; err != nil {
				utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengaktifkan kembali KRS", nil)
				return
			}
			utils.JSONResponse(w, http.StatusOK, "KRS berhasil diaktifkan kembali", existing)
			return
		}
		utils.JSONResponse(w, http.StatusBadRequest, "Anda sudah mengambil kelas ini", nil)
		return
	}
	if !errors.Is(err, gorm.ErrRecordNotFound) {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal memeriksa KRS", nil)
		return
	}

	enrollment := models.Enrollment{MahasiswaID: mahasiswaID, ClassID: input.ClassID, Status: "active"}
	if err := h.DB.Create(&enrollment).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil kelas", nil)
		return
	}
	utils.JSONResponse(w, http.StatusCreated, "Berhasil mengambil kelas", enrollment)
}

// @Summary Batalkan kelas KRS
// @Description Menandai KRS sebagai dibatalkan tanpa menghapus riwayat
// @Tags Enrollment
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body EnrollmentInput true "ID Kelas"
// @Success 200 {object} utils.Response
// @Router /enrollments/drop [post]
func (h *EnrollmentHandler) DropClass(w http.ResponseWriter, r *http.Request) {
	mahasiswaID, ok := r.Context().Value(middlewares.UserIDKey).(uint)
	if !ok {
		utils.JSONResponse(w, http.StatusUnauthorized, "Gagal mengambil data user", nil)
		return
	}
	var input EnrollmentInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}
	if err := utils.Validate.Struct(input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, utils.FormatValidationError(err), nil)
		return
	}
	result := h.DB.Model(&models.Enrollment{}).Where("mahasiswa_id = ? AND class_id = ?", mahasiswaID, input.ClassID).Update("status", "dropped")
	if result.Error != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal membatalkan KRS", nil)
		return
	}
	if result.RowsAffected == 0 {
		utils.JSONResponse(w, http.StatusNotFound, "KRS tidak ditemukan", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "KRS berhasil dibatalkan", nil)
}

// @Summary Lihat KRS Sendiri (Mahasiswa)
// @Description Mahasiswa melihat daftar KRS aktif pada periode tertentu
// @Tags Enrollment
// @Produce json
// @Security BearerAuth
// @Param year query string false "Tahun ajaran"
// @Param semester query string false "Ganjil atau Genap"
// @Param all query bool false "Tampilkan semua periode"
// @Success 200 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /enrollments/my [get]
func (h *EnrollmentHandler) GetMyKRS(w http.ResponseWriter, r *http.Request) {
	mahasiswaID, _ := r.Context().Value(middlewares.UserIDKey).(uint)
	query := activeEnrollmentFilter(h.DB.Preload("Class.Course").Preload("Class.Dosen")).Where("mahasiswa_id = ?", mahasiswaID)

	year := r.URL.Query().Get("year")
	semester := r.URL.Query().Get("semester")
	if year != "" {
		query = query.Where("class_id IN (?)", h.DB.Model(&models.Class{}).Select("id").Where("year = ?", year))
	}
	if semester != "" {
		query = query.Where("class_id IN (?)", h.DB.Model(&models.Class{}).Select("id").Where("semester = ?", semester))
	}
	all, _ := strconv.ParseBool(r.URL.Query().Get("all"))
	if !all && year == "" && semester == "" {
		period := config.AcademicPeriodNow()
		query = query.Where("class_id IN (?)", h.DB.Model(&models.Class{}).Select("id").Where("year = ? AND semester = ?", period.Year, period.Semester))
	}

	var enrollments []models.Enrollment
	if err := query.Find(&enrollments).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil data KRS", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil data KRS", enrollments)
}

// @Summary Lihat Semua KRS (Admin/Kaprodi)
// @Description Admin dan Kaprodi melihat seluruh data KRS mahasiswa
// @Tags Enrollment
// @Produce json
// @Security BearerAuth
// @Success 200 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /admin/krs/list [get]
func (h *EnrollmentHandler) GetAllEnrollments(w http.ResponseWriter, r *http.Request) {
	var enrollments []models.Enrollment
	query := h.DB.Model(&models.Enrollment{}).Preload("Mahasiswa").Preload("Class.Course")
	role, _ := r.Context().Value(middlewares.RoleKey).(string)
	if role == "kaprodi" {
		programScope, ok := currentProgramScope(w, r, h.DB)
		if !ok {
			return
		}
		query = scopedStudentRecords(query, "Mahasiswa", programScope)
	}
	err := query.Find(&enrollments).Error
	if err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil data KRS", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil data KRS", enrollments)
}

// @Summary Get Students by Class ID (Dosen/Admin/Kaprodi)
// @Description Mendapatkan daftar mahasiswa yang terdaftar di kelas tertentu
// @Tags Enrollment
// @Produce json
// @Security BearerAuth
// @Param class_id query int true "ID Kelas"
// @Param page query int false "Halaman (default: 1)"
// @Param limit query int false "Jumlah per halaman (default: 10)"
// @Success 200 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /classes/students [get]
func (h *EnrollmentHandler) GetStudentsByClass(w http.ResponseWriter, r *http.Request) {
	classIDStr := r.URL.Query().Get("class_id")
	if classIDStr == "" {
		utils.JSONResponse(w, http.StatusBadRequest, "Parameter class_id wajib diisi", nil)
		return
	}
	classID, err := strconv.ParseUint(classIDStr, 10, 64)
	if err != nil || classID == 0 {
		utils.JSONResponse(w, http.StatusBadRequest, "Parameter class_id tidak valid", nil)
		return
	}

	var class models.Class
	if err := h.DB.First(&class, uint(classID)).Error; errors.Is(err, gorm.ErrRecordNotFound) {
		utils.JSONResponse(w, http.StatusNotFound, "Kelas tidak ditemukan", nil)
		return
	} else if utils.RespondQueryError(w, err, "Gagal mengambil data kelas") {
		return
	}
	role, _ := r.Context().Value(middlewares.RoleKey).(string)
	userID, _ := r.Context().Value(middlewares.UserIDKey).(uint)
	if role == "dosen" && class.DosenID != userID {
		utils.JSONResponse(w, http.StatusForbidden, "Anda tidak memiliki akses ke kelas ini", nil)
		return
	}

	limit, offset, err := utils.GetPagination(r)
	if err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, err.Error(), nil)
		return
	}
	var total int64
	query := h.DB.Model(&models.Enrollment{}).Where("class_id = ?", classID)
	if utils.RespondQueryError(w, query.Count(&total).Error, "Gagal menghitung data KRS") {
		return
	}

	var enrollments []models.Enrollment
	if utils.RespondQueryError(w, query.Preload("Mahasiswa").Limit(limit).Offset(offset).Find(&enrollments).Error, "Gagal mengambil data mahasiswa") {
		return
	}
	page := offset/limit + 1
	w.Header().Set("X-Total-Count", strconv.FormatInt(total, 10))
	w.Header().Set("X-Page", strconv.Itoa(page))
	w.Header().Set("X-Limit", strconv.Itoa(limit))
	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil data mahasiswa", enrollments)
}
