package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/raihanmuzaffar/edu-track-campus/backend/models"
	"github.com/raihanmuzaffar/edu-track-campus/backend/utils"
	"gorm.io/gorm"
)

type UKTHandler struct {
	DB *gorm.DB
}

type UKTInput struct {
	StudentID uint   `json:"student_id"`
	Semester  string `json:"semester"`
	Billed    float64 `json:"billed"`
	Paid      float64 `json:"paid"`
	DueDate   string `json:"due_date"`
}

// CreateUKT creates a new UKT record
func (h *UKTHandler) CreateUKT(w http.ResponseWriter, r *http.Request) {
	var input UKTInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}

	var dueDate time.Time
	if input.DueDate != "" {
		parsedTime, err := time.Parse(time.RFC3339, input.DueDate)
		if err != nil {
			utils.JSONResponse(w, http.StatusBadRequest, "Format tanggal tidak valid, gunakan RFC3339", nil)
			return
		}
		dueDate = parsedTime
	}

	ukt := models.UKT{
		StudentID: input.StudentID,
		Semester:  input.Semester,
		Billed:    input.Billed,
		Paid:      input.Paid,
		DueDate:   dueDate,
	}

	if err := h.DB.Create(&ukt).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal membuat UKT", nil)
		return
	}

	utils.JSONResponse(w, http.StatusCreated, "UKT berhasil dibuat", ukt)
}

// GetAllUKT retrieves all UKT records with pagination
func (h *UKTHandler) GetAllUKT(w http.ResponseWriter, r *http.Request) {
	var ukts []models.UKT

	limit, offset := utils.GetPagination(r)

	query := h.DB.Model(&models.UKT{}).Preload("Student")

	var total int64
	query.Count(&total)

	if err := query.Limit(limit).Offset(offset).Find(&ukts).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil data UKT", nil)
		return
	}

	response := map[string]interface{}{
		"data":       ukts,
		"total_data": total,
		"page":       (offset / limit) + 1,
		"limit":      limit,
	}

	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil data UKT", response)
}

// UpdateUKT updates an existing UKT record
func (h *UKTHandler) UpdateUKT(w http.ResponseWriter, r *http.Request) {
	idStr := r.URL.Query().Get("id")
	if idStr == "" {
		utils.JSONResponse(w, http.StatusBadRequest, "ID UKT harus diisi di URL", nil)
		return
	}

	var input UKTInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}

	var ukt models.UKT
	if err := h.DB.First(&ukt, idStr).Error; err != nil {
		utils.JSONResponse(w, http.StatusNotFound, "UKT tidak ditemukan", nil)
		return
	}

	if input.DueDate != "" {
		parsedTime, err := time.Parse(time.RFC3339, input.DueDate)
		if err != nil {
			utils.JSONResponse(w, http.StatusBadRequest, "Format tanggal tidak valid, gunakan RFC3339", nil)
			return
		}
		ukt.DueDate = parsedTime
	}

	ukt.StudentID = input.StudentID
	ukt.Semester = input.Semester
	ukt.Billed = input.Billed
	ukt.Paid = input.Paid

	if err := h.DB.Save(&ukt).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengupdate UKT", nil)
		return
	}

	utils.JSONResponse(w, http.StatusOK, "UKT berhasil diupdate", ukt)
}

// DeleteUKT deletes a UKT record
func (h *UKTHandler) DeleteUKT(w http.ResponseWriter, r *http.Request) {
	idStr := r.URL.Query().Get("id")
	if idStr == "" {
		utils.JSONResponse(w, http.StatusBadRequest, "ID UKT harus diisi di URL", nil)
		return
	}

	if err := h.DB.Delete(&models.UKT{}, idStr).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menghapus UKT", nil)
		return
	}

	utils.JSONResponse(w, http.StatusOK, "UKT berhasil dihapus", nil)
}
