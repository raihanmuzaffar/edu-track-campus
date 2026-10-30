package handlers

import (
	"encoding/json"
	"net/http"

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

	class := models.Class{
		CourseID: input.CourseID, DosenID: input.DosenID, Name: input.Name,
		Day: input.Day, StartTime: input.StartTime, EndTime: input.EndTime, Room: input.Room,
	}
	if err := h.DB.Create(&class).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal membuat kelas", nil)
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
	limit, offset := utils.GetPagination(r)
	search := r.URL.Query().Get("search")

	query := h.DB.Model(&models.Class{}).Preload("Course").Preload("Dosen")
	if search != "" {
		query = query.Where("name ILIKE ? OR room ILIKE ? OR day ILIKE ?", "%"+search+"%", "%"+search+"%", "%"+search+"%")
	}

	var total int64
	query.Count(&total)

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

	if err := h.DB.Save(&class).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengupdate kelas", nil)
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
	if err := h.DB.Delete(&models.Class{}, idStr).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menghapus kelas", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Kelas berhasil dihapus", nil)
}