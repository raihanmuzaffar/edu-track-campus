package models

import "time"

type Course struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	Code      string    `gorm:"type:varchar(20);uniqueIndex;not null" json:"code"` // Contoh: IF-101
	Name      string    `gorm:"type:varchar(100);not null" json:"name"`           // Contoh: Pemrograman Dasar
	SKS       int       `gorm:"not null" json:"sks"`
	Semester  int       `gorm:"not null" json:"semester"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}