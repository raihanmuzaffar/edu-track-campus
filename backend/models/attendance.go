package models

import "time"

type Attendance struct {
	ID          uint      `gorm:"primaryKey" json:"id"`
	ClassID     uint      `gorm:"not null" json:"class_id"`
	MahasiswaID uint      `gorm:"not null" json:"mahasiswa_id"`
	Date        time.Time `gorm:"not null" json:"date"` // Tanggal pertemuan
	Status      string    `gorm:"type:varchar(20);not null" json:"status"` // hadir, izin, sakit, alpa
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`

	// Relasi GORM
	Class     Class `gorm:"foreignKey:ClassID" json:"class,omitempty"`
	Mahasiswa User  `gorm:"foreignKey:MahasiswaID" json:"mahasiswa,omitempty"`
}