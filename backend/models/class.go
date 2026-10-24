package models

import "time"

type Class struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	CourseID  uint      `gorm:"not null" json:"course_id"` // Relasi ke Mata Kuliah
	DosenID   uint      `gorm:"not null" json:"dosen_id"`  // Relasi ke User (Role: dosen)
	Name      string    `gorm:"type:varchar(50);not null" json:"name"` // Contoh: "Kelas A"
	Day       string    `gorm:"type:varchar(20);not null" json:"day"`  // Contoh: "Senin"
	StartTime string    `gorm:"type:varchar(10);not null" json:"start_time"` // Contoh: "08:00"
	EndTime   string    `gorm:"type:varchar(10);not null" json:"end_time"`   // Contoh: "10:30"
	Room      string    `gorm:"type:varchar(50)" json:"room"` // Contoh: "Lab 1"
	Year      string    `gorm:"type:varchar(20)" json:"year"`
	Semester  string    `gorm:"type:varchar(50)" json:"semester"`
	Status    string    `gorm:"type:varchar(20);default:'Aktif'" json:"status"`
	PackageID *uint     `json:"package_id"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`

	// Relasi GORM untuk mempermudah penarikan data
	Course Course `gorm:"foreignKey:CourseID" json:"course,omitempty"`
	Dosen  User   `gorm:"foreignKey:DosenID" json:"dosen,omitempty"`
}