package handlers

import (
	"encoding/json"
	"net/http"
	"strings"
	"time"

	"github.com/raihanmuzaffar/edu-track-campus/backend/config"
	"github.com/raihanmuzaffar/edu-track-campus/backend/middlewares"
	"github.com/raihanmuzaffar/edu-track-campus/backend/models"
	"github.com/raihanmuzaffar/edu-track-campus/backend/utils"
	"gorm.io/gorm"
)

type ClassHandler struct {
	DB *gorm.DB
}

type ClassInput struct {
	CourseID  uint   `json:"course_id" validate:"required"`
	DosenID   uint   `json:"dosen_id" validate:"required"`
	Name      string `json:"name" validate:"required"`
	Day       string `json:"day" validate:"required,oneof=Senin Selasa Rabu Kamis Jumat Sabtu"`
	StartTime string `json:"start_time" validate:"required"`
	EndTime   string `json:"end_time" validate:"required"`
	Room      string `json:"room" validate:"required"`
	Capacity  int    `json:"capacity" validate:"omitempty,gte=0"`
	Year      string `json:"year" validate:"omitempty"`
	Semester  string `json:"semester" validate:"omitempty,oneof=Ganjil Genap"`
	PackageID *uint  `json:"package_id"`
	Status    string `json:"status" validate:"omitempty,oneof=Aktif Nonaktif"`
}

func resolvePeriod(input *ClassInput) {
	period := config.AcademicPeriodNow()
	if strings.TrimSpace(input.Year) == "" {
		input.Year = period.Year
	}
	if strings.TrimSpace(input.Semester) == "" {
		input.Semester = period.Semester
	}
	input.Year = strings.TrimSpace(input.Year)
	input.Semester = strings.TrimSpace(input.Semester)
}

func (h *ClassHandler) validateReferences(input ClassInput) (int, string) {
	var course models.Course
	if err := h.DB.First(&course, input.CourseID).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return http.StatusBadRequest, "Mata kuliah tidak ditemukan"
		}
		return http.StatusInternalServerError, "Gagal memvalidasi mata kuliah"
	}

	var lecturer models.User
	if err := h.DB.First(&lecturer, input.DosenID).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return http.StatusBadRequest, "Dosen tidak ditemukan"
		}
		return http.StatusInternalServerError, "Gagal memvalidasi dosen"
	}
	if lecturer.Role != "dosen" {
		return http.StatusBadRequest, "dosen_id harus merujuk ke akun dosen"
	}

	if input.PackageID != nil {
		var pkg models.Package
		if err := h.DB.First(&pkg, *input.PackageID).Error; err != nil {
			if err == gorm.ErrRecordNotFound {
				return http.StatusBadRequest, "Paket tidak ditemukan"
			}
			return http.StatusInternalServerError, "Gagal memvalidasi paket"
		}
	}

	start, err := time.Parse("15:04", input.StartTime)
	if err != nil {
		return http.StatusBadRequest, "Format jam mulai harus HH:MM"
	}
	end, err := time.Parse("15:04", input.EndTime)
	if err != nil || !end.After(start) {
		return http.StatusBadRequest, "Jam selesai harus lebih besar dari jam mulai dan berformat HH:MM"
	}
	return 0, ""
}

func syncClassPackage(db *gorm.DB, classID uint, packageID *uint) error {
	if err := db.Exec("DELETE FROM package_classes WHERE class_id = ?", classID).Error; err != nil {
		return err
	}
	if packageID == nil {
		return nil
	}
	return db.Exec(
		"INSERT INTO package_classes (package_id, class_id) VALUES (?, ?) ON CONFLICT DO NOTHING",
		*packageID,
		classID,
	).Error
}

// @Summary Tambah Kelas (Admin)
// @Description Admin membuat jadwal kelas baru
// @Tags Classes
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body ClassInput true "Data Kelas"
// @Success 201 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /classes [post]
func (h *ClassHandler) CreateClass(w http.ResponseWriter, r *http.Request) {
	var input ClassInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}
	if err := utils.Validate.Struct(input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, utils.FormatValidationError(err), nil)
		return
	}
	if status, message := h.validateReferences(input); status != 0 {
		utils.JSONResponse(w, status, message, nil)
		return
	}
	resolvePeriod(&input)

	classStatus := input.Status
	if classStatus == "" {
		classStatus = "Aktif"
	}
	class := models.Class{
		CourseID: input.CourseID, DosenID: input.DosenID, Name: input.Name,
		Day: input.Day, StartTime: input.StartTime, EndTime: input.EndTime, Room: input.Room,
		Capacity: input.Capacity, Year: input.Year, Semester: input.Semester,
		PackageID: input.PackageID, Status: classStatus,
	}
	if err := h.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(&class).Error; err != nil {
			return err
		}
		return syncClassPackage(tx, class.ID, class.PackageID)
	}); err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal membuat kelas dan relasi paket", nil)
		return
	}
	utils.JSONResponse(w, http.StatusCreated, "Kelas berhasil dibuat", class)
}

