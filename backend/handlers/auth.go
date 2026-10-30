package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/raihanmuzaffar/edu-track-campus/backend/config"
	"github.com/raihanmuzaffar/edu-track-campus/backend/models"
	"github.com/raihanmuzaffar/edu-track-campus/backend/utils"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

type AuthHandler struct {
	DB *gorm.DB
}

type RegisterInput struct {
	Name     string `json:"name"`
	Email    string `json:"email"`
	Password string `json:"password"`
	Role     string `json:"role"`
}

// Tambahan: Struct khusus untuk Login agar Swagger UI lebih rapi
type LoginInput struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

// @Summary Register User Baru
// @Description Mendaftarkan user baru (Admin, Kaprodi, Dosen, Mahasiswa, Orang Tua)
// @Tags Auth
// @Accept json
// @Produce json
// @Param request body RegisterInput true "Data Registrasi"
// @Success 201 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Router /register [post]
func (h *AuthHandler) Register(w http.ResponseWriter, r *http.Request) {
	var input RegisterInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}

	// Perbaikan 1: Cek error dari bcrypt.GenerateFromPassword
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
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mendaftarkan user (email mungkin sudah terdaftar)", nil)
		return
	}

	// Perbaikan 2: Gunakan utils.JSONResponse (otomatis menangani error Encode)
	utils.JSONResponse(w, http.StatusCreated, "Registrasi berhasil", map[string]interface{}{
		"user_id": user.ID,
		"email":   user.Email,
		"role":    user.Role,
	})
}

// @Summary Login User
// @Description Autentikasi user dan mendapatkan JWT Token
// @Tags Auth
// @Accept json
// @Produce json
// @Param request body LoginInput true "Data Login"
// @Success 200 {object} utils.Response
// @Failure 401 {object} utils.Response
// @Router /login [post]
func (h *AuthHandler) Login(w http.ResponseWriter, r *http.Request) {
	// Menggunakan LoginInput
	var input LoginInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}

	var user models.User
	if err := h.DB.Where("email = ?", input.Email).First(&user).Error; err != nil {
		utils.JSONResponse(w, http.StatusUnauthorized, "Email atau password salah", nil) // Jangan beri tahu spesifik "user tidak ditemukan" untuk alasan keamanan
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(input.Password)); err != nil {
		utils.JSONResponse(w, http.StatusUnauthorized, "Email atau password salah", nil)
		return
	}

	token, err := config.GenerateToken(user.ID, user.Role)
	if err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal membuat token", nil)
		return
	}

	// Perbaikan 3: Gunakan utils.JSONResponse
	utils.JSONResponse(w, http.StatusOK, "Login berhasil", map[string]interface{}{
		"token": token,
		"role":  user.Role,
	})
}