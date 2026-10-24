package models

import "time"

type Schedule struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	Semester  string    `gorm:"type:varchar(50);not null" json:"semester"`
	ClassID   uint      `gorm:"not null" json:"class_id"`
	CourseID  uint      `gorm:"not null" json:"course_id"`
	TeacherID uint      `gorm:"not null" json:"teacher_id"`
	Day       string    `gorm:"type:varchar(20);not null" json:"day"`
	StartTime string    `gorm:"type:varchar(10);not null" json:"start_time"`
	EndTime   string    `gorm:"type:varchar(10);not null" json:"end_time"`
	Room      string    `gorm:"type:varchar(50)" json:"room"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
	Class     Class     `gorm:"foreignKey:ClassID" json:"class,omitempty"`
	Course    Course    `gorm:"foreignKey:CourseID" json:"course,omitempty"`
	Teacher   User      `gorm:"foreignKey:TeacherID" json:"teacher,omitempty"`
}
