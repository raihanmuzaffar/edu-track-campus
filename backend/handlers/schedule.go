package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/raihanmuzaffar/edu-track-campus/backend/models"
	"github.com/raihanmuzaffar/edu-track-campus/backend/utils"
	"gorm.io/gorm"
)

type ScheduleHandler struct {
	DB *gorm.DB
}

type ScheduleInput struct {
	Semester  string `json:"semester" validate:"required"`
	ClassID   uint   `json:"class_id" validate:"required,gt=0"`
	CourseID  uint   `json:"course_id" validate:"required,gt=0"`
	TeacherID uint   `json:"teacher_id" validate:"required,gt=0"`
	Day       string `json:"day" validate:"required,oneof=Senin Selasa Rabu Kamis Jumat Sabtu"`
	StartTime string `json:"start_time" validate:"required"`
	EndTime   string `json:"end_time" validate:"required"`
	Room      string `json:"room" validate:"required"`
}

// @Summary Tambah Jadwal (Admin)
// @Description Admin membuat jadwal kuliah baru
// @Tags Schedules
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body ScheduleInput true "Data Jadwal"
// @Success 201 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Router /admin/schedules [post]
func (h *ScheduleHandler) CreateSchedule(w http.ResponseWriter, r *http.Request) {
	var input ScheduleInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}
	if err := utils.Validate.Struct(input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, utils.FormatValidationError(err), nil)
		return
	}

	schedule := models.Schedule{
		Semester: input.Semester, ClassID: input.ClassID, CourseID: input.CourseID,
		TeacherID: input.TeacherID, Day: input.Day, StartTime: input.StartTime,
		EndTime: input.EndTime, Room: input.Room,
	}
	if err := h.DB.Create(&schedule).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal membuat jadwal", nil)
		return
	}
	utils.JSONResponse(w, http.StatusCreated, "Jadwal berhasil dibuat", schedule)
}

// @Summary Lihat Semua Jadwal
// @Description Mendapatkan daftar jadwal kuliah
// @Tags Schedules
// @Produce json
// @Security BearerAuth
// @Success 200 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /admin/schedules/list [get]
func (h *ScheduleHandler) GetAllSchedules(w http.ResponseWriter, r *http.Request) {
	var schedules []models.Schedule
	err := h.DB.Preload("Class").Preload("Course").Preload("Teacher").Find(&schedules).Error
	if err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil data jadwal", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil data jadwal", schedules)
}

// @Summary Update Jadwal (Admin)
// @Description Mengubah data jadwal berdasarkan ID
// @Tags Schedules
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id query int true "ID Jadwal"
// @Param request body ScheduleInput true "Data Update"
// @Success 200 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Failure 404 {object} utils.Response
// @Router /admin/schedules/update [put]
func (h *ScheduleHandler) UpdateSchedule(w http.ResponseWriter, r *http.Request) {
	idStr := r.URL.Query().Get("id")
	if idStr == "" {
		utils.JSONResponse(w, http.StatusBadRequest, "ID jadwal harus diisi di URL", nil)
		return
	}
	var input ScheduleInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}
	if err := utils.Validate.Struct(input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, utils.FormatValidationError(err), nil)
		return
	}

	var schedule models.Schedule
	if err := h.DB.First(&schedule, idStr).Error; err != nil {
		utils.JSONResponse(w, http.StatusNotFound, "Jadwal tidak ditemukan", nil)
		return
	}

	schedule.Semester = input.Semester
	schedule.ClassID = input.ClassID
	schedule.CourseID = input.CourseID
	schedule.TeacherID = input.TeacherID
	schedule.Day = input.Day
	schedule.StartTime = input.StartTime
	schedule.EndTime = input.EndTime
	schedule.Room = input.Room

	if err := h.DB.Save(&schedule).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengupdate jadwal", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Jadwal berhasil diupdate", schedule)
}

// @Summary Hapus Jadwal (Admin)
// @Description Menghapus jadwal berdasarkan ID
// @Tags Schedules
// @Produce json
// @Security BearerAuth
// @Param id query int true "ID Jadwal"
// @Success 200 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /admin/schedules/delete [delete]
func (h *ScheduleHandler) DeleteSchedule(w http.ResponseWriter, r *http.Request) {
	idStr := r.URL.Query().Get("id")
	if idStr == "" {
		utils.JSONResponse(w, http.StatusBadRequest, "ID jadwal harus diisi di URL", nil)
		return
	}
	if err := h.DB.Delete(&models.Schedule{}, idStr).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menghapus jadwal", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Jadwal berhasil dihapus", nil)
}