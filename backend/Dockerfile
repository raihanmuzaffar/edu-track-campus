# Tahap 1: Build
FROM golang:1.26.0-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go build -o main ./main.go

# Tahap 2: Run (Image kecil)
FROM alpine:latest
WORKDIR /app

# TAMBAHKAN BARIS INI UNTUK MEMPERBAIKI ERROR TIMEZONE
RUN apk add --no-cache tzdata 

COPY --from=builder /app/main .
EXPOSE 8080
CMD ["./main"]