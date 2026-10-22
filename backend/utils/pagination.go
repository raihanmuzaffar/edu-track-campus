package utils

import (
	"net/http"
	"strconv"
)

func GetPagination(r *http.Request) (limit int, offset int) {
	pageStr := r.URL.Query().Get("page")
	limitStr := r.URL.Query().Get("limit")

	page, _ := strconv.Atoi(pageStr)
	limit, _ = strconv.Atoi(limitStr)

	if page < 1 {
		page = 1
	}
	if limit < 1 {
		limit = 10 // Default 10 data per halaman
	}

	offset = (page - 1) * limit
	return limit, offset
}