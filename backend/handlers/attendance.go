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
	ClassID     uint   `json:"class_id"`
	MahasiswaID uint   `json:"mahasiswa_id"`
	Date        string `json:"date"` // Format: "2024-05-20"
	Status      string `json:"status"` // hadir, izin, sakit, alpa
}

// InputAttendance (Hanya Dosen yang mengajar kelas tersebut)
func (h *AttendanceHandler) InputAttendance(w http.ResponseWriter, r *http.Request) {
	dosenID, _ := r.Context().Value(middlewares.UserIDKey).(uint)

	var input AttendanceInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}

	// Validasi apakah dosen mengajar kelas ini
	var class models.Class
	if err := h.DB.First(&class, input.ClassID).Error; err != nil {
		utils.JSONResponse(w, http.StatusNotFound, "Kelas tidak ditemukan", nil)
		return
	}
	if class.DosenID != dosenID {
		utils.JSONResponse(w, http.StatusForbidden, "Anda tidak berhak menginput absensi di kelas ini", nil)
		return
	}

	// Parse tanggal
	dateParsed, err := time.Parse("2006-01-02", input.Date)
	if err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format tanggal harus YYYY-MM-DD", nil)
		return
	}

	attendance := models.Attendance{
		ClassID:     input.ClassID,
		MahasiswaID: input.MahasiswaID,
		Date:        dateParsed,
		Status:      input.Status,
	}

	if err := h.DB.Create(&attendance).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menyimpan absensi", nil)
		return
	}

	utils.JSONResponse(w, http.StatusCreated, "Absensi berhasil disimpan", attendance)
}

// GetMyAttendance (Bisa diakses Mahasiswa dan Orang Tua)
// Untuk Orang Tua, nanti kita bisa tambahkan parameter ?mahasiswa_id=xxx
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