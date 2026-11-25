# Audit Integrasi Flutter–Backend dan Akses Data per Peran

**Tanggal audit:** 24 November 2026
**Cakupan:** backend Go, PostgreSQL, Flutter mobile, web-admin React
**Kebijakan produk acuan:** A1 (Kaprodi hanya prodi yang ditugaskan), B2 (Mahasiswa boleh create/drop KRS), C2 (Orang tua hanya metadata dokumen anak yang tertaut)
**Status runtime E2E:** `BLOCKED / NOT RUN` — checklist environment disposable pada `RUNTIME_E2E_READINESS_CHECKLIST.md` belum lengkap.

## 1. Ringkasan Eksekutif

Integrasi Flutter–backend sudah berjalan untuk alur utama mahasiswa, dosen, dan orang tua. Backend telah memakai JWT, refresh token, revokasi sesi, dan pemeriksaan kepemilikan resource pada kelas, nilai, absensi, QR, serta relasi orang tua–anak.

Audit ini menemukan dan memperbaiki empat masalah nyata:

1. **Bug otorisasi Kaprodi pada delete** — `DELETE` dengan join scope menghasilkan SQL tanpa `FROM` untuk tabel join, sehingga permintaan di luar prodi berubah menjadi HTTP 500 dan berpotensi tidak konsisten. Diperbaiki pada kasus, dokumen, dan UKT.
2. **Endpoint jadwal global masih terbuka untuk peran non-admin** — `/admin/schedules/list` dan `/calendar` mengembalikan seluruh jadwal kampus. Keduanya kini `admin`-only karena tidak ada klien non-admin yang memakainya.
3. **Profil mandiri dapat mengubah NIM/program studi** — `PUT /users/me` menerima `nim` dan `program_studi` dari pengguna. Kini hanya `name` dan `email` yang dapat diubah sendiri; NIM/prodi tetap dikelola admin.
4. **Paginasi Flutter memotong data dosen** — daftar kelas dan mahasiswa per kelas hanya mengambil halaman pertama (default 10). Ditambahkan `ApiService.getAll` dan dipakai di beranda, nilai, dan absensi dosen.

Selain itu, profil mahasiswa tidak lagi memakai program studi hardcoded `TRKJ` dan tidak lagi hanya membaca email/role dari `SharedPreferences`; data diambil dari `/users/me`.

**Kesimpulan:** alur utama dan kontrol akses object-level sudah `CONNECTED` dengan bukti uji handler. Dua keputusan produk masih `BLOCKED / NEEDS APPROVAL`: relasi prodi terstruktur untuk Kaprodi dan status verifikasi relasi orang tua–anak.

## 2. Metode dan Bukti

### 2.1 Pemeriksaan statis
- Membaca route matrix di `backend/main.go`, middleware `backend/middlewares/auth.go`, dan seluruh handler yang menyentuh data per peran.
- Membaca service dan layar Flutter yang memanggil API: mahasiswa, dosen, orang tua, KRS, QR, profil.
- Membaca alur web-admin untuk admin dan Kaprodi.

### 2.2 Uji otomatis yang dijalankan
Database uji memakai container PostgreSQL disposable dengan `tmpfs`, bukan database bersama/production:

```text
host=127.0.0.1 user=test password=test dbname=edutrack_test port=55432 sslmode=disable
```

Hasil:

| Perintah | Hasil |
|---|---|
| `cd backend && go build ./...` | Lulus |
| `cd backend && EDUTRACK_TEST_DATABASE_DSN=... go test ./... -count=1` | Lulus seluruh paket, termasuk `handlers` |
| `cd mobile && flutter analyze` | `No issues found` |
| `cd mobile && flutter test` | 16 tes lulus |
| `cd web-admin && npm test` | 18 tes lulus |
| `cd web-admin && npm run lint` | Lulus |

Uji baru yang relevan:
- `TestAuth_UpdateProfile_DoesNotChangeAdminManagedFields` — memastikan `nim`/`program_studi` tidak berubah dari profil mandiri.
- `TestKaprodiCaseScopeAndDirectIDAccess` — memastikan delete ID di luar prodi mengembalikan 404 dan tidak menghapus data. **Catatan:** uji ini hanya untuk Cases; delete Document dan UKT telah diperbaiki pada implementasi kode namun belum memiliki regression test khusus.
- Tes `ApiService.getAll` untuk envelope paginasi dan header `X-Total-Count`.

