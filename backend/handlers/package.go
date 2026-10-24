package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/raihanmuzaffar/edu-track-campus/backend/models"
	"github.com/raihanmuzaffar/edu-track-campus/backend/utils"
	"gorm.io/gorm"
)

type PackageHandler struct {
	DB *gorm.DB
}

type PackageInput struct {
	Name     string `json:"name"`
	Term     int    `json:"term"`
	Status   string `json:"status"`
	CourseIDs []uint `json:"course_ids"`
	ClassIDs  []uint `json:"class_ids"`
}

func (h *PackageHandler) CreatePackage(w http.ResponseWriter, r *http.Request) {
	var input PackageInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}

	// Validasi input dasar
	if input.Name == "" {
		utils.JSONResponse(w, http.StatusBadRequest, "Nama paket wajib diisi", nil)
		return
	}

	// Buat paket utama terlebih dahulu
	packageData := models.Package{
		Name:   input.Name,
		Term:   input.Term,
		Status: input.Status,
	}
	if packageData.Status == "" {
		packageData.Status = "Draf"
	}

	// Simpan data utama Package terlebih dahulu
	if err := h.DB.Create(&packageData).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal membuat paket", nil)
		return
	}

	// Ambil data Courses berdasarkan ID yang dikirim dari frontend dan Append relasinya
	if len(input.CourseIDs) > 0 {
		var courses []models.Course
		if err := h.DB.Find(&courses, input.CourseIDs).Error; err != nil {
			h.DB.Delete(&packageData)
			utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil data mata kuliah", nil)
			return
		}
		if err := h.DB.Model(&packageData).Association("Courses").Append(courses); err != nil {
			utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menghubungkan relasi mata kuliah", nil)
			return
		}
	}

	// Ambil data Classes berdasarkan ID yang dikirim dari frontend dan Append relasinya
	if len(input.ClassIDs) > 0 {
		var classes []models.Class
		if err := h.DB.Find(&classes, input.ClassIDs).Error; err != nil {
			utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil data kelas", nil)
			return
		}
		if err := h.DB.Model(&packageData).Association("Classes").Append(classes); err != nil {
			utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menghubungkan relasi kelas", nil)
			return
		}
	}

	// Muat ulang paket dengan relasi Courses dan Classes untuk respons
	if err := h.DB.Preload("Courses").Preload("Classes").First(&packageData, packageData.ID).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal memuat relasi paket", nil)
		return
	}

	utils.JSONResponse(w, http.StatusCreated, "Paket berhasil dibuat", packageData)
}

func (h *PackageHandler) GetAllPackages(w http.ResponseWriter, r *http.Request) {
	var packages []models.Package
	err := h.DB.Preload("Courses").Preload("Classes").Find(&packages).Error
	if err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil data paket", nil)
		return
	}

	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil data paket", packages)
}

func (h *PackageHandler) UpdatePackage(w http.ResponseWriter, r *http.Request) {
	// Ambil ID dari query parameter
	idStr := r.URL.Query().Get("id")
	if idStr == "" {
		utils.JSONResponse(w, http.StatusBadRequest, "ID paket wajib disertakan", nil)
		return
	}

	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "ID paket tidak valid", nil)
		return
	}

	var input PackageInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}

	// Cari paket yang ada
	var packageData models.Package
	if err := h.DB.First(&packageData, id).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			utils.JSONResponse(w, http.StatusNotFound, "Paket tidak ditemukan", nil)
		} else {
			utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil paket", nil)
		}
		return
	}

	// Update fields dasar
	packageData.Name = input.Name
	packageData.Term = input.Term
	if input.Status != "" {
		packageData.Status = input.Status
	}

	// Simpan perubahan dasar
	if err := h.DB.Save(&packageData).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal memperbarui paket", nil)
		return
	}

	// Update relasi many-to-many untuk Courses dengan Replace
	if input.CourseIDs != nil {
		var courses []models.Course
		if len(input.CourseIDs) > 0 {
			if err := h.DB.Find(&courses, input.CourseIDs).Error; err != nil {
				utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil data mata kuliah", nil)
				return
			}
		}
		if err := h.DB.Model(&packageData).Association("Courses").Replace(courses); err != nil {
			utils.JSONResponse(w, http.StatusInternalServerError, "Gagal memperbarui relasi mata kuliah", nil)
			return
		}
	}

	// Update relasi many-to-many untuk Classes dengan Replace
	if input.ClassIDs != nil {
		var classes []models.Class
		if len(input.ClassIDs) > 0 {
			if err := h.DB.Find(&classes, input.ClassIDs).Error; err != nil {
				utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil data kelas", nil)
				return
			}
		}
		if err := h.DB.Model(&packageData).Association("Classes").Replace(classes); err != nil {
			utils.JSONResponse(w, http.StatusInternalServerError, "Gagal memperbarui relasi kelas", nil)
			return
		}
	}

	// Muat ulang paket dengan relasi untuk respons
	if err := h.DB.Preload("Courses").Preload("Classes").First(&packageData, packageData.ID).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal memuat relasi paket", nil)
		return
	}

	utils.JSONResponse(w, http.StatusOK, "Paket berhasil diperbarui", packageData)
}

func (h *PackageHandler) DeletePackage(w http.ResponseWriter, r *http.Request) {
	// Ambil ID dari query parameter
	idStr := r.URL.Query().Get("id")
	if idStr == "" {
		utils.JSONResponse(w, http.StatusBadRequest, "ID paket wajib disertakan", nil)
		return
	}

	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "ID paket tidak valid", nil)
		return
	}

	// Hapus paket
	if err := h.DB.Delete(&models.Package{}, id).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menghapus paket", nil)
		return
	}

	utils.JSONResponse(w, http.StatusOK, "Paket berhasil dihapus", nil)
}