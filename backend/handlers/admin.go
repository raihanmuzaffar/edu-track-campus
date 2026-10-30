package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/raihanmuzaffar/edu-track-campus/backend/models"
	"github.com/raihanmuzaffar/edu-track-campus/backend/utils"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

type AdminHandler struct {
	DB *gorm.DB
}

// @Summary Statistik Dashboard (Admin)
// @Description Mendapatkan ringkasan jumlah mahasiswa, dosen, mata kuliah, dan kelas
// @Tags Admin
// @Produce json
// @Security BearerAuth
// @Success 200 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /admin/stats [get]
func (h *AdminHandler) GetDashboardStats(w http.ResponseWriter, r *http.Request) {
	var totalMahasiswa, totalDosen, totalCourses, totalClasses int64
	h.DB.Model(&models.User{}).Where("role = ?", "mahasiswa").Count(&totalMahasiswa)
	h.DB.Model(&models.User{}).Where("role = ?", "dosen").Count(&totalDosen)
	h.DB.Model(&models.Course{}).Count(&totalCourses)
	h.DB.Model(&models.Class{}).Count(&totalClasses)

	stats := map[string]int64{
		"total_mahasiswa": totalMahasiswa,
		"total_dosen":     totalDosen,
		"total_courses":   totalCourses,
		"total_classes":   totalClasses,
	}
	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil statistik dashboard", stats)
}

// @Summary Lihat Semua User (Admin/Kaprodi)
// @Description Mendapatkan daftar semua user dengan pagination dan fitur pencarian
// @Tags Admin
// @Produce json
// @Security BearerAuth
// @Param page query int false "Halaman (default: 1)"
// @Param limit query int false "Jumlah per halaman (default: 10)"
// @Param search query string false "Cari berdasarkan nama atau email"
// @Success 200 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /admin/users [get]
func (h *AdminHandler) GetAllUsers(w http.ResponseWriter, r *http.Request) {
	var users []models.User
	limit, offset := utils.GetPagination(r)
	search := r.URL.Query().Get("search")

	query := h.DB.Model(&models.User{})
	if search != "" {
		query = query.Where("name ILIKE ? OR email ILIKE ?", "%"+search+"%", "%"+search+"%")
	}

	var total int64
	query.Count(&total)

	if err := query.Limit(limit).Offset(offset).Find(&users).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil data user", nil)
		return
	}

	response := map[string]interface{}{
		"data":       users,
		"total_data": total,
		"page":       (offset / limit) + 1,
		"limit":      limit,
	}
	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil data user", response)
}

type AdminUserInput struct {
	Name     string `json:"name" validate:"required,min=3"`
	Email    string `json:"email" validate:"required,email"`
	Password string `json:"password" validate:"omitempty,min=8"`
	Role     string `json:"role" validate:"required,oneof=admin kaprodi dosen mahasiswa orangtua"`
}

// @Summary Tambah User Baru (Admin)
// @Description Admin membuatkan akun baru untuk Dosen/Mahasiswa/Kaprodi
// @Tags Admin
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body AdminUserInput true "Data User Baru"
// @Success 201 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /admin/users/create [post]
func (h *AdminHandler) CreateUser(w http.ResponseWriter, r *http.Request) {
	var input AdminUserInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}

	if err := utils.Validate.Struct(input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, utils.FormatValidationError(err), nil)
		return
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(input.Password), bcrypt.DefaultCost)
	if err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengenkripsi password", nil)
		return
	}

	user := models.User{
		Name:     input.Name,
		Email:    input.Email,
		Password: string(hashedPassword),
		Role:     input.Role,
	}

	if err := h.DB.Create(&user).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal membuat user baru (email mungkin sudah terdaftar)", nil)
		return
	}
	utils.JSONResponse(w, http.StatusCreated, "User berhasil dibuat oleh Admin", user)
}

// @Summary Update User (Admin)
// @Description Admin mengubah data user berdasarkan ID
// @Tags Admin
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id query int true "ID User"
// @Param request body AdminUserInput true "Data Update"
// @Success 200 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Failure 404 {object} utils.Response
// @Router /admin/users/update [put]
func (h *AdminHandler) UpdateUser(w http.ResponseWriter, r *http.Request) {
	id := r.URL.Query().Get("id")
	if id == "" {
		utils.JSONResponse(w, http.StatusBadRequest, "ID user tidak ditemukan di URL", nil)
		return
	}

	var input AdminUserInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}

	if err := utils.Validate.Struct(input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, utils.FormatValidationError(err), nil)
		return
	}

	var user models.User
	if err := h.DB.First(&user, id).Error; err != nil {
		utils.JSONResponse(w, http.StatusNotFound, "User tidak ditemukan", nil)
		return
	}

	user.Name = input.Name
	user.Email = input.Email
	user.Role = input.Role

	if err := h.DB.Save(&user).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengupdate user", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "User berhasil diupdate", user)
}

// @Summary Hapus User (Admin)
// @Description Admin menghapus user berdasarkan ID
// @Tags Admin
// @Produce json
// @Security BearerAuth
// @Param id query int true "ID User"
// @Success 200 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /admin/users/delete [delete]
func (h *AdminHandler) DeleteUser(w http.ResponseWriter, r *http.Request) {
	id := r.URL.Query().Get("id")
	if id == "" {
		utils.JSONResponse(w, http.StatusBadRequest, "ID user tidak ditemukan di URL", nil)
		return
	}
	if err := h.DB.Delete(&models.User{}, id).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menghapus user", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "User berhasil dihapus", nil)
}