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

// GetCourses (Bisa diakses Admin & Kaprodi)
func (h *CourseHandler) GetCourses(w http.ResponseWriter, r *http.Request) {
	var courses []models.Course
	if err := h.DB.Find(&courses).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil data mata kuliah", nil)
		return
	}

	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil data mata kuliah", courses)
}