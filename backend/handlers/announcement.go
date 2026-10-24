package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/raihanmuzaffar/edu-track-campus/backend/models"
	"github.com/raihanmuzaffar/edu-track-campus/backend/utils"
	"gorm.io/gorm"
)

type AnnouncementHandler struct {
	DB *gorm.DB
}

type AnnouncementInput struct {
	Title     string `json:"title"`
	Category  string `json:"category"`
	Content   string `json:"content"`
	StartDate string `json:"start_date"`
	EndDate   string `json:"end_date"`
	Status    string `json:"status"`
}

// CreateAnnouncement creates a new announcement
func (h *AnnouncementHandler) CreateAnnouncement(w http.ResponseWriter, r *http.Request) {
	var input AnnouncementInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}

	var startDate, endDate time.Time
	if input.StartDate != "" {
		parsedTime, err := time.Parse(time.RFC3339, input.StartDate)
		if err != nil {
			utils.JSONResponse(w, http.StatusBadRequest, "Format start_date tidak valid, gunakan RFC3339", nil)
			return
		}
		startDate = parsedTime
	}

	if input.EndDate != "" {
		parsedTime, err := time.Parse(time.RFC3339, input.EndDate)
		if err != nil {
			utils.JSONResponse(w, http.StatusBadRequest, "Format end_date tidak valid, gunakan RFC3339", nil)
			return
		}
		endDate = parsedTime
	}

	announcement := models.Announcement{
		Title:     input.Title,
		Category:  input.Category,
		Content:   input.Content,
		StartDate: startDate,
		EndDate:   endDate,
		Status:    input.Status,
	}

	if err := h.DB.Create(&announcement).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal membuat pengumuman", nil)
		return
	}

	utils.JSONResponse(w, http.StatusCreated, "Pengumuman berhasil dibuat", announcement)
}

// GetAllAnnouncements retrieves all announcements with pagination
func (h *AnnouncementHandler) GetAllAnnouncements(w http.ResponseWriter, r *http.Request) {
	var announcements []models.Announcement

	limit, offset := utils.GetPagination(r)

	query := h.DB.Model(&models.Announcement{})

	var total int64
	query.Count(&total)

	if err := query.Limit(limit).Offset(offset).Find(&announcements).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil data pengumuman", nil)
		return
	}

	response := map[string]interface{}{
		"data":       announcements,
		"total_data": total,
		"page":       (offset / limit) + 1,
		"limit":      limit,
	}

	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil data pengumuman", response)
}

// UpdateAnnouncement updates an existing announcement
func (h *AnnouncementHandler) UpdateAnnouncement(w http.ResponseWriter, r *http.Request) {
	idStr := r.URL.Query().Get("id")
	if idStr == "" {
		utils.JSONResponse(w, http.StatusBadRequest, "ID pengumuman harus diisi di URL", nil)
		return
	}

	var input AnnouncementInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}

	var announcement models.Announcement
	if err := h.DB.First(&announcement, idStr).Error; err != nil {
		utils.JSONResponse(w, http.StatusNotFound, "Pengumuman tidak ditemukan", nil)
		return
	}

	if input.StartDate != "" {
		parsedTime, err := time.Parse(time.RFC3339, input.StartDate)
		if err != nil {
			utils.JSONResponse(w, http.StatusBadRequest, "Format start_date tidak valid, gunakan RFC3339", nil)
			return
		}
		announcement.StartDate = parsedTime
	}

	if input.EndDate != "" {
		parsedTime, err := time.Parse(time.RFC3339, input.EndDate)
		if err != nil {
			utils.JSONResponse(w, http.StatusBadRequest, "Format end_date tidak valid, gunakan RFC3339", nil)
			return
		}
		announcement.EndDate = parsedTime
	}

	announcement.Title = input.Title
	announcement.Category = input.Category
	announcement.Content = input.Content
	announcement.Status = input.Status

	if err := h.DB.Save(&announcement).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengupdate pengumuman", nil)
		return
	}

	utils.JSONResponse(w, http.StatusOK, "Pengumuman berhasil diupdate", announcement)
}

// DeleteAnnouncement deletes an announcement
func (h *AnnouncementHandler) DeleteAnnouncement(w http.ResponseWriter, r *http.Request) {
	idStr := r.URL.Query().Get("id")
	if idStr == "" {
		utils.JSONResponse(w, http.StatusBadRequest, "ID pengumuman harus diisi di URL", nil)
		return
	}

	if err := h.DB.Delete(&models.Announcement{}, idStr).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menghapus pengumuman", nil)
		return
	}

	utils.JSONResponse(w, http.StatusOK, "Pengumuman berhasil dihapus", nil)
}
