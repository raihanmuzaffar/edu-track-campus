package config

import "testing"

func TestAcademicTermBefore(t *testing.T) {
	tests := []struct {
		name                     string
		leftYear, leftSemester   string
		rightYear, rightSemester string
		want                     bool
	}{
		{
			name:          "earlier year sorts first",
			leftYear:      "2024/2025",
			leftSemester:  "Genap",
			rightYear:     "2025/2026",
			rightSemester: "Ganjil",
			want:          true,
		},
		{
			name:          "ganjil sorts before genap in same year",
			leftYear:      "2025/2026",
			leftSemester:  "Ganjil",
			rightYear:     "2025/2026",
			rightSemester: "Genap",
			want:          true,
		},
		{
			name:          "equal terms are not ordered before each other",
			leftYear:      "2025/2026",
			leftSemester:  "Ganjil",
			rightYear:     "2025/2026",
			rightSemester: "Ganjil",
			want:          false,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			got := AcademicTermBefore(
				test.leftYear,
				test.leftSemester,
				test.rightYear,
				test.rightSemester,
			)
			if got != test.want {
				t.Fatalf("AcademicTermBefore() = %t, want %t", got, test.want)
			}
		})
	}
}