### 2.3 Yang tidak dijalankan
- Runtime E2E login nyata + browser + Flutter terhadap stack berjalan: **tidak dijalankan** karena target disposable, akun uji, dan cleanup belum disetujui pada checklist.
- Inspeksi visual UI di browser/emulator: **tidak dilakukan**.
- Pengujian beban, race condition produksi, dan audit dependensi pihak ketiga: **di luar cakupan**.

## 3. Matriks Akses per Peran

| Area | Admin | Kaprodi | Dosen | Mahasiswa | Orang tua |
|---|---|---|---|---|---|
| Profil sendiri | `/users/me` | `/users/me` | `/users/me` | `/users/me` | `/users/me` |
| Statistik global | `/admin/stats` | Ditolak | Ditolak | Ditolak | Ditolak |
| Akun pengguna | CRUD semua role | List/create/update/delete hanya mahasiswa & dosen prodi sendiri; tidak boleh ubah role/prodi | Ditolak | Ditolak | Ditolak |
| Kelas | CRUD | Ditolak | List hanya kelas yang diampu | List kelas aktif periode berjalan (untuk KRS) | Ditolak |
| Mahasiswa per kelas | Semua kelas | Ditolak | Hanya kelas yang diampu | Ditolak | Ditolak |
| KRS | List semua | List prodi sendiri | Ditolak | Create/drop/list milik sendiri | Ditolak |
| Nilai | List semua | List prodi sendiri | Input/upsert hanya kelas yang diampu | List milik sendiri | List anak tertaut |
| Absensi | List semua | List prodi sendiri | Input hanya kelas yang diampu | List milik sendiri | List anak tertaut |
| UKT | CRUD | List/update/delete prodi sendiri | Ditolak | List milik sendiri | List anak tertaut periode berjalan |
| KHS | List/update | List/update prodi sendiri | Ditolak | Ringkasan/transkrip sendiri | Ringkasan anak tertaut |
| Kasus SP | CRUD | List/update/delete prodi sendiri | Ditolak | Ditolak | Ditolak |
| Dokumen | CRUD | List/update/delete prodi sendiri | Ditolak | Ditolak | Metadata anak tertaut |
| Pengumuman | CRUD | Baca aktif | Baca aktif | Baca aktif | Baca aktif |
| Jadwal global | CRUD + list | Ditolak | Ditolak | Ditolak | Ditolak |
| Jadwal sendiri | — | — | Ditolak | `/schedules/my` | `/parent/child/schedules` |
| QR | List sesi aktif | Ditolak | Generate/status/close hanya kelas sendiri | Scan/validate jika enrollment aktif | Ditolak |
| Relasi anak | Link | Ditolak | Ditolak | Ditolak | Hanya anak yang tertaut |

Catatan: `GET /classes/list` untuk mahasiswa memang mengembalikan kelas aktif kampus pada periode berjalan karena dipakai untuk memilih kelas KRS. Endpoint ini tidak membuka nilai, absensi, atau data pribadi mahasiswa lain.

## 4. Temuan dan Perbaikan

### P0 — Delete Kaprodi dengan join scope gagal (FIXED)

**Gejala:** `DeleteCase`/`DeleteDocument`/`DeleteUKT` membangun query ber-join lalu memanggil `Delete` dengan string ID. GORM menghasilkan SQL seperti:

```sql
DELETE FROM "cases" WHERE ("Student".role = 'mahasiswa' AND ...)
```

PostgreSQL menolak karena alias `Student` tidak memiliki `FROM` pada pernyataan `DELETE`. Hasilnya HTTP 500, bukan 404/aman.

**Perbaikan:** query scope dipakai untuk `First` (memastikan resource terlihat oleh Kaprodi), lalu record dihapus berdasarkan primary key tanpa join.

**Bukti:** `TestKaprodiCaseScopeAndDirectIDAccess` lulus; delete ID di luar prodi mengembalikan 404 dan record tetap ada. **Catatan:** uji hanya mencakup Cases; Document dan UKT telah diperbaiki pada level kode tetapi belum memiliki regression test khusus.

### P1 — Endpoint jadwal global terbuka untuk non-admin (FIXED)

`/admin/schedules/list` dan `/calendar` mengembalikan seluruh jadwal kampus. Tidak ada layar Flutter yang memakai `/calendar`; `/admin/schedules/list` hanya dipakai web-admin admin. Keduanya diubah menjadi `admin`-only.

Jika nanti dosen/mahasiswa/orang tua membutuhkan kalender, endpoint baru harus di-scope per peran, bukan membuka daftar global.

