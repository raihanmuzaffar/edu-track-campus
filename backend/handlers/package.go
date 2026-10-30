package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/raihanmuzaffar/edu-track-campus/backend/models"
	"github.com/raihanmuzaffar/edu-track-campus/backend/utils"
	"gorm.io/gorm"
)

type PackageHandler struct {
	DB *gorm.DB
}

type PackageInput struct {
	Name      string `json:"name" validate:"required"`
	Term      int    `json:"term" validate:"required,gt=0"`
	Status    string `json:"status" validate:"required,oneof=Draf Siap"`
	CourseIDs []uint `json:"course_ids" validate:"required"`
	ClassIDs  []uint `json:"class_ids" validate:"required"`
}

// @Summary Tambah Paket Semester (Admin)
// @Description Admin membuat paket mata kuliah baru
// @Tags Packages
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body PackageInput true "Data Paket"
// @Success 201 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Router /admin/packages [post]
func (h *PackageHandler) CreatePackage(w http.ResponseWriter, r *http.Request) {
	var input PackageInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}
	if err := utils.Validate.Struct(input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, utils.FormatValidationError(err), nil)
		return
	}

	pkg := models.Package{Name: input.Name, Term: input.Term, Status: input.Status}
	if err := h.DB.Create(&pkg).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal membuat paket", nil)
		return
	}

	if len(input.CourseIDs) > 0 {
		var courses []models.Course
		h.DB.Find(&courses, input.CourseIDs)
		h.DB.Model(&pkg).Association("Courses").Append(courses)
	}
	if len(input.ClassIDs) > 0 {
		var classes []models.Class
		h.DB.Find(&classes, input.ClassIDs)
		h.DB.Model(&pkg).Association("Classes").Append(classes)
	}

	h.DB.Preload("Courses").Preload("Classes").First(&pkg, pkg.ID)
	utils.JSONResponse(w, http.StatusCreated, "Paket berhasil dibuat", pkg)
}

// @Summary Lihat Semua Paket Semester
// @Description Mendapatkan daftar paket semester
// @Tags Packages
// @Produce json
// @Security BearerAuth
// @Success 200 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /admin/packages/list [get]
func (h *PackageHandler) GetAllPackages(w http.ResponseWriter, r *http.Request) {
	var packages []models.Package
	err := h.DB.Preload("Courses").Preload("Classes").Find(&packages).Error
	if err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil data paket", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil data paket", packages)
}

// @Summary Update Paket Semester (Admin)
// @Description Mengubah data paket berdasarkan ID
// @Tags Packages
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id query int true "ID Paket"
// @Param request body PackageInput true "Data Update"
// @Success 200 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Failure 404 {object} utils.Response
// @Router /admin/packages/update [put]
func (h *PackageHandler) UpdatePackage(w http.ResponseWriter, r *http.Request) {
	idStr := r.URL.Query().Get("id")
	if idStr == "" {
		utils.JSONResponse(w, http.StatusBadRequest, "ID paket harus diisi di URL", nil)
		return
	}
	var input PackageInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}
	if err := utils.Validate.Struct(input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, utils.FormatValidationError(err), nil)
		return
	}

	var pkg models.Package
	if err := h.DB.First(&pkg, idStr).Error; err != nil {
		utils.JSONResponse(w, http.StatusNotFound, "Paket tidak ditemukan", nil)
		return
	}

	pkg.Name = input.Name
	pkg.Term = input.Term
	pkg.Status = input.Status
	h.DB.Save(&pkg)

	var courses []models.Course
	h.DB.Find(&courses, input.CourseIDs)
	h.DB.Model(&pkg).Association("Courses").Replace(courses)

	var classes []models.Class
	h.DB.Find(&classes, input.ClassIDs)
	h.DB.Model(&pkg).Association("Classes").Replace(classes)

	h.DB.Preload("Courses").Preload("Classes").First(&pkg, pkg.ID)
	utils.JSONResponse(w, http.StatusOK, "Paket berhasil diupdate", pkg)
}

// @Summary Hapus Paket Semester (Admin)
// @Description Menghapus paket berdasarkan ID
// @Tags Packages
// @Produce json
// @Security BearerAuth
// @Param id query int true "ID Paket"
// @Success 200 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /admin/packages/delete [delete]
func (h *PackageHandler) DeletePackage(w http.ResponseWriter, r *http.Request) {
	idStr := r.URL.Query().Get("id")
	if idStr == "" {
		utils.JSONResponse(w, http.StatusBadRequest, "ID paket harus diisi di URL", nil)
		return
	}
	var pkg models.Package
	if err := h.DB.First(&pkg, idStr).Error; err != nil {
		utils.JSONResponse(w, http.StatusNotFound, "Paket tidak ditemukan", nil)
		return
	}
	h.DB.Model(&pkg).Association("Courses").Clear()
	h.DB.Model(&pkg).Association("Classes").Clear()
	h.DB.Delete(&pkg)
	utils.JSONResponse(w, http.StatusOK, "Paket berhasil dihapus", nil)
}