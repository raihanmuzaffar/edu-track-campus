package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/raihanmuzaffar/edu-track-campus/backend/models"
	"github.com/raihanmuzaffar/edu-track-campus/backend/utils"
	"gorm.io/gorm"
)

type KHSHandler struct {
	DB *gorm.DB
}

type KHSInput struct {
	StudentID uint   `json:"student_id"`
	Semester  string `json:"semester"`
	Status    string `json:"status"`
}

// CreateKHS creates a new KHS record
func (h *KHSHandler) CreateKHS(w http.ResponseWriter, r *http.Request) {
	var input KHSInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}

	if input.StudentID == 0 {
		utils.JSONResponse(w, http.StatusBadRequest, "Student ID wajib diisi", nil)
		return
	}

	if input.Semester == "" {
		input.Semester = "2026 Ganjil"
	}
	if input.Status == "" {
		input.Status = "Draf"
	}

	khs := models.KHSRecord{
		StudentID: input.StudentID,
		Semester:  input.Semester,
		Status:    input.Status,
	}

	if err := h.DB.Create(&khs).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal membuat status KHS", nil)
		return
	}

	h.DB.Preload("Student").First(&khs, khs.ID)
	utils.JSONResponse(w, http.StatusCreated, "Status KHS berhasil dibuat", khs)
}

// GetAllKHS retrieves all KHS records with Preload("Student")
func (h *KHSHandler) GetAllKHS(w http.ResponseWriter, r *http.Request) {
	var records []models.KHSRecord

	query := h.DB.Model(&models.KHSRecord{}).Preload("Student")

	if err := query.Find(&records).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil data KHS", nil)
		return
	}

	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil data KHS", records)
}

// UpdateKHStatus updates or creates (Upsert) KHS status for a student and semester
func (h *KHSHandler) UpdateKHStatus(w http.ResponseWriter, r *http.Request) {
	var input KHSInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}

	if input.StudentID == 0 {
		utils.JSONResponse(w, http.StatusBadRequest, "Student ID wajib diisi", nil)
		return
	}

	if input.Semester == "" {
		input.Semester = "2026 Ganjil"
	}

	if input.Status == "" {
		input.Status = "Draf"
	}

	var khs models.KHSRecord
	err := h.DB.Where("student_id = ? AND semester = ?", input.StudentID, input.Semester).First(&khs).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			khs = models.KHSRecord{
				StudentID: input.StudentID,
				Semester:  input.Semester,
				Status:    input.Status,
			}
			if err := h.DB.Create(&khs).Error; err != nil {
				utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menyimpan status KHS", nil)
				return
			}
		} else {
			utils.JSONResponse(w, http.StatusInternalServerError, "Terjadi kesalahan database", nil)
			return
		}
	} else {
		khs.Status = input.Status
		if err := h.DB.Save(&khs).Error; err != nil {
			utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengupdate status KHS", nil)
			return
		}
	}

	h.DB.Preload("Student").First(&khs, khs.ID)
	utils.JSONResponse(w, http.StatusOK, "Status KHS berhasil diperbarui", khs)
}

// UpdateKHS updates an existing KHS record by ID
func (h *KHSHandler) UpdateKHS(w http.ResponseWriter, r *http.Request) {
	idStr := r.URL.Query().Get("id")
	if idStr == "" {
		utils.JSONResponse(w, http.StatusBadRequest, "ID KHS harus diisi di URL", nil)
		return
	}

	var input KHSInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}

	var khs models.KHSRecord
	if err := h.DB.First(&khs, idStr).Error; err != nil {
		utils.JSONResponse(w, http.StatusNotFound, "KHS tidak ditemukan", nil)
		return
	}

	if input.StudentID != 0 {
		khs.StudentID = input.StudentID
	}
	if input.Semester != "" {
		khs.Semester = input.Semester
	}
	if input.Status != "" {
		khs.Status = input.Status
	}

	if err := h.DB.Save(&khs).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengupdate KHS", nil)
		return
	}

	h.DB.Preload("Student").First(&khs, khs.ID)
	utils.JSONResponse(w, http.StatusOK, "KHS berhasil diupdate", khs)
}

// DeleteKHS deletes a KHS record
func (h *KHSHandler) DeleteKHS(w http.ResponseWriter, r *http.Request) {
	idStr := r.URL.Query().Get("id")
	if idStr == "" {
		utils.JSONResponse(w, http.StatusBadRequest, "ID KHS harus diisi di URL", nil)
		return
	}

	if err := h.DB.Delete(&models.KHSRecord{}, idStr).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menghapus KHS", nil)
		return
	}

	utils.JSONResponse(w, http.StatusOK, "KHS berhasil dihapus", nil)
}
