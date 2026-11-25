package config

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"os"
	"strconv"
	"sync"
	"time"

	"github.com/redis/go-redis/v9"
)

const (
	refreshTTL    = 7 * 24 * time.Hour
	sessionPrefix = "edutrack:session:"
	revokedPrefix = "edutrack:revoked:"
)

var (
	SessionRedis   *redis.Client
	memoryMu       sync.Mutex
	memorySessions = map[string]SessionRecord{}
	memoryRevoked  = map[string]time.Time{}
)

type SessionRecord struct {
	UserID    uint   `json:"user_id"`
	Role      string `json:"role"`
	AccessJTI string `json:"access_jti"`
}

func refreshTokenTTL() time.Duration {
	days, err := strconv.Atoi(os.Getenv("REFRESH_TOKEN_TTL_DAYS"))
	if err != nil || days < 1 {
		return refreshTTL
	}
	return time.Duration(days) * 24 * time.Hour
}

func hashToken(token string) string {
	sum := sha256.Sum256([]byte(token))
	return hex.EncodeToString(sum[:])
}

func IssueRefreshToken(userID uint, role, accessJTI string) (string, error) {
	raw := make([]byte, 32)
	if _, err := rand.Read(raw); err != nil {
		return "", err
	}
	token := base64.RawURLEncoding.EncodeToString(raw)
	record := SessionRecord{UserID: userID, Role: role, AccessJTI: accessJTI}
	encoded, err := json.Marshal(record)
	if err != nil {
		return "", err
	}
	key := sessionPrefix + hashToken(token)
	if SessionRedis != nil {
		if err := SessionRedis.Set(context.Background(), key, encoded, refreshTokenTTL()).Err(); err != nil {
			return "", err
		}
		return token, nil
	}
	memoryMu.Lock()
	memorySessions[key] = record
	memoryMu.Unlock()
	return token, nil
}

func ConsumeRefreshToken(token string) (SessionRecord, bool) {
	var record SessionRecord
	if token == "" {
		return record, false
	}
	key := sessionPrefix + hashToken(token)
	if SessionRedis != nil {
		value, err := SessionRedis.GetDel(context.Background(), key).Bytes()
		if err != nil || json.Unmarshal(value, &record) != nil {
			return SessionRecord{}, false
		}
		return record, true
	}
	memoryMu.Lock()
	stored, ok := memorySessions[key]
	delete(memorySessions, key)
	memoryMu.Unlock()
	return stored, ok
}

func RevokeRefreshToken(token string) (bool, error) {
	if token == "" {
		return false, nil
	}
	key := sessionPrefix + hashToken(token)
	if SessionRedis != nil {
		deleted, err := SessionRedis.Del(context.Background(), key).Result()
		if err != nil {
			return false, err
		}
		return deleted > 0, nil
	}
	memoryMu.Lock()
	_, ok := memorySessions[key]
	delete(memorySessions, key)
	memoryMu.Unlock()
	return ok, nil
}

func RevokeAccess(jti string, ttl time.Duration) error {
	if jti == "" || ttl <= 0 {
		return nil
	}
	key := revokedPrefix + jti
	if SessionRedis != nil {
		return SessionRedis.Set(context.Background(), key, "1", ttl).Err()
	}
	memoryMu.Lock()
	memoryRevoked[key] = time.Now().Add(ttl)
	memoryMu.Unlock()
	return nil
}

func IsAccessRevoked(jti string) (bool, error) {
	if jti == "" {
		return false, nil
	}
	key := revokedPrefix + jti
	if SessionRedis != nil {
		exists, err := SessionRedis.Exists(context.Background(), key).Result()
		if err != nil {
			return false, err
		}
		return exists > 0, nil
	}
	memoryMu.Lock()
	expiry, ok := memoryRevoked[key]
	if ok && time.Now().After(expiry) {
		delete(memoryRevoked, key)
		ok = false
	}
	memoryMu.Unlock()
	return ok, nil
}
