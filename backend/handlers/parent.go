package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/raihanmuzaffar/edu-track-campus/backend/config"
	"github.com/raihanmuzaffar/edu-track-campus/backend/middlewares"
	"github.com/raihanmuzaffar/edu-track-campus/backend/models"
	"github.com/raihanmuzaffar/edu-track-campus/backend/utils"
	"gorm.io/gorm"
)

type ParentHandler struct {
	DB *gorm.DB
}

type LinkInput struct {
	ParentID  uint `json:"parent_id" validate:"required,gt=0"`
	StudentID uint `json:"student_id" validate:"required,gt=0"`
}

func (h *ParentHandler) children(parentID uint) ([]models.User, error) {
	var students []models.User
	err := h.DB.Joins("JOIN parent_students ps ON ps.student_id = users.id").
		Where("ps.parent_id = ? AND users.role = ?", parentID, "mahasiswa").Find(&students).Error
	return students, err
}

func (h *ParentHandler) resolveChild(parentID uint, r *http.Request) (uint, bool) {
	students, err := h.children(parentID)
	if err != nil || len(students) == 0 {
		return 0, false
	}
	raw := r.URL.Query().Get("child_id")
	if raw == "" {
		return students[0].ID, true
	}
	childID, parseErr := strconv.ParseUint(raw, 10, 64)
	if parseErr != nil || childID == 0 {
		return 0, false
	}
	for _, student := range students {
		if student.ID == uint(childID) {
			return student.ID, true
		}
	}
	return 0, false
}

func parentIDFromContext(r *http.Request) (uint, bool) {
	id, ok := r.Context().Value(middlewares.UserIDKey).(uint)
	return id, ok && id > 0
}

// @Summary Hubungkan Orang Tua ke Anak (Admin)
// @Description Admin menghubungkan akun orang tua dengan akun mahasiswa
// @Tags Parent
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body LinkInput true "ID Parent & Student"
// @Success 201 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /admin/parents/link [post]
func (h *ParentHandler) LinkParent(w http.ResponseWriter, r *http.Request) {
	var input LinkInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}
	if err := utils.Validate.Struct(input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, utils.FormatValidationError(err), nil)
		return
	}

	var parent, student models.User
	if err := h.DB.First(&parent, input.ParentID).Error; err != nil || parent.Role != "orangtua" {
		utils.JSONResponse(w, http.StatusBadRequest, "ID Orang Tua tidak valid atau role bukan 'orangtua'", nil)
		return
	}
	if err := h.DB.First(&student, input.StudentID).Error; err != nil || student.Role != "mahasiswa" {
		utils.JSONResponse(w, http.StatusBadRequest, "ID Mahasiswa tidak valid atau role bukan 'mahasiswa'", nil)
		return
	}

	relation := models.ParentStudent{ParentID: input.ParentID, StudentID: input.StudentID}
	if err := h.DB.Create(&relation).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menghubungkan (mungkin sudah terhubung)", nil)
		return
	}
	utils.JSONResponse(w, http.StatusCreated, "Berhasil menghubungkan Orang Tua dan Mahasiswa", relation)
}

// @Summary Daftar anak orang tua
// @Description Mengembalikan semua mahasiswa yang valid terhubung ke akun orang tua
// @Tags Parent
// @Produce json
// @Security BearerAuth
// @Success 200 {object} utils.Response
// @Router /parent/children [get]
func (h *ParentHandler) GetChildren(w http.ResponseWriter, r *http.Request) {
	parentID, ok := parentIDFromContext(r)
	if !ok {
		utils.JSONResponse(w, http.StatusUnauthorized, "Gagal mengambil data user", nil)
		return
	}
	students, err := h.children(parentID)
	if err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil daftar anak", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil daftar anak", students)
}

// @Summary Profil anak orang tua
// @Tags Parent
// @Produce json
// @Security BearerAuth
// @Param child_id query int false "ID anak"
// @Success 200 {object} utils.Response
// @Router /parent/child/profile [get]
func (h *ParentHandler) GetChildProfile(w http.ResponseWriter, r *http.Request) {
	parentID, ok := parentIDFromContext(r)
	if !ok {
		utils.JSONResponse(w, http.StatusUnauthorized, "Gagal mengambil data user", nil)
		return
	}
	childID, valid := h.resolveChild(parentID, r)
	if !valid {
		utils.JSONResponse(w, http.StatusNotFound, "Data anak tidak ditemukan untuk akun ini", nil)
		return
	}
	var student models.User
	if err := h.DB.First(&student, childID).Error; err != nil {
		utils.JSONResponse(w, http.StatusNotFound, "Data anak tidak ditemukan", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil profil anak", student)
}

// @Summary Lihat Nilai Anak (Orang Tua)
// @Description Orang tua melihat daftar nilai dari anak yang sudah dihubungkan
// @Tags Parent
// @Produce json
// @Security BearerAuth
// @Param child_id query int false "ID anak"
// @Success 200 {object} utils.Response
// @Failure 404 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /parent/child/grades [get]
func (h *ParentHandler) GetChildGrades(w http.ResponseWriter, r *http.Request) {
	parentID, _ := r.Context().Value(middlewares.UserIDKey).(uint)
	childID, valid := h.resolveChild(parentID, r)
	if !valid {
		utils.JSONResponse(w, http.StatusNotFound, "Data anak tidak ditemukan untuk akun ini", nil)
		return
	}
	var grades []models.Grade
	err := h.DB.Preload("Class.Course").Where("mahasiswa_id = ?", childID).Find(&grades).Error
	if err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil nilai anak", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil nilai anak", grades)
}

// @Summary Lihat Absensi Anak (Orang Tua)
// @Description Orang tua melihat rekap kehadiran dari anak yang sudah dihubungkan
// @Tags Parent
// @Produce json
// @Security BearerAuth
// @Param child_id query int false "ID anak"
// @Success 200 {object} utils.Response
// @Failure 404 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /parent/child/attendances [get]
func (h *ParentHandler) GetChildAttendance(w http.ResponseWriter, r *http.Request) {
	parentID, _ := r.Context().Value(middlewares.UserIDKey).(uint)
	childID, valid := h.resolveChild(parentID, r)
	if !valid {
		utils.JSONResponse(w, http.StatusNotFound, "Data anak tidak ditemukan untuk akun ini", nil)
		return
	}
	var attendances []models.Attendance
	err := h.DB.Preload("Class.Course").Where("mahasiswa_id = ?", childID).Find(&attendances).Error
	if err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil absensi anak", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil absensi anak", attendances)
}

