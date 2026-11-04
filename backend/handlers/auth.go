package handlers

import (
	"encoding/json"
	"fmt"
	"math/rand"
	"net/http"
	"time"

	"github.com/raihanmuzaffar/edu-track-campus/backend/config"
	"github.com/raihanmuzaffar/edu-track-campus/backend/middlewares"
	"github.com/raihanmuzaffar/edu-track-campus/backend/models"
	"github.com/raihanmuzaffar/edu-track-campus/backend/utils"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

type AuthHandler struct {
	DB *gorm.DB
}

type RegisterInput struct {
	Name     string `json:"name" validate:"required,min=3"`
	Email    string `json:"email" validate:"required,email"`
	Password string `json:"password" validate:"required,min=8"`
	Role     string `json:"role" validate:"required,oneof=admin kaprodi dosen mahasiswa orangtua"`
}

type LoginInput struct {
	Email    string `json:"email" validate:"required,email"`
	Password string `json:"password" validate:"required"`
}

type ForgotPasswordInput struct {
	Email string `json:"email" validate:"required,email"`
}

type ResetPasswordInput struct {
	Email       string `json:"email" validate:"required,email"`
	Token       string `json:"token" validate:"required"`
	NewPassword string `json:"new_password" validate:"required,min=8"`
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

	// Validasi Input
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
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mendaftarkan user (email mungkin sudah terdaftar)", nil)
		return
	}

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
// @Failure 400 {object} utils.Response
// @Failure 401 {object} utils.Response
// @Router /login [post]
func (h *AuthHandler) Login(w http.ResponseWriter, r *http.Request) {
	var input LoginInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}

	// Validasi Input
	if err := utils.Validate.Struct(input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, utils.FormatValidationError(err), nil)
		return
	}

	var user models.User
	if err := h.DB.Where("email = ?", input.Email).First(&user).Error; err != nil {
		utils.JSONResponse(w, http.StatusUnauthorized, "Email atau password salah", nil)
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

	utils.JSONResponse(w, http.StatusOK, "Login berhasil", map[string]interface{}{
		"token": token,
		"role":  user.Role,
	})
}

// @Summary Lupa Password (Minta Token)
// @Description Mengirimkan token reset password ke email pengguna
// @Tags Auth
// @Accept json
// @Produce json
// @Param request body ForgotPasswordInput true "Email"
// @Success 200 {object} utils.Response
// @Router /forgot-password [post]
func (h *AuthHandler) ForgotPassword(w http.ResponseWriter, r *http.Request) {
	var input ForgotPasswordInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}
	if err := utils.Validate.Struct(input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, utils.FormatValidationError(err), nil)
		return
	}

	var user models.User
	if err := h.DB.Where("email = ?", input.Email).First(&user).Error; err != nil {
		// Demi keamanan, kita tetap balas OK meskipun email tidak ada
		utils.JSONResponse(w, http.StatusOK, "Jika email terdaftar, instruksi reset password telah dikirim", nil)
		return
	}

	// Generate 6 digit token acak (Tidak perlu rand.Seed lagi di Go 1.20+)
	token := fmt.Sprintf("%06d", rand.Intn(1000000))

	// Simpan token dan waktu kedaluwarsa (15 menit)
	user.ResetToken = token
	user.ResetTokenExpiry = time.Now().Add(15 * time.Minute)
	_ = h.DB.Save(&user) // Tambahkan _ = untuk linter

	// --- PROSES PENGIRIMAN EMAIL ---
	subject := "EduTrack Campus - Reset Password"
	body := fmt.Sprintf("Halo,\n\nAnda meminta untuk mereset password akun EduTrack Campus Anda.\n\nBerikut adalah kode token reset password Anda:\n\n%s\n\nToken ini hanya berlaku selama 15 menit. Jangan bagikan kode ini kepada siapa pun.\n\nJika Anda tidak merasa meminta reset password, abaikan email ini.\n\nSalam,\nTim EduTrack Campus", token)

	err := utils.SendEmail(user.Email, subject, body)
	if err != nil {
		// Jika gagal kirim email, catat error di log Docker
		fmt.Printf("❌ Gagal mengirim email ke %s: %v\n", user.Email, err)
	} else {
		fmt.Printf("✅ Email reset password berhasil dikirim ke %s\n", user.Email)
	}

	utils.JSONResponse(w, http.StatusOK, "Jika email terdaftar, instruksi reset password telah dikirim", nil)
}

// @Summary Reset Password (Gunakan Token)
// @Description Mengganti password menggunakan token yang valid
// @Tags Auth
// @Accept json
// @Produce json
// @Param request body ResetPasswordInput true "Data Reset"
// @Success 200 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Router /reset-password [post]
func (h *AuthHandler) ResetPassword(w http.ResponseWriter, r *http.Request) {
	var input ResetPasswordInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}
	if err := utils.Validate.Struct(input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, utils.FormatValidationError(err), nil)
		return
	}

	var user models.User
	if err := h.DB.Where("email = ?", input.Email).First(&user).Error; err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Email tidak ditemukan", nil)
		return
	}

	// Validasi Token & Kedaluwarsa
	if user.ResetToken != input.Token {
		utils.JSONResponse(w, http.StatusBadRequest, "Token tidak valid", nil)
		return
	}
	if time.Now().After(user.ResetTokenExpiry) {
		utils.JSONResponse(w, http.StatusBadRequest, "Token sudah kedaluwarsa", nil)
		return
	}

	// Hash password baru
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(input.NewPassword), bcrypt.DefaultCost)
	if err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengenkripsi password", nil)
		return
	}

	// Update password & hapus token
	user.Password = string(hashedPassword)
	user.ResetToken = ""
	user.ResetTokenExpiry = time.Time{}
	_ = h.DB.Save(&user) // Tambahkan _ = untuk linter

	utils.JSONResponse(w, http.StatusOK, "Password berhasil diubah. Silakan login kembali.", nil)
}

// @Summary Get Current User Profile
// @Description Mendapatkan data user yang sedang login berdasarkan JWT Token
// @Tags Auth
// @Produce json
// @Security BearerAuth
// @Success 200 {object} utils.Response
// @Failure 404 {object} utils.Response
// @Router /users/me [get]
func (h *AuthHandler) GetMe(w http.ResponseWriter, r *http.Request) {
	// Ambil UserID dari Context (yang disisipkan oleh Middleware)
	userID, ok := r.Context().Value(middlewares.UserIDKey).(uint)
	if !ok {
		utils.JSONResponse(w, http.StatusUnauthorized, "Gagal mengambil data user dari token", nil)
		return
	}
	
	var user models.User
	if err := h.DB.First(&user, userID).Error; err != nil {
		utils.JSONResponse(w, http.StatusNotFound, "User tidak ditemukan", nil)
		return
	}

	// Kembalikan data user (Password otomatis disembunyikan karena tag json:"-")
	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil profil", user)
}