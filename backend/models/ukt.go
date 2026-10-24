package models

import "time"

type UKT struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	StudentID uint      `gorm:"not null" json:"student_id"`
	Semester  string    `gorm:"type:varchar(50);not null" json:"semester"`
	Billed    float64   `gorm:"not null" json:"billed"`
	Paid      float64   `gorm:"not null" json:"paid"`
	DueDate   time.Time `json:"due_date"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
	Student   User      `gorm:"foreignKey:StudentID" json:"student,omitempty"`
}
