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

// @Summary Input Nilai (Dosen)
// @Description Dosen menginput nilai mahasiswa di kelas yang diajar
// @Tags Grade
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body GradeInput true "Data Nilai"
// @Success 200 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Failure 403 {object} utils.Response
// @Router /grades [post]
func (h *GradeHandler) InputGrade(w http.ResponseWriter, r *http.Request) {
	dosenID, _ := r.Context().Value(middlewares.UserIDKey).(uint)

	var input GradeInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}

	var class models.Class
	if err := h.DB.First(&class, input.ClassID).Error; err != nil {
		utils.JSONResponse(w, http.StatusNotFound, "Kelas tidak ditemukan", nil)
		return
	}
	if class.DosenID != dosenID {
		utils.JSONResponse(w, http.StatusForbidden, "Anda tidak berhak menginput nilai di kelas ini", nil)
		return
	}

	var grade models.Grade
	err := h.DB.Where("mahasiswa_id = ? AND class_id = ?", input.MahasiswaID, input.ClassID).First(&grade).Error
	
	if err == nil {
		grade.Score = input.Score
		grade.Letter = input.Letter
		h.DB.Save(&grade)
	} else {
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

// @Summary Lihat Nilai Sendiri (Mahasiswa)
// @Description Mahasiswa melihat daftar nilai yang sudah diinput dosen
// @Tags Grade
// @Produce json
// @Security BearerAuth
// @Success 200 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /grades/my [get]
func (h *GradeHandler) GetMyGrades(w http.ResponseWriter, r *http.Request) {
	mahasiswaID, _ := r.Context().Value(middlewares.UserIDKey).(uint)

	var grades []models.Grade
	err := h.DB.Preload("Class.Course").Where("mahasiswa_id = ?", mahasiswaID).Find(&grades).Error
	if err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil data nilai", nil)
		return
	}

	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil data nilai", grades)
}

// @Summary Lihat Semua Nilai (Admin/Kaprodi)
// @Description Admin dan Kaprodi melihat seluruh nilai mahasiswa
// @Tags Grade
// @Produce json
// @Security BearerAuth
// @Success 200 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /admin/grades/list [get]
func (h *GradeHandler) GetAllGrades(w http.ResponseWriter, r *http.Request) {
	var grades []models.Grade
	err := h.DB.Preload("Mahasiswa").Preload("Class.Course").Find(&grades).Error
	if err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil data nilai", nil)
		return
	}

	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil semua data nilai", grades)
}