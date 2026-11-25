package utils_test

import (
	"net/http/httptest"
	"testing"

	"github.com/raihanmuzaffar/edu-track-campus/backend/handlers"
	"github.com/raihanmuzaffar/edu-track-campus/backend/utils"
)

func TestGetPaginationDefaultsAndLimits(t *testing.T) {
	tests := []struct {
		name       string
		query      string
		wantLimit  int
		wantOffset int
		wantErr    bool
	}{
		{name: "defaults", wantLimit: 10, wantOffset: 0},
		{name: "page and limit", query: "?page=3&limit=25", wantLimit: 25, wantOffset: 50},
		{name: "invalid page", query: "?page=nope", wantErr: true},
		{name: "oversized limit", query: "?limit=101", wantErr: true},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			request := httptest.NewRequest("GET", "/items"+test.query, nil)
			limit, offset, err := utils.GetPagination(request)
			if (err != nil) != test.wantErr {
				t.Fatalf("GetPagination error = %v, wantErr %v", err, test.wantErr)
			}
			if err == nil && (limit != test.wantLimit || offset != test.wantOffset) {
				t.Fatalf("GetPagination = (%d, %d), want (%d, %d)", limit, offset, test.wantLimit, test.wantOffset)
			}
		})
	}
}

func TestPublicRegistrationDoesNotAllowWebAdminRoles(t *testing.T) {
	for _, role := range []string{"admin", "kaprodi"} {
		input := handlers.RegisterInput{
			Name:     "Testing User",
			Email:    "testing@example.com",
			Password: "long-password",
			Role:     role,
		}
		if err := utils.Validate.Struct(input); err == nil {
			t.Errorf("public registration unexpectedly accepts role %q", role)
		}
	}
}

func TestMultiwordStatusValidation(t *testing.T) {
	tests := []struct {
		name  string
		input interface{}
	}{
		{name: "case status", input: handlers.CaseInput{StudentID: 1, Level: "SP 1", Reason: "Alasan", Followup: "Tindak lanjut", Status: "Perlu diperiksa"}},
		{name: "document status", input: handlers.DocumentInput{StudentID: 1, Type: "KHS", Semester: "Ganjil", Status: "Memerlukan perbaikan", Date: "2026-01-01"}},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			if err := utils.Validate.Struct(test.input); err != nil {
				t.Fatalf("status should be valid: %v", err)
			}
		})
	}
}