// @Summary Ringkasan akademik anak
// @Tags Parent
// @Produce json
// @Security BearerAuth
// @Param child_id query int false "ID anak"
// @Success 200 {object} utils.Response
// @Router /parent/child/summary [get]
func (h *ParentHandler) GetChildSummary(w http.ResponseWriter, r *http.Request) {
	parentID, ok := parentIDFromContext(r)
	if !ok {
		utils.JSONResponse(w, http.StatusUnauthorized, "Gagal mengambil data user", nil)
		return
	}
	childID, valid := h.resolveChild(parentID, r)
	if !valid {
		utils.JSONResponse(w, http.StatusNotFound, "Data anak tidak ditemukan untuk akun ini", nil)
		return
	}
	summary, err := BuildAcademicSummary(h.DB, childID)
	if err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menyusun ringkasan anak", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil ringkasan anak", summary)
}

// @Summary Jadwal anak orang tua
// @Tags Parent
// @Produce json
// @Security BearerAuth
// @Param child_id query int false "ID anak"
// @Success 200 {object} utils.Response
// @Router /parent/child/schedules [get]
func (h *ParentHandler) GetChildSchedule(w http.ResponseWriter, r *http.Request) {
	parentID, ok := parentIDFromContext(r)
	if !ok {
		utils.JSONResponse(w, http.StatusUnauthorized, "Gagal mengambil data user", nil)
		return
	}
	childID, valid := h.resolveChild(parentID, r)
	if !valid {
		utils.JSONResponse(w, http.StatusNotFound, "Data anak tidak ditemukan untuk akun ini", nil)
		return
	}
	period := config.AcademicPeriodNow()
	var enrollments []models.Enrollment
	err := activeEnrollmentFilter(h.DB.Preload("Class.Course").Preload("Class.Dosen")).
		Where("mahasiswa_id = ?", childID).Find(&enrollments).Error
	if err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil jadwal anak", nil)
		return
	}
	result := make([]map[string]interface{}, 0)
	for _, enrollment := range enrollments {
		class := enrollment.Class
		if class.Year != period.Year || class.Semester != period.Semester {
			continue
		}
		result = append(result, map[string]interface{}{
			"id": class.ID, "course": class.Course.Name, "code": class.Course.Code,
			"day": class.Day, "start_time": class.StartTime, "end_time": class.EndTime,
			"room": class.Room, "lecturer": class.Dosen.Name,
		})
	}
	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil jadwal anak", result)
}

// @Summary UKT anak orang tua
// @Tags Parent
// @Produce json
// @Security BearerAuth
// @Param child_id query int false "ID anak"
// @Success 200 {object} utils.Response
// @Router /parent/child/ukt [get]
func (h *ParentHandler) GetChildUKT(w http.ResponseWriter, r *http.Request) {
	parentID, ok := parentIDFromContext(r)
	if !ok {
		utils.JSONResponse(w, http.StatusUnauthorized, "Gagal mengambil data user", nil)
		return
	}
	childID, valid := h.resolveChild(parentID, r)
	if !valid {
		utils.JSONResponse(w, http.StatusNotFound, "Data anak tidak ditemukan untuk akun ini", nil)
		return
	}
	period := config.AcademicPeriodNow()
	var records []models.UKT
	if err := h.DB.Where("student_id = ? AND semester = ?", childID, period.Year).Find(&records).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil UKT anak", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil UKT anak", records)
}

// @Summary Pengumuman untuk orang tua
// @Tags Parent
// @Produce json
// @Security BearerAuth
// @Success 200 {object} utils.Response
// @Router /parent/announcements [get]
func (h *ParentHandler) GetAnnouncements(w http.ResponseWriter, r *http.Request) {
	var announcements []models.Announcement
	now := time.Now()
	if err := h.DB.Where(
		"status = ? AND start_date <= ? AND end_date >= ?",
		"Aktif",
		now,
		now,
	).Order("created_at DESC").Find(&announcements).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil pengumuman", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil pengumuman", announcements)
}

// @Summary Dokumen anak orang tua
// @Tags Parent
// @Produce json
// @Security BearerAuth
// @Param child_id query int false "ID anak"
// @Success 200 {object} utils.Response
// @Router /parent/child/documents [get]
func (h *ParentHandler) GetChildDocuments(w http.ResponseWriter, r *http.Request) {
	parentID, ok := parentIDFromContext(r)
	if !ok {
		utils.JSONResponse(w, http.StatusUnauthorized, "Gagal mengambil data user", nil)
		return
	}
	childID, valid := h.resolveChild(parentID, r)
	if !valid {
		utils.JSONResponse(w, http.StatusNotFound, "Data anak tidak ditemukan untuk akun ini", nil)
		return
	}
	var documents []models.Document
	if err := h.DB.Where("student_id = ?", childID).Order("date DESC").Find(&documents).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil dokumen anak", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil dokumen anak", documents)
}
