package handlers_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/raihanmuzaffar/edu-track-campus/backend/handlers"
)

func TestCreateCourse_Success(t *testing.T) {
	handler := &handlers.CourseHandler{DB: testDB}

	body := map[string]interface{}{
		"code":     "CS-101",
		"name":     "Pemrograman Dasar",
		"sks":      3,
		"semester": 1,
	}
	jsonBody, _ := json.Marshal(body)

	req := httptest.NewRequest("POST", "/courses", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()

	handler.CreateCourse(w, req)

	if w.Code != http.StatusCreated {
		t.Errorf("Expected status 201, got %d", w.Code)
	}
}

func TestCreateCourse_FailInvalidSKS(t *testing.T) {
	handler := &handlers.CourseHandler{DB: testDB}

	body := map[string]interface{}{
		"code":     "CS-102",
		"name":     "Struktur Data",
		"sks":      0, // Sengaja 0, padahal aturannya gt=0 (greater than 0)
		"semester": 1,
	}
	jsonBody, _ := json.Marshal(body)

	req := httptest.NewRequest("POST", "/courses", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()

	handler.CreateCourse(w, req)

	// Harusnya gagal (400) karena validasi SKS
	if w.Code != http.StatusBadRequest {
		t.Errorf("Expected status 400, got %d", w.Code)
	}
}