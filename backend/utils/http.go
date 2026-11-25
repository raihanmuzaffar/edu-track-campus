package utils

import (
	"errors"
	"net/http"
	"sort"
	"strings"
)

type sqlStateError interface {
	SQLState() string
}

// RespondQueryError writes a generic API error when a database query fails.
func RespondQueryError(w http.ResponseWriter, err error, message string) bool {
	if err == nil {
		return false
	}
	JSONResponse(w, http.StatusInternalServerError, message, nil)
	return true
}

func IsForeignKeyViolation(err error) bool {
	var databaseError sqlStateError
	return errors.As(err, &databaseError) && databaseError.SQLState() == "23503"
}

func MethodOnly(method string, next http.Handler) http.Handler {
	return MethodRouter(map[string]http.Handler{method: next})
}

func MethodRouter(handlers map[string]http.Handler) http.Handler {
	allowed := make([]string, 0, len(handlers))
	for method := range handlers {
		allowed = append(allowed, method)
	}
	sort.Strings(allowed)
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		handler, ok := handlers[r.Method]
		if !ok {
			w.Header().Set("Allow", strings.Join(allowed, ", "))
			JSONResponse(w, http.StatusMethodNotAllowed, "Metode HTTP tidak diizinkan untuk endpoint ini", nil)
			return
		}
		handler.ServeHTTP(w, r)
	})
}
