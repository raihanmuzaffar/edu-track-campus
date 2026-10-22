package utils

import (
	"encoding/json"
	"net/http"
)

type Response struct {
	Status  string      `json:"status"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

func JSONResponse(w http.ResponseWriter, statusCode int, message string, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	// Tambahkan "_ =" di bawah ini
	_ = json.NewEncoder(w).Encode(Response{
		Status:  http.StatusText(statusCode),
		Message: message,
		Data:    data,
	})
}