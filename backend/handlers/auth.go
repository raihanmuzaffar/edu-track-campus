package handlers

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
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
	Role     string `json:"role" validate:"required,oneof=dosen mahasiswa orangtua"`
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

type RefreshTokenInput struct {
	RefreshToken string `json:"refresh_token" validate:"required"`
}

type LogoutInput struct {
	RefreshToken string `json:"refresh_token"`
}

type ChangePasswordInput struct {
	OldPassword string `json:"old_password" validate:"required"`
	NewPassword string `json:"new_password" validate:"required,min=8"`
}

type UpdateProfileInput struct {
	Name         string `json:"name" validate:"required,min=3"`
	Email        string `json:"email" validate:"required,email"`
	NIM          string `json:"nim"`
	ProgramStudi string `json:"program_studi"`
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

	token, jti, err := config.GenerateToken(user.ID, user.Role)
	if err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal membuat token", nil)
		return
	}
	refreshToken, err := config.IssueRefreshToken(user.ID, user.Role, jti)
	if err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal membuat sesi login", nil)
		return
	}

	utils.JSONResponse(w, http.StatusOK, "Login berhasil", map[string]interface{}{
		"token":         token,
		"refresh_token": refreshToken,
		"token_type":    "Bearer",
		"expires_in":    int64(config.AccessTokenTTL().Seconds()),
		"role":          user.Role,
	})
}

// @Summary Perbarui access token
// @Description Memutar refresh token dan menerbitkan pasangan token baru
// @Tags Auth
// @Accept json
// @Produce json
// @Param request body RefreshTokenInput true "Refresh token"
// @Success 200 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Failure 401 {object} utils.Response
// @Router /refresh-token [post]
func (h *AuthHandler) RefreshToken(w http.ResponseWriter, r *http.Request) {
	var input RefreshTokenInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}
	if err := utils.Validate.Struct(input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, utils.FormatValidationError(err), nil)
		return
	}

	record, ok := config.ConsumeRefreshToken(input.RefreshToken)
	if !ok {
		utils.JSONResponse(w, http.StatusUnauthorized, "Sesi tidak valid atau sudah digunakan", nil)
		return
	}
	var user models.User
	if err := h.DB.First(&user, record.UserID).Error; err != nil || user.Role != record.Role {
		utils.JSONResponse(w, http.StatusUnauthorized, "Akun tidak ditemukan atau peran berubah", nil)
		return
	}

	token, jti, err := config.GenerateToken(user.ID, user.Role)
	if err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal membuat token", nil)
		return
	}
	refreshToken, err := config.IssueRefreshToken(user.ID, user.Role, jti)
	if err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal membuat sesi login", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Token berhasil diperbarui", map[string]interface{}{
		"token":         token,
		"refresh_token": refreshToken,
		"token_type":    "Bearer",
		"expires_in":    int64(config.AccessTokenTTL().Seconds()),
		"role":          user.Role,
	})
}

// @Summary Logout
// @Description Mencabut access token dan refresh token di server
// @Tags Auth
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body LogoutInput true "Refresh token"
// @Success 200 {object} utils.Response
// @Failure 503 {object} utils.Response
// @Router /logout [post]
func (h *AuthHandler) Logout(w http.ResponseWriter, r *http.Request) {
	var input LogoutInput
	_ = json.NewDecoder(r.Body).Decode(&input)
	if _, err := config.RevokeRefreshToken(strings.TrimSpace(input.RefreshToken)); err != nil {
		utils.JSONResponse(w, http.StatusServiceUnavailable, "Sesi tidak dapat dicabut saat ini", nil)
		return
	}
	jti, _ := r.Context().Value(middlewares.JTIKey).(string)
	claims, err := config.ParseToken(strings.TrimSpace(strings.TrimPrefix(r.Header.Get("Authorization"), "Bearer ")))
	if err == nil {
		if err := config.RevokeAccess(claims.ID, config.TokenExpiry(claims)); err != nil {
			utils.JSONResponse(w, http.StatusServiceUnavailable, "Sesi tidak dapat dicabut saat ini", nil)
			return
		}
	} else if jti != "" {
		if err := config.RevokeAccess(jti, config.AccessTokenTTL()); err != nil {
			utils.JSONResponse(w, http.StatusServiceUnavailable, "Sesi tidak dapat dicabut saat ini", nil)
			return
		}
	}
	utils.JSONResponse(w, http.StatusOK, "Logout berhasil", nil)
}

