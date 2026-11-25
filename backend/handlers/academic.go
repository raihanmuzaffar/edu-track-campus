package handlers

import (
	"math"
	"net/http"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/raihanmuzaffar/edu-track-campus/backend/config"
	"github.com/raihanmuzaffar/edu-track-campus/backend/middlewares"
	"github.com/raihanmuzaffar/edu-track-campus/backend/models"
	"github.com/raihanmuzaffar/edu-track-campus/backend/utils"
	"gorm.io/gorm"
)

type AcademicHandler struct {
	DB *gorm.DB
}

type CourseGrade struct {
	GradeID     uint    `json:"grade_id"`
	ClassID     uint    `json:"class_id"`
	Course      string  `json:"course"`
	Code        string  `json:"code"`
	SKS         int     `json:"sks"`
	Score       float64 `json:"score"`
	Letter      string  `json:"letter"`
	Point       float64 `json:"point"`
	Year        string  `json:"year"`
	Semester    string  `json:"semester"`
	Lecturer    string  `json:"lecturer"`
	ValidPeriod bool    `json:"valid_period"`
}

type SemesterSummary struct {
	Year      string        `json:"year"`
	Semester  string        `json:"semester"`
	SKS       int           `json:"sks"`
	EarnedSKS int           `json:"earned_sks"`
	IPS       float64       `json:"ips"`
	Courses   []CourseGrade `json:"courses"`
}

type AttendanceSummary struct {
	Total      int64   `json:"total"`
	Present    int64   `json:"present"`
	Percentage float64 `json:"percentage"`
}

type UKTSummary struct {
	Billed int64 `json:"billed"`
	Paid   int64 `json:"paid"`
	Debt   int64 `json:"debt"`
}

type AcademicSummary struct {
	StudentID          uint                  `json:"student_id"`
	Name               string                `json:"name"`
	NIM                string                `json:"nim"`
	ProgramStudi       string                `json:"program_studi"`
	Period             config.AcademicPeriod `json:"period"`
	PlannedSKS         int                   `json:"planned_sks"`
	GradedSKS          int                   `json:"graded_sks"`
	EarnedSKS          int                   `json:"earned_sks"`
	IPK                float64               `json:"ipk"`
	IPS                float64               `json:"ips"`
	GradePoints        map[string]float64    `json:"grade_points"`
	DataComplete       bool                  `json:"data_lengkap"`
	MissingPeriodCount int                   `json:"periode_tidak_valid"`
	Semesters          []SemesterSummary     `json:"semesters"`
	Courses            []CourseGrade         `json:"courses"`
	Attendance         AttendanceSummary     `json:"attendance"`
	UKT                UKTSummary            `json:"ukt"`
}

func round2(value float64) float64 {
	return math.Round(value*100) / 100
}

