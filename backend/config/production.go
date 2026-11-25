package config

import (
	"fmt"
	"net"
	"net/url"
	"os"
	"sort"
	"strconv"
	"strings"
)

func IsProductionEnvironment() bool {
	return strings.EqualFold(strings.TrimSpace(os.Getenv("APP_ENV")), "production")
}

func ValidateEnvironmentMode() error {
	return ValidateEnvironmentModeValue(os.Getenv("APP_ENV"))
}

func ValidateEnvironmentModeValue(value string) error {
	mode := strings.ToLower(strings.TrimSpace(value))
	switch mode {
	case "development", "staging", "production":
		return nil
	default:
		return fmt.Errorf("APP_ENV must be development, staging, or production")
	}
}

func ValidateProductionEnvironment() error {
	invalid := map[string]struct{}{}
	required := []string{
		"DB_HOST",
		"DB_PORT",
		"DB_USER",
		"DB_PASSWORD",
		"DB_NAME",
		"DB_SSLROOTCERT",
		"REDIS_HOST",
		"REDIS_PORT",
		"REDIS_PASSWORD",
		"JWT_SECRET",
		"SMTP_HOST",
		"SMTP_PORT",
		"SMTP_FROM",
	}
	for _, name := range required {
		if strings.TrimSpace(os.Getenv(name)) == "" {
			invalid[name] = struct{}{}
		}
	}

	if !strings.EqualFold(strings.TrimSpace(os.Getenv("DB_SSLMODE")), "verify-full") {
		invalid["DB_SSLMODE"] = struct{}{}
	}
	if !strings.EqualFold(strings.TrimSpace(os.Getenv("REDIS_TLS")), "true") {
		invalid["REDIS_TLS"] = struct{}{}
	}
	if len(os.Getenv("JWT_SECRET")) < 32 {
		invalid["JWT_SECRET"] = struct{}{}
	}
	for _, name := range []string{"DB_PORT", "REDIS_PORT", "SMTP_PORT"} {
		port, err := strconv.Atoi(os.Getenv(name))
		if err != nil || port < 1 || port > 65535 {
			invalid[name] = struct{}{}
		}
	}

	rootCert := os.Getenv("DB_SSLROOTCERT")
	if rootCert != "" {
		file, err := os.Open(rootCert)
		if err != nil {
			invalid["DB_SSLROOTCERT"] = struct{}{}
		} else {
			info, statErr := file.Stat()
			closeErr := file.Close()
			if statErr != nil || closeErr != nil || !info.Mode().IsRegular() {
				invalid["DB_SSLROOTCERT"] = struct{}{}
			}
		}
	}

	smtpUsername := strings.TrimSpace(os.Getenv("SMTP_USERNAME"))
	smtpPassword := strings.TrimSpace(os.Getenv("SMTP_PASSWORD"))
	if (smtpUsername == "") != (smtpPassword == "") {
		invalid["SMTP_USERNAME"] = struct{}{}
		invalid["SMTP_PASSWORD"] = struct{}{}
	}
	if _, err := ParseProductionCORSOrigins(os.Getenv("CORS_ALLOWED_ORIGINS")); err != nil {
		invalid["CORS_ALLOWED_ORIGINS"] = struct{}{}
	}

	if len(invalid) == 0 {
		return nil
	}
	names := make([]string, 0, len(invalid))
	for name := range invalid {
		names = append(names, name)
	}
	sort.Strings(names)
	return fmt.Errorf("invalid or missing production environment variables: %s", strings.Join(names, ", "))
}

func ParseProductionCORSOrigins(raw string) ([]string, error) {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return nil, nil
	}

	origins := make([]string, 0)
	seen := make(map[string]struct{})
	for _, item := range strings.Split(raw, ",") {
		origin := strings.TrimSpace(item)
		parsed, err := url.Parse(origin)
		if origin == "" ||
			err != nil ||
			strings.Contains(origin, "*") ||
			!strings.EqualFold(parsed.Scheme, "https") ||
			parsed.Host == "" ||
			parsed.User != nil ||
			parsed.Path != "" ||
			parsed.RawQuery != "" ||
			parsed.Fragment != "" ||
			parsed.Opaque != "" ||
			parsed.String() != origin {
			return nil, fmt.Errorf("invalid CORS_ALLOWED_ORIGINS")
		}
		if port := parsed.Port(); port != "" {
			number, err := strconv.Atoi(port)
			if err != nil || number < 1 || number > 65535 {
				return nil, fmt.Errorf("invalid CORS_ALLOWED_ORIGINS")
			}
		}
		if _, ok := seen[origin]; ok {
			continue
		}
		seen[origin] = struct{}{}
		origins = append(origins, origin)
	}
	return origins, nil
}

func ProductionPostgresDSN() string {
	connection := url.URL{
		Scheme: "postgres",
		User:   url.UserPassword(os.Getenv("DB_USER"), os.Getenv("DB_PASSWORD")),
		Host:   net.JoinHostPort(os.Getenv("DB_HOST"), os.Getenv("DB_PORT")),
		Path:   "/" + os.Getenv("DB_NAME"),
	}
	parameters := url.Values{}
	parameters.Set("sslmode", os.Getenv("DB_SSLMODE"))
	parameters.Set("sslrootcert", os.Getenv("DB_SSLROOTCERT"))
	parameters.Set("TimeZone", "Asia/Jakarta")
	connection.RawQuery = parameters.Encode()
	return connection.String()
}
