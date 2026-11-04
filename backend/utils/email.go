package utils

import (
	"os"
	"gopkg.in/mail.v2"
)

func SendEmail(to, subject, body string) error {
	m := mail.NewMessage()
	m.SetHeader("From", "noreply@edutrack.com") // Bebas mau diisi apa
	m.SetHeader("To", to)
	m.SetHeader("Subject", subject)
	m.SetBody("text/plain", body)

	// Ambil host dan port dari environment
	host := os.Getenv("SMTP_HOST")
	port := 1025 // Default port Mailpit

	// Karena Mailpit lokal tidak butuh password, kita kosongkan auth-nya
	d := mail.NewDialer(host, port, "", "")
	d.StartTLSPolicy = mail.OpportunisticStartTLS // Mailpit tidak pakai TLS wajib

	return d.DialAndSend(m)
}