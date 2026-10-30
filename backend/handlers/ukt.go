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
	StudentID uint    `json:"student_id" validate:"required,gt=0"`
	Semester  string  `json:"semester" validate:"required"`
	Billed    float64 `json:"billed" validate:"required,gte=0"`
	Paid      float64 `json:"paid" validate:"required,gte=0"`
	DueDate   string  `json:"due_date" validate:"required"` // Format: YYYY-MM-DD
}

// @Summary Tambah Tagihan UKT (Admin)
// @Description Admin membuat tagihan UKT baru
// @Tags UKT
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body UKTInput true "Data UKT"
// @Success 201 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Router /admin/ukt [post]
func (h *UKTHandler) CreateUKT(w http.ResponseWriter, r *http.Request) {
	var input UKTInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}
	if err := utils.Validate.Struct(input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, utils.FormatValidationError(err), nil)
		return
	}

	dateParsed, err := time.Parse("2006-01-02", input.DueDate)
	if err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format tanggal harus YYYY-MM-DD", nil)
		return
	}

	ukt := models.UKT{
		StudentID: input.StudentID, Semester: input.Semester,
		Billed: input.Billed, Paid: input.Paid, DueDate: dateParsed,
	}
	if err := h.DB.Create(&ukt).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menyimpan data UKT", nil)
		return
	}
	utils.JSONResponse(w, http.StatusCreated, "Data UKT berhasil dibuat", ukt)
}

// @Summary Lihat Semua Data UKT (Admin/Kaprodi)
// @Description Admin dan Kaprodi melihat seluruh data UKT mahasiswa
// @Tags UKT
// @Produce json
// @Security BearerAuth
// @Success 200 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /admin/ukt/list [get]
func (h *UKTHandler) GetAllUKT(w http.ResponseWriter, r *http.Request) {
	var ukt []models.UKT
	err := h.DB.Preload("Student").Find(&ukt).Error
	if err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil data UKT", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil data UKT", ukt)
}

// @Summary Update Data UKT (Admin)
// @Description Mengubah data UKT berdasarkan ID
// @Tags UKT
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id query int true "ID UKT"
// @Param request body UKTInput true "Data Update"
// @Success 200 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Failure 404 {object} utils.Response
// @Router /admin/ukt/update [put]
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
	if err := utils.Validate.Struct(input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, utils.FormatValidationError(err), nil)
		return
	}

	var ukt models.UKT
	if err := h.DB.First(&ukt, idStr).Error; err != nil {
		utils.JSONResponse(w, http.StatusNotFound, "Data UKT tidak ditemukan", nil)
		return
	}

	dateParsed, err := time.Parse("2006-01-02", input.DueDate)
	if err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format tanggal harus YYYY-MM-DD", nil)
		return
	}

	ukt.StudentID = input.StudentID
	ukt.Semester = input.Semester
	ukt.Billed = input.Billed
	ukt.Paid = input.Paid
	ukt.DueDate = dateParsed

	if err := h.DB.Save(&ukt).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengupdate data UKT", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Data UKT berhasil diupdate", ukt)
}

// @Summary Hapus Data UKT (Admin)
// @Description Menghapus data UKT berdasarkan ID
// @Tags UKT
// @Produce json
// @Security BearerAuth
// @Param id query int true "ID UKT"
// @Success 200 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /admin/ukt/delete [delete]
func (h *UKTHandler) DeleteUKT(w http.ResponseWriter, r *http.Request) {
	idStr := r.URL.Query().Get("id")
	if idStr == "" {
		utils.JSONResponse(w, http.StatusBadRequest, "ID UKT harus diisi di URL", nil)
		return
	}
	if err := h.DB.Delete(&models.UKT{}, idStr).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menghapus data UKT", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Data UKT berhasil dihapus", nil)
}