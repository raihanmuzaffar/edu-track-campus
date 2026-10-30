package handlers_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/raihanmuzaffar/edu-track-campus/backend/handlers"
)

func TestRegister_Success(t *testing.T) {
	handler := &handlers.AuthHandler{DB: testDB}

	body := map[string]string{
		"name":     "Budi Test",
		"email":    "buditest@test.com",
		"password": "password123",
		"role":     "mahasiswa",
	}
	jsonBody, _ := json.Marshal(body)

	req := httptest.NewRequest("POST", "/register", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()

	handler.Register(w, req)

	// Harusnya berhasil (201)
	if w.Code != http.StatusCreated {
		t.Errorf("Expected status 201, got %d", w.Code)
	}
}

func TestRegister_FailInvalidEmail(t *testing.T) {
	handler := &handlers.AuthHandler{DB: testDB}

	body := map[string]string{
		"name":     "Budi Test",
		"email":    "bukan-email", // Sengaja salah format
		"password": "password123",
		"role":     "mahasiswa",
	}
	jsonBody, _ := json.Marshal(body)

	req := httptest.NewRequest("POST", "/register", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()

	handler.Register(w, req)

	// Harusnya gagal karena validasi email (400)
	if w.Code != http.StatusBadRequest {
		t.Errorf("Expected status 400, got %d", w.Code)
	}
}

func TestLogin_Success(t *testing.T) {
	handler := &handlers.AuthHandler{DB: testDB}

	// Login menggunakan akun admin yang dibuat di setup_test.go
	body := map[string]string{
		"email":    "testadmin@test.com",
		"password": "password123",
	}
	jsonBody, _ := json.Marshal(body)

	req := httptest.NewRequest("POST", "/login", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()

	handler.Login(w, req)

	// Harusnya berhasil (200)
	if w.Code != http.StatusOK {
		t.Errorf("Expected status 200, got %d", w.Code)
	}
}