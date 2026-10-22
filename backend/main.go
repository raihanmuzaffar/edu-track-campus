package main

import (
	"fmt"
	"net/http"
)

func main() {
	http.HandleFunc("/api/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		fmt.Fprintf(w, `{"status": "OK", "message": "Edu-Track Backend is running!"}`)
	})

	fmt.Println("Server berjalan di port 8080")
	http.ListenAndServe(":8080", nil)
}