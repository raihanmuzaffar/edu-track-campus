package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/raihanmuzaffar/edu-track-campus/backend/middlewares"
	"github.com/raihanmuzaffar/edu-track-campus/backend/models"
	"github.com/raihanmuzaffar/edu-track-campus/backend/utils"
	"gorm.io/gorm"
)

type AttendanceHandler struct {
	DB *gorm.DB
}

type AttendanceInput struct {
	ClassID     uint   `json:"class_id" validate:"required,gt=0"`
	MahasiswaID uint   `json:"mahasiswa_id" validate:"required,gt=0"`
	Date        string `json:"date" validate:"required"`
	Status      string `json:"status" validate:"required,oneof=hadir izin sakit alpa"`
}

// @Summary Input Absensi (Dosen)
// @Description Dosen menginput kehadiran mahasiswa
// @Tags Attendance
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body AttendanceInput true "Data Absensi"
// @Success 201 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Failure 403 {object} utils.Response
// @Router /attendances [post]
func (h *AttendanceHandler) InputAttendance(w http.ResponseWriter, r *http.Request) {
	dosenID, _ := r.Context().Value(middlewares.UserIDKey).(uint)
	var input AttendanceInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}
	if err := utils.Validate.Struct(input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, utils.FormatValidationError(err), nil)
		return
	}

	var class models.Class
	if err := h.DB.First(&class, input.ClassID).Error; err != nil {
		utils.JSONResponse(w, http.StatusNotFound, "Kelas tidak ditemukan", nil)
		return
	}
	if class.DosenID != dosenID {
		utils.JSONResponse(w, http.StatusForbidden, "Anda tidak berhak menginput absensi di kelas ini", nil)
		return
	}

	dateParsed, err := time.Parse("2006-01-02", input.Date)
	if err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format tanggal harus YYYY-MM-DD", nil)
		return
	}

	attendance := models.Attendance{
		ClassID: input.ClassID, MahasiswaID: input.MahasiswaID, Date: dateParsed, Status: input.Status,
	}

	if err := h.DB.Create(&attendance).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menyimpan absensi", nil)
		return
	}
	utils.JSONResponse(w, http.StatusCreated, "Absensi berhasil disimpan", attendance)
}

// @Summary Lihat Absensi Sendiri (Mahasiswa)
// @Description Mahasiswa melihat rekap kehadiran dirinya
// @Tags Attendance
// @Produce json
// @Security BearerAuth
// @Success 200 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /attendances/my [get]
func (h *AttendanceHandler) GetMyAttendance(w http.ResponseWriter, r *http.Request) {
	mahasiswaID, _ := r.Context().Value(middlewares.UserIDKey).(uint)
	var attendances []models.Attendance
	err := h.DB.Preload("Class.Course").Where("mahasiswa_id = ?", mahasiswaID).Find(&attendances).Error
	if err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil data absensi", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil data absensi", attendances)
}

// @Summary Lihat Semua Absensi (Admin/Kaprodi)
// @Description Admin dan Kaprodi melihat seluruh data absensi mahasiswa
// @Tags Attendance
// @Produce json
// @Security BearerAuth
// @Success 200 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /admin/attendances/list [get]
func (h *AttendanceHandler) GetAllAttendance(w http.ResponseWriter, r *http.Request) {
	var attendances []models.Attendance
	err := h.DB.Preload("Mahasiswa").Preload("Class.Course").Find(&attendances).Error
	if err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil data absensi", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil semua data absensi", attendances)
}