package handlers

import (
	"encoding/json"
	"net/http"
	"strings"

	"github.com/raihanmuzaffar/edu-track-campus/backend/middlewares"
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
	counts := []struct {
		query *gorm.DB
		total *int64
	}{
		{h.DB.Model(&models.User{}).Where("role = ?", "mahasiswa"), &totalMahasiswa},
		{h.DB.Model(&models.User{}).Where("role = ?", "dosen"), &totalDosen},
		{h.DB.Model(&models.Course{}), &totalCourses},
		{h.DB.Model(&models.Class{}), &totalClasses},
	}
	for _, count := range counts {
		if utils.RespondQueryError(w, count.query.Count(count.total).Error, "Gagal mengambil statistik dashboard") {
			return
		}
	}

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
	actorRole, _ := r.Context().Value(middlewares.RoleKey).(string)
	programScope, ok := currentProgramScope(w, r, h.DB)
	if !ok {
		return
	}
	limit, offset, err := utils.GetPagination(r)
	if err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, err.Error(), nil)
		return
	}
	search := r.URL.Query().Get("search")

	query := h.DB.Model(&models.User{})
	if actorRole == "kaprodi" {
		query = query.Where("TRIM(program_studi) = ? AND role IN ?", programScope, []string{"mahasiswa", "dosen"})
	}
	if search != "" {
		query = query.Where("(name ILIKE ? OR email ILIKE ?)", "%"+search+"%", "%"+search+"%")
	}

	var total int64
	if utils.RespondQueryError(w, query.Count(&total).Error, "Gagal menghitung data user") {
		return
	}

	if utils.RespondQueryError(w, query.Limit(limit).Offset(offset).Find(&users).Error, "Gagal mengambil data user") {
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
	Name         string  `json:"name" validate:"required,min=3"`
	Email        string  `json:"email" validate:"required,email"`
	Password     string  `json:"password" validate:"omitempty,min=8"`
	Role         string  `json:"role" validate:"required,oneof=admin kaprodi dosen mahasiswa orangtua"`
	NIM          *string `json:"nim"`
	NIDN         *string `json:"nidn"`
	NIP          *string `json:"nip"`
	ProgramStudi *string `json:"program_studi"`
}

func inputString(value *string) string {
	if value == nil {
		return ""
	}
	return *value
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
	actorRole, _ := r.Context().Value(middlewares.RoleKey).(string)
	if !utils.CanManageUserRole(actorRole, input.Role) {
		utils.JSONResponse(w, http.StatusForbidden, "Hanya admin yang dapat membuat akun admin atau kaprodi", nil)
		return
	}
	programScope := ""
	if actorRole == "kaprodi" {
		var ok bool
		programScope, ok = currentProgramScope(w, r, h.DB)
		if !ok {
			return
		}
		if input.Role != "mahasiswa" && input.Role != "dosen" {
			utils.JSONResponse(w, http.StatusForbidden, "Kaprodi hanya dapat mengelola akun mahasiswa atau dosen dalam prodi yang ditugaskan", nil)
			return
		}
		if input.ProgramStudi != nil && strings.TrimSpace(*input.ProgramStudi) != "" &&
			!utils.ProgramScopeMatches(actorRole, programScope, *input.ProgramStudi) {
			utils.JSONResponse(w, http.StatusForbidden, "Akun harus berada dalam prodi yang ditugaskan", nil)
			return
		}
	}

	if len(input.Password) < 8 {
		utils.JSONResponse(w, http.StatusBadRequest, "Password minimal 8 karakter", nil)
		return
	}
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(input.Password), bcrypt.DefaultCost)
	if err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengenkripsi password", nil)
		return
	}

	user := models.User{
		Name:         input.Name,
		Email:        input.Email,
		Password:     string(hashedPassword),
		Role:         input.Role,
		NIM:          inputString(input.NIM),
		NIDN:         inputString(input.NIDN),
		NIP:          inputString(input.NIP),
		ProgramStudi: inputString(input.ProgramStudi),
	}
	if actorRole == "kaprodi" {
		user.ProgramStudi = programScope
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

	actorRole, _ := r.Context().Value(middlewares.RoleKey).(string)
	programScope, ok := currentProgramScope(w, r, h.DB)
	if !ok {
		return
	}
	var user models.User
	query := h.DB
	if actorRole == "kaprodi" {
		query = query.Where("TRIM(program_studi) = ? AND role IN ?", programScope, []string{"mahasiswa", "dosen"})
	}
	if err := query.First(&user, id).Error; err != nil {
		utils.JSONResponse(w, http.StatusNotFound, "User tidak ditemukan", nil)
		return
	}
	if !utils.CanManageUserRole(actorRole, user.Role) || !utils.CanManageUserRole(actorRole, input.Role) {
		utils.JSONResponse(w, http.StatusForbidden, "Hanya admin yang dapat mengubah akun admin atau kaprodi", nil)
		return
	}
	if actorRole == "kaprodi" {
		if input.Role != user.Role {
			utils.JSONResponse(w, http.StatusForbidden, "Kaprodi tidak dapat mengubah role akun", nil)
			return
		}
		if input.ProgramStudi != nil && strings.TrimSpace(*input.ProgramStudi) != "" &&
			!utils.ProgramScopeMatches(actorRole, programScope, *input.ProgramStudi) {
			utils.JSONResponse(w, http.StatusForbidden, "Akun harus tetap berada dalam prodi yang ditugaskan", nil)
			return
		}
	}

	user.Name = input.Name
	user.Email = input.Email
	user.Role = input.Role
	if input.NIM != nil {
		user.NIM = *input.NIM
	}
	if input.NIDN != nil {
		user.NIDN = *input.NIDN
	}
	if input.NIP != nil {
		user.NIP = *input.NIP
	}
	if input.ProgramStudi != nil {
		user.ProgramStudi = *input.ProgramStudi
	}
	if actorRole == "kaprodi" {
		user.ProgramStudi = programScope
	}
	if input.Password != "" {
		hashedPassword, err := bcrypt.GenerateFromPassword([]byte(input.Password), bcrypt.DefaultCost)
		if err != nil {
			utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengenkripsi password", nil)
			return
		}
		user.Password = string(hashedPassword)
	}

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
	actorRole, _ := r.Context().Value(middlewares.RoleKey).(string)
	programScope, ok := currentProgramScope(w, r, h.DB)
	if !ok {
		return
	}
	var user models.User
	query := h.DB
	if actorRole == "kaprodi" {
		query = query.Where("TRIM(program_studi) = ? AND role IN ?", programScope, []string{"mahasiswa", "dosen"})
	}
	if err := query.First(&user, id).Error; err != nil {
		utils.JSONResponse(w, http.StatusNotFound, "User tidak ditemukan", nil)
		return
	}
	if !utils.CanManageUserRole(actorRole, user.Role) {
		utils.JSONResponse(w, http.StatusForbidden, "Hanya admin yang dapat menghapus akun admin atau kaprodi", nil)
		return
	}
	result := h.DB.Delete(&user)
	if result.Error != nil {
		if utils.IsForeignKeyViolation(result.Error) {
			utils.JSONResponse(w, http.StatusConflict, "User masih digunakan oleh data akademik", nil)
			return
		}
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menghapus user", nil)
		return
	}
	if result.RowsAffected == 0 {
		utils.JSONResponse(w, http.StatusNotFound, "User tidak ditemukan", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "User berhasil dihapus", nil)
}
