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
	StudentID uint   `json:"student_id" validate:"required,gt=0"`
	Type      string `json:"type" validate:"required"`
	Semester  string `json:"semester" validate:"required"`
	Status    string `json:"status" validate:"required,oneof=Lengkap Memerlukan perbaikan Draf"`
	Date      string `json:"date" validate:"required"` // Format: YYYY-MM-DD
}

// @Summary Tambah Dokumen (Admin/Kaprodi)
// @Description Menambahkan data dokumen akademik
// @Tags Documents
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body DocumentInput true "Data Dokumen"
// @Success 201 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Router /admin/documents [post]
func (h *DocumentHandler) CreateDocument(w http.ResponseWriter, r *http.Request) {
	var input DocumentInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}
	if err := utils.Validate.Struct(input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, utils.FormatValidationError(err), nil)
		return
	}

	dateParsed, _ := time.Parse("2006-01-02", input.Date)
	doc := models.Document{
		StudentID: input.StudentID, Type: input.Type, Semester: input.Semester,
		Status: input.Status, Date: dateParsed,
	}
	if err := h.DB.Create(&doc).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menyimpan dokumen", nil)
		return
	}
	utils.JSONResponse(w, http.StatusCreated, "Dokumen berhasil dibuat", doc)
}

// @Summary Lihat Semua Dokumen
// @Description Mendapatkan daftar dokumen akademik
// @Tags Documents
// @Produce json
// @Security BearerAuth
// @Success 200 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /admin/documents/list [get]
func (h *DocumentHandler) GetAllDocuments(w http.ResponseWriter, r *http.Request) {
	var docs []models.Document
	if err := h.DB.Preload("Student").Find(&docs).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil data dokumen", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil data dokumen", docs)
}

// @Summary Update Dokumen (Admin/Kaprodi)
// @Description Mengubah data dokumen berdasarkan ID
// @Tags Documents
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id query int true "ID Dokumen"
// @Param request body DocumentInput true "Data Update"
// @Success 200 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Failure 404 {object} utils.Response
// @Router /admin/documents/update [put]
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
	if err := utils.Validate.Struct(input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, utils.FormatValidationError(err), nil)
		return
	}

	var doc models.Document
	if err := h.DB.First(&doc, idStr).Error; err != nil {
		utils.JSONResponse(w, http.StatusNotFound, "Dokumen tidak ditemukan", nil)
		return
	}

	dateParsed, _ := time.Parse("2006-01-02", input.Date)

	doc.StudentID = input.StudentID
	doc.Type = input.Type
	doc.Semester = input.Semester
	doc.Status = input.Status
	doc.Date = dateParsed

	if err := h.DB.Save(&doc).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengupdate dokumen", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Dokumen berhasil diupdate", doc)
}

// @Summary Hapus Dokumen (Admin/Kaprodi)
// @Description Menghapus dokumen berdasarkan ID
// @Tags Documents
// @Produce json
// @Security BearerAuth
// @Param id query int true "ID Dokumen"
// @Success 200 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /admin/documents/delete [delete]
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