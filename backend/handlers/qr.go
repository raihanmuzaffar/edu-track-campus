package handlers

import (
	"encoding/json"
	"errors"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/raihanmuzaffar/edu-track-campus/backend/config"
	"github.com/raihanmuzaffar/edu-track-campus/backend/middlewares"
	"github.com/raihanmuzaffar/edu-track-campus/backend/models"
	"github.com/raihanmuzaffar/edu-track-campus/backend/utils"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

var (
	errAttendanceAlreadyExists = errors.New("attendance already exists")
	errQRSessionInactive       = errors.New("QR session is inactive or expired")
	errQRInvalidPeriod         = errors.New("QR class period is invalid")
)

const qrSessionLifetime = 15 * time.Minute

type QRHandler struct {
	DB *gorm.DB
}

type GenerateQRInput struct {
	ClassID uint `json:"class_id" validate:"required,gt=0"`
}

type ScanQRInput struct {
	Token string `json:"token" validate:"required"`
}

// @Summary Buat sesi QR absensi
// @Description Membuat sesi QR aktif berdurasi terbatas untuk kelas yang diampu dosen.
// @Tags QR
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body GenerateQRInput true "ID kelas"
// @Success 201 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Failure 403 {object} utils.Response
// @Failure 404 {object} utils.Response
// @Router /qr/generate [post]
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

	var qrSession models.QRSession
	err := h.DB.Transaction(func(tx *gorm.DB) error {
		var class models.Class
		if err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).First(&class, input.ClassID).Error; err != nil {
			return err
		}
		if class.DosenID != dosenID {
			return gorm.ErrInvalidData
		}
		period := config.AcademicPeriodNow()
		if strings.TrimSpace(class.Year) == "" || strings.TrimSpace(class.Semester) == "" ||
			class.Year != period.Year || class.Semester != period.Semester {
			return errQRInvalidPeriod
		}

		// Replace the previous active session and create its successor atomically.
		if err := tx.Model(&models.QRSession{}).
			Where("class_id = ? AND is_active = ?", input.ClassID, true).
			Update("is_active", false).Error; err != nil {
			return err
		}

		qrSession = models.QRSession{
			Token:     uuid.NewString(),
			ClassID:   input.ClassID,
			DosenID:   dosenID,
			IsActive:  true,
			ExpiresAt: time.Now().Add(qrSessionLifetime),
		}
		return tx.Create(&qrSession).Error
	})
	if err != nil {
		switch {
		case errors.Is(err, gorm.ErrRecordNotFound):
			utils.JSONResponse(w, http.StatusNotFound, "Kelas tidak ditemukan", nil)
		case errors.Is(err, gorm.ErrInvalidData):
			utils.JSONResponse(w, http.StatusForbidden, "Anda tidak berhak membuat QR untuk kelas ini", nil)
		case errors.Is(err, errQRInvalidPeriod):
			utils.JSONResponse(w, http.StatusBadRequest, "Periode kelas belum valid untuk periode aktif", nil)
		default:
			utils.JSONResponse(w, http.StatusInternalServerError, "Gagal membuat QR Code", nil)
		}
		return
	}

	utils.JSONResponse(w, http.StatusCreated, "QR Code berhasil dibuat", qrSession)
}

