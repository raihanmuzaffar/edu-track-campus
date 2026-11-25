package middlewares

import (
	"context"
	"net/http"
	"strings"

	"github.com/raihanmuzaffar/edu-track-campus/backend/config"
	"github.com/raihanmuzaffar/edu-track-campus/backend/utils"
)

type contextKey string

const (
	UserIDKey contextKey = "user_id"
	RoleKey   contextKey = "role"
	TokenKey  contextKey = "token"
	JTIKey    contextKey = "jti"
)

func AuthMiddleware(allowedRoles ...string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			authHeader := strings.TrimSpace(r.Header.Get("Authorization"))
			if !strings.HasPrefix(authHeader, "Bearer ") {
				utils.JSONResponse(w, http.StatusUnauthorized, "Header Authorization harus menggunakan Bearer token", nil)
				return
			}
			tokenString := strings.TrimSpace(strings.TrimPrefix(authHeader, "Bearer "))
			claims, err := config.ParseToken(tokenString)
			if err != nil {
				utils.JSONResponse(w, http.StatusUnauthorized, "Token tidak valid atau sudah kedaluwarsa", nil)
				return
			}
			revoked, err := config.IsAccessRevoked(claims.ID)
			if err != nil {
				utils.JSONResponse(w, http.StatusServiceUnavailable, "Status sesi tidak dapat diverifikasi saat ini", nil)
				return
			}
			if revoked {
				utils.JSONResponse(w, http.StatusUnauthorized, "Sesi telah berakhir. Silakan login kembali", nil)
				return
			}

			isAllowed := false
			for _, role := range allowedRoles {
				if claims.Role == role {
					isAllowed = true
					break
				}
			}
			if !isAllowed {
				utils.JSONResponse(w, http.StatusForbidden, "Anda tidak memiliki akses untuk sumber daya ini", nil)
				return
			}

			ctx := context.WithValue(r.Context(), UserIDKey, claims.UserID)
			ctx = context.WithValue(ctx, RoleKey, claims.Role)
			ctx = context.WithValue(ctx, TokenKey, tokenString)
			ctx = context.WithValue(ctx, JTIKey, claims.ID)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}
