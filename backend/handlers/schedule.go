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
	Semester  string `json:"semester"`
	ClassID   uint   `json:"class_id"`
	CourseID  uint   `json:"course_id"`
	TeacherID uint   `json:"teacher_id"`
	Day       string `json:"day"`
	StartTime string `json:"start_time"`
	EndTime   string `json:"end_time"`
	Room      string `json:"room"`
}

// CreateSchedule creates a new schedule
func (h *ScheduleHandler) CreateSchedule(w http.ResponseWriter, r *http.Request) {
	var input ScheduleInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}

	schedule := models.Schedule{
		Semester:  input.Semester,
		ClassID:   input.ClassID,
		CourseID:  input.CourseID,
		TeacherID: input.TeacherID,
		Day:       input.Day,
		StartTime: input.StartTime,
		EndTime:   input.EndTime,
		Room:      input.Room,
	}

	if err := h.DB.Create(&schedule).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal membuat jadwal", nil)
		return
	}

	utils.JSONResponse(w, http.StatusCreated, "Jadwal berhasil dibuat", schedule)
}

// GetAllSchedules retrieves all schedules with pagination and preloads
func (h *ScheduleHandler) GetAllSchedules(w http.ResponseWriter, r *http.Request) {
	var schedules []models.Schedule

	limit, offset := utils.GetPagination(r)

	query := h.DB.Model(&models.Schedule{}).Preload("Class").Preload("Course").Preload("Teacher")

	var total int64
	query.Count(&total)

	if err := query.Limit(limit).Offset(offset).Find(&schedules).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil data jadwal", nil)
		return
	}

	response := map[string]interface{}{
		"data":       schedules,
		"total_data": total,
		"page":       (offset / limit) + 1,
		"limit":      limit,
	}

	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil data jadwal", response)
}

// UpdateSchedule updates an existing schedule
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

// DeleteSchedule deletes a schedule
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
