package utils

import (
	"fmt"
	"net/http"
	"strconv"
)

const (
	defaultPage  = 1
	defaultLimit = 10
	maxPage      = 1_000_000
	maxLimit     = 100
)

func GetPagination(r *http.Request) (limit int, offset int, err error) {
	pageStr := r.URL.Query().Get("page")
	limitStr := r.URL.Query().Get("limit")

	page := defaultPage
	if pageStr != "" {
		page, err = strconv.Atoi(pageStr)
		if err != nil || page < 1 || page > maxPage {
			return 0, 0, fmt.Errorf("page harus berupa bilangan bulat antara 1 dan %d", maxPage)
		}
	}
	limit = defaultLimit
	if limitStr != "" {
		limit, err = strconv.Atoi(limitStr)
		if err != nil || limit < 1 || limit > maxLimit {
			return 0, 0, fmt.Errorf("limit harus berupa bilangan bulat antara 1 dan %d", maxLimit)
		}
	}

	offset = (page - 1) * limit
	return limit, offset, nil
}
