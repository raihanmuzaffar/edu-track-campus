package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/raihanmuzaffar/edu-track-campus/backend/middlewares"
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
	Status string `json:"status" validate:"required,oneof='Draf' 'Siap dipublikasikan' 'Perlu diperiksa' 'Dipublikasikan'"`
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
	query := h.DB.Model(&models.KHSRecord{}).Preload("Student")
	role, _ := r.Context().Value(middlewares.RoleKey).(string)
	if role == "kaprodi" {
		programScope, ok := currentProgramScope(w, r, h.DB)
		if !ok {
			return
		}
		query = scopedStudentRecords(query, "Student", programScope)
	}
	if err := query.Find(&khs).Error; err != nil {
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
// @Router /admin/khs/update [put]
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
	actorRole, _ := r.Context().Value(middlewares.RoleKey).(string)
	programScope, ok := currentProgramScope(w, r, h.DB)
	if !ok {
		return
	}
	if actorRole == "kaprodi" {
		allowed, err := studentBelongsToProgram(h.DB, input.StudentID, programScope)
		if err != nil {
			utils.JSONResponse(w, http.StatusInternalServerError, "Gagal memverifikasi cakupan mahasiswa", nil)
			return
		}
		if !allowed {
			utils.JSONResponse(w, http.StatusForbidden, "Mahasiswa berada di luar prodi yang ditugaskan", nil)
			return
		}
	}

	var student models.User
	if err := h.DB.Where("id = ? AND role = ?", input.StudentID, "mahasiswa").First(&student).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			utils.JSONResponse(w, http.StatusBadRequest, "Mahasiswa tidak ditemukan", nil)
			return
		}
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal memvalidasi mahasiswa", nil)
		return
	}

	var khs models.KHSRecord
	err := h.DB.Where("student_id = ? AND semester = ?", input.StudentID, input.Semester).First(&khs).Error

	if err == nil {
		khs.Status = input.Status
		if err := h.DB.Save(&khs).Error; err != nil {
			utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menyimpan data KHS", nil)
			return
		}
	} else if err == gorm.ErrRecordNotFound {
		khs = models.KHSRecord{
			StudentID: input.StudentID, Semester: input.Semester, Status: input.Status,
		}
		if err := h.DB.Create(&khs).Error; err != nil {
			utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menyimpan data KHS", nil)
			return
		}
	} else {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil data KHS", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Status KHS berhasil diperbarui", khs)
}