func BuildAcademicSummary(db *gorm.DB, studentID uint) (AcademicSummary, error) {
	summary := AcademicSummary{
		StudentID:   studentID,
		Period:      config.AcademicPeriodNow(),
		GradePoints: config.GradePoints(),
		Semesters:   []SemesterSummary{},
		Courses:     []CourseGrade{},
	}
	var student models.User
	if err := db.First(&student, studentID).Error; err != nil {
		return summary, err
	}
	summary.Name = student.Name
	summary.NIM = student.NIM
	summary.ProgramStudi = student.ProgramStudi

	var enrollments []models.Enrollment
	if err := activeEnrollmentFilter(db.Preload("Class.Course")).Where("mahasiswa_id = ?", studentID).Find(&enrollments).Error; err != nil {
		return summary, err
	}
	for _, enrollment := range enrollments {
		if enrollment.Class.Year != summary.Period.Year || enrollment.Class.Semester != summary.Period.Semester {
			continue
		}
		summary.PlannedSKS += enrollment.Class.Course.SKS
	}

	var grades []models.Grade
	if err := db.Preload("Class.Course").Preload("Class.Dosen").Where("mahasiswa_id = ?", studentID).Find(&grades).Error; err != nil {
		return summary, err
	}
	points := config.GradePoints()
	passing := config.PassingGrades()
	semesterMap := map[string]*SemesterSummary{}
	var weightedTotal float64
	for _, grade := range grades {
		course := grade.Class.Course
		if course.SKS <= 0 {
			continue
		}
		point, known := points[strings.ToUpper(strings.TrimSpace(grade.Letter))]
		if !known {
			point = 0
		}
		validPeriod := strings.TrimSpace(grade.Class.Year) != "" && strings.TrimSpace(grade.Class.Semester) != ""
		if !validPeriod {
			summary.MissingPeriodCount++
		}
		item := CourseGrade{
			GradeID: grade.ID, ClassID: grade.ClassID, Course: course.Name, Code: course.Code,
			SKS: course.SKS, Score: grade.Score, Letter: grade.Letter, Point: point,
			Year: grade.Class.Year, Semester: grade.Class.Semester,
			Lecturer: grade.Class.Dosen.Name, ValidPeriod: validPeriod,
		}
		summary.Courses = append(summary.Courses, item)

		key := grade.Class.Year + "|" + grade.Class.Semester
		bucket, exists := semesterMap[key]
		if !exists {
			bucket = &SemesterSummary{Year: grade.Class.Year, Semester: grade.Class.Semester, Courses: []CourseGrade{}}
			semesterMap[key] = bucket
		}
		bucket.Courses = append(bucket.Courses, item)
		bucket.SKS += course.SKS
		weightedTotal += point * float64(course.SKS)
		summary.GradedSKS += course.SKS
		if passing[strings.ToUpper(strings.TrimSpace(grade.Letter))] {
			summary.EarnedSKS += course.SKS
			bucket.EarnedSKS += course.SKS
		}
	}
	for _, bucket := range semesterMap {
		if bucket.SKS > 0 {
			bucket.IPS = 0
			for _, course := range bucket.Courses {
				bucket.IPS += course.Point * float64(course.SKS)
			}
			bucket.IPS = round2(bucket.IPS / float64(bucket.SKS))
		}
		summary.Semesters = append(summary.Semesters, *bucket)
		for i := range summary.Semesters {
			if summary.Semesters[i].Year == bucket.Year && summary.Semesters[i].Semester == bucket.Semester {
				summary.Semesters[i].IPS = bucket.IPS
			}
		}
	}
	sort.Slice(summary.Semesters, func(i, j int) bool {
		left, right := summary.Semesters[i], summary.Semesters[j]
		return config.AcademicTermBefore(
			left.Year,
			left.Semester,
			right.Year,
			right.Semester,
		)
	})
	if summary.GradedSKS > 0 {
		summary.IPK = round2(weightedTotal / float64(summary.GradedSKS))
	}
	summary.DataComplete = summary.GradedSKS > 0 && summary.MissingPeriodCount == 0
	for _, bucket := range summary.Semesters {
		if bucket.Year == summary.Period.Year && bucket.Semester == summary.Period.Semester {
			summary.IPS = bucket.IPS
			break
		}
	}

	var attendances []models.Attendance
	if err := db.Where("mahasiswa_id = ?", studentID).Find(&attendances).Error; err != nil {
		return summary, err
	}
	summary.Attendance.Total = int64(len(attendances))
	for _, attendance := range attendances {
		if strings.EqualFold(strings.TrimSpace(attendance.Status), "hadir") {
			summary.Attendance.Present++
		}
	}
	if summary.Attendance.Total > 0 {
		summary.Attendance.Percentage = round2(float64(summary.Attendance.Present) / float64(summary.Attendance.Total) * 100)
	}

	var uktRecords []models.UKT
	if err := db.Where("student_id = ? AND semester = ?", studentID, summary.Period.Year).Find(&uktRecords).Error; err != nil {
		return summary, err
	}
	for _, record := range uktRecords {
		summary.UKT.Billed += int64(record.Billed)
		summary.UKT.Paid += int64(record.Paid)
	}
	summary.UKT.Debt = summary.UKT.Billed - summary.UKT.Paid
	if summary.UKT.Debt < 0 {
		summary.UKT.Debt = 0
	}
	return summary, nil
}

func studentIDFromContext(r *http.Request) (uint, bool) {
	id, ok := r.Context().Value(middlewares.UserIDKey).(uint)
	return id, ok && id > 0
}

// @Summary Ringkasan akademik mahasiswa
// @Description IPK berbobot SKS, rekap KRS, nilai, absensi, dan UKT
// @Tags Academic
// @Produce json
// @Security BearerAuth
// @Success 200 {object} utils.Response
// @Router /student/academic/summary [get]
func (h *AcademicHandler) GetMySummary(w http.ResponseWriter, r *http.Request) {
	studentID, ok := studentIDFromContext(r)
	if !ok {
		utils.JSONResponse(w, http.StatusUnauthorized, "Gagal mengambil data user", nil)
		return
	}
	summary, err := BuildAcademicSummary(h.DB, studentID)
	if err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal menyusun ringkasan akademik", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil ringkasan akademik", summary)
}

