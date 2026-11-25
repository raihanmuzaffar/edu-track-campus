package main

import (
	"context"
	"io"
	"testing"
)

func TestDatabaseLoggerRedactsQueryParameters(t *testing.T) {
	queryLogger := newDatabaseLogger(io.Discard)
	filter, ok := queryLogger.(interface {
		ParamsFilter(context.Context, string, ...interface{}) (string, []interface{})
	})
	if !ok {
		t.Fatal("database logger does not support parameter filtering")
	}

	const query = "SELECT * FROM users WHERE email = ?"
	filteredQuery, params := filter.ParamsFilter(context.Background(), query, "sensitive-value")
	if filteredQuery != query {
		t.Fatalf("query = %q, want unchanged parameterized SQL %q", filteredQuery, query)
	}
	if len(params) != 0 {
		t.Fatalf("logger retained %d query parameters, want none", len(params))
	}
}
