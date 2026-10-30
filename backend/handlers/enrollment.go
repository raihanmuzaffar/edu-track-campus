package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/raihanmuzaffar/edu-track-campus/backend/middlewares"
	"github.com/raihanmuzaffar/edu-track-campus/backend/models"
	"github.com/raihanmuzaffar/edu-track-campus/backend/utils"
	"gorm.io/gorm"
)

type EnrollmentHandler struct {
	DB *gorm.DB
}

type EnrollmentInput struct {
	ClassID uint `json:"class_id"`
}

// @Summary Ambil Kelas (Mahasiswa)
// @Description Mahasiswa mendaftar ke kelas yang tersedia
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

	var existingEnrollment models.Enrollment
	err := h.DB.Where("mahasiswa_id = ? AND class_id = ?", mahasiswaID, input.ClassID).First(&existingEnrollment).Error
	if err == nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Anda sudah mengambil kelas ini", nil)
		return
	}

	enrollment := models.Enrollment{
		MahasiswaID: mahasiswaID,
		ClassID:     input.ClassID,
		Status:      "active",
	}

	if err := h.DB.Create(&enrollment).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil kelas", nil)
		return
	}

	utils.JSONResponse(w, http.StatusCreated, "Berhasil mengambil kelas", enrollment)
}

// @Summary Lihat KRS Sendiri (Mahasiswa)
// @Description Mahasiswa melihat daftar KRS yang sudah diambil
// @Tags Enrollment
// @Produce json
// @Security BearerAuth
// @Success 200 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /enrollments/my [get]
func (h *EnrollmentHandler) GetMyKRS(w http.ResponseWriter, r *http.Request) {
	mahasiswaID, _ := r.Context().Value(middlewares.UserIDKey).(uint)

	var enrollments []models.Enrollment
	err := h.DB.Preload("Class.Course").Preload("Class.Dosen").Where("mahasiswa_id = ?", mahasiswaID).Find(&enrollments).Error
	if err != nil {
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
	err := h.DB.Preload("Mahasiswa").Preload("Class.Course").Find(&enrollments).Error
	if err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil data KRS", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil data KRS", enrollments)
}