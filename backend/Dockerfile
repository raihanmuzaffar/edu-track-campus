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

RUN apk add --no-cache ca-certificates tzdata \
    && addgroup -S app \
    && adduser -S -G app -h /app app

COPY --from=builder --chown=app:app /app/main .
USER app
EXPOSE 8080
CMD ["./main"]