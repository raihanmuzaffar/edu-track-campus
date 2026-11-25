package main

import (
	"os"
	"path/filepath"
	"testing"
)

func validSeedTarget() seedTargetConfig {
	return seedTargetConfig{
		appEnv:           "development",
		allowDestructive: "true",
		targetDisposable: "true",
		dbHost:           "localhost",
		dbPort:           "5432",
		dbUser:           "seed-fixture-user",
		dbPassword:       "test-only",
		dbName:           "fixture",
		dbSSLMode:        "disable",
	}
}

func TestSeedGuardRequiresDevelopmentAndExplicitDisposableOptIns(t *testing.T) {
	tests := []struct {
		name   string
		change func(*seedTargetConfig)
	}{
		{name: "empty mode", change: func(target *seedTargetConfig) { target.appEnv = "" }},
		{name: "unknown mode", change: func(target *seedTargetConfig) { target.appEnv = "prod" }},
		{name: "production mode", change: func(target *seedTargetConfig) { target.appEnv = "production" }},
		{name: "missing destructive opt-in", change: func(target *seedTargetConfig) { target.allowDestructive = "" }},
		{name: "missing disposable declaration", change: func(target *seedTargetConfig) { target.targetDisposable = "" }},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			target := validSeedTarget()
			test.change(&target)
			if err := target.validate(); err == nil {
				t.Fatal("seed target unexpectedly passed safety guard")
			}
		})
	}
}

func TestSeedGuardAllowsExplicitDisposableDevelopmentTarget(t *testing.T) {
	target := validSeedTarget()
	if err := target.validate(); err != nil {
		t.Fatalf("seed target rejected: %v", err)
	}
}

func TestSeedGuardRequiresExplicitDatabaseConfiguration(t *testing.T) {
	target := validSeedTarget()
	target.dbPassword = ""
	if err := target.validate(); err == nil {
		t.Fatal("seed target without explicit database credentials passed safety guard")
	}
}

func TestSeedGuardAllowsVerifiedTLSOnlyWithReadableCA(t *testing.T) {
	target := validSeedTarget()
	target.dbSSLMode = "verify-full"
	if err := target.validate(); err == nil {
		t.Fatal("verified TLS without a CA file passed safety guard")
	}

	caFile := filepath.Join(t.TempDir(), "root-ca.pem")
	if err := os.WriteFile(caFile, []byte("test CA fixture"), 0o600); err != nil {
		t.Fatal("create CA fixture")
	}
	target.dbSSLRootCertificate = caFile
	if err := target.validate(); err != nil {
		t.Fatalf("verified TLS with readable CA was rejected: %v", err)
	}
}
