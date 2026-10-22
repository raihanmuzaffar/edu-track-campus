package models

import "time"

type Grade struct {
	ID          uint      `gorm:"primaryKey" json:"id"`
	MahasiswaID uint      `gorm:"not null" json:"mahasiswa_id"`
	ClassID     uint      `gorm:"not null" json:"class_id"`
	Score       float64   `gorm:"not null" json:"score"` // Contoh: 85.5
	Letter      string    `gorm:"type:varchar(2);not null" json:"letter"` // Contoh: A, B+, C
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`

	// Relasi GORM
	Mahasiswa User  `gorm:"foreignKey:MahasiswaID" json:"mahasiswa,omitempty"`
	Class     Class `gorm:"foreignKey:ClassID" json:"class,omitempty"`
}