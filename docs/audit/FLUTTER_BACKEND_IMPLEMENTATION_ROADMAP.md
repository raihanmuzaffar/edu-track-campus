# Roadmap Integrasi Flutter EduTrack Campus – Backend

Lampiran audit — 2026-11-19. Urutan ini direkomendasikan karena beberapa perbaikan backend merupakan prasyarat agar perbaikan Flutter tidak ditulis ulang.

## Prinsip urutan

1. Perbaiki kontrak HTTP dan autentikasi antesebab seluruh penanganan error Flutter bergantung padanya.
2. Perbaiki data yang membuat fitur yang sudah terhubung menjadi tampak kosong (periode akademik).
3. Aktifkan fitur yang kodenya sudah ada tetapi tidak reachable (QR scanner).
4. Hubungkan modul yang benar-benar putus (Orang Tua).
5. Tambah endpoint/fitur baru setelah fondasi stabil.

---

## Tahap 1 — Fondasi kontrak HTTP & autentikasi (Critical)

| Item | Detail |
|---|---|
| Target | 65 route mematuhi method; error auth ber-JSON; Flutter menangani 401 dengan benar |
| File Flutter | `mobile/lib/services/api_service.dart`, `mobile/lib/screens/splash_screen.dart`, `mobile/lib/screens/login_screen.dart` |
| File backend | `backend/main.go`, `backend/middlewares/auth.go`, `backend/utils/response.go`, `backend/config/jwt.go` |
| Endpoint | semua route; tambahan `POST /logout`, `POST /refresh-token` |
| Kriteria keberhasilan | `GET /api/v1/login` → 405; `GET /users/me` tanpa token → JSON envelope dengan `message`; token kedaluwarsa memicu refresh sekali lalu logout & navigasi `/login` |
| Dependency | tidak ada |

**Pekerjaan:**
- [ ] Validasi `r.Method` atau migrasi ke router sadar-method.
- [ ] `utils.JSONResponse` untuk semua kegagalan middleware.
- [ ] `ApiResult<T>`/`tryRefresh()` di `ApiService`; hapus duplikasi `jsonDecode`.
- [ ] Simpan `refresh_token` terpisah; jangan pernah dicetak ke log.
- [ ] Endpoint logout dengan pencabutan token (Redis sudah tersedia tetapi belum dipakai).

---

## Tahap 2 — Periode akademik & akurasi dashboard (Critical/High)

| Item | Detail |
|---|---|
| Target | KRS dan Nilai menampilkan periode yang benar; IPK/SKS valid; jadwal sesuai mahasiswa |
| File Flutter | `mahasiswa/krs_tab.dart`, `mahasiswa/nilai_tab.dart`, `mahasiswa/beranda_tab.dart`, `dosen/beranda_dosen_tab.dart` |
| File backend | `handlers/class.go`, `seed/main.go`, `models/class.go`, `handlers/schedule.go`, migrasi baru |
| Endpoint | `POST /classes`, `GET /enrollments/my`, `GET /grades/my`, `GET /admin/schedules/list` |
| Kriteria keberhasilan | `class.year` dan `class.semester` tidak kosong; selector periode KRS terisi; jadwal mahasiswa hanya kelasnya; IPK dihitung dengan bobot SKS |
| Dependency | Tahap 1 |

**Pekerjaan:**
- [ ] Tambah `year`, `semester` ke `ClassInput` dan seeder; backfill data yang ada.
- [ ] Fallback sementara di Flutter: periode dari `schedule.semester` bila `class.year` kosong.
- [ ] Endpoint `/schedules/my` dengan filter kelas/enrollment mahasiswa.
- [ ] Kirim `page`/`limit` dari Flutter atau endpoint `/classes/mine` untuk dosen.
- [ ] Terapkan aturan konversi nilai → IPK yang disepakati.

---

## Tahap 3 — Aktifkan presensi QR mahasiswa (Critical)

| Item | Detail |
|---|---|
| Target | Tombol pemindai QR mahasiswa dapat dibuka dan menyimpan absensi |
| File Flutter | `main.dart`, `mahasiswa/absensi_tab.dart`, `mahasiswa/qr_scanner_screen.dart` |
| File backend | `handlers/qr.go` (opsional: validasi status sesi) |
| Endpoint | `POST /api/v1/qr/scan` |
| Kriteria keberhasilan | Scan token valid → 201/200 → absensi muncul di `/attendances/my`; token duplikat harian ditolak; token kedaluwarsa ditolak dengan pesan jelas |
| Dependency | Tahap 1 |

**Pekerjaan:**
- [ ] Daftarkan route `/qr-scanner` di `main.dart:71-88`.
- [ ] Ganti dialog simulasi di `absensi_tab.dart:608-667` dengan navigasi scanner.
- [ ] Tampilkan detail-error dari envelope backend, bukan string generik.
- [ ] Tambah anotasi Swagger untuk 4 route QR.

---

## Tahap 4 — Integrasi modul Orang Tua (Critical)

| Item | Detail |
|---|---|
| Target | 9 tab orang tua menampilkan data nyata, bukan `OrangTuaDashboardData.empty` |
| File Flutter | `orang_tua_dashboard.dart` + seluruh tab + widget + service baru `mobile/lib/services/parent_service.dart` |
| File backend | `handlers/parent.go`, baru `handlers/student_ukt.go`, `handlers/profile.go` |
| Endpoint | `GET /parent/child/grades`, `GET /parent/child/attendances`, `GET /users/me`, `GET /admin/announcements/list`, `GET /admin/schedules/list`, baru `GET /student/ukt/my`, `GET /parent/child/profile` |
| Kriteria keberhasilan | Tidak ada jalur production yang memakai `.empty`; data berubah setelah admin memperbarui nilai/absensi/pengumuman; error/empty state jelas |
| Dependency | Tahap 1, Tahap 2 |

