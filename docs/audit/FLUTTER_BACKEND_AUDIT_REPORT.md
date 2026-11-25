# Audit Integrasi Flutter EduTrack Campus dengan Backend Golang

- Tanggal audit: 2026-11-19
- Repository: `/home/raihan/Documents/edutrack`
- Ruang lingkup: seluruh source Flutter (`mobile/`), seluruh source backend Go (`backend/`), konfigurasi terkait (`docker/`, `README.md`), dan `web-admin/` sebagai konteks produk.
- Metode: inspeksi statis seluruh file sumber + probe API **read-only** terhadap server yang berjalan di `127.0.0.1:8080`. Tidak ada perubahan kode, konfigurasi, atau database. Tidak ada operasi destruktif.
- Kredensial, secret, dan nilai environment sensitif **sengaja tidak dicantumkan** dalam dokumen ini.

---

## BAB 1 — Ringkasan Eksekutif

### 1.1 Kondisi umum

Integrasi Flutter–backend **tidak merata**. Modul **Mahasiswa** dan **Dosen** sebagian besar sudah memanggil API nyata dan responsnya diolah menjadi UI. Modul **Orang Tua** di production justru memakai objek data kosong/local (`OrangTuaDashboardData.empty`) dan seluruh kontennya bersifat statis, meskipun backend sudah menyediakan endpoint khusus orang tua. Tidak ada halaman admin/kaprodi di Flutter; permukaan itu ada di `web-admin/`.

Backend terimplementasi dengan baik di level handler–GORM (65 route terdaftar, semua handler ada), tetapi ada kelemahan kontrak yang serius: **tidak ada penegakan HTTP method** sehingga semua verb diterima oleh semua route, autentikasi gagal mengembalikan teks biasa (bukan envelope JSON), serta tidak ada refresh token, logout server-side, atau ganti password.

### 1.2 Angka audit

| Metrik | Jumlah | Catatan |
|---|---:|---|
| File Dart di `mobile/lib` | 44 | Termasuk 2 file data demo dan 1 file demo entry point |
| Unit fitur Flutter yang dinilai | 48 | Didefinisikan dalam BAB 3; satu unit = satu alur/fitur yang dapat diuji |
| **TERHUBUNG** | **11** | API dipanggil, respons diolah, dan terverifikasi lewat probe read-only |
| **TERHUBUNG SEBAGIAN** | **7** | Ada pemanggilan API, tetapi sebagian alur/operasi belum ada atau belum terverifikasi |
| **BELUM TERHUBUNG** | **9** | UI/adanya fitur tetapi tidak ada integrasi, atau tombol dead-end |
| **DUMMY/STATIC** | **8** | Data lokal/hardcoded, termasuk demo yang memang disengaja |
| **BACKEND BELUM TERSEDIA** | **7** | Flutter memerlukan endpoint yang tidak ada di backend |
| **BERMASALAH** | **5** | Integrasi ada tetapi ada ketidaksesuaian/bug yang mengganggu |
| **BELUM DAPAT DIVERIFIKASI** | **1** | Register: kontrak cocok, tetapi tidak dieksekusi karena akan menulis data |
| Route backend terdaftar | 65 | Semua handler real; 2 dashboard bersifat statis |
| Endpoint unik yang dipanggil Flutter | 17 | 14 GET + 3 POST (termasuk 4 endpoint auth publik) |
| Endpoint backend tidak dipakai Flutter | 48 | TERMASUK endpoint yang dipakai `web-admin` |
| Endpoint backend terdokumentasi Swagger | 57 | 8 route tidak didokumentasikan |
| Temuan masalah integrasi | 34 | BAB 9 |
| Test Flutter | 1 | Hanya `expect(1 + 1, 2)` |

### 1.3 Hasil pemeriksaan teknis yang dijalankan

| Pemeriksaan | Hasil |
|---|---|
| `flutter analyze --no-fatal-infos --no-fatal-warnings` (`mobile/`) | Lulus; 3 info `curly_braces_in_flow_control_structures` di `login_screen.dart:31-33` |
| `go build ./...` (`backend/`) | Lulus, tanpa output error |
| `GET /api/health` | HTTP 200 |
| Login 4 peran (admin, kaprodi, dosen, mahasiswa) lewat probe read-only | HTTP 200, envelope `{status, message, data:{token, role}}` sesuai `api_service.dart:20-28` |
| Probe GET terautentikasi | `/users/me`, `/enrollments/my`, `/grades/my`, `/attendances/my`, `/admin/schedules/list`, `/admin/announcements/list`, `/classes/list`, `/classes/students`, `/admin/stats`, `/admin/ukt/list`, `/admin/khs/list`, `/admin/qr/active`, `/mobile/dashboard` semuanya HTTP 200 |
| Cek otorisasi | Mahasiswa mendapat 403 untuk `/admin/stats`, `/admin/users`, `POST /grades` (akses GET yang digunakan untuk probing) |
| Cek penegakan method | `GET /api/v1/login` menghasilkan 400 "Format JSON tidak valid", bukan 405 → mengonfirmasi tidak ada penegakan method |
| `go test ./handlers/...` | **Tidak dijalankan**: test melakukan `TRUNCATE` pada database uji (`handlers/all_test.go:54,80`) dan mensyaratkan DSN khusus |
| Build Flutter / unit test / inspeksi UI browser | Tidak dijalankan; tidak ada bukti visual yang diklaim dalam laporan ini |

### 1.4 Temuan paling kritis (ringkas)

1. **`Class.year` dan `Class.semester` tidak pernah diisi** oleh handler maupun seeder, tetapi KRS dan Nilai Flutter menggantungkan pembentukan periode pada kedua field ini. Probe langsung mengembalikan `year: ""`, `semester: ""` (`backend/seed/main.go:100-105`, `backend/handlers/class.go:48-51`, `mobile/lib/screens/mahasiswa/krs_tab.dart:139-157`).
2. **Tidak ada penegakan HTTP method** pada 65 route (`backend/main.go:123-242`). Contoh: `DELETE /api/v1/courses` akan masuk ke `CreateCourse`.
3. **Respons 401/403 middleware berupa plain text** (`backend/middlewares/auth.go:28,42,56`), sedangkan Flutter melakukan `jsonDecode` tanpa pengecekan content-type (`mobile/lib/services/api_service.dart:125,150`). Token kedaluwarsa menghasilkan pesan generik, bukan navigasi login.
4. **Modul Orang Tua tidak terhubung** sama sekali di production (`mobile/lib/screens/orang_tua/orang_tua_dashboard.dart:27-29`), padahal backend punya `/parent/child/grades` dan `/parent/child/attendances`.
5. **QR scanner mahasiswa tidak bisa dibuka** dari mana pun (`mobile/lib/screens/mahasiswa/qr_scanner_screen.dart` hanya mereferensikan dirinya sendiri).
6. **Lupa password menginstruksikan pengguna membaca log Docker** untuk mendapatkan token reset (`mobile/lib/screens/forgot_password_screen.dart:28-33`), bukan email.

---

## BAB 2 — Arsitektur Sistem

### 2.1 Arsitektur Flutter

- Entry point `mobile/lib/main.dart:14-16`; `MaterialApp` dengan 11 named route terdaftar (`main.dart:70-88`).
- Tidak ada state management eksternal (tanpa Provider/Riverpod/BLoC). Setiap `StatefulWidget` memanggil `ApiService` static dan menyimpan hasil di `setState`.
- Satu-satunya lapisan akses data: `mobile/lib/services/api_service.dart` (182 baris) dengan `http` + `shared_preferences` (`mobile/pubspec.yaml:19-20`).
- Tidak ada model Dart bertipe `class` dengan `fromJson`/`toJson`; respons dikonsumsi sebagai `Map<String, dynamic>`/`List<dynamic>` secara langsung, dengan helper `_map`, `_value`, `_nonEmptyText` yang tersebar di tiap screen.
- Dashboard memakai `IndexedStack` untuk tab: `mahasiswa_dashboard.dart:27-38`, `dosen_dashboard.dart:44-51`, `orang_tua_dashboard.dart:39-51`.
- `DummyDashboard` di `main.dart:96-137` tidak terdaftar sebagai route dan tidak dipakai.

### 2.2 Arsitektur backend

- Go `net/http` + `http.DefaultServeMux` (bukan Gin, meskipun `docker/docker-compose.yml:52` melabelinya "Gin"), GORM + PostgreSQL (`backend/main.go:3-21,79-97,123-242,247,251`).
- Tidak ada layer service/repository/usecase; 61 handler method menerima `*gorm.DB` langsung, mis. `backend/handlers/auth.go:18-20`, `backend/handlers/qr.go:26-28`.
- Skema dibuat otomatis via `AutoMigrate` 15 model saat startup (`main.go:79-97`). Tidak ada file migrasi/SQL di repository.
- Envelope respons tunggal: `{status, message, data}` dengan `data` dihilangkan jika nil (`backend/utils/response.go:8-22`).
- Pagination `page`/`limit` dengan default 1/10, tanpa batas maksimal (`backend/utils/pagination.go:8-23`).
- Middleware global CORS (`*` origin) membungkus mux; `OPTIONS` dijawab sebelum auth (`main.go:247`, `middlewares/cors.go:5-19`).
- Redis dibuat dan di-`Ping` tetapi tidak digunakan untuk sesi/token (`main.go:23,62-74`).

### 2.3 Alur komunikasi Flutter → backend

```
Widget StatefulWidget
  -> ApiService.get/post(endpoint, body)         mobile/lib/services/api_service.dart:114-160
  -> SharedPreferences.getString('token')        api_service.dart:172-175
  -> Authorization: Bearer <token>               api_service.dart:121,145
  -> http://10.0.2.2:8080/api/v1<endpoint>       api_service.dart:9,118,142
  -> CORS -> AuthMiddleware(role...)             backend/main.go:247,153-242
  -> Handler -> GORM -> PostgreSQL
  -> utils.JSONResponse                          backend/utils/response.go:8-22
  -> jsonDecode -> response['data'] -> setState
```

### 2.4 Base URL dan environment