// @Summary Ganti password
// @Description Mengganti password dengan verifikasi password lama
// @Tags Auth
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body ChangePasswordInput true "Password lama dan baru"
// @Success 200 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Router /change-password [post]
func (h *AuthHandler) ChangePassword(w http.ResponseWriter, r *http.Request) {
	userID, ok := r.Context().Value(middlewares.UserIDKey).(uint)
	if !ok {
		utils.JSONResponse(w, http.StatusUnauthorized, "Gagal mengambil data user dari token", nil)
		return
	}
	var input ChangePasswordInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}
	if err := utils.Validate.Struct(input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, utils.FormatValidationError(err), nil)
		return
	}
	var user models.User
	if err := h.DB.First(&user, userID).Error; err != nil {
		utils.JSONResponse(w, http.StatusNotFound, "User tidak ditemukan", nil)
		return
	}
	if bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(input.OldPassword)) != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Password lama tidak sesuai", nil)
		return
	}
	hashed, err := bcrypt.GenerateFromPassword([]byte(input.NewPassword), bcrypt.DefaultCost)
	if err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengenkripsi password", nil)
		return
	}
	if err := h.DB.Model(&user).Update("password", string(hashed)).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menyimpan password", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Password berhasil diubah", nil)
}

// @Summary Perbarui profil sendiri
// @Description Mengubah data profil akun yang sedang login
// @Tags Auth
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body UpdateProfileInput true "Data profil"
// @Success 200 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Router /users/me [put]
func (h *AuthHandler) UpdateProfile(w http.ResponseWriter, r *http.Request) {
	userID, ok := r.Context().Value(middlewares.UserIDKey).(uint)
	if !ok {
		utils.JSONResponse(w, http.StatusUnauthorized, "Gagal mengambil data user dari token", nil)
		return
	}
	var input UpdateProfileInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}
	if err := utils.Validate.Struct(input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, utils.FormatValidationError(err), nil)
		return
	}
	input.Email = strings.ToLower(strings.TrimSpace(input.Email))
	var user models.User
	if err := h.DB.First(&user, userID).Error; err != nil {
		utils.JSONResponse(w, http.StatusNotFound, "User tidak ditemukan", nil)
		return
	}
	var duplicate models.User
	if err := h.DB.Where("email = ? AND id <> ?", input.Email, userID).First(&duplicate).Error; err == nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Email sudah digunakan akun lain", nil)
		return
	}
	user.Name = strings.TrimSpace(input.Name)
	user.Email = input.Email
	if err := h.DB.Save(&user).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menyimpan profil", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Profil berhasil disimpan", user)
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
	if err := h.DB.Where("email = ?", strings.ToLower(strings.TrimSpace(input.Email))).First(&user).Error; err != nil {
		utils.JSONResponse(w, http.StatusOK, "Jika email terdaftar, instruksi reset password telah dikirim", nil)
		return
	}

	rawToken := make([]byte, 16)
	if _, err := rand.Read(rawToken); err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal membuat token reset", nil)
		return
	}
	token := hex.EncodeToString(rawToken)
	user.ResetToken = token
	user.ResetTokenExpiry = time.Now().Add(15 * time.Minute)
	if err := h.DB.Save(&user).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menyimpan token reset", nil)
		return
	}

	subject := "EduTrack Campus - Reset Password"
	body := fmt.Sprintf("Halo %s,\n\nAnda meminta untuk mereset password akun EduTrack Campus Anda.\n\nBerikut adalah token reset password Anda:\n\n%s\n\nToken ini hanya berlaku selama 15 menit. Jangan bagikan token ini kepada siapa pun.\n\nJika Anda tidak merasa meminta reset password, abaikan email ini.\n\nSalam,\nTim EduTrack Campus", user.Name, token)

	if err := utils.SendEmail(user.Email, subject, body); err != nil {
		user.ResetToken = ""
		user.ResetTokenExpiry = time.Time{}
		_ = h.DB.Save(&user)
		utils.JSONResponse(w, http.StatusServiceUnavailable, "Gagal mengirim instruksi reset. Coba lagi nanti", nil)
		return
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
	if err := h.DB.Where("email = ?", strings.ToLower(strings.TrimSpace(input.Email))).First(&user).Error; err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Email atau token tidak valid", nil)
		return
	}

	if user.ResetToken == "" || user.ResetToken != strings.TrimSpace(input.Token) || time.Now().After(user.ResetTokenExpiry) {
		utils.JSONResponse(w, http.StatusBadRequest, "Token tidak valid atau sudah kedaluwarsa", nil)
		return
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(input.NewPassword), bcrypt.DefaultCost)
	if err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengenkripsi password", nil)
		return
	}

	user.Password = string(hashedPassword)
	user.ResetToken = ""
	user.ResetTokenExpiry = time.Time{}
	if err := h.DB.Save(&user).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menyimpan password", nil)
		return
	}

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
