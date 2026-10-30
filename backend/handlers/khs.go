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
	StudentID uint   `json:"student_id" validate:"required,gt=0"`
	Semester  string `json:"semester" validate:"required"`
	// Perbaikan: Gunakan tanda kutip tunggal untuk opsi yang memiliki spasi
	Status    string `json:"status" validate:"required,oneof='Siap dipublikasikan' 'Perlu diperiksa'"`
}

// @Summary Lihat Semua KHS (Admin/Kaprodi)
// @Description Mendapatkan daftar status publikasi KHS mahasiswa
// @Tags KHS
// @Produce json
// @Security BearerAuth
// @Success 200 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /admin/khs/list [get]
func (h *KHSHandler) GetAllKHS(w http.ResponseWriter, r *http.Request) {
	var khs []models.KHSRecord
	if err := h.DB.Preload("Student").Find(&khs).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil data KHS", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil data KHS", khs)
}

// @Summary Update Status Publikasi KHS (Admin/Kaprodi)
// @Description Mengubah status publikasi KHS mahasiswa
// @Tags KHS
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body KHSInput true "Data KHS"
// @Success 200 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Router /admin/khs/update [post]
func (h *KHSHandler) UpdateKHStatus(w http.ResponseWriter, r *http.Request) {
	var input KHSInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}
	if err := utils.Validate.Struct(input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, utils.FormatValidationError(err), nil)
		return
	}

	var khs models.KHSRecord
	err := h.DB.Where("student_id = ? AND semester = ?", input.StudentID, input.Semester).First(&khs).Error

	if err == nil {
		khs.Status = input.Status
		h.DB.Save(&khs)
	} else {
		khs = models.KHSRecord{
			StudentID: input.StudentID, Semester: input.Semester, Status: input.Status,
		}
		if err := h.DB.Create(&khs).Error; err != nil {
			utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menyimpan data KHS", nil)
			return
		}
	}
	utils.JSONResponse(w, http.StatusOK, "Status KHS berhasil diperbarui", khs)
}