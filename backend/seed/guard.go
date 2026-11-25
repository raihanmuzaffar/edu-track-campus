package main

import (
	"fmt"
	"os"
	"sort"
	"strconv"
	"strings"

	"github.com/raihanmuzaffar/edu-track-campus/backend/config"
)

type seedTargetConfig struct {
	appEnv               string
	allowDestructive     string
	targetDisposable     string
	dbHost               string
	dbPort               string
	dbUser               string
	dbPassword           string
	dbName               string
	dbSSLMode            string
	dbSSLRootCertificate string
}

func loadSeedTargetConfig() (seedTargetConfig, error) {
	target := seedTargetConfig{
		appEnv:               os.Getenv("APP_ENV"),
		allowDestructive:     os.Getenv("SEED_ALLOW_DESTRUCTIVE"),
		targetDisposable:     os.Getenv("SEED_TARGET_DISPOSABLE"),
		dbHost:               os.Getenv("DB_HOST"),
		dbPort:               os.Getenv("DB_PORT"),
		dbUser:               os.Getenv("DB_USER"),
		dbPassword:           os.Getenv("DB_PASSWORD"),
		dbName:               os.Getenv("DB_NAME"),
		dbSSLMode:            os.Getenv("DB_SSLMODE"),
		dbSSLRootCertificate: os.Getenv("DB_SSLROOTCERT"),
	}
	if err := target.validate(); err != nil {
		return seedTargetConfig{}, err
	}
	return target, nil
}

func (target *seedTargetConfig) validate() error {
	if err := config.ValidateEnvironmentModeValue(target.appEnv); err != nil {
		return fmt.Errorf("APP_ENV wajib diatur ke mode yang didukung")
	}
	if !strings.EqualFold(strings.TrimSpace(target.appEnv), "development") {
		return fmt.Errorf("Seeder hanya diizinkan pada APP_ENV=development")
	}
	if !strings.EqualFold(strings.TrimSpace(target.allowDestructive), "true") {
		return fmt.Errorf("SEED_ALLOW_DESTRUCTIVE=true wajib untuk menjalankan seeder")
	}
	if !strings.EqualFold(strings.TrimSpace(target.targetDisposable), "true") {
		return fmt.Errorf("SEED_TARGET_DISPOSABLE=true wajib untuk target fixture disposable")
	}

	missing := make([]string, 0)
	for name, value := range map[string]string{
		"DB_HOST":     target.dbHost,
		"DB_PORT":     target.dbPort,
		"DB_USER":     target.dbUser,
		"DB_PASSWORD": target.dbPassword,
		"DB_NAME":     target.dbName,
	} {
		if strings.TrimSpace(value) == "" {
			missing = append(missing, name)
		}
	}
	if len(missing) > 0 {
		sort.Strings(missing)
		return fmt.Errorf("konfigurasi seeder belum lengkap: %s", strings.Join(missing, ", "))
	}

	port, err := strconv.Atoi(target.dbPort)
	if err != nil || port < 1 || port > 65535 {
		return fmt.Errorf("DB_PORT tidak valid")
	}

	sslMode := strings.ToLower(strings.TrimSpace(target.dbSSLMode))
	if sslMode == "" {
		sslMode = "disable"
	}
	switch sslMode {
	case "disable":
		target.dbSSLMode = sslMode
	case "verify-full":
		if err := validateSeedRootCertificate(target.dbSSLRootCertificate); err != nil {
			return err
		}
		target.dbSSLMode = sslMode
	default:
		return fmt.Errorf("DB_SSLMODE seeder harus disable atau verify-full")
	}
	return nil
}

func validateSeedRootCertificate(path string) error {
	if strings.TrimSpace(path) == "" {
		return fmt.Errorf("DB_SSLROOTCERT wajib untuk DB_SSLMODE=verify-full")
	}
	file, err := os.Open(path)
	if err != nil {
		return fmt.Errorf("DB_SSLROOTCERT tidak dapat dibaca")
	}
	info, statErr := file.Stat()
	closeErr := file.Close()
	if statErr != nil || closeErr != nil || !info.Mode().IsRegular() {
		return fmt.Errorf("DB_SSLROOTCERT tidak valid")
	}
	return nil
}
