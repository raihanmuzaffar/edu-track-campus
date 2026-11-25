package utils

import (
	"fmt"
	"os"
	"strconv"

	"github.com/raihanmuzaffar/edu-track-campus/backend/config"
	"gopkg.in/mail.v2"
)

func SendEmail(to, subject, body string) error {
	host := os.Getenv("SMTP_HOST")
	if host == "" {
		return fmt.Errorf("SMTP_HOST belum dikonfigurasi")
	}
	port := 1025
	if configured, err := strconv.Atoi(os.Getenv("SMTP_PORT")); err == nil && configured > 0 {
		port = configured
	}
	username := os.Getenv("SMTP_USERNAME")
	password := os.Getenv("SMTP_PASSWORD")
	from := os.Getenv("SMTP_FROM")
	if from == "" {
		if config.IsProductionEnvironment() {
			return fmt.Errorf("SMTP_FROM belum dikonfigurasi")
		}
		from = "noreply@edutrack.local"
	}

	m := mail.NewMessage()
	m.SetHeader("From", from)
	m.SetHeader("To", to)
	m.SetHeader("Subject", subject)
	m.SetBody("text/plain", body)

	d := mail.NewDialer(host, port, username, password)
	d.StartTLSPolicy = mail.OpportunisticStartTLS
	if config.IsProductionEnvironment() {
		d.StartTLSPolicy = mail.MandatoryStartTLS
	}
	return d.DialAndSend(m)
}
