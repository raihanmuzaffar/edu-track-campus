package utils

import (
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestRespondQueryErrorUsesGenericAPIErrorEnvelope(t *testing.T) {
	response := httptest.NewRecorder()
	handled := RespondQueryError(response, errors.New("internal database detail"), "Gagal mengambil data")

	if !handled {
		t.Fatal("query error was not handled")
	}
	if response.Code != http.StatusInternalServerError {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusInternalServerError)
	}
	rawBody := response.Body.String()
	var body Response
	if err := json.NewDecoder(strings.NewReader(rawBody)).Decode(&body); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	if body.Status != http.StatusText(http.StatusInternalServerError) || body.Message != "Gagal mengambil data" || body.Data != nil {
		t.Fatalf("unexpected error response: %+v", body)
	}
	if rawBody == "" || strings.Contains(rawBody, "internal database detail") {
		t.Fatal("response should contain the API error envelope without internal database details")
	}
}

func TestRespondQueryErrorLeavesSuccessfulEmptyQueryUnchanged(t *testing.T) {
	response := httptest.NewRecorder()
	if handled := RespondQueryError(response, nil, "Gagal mengambil data"); handled {
		t.Fatal("nil query error should not be handled as a failure")
	}
	if response.Code != http.StatusOK || response.Body.Len() != 0 {
		t.Fatalf("response changed for a successful empty result: status=%d body=%q", response.Code, response.Body.String())
	}
}

func TestMethodRouterRejectsUnsupportedMethods(t *testing.T) {
	router := MethodRouter(map[string]http.Handler{
		http.MethodPost: http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
			w.WriteHeader(http.StatusCreated)
		}),
	})
	response := httptest.NewRecorder()
	router.ServeHTTP(response, httptest.NewRequest(http.MethodGet, "/", nil))

	if response.Code != http.StatusMethodNotAllowed {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusMethodNotAllowed)
	}
	if response.Header().Get("Allow") != http.MethodPost {
		t.Fatalf("Allow = %q, want %q", response.Header().Get("Allow"), http.MethodPost)
	}
}

func TestMethodRouterInvokesAllowedMethod(t *testing.T) {
	router := MethodRouter(map[string]http.Handler{
		http.MethodPost: http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
			w.WriteHeader(http.StatusCreated)
		}),
	})
	response := httptest.NewRecorder()
	router.ServeHTTP(response, httptest.NewRequest(http.MethodPost, "/", nil))

	if response.Code != http.StatusCreated {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusCreated)
	}
}
