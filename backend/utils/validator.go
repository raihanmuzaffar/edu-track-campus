package utils

import (
	"fmt"
	"strings"

	"github.com/go-playground/validator/v10"
)

// Inisialisasi validator global
var Validate = validator.New()

// Fungsi untuk menerjemahkan error validator ke Bahasa Indonesia
func FormatValidationError(err error) string {
	if err == nil {
		return ""
	}

	// Ambil error pertama saja agar pesannya simpel
	for _, e := range err.(validator.ValidationErrors) {
		field := strings.ToLower(e.Field())
		
		switch e.Tag() {
		case "required":
			return fmt.Sprintf("%s wajib diisi", field)
		case "email":
			return fmt.Sprintf("format %s tidak valid", field)
		case "min":
			return fmt.Sprintf("%s minimal %s karakter/angka", field, e.Param())
		case "max":
			return fmt.Sprintf("%s maksimal %s karakter/angka", field, e.Param())
		case "numeric":
			return fmt.Sprintf("%s harus berupa angka", field)
		case "oneof":
			return fmt.Sprintf("%s harus salah satu dari: %s", field, e.Param())
		case "gt":
			return fmt.Sprintf("%s harus lebih besar dari %s", field, e.Param())
		default:
			return fmt.Sprintf("%s tidak valid", field)
		}
	}
	return "Data tidak valid"
}	