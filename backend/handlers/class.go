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

// GetClasses (Bisa diakses semua role yang login)
func (h *ClassHandler) GetClasses(w http.ResponseWriter, r *http.Request) {
	var classes []models.Class
	// Preload digunakan untuk menarik data Course dan Dosen sekaligus
	if err := h.DB.Preload("Course").Preload("Dosen").Find(&classes).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil data kelas", nil)
		return
	}

	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil data kelas", classes)
}