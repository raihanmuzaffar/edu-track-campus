	package models

import "time"

type ParentStudent struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	ParentID  uint      `gorm:"not null;uniqueIndex:idx_parent_student" json:"parent_id"`
	StudentID uint      `gorm:"not null;uniqueIndex:idx_parent_student" json:"student_id"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`

	// Relasi GORM
	Parent  User `gorm:"foreignKey:ParentID" json:"parent,omitempty"`
	Student User `gorm:"foreignKey:StudentID" json:"student,omitempty"`
}