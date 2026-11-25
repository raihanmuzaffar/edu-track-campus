# Fitur Flutter Belum Terhubung / Dummy

Lampiran audit — 2026-11-19. Status dan penomoran mengikuti BAB 3 laporan utama. Tidak ada perubahan kode yang dilakukan.

## Ringkasan

| Kategori | Jumlah | ID fitur |
|---|---:|---|
| BELUM TERHUBUNG | 9 | F07, F16, F17, F19, F25, F26, F32, F37, F48 |
| BACKEND BELUM TERSEDIA | 7 | F03, F04, F08, F20, F27, F36, F38 |
| DUMMY/STATIC | 8 | F29, F40, F41, F42, F43, F44, F45, F47 |
| BERMASALAH (integrasi ada tapi cacat) | 5 | F09, F12, F15, F23, F24 |

---

## A. UI tersedia tetapi tidak terhubung (BELUM TERHUBUNG)

### F07 — Edit profil
- Lokasi: `mobile/lib/screens/dosen/profil_dosen_tab.dart:259-263`
- Kondisi: menu menampilkan snackbar "Fitur edit profil belum tersedia."
- Endpoint diperlukan: `PUT /api/v1/users/me`
- Tersedia: **tidak**
- Yang dibuat: DTO `UpdateProfileInput` di `backend/handlers/auth.go`, route terautentikasi di `main.go:236` area, form Flutter dengan prefill `/users/me`
- Prioritas: High

### F16 — Dashboard Admin & Kaprodi di Flutter
- Lokasi: tidak ada screen Flutter; hanya `mobile/lib/main.dart:71-88` untuk mahasiswa/dosen/orangtua
- Kondisi: peran admin/kaprodi tidak bisa masuk aplikasi mobile (`login_screen.dart:29-33`)
- Endpoint diperlukan: `/admin/stats`, `/admin/users`, `/admin/krs/list`, `/admin/grades/list`, `/admin/attendances/list`, `/admin/ukt/list`, dll.
- Tersedia: **ya**, tetapi hanya dipakai `web-admin/src/admin`, `web-admin/src/prodi`
- Yang dibuat: Flutter admin shell + navigasi peran, atau keputusan resmi bahwa web-admin adalah satu-satunya klien admin
- Prioritas: Medium

### F17 — Notifikasi/push
- Lokasi: tidak ada
- Endpoint diperlukan: `GET /api/v1/notifications` + push provider
- Tersedia: **tidak**; hanya pengumuman (`/admin/announcements/list`)
- Prioritas: Medium

### F19 — Data dosen (daftar/CRUD)
- Lokasi: tidak ada screen; dosen hanya nested di `Class.Dosen` (`backend/models/class.go:23`)
- Endpoint diperlukan: `GET /api/v1/admin/users?role=dosen` atau endpoint khusus
- Tersedia: sebagian (`/admin/users`, tanpa filter role di `admin.go:55-75`)
- Prioritas: Medium

### F25 — KRS ambil/enroll matkul
- Lokasi: `mobile/lib/screens/mahasiswa/krs_tab.dart:326` hanya pesan cetak tidak tersedia; tidak ada aksi enroll
- Endpoint diperlukan: `POST /api/v1/enrollments`
- Tersedia: **ya** (`main.go:174`, `enrollment.go:27-60`)
- Yang dibuat: tombol "Ambil kelas" + dialog pilih kelas dari `/classes/list`, kirim `class_id`
- Prioritas: High

### F26 — KHS
- Lokasi: tidak ada screen Flutter
- Endpoint diperlukan: `GET /api/v1/khs/my`
- Tersedia: hanya `/admin/khs/list` dan `/admin/khs/update` (`main.go:227-228`)
- Prioritas: High

### F32 — Presensi QR mahasiswa
- Lokasi: `mobile/lib/screens/mahasiswa/qr_scanner_screen.dart:5-57`
- Kondisi: screen memiliki kamera (`mobile_scanner`) dan `POST /qr/scan` di `:37`, tetapi tidak terdaftar di `main.dart:71-88` dan tidak direferensikan file lain
- Endpoint diperlukan: `POST /api/v1/qr/scan`
- Tersedia: **ya** (`main.go:240`, `qr.go:90-199`)
- Yang dibuat: route `/qr-scanner` + tombol pemindai di `absensi_tab.dart` menggantikan dialog simulasi `:608-667`
- Prioritas: Critical

### F37 — Pengelolaan akun & role di Flutter
- Lokasi: tidak ada
- Endpoint diperlukan: `/admin/users*`, tabel roles/permissions
- Tersedia: CRUD users saja; tidak ada roles/permissions (`models/user.go:5-22`)
- Prioritas: Medium