// @Summary KHS mahasiswa
// @Description Daftar kartu hasil studi per semester
// @Tags Academic
// @Produce json
// @Security BearerAuth
// @Success 200 {object} utils.Response
// @Router /student/khs [get]
func (h *AcademicHandler) GetMyKHS(w http.ResponseWriter, r *http.Request) {
	studentID, ok := studentIDFromContext(r)
	if !ok {
		utils.JSONResponse(w, http.StatusUnauthorized, "Gagal mengambil data user", nil)
		return
	}
	summary, err := BuildAcademicSummary(h.DB, studentID)
	if err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil KHS", nil)
		return
	}
	var records []models.KHSRecord
	if utils.RespondQueryError(w, h.DB.Where("student_id = ?", studentID).Find(&records).Error, "Gagal mengambil status KHS") {
		return
	}
	result := make([]map[string]interface{}, 0, len(summary.Semesters))
	for _, semester := range summary.Semesters {
		status := "Draf"
		for _, record := range records {
			if record.Semester == semester.Year || record.Semester == semester.Semester {
				status = record.Status
				break
			}
		}
		result = append(result, map[string]interface{}{
			"semester": semester.Semester, "year": semester.Year, "sks": semester.SKS,
			"earned_sks": semester.EarnedSKS, "ips": semester.IPS, "status": status,
			"courses": semester.Courses,
		})
	}
	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil KHS", result)
}

// @Summary Transkrip nilai mahasiswa
// @Description Transkrip akademik lengkap berdasarkan data nilai
// @Tags Academic
// @Produce json
// @Security BearerAuth
// @Success 200 {object} utils.Response
// @Router /student/transcript [get]
func (h *AcademicHandler) GetMyTranscript(w http.ResponseWriter, r *http.Request) {
	studentID, ok := studentIDFromContext(r)
	if !ok {
		utils.JSONResponse(w, http.StatusUnauthorized, "Gagal mengambil data user", nil)
		return
	}
	summary, err := BuildAcademicSummary(h.DB, studentID)
	if err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil transkrip", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil transkrip", map[string]interface{}{
		"student_id": summary.StudentID, "name": summary.Name, "nim": summary.NIM,
		"program_studi": summary.ProgramStudi, "ipk": summary.IPK, "total_sks": summary.EarnedSKS,
		"semesters": summary.Semesters, "grade_points": summary.GradePoints,
	})
}

// @Summary Jadwal kuliah saya
// @Description Jadwal mahasiswa berdasarkan KRS aktif pada periode berjalan
// @Tags Academic
// @Produce json
// @Security BearerAuth
// @Success 200 {object} utils.Response
// @Router /schedules/my [get]
func (h *AcademicHandler) GetMySchedule(w http.ResponseWriter, r *http.Request) {
	studentID, ok := studentIDFromContext(r)
	if !ok {
		utils.JSONResponse(w, http.StatusUnauthorized, "Gagal mengambil data user", nil)
		return
	}
	period := config.AcademicPeriodNow()
	var enrollments []models.Enrollment
	err := activeEnrollmentFilter(h.DB.Preload("Class.Course").Preload("Class.Dosen")).
		Where("mahasiswa_id = ?", studentID).Find(&enrollments).Error
	if err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil jadwal", nil)
		return
	}
	result := make([]map[string]interface{}, 0)
	for _, enrollment := range enrollments {
		class := enrollment.Class
		if class.Year != period.Year || class.Semester != period.Semester {
			continue
		}
		result = append(result, map[string]interface{}{
			"id": class.ID, "class_name": class.Name, "course": class.Course.Name,
			"code": class.Course.Code, "sks": class.Course.SKS, "day": class.Day,
			"start_time": class.StartTime, "end_time": class.EndTime, "room": class.Room,
			"lecturer": class.Dosen.Name, "year": class.Year, "semester": class.Semester,
		})
	}
	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil jadwal", result)
}

// @Summary UKT saya
// @Description Tagihan dan pembayaran UKT mahasiswa
// @Tags Academic
// @Produce json
// @Security BearerAuth
// @Success 200 {object} utils.Response
// @Router /student/ukt/my [get]
func (h *AcademicHandler) GetMyUKT(w http.ResponseWriter, r *http.Request) {
	studentID, ok := studentIDFromContext(r)
	if !ok {
		utils.JSONResponse(w, http.StatusUnauthorized, "Gagal mengambil data user", nil)
		return
	}
	period := config.AcademicPeriodNow()
	var records []models.UKT
	if err := h.DB.Where("student_id = ? AND semester = ?", studentID, period.Year).Find(&records).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil data UKT", nil)
		return
	}
	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil data UKT", records)
}

