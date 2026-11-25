package middlewares_test

import (
	"context"
	"encoding/json"
	"errors"
	"net"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/raihanmuzaffar/edu-track-campus/backend/config"
	"github.com/raihanmuzaffar/edu-track-campus/backend/handlers"
	"github.com/raihanmuzaffar/edu-track-campus/backend/utils"
	"github.com/redis/go-redis/v9"
)

func TestLogoutReportsUnavailableWhenRedisCannotRevokeRefreshToken(t *testing.T) {
	previousRedis := config.SessionRedis
	client := redis.NewClient(&redis.Options{
		Addr:       "unused",
		MaxRetries: -1,
		Dialer: func(context.Context, string, string) (net.Conn, error) {
			return nil, errors.New("test Redis unavailable")
		},
	})
	config.SessionRedis = client
	t.Cleanup(func() {
		config.SessionRedis = previousRedis
		_ = client.Close()
	})

	request := httptest.NewRequest(http.MethodPost, "/api/v1/logout", strings.NewReader(`{"refresh_token":"refresh-token"}`))
	response := httptest.NewRecorder()
	(&handlers.AuthHandler{}).Logout(response, request)

	if response.Code != http.StatusServiceUnavailable {
		t.Fatalf("Logout() status = %d, want %d", response.Code, http.StatusServiceUnavailable)
	}
	var body utils.Response
	if err := json.Unmarshal(response.Body.Bytes(), &body); err != nil {
		t.Fatalf("Logout() response is not a valid API response: %v", err)
	}
	if body.Status != http.StatusText(http.StatusServiceUnavailable) {
		t.Fatalf("Logout() response status = %q, want %q", body.Status, http.StatusText(http.StatusServiceUnavailable))
	}
}
