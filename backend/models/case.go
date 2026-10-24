package models

import "time"

type Case struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	StudentID uint      `gorm:"not null" json:"student_id"`
	Level     string    `gorm:"type:varchar(20);not null" json:"level"`
	Reason    string    `gorm:"type:text" json:"reason"`
	Followup  string    `gorm:"type:text" json:"followup"`
	Status    string    `gorm:"type:varchar(30);default:'Draf'" json:"status"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
	Student   User      `gorm:"foreignKey:StudentID" json:"student,omitempty"`
}
