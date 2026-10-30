package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/raihanmuzaffar/edu-track-campus/backend/middlewares"
	"github.com/raihanmuzaffar/edu-track-campus/backend/models"
	"github.com/raihanmuzaffar/edu-track-campus/backend/utils"
	"gorm.io/gorm"
)

type ParentHandler struct {
	DB *gorm.DB
}

type LinkInput struct {
	ParentID  uint `json:"parent_id" validate:"required,gt=0"`
	StudentID uint `json:"student_id" validate:"required,gt=0"`
}

// @Summary Hubungkan Orang Tua ke Anak (Admin)
// @Description Admin menghubungkan akun orang tua dengan akun mahasiswa
// @Tags Parent
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body LinkInput true "ID Parent & Student"
// @Success 201 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /admin/parents/link [post]
func (h *ParentHandler) LinkParent(w http.ResponseWriter, r *http.Request) {
	var input LinkInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}
	if err := utils.Validate.Struct(input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, utils.FormatValidationError(err), nil)
		return
	}

	var parent, student models.User
	if err := h.DB.First(&parent, input.ParentID).Error; err != nil || parent.Role != "orangtua" {
		utils.JSONResponse(w, http.StatusBadRequest, "ID Orang Tua tidak valid atau role bukan 'orangtua'", nil)
		return
	}
	if err := h.DB.First(&student, input.StudentID).Error; err != nil || student.Role != "mahasiswa" {
		utils.JSONResponse(w, http.StatusBadRequest, "ID Mahasiswa tidak valid atau role bukan 'mahasiswa'", nil)
		return
	}

	relation := models.ParentStudent{ParentID: input.ParentID, StudentID: input.StudentID}
	if err := h.DB.Create(&relation).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menghubungkan (mungkin sudah terhubung)", nil)
		return
	}
	utils.JSONResponse(w, http.StatusCreated, "Berhasil menghubungkan Orang Tua dan Mahasiswa", relation)
}

// @Summary Lihat Nilai Anak (Orang Tua)
// @Description Orang tua melihat daftar nilai dari anak yang sudah dihubungkan
// @Tags Parent
// @Produce json
// @Security BearerAuth
// @Success 200 {object} utils.Response
// @Failure 404 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /parent/child/grades [get]
func (h *ParentHandler) GetChildGrades(w http.ResponseWriter, r *http.Request) {
	parentID, _ := r.Context().Value(middlewares.UserIDKey).(uint)
	var relation models.ParentStudent
	if err := h.DB.Where("parent_id = ?", parentID).First(&relation).Error; err != nil {
		utils.JSONResponse(w, http.StatusNotFound, "Data anak tidak ditemukan untuk akun ini", nil)
		return
	}

	var grades []models.Grade
	err := h.DB.Preload("Class.Course").Where("mahasiswa_id = ?", relation.StudentID).Find(&grades).Error
	if err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil nilai anak", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil nilai anak", grades)
}

// @Summary Lihat Absensi Anak (Orang Tua)
// @Description Orang tua melihat rekap kehadiran dari anak yang sudah dihubungkan
// @Tags Parent
// @Produce json
// @Security BearerAuth
// @Success 200 {object} utils.Response
// @Failure 404 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /parent/child/attendances [get]
func (h *ParentHandler) GetChildAttendance(w http.ResponseWriter, r *http.Request) {
	parentID, _ := r.Context().Value(middlewares.UserIDKey).(uint)
	var relation models.ParentStudent
	if err := h.DB.Where("parent_id = ?", parentID).First(&relation).Error; err != nil {
		utils.JSONResponse(w, http.StatusNotFound, "Data anak tidak ditemukan untuk akun ini", nil)
		return
	}

	var attendances []models.Attendance
	err := h.DB.Preload("Class.Course").Where("mahasiswa_id = ?", relation.StudentID).Find(&attendances).Error
	if err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil absensi anak", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil absensi anak", attendances)
}