// @Summary Catat absensi QR
// @Description Mencatat maksimal satu absensi per mahasiswa, kelas, dan tanggal Jakarta.
// @Tags QR
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body ScanQRInput true "Token QR"
// @Success 201 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Failure 403 {object} utils.Response
// @Failure 409 {object} utils.Response
// @Router /qr/scan [post]
func (h *QRHandler) ScanQR(w http.ResponseWriter, r *http.Request) {
	mahasiswaID, _ := r.Context().Value(middlewares.UserIDKey).(uint)

	var input ScanQRInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}
	input.Token = strings.TrimSpace(input.Token)
	if err := utils.Validate.Struct(input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, utils.FormatValidationError(err), nil)
		return
	}

	var qrSession models.QRSession
	if err := h.DB.Where("token = ? AND is_active = ?", input.Token, true).First(&qrSession).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			utils.JSONResponse(w, http.StatusBadRequest, "QR Code tidak valid atau sudah tidak aktif", nil)
			return
		}
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal memeriksa QR Code", nil)
		return
	}

	now := time.Now()
	if !now.Before(qrSession.ExpiresAt) {
		if err := h.DB.Model(&qrSession).Update("is_active", false).Error; err != nil {
			utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menonaktifkan QR Code kedaluwarsa", nil)
			return
		}
		utils.JSONResponse(w, http.StatusBadRequest, "QR Code sudah kedaluwarsa", nil)
		return
	}

	var attendance models.Attendance
	err := h.DB.Transaction(func(tx *gorm.DB) error {
		// Lock the class first in every QR transaction. This serializes session
		// generation and scans with a consistent lock order (class, then session).
		var class models.Class
		if err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).First(&class, qrSession.ClassID).Error; err != nil {
			return err
		}

		// Re-check and lock the session inside the transaction so a concurrently
		// closed or expired QR cannot be used after the initial lookup.
		var currentSession models.QRSession
		if err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).
			Where("id = ? AND is_active = ? AND expires_at > ?", qrSession.ID, true, time.Now()).
			First(&currentSession).Error; err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				return errQRSessionInactive
			}
			return err
		}

		var enrollment models.Enrollment
		if err := activeEnrollmentFilter(tx.Where("mahasiswa_id = ? AND class_id = ?", mahasiswaID, qrSession.ClassID)).
			First(&enrollment).Error; err != nil {
			return err
		}

		location, err := time.LoadLocation("Asia/Jakarta")
		if err != nil {
			location = time.Local
		}
		localNow := now.In(location)
		startOfDay := time.Date(localNow.Year(), localNow.Month(), localNow.Day(), 0, 0, 0, 0, location)
		startOfNextDay := startOfDay.AddDate(0, 0, 1)

		var existing models.Attendance
		err = tx.Where(
			"mahasiswa_id = ? AND class_id = ? AND date >= ? AND date < ?",
			mahasiswaID, qrSession.ClassID, startOfDay, startOfNextDay,
		).First(&existing).Error
		if err == nil {
			return errAttendanceAlreadyExists
		}
		if !errors.Is(err, gorm.ErrRecordNotFound) {
			return err
		}

		attendance = models.Attendance{
			ClassID:     qrSession.ClassID,
			MahasiswaID: mahasiswaID,
			Date:        now,
			Status:      "hadir",
		}
		return tx.Create(&attendance).Error
	})
	if err != nil {
		switch {
		case errors.Is(err, errQRSessionInactive):
			utils.JSONResponse(w, http.StatusBadRequest, "QR Code sudah tidak aktif atau kedaluwarsa", nil)
		case errors.Is(err, gorm.ErrRecordNotFound):
			// A missing class or enrollment is treated as not eligible.
			utils.JSONResponse(w, http.StatusForbidden, "Anda tidak terdaftar di kelas ini", nil)
		case errors.Is(err, errAttendanceAlreadyExists):
			utils.JSONResponse(w, http.StatusConflict, "Anda sudah melakukan absensi untuk kelas ini hari ini", nil)
		default:
			utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menyimpan absensi", nil)
		}
		return
	}

	utils.JSONResponse(w, http.StatusCreated, "Absensi berhasil dicatat", attendance)
}

// @Summary Tutup sesi QR
// @Description Menutup sesi QR milik dosen yang sedang masuk.
// @Tags QR
// @Produce json
// @Security BearerAuth
// @Param id query int true "ID sesi QR"
// @Success 200 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Failure 403 {object} utils.Response
// @Failure 404 {object} utils.Response
// @Router /qr/close [post]
func (h *QRHandler) CloseQR(w http.ResponseWriter, r *http.Request) {
	dosenID, _ := r.Context().Value(middlewares.UserIDKey).(uint)
	id, err := strconv.ParseUint(r.URL.Query().Get("id"), 10, 64)
	if err != nil || id == 0 {
		utils.JSONResponse(w, http.StatusBadRequest, "ID sesi tidak valid", nil)
		return
	}

	var qrSession models.QRSession
	if err := h.DB.First(&qrSession, id).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			utils.JSONResponse(w, http.StatusNotFound, "Sesi QR tidak ditemukan", nil)
		} else {
			utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil sesi QR", nil)
		}
		return
	}
	if qrSession.DosenID != dosenID {
		utils.JSONResponse(w, http.StatusForbidden, "Anda tidak berhak menutup sesi ini", nil)
		return
	}
	if err := h.DB.Model(&qrSession).Update("is_active", false).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menutup sesi QR", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Sesi QR berhasil ditutup", nil)
}

