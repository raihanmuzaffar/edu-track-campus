package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/raihanmuzaffar/edu-track-campus/backend/models"
	"github.com/raihanmuzaffar/edu-track-campus/backend/utils"
	"gorm.io/gorm"
)

type CaseHandler struct {
	DB *gorm.DB
}

type CaseInput struct {
	StudentID uint   `json:"student_id"`
	Level     string `json:"level"`
	Reason    string `json:"reason"`
	Followup  string `json:"followup"`
	Status    string `json:"status"`
}

// CreateCase creates a new case (Surat Peringatan)
func (h *CaseHandler) CreateCase(w http.ResponseWriter, r *http.Request) {
	var input CaseInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}

	if input.StudentID == 0 {
		utils.JSONResponse(w, http.StatusBadRequest, "Student ID wajib diisi", nil)
		return
	}

	if input.Level == "" {
		input.Level = "SP 1"
	}

	if input.Status == "" {
		input.Status = "Draf"
	}

	caseRecord := models.Case{
		StudentID: input.StudentID,
		Level:     input.Level,
		Reason:    input.Reason,
		Followup:  input.Followup,
		Status:    input.Status,
	}

	if err := h.DB.Create(&caseRecord).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal membuat surat peringatan", nil)
		return
	}

	h.DB.Preload("Student").First(&caseRecord, caseRecord.ID)
	utils.JSONResponse(w, http.StatusCreated, "Surat peringatan berhasil dibuat", caseRecord)
}

// GetAllCases retrieves all cases with Preload("Student")
func (h *CaseHandler) GetAllCases(w http.ResponseWriter, r *http.Request) {
	var cases []models.Case

	query := h.DB.Model(&models.Case{}).Preload("Student")

	if r.URL.Query().Get("page") != "" || r.URL.Query().Get("limit") != "" {
		limit, offset := utils.GetPagination(r)
		var total int64
		query.Count(&total)

		if err := query.Limit(limit).Offset(offset).Find(&cases).Error; err != nil {
			utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil data surat peringatan", nil)
			return
		}

		response := map[string]interface{}{
			"data":       cases,
			"total_data": total,
			"page":       (offset / limit) + 1,
			"limit":      limit,
		}
		utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil data surat peringatan", response)
		return
	}

	if err := query.Find(&cases).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil data surat peringatan", nil)
		return
	}

	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil data surat peringatan", cases)
}

// UpdateCase updates an existing case
func (h *CaseHandler) UpdateCase(w http.ResponseWriter, r *http.Request) {
	idStr := r.URL.Query().Get("id")
	if idStr == "" {
		utils.JSONResponse(w, http.StatusBadRequest, "ID kasus harus diisi di URL", nil)
		return
	}

	var input CaseInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}

	var caseRecord models.Case
	if err := h.DB.First(&caseRecord, idStr).Error; err != nil {
		utils.JSONResponse(w, http.StatusNotFound, "Kasus tidak ditemukan", nil)
		return
	}

	if input.StudentID != 0 {
		caseRecord.StudentID = input.StudentID
	}
	if input.Level != "" {
		caseRecord.Level = input.Level
	}
	caseRecord.Reason = input.Reason
	caseRecord.Followup = input.Followup
	if input.Status != "" {
		caseRecord.Status = input.Status
	}

	if err := h.DB.Save(&caseRecord).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengupdate surat peringatan", nil)
		return
	}

	h.DB.Preload("Student").First(&caseRecord, caseRecord.ID)
	utils.JSONResponse(w, http.StatusOK, "Surat peringatan berhasil diupdate", caseRecord)
}

// DeleteCase deletes a case
func (h *CaseHandler) DeleteCase(w http.ResponseWriter, r *http.Request) {
	idStr := r.URL.Query().Get("id")
	if idStr == "" {
		utils.JSONResponse(w, http.StatusBadRequest, "ID kasus harus diisi di URL", nil)
		return
	}

	if err := h.DB.Delete(&models.Case{}, idStr).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menghapus surat peringatan", nil)
		return
	}

	utils.JSONResponse(w, http.StatusOK, "Surat peringatan berhasil dihapus", nil)
}
