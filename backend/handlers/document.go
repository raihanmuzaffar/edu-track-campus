package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/raihanmuzaffar/edu-track-campus/backend/models"
	"github.com/raihanmuzaffar/edu-track-campus/backend/utils"
	"gorm.io/gorm"
)

type DocumentHandler struct {
	DB *gorm.DB
}

type DocumentInput struct {
	StudentID uint   `json:"student_id"`
	Type      string `json:"type"`
	Semester  string `json:"semester"`
	Status    string `json:"status"`
	Date      string `json:"date"`
}

func parseDocumentDate(dateStr string) time.Time {
	if dateStr == "" {
		return time.Now()
	}
	if t, err := time.Parse(time.RFC3339, dateStr); err == nil {
		return t
	}
	if t, err := time.Parse("2006-01-02", dateStr); err == nil {
		return t
	}
	return time.Now()
}

// CreateDocument creates a new document record
func (h *DocumentHandler) CreateDocument(w http.ResponseWriter, r *http.Request) {
	var input DocumentInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}

	if input.StudentID == 0 {
		utils.JSONResponse(w, http.StatusBadRequest, "Student ID wajib diisi", nil)
		return
	}

	if input.Type == "" {
		input.Type = "Dokumen pendukung"
	}
	if input.Semester == "" {
		input.Semester = "2026 Ganjil"
	}
	if input.Status == "" {
		input.Status = "Draf"
	}

	doc := models.Document{
		StudentID: input.StudentID,
		Type:      input.Type,
		Semester:  input.Semester,
		Status:    input.Status,
		Date:      parseDocumentDate(input.Date),
	}

	if err := h.DB.Create(&doc).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal membuat dokumen", nil)
		return
	}

	h.DB.Preload("Student").First(&doc, doc.ID)
	utils.JSONResponse(w, http.StatusCreated, "Dokumen berhasil dibuat", doc)
}

// GetAllDocuments retrieves all documents with Preload("Student")
func (h *DocumentHandler) GetAllDocuments(w http.ResponseWriter, r *http.Request) {
	var docs []models.Document

	query := h.DB.Model(&models.Document{}).Preload("Student")

	if r.URL.Query().Get("page") != "" || r.URL.Query().Get("limit") != "" {
		limit, offset := utils.GetPagination(r)
		var total int64
		query.Count(&total)

		if err := query.Limit(limit).Offset(offset).Find(&docs).Error; err != nil {
			utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil data dokumen", nil)
			return
		}

		response := map[string]interface{}{
			"data":       docs,
			"total_data": total,
			"page":       (offset / limit) + 1,
			"limit":      limit,
		}
		utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil data dokumen", response)
		return
	}

	if err := query.Find(&docs).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil data dokumen", nil)
		return
	}

	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil data dokumen", docs)
}

// UpdateDocument updates an existing document
func (h *DocumentHandler) UpdateDocument(w http.ResponseWriter, r *http.Request) {
	idStr := r.URL.Query().Get("id")
	if idStr == "" {
		utils.JSONResponse(w, http.StatusBadRequest, "ID dokumen harus diisi di URL", nil)
		return
	}

	var input DocumentInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}

	var doc models.Document
	if err := h.DB.First(&doc, idStr).Error; err != nil {
		utils.JSONResponse(w, http.StatusNotFound, "Dokumen tidak ditemukan", nil)
		return
	}

	if input.StudentID != 0 {
		doc.StudentID = input.StudentID
	}
	if input.Type != "" {
		doc.Type = input.Type
	}
	if input.Semester != "" {
		doc.Semester = input.Semester
	}
	if input.Status != "" {
		doc.Status = input.Status
	}
	if input.Date != "" {
		doc.Date = parseDocumentDate(input.Date)
	}

	if err := h.DB.Save(&doc).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengupdate dokumen", nil)
		return
	}

	h.DB.Preload("Student").First(&doc, doc.ID)
	utils.JSONResponse(w, http.StatusOK, "Dokumen berhasil diupdate", doc)
}

// DeleteDocument deletes a document
func (h *DocumentHandler) DeleteDocument(w http.ResponseWriter, r *http.Request) {
	idStr := r.URL.Query().Get("id")
	if idStr == "" {
		utils.JSONResponse(w, http.StatusBadRequest, "ID dokumen harus diisi di URL", nil)
		return
	}

	if err := h.DB.Delete(&models.Document{}, idStr).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menghapus dokumen", nil)
		return
	}

	utils.JSONResponse(w, http.StatusOK, "Dokumen berhasil dihapus", nil)
}
