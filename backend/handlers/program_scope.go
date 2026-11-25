package handlers

import (
	"errors"
	"net/http"
	"strings"

	"github.com/raihanmuzaffar/edu-track-campus/backend/middlewares"
	"github.com/raihanmuzaffar/edu-track-campus/backend/models"
	"github.com/raihanmuzaffar/edu-track-campus/backend/utils"
	"gorm.io/gorm"
)

func currentProgramScope(w http.ResponseWriter, r *http.Request, db *gorm.DB) (string, bool) {
	role, _ := r.Context().Value(middlewares.RoleKey).(string)
	if role == "admin" {
		return "", true
	}
	if role != "kaprodi" {
		utils.JSONResponse(w, http.StatusForbidden, "Anda tidak memiliki akses untuk sumber daya ini", nil)
		return "", false
	}

	userID, ok := r.Context().Value(middlewares.UserIDKey).(uint)
	if !ok || userID == 0 {
		utils.JSONResponse(w, http.StatusUnauthorized, "Gagal mengambil identitas Kaprodi", nil)
		return "", false
	}

	var actor models.User
	err := db.Select("id", "role", "program_studi").
		Where("id = ? AND role = ?", userID, "kaprodi").
		First(&actor).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		utils.JSONResponse(w, http.StatusForbidden, "Penugasan program studi tidak valid", nil)
		return "", false
	}
	if err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal memverifikasi penugasan program studi", nil)
		return "", false
	}

	scope := strings.TrimSpace(actor.ProgramStudi)
	if scope == "" {
		utils.JSONResponse(w, http.StatusForbidden, "Penugasan program studi tidak tersedia", nil)
		return "", false
	}
	return scope, true
}

func scopedStudentRecords(query *gorm.DB, association, program string) *gorm.DB {
	alias := `"` + association + `"`
	return query.
		Joins(association).
		Where(alias+".role = ? AND TRIM("+alias+".program_studi) = ?", "mahasiswa", program)
}

func studentBelongsToProgram(db *gorm.DB, studentID uint, program string) (bool, error) {
	var count int64
	err := db.Model(&models.User{}).
		Where("id = ? AND role = ? AND TRIM(program_studi) = ?", studentID, "mahasiswa", program).
		Count(&count).Error
	return count == 1, err
}
