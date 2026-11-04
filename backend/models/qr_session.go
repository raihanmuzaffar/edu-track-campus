package models

import "time"

type QRSession struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	Token     string    `gorm:"type:varchar(100);uniqueIndex;not null" json:"token"`
	ClassID   uint      `gorm:"not null" json:"class_id"`
	DosenID   uint      `gorm:"not null" json:"dosen_id"`
	IsActive  bool      `gorm:"default:true" json:"is_active"`
	ExpiresAt time.Time `gorm:"not null" json:"expires_at"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`

	// Relasi GORM
	Class Class `gorm:"foreignKey:ClassID" json:"class,omitempty"`
	Dosen User  `gorm:"foreignKey:DosenID" json:"dosen,omitempty"`
}