| Client | Base URL | Bukti |
|---|---|---|
| Flutter | `http://10.0.2.2:8080/api/v1` (hardcoded, komentar manual untuk HP fisik) | `mobile/lib/services/api_service.dart:6-9` |
| Web admin | `http://localhost/api/v1` (lewats Nginx port 80) | `web-admin/src/services/api.js:3-6` |
| Swagger | `host: localhost:8080`, `basePath: /api/v1` | `backend/main.go:25-39`, `backend/docs/swagger.json:2-9` |
| Nginx | Hanya `location /api/` yang diproksikan; **tanpa** `location /swagger/` | `docker/nginx/nginx.conf:12-25` |

Nama environment variable yang terdeteksi (tanpa nilai): `DB_HOST`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`, `DB_PORT`, `JWT_SECRET`, `REDIS_HOST`, `REDIS_PORT`, `SMTP_HOST`, `SMTP_PORT`, `EDUTRACK_TEST_DATABASE_DSN`. Sumber: `docker/docker-compose.yml:7-9,59-68`, `backend/config/jwt.go:10`, `backend/utils/email.go:16`, `backend/handlers/all_test.go:26`. Tidak ada `.env.example`. Flutter/web-admin **tidak** membaca environment variable sama sekali.

### 2.5 Authentication flow

1. `POST /api/v1/login` → handler mencari user, membandingkan bcrypt, membuat JWT HS256 berlaku 24 jam (`backend/handlers/auth.go:101-135`, `backend/config/jwt.go:18-30`).
2. Flutter menyimpan `token`, `role`, `email` ke `SharedPreferences` (`api_service.dart:24-27`).
3. `SplashScreen` melakukan delay 2 detik lalu memilih route dari `isFirstTime`, `token`, dan `role` lokal (`mobile/lib/screens/splash_screen.dart:21-44`). **Tidak ada validasi token ke server.**
4. Setiap request protected mengirim Bearer token; middleware mem-parse JWT, membandingkan peran dari claim dengan allow-list route, lalu menyuntik `UserIDKey`/`RoleKey` ke context (`backend/middlewares/auth.go:22-68`).
5. Logout hanya menghapus tiga kunci lokal (`api_service.dart:163-169`); token tetap valid hingga kedaluwarsa karena backend tidak memiliki blacklist/revocation.
6. Tidak ada refresh token, tidak ada endpoint logout, tidak ada endpoint ganti password terautentikasi.

---

## BAB 3 — Inventarisasi Semua Modul Flutter

Status mengikuti definisi pada prompt. `ApiService.*` merujuk ke `mobile/lib/services/api_service.dart`.

| No | Modul | Screen/Fitur | File Flutter | Service/Repository | Status | Keterangan |
|---:|---|---|---|---|---|---|
| F01 | Autentikasi | Login | `mobile/lib/screens/login_screen.dart:20-40` | `ApiService.login` | TERHUBUNG | Probe 4 peran HTTP 200; token/role tersimpan. Dua tombol sosial no-op di `:134,144`. |
| F02 | Autentikasi | Register | `mobile/lib/screens/register_screen.dart:16-40` | `ApiService.register` | BELUM DAPAT DIVERIFIKASI | Kontrak cocok dengan `auth.go:22-27,53-89`; tidak dieksekusi karena akan membuat user. |
| F03 | Autentikasi | Logout | `mobile/lib/screens/mahasiswa/profil_tab.dart:78`, `dosen/profil_dosen_tab.dart:242`, `orang_tua/profil_orang_tua_tab.dart:74` | `ApiService.logout` | BACKEND BELUM TERSEDIA | Hanya `prefs.remove` (`api_service.dart:163-169`); tidak ada route logout. |
| F04 | Autentikasi | Refresh token | — | — | BACKEND BELUM TERSEDIA | Tidak ada kode Flutter, kunci penyimpanan, atau endpoint. JWT 24 jam tanpa perpanjangan. |
| F05 | Autentikasi | Penyimpanan token & pengecekan sesi splash | `mobile/lib/screens/splash_screen.dart:21-44`, `welcome_screen.dart:8-14` | `SharedPreferences` via `ApiService` | TERHUBUNG SEBAGIAN | Token dipakai request berhasil, tetapi sesi tidak divalidasi ke server. |
| F06 | Autentikasi | Profil pengguna (baca) | `mahasiswa/beranda_tab.dart:80-84`, `dosen/beranda_dosen_tab.dart:46-49`, `dosen/profil_dosen_tab.dart:214` | `GET /users/me` | TERHUBUNG | Probe 200; field `name`, `nim`, `program_studi` hadir. |
| F07 | Autentikasi | Edit profil | `dosen/profil_dosen_tab.dart:259-263` | — | BELUM TERHUBUNG | Menu menampilkan "Fitur edit profil belum tersedia"; tidak ada DTO/endpoint update profil. |
| F08 | Autentikasi | Ganti password (terautentikasi) | `dosen/profil_dosen_tab.dart:238-239` | — | BACKEND BELUM TERSEDIA | Menu "ubah password" mengarah ke lupa password; tidak ada endpoint change-password. |
| F09 | Autentikasi | Lupa/reset password | `forgot_password_screen.dart:18-40`, `new_password_screen.dart:21-45` | `ApiService.forgotPassword`, `.resetPassword` | BERMASALAH | Kontrak request/response sesuai backend; UX meminta token dari log Docker, bukan email. Tidak dijalankan (menulis token reset). |
| F10 | Autentikasi | Role & permission | `login_screen.dart:26-33`, `splash_screen.dart:23-44` | `ApiService.getRole` | TERHUBUNG SEBAGIAN | Role dari JWT dipakai untuk routing; keputusan UI juga bergantung role lokal yang dapat berubah. |
| F11 | Dashboard | Dashboard Mahasiswa (ringkasan) | `mahasiswa/beranda_tab.dart:80-129` | 5 endpoint GET | TERHUBUNG | Semua endpoint ter-probe 200 dan dipetakan ke state. |
| F12 | Dashboard | Statistik IPK & total SKS | `mahasiswa/beranda_tab.dart:86-106,469-479` | Turunan `/enrollments/my`, `/grades/my` | BERMASALAH | IPK = rata-rata skor/100×4, bukan rerata bobot SKS; SKS menjumlahkan seluruh KRS tanpa filter periode. |
| F13 | Dashboard | Ringkasan jadwal & pengumuman mahasiswa | `mahasiswa/beranda_tab.dart:108-116,552-566` | `GET /admin/schedules/list`, `/admin/announcements/list` | TERHUBUNG | Data tampil; tetapi daftar jadwal bersifat global (lihat I09). |
| F14 | Dashboard | Dashboard Dosen | `dosen/beranda_dosen_tab.dart:38-80` | `GET /users/me`, `/classes/list` | TERHUBUNG | Kedua endpoint ter-probe 200; kelas difilter oleh `dosen_id`. |
| F15 | Dashboard | Identitas NIDN/NIP dosen | `dosen/beranda_dosen_tab.dart:66` | Turunan `/users/me` | BERMASALAH | Flutter membaca `nidn`/`nip`; `models/user.go:5-22` hanya punya `nim`. Probe mengonfirmasi field tidak ada. |
| F16 | Dashboard | Dashboard Admin & Kaprodi (Flutter) | — | — | BELUM TERHUBUNG | Tidak ada screen Flutter untuk peran ini; tersedia di `web-admin/src/admin`, `web-admin/src/prodi`. |
| F17 | Dashboard | Notifikasi/push | — | — | BELUM TERHUBUNG | Backend hanya menyediakan pengumuman; tidak ada push/notification endpoint. |
| F18 | Akademik | Daftar mahasiswa dalam kelas (dosen) | `dosen/nilai_dosen_tab.dart:131-133`, `dosen/absensi_dosen_tab.dart:365-367` | `GET /classes/students` | TERHUBUNG | Probe 200; respons berupa enrollment dengan nested `mahasiswa`. |
| F19 | Akademik | Data dosen (daftar/CRUD) | — | — | BELUM TERHUBUNG | Dosen hanya muncul nested di `Class.Dosen`; tidak ada halaman Flutter. |
| F20 | Akademik | Data program studi & fakultas | `dosen/profil_dosen_tab.dart:16-18` | — | BACKEND BELUM TERSEDIA | Hanya string `program_studi` pada `models/user.go:14`; tidak ada model/route prodi/fakultas. |
| F21 | Akademik | Data kelas (baca) | `dosen/beranda_dosen_tab.dart:51-60`, `mahasiswa/absensi_tab.dart:104` | `GET /classes/list` | TERHUBUNG | Probe 200 dengan envelope pagination `{data:{data,...},total_data,page,limit}`. |
| F22 | Akademik | Data mata kuliah | Turunan `class.course`, `grade.class.course`, `schedule.course` | `GET /classes/list`, `/grades/my`, `/admin/schedules/list` | TERHUBUNG SEBAGIAN | Tampil sebagai data nested; tidak ada halaman/CRUD mata kuliah di Flutter. |
| F23 | Akademik | Tahun akademik & semester | `mahasiswa/krs_tab.dart:139-157`, `nilai_tab.dart:65-85` | Turunan `class.year`, `class.semester` | BERMASALAH | Field tidak pernah diisi backend; probe menghasilkan string kosong. |
| F24 | Akademik | KRS — lihat | `mahasiswa/krs_tab.dart:100-127` | `GET /enrollments/my` | BERMASALAH | Endpoint 200, tetapi pemilih periode tidak punya data sehingga daftar KRS berakhir di empty state. |
| F25 | Akademik | KRS — ambil/enroll matkul | `mahasiswa/krs_tab.dart:326` (cetak tidak tersedia) | — | BELUM TERHUBUNG | Tidak ada pemanggilan `POST /enrollments` di Flutter, padahal endpoint tersedia. |
| F26 | Akademik | KHS | — | — | BELUM TERHUBUNG | Tidak ada screen Flutter; backend hanya `/admin/khs/list` dan `/admin/khs/update`. |
| F27 | Akademik | Transkrip nilai | — | — | BACKEND BELUM TERSEDIA | Tidak ada model, route, atau handler transkrip. |
| F28 | Akademik | Jadwal kuliah mahasiswa | `mahasiswa/beranda_tab.dart:108-110,552-566` | `GET /admin/schedules/list` | TERHUBUNG | Probe 200; field `course.name`, `day`, `start_time`, `end_time`, `room` sesuai model. |
| F29 | Akademik | Jadwal kuliah orang tua | `orang_tua/jadwal_tab.dart:16-71` | `OrangTuaDashboardData` | DUMMY/STATIC | Production memakai data kosong; demo memakai daftar lokal; tidak ada API call. |
| F30 | Akademik | Riwayat presensi mahasiswa | `mahasiswa/absensi_tab.dart:95-124` | `GET /attendances/my`, `/enrollments/my` | TERHUBUNG | Kedua endpoint ter-probe 200; dikelompokkan per kelas/matkul. |
| F31 | Akademik | Input presensi manual dosen | `dosen/absensi_dosen_tab.dart:604-621` | `POST /attendances` | TERHUBUNG SEBAGIAN | Payload sesuai DTO; tidak dieksekusi karena akan menulis data. Tidak ada guard duplikat di backend. |
| F32 | Akademik | Presensi QR mahasiswa (scanner) | `mahasiswa/qr_scanner_screen.dart:27-57` | `POST /qr/scan` | BELUM TERHUBUNG | Screen tidak terdaftar/terreferensi; tidak bisa dibuka dari aplikasi. |
| F33 | Akademik | Generate/tutup QR dosen | `dosen/qr_generator_screen.dart:211-213,365` | `POST /qr/generate`, `/qr/close` | TERHUBUNG SEBAGIAN | Kontrak sesuai; sesi disimpan lokal. Tidak dieksekusi (menulis sesi QR). |
| F34 | Akademik | Input nilai dosen | `dosen/nilai_dosen_tab.dart:1030-1054` | `POST /grades` | TERHUBUNG SEBAGIAN | Payload `mahasiswa_id,class_id,score,letter` sesuai `grade.go:17-22`; tidak dieksekusi. |
| F35 | Akademik | Nilai mahasiswa | `mahasiswa/nilai_tab.dart:31-59` | `GET /grades/my` | TERHUBUNG | Probe 200; tampil setelah dikelompokkan (masalah periode ada di F23). |
| F36 | Akademik | Kalender akademik | — | — | BACKEND BELUM TERSEDIA | Tidak ada entity/route kalender; pengumuman punya tanggal tetapi bukan kalender. |
| F37 | Pengguna | Pengelolaan akun & role (Flutter) | — | — | BELUM TERHUBUNG | Backend punya CRUD `/admin/users`; Flutter tidak punya halaman admin. |
| F38 | Pengguna | Aktivasi akun | — | — | BACKEND BELUM TERSEDIA | Tidak ada field/endpoint aktivasi; `models/user.go` tidak punya status aktif. |
| F39 | Lainnya | Pengumuman (daftar, semua peran) | `mahasiswa/beranda_tab.dart:112-116` | `GET /admin/announcements/list` | TERHUBUNG | Probe 200 dengan role mahasiswa, sesuai allow-list `main.go:198`. |
| F40 | Orang Tua | Profil anak | `orang_tua/profil_anak_tab.dart:24-33` | `OrangTuaDashboardData` | DUMMY/STATIC | Production `student == null` → empty state; tidak ada pemanggilan API. |
| F41 | Orang Tua | Nilai anak | `orang_tua/nilai_tab.dart:24-79,181-193` | `OrangTuaDashboardData` | DUMMY/STATIC | Data demo/empty; endpoint `/parent/child/grades` tidak dipanggil. |
| F42 | Orang Tua | Absensi anak | `orang_tua/absensi_tab.dart:26-33,171-175` | `OrangTuaDashboardData` | DUMMY/STATIC | Data demo/empty; endpoint `/parent/child/attendances` tidak dipanggil. |
| F43 | Orang Tua | Keuangan/UKT | `orang_tua/keuangan_tab.dart:28-76` | `OrangTuaDashboardData` | DUMMY/STATIC | Data demo/empty; UI menyatakan tidak ada pemrosesan pembayaran; backend hanya admin CRUD UKT. |
| F44 | Orang Tua | Pengumuman | `orang_tua/pengumuman_tab.dart:21-58` | `OrangTuaDashboardData` | DUMMY/STATIC | Daftar lokal; API pengumuman tidak dipanggil. |
| F45 | Orang Tua | Informasi/bantuan | `orang_tua/informasi_tab.dart:72-117` | Navigasi lokal | DUMMY/STATIC | Hanya pengalih ke tab lain; tidak ada konten backend. |
| F46 | Orang Tua | Profil orang tua | `orang_tua/profil_orang_tua_tab.dart:42-76` | `SharedPreferences`, `ApiService.logout` | TERHUBUNG SEBAGIAN | Email diambil dari lokal, bukan `/users/me`; logout lokal. |
| F47 | Demo | Dashboard demo mahasiswa | `mahasiswa_demo.dart:17-29`, `data/mahasiswa_demo_data.dart:4-405` | Data lokal | DUMMY/STATIC | Demo yang memang disengaja dan didokumentasikan (`mobile/README.md:15-24`), bukan bug produksi. |
| F48 | Akademik | Cetak KRS | `mahasiswa/krs_tab.dart:326` | — | BELUM TERHUBUNG | UI secara eksplisit menyatakan fitur belum tersedia; tidak ada endpoint PDF/cetak. |

**Rekap status:** TERHUBUNG 11 · TERHUBUNG SEBAGIAN 7 · BELUM TERHUBUNG 9 · DUMMY/STATIC 8 · BACKEND BELUM TERSEDIA 7 · BERMASALAH 5 · BELUM DAPAT DIVERIFIKASI 1 = **48**.

---

## BAB 4 — Inventarisasi Endpoint Backend

Semua route terdaftar di `backend/main.go:123-242`. **Method pada kolom "Method (Swagger)" adalah method yang dimaksudkan oleh anotasi `@Router`; runtime menerima semua HTTP method** karena `http.HandleFunc`/`http.Handle` tidak memeriksa `r.Method` (lihat I01). Autentikasi middleware dan allow-list peran diambil langsung dari baris registrasi. Status backend "Terimplementasi" berarti handler ada dan melakukan operasi GORM nyata; tidak serta-merta berarti benar kontraknya.

| No | Method (Swagger) | Endpoint | Handler | Authentication | Role | Status Backend |
|---:|---|---|---|---|---|---|
| 1 | ANY | `/api/health` | inline closure `main.go:123-125` | Tidak | Semua | Terimplementasi (statis) |
| 2 | POST | `/api/v1/register` | `authHandler.Register` `auth.go:53` | Tidak | Semua | Terimplementasi |
| 3 | POST | `/api/v1/login` | `authHandler.Login` `auth.go:101` | Tidak | Semua | Terimplementasi (terverifikasi) |
| 4 | POST | `/api/v1/forgot-password` | `authHandler.ForgotPassword` `auth.go:145` | Tidak | Semua | Terimplementasi |
| 5 | POST | `/api/v1/reset-password` | `authHandler.ResetPassword` `auth.go:195` | Tidak | Semua | Terimplementasi |
| 6 | ANY | `/swagger/` | `httpSwagger.WrapHandler` `main.go:135` | Tidak | Semua | Terimplementasi |
| 7 | ANY | `/api/v1/mobile/dashboard` | inline closure `main.go:142-145` | Ya | mahasiswa, dosen, orangtua | Terimplementasi (statis: hanya `role_anda`) |
| 8 | ANY | `/api/v1/admin/dashboard` | inline closure `main.go:147-150` | Ya | admin, kaprodi | Terimplementasi (statis: hanya `role_anda`) |
| 9 | GET | `/api/v1/admin/stats` | `adminHandler.GetDashboardStats` `admin.go:26` | Ya | admin | Terimplementasi (terverifikasi) |
| 10 | GET | `/api/v1/admin/users` | `adminHandler.GetAllUsers` `admin.go:55` | Ya | admin, kaprodi | Terimplementasi |
| 11 | POST | `/api/v1/admin/users/create` | `adminHandler.CreateUser` `admin.go:88` | Ya | admin, kaprodi | Terimplementasi (kata sandi kosong bisa ter-hash) |
| 12 | PUT | `/api/v1/admin/users/update` | `adminHandler.UpdateUser` `admin.go:136` | Ya | admin, kaprodi | Terimplementasi sebagian (password diabaikan `admin.go:165-167`) |
| 13 | DELETE | `/api/v1/admin/users/delete` | `adminHandler.DeleteUser` `admin.go:179` | Ya | admin, kaprodi | Terimplementasi |
| 14 | POST | `/api/v1/courses` | `courseHandler.CreateCourse` `course.go:33` | Ya | admin, kaprodi | Terimplementasi |
| 15 | GET | `/api/v1/courses/list` | `courseHandler.GetCourses` `course.go:63` | Ya | admin, kaprodi | Terimplementasi |
| 16 | PUT | `/api/v1/courses/update` | `courseHandler.UpdateCourse` `course.go:108` | Ya | admin, kaprodi | Terimplementasi |
| 17 | DELETE | `/api/v1/courses/delete` | `courseHandler.DeleteCourse` `course.go:145` | Ya | admin, kaprodi | Terimplementasi |
| 18 | POST | `/api/v1/classes` | `classHandler.CreateClass` `class.go:37` | Ya | admin, kaprodi | Terimplementasi (year/semester tidak dapat diisi) |
| 19 | GET | `/api/v1/classes/list` | `classHandler.GetClasses` `class.go:70` | Ya | admin, kaprodi, dosen, mahasiswa, orangtua | Terimplementasi (terverifikasi) |
| 20 | PUT | `/api/v1/classes/update` | `classHandler.UpdateClass` `class.go:115` | Ya | admin, kaprodi | Terimplementasi |
| 21 | DELETE | `/api/v1/classes/delete` | `classHandler.DeleteClass` `class.go:149` | Ya | admin, kaprodi | Terimplementasi |
| 22 | POST | `/api/v1/enrollments` | `enrollmentHandler.EnrollClass` `enrollment.go:27` | Ya | mahasiswa | Terimplementasi |
| 23 | GET | `/api/v1/enrollments/my` | `enrollmentHandler.GetMyKRS` `enrollment.go:70` | Ya | mahasiswa | Terimplementasi (terverifikasi) |
| 24 | GET | `/api/v1/admin/krs/list` | `enrollmentHandler.GetAllEnrollments` `enrollment.go:86` | Ya | admin, kaprodi | Terimplementasi |
| 25 | GET | `/api/v1/classes/students` | `enrollmentHandler.GetStudentsByClass` `enrollment.go:110` | Ya | admin, kaprodi, dosen | Terimplementasi (terverifikasi) |
| 26 | POST | `/api/v1/grades` | `gradeHandler.InputGrade` `grade.go:31` | Ya | dosen | Terimplementasi (upsert, ownership check) |
| 27 | GET | `/api/v1/grades/my` | `gradeHandler.GetMyGrades` `grade.go:81` | Ya | mahasiswa | Terimplementasi (terverifikasi) |
| 28 | GET | `/api/v1/admin/grades/list` | `gradeHandler.GetAllGrades` `grade.go:99` | Ya | admin, kaprodi | Terimplementasi |
| 29 | POST | `/api/v1/attendances` | `attendanceHandler.InputAttendance` `attendance.go:32` | Ya | dosen | Terimplementasi (tanpa guard duplikat) |
| 30 | GET | `/api/v1/attendances/my` | `attendanceHandler.GetMyAttendance` `attendance.go:80` | Ya | mahasiswa | Terimplementasi (terverifikasi) |
| 31 | GET | `/api/v1/admin/attendances/list` | `attendanceHandler.GetAllAttendance` `attendance.go:98` | Ya | admin, kaprodi | Terimplementasi |
| 32 | POST | `/api/v1/admin/ukt` | `uktHandler.CreateUKT` `ukt.go:35` | Ya | admin, kaprodi | Terimplementasi |
| 33 | GET | `/api/v1/admin/ukt/list` | `uktHandler.GetAllUKT` `ukt.go:69` | Ya | admin, kaprodi | Terimplementasi (terverifikasi) |
| 34 | PUT | `/api/v1/admin/ukt/update` | `uktHandler.UpdateUKT` `ukt.go:94` | Ya | admin, kaprodi | Terimplementasi |
| 35 | DELETE | `/api/v1/admin/ukt/delete` | `uktHandler.DeleteUKT` `ukt.go:140` | Ya | admin, kaprodi | Terimplementasi |
| 36 | POST | `/api/v1/admin/announcements` | `announcementHandler.CreateAnnouncement` `announcement.go:34` | Ya | admin, kaprodi | Terimplementasi (error parse tanggal diabaikan) |
| 37 | GET | `/api/v1/admin/announcements/list` | `announcementHandler.GetAllAnnouncements` `announcement.go:66` | Ya | admin, kaprodi, mahasiswa, dosen, orangtua | Terimplementasi (terverifikasi) |
| 38 | PUT | `/api/v1/admin/announcements/update` | `announcementHandler.UpdateAnnouncement` `announcement.go:96` | Ya | admin, kaprodi | Terimplementasi |
| 39 | DELETE | `/api/v1/admin/announcements/delete` | `announcementHandler.DeleteAnnouncement` `announcement.go:136` | Ya | admin, kaprodi | Terimplementasi |
| 40 | POST | `/api/v1/admin/schedules` | `scheduleHandler.CreateSchedule` `schedule.go:32` | Ya | admin, kaprodi | Terimplementasi |
| 41 | GET | `/api/v1/admin/schedules/list` | `scheduleHandler.GetAllSchedules` `schedule.go:66` | Ya | admin, kaprodi, mahasiswa, dosen, orangtua | Terimplementasi (terverifikasi; daftar global) |
| 42 | PUT | `/api/v1/admin/schedules/update` | `scheduleHandler.UpdateSchedule` `schedule.go:99` | Ya | admin, kaprodi | Terimplementasi |
| 43 | DELETE | `/api/v1/admin/schedules/delete` | `scheduleHandler.DeleteSchedule` `schedule.go:137` | Ya | admin, kaprodi | Terimplementasi |
| 44 | POST | `/api/v1/admin/packages` | `packageHandler.CreatePackage` `package.go:31` | Ya | admin, kaprodi | Terimplementasi |
| 45 | GET | `/api/v1/admin/packages/list` | `packageHandler.GetAllPackages` `package.go:72` | Ya | admin, kaprodi | Terimplementasi |
| 46 | PUT | `/api/v1/admin/packages/update` | `packageHandler.UpdatePackage` `package.go:101` | Ya | admin, kaprodi | Terimplementasi |
| 47 | DELETE | `/api/v1/admin/packages/delete` | `packageHandler.DeletePackage` `package.go:147` | Ya | admin, kaprodi | Terimplementasi |
| 48 | POST | `/api/v1/admin/cases` | `caseHandler.CreateCase` `case.go:32` | Ya | admin, kaprodi | Terimplementasi (tag `oneof` bermasalah) |
| 49 | GET | `/api/v1/admin/cases/list` | `caseHandler.GetAllCases` `case.go:62` | Ya | admin, kaprodi | Terimplementasi |
| 50 | PUT | `/api/v1/admin/cases/update` | `caseHandler.UpdateCase` `case.go:92` | Ya | admin, kaprodi | Terimplementasi |
| 51 | DELETE | `/api/v1/admin/cases/delete` | `caseHandler.DeleteCase` `case.go:130` | Ya | admin, kaprodi | Terimplementasi |
| 52 | POST | `/api/v1/admin/documents` | `documentHandler.CreateDocument` `document.go:34` | Ya | admin, kaprodi | Terimplementasi (metadata saja) |
| 53 | GET | `/api/v1/admin/documents/list` | `documentHandler.GetAllDocuments` `document.go:64` | Ya | admin, kaprodi | Terimplementasi |
| 54 | PUT | `/api/v1/admin/documents/update` | `documentHandler.UpdateDocument` `document.go:94` | Ya | admin, kaprodi | Terimplementasi |
| 55 | DELETE | `/api/v1/admin/documents/delete` | `documentHandler.DeleteDocument` `document.go:132` | Ya | admin, kaprodi | Terimplementasi |
| 56 | GET | `/api/v1/admin/khs/list` | `khsHandler.GetAllKHS` `khs.go:28` | Ya | admin, kaprodi | Terimplementasi (terverifikasi) |
| 57 | POST | `/api/v1/admin/khs/update` | `khsHandler.UpdateKHStatus` `khs.go:51` | Ya | admin, kaprodi | Terimplementasi |
| 58 | POST | `/api/v1/admin/parents/link` | `parentHandler.LinkParent` `parent.go:39` | Ya | admin | Terimplementasi |
| 59 | GET | `/api/v1/parent/child/grades` | `parentHandler.GetChildGrades` `parent.go:68` | Ya | orangtua | Terimplementasi (hanya anak pertama) |
| 60 | GET | `/api/v1/parent/child/attendances` | `parentHandler.GetChildAttendance` `parent.go:93` | Ya | orangtua | Terimplementasi (hanya anak pertama) |
| 61 | GET | `/api/v1/users/me` | `authHandler.GetMe` `auth.go:246` | Ya | admin, kaprodi, dosen, mahasiswa, orangtua | Terimplementasi (terverifikasi) |
| 62 | ANY* | `/api/v1/qr/generate` | `qrHandler.GenerateQR` `qr.go:38` | Ya | dosen | Terimplementasi (tidak ada di Swagger) |
| 63 | ANY* | `/api/v1/qr/scan` | `qrHandler.ScanQR` `qr.go:90` | Ya | mahasiswa | Terimplementasi (tidak ada di Swagger) |
| 64 | ANY* | `/api/v1/qr/close` | `qrHandler.CloseQR` `qr.go:200` | Ya | dosen | Terimplementasi (tidak ada di Swagger) |
| 65 | ANY* | `/api/v1/admin/qr/active` | `qrHandler.GetActiveQRs` `qr.go:229` | Ya | admin, kaprodi | Terimplementasi (terverifikasi; tidak ada di Swagger) |

`ANY*` = route terdaftar tanpa anotasi Swagger, namun tetap menerima semua method karena tidak ada penegakan method.

**Tidak ada** endpoint untuk: refresh token, logout, change password, update profil, aktivasi akun, program studi/fakultas, tahun akademik, semester, transkrip, KHS versi mahasiswa/orang tua, kalender akademik, notifikasi/push, upload/download berkas, pembayaran UKT, daftar/anak orang tua, dan file statis.

---

## BAB 5 — Matriks Integrasi Flutter vs Backend

Status Flutter merujuk BAB 3. "Terverifikasi" berarti probe read-only berhasil dan field yang dibaca Flutter memang ada pada respons.

| Modul | Fitur | Endpoint Backend | Status Flutter | Status Backend | Hasil Audit | Bukti |
|---|---|---|---|---|---|---|
| Autentikasi | Login | `POST /api/v1/login` | TERHUBUNG | Terimplementasi | **Sesuai** | `api_service.dart:14-28`; `auth.go:101-134`; probe 200 |
| Autentikasi | Register | `POST /api/v1/register` | BELUM DAPAT DIVERIFIKASI | Terimplementasi | Kontrak cocok, runtime belum diuji | `api_service.dart:46-63`; `auth.go:53-89` |
| Autentikasi | Lupa password | `POST /api/v1/forgot-password` | BERMASALAH | Terimplementasi | API cocok, instruksi UI salah | `forgot_password_screen.dart:28-33`; `auth.go:171-183` |
| Autentikasi | Reset password | `POST /api/v1/reset-password` | BERMASALAH | Terimplementasi | Payload cocok; token tidak dikirim via email UI | `new_password_screen.dart:30-45`; `auth.go:195-235` |
| Autentikasi | Logout | — | BACKEND BELUM TERSEDIA | Tidak ada | Token tetap valid sampai kedaluwarsa | `api_service.dart:163-169`; `main.go:123-242` |
| Autentikasi | Refresh token | — | BACKEND BELUM TERSEDIA | Tidak ada | Tidak ada mekanisme perpanjangan | `config/jwt.go:18-30` |
| Autentikasi | Profil | `GET /api/v1/users/me` | TERHUBUNG | Terimplementasi | **Sesuai** | `beranda_tab.dart:80-84`; `auth.go:246-261`; probe 200 |
| Dashboard | Beranda mahasiswa | `/users/me`, `/enrollments/my`, `/grades/my`, `/admin/schedules/list`, `/admin/announcements/list` | TERHUBUNG | Terimplementasi | **Sesuai** (dengan catatan F12/F23) | `beranda_tab.dart:80-116`; probe semua 200 |
| Dashboard | Beranda dosen | `/users/me`, `/classes/list` | TERHUBUNG | Terimplementasi | **Sesuai**, kecuali NIDN | `beranda_dosen_tab.dart:46-69`; probe 200 |
| Dashboard | Dashboard orang tua | — | DUMMY/STATIC | Endpoint parent tersedia tapi tidak dipakai | **Putus** | `orang_tua_dashboard.dart:27-29` |
| Akademik | KRS lihat | `GET /api/v1/enrollments/my` | BERMASALAH | Terimplementasi | Respons 200 tetapi periode kosong | `krs_tab.dart:139-157`; probe `year:''` |
| Akademik | KRS ambil matkul | `POST /api/v1/enrollments` | BELUM TERHUBUNG | Terimplementasi | Tidak dipanggil Flutter | `main.go:174`; tidak ada referensi di `mobile/lib` |
| Akademik | Nilai mahasiswa | `GET /api/v1/grades/my` | TERHUBUNG | Terimplementasi | **Sesuai** | `nilai_tab.dart:42-43`; probe 200 |
| Akademik | Nilai dosen input | `POST /api/v1/grades` | TERHUBUNG SEBAGIAN | Terimplementasi | Payload sesuai, write belum diuji | `nilai_dosen_tab.dart:1037-1042`; `grade.go:17-22` |
| Akademik | Absensi mahasiswa | `GET /api/v1/attendances/my` | TERHUBUNG | Terimplementasi | **Sesuai** | `absensi_tab.dart:102-107`; probe 200 |
| Akademik | Absensi dosen input | `POST /api/v1/attendances` | TERHUBUNG SEBAGIAN | Terimplementasi | Payload sesuai, write belum diuji | `absensi_dosen_tab.dart:608-613`; `attendance.go:18-23` |
| Akademik | Roster kelas | `GET /api/v1/classes/students` | TERHUBUNG | Terimplementasi | **Sesuai** | `nilai_dosen_tab.dart:131-133`; probe 200 n=2 |
| Akademik | Kelas | `GET /api/v1/classes/list` | TERHUBUNG | Terimplementasi | **Sesuai** (envelope pagination benar) | `beranda_dosen_tab.dart:51-56`; `class.go:70-92` |
| Akademik | Jadwal | `GET /api/v1/admin/schedules/list` | TERHUBUNG | Terimplementasi | **Sesuai secara field**, tapi data global | `beranda_tab.dart:562-566`; `schedule.go:66-71` |
| Akademik | Pengumuman | `GET /api/v1/admin/announcements/list` | TERHUBUNG | Terimplementasi | **Sesuai** | `beranda_tab.dart:112-116`; probe 200 |
| Akademik | QR dosen | `POST /qr/generate`, `/qr/close` | TERHUBUNG SEBAGIAN | Terimplementasi | Payload sesuai, tidak ada di Swagger | `qr_generator_screen.dart:211-213,365`; `main.go:239-241` |
| Akademik | QR mahasiswa | `POST /api/v1/qr/scan` | BELUM TERHUBUNG | Terimplementasi | Screen tidak dapat dibuka | `qr_scanner_screen.dart:37`; `main.dart:71-88` |
| Orang Tua | Nilai anak | `GET /api/v1/parent/child/grades` | DUMMY/STATIC | Terimplementasi | **Putus** | `orang_tua/nilai_tab.dart:24-79`; `main.go:232` |
| Orang Tua | Absensi anak | `GET /api/v1/parent/child/attendances` | DUMMY/STATIC | Terimplementasi | **Putus** | `orang_tua/absensi_tab.dart:26-33`; `main.go:233` |
| Orang Tua | Keuangan | `/api/v1/admin/ukt/list` (admin only) | DUMMY/STATIC | Terimplementasi sebagian | **Putus**: tidak ada endpoint UKT untuk mahasiswa/orang tua | `orang_tua/keuangan_tab.dart:28-76`; `main.go:191-194` |
| Orang Tua | Profil pengguna | `GET /api/v1/users/me` | TERHUBUNG SEBAGIAN | Terimplementasi | Email diambil dari lokal | `profil_orang_tua_tab.dart:42-46` |
| Akademik | KHS | `/api/v1/admin/khs/list`, `/admin/khs/update` | BELUM TERHUBUNG | Terimplementasi | Tidak ada screen Flutter; probe list 200 | `main.go:227-228` |
| Administrasi | statistik dashboard | `GET /api/v1/admin/stats` | BELUM TERHUBUNG | Terimplementasi | Dipakai web-admin, bukan Flutter | `web-admin/src/admin/AdminAcademicDashboard.jsx:138-150`; probe 200 |
| Administrasi | CRUD users/courses/classes | `/admin/users*`, `/courses*`, `/classes*` | BELUM TERHUBUNG | Terimplementasi | Hanya web-admin yang memakai | `main.go:156-171` |
| Administrasi | packages/cases/documents | `/admin/packages*`, `/admin/cases*`, `/admin/documents*` | BELUM TERHUBUNG | Terimplementasi | Hanya web-admin yang memakai | `main.go:209-224` |
| Akademik | Transkrip/kalender/aktivasi | — | BACKEND BELUM TERSEDIA | Tidak ada | Tidak dapat diintegrasikan saat ini | tidak ada route/handler |

---

## BAB 6 — Fitur Belum Terhubung

Prioritas: **Critical** = menghalangi alur utama pengguna; **High** = data penting salah/tidak tampil; **Medium** = kenyamanan/lengkap; **Low** = kosmetik/demo.

| Fitur | Lokasi Flutter | Kondisi saat ini | Endpoint diperlukan | Endpoint tersedia? | Yang harus dibuat | Prioritas |
|---|---|---|---|---|---|---|
| QR scanner mahasiswa | `mahasiswa/qr_scanner_screen.dart:5-57` | Kode lengkap tetapi tidak ada route/navigasi | `POST /qr/scan` | Ya | Daftarkan route di `main.dart:71-88` dan panggil dari tab absensi | Critical |
| KRS periode & daftar | `mahasiswa/krs_tab.dart:139-157` | Period selector kosong karena `year/semester` kosong | `GET /enrollments/my` + perbaikan `Class.year/semester` | Ya (perbaikan backend) | Isi `year/semester` saat create class & seed; fallback periode dari `Schedule.semester` di Flutter | Critical |
| Modul Orang Tua | `orang_tua/orang_tua_dashboard.dart:27-29` | Production memakai `OrangTuaDashboardData.empty` | `GET /parent/child/grades`, `/parent/child/attendances`, `/users/me`, `/admin/announcements/list`, `/admin/schedules/list` | Sebagian (tidak ada endpoint UKT/kelas anak) | Buat `ParentApiService`; hubungkan 9 tab; tambahkan endpoint UKT & profil anak di backend | Critical |
| Logout server-side | `api_service.dart:163-169` | Hapus kunci lokal saja | `POST /logout` + blacklist/token store | Tidak | Endpoint logout + revoked-token check di middleware | High |
| Refresh token | `api_service.dart:114-160` | Token mati setelah 24 jam | `POST /refresh-token` | Tidak | Refresh token rotation; interceptor + retry 401 di Flutter | High |
| Ganti password | `dosen/profil_dosen_tab.dart:238-239` | Diarahkan ke lupa password | `POST /change-password` | Tidak | Endpoint terautentikasi dengan verifikasi password lama | High |
| Edit profil | `dosen/profil_dosen_tab.dart:259-263` | Snackbar "belum tersedia" | `PUT /users/me` / `PATCH /users/me` | Tidak | DTO profil + endpoint; form Flutter | High |
| KRS enroll | `mahasiswa/krs_tab.dart:326` | Tidak ada aksi ambil matkul | `POST /enrollments` | Ya | Tambahkan UI pilih kelas + submit | High |
| KHS mahasiswa | — | Tidak ada halaman | `GET /khs/my` | Tidak | Endpoint KHS mahasiswa + screen Flutter | High |
| Dashboards admin/kaprodi di Flutter | — | Hanya ada di web-admin | `/admin/dashboard`, `/admin/stats`, dll. | Ya | Tambahkan Flutter admin shell atau dokumentasikan web-admin sebagai satu-satunya klien | Medium |
| Transkrip nilai | — | Tidak ada | `GET /transcripts/my` | Tidak | Model `Transcript` + endpoint + screen PDF/cetak | Medium |
| Cetak KRS | `mahasiswa/krs_tab.dart:326` | Pesan "belum tersedia" | `GET /krs/print` atau generate PDF | Tidak | Endpoint PDF + `url_launcher`/`path_provider` | Medium |
| Kalender akademik | — | Tidak ada | `GET /academic-calendar` | Tidak | Entity kalender + endpoint + UI | Medium |
| Aktivasi akun | — | Tidak ada | `POST /users/activate` | Tidak | Field status + endpoint + alur admin | Medium |
| Notifikasi | — | Tidak ada | `GET /notifications` + push | Tidak | Entity notifikasi + FCM | Medium |
| Manajemen akun/role Flutter | — | Tidak ada di Flutter | `/admin/users*`, roles/permissions | Sebagian (CRUD users ada) | Screen admin Flutter atau konfirmasi web-admin sebagai klien resmi | Low |
| Data prodi/fakultas | `dosen/profil_dosen_tab.dart:16-18` | Hardcoded 3 konstanta | `GET /faculties`, `/study-programs` | Tidak | Model + seed + endpoint + UI | Low |
| Upload dokumen | — | Tidak ada | `POST /documents/upload` (multipart) | Tidak (metadata saja) | Storage + endpoint + Flutter file picker | Low |
| Tombol sosial login | `login_screen.dart:134,144` | `onPressed: () {}` | OAuth Google/Apple | Tidak | Implementasi OAuth atau hapus tombol | Low |

---

## BAB 7 — Dummy dan Static Data

Dibedakan antara **data konfigurasi statis yang wajar** (warna, enum, daftar hari, label UI) dan **data bisnis** yang seharusnya berasal dari backend. Tabel berikut hanya mencantumkan yang terakhir, termasuk demo yang disengaja.

| Modul | File | Lokasi Kode | Jenis Dummy | Dampak | Rekomendasi |
|---|---|---|---|---|---|
| Mahasiswa (demo) | `mobile/lib/data/mahasiswa_demo_data.dart` | `:4-10` identitas, `:12-27` jadwal, `:29-40` pengumuman, `:42-405` KRS/absensi/nilai | Static JSON lokal | Hanya berjalan lewat `mahasiswa_demo.dart`; production tidak memakai | Pertahankan sebagai demo, beri label jelas (sudah ada) |
| Mahasiswa (entry demo) | `mobile/lib/mahasiswa_demo.dart` | `:17-29` | Entry point alternatif `demoMode: true` | Tidak memengaruhi production | Dokumentasikan (sudah ada di `mobile/README.md:15-24`) |
| Main app | `mobile/lib/main.dart` | `:93-137` `DummyDashboard` | Halaman dummy tidak terpakai | Dead code, menyesatkan pembaca | Hapus saat refactor (bukan bagian audit ini) |
| Beranda mahasiswa | `mahasiswa/beranda_tab.dart` | `:51-77` | Cabang demo lokal | Hanya aktif jika `demoMode: true` | Pertahankan |
| KRS mahasiswa | `mahasiswa/krs_tab.dart` | `:57-63` `KrsTab.preview` | Data preview lokal | Hanya dipakai mode demo | Pertahankan |
| Absensi mahasiswa | `mahasiswa/absensi_tab.dart` | `:98-100`, `:608-667` | Data demo + dialog "Simulasikan" | Di production tombol scan hanya simulasi, tidak menyimpan absensi | Hubungkan ke `QrScannerScreen` + `/qr/scan` |
| Nilai mahasiswa | `mahasiswa/nilai_tab.dart` | `:39-40`, `:381-384` | Data demo + banner demo | Tidak memengaruhi production | Pertahankan |
| Profil mahasiswa | `mahasiswa/profil_tab.dart` | `:32-37` | Identitas demo | Hanya mode demo | Pertahankan |
| Absensi dosen | `dosen/absensi_dosen_tab.dart` | `:6-242` contoh kelas/mahasiswa, `:244-254` preview, `:597` snackbar lokal, `:1590-1591` estimasi status | Sample data + state lokal | Status kehadiran dosen bisa tampil berbeda dari database | Simpan perubahan lewat `POST /attendances` / endpoint update |
| Nilai dosen | `dosen/nilai_dosen_tab.dart` | `:412-413`, `:857-859` | Komponen nilai Tugas/UTS/UAS ditampilkan `—` | Penilaian tampak tidak lengkap | Tambahkan field komponen nilai di backend & Flutter |
| Profil dosen | `dosen/profil_dosen_tab.dart` | `:16-18`, `:259-263` | Prodi/fakultas/universitas hardcoded; menu tidak aktif | Data institusi tidak mengikuti backend | Ambil dari `/users/me` atau endpoint prodi |
| QR dosen | `dosen/qr_generator_screen.dart` | `:62`, `:288-311`, `:952-956` | Sesi disimpan `SharedPreferences`; detail tidak lengkap | Sesi lokal bisa bertahan setelah backend menutupnya | Validasi ulang ke `/admin/qr/active` atau endpoint status sesi |
| Orang tua (semua tab) | `orang_tua/orang_tua_dashboard.dart` | `:27-29` | `OrangTuaDashboardData.empty` di production | Seluruh data bisnis orang tua kosong/statis | Integrasikan endpoint parent (BAB 6) |
| Orang tua (data demo) | `data/orang_tua_preview_data.dart` | `:24` empty, `:26-417` demo | Model + dataset lokal 653 baris | Demo terlihat kaya, production kosong | Pindahkan pengambilan data ke API; pertahankan demo sebagai preview |
| Orang tua — jadwal | `orang_tua/jadwal_tab.dart` | `:16-24`, `:43-71` | Data lokal + label DEMO | Jadwal anak tidak nyata | `GET /admin/schedules/list` + filter kelas anak |
| Orang tua — pengumuman | `orang_tua/pengumuman_tab.dart` | `:21-58` | Daftar lokal | Tidak menerima pengumuman baru | `GET /admin/announcements/list` |
| Orang tua — keuangan | `orang_tua/keuangan_tab.dart` | `:28-76`, `:168-304` | Ringkasan UKT lokal, menyatakan tidak ada pembayaran | Tidak ada data tagihan nyata | Endpoint UKT mahasiswa/orang tua |
| Orang tua — profil | `orang_tua/profil_orang_tua_tab.dart` | `:42-46` | Email dari lokal/demo | Bisa berbeda dari email akun | `GET /users/me` |
| Login | `login_screen.dart` | `:134,144` | Tombol sosial tanpa aksi | UI menjanjikan fungsi yang tidak ada | Implementasi atau hapus |
| Reset password | `forgot_password_screen.dart` | `:28-33` | Instruksi membaca log Docker | Token tidak sampai ke pengguna lewat UI | Tampilkan instruksi email; validasi pengiriman email |

**Data statis yang wajar dan tidak dianggap temuan:** konstanta warna/tema (`orang_tua/widgets/orang_tua_theme.dart:3-14`), daftar hari dan label filter, daftar menu navigasi (`web-admin/src/constants/prodiNavigation.js:1-31`), konfigurasi build (`pubspec.yaml`, `docker-compose.yml`), dan pesan error UI.

Catatan konteks (di luar fokus Flutter): `web-admin/src/admin/constants/adminData.js:5-147` dan `web-admin/src/admin/AdminAcademicDashboard.jsx:435-447,699-707,1176-1190` masih menyimpan dan memutasi data demo secara lokal; `web-admin/src/prodi/ProdiDashboard.jsx:98-100,1357,1443-1457` memakai array kosong, grafik literal, dan penyimpanan pengaturan lokal.

---

## BAB 8 — Endpoint Backend Belum Digunakan

Dari 65 route, **17 dipanggil Flutter**, **42 dipanggil `web-admin`** (4 di antaranya juga dipanggil Flutter: `/login`, `/classes/list`, `/admin/announcements/list`, `/admin/schedules/list`), dan **10 tidak dipakai klien mana pun**. Jadi ada **48 endpoint yang tidak dipakai Flutter**: 38 hanya dipakai web-admin + 10 tidak dipakai sama sekali.

### 8.1 Dipakai web-admin, bukan Flutter (38)

| Endpoint | Fungsi | Penggunaan potensial di Flutter |
|---|---|---|
| `GET /api/v1/admin/users` | Daftar user berhalaman | Kelola akun mahasiswa/dosen |
| `POST /api/v1/admin/users/create` | Buat user | Registrasi oleh admin |
| `PUT /api/v1/admin/users/update` | Update user | Edit profil/admin |
| `DELETE /api/v1/admin/users/delete` | Hapus user | Kelola akun |
| `POST /api/v1/courses` | Buat mata kuliah | Modul akademik admin |
| `GET /api/v1/courses/list` | Daftar mata kuliah | Pilihan KRS / referensi dosen |
| `PUT /api/v1/courses/update` | Update mata kuliah | Modul akademik admin |
| `DELETE /api/v1/courses/delete` | Hapus mata kuliah | Modul akademik admin |
| `POST /api/v1/classes` | Buat kelas | Modul akademik admin, sekaligus tempat mengisi `year`/`semester` |
| `PUT /api/v1/classes/update` | Update kelas | Modul akademik admin |
| `DELETE /api/v1/classes/delete` | Hapus kelas | Modul akademik admin |
| `GET /api/v1/admin/krs/list` | Semua KRS | Monitoring KRS kaprodi |
| `GET /api/v1/admin/grades/list` | Semua nilai | Analitik nilai |
| `GET /api/v1/admin/attendances/list` | Semua absensi | Monitoring absensi |
| `POST /api/v1/admin/ukt` | Buat tagihan UKT | Modul keuangan admin |
| `GET /api/v1/admin/ukt/list` | Semua tagihan UKT | Dasar endpoint UKT orang tua (perlu scoped) |
| `PUT /api/v1/admin/ukt/update` | Update tagihan | Modul keuangan admin |
| `DELETE /api/v1/admin/ukt/delete` | Hapus tagihan | Modul keuangan admin |
| `POST /api/v1/admin/announcements` | Buat pengumuman | Panel pengumuman |
| `PUT /api/v1/admin/announcements/update` | Update pengumuman | Panel pengumuman |
| `DELETE /api/v1/admin/announcements/delete` | Hapus pengumuman | Panel pengumuman |
| `POST /api/v1/admin/schedules` | Buat jadwal | Panel jadwal |
| `PUT /api/v1/admin/schedules/update` | Update jadwal | Panel jadwal |
| `DELETE /api/v1/admin/schedules/delete` | Hapus jadwal | Panel jadwal |
| `POST /api/v1/admin/packages` | Buat paket semester | Modul administrasi |
| `GET /api/v1/admin/packages/list` | Daftar paket semester | Informasi paket KRS |
| `PUT /api/v1/admin/packages/update` | Update paket | Modul administrasi |
| `DELETE /api/v1/admin/packages/delete` | Hapus paket | Modul administrasi |
| `POST /api/v1/admin/cases` | Buat kasus kemahasiswaan | Panel kemahasiswaan |
| `GET /api/v1/admin/cases/list` | Daftar kasus | Panel kemahasiswaan |
| `PUT /api/v1/admin/cases/update` | Update kasus | Panel kemahasiswaan |
| `DELETE /api/v1/admin/cases/delete` | Hapus kasus | Panel kemahasiswaan |
| `POST /api/v1/admin/documents` | Buat metadata dokumen | Panel dokumen |
| `GET /api/v1/admin/documents/list` | Metadata dokumen | Panel dokumen |
| `PUT /api/v1/admin/documents/update` | Update metadata | Panel dokumen |
| `DELETE /api/v1/admin/documents/delete` | Hapus metadata | Panel dokumen |
| `GET /api/v1/admin/khs/list` | Daftar KHS (admin) | Dasar endpoint `GET /khs/my` |
| `POST /api/v1/admin/khs/update` | Publikasi KHS | Panel KHS kaprodi |

### 8.2 Tidak dipakai klien mana pun (10)

| Endpoint | Fungsi | Penggunaan potensial |
|---|---|---|
| `GET /api/health` | Health check | Monitoring/status screen |
| `GET /swagger/` | Dokumentasi API | Developer tooling; tidak dapat diakses lewat Nginx port 80 |
| `GET /api/v1/mobile/dashboard` | Sapaan + `role_anda` (statis) | Tidak membawa data; bisa dihapus atau diperkaya |
| `GET /api/v1/admin/dashboard` | Sapaan + `role_anda` (statis) | Sama |
| `GET /api/v1/admin/stats` | 4 counter dashboard | Dashboard admin Flutter (jika dibuat) |
| `POST /api/v1/enrollments` | Ambil KRS | **Prioritas**: tombol ambil matkul mahasiswa |
| `POST /api/v1/admin/parents/link` | Hubungkan orang tua–anak | Halaman administrasi orang tua |
| `GET /api/v1/parent/child/grades` | Nilai anak | **Prioritas**: tab nilai orang tua |
| `GET /api/v1/parent/child/attendances` | Absensi anak | **Prioritas**: tab absensi orang tua |
| `GET /api/v1/admin/qr/active` | Sesi QR aktif | Validasi sesi QR di Flutter dosen |

---

## BAB 9 — Masalah Integrasi

Kode status: Critical/High/Medium/Low. Semua bukti berupa path relatif terhadap root repository.

### 9.1 Authentication & Authorization

| ID | Sev | Masalah | Bukti |
|---|---|---|---|
| I01 | Critical | Tidak ada penegakan HTTP method pada 65 route; `DELETE /courses` masuk ke handler create. Probe: `GET /login` → 400 JSON, bukan 405. | `backend/main.go:123-242`; `backend/middlewares/cors.go:13` (satu-satunya pengecekan `r.Method`) |
| I02 | Critical | Middleware 401/403 mengembalikan plain text, bukan envelope JSON; Flutter `jsonDecode` pasti gagal dan pesan asli hilang. Probe: `Missing Authorization Header`. | `backend/middlewares/auth.go:28,42,56`; `backend/utils/response.go:8-22`; `mobile/lib/services/api_service.dart:125,150` |
| I03 | Critical | Tidak ada penanganan 401/refresh; token kedaluwarsa tidak memicu navigasi ulang login. | `api_service.dart:114-160`; `splash_screen.dart:21-44`; `config/jwt.go:18-30` |
| I04 | High | Logout hanya lokal; JWT tetap valid sampai 24 jam, tidak ada revocation/blacklist. Redis tersedia tetapi tidak dipakai. | `api_service.dart:163-169`; `config/jwt.go:18-30`; `main.go:23,62-74` |
| I05 | High | Tidak ada refresh token, logout, change-password, update profil, atau aktivasi akun di backend. | `main.go:123-242` (tidak ada route) |
| I06 | High | Role untuk routing diambil dari `SharedPreferences`, bukan dari `/users/me`; peran di JWT bisa berubah tanpa UI sinkron. | `splash_screen.dart:23-44`; `login_screen.dart:26-33` |
| I07 | Medium | Prefix `Bearer ` dihapus dengan `strings.Replace`, bukan `TrimPrefix`, sehingga token tanpa skema tetap diterima. | `backend/middlewares/auth.go:33` |
| I08 | Medium | Algoritma JWT tidak di-pin; token HMAC lain dengan kunci sama berpotensi diterima. Tidak ada `iss/aud/jti`. | `backend/config/jwt.go:12-30`; `middlewares/auth.go:36-39` |
| I09 | High | Allow-list peran hanya di registrasi route; tidak ada tabel roles/permissions. | `main.go:153-242`; `models/user.go:5-22` |

### 9.2 Request, Response, dan Model

| ID | Sev | Masalah | Bukti |
|---|---|---|---|
| I10 | Critical | `Class.year`/`semester` tidak pernah diisi oleh `CreateClass` atau seeder, tetapi dipakai Flutter untuk periode KRS/Nilai. Probe langsung: `''`, `''`. | `backend/handlers/class.go:16-24,48-51`; `backend/seed/main.go:100-105`; `mobile/lib/screens/mahasiswa/krs_tab.dart:139-157`; `nilai_tab.dart:65-85` |
| I11 | High | NIDN/NIP dibaca Flutter, tidak ada di model User; selalu kosong. | `dosen/beranda_dosen_tab.dart:66`; `backend/models/user.go:5-22`; probe `/users/me` |
| I12 | High | Jadwal mahasiswa bersifat global (`GetAllSchedules`) lalu `take(2)`; mahasiswa bisa melihat jadwal kelas lain. | `backend/handlers/schedule.go:66-71`; `mahasiswa/beranda_tab.dart:108-110` |
| I13 | High | IPK dihitung dari rata-rata skor mentah × 4, bukan rerata bobot SKS; SKS menjumlahkan semua KRS tanpa filter periode aktif. | `mahasiswa/beranda_tab.dart:86-106` |
| I14 | High | `/classes/list` dibatasi default 10 per halaman, Flutter tidak mengirim `page`/`limit` sehingga hanya halaman pertama yang tampil. | `backend/utils/pagination.go:12-20`; `dosen/beranda_dosen_tab.dart:51`, `dosen/nilai_dosen_tab.dart:84`, `dosen/absensi_dosen_tab.dart:330` |
| I15 | Medium | `UpdateUser` memvalidasi password lalu mengabaikannya; `CreateUser` meng-hash string kosong jika password tidak diisi. | `backend/handlers/admin.go:82,109,165-167` |
| I16 | Medium | Tag `oneof` dengan nilai multi-kata tidak dikutip pada Case/Document DTO → validasi terpecah. | `backend/handlers/case.go:22`; `backend/handlers/document.go:21`; bandingkan `khs.go:20` |
| I17 | Medium | Error parse tanggal diabaikan pada announcement/document → tanggal bisa tersimpan nol. | `backend/handlers/announcement.go:47-48,112-113`; `document.go:46,109` |
| I18 | Medium | `FormatValidationError` melakukan type assertion tanpa pengecekan; error non-validasi dapat memicu panic. | `backend/utils/validator.go:20` |
| I19 | Medium | `GetPagination` mengabaikan error parsing dan tidak membatasi `limit` maksimal. | `backend/utils/pagination.go:12-20` |
| I20 | Medium | Swagger hanya mendokumentasikan 57 dari 65 route; semua route QR dan 2 dashboard tidak ada. Skema `data` generik, bukan DTO. | `backend/docs/swagger.json`; `backend/main.go:123,135,142,147,239-242` |
| I21 | Medium | Base URL Flutter hardcoded untuk emulator; gagal di HP fisik/web tanpa edit kode. Web-admin memakai port 80, mobile port 8080 langsung, Nginx tidak mem-proxy `/swagger/`. | `mobile/lib/services/api_service.dart:6-9`; `web-admin/src/services/api.js:3-6`; `docker/nginx/nginx.conf:12-25` |
| I22 | Medium | Dosen attendance status hanya estimasi tampilan, tidak tersimpan; manual `POST /attendances` juga tanpa guard duplikat (berbeda dengan QR scan). | `dosen/absensi_dosen_tab.dart:1590-1591`; `backend/handlers/attendance.go:53-68`; `qr.go:163-173` |
| I23 | Low | Grade hanya menyimpan skor akhir + huruf; UI menampilkan Tugas/UTS/UAS sebagai `—`. | `dosen/nilai_dosen_tab.dart:412-413,857-859`; `backend/models/grade.go:5-17` |

### 9.3 State Management, UI, dan Alur

| ID | Sev | Masalah | Bukti |
|---|---|---|---|
| I24 | Critical | Modul orang tua production memakai data kosong; 9 tab tidak ada yang memanggil API. | `orang_tua/orang_tua_dashboard.dart:27-29`; seluruh `orang_tua/*.dart` |
| I25 | Critical | QR scanner mahasiswa tidak memiliki route/navigasi, sehingga fitur presensi QR tidak dapat diakses. | `mahasiswa/qr_scanner_screen.dart:5-57`; `main.dart:71-88`; pencarian referensi hanya menemukan file itu sendiri |
| I26 | High | Alur lupa password memberitahu pengguna membaca log Docker, bukan email; backend sebenarnya mengirim email. | `forgot_password_screen.dart:28-33`; `backend/handlers/auth.go:171-183`; `backend/utils/email.go:8-24` |
| I27 | High | Sesi QR dosen disimpan di `SharedPreferences` tanpa validasi ulang ke server; bisa tampak aktif setelah ditutup. | `dosen/qr_generator_screen.dart:62,288-311`; `main.go:242` |
| I28 | Medium | Tombol login sosial tidak memiliki aksi. | `login_screen.dart:134,144` |
| I29 | Medium | `DummyDashboard` dan dialog simulasi absensi tetap menjadi kode mati/placeholder. | `main.dart:93-137`; `mahasiswa/absensi_tab.dart:608-667` |
| I30 | Medium | Modul admin/kaprodi tidak ada di Flutter; tidak ada keputusan arsitektur yang didokumentasikan bahwa web-admin adalah klien resmi. | `main.dart:71-88`; `README.md:77-81`; `web-admin/src/App.jsx:8-17` |
| I31 | Medium | Tidak ada state/empty/error terpadu: tiap screen mengulang pola `setState` + `debugPrint`; error 401 tidak dibedakan. | `api_service.dart:114-160`; `beranda_tab.dart:130-138`; `krs_tab.dart:119-127` |
| I32 | Low | Tiga info lint `curly_braces_in_flow_control_structures` di login. | `flutter analyze`; `login_screen.dart:31-33` |

### 9.4 Database, Testing, dan Operasional

| ID | Sev | Masalah | Bukti |
|---|---|---|---|
| I33 | High | Tidak ada file migrasi/SQL; skema bergantung pada AutoMigrate saat startup, sehingga perubahan field sulit diaudit. | `backend/main.go:79-97`; tidak ada `*.sql`/direktori migrasi |
| I34 | Medium | Test backend melakukan `TRUNCATE` dan mensyaratkan DSN uji; test Flutter hanya aritmetika. Keduanya tidak dijadikan bukti integrasi. | `backend/handlers/all_test.go:24-40,54,80`; `mobile/test/basic_test.dart:4-7` |

Catatan tambahan (bukan bug integrasi, tetapi relevan): seeder melakukan truncate seluruh tabel dan memakai satu kata sandi demo bersama untuk semua akun; **tidak dijalankan** selama audit. Detail kredensial sengaja tidak direproduksi di sini meskipun tersedia di `README.md:52-61`.

---

## BAB 10 — Daftar Pekerjaan yang Belum Selesai

### Critical

- [ ] Terapkan penegakan HTTP method (mux berbasis method atau pengecekan `r.Method`) pada 65 route.
- [ ] Ubah middleware auth agar mengembalikan envelope JSON yang sama dengan `utils.JSONResponse`.
- [ ] Tambahkan penanganan 401 di `ApiService` (hapus sesi + navigasi `/login`) dan hentikan parsed error generik.
- [ ] Isi `Class.year` dan `Class.semester` di `ClassInput`/`CreateClass` dan seeder; backfill data lama.
- [ ] Hubungkan `QrScannerScreen` ke route/navigasi mahasiswa.
- [ ] Integrasikan seluruh tab Orang Tua dengan API parent/profile/announcement/schedule.

### High

- [ ] Endpoint logout, refresh token, change password, update profil, dan aktivasi akun.
- [ ] Tekan Refresh di `ApiService` dengan retry satu kali untuk 401.
- [ ] Buat scoped endpoint UKT untuk mahasiswa/orang tua dan KHS mahasiswa.
- [ ] Tambahkan filter schedule per mahasiswa/kelas, jangan kirim seluruh jadwal.
- [ ] Kirim `page`/`limit` dari Flutter atau tambahkan endpoint ringkas untuk daftar kelas dosen.
- [ ] Perbaiki perhitungan IPK/SKS agar berbasis bobot SKS dan periode aktif.
- [ ] Tambahkan `nidn`/`nip` (atau ganti UI ke field yang tersedia).
- [ ] Validasi token QR secara server-side sebelum menampilkan status aktif.
- [ ] Alur reset password berbasis email dengan konfirmasi pengiriman.

### Medium

- [ ] DTO dan endpoint untuk nilai komponen (Tugas/UTS/UAS), kalender akademik, transkrip, notifikasi.
- [ ] Screen admin/kaprodi Flutter atau dokumentasi resmi pembagian klien.
- [ ] File migrasi SQL versi-terkontrol; hentikan ketergantungan penuh pada AutoMigrate.
- [ ] Lengkapi Swagger: 8 route missing + skema `data` per endpoint.
- [ ] Konfigurasi base URL Flutter via `--dart-define`/flavor, bukan hardcoded.
- [ ] Perbaiki validasi DTO (`oneof` berkutip), error parsing tanggal, dan batas `limit`.
- [ ] Unify komponen loading/empty/error di Flutter.
- [ ] Perbaiki 3 info lint di `login_screen.dart:31-33`.

### Low

- [ ] Hapus atau implementasikan tombol sosial login.
- [ ] Hapus `DummyDashboard` yang tidak terpakai.
- [ ] HilangkanTooltip simulasi pada dialog absensi setelah QR scanner aktif.
- [ ] Tambah `.env.example` berisi **nama** variabel saja (tanpa nilai).
- [ ] Dokumentasikan placeholder demo web-admin agar tidak disalahartikan sebagai data produksi.

---

## BAB 11 — Roadmap Penyelesaian

| Tahap | Target | File Flutter | File Backend | Endpoint | Kriteria keberhasilan | Dependency |
|---|---|---|---|---|---|---|
| 1 | Stabilkan kontrak HTTP & auth | `services/api_service.dart` | `main.go`, `middlewares/auth.go`, `utils/response.go`, `config/jwt.go` | semua 65 route | Semua route menolak method salah (405); 401/403 ber-JSON; Flutter menampilkan pesan server dan kembali ke login | — |
| 2 | Perbaiki data periode akademik | `mahasiswa/krs_tab.dart`, `nilai_tab.dart`, `beranda_tab.dart` | `handlers/class.go`, `seed/main.go`, `models/class.go`, migrasi baru | `POST /classes`, `GET /enrollments/my`, `GET /grades/my` | Probe KRS/Nilai menampilkan periode tahun/semester bukan string kosong | Tahap 1 |
| 3 | Aktifkan QR mahasiswa | `main.dart`, `mahasiswa/absensi_tab.dart`, `mahasiswa/qr_scanner_screen.dart` | `handlers/qr.go` (validasi sesi opsional) | `POST /qr/scan` | Scanner dapat dibuka, token valid tercatat, duplikat harian ditolak | Tahap 1 |
| 4 | Integrasi penuh Orang Tua | `orang_tua_dashboard.dart` + 9 tab + service baru | `handlers/parent.go`, baru `handlers/ukt_student.go` | `GET /parent/child/grades`, `/parent/child/attendances`, `/users/me`, `/admin/announcements/list`, `/admin/schedules/list`, baru `/student/ukt/my` | Production orang tua menampilkan data akun nyata; tidak ada `OrangTuaDashboardData.empty` di jalur production | Tahap 1, 2 |
| 5 | Lengkapi manajemen sesi | `login_screen.dart`, `profil*.dart`, `splash_screen.dart` | `handlers/auth.go`, `main.go`, `middlewares/auth.go` | baru `/logout`, `/refresh-token`, `/change-password`, `PUT /users/me` | Logout membatalkan token; token diperbarui otomatis; ganti password tanpa email | Tahap 1 |
| 6 | Perbaiki akurasi dashboard & filter | `beranda_tab.dart`, `beranda_dosen_tab.dart` | `handlers/schedule.go` | `/admin/schedules/list`, `/classes/list` | Mahasiswa hanya melihat jadwal kelasnya; IPK sesuai bobot SKS; daftar dosen tidak terpotong halaman pertama | Tahap 2 |
| 7 | Tambah fitur yang belum ada | screen KHS/transkrip/kalender/notifikasi | model+handler KHS mahasiswa, transkrip, kalender, notifikasi | `GET /khs/my`, `/transcripts/my`, `/academic-calendar`, `/notifications` | Screen Flutter menampilkan data dari endpoint baru | Tahap 1 |
| 8 | Rapikan kualitas & dokumentasi | seluruh `lib/`, `test/` | `docs/`, migrasi | — | `flutter analyze` bersih, test integrasi API bertambah, Swagger 65/65 route, base URL tidak hardcoded | Tahap 1–7 |

---

## BAB 12 — Kesimpulan

Aplikasi Flutter EduTrack Campus **belum siap** digunakan secara penuh dengan backend.

- Modul **Mahasiswa** dan **Dosen** sudah berada pada kondisi "terhubung sebagian besar": 11 fitur terverifikasi terhubung, 7 terhubung sebagian. Namun ada cacat nyata pada periode KRS/Nilai, IPK, NIDN, cakupan jadwal, dan akses QR scanner.
- Modul **Orang Tua** secara fungsional **tidak terhubung** di jalur production meskipun backend menyediakan endpoint yang relevan.
- Tidak ada admin/kaprodi di Flutter; peran tersebut hanya ada di web-admin, dan web-admin sendiri masih menyimpan sejumlah data demo.
- Backend solid di level CRUD GORM, tetapi **kontrak HTTP dan autentikasi perlu diperbaiki lebih dulu** sebelum menambah fitur Flutter baru. Tanpa perbaikan method enforcement dan JSON error, penanganan error klien akan tetap rapuh.
- Penilaian kesiapan: **sekitar 23% fitur (11/48) benar-benar terhubung dan terverifikasi**; **25% (12/48) memerlukan endpoint backend baru atau perbaikan kontrak** (BACKEND BELUM TERSEDIA + BERMASALAH), dan 9 fitur BELUM TERHUBUNG perlu dihubungkan meski sebagian endpointnya sudah tersedia.
- Tidak ada perubahan kode atau database yang dilakukan selama audit. Semua status "TERHUBUNG" didasarkan pada kombinasi bukti source code dan probe read-only; operasi yang menulis data sengaja tidak dijalankan dan ditandai BELUM DAPAT DIVERIFIKASI/TERHUBUNG SEBAGIAN.

### Batasan verifikasi

- Tidak ada build APK/IPA, tidak ada inspeksi visual runtime Flutter, dan tidak ada unit/widget test yang dijalankan.
- Probe API hanya mencakup login (4 peran) dan endpoint GET; tidak ada POST/PUT/DELETE yang dieksekusi terhadap database.
- Status "Terimplementasi" pada BAB 4 berarti handler dan query GORM nyata ditemukan, bukan jaminan bahwa semua kasus tepi sudah benar.
- Lingkungan yang di-probe adalah server lokal di `127.0.0.1:8080`; tidak ada jaminan konfigurasi produksi/staging identik.
