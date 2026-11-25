package config

import (
	"errors"
	"os"
	"strconv"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

const (
	TokenIssuer   = "edutrack-campus"
	TokenAudience = "edutrack-clients"
)

var (
	JwtKey            = []byte(os.Getenv("JWT_SECRET"))
	ErrInvalidToken   = errors.New("token tidak valid")
	ErrWrongAlgorithm = errors.New("algoritma token tidak diizinkan")
	ErrWrongIssuer    = errors.New("penerbit token tidak dikenal")
	ErrWrongAudience  = errors.New("audiens token tidak dikenal")
	ErrMissingClaims  = errors.New("klaim token tidak lengkap")
	ErrRevokedToken   = errors.New("token telah dicabut")
)

type Claims struct {
	UserID uint   `json:"user_id"`
	Role   string `json:"role"`
	jwt.RegisteredClaims
}

func AccessTokenTTL() time.Duration {
	hours, err := strconv.Atoi(os.Getenv("JWT_ACCESS_TTL_HOURS"))
	if err != nil || hours < 1 {
		return 24 * time.Hour
	}
	return time.Duration(hours) * time.Hour
}

func GenerateToken(userID uint, role string) (string, string, error) {
	now := time.Now()
	jti := uuid.NewString()
	claims := &Claims{
		UserID: userID,
		Role:   role,
		RegisteredClaims: jwt.RegisteredClaims{
			ID:        jti,
			Subject:   strconv.FormatUint(uint64(userID), 10),
			Issuer:    TokenIssuer,
			Audience:  jwt.ClaimStrings{TokenAudience},
			IssuedAt:  jwt.NewNumericDate(now),
			NotBefore: jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(AccessTokenTTL())),
		},
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	signed, err := token.SignedString(JwtKey)
	return signed, jti, err
}

func ParseToken(tokenString string) (*Claims, error) {
	claims := &Claims{}
	token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
		if token.Method.Alg() != jwt.SigningMethodHS256.Alg() {
			return nil, ErrWrongAlgorithm
		}
		return JwtKey, nil
	}, jwt.WithValidMethods([]string{jwt.SigningMethodHS256.Alg()}),
		jwt.WithIssuer(TokenIssuer),
		jwt.WithAudience(TokenAudience),
		jwt.WithExpirationRequired(),
	)
	if err != nil || token == nil || !token.Valid {
		return nil, ErrInvalidToken
	}
	if claims.UserID == 0 || claims.Role == "" || claims.ID == "" {
		return nil, ErrMissingClaims
	}
	if claims.ExpiresAt == nil {
		return nil, ErrMissingClaims
	}
	return claims, nil
}

func TokenExpiry(claims *Claims) time.Duration {
	if claims == nil || claims.ExpiresAt == nil {
		return 0
	}
	remaining := time.Until(claims.ExpiresAt.Time)
	if remaining < 0 {
		return 0
	}
	return remaining
}
