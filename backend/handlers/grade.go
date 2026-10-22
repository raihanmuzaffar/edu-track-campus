package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/raihanmuzaffar/edu-track-campus/backend/middlewares"
	"github.com/raihanmuzaffar/edu-track-campus/backend/models"
	"github.com/raihanmuzaffar/edu-track-campus/backend/utils"
	"gorm.io/gorm"
)

type GradeHandler struct {
	DB *gorm.DB
}

type GradeInput struct {
	MahasiswaID uint    `json:"mahasiswa_id"`
	ClassID     uint    `json:"class_id"`
	Score       float64 `json:"score"`
	Letter      string  `json:"letter"`
}

// InputGrade (Hanya Dosen yang mengajar kelas tersebut)
func (h *GradeHandler) InputGrade(w http.ResponseWriter, r *http.Request) {
	// 1. Ambil ID Dosen dari JWT
	dosenID, _ := r.Context().Value(middlewares.UserIDKey).(uint)

	var input GradeInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}

	// 2. Validasi: Apakah Dosen ini benar-benar mengajar kelas tersebut?
	var class models.Class
	if err := h.DB.First(&class, input.ClassID).Error; err != nil {
		utils.JSONResponse(w, http.StatusNotFound, "Kelas tidak ditemukan", nil)
		return
	}
	if class.DosenID != dosenID {
		utils.JSONResponse(w, http.StatusForbidden, "Anda tidak berhak menginput nilai di kelas ini", nil)
		return
	}

	// 3. Cek apakah nilai sudah ada, jika ada maka update, jika belum maka create
	var grade models.Grade
	err := h.DB.Where("mahasiswa_id = ? AND class_id = ?", input.MahasiswaID, input.ClassID).First(&grade).Error
	
	if err == nil {
		// Update nilai yang sudah ada
		grade.Score = input.Score
		grade.Letter = input.Letter
		h.DB.Save(&grade)
	} else {
		// Buat nilai baru
		grade = models.Grade{
			MahasiswaID: input.MahasiswaID,
			ClassID:     input.ClassID,
			Score:       input.Score,
			Letter:      input.Letter,
		}
		if err := h.DB.Create(&grade).Error; err != nil {
			utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menyimpan nilai", nil)
			return
		}
	}

	utils.JSONResponse(w, http.StatusOK, "Nilai berhasil disimpan", grade)
}

// GetMyGrades (Hanya Mahasiswa - Melihat nilai sendiri)
func (h *GradeHandler) GetMyGrades(w http.ResponseWriter, r *http.Request) {
	mahasiswaID, _ := r.Context().Value(middlewares.UserIDKey).(uint)

	var grades []models.Grade
	// Preload Class dan Course agar mahasiswa tahu nilai ini untuk mata kuliah apa
	err := h.DB.Preload("Class.Course").Where("mahasiswa_id = ?", mahasiswaID).Find(&grades).Error
	if err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil data nilai", nil)
		return
	}

	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil data nilai", grades)
}