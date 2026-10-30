package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/raihanmuzaffar/edu-track-campus/backend/models"
	"github.com/raihanmuzaffar/edu-track-campus/backend/utils"
	"gorm.io/gorm"
)

type CourseHandler struct {
	DB *gorm.DB
}

type CourseInput struct {
	Code     string `json:"code" validate:"required"`
	Name     string `json:"name" validate:"required,min=3"`
	SKS      int    `json:"sks" validate:"required,gt=0,max=6"`
	Semester int    `json:"semester" validate:"required,gt=0"`
}

// @Summary Tambah Mata Kuliah (Admin)
// @Description Admin menambahkan mata kuliah baru ke katalog
// @Tags Courses
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body CourseInput true "Data Mata Kuliah"
// @Success 201 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /courses [post]
func (h *CourseHandler) CreateCourse(w http.ResponseWriter, r *http.Request) {
	var input CourseInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}
	if err := utils.Validate.Struct(input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, utils.FormatValidationError(err), nil)
		return
	}

	course := models.Course{Code: input.Code, Name: input.Name, SKS: input.SKS, Semester: input.Semester}
	if err := h.DB.Create(&course).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menyimpan mata kuliah (mungkin kode sudah ada)", nil)
		return
	}
	utils.JSONResponse(w, http.StatusCreated, "Mata kuliah berhasil ditambahkan", course)
}

// @Summary Lihat Semua Mata Kuliah (Admin/Kaprodi)
// @Description Mendapatkan daftar mata kuliah dengan pagination dan fitur pencarian
// @Tags Courses
// @Produce json
// @Security BearerAuth
// @Param page query int false "Halaman (default: 1)"
// @Param limit query int false "Jumlah per halaman (default: 10)"
// @Param search query string false "Cari berdasarkan nama atau kode"
// @Success 200 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /courses/list [get]
func (h *CourseHandler) GetCourses(w http.ResponseWriter, r *http.Request) {
	var courses []models.Course
	limit, offset := utils.GetPagination(r)
	search := r.URL.Query().Get("search")

	query := h.DB.Model(&models.Course{})
	if search != "" {
		query = query.Where("name ILIKE ? OR code ILIKE ?", "%"+search+"%", "%"+search+"%")
	}

	var total int64
	query.Count(&total)

	if err := query.Limit(limit).Offset(offset).Find(&courses).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil data mata kuliah", nil)
		return
	}
	response := map[string]interface{}{
		"data":       courses,
		"total_data": total,
		"page":       (offset / limit) + 1,
		"limit":      limit,
	}
	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil data mata kuliah", response)
}

// @Summary Update Mata Kuliah (Admin)
// @Description Mengubah data mata kuliah berdasarkan ID
// @Tags Courses
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id query int true "ID Mata Kuliah"
// @Param request body CourseInput true "Data Update"
// @Success 200 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Failure 404 {object} utils.Response
// @Router /courses/update [put]
func (h *CourseHandler) UpdateCourse(w http.ResponseWriter, r *http.Request) {
	idStr := r.URL.Query().Get("id")
	if idStr == "" {
		utils.JSONResponse(w, http.StatusBadRequest, "ID mata kuliah harus diisi di URL", nil)
		return
	}

	var input CourseInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}
	if err := utils.Validate.Struct(input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, utils.FormatValidationError(err), nil)
		return
	}

	var course models.Course
	if err := h.DB.First(&course, idStr).Error; err != nil {
		utils.JSONResponse(w, http.StatusNotFound, "Mata kuliah tidak ditemukan", nil)
		return
	}

	course.Code = input.Code
	course.Name = input.Name
	course.SKS = input.SKS
	course.Semester = input.Semester

	if err := h.DB.Save(&course).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengupdate mata kuliah", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Mata kuliah berhasil diupdate", course)
}

// @Summary Hapus Mata Kuliah (Admin)
// @Description Menghapus mata kuliah berdasarkan ID
// @Tags Courses
// @Produce json
// @Security BearerAuth
// @Param id query int true "ID Mata Kuliah"
// @Success 200 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /courses/delete [delete]
func (h *CourseHandler) DeleteCourse(w http.ResponseWriter, r *http.Request) {
	idStr := r.URL.Query().Get("id")
	if idStr == "" {
		utils.JSONResponse(w, http.StatusBadRequest, "ID mata kuliah harus diisi di URL", nil)
		return
	}
	if err := h.DB.Delete(&models.Course{}, idStr).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menghapus mata kuliah", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Mata kuliah berhasil dihapus", nil)
}