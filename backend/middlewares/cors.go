package middlewares

import (
	"net/http"
	"os"

	"github.com/raihanmuzaffar/edu-track-campus/backend/config"
)

func EnableCORS(next http.Handler) (http.Handler, error) {
	production := config.IsProductionEnvironment()
	allowedOrigins := make(map[string]struct{})
	if production {
		origins, err := config.ParseProductionCORSOrigins(os.Getenv("CORS_ALLOWED_ORIGINS"))
		if err != nil {
			return nil, err
		}
		for _, origin := range origins {
			allowedOrigins[origin] = struct{}{}
		}
	}

	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		origin := r.Header.Get("Origin")
		if production {
			if origin != "" {
				if _, ok := allowedOrigins[origin]; !ok {
					http.Error(w, "Origin tidak diizinkan", http.StatusForbidden)
					return
				}
				w.Header().Set("Access-Control-Allow-Origin", origin)
				w.Header().Add("Vary", "Origin")
				w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
				w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
			}
		} else {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
		}

		if r.Method == http.MethodOptions {
			if production {
				w.WriteHeader(http.StatusNoContent)
			} else {
				w.WriteHeader(http.StatusOK)
			}
			return
		}
		next.ServeHTTP(w, r)
	})
	return handler, nil
}
