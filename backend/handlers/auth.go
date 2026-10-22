package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/raihanmuzaffar/edu-track-campus/backend/config"
	"github.com/raihanmuzaffar/edu-track-campus/backend/models"
	"github.com/raihanmuzaffar/edu-track-campus/backend/utils" // Tambahkan import utils
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

func (h *AuthHandler) Login(w http.ResponseWriter, r *http.Request) {
	var input RegisterInput
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