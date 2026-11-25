# Daftar Masalah Integrasi Flutter–Backend

Lampiran audit — 2026-11-19. Bukti berupa path relatif terhadap root repository. Tidak ada perbaikan kode yang dilakukan.

## Ringkasan severitas

| Severitas | Jumlah | ID |
|---|---:|---|
| Critical | 6 | I01, I02, I03, I10, I24, I25 |
| High | 11 | I04, I05, I06, I09, I11, I12, I13, I14, I26, I27, I33 |
| Medium | 15 | I07, I08, I15, I16, I17, I18, I19, I20, I21, I22, I28, I29, I30, I31, I34 |
| Low | 2 | I23, I32 |

Total 34 temuan (I01–I34).

| ID | Severitas | Kategori | Masalah | Bukti | Dampak | Rekomendasi |
|---|---|---|---|---|---|---|
| I01 | Critical | Network/Routing | Tidak ada penegakan HTTP method pada 65 route. Probe `GET /api/v1/login` → 400 "Format JSON tidak valid", bukan 405. | `backend/main.go:123-242`; `backend/middlewares/cors.go:13` | `DELETE /courses` dapat memanggil `CreateCourse`; kontrak Swagger tidak mencerminkan runtime | Gunakan mux yang sadar method atau validasi `r.Method` di setiap handler |
| I02 | Critical | Error handling | Middleware 401/403 mengembalikan plain text (`http.Error`), bukan envelope `{status,message,data}`. Probe: `Missing Authorization Header`. | `backend/middlewares/auth.go:28,42,56`; `backend/utils/response.go:8-22` | Flutter `jsonDecode` di `api_service.dart:125,150` melempar FormatException; pesan asli hilang | Seragamkan `utils.JSONResponse` di middleware |
| I03 | Critical | Authentication | Tidak ada penanganan 401/refresh. Token 24 jam, tidak ada perpanjangan. | `mobile/lib/services/api_service.dart:114-160`; `backend/config/jwt.go:18-30`; `splash_screen.dart:21-44` | Setelah token kedaluwarsa pengguna terjebak pada error generik | Tambah refresh token + interceptor retry + redirect login |
| I04 | High | Authentication | Logout hanya menghapus `token`, `role`, `email` di SharedPreferences; JWT masih valid. Redis tidak dipakai. | `api_service.dart:163-169`; `main.go:23,62-74` | Tidak ada pencabutan sesi nyata | Endpoint logout + token blacklist/whitelist |
| I05 | High | Backend gap | Tidak ada endpoint logout, refresh, change-password, update-profil, aktivasi akun. | `main.go:123-242` | Fitur akun Flutter tidak lengkap | Tambah endpoint sesuai BAB 6 |
| I06 | High | Authorization | Role untuk routing berasal dari SharedPreferences, bukan verifikasi server. | `splash_screen.dart:23-44`; `login_screen.dart:26-33` | Role lokal bisa basi/berubah tanpa sinkronisasi JWT | Validasi `/users/me` saat splash |
| I07 | Medium | Authentication | Prefix Bearer dihapus memakai `strings.Replace`, bukan `TrimPrefix`. | `backend/middlewares/auth.go:33` | Token tanpa skema tetap diterima; klarifikasi kontrak | Gunakan `strings.TrimPrefix` + validasi skema |
| I08 | Medium | Authentication | Algoritma JWT tidak di-pin; tidak ada `iss`, `aud`, `jti`. | `backend/config/jwt.go:12-30`; `middlewares/auth.go:36-39` | Risiko penerimaan token HMAC lain dengan kunci sama | Periksa `token.Method.Alg() == HS256` sebelum keyfunc |
| I09 | High | Authorization | Role enforcement hanya allow-list statis di registrasi route; tidak ada tabel roles/permissions. | `main.go:153-242`; `models/user.go:5-22` | Tidak ada manajemen hak akses dinamis | Model Role/Permission + middleware berbasis DB |
| I10 | Critical | JSON model/DB | `Class.year` dan `Class.semester` tidak pernah diisi oleh `CreateClass` atau seeder, tetapi dipakai Flutter untuk periode. Probe: `year:''`, `semester:''`. | `handlers/class.go:16-24,48-51`; `seed/main.go:100-105`; `mobile/.../krs_tab.dart:139-157`; `nilai_tab.dart:65-85` | Period selector KRS kosong; Nilai terkelompok dalam satu periode kosong | Tambah field ke DTO + seed + backfill; fallback dari `Schedule.semester` |
| I11 | High | JSON model | Flutter membaca `nidn`/`nip` yang tidak ada di model User. | `dosen/beranda_dosen_tab.dart:66`; `backend/models/user.go:5-22`; probe `/users/me` | Identitas dosen kosong | Tambah field atau ganti ke `nim` |
| I12 | High | Authorization/data scope | `/admin/schedules/list` mengembalikan semua jadwal; Flutter mengambil 2 pertama. | `handlers/schedule.go:66-71`; `mahasiswa/beranda_tab.dart:108-110` | Mahasiswa melihat jadwal kelas lain | Endpoint jadwal per mahasiswa/kelas |
| I13 | High | Business logic | IPK dihitung `(rata-rata skor/100)*4`, SKS menjumlahkan seluruh KRS tanpa filter. | `mahasiswa/beranda_tab.dart:86-106` | Angka IPK/SKS menyesatkan | Hitung bobot SKS & konversi nilai huruf sesuai aturan akademik |
| I14 | High | Pagination | `/classes/list` default 10 per halaman; Flutter tidak mengirim `page`/`limit`. | `utils/pagination.go:12-20`; `dosen/beranda_dosen_tab.dart:51`, `nilai_dosen_tab.dart:84`, `absensi_dosen_tab.dart:330` | Dosen hanya melihat 10 kelas pertama | Kirim pagination atau endpoint ringkas "kelas saya" |
| I15 | Medium | Request | `UpdateUser` memvalidasi password lalu mengabaikannya; `CreateUser` meng-hash password kosong. | `handlers/admin.go:82,109,165-167` | Password tidak berubah / akun dengan hash kosong | Terapkan password jika diisi; wajibkan saat create |
| I16 | Medium | Validation | Tag `oneof` multi-kata tanpa tanda kutip pada Case/Document DTO. | `handlers/case.go:22`; `handlers/document.go:21`; bandingkan `khs.go:20` | Nilai status seperti "Perlu diperiksa" ditolak | Gunakan `oneof='Perlu diperiksa' ...` |
| I17 | Medium | Database | Error parsing tanggal diabaikan pada announcement/document. | `handlers/announcement.go:47-48,112-113`; `handlers/document.go:46,109` | Tanggal tersimpan `0001-01-01` | Kembalikan 400 saat parse gagal |
| I18 | Medium | Error handling | `FormatValidationError` melakukan type assertion tanpa pengecekan. | `utils/validator.go:20` | Error non-validasi dapat memicu panic | Gunakan `err.(validator.ValidationErrors)` dengan `ok` check |
| I19 | Medium | Pagination | `GetPagination` mengabaikan error Atoi dan tidak membatasi `limit` maksimal. | `utils/pagination.go:12-20` | `limit` sangat besar bisa membebani DB | Batasi 1–100; kembalikan 400 untuk nilai invalid |
| I20 | Medium | Dokumentasi | Swagger hanya 57 dari 65 route; semua QR + 2 dashboard tidak ada; skema `data` generik. | `backend/docs/swagger.json`; `main.go:123,135,142,147,239-242` | Klien tidak bisa menghasilkan DTO dari spec | Tambah anotasi untuk 8 route & skema data per endpoint |
| I21 | Medium | Konfigurasi | Base URL Flutter hardcoded `10.0.2.2:8080`; web-admin memakai port 80; Nginx tidak mem-proxy `/swagger/`. | `api_service.dart:6-9`; `web-admin/src/services/api.js:3-6`; `docker/nginx/nginx.conf:12-25` | Gagal di HP fisik/web; dokumentasi Swagger tidak konsisten | Gunakan `--dart-define` / flavor; tambah proxy swagger jika perlu |
| I22 | Medium | State/DB | Status kehadiran dosen hanya estimasi lokal; `POST /attendances` tanpa guard duplikat (berbeda dari QR scan). | `dosen/absensi_dosen_tab.dart:1590-1591`; `handlers/attendance.go:53-68`; `qr.go:163-173` | Data absensi bisa dobel atau tidak tersimpan | Endpoint upsert harian + refresh setelah submit |
| I23 | Low | JSON model | Grade hanya menyimpan `score`/`letter`; UI menampilkan Tugas/UTS/UAS sebagai `—`. | `dosen/nilai_dosen_tab.dart:412-413,857-859`; `models/grade.go:5-17` | Penilaian tampak tidak lengkap | Tambah field komponen nilai |
| I24 | Critical | Modul putus | Modul Orang Tua production memakai data kosong; 9 tab tidak ada yang memanggil API. | `orang_tua_dashboard.dart:27-29`; seluruh `orang_tua/*.dart` | Fitur orang tua tidak fungsional | Integrasikan endpoint parent/profile/announcement/schedule |
| I25 | Critical | Navigasi | QR scanner mahasiswa tidak punya route/navigasi; pencarian referensi hanya menemukan file itu sendiri. | `qr_scanner_screen.dart:5-57`; `main.dart:71-88` | Presensi QR tidak dapat diakses | Daftarkan route & tombol di tab absensi |
| I26 | High | UX integrasi | Alur lupa password menyuruh pengguna membaca log Docker untuk token reset. | `forgot_password_screen.dart:28-33`; `handlers/auth.go:171-183`; `utils/email.go:8-24` | Pengguna tidak bisa reset password sendiri | Tampilkan konfirmasi email; pastikan Mailpit/SMTP production |
| I27 | High | State | Sesi QR dosen disimpan di SharedPreferences tanpa validasi server. | `dosen/qr_generator_screen.dart:62,288-311`; `main.go:242` | QR tampak aktif setelah ditutup backend | Cek status ke `/admin/qr/active` atau endpoint khusus |
| I28 | Medium | UI | Tombol login sosial memiliki `onPressed: () {}`. | `login_screen.dart:134,144` | Kontrol palsu | Implementasi OAuth atau hapus tombol |
| I29 | Medium | Placeholder | `DummyDashboard` dan dialog simulasi absensi tetap ada. | `main.dart:93-137`; `mahasiswa/absensi_tab.dart:608-667` | Dead code dan alur simulasi menyesatkan | Hapus/setelah scanner aktif ganti dialog |
| I30 | Medium | Arsitektur | Tidak ada keputusan terdokumentasi bahwa admin/kaprodi hanya ada di web-admin. | `main.dart:71-88`; `README.md:77-81`; `web-admin/src/App.jsx:8-17` | Duplikasi ekspektasi fitur | Dokumentasikan pembagian klien atau tambah screen Flutter |
| I31 | Medium | State management | Tidak ada komponen loading/empty/error terpadu; tiap screen mengulang pola `setState` + `debugPrint`. | `api_service.dart:114-160`; `beranda_tab.dart:130-138`; `krs_tab.dart:119-127` | Inkonsistensi pesan error; 401 tidak dibedakan | Abstraksi `ApiResult<T>` + widget state standar |
| I32 | Low | Lint | 3 info lint `curly_braces_in_flow_control_structures`. | `flutter analyze`; `login_screen.dart:31-33` | Kebersihan kode | Tambah kurung kurawal |
| I33 | High | Database | Tidak ada file migrasi/SQL; skema bergantung pada AutoMigrate startup. | `backend/main.go:79-97`; tidak ada `*.sql` | Perubahan skema sulit diaudit & rollback | Migrasi versi-terkontrol (golang-migrate/goose) |
| I34 | Medium | Testing | Test backend melakukan TRUNCATE dan mensyaratkan DSN uji; test Flutter hanya `expect(1+1,2)`. | `handlers/all_test.go:24-40,54,80`; `mobile/test/basic_test.dart:4-7` | Tidak ada jaminan integrasi otomatis | Tambah kontrak test & widget test; jangan jalankan TRUNCATE di lingkungan bersama |

## Ketidaksesuaian kontrak ringkas

| Aspek | Flutter mengharapkan | Backend mengirim | Hasil |
|---|---|---|---|
| Envelope login | `data.token`, `data.role` | `{token, role}` di `data` | Sesuai (probe 200) |
| Envelope daftar kelas | `data.data` sebagai list | `{data:[...],total_data,page,limit}` di `data` | Sesuai |
| Periode KRS/Nilai | `class.year`, `class.semester` terisi | string kosong | **Tidak sesuai** |
| Identitas dosen | `nidn`/`nip` | tidak ada field | **Tidak sesuai** |
| Error 401/403 | JSON `message` | plain text | **Tidak sesuai** |
| Method HTTP | POST/PUT/DELETE sesuai Swagger | semua verb diterima | **Tidak sesuai** |
| Jadwal | jadwal mahasiswa bersifat scoped | daftar global | **Tidak sesuai** |
| Reset password | token dibaca dari UI/log | token dikirim email | **Tidak sesuai secara UX** |
| QR | generate/scan/close | tersedia, tetapi tidak ada di Swagger | Sesuai kode, dokumentasi kurang |
