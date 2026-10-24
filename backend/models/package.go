package models

import "time"

type Package struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	Name      string    `gorm:"type:varchar(100);not null" json:"name"`
	Term      int       `gorm:"not null" json:"term"`
	Status    string    `gorm:"type:varchar(20);default:'Draf'" json:"status"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
	// Relasi Many-to-Many (GORM akan otomatis membuat tabel pivot)
	Courses []Course `gorm:"many2many:package_courses;" json:"courses"`
	Classes []Class  `gorm:"many2many:package_classes;" json:"classes"`
}