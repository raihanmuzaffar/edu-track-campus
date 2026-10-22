package models

import "time"

type Enrollment struct {
	ID          uint      `gorm:"primaryKey" json:"id"`
	MahasiswaID uint      `gorm:"not null" json:"mahasiswa_id"` // Relasi ke User (Role: mahasiswa)
	ClassID     uint      `gorm:"not null" json:"class_id"`     // Relasi ke Class
	Status      string    `gorm:"type:varchar(20);default:'active'" json:"status"` // active, dropped
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`

	// Relasi GORM
	Mahasiswa User  `gorm:"foreignKey:MahasiswaID" json:"mahasiswa,omitempty"`
	Class     Class `gorm:"foreignKey:ClassID" json:"class,omitempty"`
}