**Pekerjaan:**
- [ ] Buat `ParentDashboardRepository` yang menggabungkan 5–7 endpoint.
- [ ] Terapkan state loading/error/empty per tab.
- [ ] Dukung beberapa anak (backend saat ini hanya mengambil relasi pertama: `parent.go:74,100`).
- [ ] Tambah endpoint UKT scoped untuk orang tua/mahasiswa.

---

## Tahap 5 — Lengkapi manajemen akun (High)

| Item | Detail |
|---|---|
| Target | Logout, refresh, ganti password, edit profil, aktivasi akun berfungsi penuh |
| File Flutter | `login_screen.dart`, `forgot_password_screen.dart`, `new_password_screen.dart`, `profil_tab.dart`, `profil_dosen_tab.dart`, `profil_orang_tua_tab.dart`, `splash_screen.dart` |
| File backend | `handlers/auth.go`, `main.go`, `middlewares/auth.go`, `handlers/admin.go`, `models/user.go` |
| Endpoint | baru `POST /logout`, `/refresh-token`, `/change-password`, `PUT /users/me`, `/users/activate` |
| Kriteria keberhasilan | Ganti password tanpa email; logout membuat token tidak valid; profil tersimpan di DB; reset token dikirim email dan tidak perlu dibaca dari log |
| Dependency | Tahap 1 |

---

## Tahap 6 — Fitur backend yang belum ada (Medium)

| Item | Detail |
|---|---|
| Target | KHS mahasiswa, transkrip, kalender akademik, notifikasi, dokumen upload, prodi/fakultas |
| File Flutter | screen baru di `mobile/lib/screens/`, `pubspec.yaml` jika butuh `file_picker`/`url_launcher` |
| File backend | model + handler + route baru; tabel migrasi |
| Endpoint | `GET /khs/my`, `GET /transcripts/my`, `GET /academic-calendar`, `GET /notifications`, `POST /documents/upload` (multipart), `GET /faculties`, `/study-programs` |
| Kriteria keberhasilan | Tiap screen Flutter menampilkan data dari endpoint nyata; upload berkas tersimpan & dapat diunduh; tidak ada angka statis |
| Dependency | Tahap 1 |

---

## Tahap 7 — Kualitas dan pengujian (Medium/Low)

| Item | Detail |
|---|---|
| Target | Analisis bersih dan jaminan otomatis untuk alur yang sudah terhubung |
| File Flutter | seluruh `mobile/lib`, `mobile/test/` |
| File backend | `backend/handlers/*_test.go`, test kontrak baru |
| Endpoint | 17 endpoint yang dipakai Flutter memiliki test kontrak |
| Kriteria keberhasilan | `flutter analyze` 0 issue; test widget/service untuk KRS, Nilai, Absensi, QR, dan parent; test backend tidak melakukan TRUNCATE pada lingkungan bersama |
| Dependency | Tahap 1–6 |

---

## Tahap 8 — Dokumentasi dan portabilitas (Low)

| Item | Detail |
|---|---|
| Target | Kontrak API terdokumentasi penuh dan konfigurasi tidak bergantung pada emulator |
| File Flutter | `mobile/lib/services/api_service.dart`, `mobile/pubspec.yaml` |
| File backend | `backend/docs/`, `.env.example` |
| Endpoint | 65/65 route terdokumentasi di Swagger dengan skema `data` per endpoint |
| Kriteria keberhasilan | Base URL dari `--dart-define`; tidak ada `DummyDashboard`/tombol no-op; `.env.example` hanya berisi nama variabel; Swagger dapat diakses sesuai dokumentasi |
| Dependency | Tahap 1 |

---

## Checklist prioritas ringkas

### Critical
- [ ] Penegakan HTTP method (65 route)
- [ ] Envelope JSON untuk 401/403 + penanganan 401 di Flutter
- [ ] Isi `Class.year`/`semester` + backfill
- [ ] Route & navigasi QR scanner mahasiswa
- [ ] Integrasi 9 tab orang tua
- [ ] Perbaiki periode KRS/Nilai yang kosong

### High
- [ ] Logout/refresh/change-password/update profil
- [ ] Endpoint UKT & KHS scoped untuk mahasiswa/orang tua
- [ ] Filter jadwal per mahasiswa
- [ ] Pagination dari Flutter / endpoint "kelas saya"
- [ ] IPK berbasis bobot SKS
- [ ] NIDN/NIP atau ganti field yang tersedia
- [ ] Validasi sesi QR server-side
- [ ] Alur reset password via email

### Medium
- [ ] Nilai komponen, kalender, transkrip, notifikasi
- [ ] Flutter admin shell atau dokumentasi pembagian klien
- [ ] Migrasi SQL versi-terkontrol
- [ ] Swagger lengkap 65/65 + skema data
- [ ] Base URL via `--dart-define`
- [ ] Validasi DTO & batas pagination
- [ ] Widget state standar (loading/empty/error)

### Low
- [ ] Hapus/implementasikan tombol sosial login
- [ ] Hapus `DummyDashboard`
- [ ] Hilangkan label simulasi setelah QR aktif
- [ ] `.env.example` tanpa nilai
- [ ] Beri label demo pada web-admin preview
