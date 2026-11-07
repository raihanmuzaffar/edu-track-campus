package handlers

import (
	"encoding/json"
	"errors"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/raihanmuzaffar/edu-track-campus/backend/middlewares"
	"github.com/raihanmuzaffar/edu-track-campus/backend/models"
	"github.com/raihanmuzaffar/edu-track-campus/backend/utils"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
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

// GenerateQR creates a short-lived attendance session for a class owned by the caller.
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
		if err := tx.First(&class, input.ClassID).Error; err != nil {
			return err
		}
		if class.DosenID != dosenID {
			return gorm.ErrInvalidData
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
		default:
			utils.JSONResponse(w, http.StatusInternalServerError, "Gagal membuat QR Code", nil)
		}
		return
	}

	utils.JSONResponse(w, http.StatusCreated, "QR Code berhasil dibuat", qrSession)
}

// ScanQR records one attendance per student and class per Jakarta calendar day.
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
		// Serialize scans for this class. This closes the check-then-insert race
		// when the same student scans from two devices at nearly the same time.
		var class models.Class
		if err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).First(&class, qrSession.ClassID).Error; err != nil {
			return err
		}

		var enrollment models.Enrollment
		if err := tx.Where("mahasiswa_id = ? AND class_id = ?", mahasiswaID, qrSession.ClassID).
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
			return gorm.ErrDuplicatedKey
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
		case errors.Is(err, gorm.ErrRecordNotFound):
			// A missing class or enrollment is treated as not eligible.
			utils.JSONResponse(w, http.StatusForbidden, "Anda tidak terdaftar di kelas ini", nil)
		case errors.Is(err, gorm.ErrDuplicatedKey):
			utils.JSONResponse(w, http.StatusConflict, "Anda sudah melakukan absensi untuk kelas ini hari ini", nil)
		default:
			utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menyimpan absensi", nil)
		}
		return
	}

	utils.JSONResponse(w, http.StatusCreated, "Absensi berhasil dicatat", attendance)
}

// CloseQR closes a session owned by the requesting lecturer.
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

// GetActiveQRs lists active, non-expired sessions for administrators and program heads.
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