### F48 — Cetak KRS
- Lokasi: `mobile/lib/screens/mahasiswa/krs_tab.dart:326`
- Endpoint diperlukan: `GET /api/v1/krs/print` atau PDF generation
- Tersedia: **tidak**
- Prioritas: Low

---

## B. Flutter membutuhkan endpoint yang belum ada (BACKEND BELUM TERSEDIA)

| ID | Fitur | Bukti Flutter | Endpoint yang dibutuhkan | Prioritas |
|---|---|---|---|---|
| F03 | Logout server-side | `api_service.dart:163-169` hanya `prefs.remove` | `POST /logout` + pencabutan token | High |
| F04 | Refresh token | Tidak ada kode; JWT 24 jam di `config/jwt.go:18-30` | `POST /refresh-token` + rotasi | High |
| F08 | Ganti password terautentikasi | `dosen/profil_dosen_tab.dart:238-239` mengarah ke lupa password | `POST /change-password` | High |
| F20 | Program studi & fakultas | `dosen/profil_dosen_tab.dart:16-18` hardcoded | `GET /faculties`, `/study-programs` | Low |
| F27 | Transkrip nilai | Tidak ada screen/model | `GET /transcripts/my` | Medium |
| F36 | Kalender akademik | Tidak ada screen/model | `GET /academic-calendar` | Medium |
| F38 | Aktivasi akun | Tidak ada field status di `models/user.go` | `POST /users/activate` | Medium |

---

## C. Data dummy / statis (DUMMY/STATIC)

| ID | Fitur | Lokasi | Jenis | Endpoint yang seharusnya dipakai | Prioritas |
|---|---|---|---|---|---|
| F29 | Jadwal orang tua | `orang_tua/jadwal_tab.dart:16-71` | Data lokal + label DEMO | `/admin/schedules/list` (difilter kelas anak) | High |
| F40 | Profil anak | `orang_tua/profil_anak_tab.dart:24-33` | `OrangTuaDashboardData.empty` → empty state | `/parent/child/profile` (perlu dibuat) | High |
| F41 | Nilai anak | `orang_tua/nilai_tab.dart:24-79,181-193` | Data demo/empty | `/parent/child/grades` (**sudah ada**, `main.go:232`) | Critical |
| F42 | Absensi anak | `orang_tua/absensi_tab.dart:26-33,171-175` | Data demo/empty | `/parent/child/attendances` (**sudah ada**, `main.go:233`) | Critical |
| F43 | Keuangan/UKT | `orang_tua/keuangan_tab.dart:28-76` | Ringkasan lokal; menyatakan tidak ada pembayaran | `/student/ukt/my` (perlu dibuat) | High |
| F44 | Pengumuman orang tua | `orang_tua/pengumuman_tab.dart:21-58` | Daftar lokal | `/admin/announcements/list` (**sudah ada**) | High |
| F45 | Informasi orang tua | `orang_tua/informasi_tab.dart:72-117` | Hanya navigasi lokal; tanpa konten backend | Tidak ada (butuh desain konten) | Low |
| F47 | Dashboard demo mahasiswa | `mahasiswa_demo.dart:17-29`, `data/mahasiswa_demo_data.dart:4-405` | Demo disengaja, terdokumentasi | Tidak perlu — pertahankan sebagai preview | Low |

Akibat utama: pada jalur production Flutter, `OrangTuaDashboard` memakai `OrangTuaDashboardData.empty` (`orang_tua_dashboard.dart:27-29`), sehingga seluruh 9 tab orang tua tidak menampilkan data akun nyata meskipun backend memiliki endpoint parent.

---

## D. Integrasi ada tetapi bermasalah (BERMASALAH)

| ID | Fitur | Lokasi | Masalah | Prioritas |
|---|---|---|---|---|
| F09 | Lupa/reset password | `forgot_password_screen.dart:28-33` | Pengguna disuruh membaca log Docker untuk token reset, padahal backend mengirim email (`auth.go:171-183`) | High |
| F12 | Statistik IPK/SKS | `beranda_tab.dart:86-106` | IPK = rata-rata skor/100×4, bukan bobot SKS; SKS tidak difilter periode | High |
| F15 | NIDN/NIP dosen | `beranda_dosen_tab.dart:66` | Field tidak ada di `models/user.go:5-22`; probe mengonfirmasi | Medium |
| F23 | Tahun akademik & semester | `krs_tab.dart:139-157`, `nilai_tab.dart:65-85` | `class.year`/`class.semester` selalu kosong dari backend | Critical |
| F24 | KRS lihat | `krs_tab.dart:100-127` | Endpoint 200, tetapi period selector kosong sehingga daftar KRS tidak tampil | Critical |
