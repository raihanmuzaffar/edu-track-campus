package config

import (
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func setValidProductionEnvironment(t *testing.T) {
	t.Helper()
	certificate := filepath.Join(t.TempDir(), "root-ca.pem")
	if err := os.WriteFile(certificate, []byte("test certificate fixture"), 0o600); err != nil {
		t.Fatal("create CA fixture")
	}

	values := map[string]string{
		"DB_HOST":              "db.example.invalid",
		"DB_PORT":              "5432",
		"DB_USER":              "application",
		"DB_PASSWORD":          "fixture",
		"DB_NAME":              "edutrack",
		"DB_SSLMODE":           "verify-full",
		"DB_SSLROOTCERT":       certificate,
		"REDIS_HOST":           "redis.example.invalid",
		"REDIS_PORT":           "6379",
		"REDIS_PASSWORD":       "fixture",
		"REDIS_TLS":            "true",
		"JWT_SECRET":           strings.Repeat("x", 32),
		"SMTP_HOST":            "smtp.example.invalid",
		"SMTP_PORT":            "587",
		"SMTP_FROM":            "noreply@example.test",
		"CORS_ALLOWED_ORIGINS": "https://portal.example.test",
	}
	for name, value := range values {
		t.Setenv(name, value)
	}
}

func TestValidateProductionEnvironment(t *testing.T) {
	setValidProductionEnvironment(t)

	if err := ValidateProductionEnvironment(); err != nil {
		t.Fatalf("ValidateProductionEnvironment() error = %v", err)
	}
}

func TestValidateEnvironmentMode(t *testing.T) {
	tests := []struct {
		name       string
		value      string
		wantErr    bool
		production bool
	}{
		{name: "empty is rejected", value: "", wantErr: true},
		{name: "typo is rejected", value: "prod", wantErr: true},
		{name: "production is accepted", value: "production", production: true},
		{name: "development is accepted", value: "development"},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Setenv("APP_ENV", test.value)
			if err := ValidateEnvironmentMode(); (err != nil) != test.wantErr {
				t.Fatalf("ValidateEnvironmentMode() error = %v, wantErr %t", err, test.wantErr)
			}
			if got := IsProductionEnvironment(); got != test.production {
				t.Fatalf("IsProductionEnvironment() = %t, want %t", got, test.production)
			}
		})
	}
}

func TestValidateProductionEnvironmentRejectsInsecureDependencies(t *testing.T) {
	setValidProductionEnvironment(t)
	t.Setenv("DB_SSLMODE", "disable")
	t.Setenv("REDIS_TLS", "false")
	t.Setenv("JWT_SECRET", "short")
	t.Setenv("CORS_ALLOWED_ORIGINS", "*")

	err := ValidateProductionEnvironment()
	if err == nil {
		t.Fatal("ValidateProductionEnvironment() accepted insecure configuration")
	}
	for _, name := range []string{"DB_SSLMODE", "REDIS_TLS", "JWT_SECRET", "CORS_ALLOWED_ORIGINS"} {
		if !strings.Contains(err.Error(), name) {
			t.Errorf("error does not identify %s", name)
		}
	}
}

func TestParseProductionCORSOrigins(t *testing.T) {
	origins, err := ParseProductionCORSOrigins("https://portal.example.test,https://admin.example.test")
	if err != nil {
		t.Fatalf("ParseProductionCORSOrigins() error = %v", err)
	}
	if len(origins) != 2 {
		t.Fatalf("ParseProductionCORSOrigins() returned %d origins, want 2", len(origins))
	}

	for _, value := range []string{
		"*",
		"https://*.example.test",
		"http://portal.example.test",
		"https://portal.example.test/path",
		"https://portal.example.test:99999",
	} {
		if _, err := ParseProductionCORSOrigins(value); err == nil {
			t.Errorf("ParseProductionCORSOrigins(%q) unexpectedly succeeded", value)
		}
	}
}

func TestProductionPostgresDSNUsesVerifiedTLS(t *testing.T) {
	setValidProductionEnvironment(t)

	connection, err := url.Parse(ProductionPostgresDSN())
	if err != nil {
		t.Fatal("ProductionPostgresDSN() did not return a valid URL")
	}
	if connection.Scheme != "postgres" || connection.Path != "/edutrack" {
		t.Fatal("ProductionPostgresDSN() returned an unexpected database URL")
	}
	parameters := connection.Query()
	if parameters.Get("sslmode") != "verify-full" ||
		parameters.Get("sslrootcert") != os.Getenv("DB_SSLROOTCERT") {
		t.Fatal("ProductionPostgresDSN() omitted verified TLS configuration")
	}
}