### P1 — Profil mandiri dapat mengubah data yang dikelola admin (FIXED)

`PUT /users/me` sebelumnya menulis `NIM` untuk mahasiswa/dosen dan `program_studi` untuk hampir semua role. Ini melemahkan integritas scope Kaprodi dan memungkinkan pengguna mengubah identitas akademiknya sendiri.

**Perbaikan:** profil mandiri hanya menyimpan `name` dan `email`. NIM dan program studi tetap melalui endpoint admin. DTO lama masih menerima field tersebut agar kompatibel, tetapi nilainya diabaikan.

### P1 — Paginasi daftar kelas/mahasiswa dosen terpotong (FIXED)

`GET /classes/list` dan `GET /classes/students` memakai limit default 10. Layar dosen tidak mengirim `limit` dan tidak membaca total, sehingga dosen dengan lebih dari 10 kelas atau kelas dengan lebih dari 10 mahasiswa kehilangan data.

**Perbaikan:** `ApiService.getAll` membaca envelope `{data:{data,total_data}}` maupun header `X-Total-Count`, lalu mengambil semua halaman. Dipakai di:
- `mobile/lib/screens/dosen/beranda_dosen_tab.dart`
- `mobile/lib/screens/dosen/nilai_dosen_tab.dart`
- `mobile/lib/screens/dosen/absensi_dosen_tab.dart`

### P2 — Profil mahasiswa hardcoded dan tidak membaca server (FIXED)

`profil_tab.dart` menampilkan `TRKJ` hardcoded dan hanya membaca email/role dari `SharedPreferences`. Sekarang memuat `/users/me`, menampilkan nama, NIM, email, role, dan program studi sebenarnya, dengan state loading/error/retry.

### P2 — Kontrol login dekoratif (FIXED)

Tombol Facebook dan Google di `login_screen.dart` tidak memiliki aksi. Kontrol dekoratif dihapus agar tidak menyesatkan pengguna.

### P2 — Program studi profil dosen hardcoded (FIXED)

Profil dosen kini memakai `program_studi` dari `/users/me`; konstanta institusi hanya menjadi fallback tampilan.

## 5. Kontrol Akses yang Sudah Benar

| Kontrol | Bukti kode |
|---|---|
| JWT + refresh token + revokasi sesi | `backend/config/jwt.go`, `backend/config/session.go`, `backend/middlewares/auth.go` |
| Kaprodi membaca ulang role/prodi dari DB setiap request | `backend/handlers/program_scope.go` |
| Kaprodi tanpa prodi gagal tertutup (403) | `currentProgramScope` |
| List/update/delete berbasis prodi | `scopedStudentRecords` pada user, KRS, nilai, absensi, UKT, KHS, kasus, dokumen |
| Dosen hanya kelas yang diampu | `GetStudentsByClass`, `InputGrade`, `InputAttendance`, `GenerateQR`, `GetSessionStatus`, `CloseQR` |
| Mahasiswa hanya data sendiri | `/enrollments/my`, `/grades/my`, `/attendances/my`, `/student/*`, `/schedules/my` |
| Orang tua hanya anak tertaut | `resolveChild` pada semua `/parent/child/*` |
| QR tidak bisa dipakai ulang/kedaluwarsa | `ScanQR` mengunci kelas + sesi, cek expiry, cek enrollment aktif, cek duplikat harian |
| Absensi manual tidak dobel | `InputAttendance` menolak duplikat kelas+mahasiswa+tanggal |
| Nilai bersifat upsert dengan cek kepemilikan | `InputGrade` |

## 6. Kesenjangan dan Risiko Residual

### 6.1 `BLOCKED / NEEDS APPROVAL`

1. **Relasi prodi terstruktur untuk Kaprodi.**
   Keputusan A1 mensyaratkan relasi terstruktur dan tervalidasi, bukan pencocokan teks. Saat ini penugasan masih berupa string `users.program_studi`, dibaca ulang dari DB dan dibandingkan dengan `TRIM`. Enforcement server-side sudah ada dan gagal tertutup, tetapi model data belum memenuhi keputusan A1 secara penuh. Perlu persetujuan untuk tabel/relasi prodi dan migrasi data.

2. **Status verifikasi relasi orang tua–anak.**
   `parent_students` tidak memiliki kolom status/verifikasi. Relasi hanya dapat dibuat oleh admin melalui `/admin/parents/link`, sehingga relasi admin dianggap sah. Tidak ada alur verifikasi, pencabutan, atau audit. Perlu keputusan produk sebelum menambah model/endpoint.

