package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/raihanmuzaffar/edu-track-campus/backend/models"
	"github.com/raihanmuzaffar/edu-track-campus/backend/utils"
	"gorm.io/gorm"
)

type CourseHandler struct {
	DB *gorm.DB
}

type CourseInput struct {
	Code     string `json:"code"`
	Name     string `json:"name"`
	SKS      int    `json:"sks"`
	Semester int    `json:"semester"`
}

// CreateCourse (Hanya Admin)
func (h *CourseHandler) CreateCourse(w http.ResponseWriter, r *http.Request) {
	var input CourseInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}

	course := models.Course{
		Code:     input.Code,
		Name:     input.Name,
		SKS:      input.SKS,
		Semester: input.Semester,
	}

	if err := h.DB.Create(&course).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menyimpan mata kuliah (mungkin kode sudah ada)", nil)
		return
	}

	utils.JSONResponse(w, http.StatusCreated, "Mata kuliah berhasil ditambahkan", course)
}

// GetCourses (Bisa diakses Admin & Kaprodi - Dengan Pagination & Search)
func (h *CourseHandler) GetCourses(w http.ResponseWriter, r *http.Request) {
	var courses []models.Course

	// Ambil parameter pagination dan search
	limit, offset := utils.GetPagination(r)
	search := r.URL.Query().Get("search")

	// Inisialisasi query
	query := h.DB.Model(&models.Course{})

	// Jika ada parameter search, cari berdasarkan nama atau kode mata kuliah
	if search != "" {
		query = query.Where("name ILIKE ? OR code ILIKE ?", "%"+search+"%", "%"+search+"%")
	}

	// Hitung total data
	var total int64
	query.Count(&total)

	// Ambil data dengan limit dan offset
	if err := query.Limit(limit).Offset(offset).Find(&courses).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil data mata kuliah", nil)
		return
	}

	// Format respons dengan metadata pagination
	response := map[string]interface{}{
		"data":       courses,
		"total_data": total,
		"page":       (offset / limit) + 1,
		"limit":      limit,
	}

	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil data mata kuliah", response)
}

// UpdateCourse (Hanya Admin)
func (h *CourseHandler) UpdateCourse(w http.ResponseWriter, r *http.Request) {
	// Ambil ID dari URL Query Parameter (misal: /api/v1/courses/update?id=1)
	idStr := r.URL.Query().Get("id")
	if idStr == "" {
		utils.JSONResponse(w, http.StatusBadRequest, "ID mata kuliah harus diisi di URL", nil)
		return
	}

	var input CourseInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}

	var course models.Course
	if err := h.DB.First(&course, idStr).Error; err != nil {
		utils.JSONResponse(w, http.StatusNotFound, "Mata kuliah tidak ditemukan", nil)
		return
	}

	// Update field
	course.Code = input.Code
	course.Name = input.Name
	course.SKS = input.SKS
	course.Semester = input.Semester

	if err := h.DB.Save(&course).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengupdate mata kuliah", nil)
		return
	}

	utils.JSONResponse(w, http.StatusOK, "Mata kuliah berhasil diupdate", course)
}

// DeleteCourse (Hanya Admin)
func (h *CourseHandler) DeleteCourse(w http.ResponseWriter, r *http.Request) {
	// Ambil ID dari URL Query Parameter (misal: /api/v1/courses/delete?id=1)
	idStr := r.URL.Query().Get("id")
	if idStr == "" {
		utils.JSONResponse(w, http.StatusBadRequest, "ID mata kuliah harus diisi di URL", nil)
		return
	}

	if err := h.DB.Delete(&models.Course{}, idStr).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menghapus mata kuliah", nil)
		return
	}

	utils.JSONResponse(w, http.StatusOK, "Mata kuliah berhasil dihapus", nil)
}