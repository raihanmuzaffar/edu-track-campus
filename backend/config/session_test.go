package config

import (
	"context"
	"errors"
	"net"
	"testing"

	"github.com/redis/go-redis/v9"
)

func TestRedisSessionFailuresAreReturnedWithoutMemoryFallback(t *testing.T) {
	previousRedis := SessionRedis
	client := redis.NewClient(&redis.Options{
		Addr:       "unused",
		MaxRetries: -1,
		Dialer: func(context.Context, string, string) (net.Conn, error) {
			return nil, errors.New("test Redis unavailable")
		},
	})
	SessionRedis = client
	t.Cleanup(func() {
		SessionRedis = previousRedis
		_ = client.Close()
	})

	if _, err := RevokeRefreshToken("refresh-token"); err == nil {
		t.Fatal("RevokeRefreshToken() did not return the Redis error")
	}
	if err := RevokeAccess("access-jti", 1); err == nil {
		t.Fatal("RevokeAccess() did not return the Redis error")
	}
	if revoked, err := IsAccessRevoked("access-jti"); err == nil || revoked {
		t.Fatal("IsAccessRevoked() did not return the Redis error")
	}
}
