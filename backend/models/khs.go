package models

import "time"

type KHSRecord struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	StudentID uint      `gorm:"not null;uniqueIndex:idx_student_semester" json:"student_id"`
	Semester  string    `gorm:"type:varchar(50);not null;uniqueIndex:idx_student_semester" json:"semester"`
	Status    string    `gorm:"type:varchar(30);default:'Draf'" json:"status"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
	Student   User      `gorm:"foreignKey:StudentID" json:"student,omitempty"`
}
