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
	StudentID uint   `json:"student_id" validate:"required,gt=0"`
	Level     string `json:"level" validate:"required"`
	Reason    string `json:"reason" validate:"required"`
	Followup  string `json:"followup" validate:"required"`
	Status    string `json:"status" validate:"required,oneof=Draf Diajukan Perlu diperiksa Diterbitkan (simulasi) Ditutup"`
}

// @Summary Tambah Kasus SP (Admin/Kaprodi)
// @Description Mencatat kasus akademik baru
// @Tags Cases
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body CaseInput true "Data Kasus"
// @Success 201 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Router /admin/cases [post]
func (h *CaseHandler) CreateCase(w http.ResponseWriter, r *http.Request) {
	var input CaseInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}
	if err := utils.Validate.Struct(input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, utils.FormatValidationError(err), nil)
		return
	}

	c := models.Case{
		StudentID: input.StudentID, Level: input.Level, Reason: input.Reason,
		Followup: input.Followup, Status: input.Status,
	}
	if err := h.DB.Create(&c).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menyimpan kasus", nil)
		return
	}
	utils.JSONResponse(w, http.StatusCreated, "Kasus berhasil dibuat", c)
}

// @Summary Lihat Semua Kasus SP
// @Description Mendapatkan daftar kasus akademik
// @Tags Cases
// @Produce json
// @Security BearerAuth
// @Success 200 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /admin/cases/list [get]
func (h *CaseHandler) GetAllCases(w http.ResponseWriter, r *http.Request) {
	var cases []models.Case
	if err := h.DB.Preload("Student").Find(&cases).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil data kasus", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil data kasus", cases)
}

// @Summary Update Kasus SP (Admin/Kaprodi)
// @Description Mengubah data kasus berdasarkan ID
// @Tags Cases
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id query int true "ID Kasus"
// @Param request body CaseInput true "Data Update"
// @Success 200 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Failure 404 {object} utils.Response
// @Router /admin/cases/update [put]
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
	if err := utils.Validate.Struct(input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, utils.FormatValidationError(err), nil)
		return
	}

	var c models.Case
	if err := h.DB.First(&c, idStr).Error; err != nil {
		utils.JSONResponse(w, http.StatusNotFound, "Kasus tidak ditemukan", nil)
		return
	}

	c.StudentID = input.StudentID
	c.Level = input.Level
	c.Reason = input.Reason
	c.Followup = input.Followup
	c.Status = input.Status

	if err := h.DB.Save(&c).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengupdate kasus", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Kasus berhasil diupdate", c)
}

// @Summary Hapus Kasus SP (Admin/Kaprodi)
// @Description Menghapus kasus berdasarkan ID
// @Tags Cases
// @Produce json
// @Security BearerAuth
// @Param id query int true "ID Kasus"
// @Success 200 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /admin/cases/delete [delete]
func (h *CaseHandler) DeleteCase(w http.ResponseWriter, r *http.Request) {
	idStr := r.URL.Query().Get("id")
	if idStr == "" {
		utils.JSONResponse(w, http.StatusBadRequest, "ID kasus harus diisi di URL", nil)
		return
	}
	if err := h.DB.Delete(&models.Case{}, idStr).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menghapus kasus", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Kasus berhasil dihapus", nil)
}