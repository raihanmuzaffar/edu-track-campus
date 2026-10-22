package handlers

import (
	"net/http"

	"github.com/raihanmuzaffar/edu-track-campus/backend/models"
	"github.com/raihanmuzaffar/edu-track-campus/backend/utils"
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