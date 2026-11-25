package middlewares

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestEnableCORSProductionAllowsListedAndOriginlessRequests(t *testing.T) {
	t.Setenv("APP_ENV", "production")
	t.Setenv("CORS_ALLOWED_ORIGINS", "https://portal.example.test")

	nextCalled := false
	handler, err := EnableCORS(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		nextCalled = true
		w.WriteHeader(http.StatusNoContent)
	}))
	if err != nil {
		t.Fatal("EnableCORS() rejected valid production origins")
	}

	request := httptest.NewRequest(http.MethodGet, "/api/v1/users/me", nil)
	request.Header.Set("Origin", "https://portal.example.test")
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request)
	if response.Code != http.StatusNoContent {
		t.Fatalf("allowed origin status = %d, want %d", response.Code, http.StatusNoContent)
	}
	if response.Header().Get("Access-Control-Allow-Origin") != "https://portal.example.test" {
		t.Fatal("allowed origin was not echoed")
	}

	nextCalled = false
	request = httptest.NewRequest(http.MethodGet, "/api/v1/users/me", nil)
	response = httptest.NewRecorder()
	handler.ServeHTTP(response, request)
	if response.Code != http.StatusNoContent || !nextCalled {
		t.Fatal("originless mobile request was not passed through")
	}
	if response.Header().Get("Access-Control-Allow-Origin") != "" {
		t.Fatal("originless request unexpectedly received CORS permission")
	}
}

func TestEnableCORSProductionRejectsUnlistedOrigin(t *testing.T) {
	t.Setenv("APP_ENV", "production")
	t.Setenv("CORS_ALLOWED_ORIGINS", "https://portal.example.test")

	nextCalled := false
	handler, err := EnableCORS(http.HandlerFunc(func(http.ResponseWriter, *http.Request) {
		nextCalled = true
	}))
	if err != nil {
		t.Fatal("EnableCORS() rejected valid production origins")
	}

	request := httptest.NewRequest(http.MethodOptions, "/api/v1/users/me", nil)
	request.Header.Set("Origin", "https://unlisted.example.test")
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request)
	if response.Code != http.StatusForbidden || nextCalled {
		t.Fatal("unlisted origin was not rejected before reaching the handler")
	}
}

func TestEnableCORSDevelopmentRetainsWildcard(t *testing.T) {
	t.Setenv("APP_ENV", "development")
	t.Setenv("CORS_ALLOWED_ORIGINS", "")

	handler, err := EnableCORS(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusNoContent)
	}))
	if err != nil {
		t.Fatal("EnableCORS() returned an error in development")
	}

	request := httptest.NewRequest(http.MethodGet, "/api/v1/users/me", nil)
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request)
	if response.Header().Get("Access-Control-Allow-Origin") != "*" {
		t.Fatal("development wildcard behavior changed")
	}
}

func TestEnableCORSRejectsInvalidProductionOriginConfiguration(t *testing.T) {
	t.Setenv("APP_ENV", "production")
	t.Setenv("CORS_ALLOWED_ORIGINS", "*")

	if _, err := EnableCORS(http.NotFoundHandler()); err == nil {
		t.Fatal("EnableCORS() accepted a wildcard production origin")
	}
}