// @Summary Kalender akademik
// @Description Jadwal kuliah dan pengumuman aktif
// @Tags Academic
// @Produce json
// @Security BearerAuth
// @Success 200 {object} utils.Response
// @Router /calendar [get]
func (h *AcademicHandler) GetCalendar(w http.ResponseWriter, r *http.Request) {
	period := config.AcademicPeriodNow()
	events := make([]map[string]interface{}, 0)
	var schedules []models.Schedule
	if err := h.DB.Preload("Course").Preload("Teacher").Where("semester = ?", period.Year).Find(&schedules).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil kalender akademik", nil)
		return
	}
	for _, schedule := range schedules {
		events = append(events, map[string]interface{}{
			"type": "schedule", "title": schedule.Course.Name, "day": schedule.Day,
			"start_time": schedule.StartTime, "end_time": schedule.EndTime,
			"room": schedule.Room, "lecturer": schedule.Teacher.Name,
		})
	}
	var announcements []models.Announcement
	now := time.Now()
	if err := h.DB.Where(
		"status = ? AND start_date <= ? AND end_date >= ?",
		"Aktif",
		now,
		now,
	).Find(&announcements).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil kalender akademik", nil)
		return
	}
	for _, announcement := range announcements {
		events = append(events, map[string]interface{}{
			"type": "announcement", "title": announcement.Title, "category": announcement.Category,
			"start_date": announcement.StartDate, "end_date": announcement.EndDate,
		})
	}
	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil kalender akademik", events)
}

// @Summary Notifikasi pengguna
// @Description Pengumuman aktif dan tagihan UKT yang perlu diperhatikan
// @Tags Academic
// @Produce json
// @Security BearerAuth
// @Success 200 {object} utils.Response
// @Router /notifications [get]
func (h *AcademicHandler) GetNotifications(w http.ResponseWriter, r *http.Request) {
	userID, ok := studentIDFromContext(r)
	if !ok {
		utils.JSONResponse(w, http.StatusUnauthorized, "Gagal mengambil data user", nil)
		return
	}
	notifications := make([]map[string]interface{}, 0)
	var announcements []models.Announcement
	now := time.Now()
	if err := h.DB.Where(
		"status = ? AND start_date <= ? AND end_date >= ?",
		"Aktif",
		now,
		now,
	).Order("created_at DESC").Limit(20).Find(&announcements).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil notifikasi", nil)
		return
	}
	for _, announcement := range announcements {
		notifications = append(notifications, map[string]interface{}{
			"type": "announcement", "title": announcement.Title,
			"body": announcement.Content, "created_at": announcement.CreatedAt,
		})
	}
	var ukts []models.UKT
	if err := h.DB.Where("student_id = ? AND paid < billed AND due_date < ?", userID, now).Find(&ukts).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil notifikasi", nil)
		return
	}
	for _, ukt := range ukts {
		notifications = append(notifications, map[string]interface{}{
			"type": "ukt", "title": "Tagihan UKT jatuh tempo",
			"body": "Tagihan semester " + ukt.Semester + " belum lunas.", "created_at": ukt.DueDate,
		})
	}
	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil notifikasi", notifications)
}

// @Summary Audit periode kelas
// @Description Daftar kelas dengan tahun/semester kosong untuk rekonsiliasi aman
// @Tags Academic
// @Produce json
// @Security BearerAuth
// @Success 200 {object} utils.Response
// @Router /admin/academic/period-reconciliation [get]
func (h *AcademicHandler) GetPeriodReconciliation(w http.ResponseWriter, r *http.Request) {
	var classes []models.Class
	if err := h.DB.Where("year IS NULL OR year = '' OR semester IS NULL OR semester = ''").Find(&classes).Error; err != nil {
		utils.JSONResponse(w, http.StatusInternalServerError, "Gagal mengambil audit periode", nil)
		return
	}
	result := make([]map[string]interface{}, 0, len(classes))
	for _, class := range classes {
		var enrollments int64
		var grades int64
		if utils.RespondQueryError(w, h.DB.Model(&models.Enrollment{}).Where("class_id = ?", class.ID).Count(&enrollments).Error, "Gagal menghitung KRS pada audit periode") {
			return
		}
		if utils.RespondQueryError(w, h.DB.Model(&models.Grade{}).Where("class_id = ?", class.ID).Count(&grades).Error, "Gagal menghitung nilai pada audit periode") {
			return
		}
		result = append(result, map[string]interface{}{
			"class_id": class.ID, "class_name": class.Name,
			"year": class.Year, "semester": class.Semester,
			"enrollments": enrollments, "grades": grades,
			"action": "Perlu ditentukan periode oleh admin sebelum dipakai KRS",
		})
	}
	utils.JSONResponse(w, http.StatusOK, "Berhasil mengambil audit periode", map[string]interface{}{
		"active_period": config.AcademicPeriodNow(), "classes": result,
		"total": strconv.Itoa(len(result)),
	})
}
