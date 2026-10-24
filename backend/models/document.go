package models

import "time"

type Document struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	StudentID uint      `gorm:"not null" json:"student_id"`
	Type      string    `gorm:"type:varchar(50);not null" json:"type"`
	Semester  string    `gorm:"type:varchar(50);not null" json:"semester"`
	Status    string    `gorm:"type:varchar(30);not null" json:"status"`
	Date      time.Time `json:"date"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
	Student   User      `gorm:"foreignKey:StudentID" json:"student,omitempty"`
}
