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
	CourseID  uint   `json:"course_id"`
	DosenID   uint   `json:"dosen_id"`
	Name      string `json:"name"`
	Day       string `json:"day"`
	StartTime string `json:"start_time"`
	EndTime   string `json:"end_time"`
	Room      string `json:"room"`
}

// CreateClass (Hanya Admin)
func (h *ClassHandler) CreateClass(w http.ResponseWriter, r *http.Request) {
	var input ClassInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}

	class := models.Class{
		CourseID:  input.CourseID,
		DosenID:   input.DosenID,
		Name:      input.Name,
		Day:       input.Day,
		StartTime: input.StartTime,
		EndTime:   input.EndTime,
		Room:      input.Room,
	}

	if err := h.DB.Create(&class).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal membuat kelas", nil)
		return
	}

	utils.JSONResponse(w, http.StatusCreated, "Kelas berhasil dibuat", class)
}

// GetClasses (Bisa diakses semua role - Dengan Pagination & Search)
func (h *ClassHandler) GetClasses(w http.ResponseWriter, r *http.Request) {
	var classes []models.Class

	// Ambil parameter pagination dan search
	limit, offset := utils.GetPagination(r)
	search := r.URL.Query().Get("search")

	// Inisialisasi query dengan Preload untuk menarik data Course dan Dosen
	query := h.DB.Model(&models.Class{}).Preload("Course").Preload("Dosen")

	// Jika ada parameter search, cari berdasarkan nama kelas, ruangan, atau hari
	if search != "" {
		query = query.Where("name ILIKE ? OR room ILIKE ? OR day ILIKE ?", "%"+search+"%", "%"+search+"%", "%"+search+"%")
	}

	// Hitung total data
	var total int64
	query.Count(&total)

	// Ambil data dengan limit dan offset
	if err := query.Limit(limit).Offset(offset).Find(&classes).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil data kelas", nil)
		return
	}

	// Format respons dengan metadata pagination
	response := map[string]interface{}{
		"data":       classes,
		"total_data": total,
		"page":       (offset / limit) + 1,
		"limit":      limit,
	}

	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil data kelas", response)
}

// UpdateClass (Hanya Admin)
func (h *ClassHandler) UpdateClass(w http.ResponseWriter, r *http.Request) {
	// Ambil ID dari URL Query Parameter (misal: /api/v1/classes/update?id=1)
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

	var class models.Class
	if err := h.DB.First(&class, idStr).Error; err != nil {
		utils.JSONResponse(w, http.StatusNotFound, "Kelas tidak ditemukan", nil)
		return
	}

	// Update field
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

// DeleteClass (Hanya Admin)
func (h *ClassHandler) DeleteClass(w http.ResponseWriter, r *http.Request) {
	// Ambil ID dari URL Query Parameter (misal: /api/v1/classes/delete?id=1)
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