// @Summary Lihat Semua Kelas
// @Description Mendapatkan daftar kelas dengan pagination dan fitur pencarian
// @Tags Classes
// @Produce json
// @Security BearerAuth
// @Param page query int false "Halaman (default: 1)"
// @Param limit query int false "Jumlah per halaman (default: 10)"
// @Param search query string false "Cari berdasarkan nama, ruang, atau hari"
// @Success 200 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /classes/list [get]
func (h *ClassHandler) GetClasses(w http.ResponseWriter, r *http.Request) {
	var classes []models.Class
	limit, offset, err := utils.GetPagination(r)
	if err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, err.Error(), nil)
		return
	}
	search := r.URL.Query().Get("search")

	query := h.DB.Model(&models.Class{}).Preload("Course").Preload("Dosen")
	if search != "" {
		query = query.Where("(name ILIKE ? OR room ILIKE ? OR day ILIKE ?)", "%"+search+"%", "%"+search+"%", "%"+search+"%")
	}
	year := r.URL.Query().Get("year")
	semester := r.URL.Query().Get("semester")
	if year != "" {
		query = query.Where("year = ?", year)
	}
	if semester != "" {
		query = query.Where("semester = ?", semester)
	}
	role, _ := r.Context().Value(middlewares.RoleKey).(string)
	if role == "dosen" {
		dosenID, ok := r.Context().Value(middlewares.UserIDKey).(uint)
		if !ok || dosenID == 0 {
			utils.JSONResponse(w, http.StatusUnauthorized, "Gagal mengambil data dosen", nil)
			return
		}
		query = query.Where("dosen_id = ?", dosenID)
	}
	if role == "mahasiswa" {
		period := config.AcademicPeriodNow()
		query = query.Where("year = ? AND semester = ?", period.Year, period.Semester)
		query = query.Where("(status = 'Aktif' OR status = '' OR status IS NULL)")
	}

	var total int64
	if err := query.Count(&total).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menghitung data kelas", nil)
		return
	}

	if err := query.Limit(limit).Offset(offset).Find(&classes).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil data kelas", nil)
		return
	}
	response := map[string]interface{}{
		"data":       classes,
		"total_data": total,
		"page":       (offset / limit) + 1,
		"limit":      limit,
	}
	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil data kelas", response)
}

// @Summary Update Kelas (Admin)
// @Description Mengubah data kelas berdasarkan ID
// @Tags Classes
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id query int true "ID Kelas"
// @Param request body ClassInput true "Data Update"
// @Success 200 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Failure 404 {object} utils.Response
// @Router /classes/update [put]
func (h *ClassHandler) UpdateClass(w http.ResponseWriter, r *http.Request) {
	idStr := r.URL.Query().Get("id")
	if idStr == "" {
		utils.JSONResponse(w, http.StatusBadRequest, "ID kelas harus diisi di URL", nil)
		return
	}
	var input ClassInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}
	if err := utils.Validate.Struct(input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, utils.FormatValidationError(err), nil)
		return
	}
	if status, message := h.validateReferences(input); status != 0 {
		utils.JSONResponse(w, status, message, nil)
		return
	}

	var class models.Class
	if err := h.DB.First(&class, idStr).Error; err != nil {
		utils.JSONResponse(w, http.StatusNotFound, "Kelas tidak ditemukan", nil)
		return
	}

	class.CourseID = input.CourseID
	class.DosenID = input.DosenID
	class.Name = input.Name
	class.Day = input.Day
	class.StartTime = input.StartTime
	class.EndTime = input.EndTime
	class.Room = input.Room
	class.Capacity = input.Capacity
	class.PackageID = input.PackageID
	if input.Status != "" {
		class.Status = input.Status
	}
	if strings.TrimSpace(input.Year) != "" {
		class.Year = strings.TrimSpace(input.Year)
	} else if strings.TrimSpace(class.Year) == "" {
		class.Year = config.AcademicPeriodNow().Year
	}
	if strings.TrimSpace(input.Semester) != "" {
		class.Semester = strings.TrimSpace(input.Semester)
	} else if strings.TrimSpace(class.Semester) == "" {
		class.Semester = config.AcademicPeriodNow().Semester
	}

	if err := h.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Save(&class).Error; err != nil {
			return err
		}
		return syncClassPackage(tx, class.ID, class.PackageID)
	}); err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengupdate kelas dan relasi paket", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Kelas berhasil diupdate", class)
}

// @Summary Hapus Kelas (Admin)
// @Description Menghapus kelas berdasarkan ID
// @Tags Classes
// @Produce json
// @Security BearerAuth
// @Param id query int true "ID Kelas"
// @Success 200 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /classes/delete [delete]
func (h *ClassHandler) DeleteClass(w http.ResponseWriter, r *http.Request) {
	idStr := r.URL.Query().Get("id")
	if idStr == "" {
		utils.JSONResponse(w, http.StatusBadRequest, "ID kelas harus diisi di URL", nil)
		return
	}
	var affected int64
	err := h.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Exec("DELETE FROM package_classes WHERE class_id = ?", idStr).Error; err != nil {
			return err
		}
		result := tx.Delete(&models.Class{}, idStr)
		affected = result.RowsAffected
		return result.Error
	})
	if err != nil {
		if utils.IsForeignKeyViolation(err) {
			utils.JSONResponse(w, http.StatusConflict, "Kelas masih digunakan oleh jadwal atau data akademik", nil)
			return
		}
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menghapus kelas", nil)
		return
	}
	if affected == 0 {
		utils.JSONResponse(w, http.StatusNotFound, "Kelas tidak ditemukan", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Kelas berhasil dihapus", nil)
}
