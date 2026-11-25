package config

import (
	"encoding/json"
	"os"
	"strconv"
	"strings"
	"time"
)

type AcademicPeriod struct {
	Year     string `json:"year"`
	Semester string `json:"semester"`
}

func AcademicTermBefore(leftYear, leftSemester, rightYear, rightSemester string) bool {
	if leftYear != rightYear {
		return leftYear < rightYear
	}
	leftOrder := academicSemesterOrder(leftSemester)
	rightOrder := academicSemesterOrder(rightSemester)
	if leftOrder != rightOrder {
		return leftOrder < rightOrder
	}
	return strings.ToLower(leftSemester) < strings.ToLower(rightSemester)
}

func academicSemesterOrder(semester string) int {
	switch strings.ToLower(strings.TrimSpace(semester)) {
	case "ganjil":
		return 0
	case "genap":
		return 1
	default:
		return 2
	}
}

func AcademicPeriodNow() AcademicPeriod {
	year := os.Getenv("ACADEMIC_ACTIVE_YEAR")
	semester := os.Getenv("ACADEMIC_ACTIVE_SEMESTER")
	if semester == "" {
		now := time.Now().In(time.FixedZone("WIB", 7*3600))
		if now.Month() >= time.July {
			semester = "Ganjil"
			if year == "" {
				year = strconv.Itoa(now.Year()) + "/" + strconv.Itoa(now.Year()+1)
			}
		} else {
			semester = "Genap"
			if year == "" {
				year = strconv.Itoa(now.Year()-1) + "/" + strconv.Itoa(now.Year())
			}
		}
	}
	if year == "" {
		now := time.Now().In(time.FixedZone("WIB", 7*3600))
		year = strconv.Itoa(now.Year()) + "/" + strconv.Itoa(now.Year()+1)
	}
	return AcademicPeriod{Year: year, Semester: semester}
}

func GradePoints() map[string]float64 {
	defaults := map[string]float64{"A": 4, "AB": 3.7, "B": 3.3, "BC": 3, "C": 2.7, "D": 2, "E": 0}
	raw := os.Getenv("ACADEMIC_GRADE_POINTS")
	if raw == "" {
		return defaults
	}
	parsed := map[string]float64{}
	if err := json.Unmarshal([]byte(raw), &parsed); err != nil || len(parsed) == 0 {
		return defaults
	}
	return parsed
}

func PassingGrades() map[string]bool {
	defaults := map[string]bool{"A": true, "AB": true, "B": true, "BC": true, "C": true, "D": true, "E": false}
	raw := os.Getenv("ACADEMIC_PASSING_GRADES")
	if raw == "" {
		return defaults
	}
	parsed := map[string]bool{}
	if err := json.Unmarshal([]byte(raw), &parsed); err != nil || len(parsed) == 0 {
		return defaults
	}
	return parsed
}

func MaxSKS() int {
	value, err := strconv.Atoi(os.Getenv("ACADEMIC_MAX_SKS"))
	if err != nil || value < 1 {
		return 24
	}
	return value
}
