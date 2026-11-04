package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/google/uuid"
	"github.com/raihanmuzaffar/edu-track-campus/backend/middlewares"
	"github.com/raihanmuzaffar/edu-track-campus/backend/models"
	"github.com/raihanmuzaffar/edu-track-campus/backend/utils"
	"gorm.io/gorm"
)

type QRHandler struct {
	DB *gorm.DB
}

type GenerateQRInput struct {
	ClassID uint `json:"class_id" validate:"required,gt=0"`
}

type ScanQRInput struct {
	Token string `json:"token" validate:"required"`
}

// GenerateQR (Hanya Dosen)
func (h *QRHandler) GenerateQR(w http.ResponseWriter, r *http.Request) {
	dosenID, _ := r.Context().Value(middlewares.UserIDKey).(uint)

	var input GenerateQRInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}
	if err := utils.Validate.Struct(input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, utils.FormatValidationError(err), nil)
		return
	}

	// 1. Validasi apakah Dosen mengajar kelas ini
	var class models.Class
	if err := h.DB.First(&class, input.ClassID).Error; err != nil {
		utils.JSONResponse(w, http.StatusNotFound, "Kelas tidak ditemukan", nil)
		return
	}
	if class.DosenID != dosenID {
		utils.JSONResponse(w, http.StatusForbidden, "Anda tidak berhak membuat QR untuk kelas ini", nil)
		return
	}

	// 2. Nonaktifkan sesi QR lama yang masih aktif di kelas ini (jika ada)
	h.DB.Model(&models.QRSession{}).Where("class_id = ? AND is_active = ?", input.ClassID, true).Update("is_active", false)

	// 3. Buat sesi QR baru (berlaku 15 menit)
	token := uuid.New().String()
	qrSession := models.QRSession{
		Token:     token,
		ClassID:   input.ClassID,
		DosenID:   dosenID,
		IsActive:  true,
		ExpiresAt: time.Now().Add(15 * time.Minute),
	}

	if err := h.DB.Create(&qrSession).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal membuat QR Code", nil)
		return
	}

	utils.JSONResponse(w, http.StatusCreated, "QR Code berhasil dibuat", qrSession)
}

// ScanQR (Hanya Mahasiswa)
func (h *QRHandler) ScanQR(w http.ResponseWriter, r *http.Request) {
	mahasiswaID, _ := r.Context().Value(middlewares.UserIDKey).(uint)

	var input ScanQRInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}
	if err := utils.Validate.Struct(input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, utils.FormatValidationError(err), nil)
		return
	}

	// 1. Cari Sesi QR berdasarkan Token
	var qrSession models.QRSession
	if err := h.DB.Where("token = ? AND is_active = ?", input.Token, true).First(&qrSession).Error; err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "QR Code tidak valid atau sudah tidak aktif", nil)
		return
	}

	// 2. Cek apakah sudah kedaluwarsa
	if time.Now().After(qrSession.ExpiresAt) {
		// Matikan sesi karena sudah expired
		h.DB.Model(&qrSession).Update("is_active", false)
		utils.JSONResponse(w, http.StatusBadRequest, "QR Code sudah kedaluwarsa", nil)
		return
	}

	// 3. Cek apakah mahasiswa terdaftar di kelas ini
	var enrollment models.Enrollment
	if err := h.DB.Where("mahasiswa_id = ? AND class_id = ?", mahasiswaID, qrSession.ClassID).First(&enrollment).Error; err != nil {
		utils.JSONResponse(w, http.StatusForbidden, "Anda tidak terdaftar di kelas ini", nil)
		return
	}

	// 4. Cek apakah mahasiswa sudah absen hari ini untuk kelas ini (mencegah double scan)
	today := time.Now().Format("2006-01-02")
	var existingAttendance models.Attendance
	err := h.DB.Where("mahasiswa_id = ? AND class_id = ? AND DATE(date) = ?", mahasiswaID, qrSession.ClassID, today).First(&existingAttendance).Error
	if err == nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Anda sudah melakukan absensi untuk kelas ini hari ini", nil)
		return
	}

	// 5. Simpan Kehadiran
	attendance := models.Attendance{
		ClassID:     qrSession.ClassID,
		MahasiswaID: mahasiswaID,
		Date:        time.Now(),
		Status:      "hadir",
	}

	if err := h.DB.Create(&attendance).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menyimpan absensi", nil)
		return
	}

	utils.JSONResponse(w, http.StatusCreated, "Absensi berhasil dicatat", attendance)
}

// CloseQR (Hanya Dosen)
func (h *QRHandler) CloseQR(w http.ResponseWriter, r *http.Request) {
	dosenID, _ := r.Context().Value(middlewares.UserIDKey).(uint)
	
	idStr := r.URL.Query().Get("id")
	if idStr == "" {
		utils.JSONResponse(w, http.StatusBadRequest, "ID sesi tidak ditemukan", nil)
		return
	}

	var qrSession models.QRSession
	if err := h.DB.First(&qrSession, idStr).Error; err != nil {
		utils.JSONResponse(w, http.StatusNotFound, "Sesi QR tidak ditemukan", nil)
		return
	}

	if qrSession.DosenID != dosenID {
		utils.JSONResponse(w, http.StatusForbidden, "Anda tidak berhak menutup sesi ini", nil)
		return
	}

	h.DB.Model(&qrSession).Update("is_active", false)
	utils.JSONResponse(w, http.StatusOK, "Sesi QR berhasil ditutup", nil)
}

// GetActiveQRs (Hanya Admin/Kaprodi)
func (h *QRHandler) GetActiveQRs(w http.ResponseWriter, r *http.Request) {
	var sessions []models.QRSession
	// Ambil sesi yang aktif dan belum kedaluwarsa
	if err := h.DB.Preload("Class").Preload("Dosen").Where("is_active = ? AND expires_at > ?", true, time.Now()).Find(&sessions).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil data sesi QR", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil sesi QR aktif", sessions)
}