3. **Registrasi publik untuk role dosen/mahasiswa/orang tua.**
   `POST /register` masih terbuka dan mengizinkan role `dosen`, `mahasiswa`, `orangtua`. Pendaftaran dosen tidak diverifikasi admin. Dampak data saat ini terbatas karena backend membatasi dosen ke kelas yang diampu, tetapi integritas akun dan tata kelola role perlu keputusan produk.

### 6.2 Risiko yang diterima sementara

- `GET /classes/list` untuk mahasiswa mengembalikan seluruh kelas aktif periode berjalan. Ini diperlukan untuk pemilihan KRS, tetapi memuat informasi dosen dan jadwal kelas lain. Jika tidak diinginkan, perlu endpoint khusus `GET /classes/available` dengan field terbatas.
- `GET /admin/announcements/list` dipakai mahasiswa untuk pengumuman dan hanya mengembalikan pengumuman aktif. Ini disengaja.
- `/notifications` tersedia untuk beberapa peran; untuk dosen/orang tua tidak ada data UKT pribadi yang relevan. Tidak ditemukan kebocoran data mahasiswa lain.
- Web-admin `getAllRecords` sudah menangani paginasi, tetapi endpoint array tanpa header total dan tepat 100 record dapat berhenti di halaman pertama. Tidak ditemukan pemakaian seperti itu pada alur admin saat ini.

## 7. Status per Modul

| Modul | Status | Catatan |
|---|---|---|
| Login/logout/refresh/change password | `CONNECTED` | Token, refresh, revokasi, dan sesi Redis/memory |
| Profil sendiri | `CONNECTED` | Baca `/users/me`; update hanya nama/email |
| Dashboard mahasiswa | `CONNECTED` | Ringkasan akademik, jadwal sendiri, pengumuman aktif |
| KRS mahasiswa | `CONNECTED` | Create/drop/read ulang; validasi backend |
| Nilai & absensi mahasiswa | `CONNECTED` | Hanya data sendiri |
| Dashboard/nilai/absensi dosen | `CONNECTED` | Paginasi penuh; hanya kelas yang diampu |
| QR dosen/mahasiswa | `CONNECTED` | Kepemilikan, expiry, enrollment aktif, anti-duplikat |
| Orang tua | `CONNECTED` | Relasi admin; semua child endpoint memvalidasi relasi |
| Web admin | `CONNECTED` | CRUD dan paginasi; jadwal admin-only |
| Kaprodi | `PARTIAL` | Enforcement prodi berjalan, model relasi belum terstruktur |
| Verifikasi orang tua | `BLOCKED` | Tidak ada field/status verifikasi |

## 8. Perubahan File

Backend:
- `backend/handlers/case.go`
- `backend/handlers/document.go`
- `backend/handlers/ukt.go`
- `backend/handlers/auth.go`
- `backend/main.go`
- `backend/handlers/all_test.go`

Mobile:
- `mobile/lib/services/api_service.dart`
- `mobile/lib/screens/dosen/beranda_dosen_tab.dart`
- `mobile/lib/screens/dosen/nilai_dosen_tab.dart`
- `mobile/lib/screens/dosen/absensi_dosen_tab.dart`
- `mobile/lib/screens/dosen/profil_dosen_tab.dart`
- `mobile/lib/screens/mahasiswa/profil_tab.dart`
- `mobile/lib/screens/login_screen.dart`
- `mobile/test/api_service_test.dart`

## 9. Rekomendasi Berikutnya

1. Setujui model relasi prodi terstruktur dan migrasi data sebelum menyatakan A1 selesai.
2. Setujui model verifikasi relasi orang tua–anak (status, aktor verifikator, waktu, alasan cabut).
3. Putuskan apakah registrasi dosen/mahasiswa/orang tua tetap publik atau harus melalui admin.
4. Jalankan runtime E2E setelah checklist environment disposable, akun uji, dan cleanup disetujui.
5. Inspeksi UI pada emulator/browser untuk memastikan state loading, error, dan empty tampil benar.

## 10. Pernyataan Batas

Dokumen ini tidak mengklaim runtime E2E, pengujian browser, atau verifikasi production telah dilakukan. Bukti yang tersedia adalah pemeriksaan statis, build, unit/integration test handler dengan database disposable, serta test Flutter/web-admin yang tercantum di atas.
