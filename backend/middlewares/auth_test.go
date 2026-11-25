package middlewares

import (
	"context"
	"errors"
	"net"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/raihanmuzaffar/edu-track-campus/backend/config"
	"github.com/redis/go-redis/v9"
)

func TestAuthMiddlewareFailsClosedWhenRedisIsUnavailable(t *testing.T) {
	previousKey := config.JwtKey
	config.JwtKey = []byte(strings.Repeat("test-key", 4))
	t.Cleanup(func() {
		config.JwtKey = previousKey
	})

	token, _, err := config.GenerateToken(1, "admin")
	if err != nil {
		t.Fatal("GenerateToken() failed")
	}

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

	nextCalled := false
	handler := AuthMiddleware("admin")(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		nextCalled = true
		w.WriteHeader(http.StatusNoContent)
	}))
	request := httptest.NewRequest(http.MethodGet, "/protected", nil)
	request.Header.Set("Authorization", "Bearer "+token)
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request)

	if response.Code != http.StatusServiceUnavailable || nextCalled {
		t.Fatalf("Redis failure response = %d, handler called = %t; want 503 and handler not called", response.Code, nextCalled)
	}
}