// @Summary Daftar sesi QR aktif
// @Description Mengambil sesi aktif yang belum kedaluwarsa untuk administrator dan kaprodi.
// @Tags QR
// @Produce json
// @Security BearerAuth
// @Success 200 {object} utils.Response
// @Router /admin/qr/active [get]
func (h *QRHandler) GetActiveQRs(w http.ResponseWriter, r *http.Request) {
	var sessions []models.QRSession
	if err := h.DB.Preload("Class").Preload("Dosen").
		Where("is_active = ? AND expires_at > ?", true, time.Now()).
		Find(&sessions).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil data sesi QR", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil sesi QR aktif", sessions)
}

// @Summary Status QR kelas dosen
// @Description Mengambil sesi QR aktif yang benar-benar berasal dari server
// @Tags QR
// @Produce json
// @Security BearerAuth
// @Param class_id query int true "ID Kelas"
// @Success 200 {object} utils.Response
// @Router /qr/session [get]
func (h *QRHandler) GetSessionStatus(w http.ResponseWriter, r *http.Request) {
	dosenID, _ := r.Context().Value(middlewares.UserIDKey).(uint)
	classID, err := strconv.ParseUint(r.URL.Query().Get("class_id"), 10, 64)
	if err != nil || classID == 0 {
		utils.JSONResponse(w, http.StatusBadRequest, "ID kelas tidak valid", nil)
		return
	}
	var class models.Class
	if err := h.DB.First(&class, uint(classID)).Error; err != nil {
		utils.JSONResponse(w, http.StatusNotFound, "Kelas tidak ditemukan", nil)
		return
	}
	if class.DosenID != dosenID {
		utils.JSONResponse(w, http.StatusForbidden, "Anda tidak memiliki akses ke kelas ini", nil)
		return
	}
	var session models.QRSession
	err = h.DB.Preload("Class").Where("class_id = ? AND is_active = ? AND expires_at > ?", classID, true, time.Now()).
		Order("created_at DESC").First(&session).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		utils.JSONResponse(w, http.StatusOK, "Tidak ada sesi QR aktif", map[string]interface{}{"active": false})
		return
	}
	if err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal memeriksa sesi QR", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil sesi QR", map[string]interface{}{
		"active": true, "session": session,
	})
}

// @Summary Validasi token QR
// @Description Memeriksa token QR tanpa mencatat absensi
// @Tags QR
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body ScanQRInput true "Token QR"
// @Success 200 {object} utils.Response
// @Router /qr/validate [post]
func (h *QRHandler) ValidateQR(w http.ResponseWriter, r *http.Request) {
	mahasiswaID, _ := r.Context().Value(middlewares.UserIDKey).(uint)
	var input ScanQRInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}
	input.Token = strings.TrimSpace(input.Token)
	if err := utils.Validate.Struct(input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, utils.FormatValidationError(err), nil)
		return
	}
	var session models.QRSession
	if err := h.DB.Preload("Class.Course").Where("token = ? AND is_active = ? AND expires_at > ?", input.Token, true, time.Now()).
		First(&session).Error; err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "QR Code tidak valid atau sudah kedaluwarsa", nil)
		return
	}
	var enrollment models.Enrollment
	if err := activeEnrollmentFilter(h.DB.Where("mahasiswa_id = ? AND class_id = ?", mahasiswaID, session.ClassID)).
		First(&enrollment).Error; err != nil {
		utils.JSONResponse(w, http.StatusForbidden, "Anda tidak terdaftar aktif di kelas ini", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "QR Code valid", map[string]interface{}{
		"valid": true, "class_id": session.ClassID,
		"class_name": session.Class.Name, "course": session.Class.Course.Name,
		"expires_at": session.ExpiresAt,
	})
}
