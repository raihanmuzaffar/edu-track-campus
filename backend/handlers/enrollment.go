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

// EnrollClass (Hanya Mahasiswa)
func (h *EnrollmentHandler) EnrollClass(w http.ResponseWriter, r *http.Request) {
	// 1. Ambil ID Mahasiswa dari JWT Token (Context)
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

	// 2. Cek apakah mahasiswa sudah pernah mengambil kelas ini
	var existingEnrollment models.Enrollment
	err := h.DB.Where("mahasiswa_id = ? AND class_id = ?", mahasiswaID, input.ClassID).First(&existingEnrollment).Error
	if err == nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Anda sudah mengambil kelas ini", nil)
		return
	}

	// 3. Simpan ke database
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

// GetMyKRS (Hanya Mahasiswa - Melihat kelas apa saja yang sudah diambil)
func (h *EnrollmentHandler) GetMyKRS(w http.ResponseWriter, r *http.Request) {
	mahasiswaID, _ := r.Context().Value(middlewares.UserIDKey).(uint)

	var enrollments []models.Enrollment
	// Preload Class, Course, dan Dosen agar datanya lengkap
	err := h.DB.Preload("Class.Course").Preload("Class.Dosen").Where("mahasiswa_id = ?", mahasiswaID).Find(&enrollments).Error
	if err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil data KRS", nil)
		return
	}

	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil data KRS", enrollments)
}