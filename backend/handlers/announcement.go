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
	Title     string `json:"title" validate:"required"`
	Category  string `json:"category" validate:"required"`
	Content   string `json:"content" validate:"required"`
	StartDate string `json:"start_date" validate:"required"` // Format: YYYY-MM-DD
	EndDate   string `json:"end_date" validate:"required"`   // Format: YYYY-MM-DD
	Status    string `json:"status" validate:"required,oneof=Draf Aktif Berakhir"`
}

// @Summary Tambah Pengumuman (Admin/Kaprodi)
// @Description Menambahkan pengumuman baru
// @Tags Announcements
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body AnnouncementInput true "Data Pengumuman"
// @Success 201 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Router /admin/announcements [post]
func (h *AnnouncementHandler) CreateAnnouncement(w http.ResponseWriter, r *http.Request) {
	var input AnnouncementInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, "Format JSON tidak valid", nil)
		return
	}
	if err := utils.Validate.Struct(input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, utils.FormatValidationError(err), nil)
		return
	}

	startDate, _ := time.Parse("2006-01-02", input.StartDate)
	endDate, _ := time.Parse("2006-01-02", input.EndDate)

	announcement := models.Announcement{
		Title: input.Title, Category: input.Category, Content: input.Content,
		StartDate: startDate, EndDate: endDate, Status: input.Status,
	}
	if err := h.DB.Create(&announcement).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menyimpan pengumuman", nil)
		return
	}
	utils.JSONResponse(w, http.StatusCreated, "Pengumuman berhasil dibuat", announcement)
}

// @Summary Lihat Semua Pengumuman
// @Description Mendapatkan daftar pengumuman
// @Tags Announcements
// @Produce json
// @Security BearerAuth
// @Success 200 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /admin/announcements/list [get]
func (h *AnnouncementHandler) GetAllAnnouncements(w http.ResponseWriter, r *http.Request) {
	var announcements []models.Announcement
	if err := h.DB.Find(&announcements).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil data pengumuman", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil data pengumuman", announcements)
}

// @Summary Update Pengumuman (Admin/Kaprodi)
// @Description Mengubah data pengumuman berdasarkan ID
// @Tags Announcements
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id query int true "ID Pengumuman"
// @Param request body AnnouncementInput true "Data Update"
// @Success 200 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Failure 404 {object} utils.Response
// @Router /admin/announcements/update [put]
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
	if err := utils.Validate.Struct(input); err != nil {
		utils.JSONResponse(w, http.StatusBadRequest, utils.FormatValidationError(err), nil)
		return
	}

	var announcement models.Announcement
	if err := h.DB.First(&announcement, idStr).Error; err != nil {
		utils.JSONResponse(w, http.StatusNotFound, "Pengumuman tidak ditemukan", nil)
		return
	}

	startDate, _ := time.Parse("2006-01-02", input.StartDate)
	endDate, _ := time.Parse("2006-01-02", input.EndDate)

	announcement.Title = input.Title
	announcement.Category = input.Category
	announcement.Content = input.Content
	announcement.StartDate = startDate
	announcement.EndDate = endDate
	announcement.Status = input.Status

	if err := h.DB.Save(&announcement).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengupdate pengumuman", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Pengumuman berhasil diupdate", announcement)
}

// @Summary Hapus Pengumuman (Admin/Kaprodi)
// @Description Menghapus pengumuman berdasarkan ID
// @Tags Announcements
// @Produce json
// @Security BearerAuth
// @Param id query int true "ID Pengumuman"
// @Success 200 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /admin/announcements/delete [delete]
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