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

// GetDashboardStats (Hanya Admin)
func (h *AdminHandler) GetDashboardStats(w http.ResponseWriter, r *http.Request) {
	var totalMahasiswa, totalDosen, totalCourses, totalClasses int64

	// Menghitung jumlah data menggunakan GORM Count
	h.DB.Model(&models.User{}).Where("role = ?", "mahasiswa").Count(&totalMahasiswa)
	h.DB.Model(&models.User{}).Where("role = ?", "dosen").Count(&totalDosen)
	h.DB.Model(&models.Course{}).Count(&totalCourses)
	h.DB.Model(&models.Class{}).Count(&totalClasses)

	// Kembalikan data dalam bentuk JSON yang rapi
	stats := map[string]int64{
		"total_mahasiswa": totalMahasiswa,
		"total_dosen":     totalDosen,
		"total_courses":   totalCourses,
		"total_classes":   totalClasses,
	}

	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil statistik dashboard", stats)
}

// GetAllUsers (Hanya Admin)
func (h *AdminHandler) GetAllUsers(w http.ResponseWriter, r *http.Request) {
	var users []models.User

	// Mengambil semua user. Karena di model User password di-set `json:"-"`, 
	// maka password tidak akan pernah ikut terkirim ke Frontend (Aman!).
	if err := h.DB.Find(&users).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil data user", nil)
		return
	}

	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil data user", users)
}

// ==========================================
// --- FITUR CRUD USER LANJUTAN ---
// ==========================================

type AdminUserInput struct {
	Name     string `json:"name"`
	Email    string `json:"email"`
	Password string `json:"password"`
	Role     string `json:"role"`
}

// CreateUser (Admin membuatkan akun untuk Dosen/Mahasiswa)
func (h *AdminHandler) CreateUser(w http.ResponseWriter, r *http.Request) {
	var input AdminUserInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
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

// UpdateUser (Admin mengedit data user)
func (h *AdminHandler) UpdateUser(w http.ResponseWriter, r *http.Request) {
	// Ambil ID dari URL Query Parameter (misal: /api/v1/admin/users/update?id=1)
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

	var user models.User
	if err := h.DB.First(&user, id).Error; err != nil {
		utils.JSONResponse(w, http.StatusNotFound, "User tidak ditemukan", nil)
		return
	}

	// Update field (Password biasanya diupdate lewat endpoint terpisah/reset password)
	user.Name = input.Name
	user.Email = input.Email
	user.Role = input.Role

	if err := h.DB.Save(&user).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengupdate user", nil)
		return
	}

	utils.JSONResponse(w, http.StatusOK, "User berhasil diupdate", user)
}

// DeleteUser (Admin menghapus user)
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