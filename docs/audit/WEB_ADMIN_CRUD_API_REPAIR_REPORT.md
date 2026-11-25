# Laporan Audit dan Perbaikan Web Admin, CRUD, dan Kontrak API

Tanggal: 2026-11-23
Ruang lingkup: `web-admin/`, backend Go yang diperlukan, dokumentasi API, dan konfigurasi penyajian lokal/container. Kode aplikasi mobile tidak diubah.

Catatan: Bagian 1–12 mencatat audit/perbaikan web-admin terdahulu. Status integrasi Flutter–backend dan validasi terbaru diperbarui pada §13; bila ada perbedaan, gunakan addendum tersebut untuk kondisi worktree saat ini.

## 1. Ringkasan kondisi awal

Repository berada pada branch `main` dengan perubahan lokal yang belum di-commit ketika audit dilanjutkan. Perubahan tersebut dipertahankan; tidak ada reset, penghapusan data, migrasi destruktif, atau deployment production.

Audit membandingkan implementasi saat ini dengan laporan Flutter/backend sebelumnya. Temuan lama tidak dianggap otomatis masih berlaku. Perubahan penting yang masih perlu ditangani pada tahap ini adalah:

- Dashboard Prodi menampilkan statistik, grafik, aktivitas, identitas, dan periode hardcoded; pengambilan data gagal tidak dibedakan dari data kosong.
- Sejumlah form mengirim field atau tanggal yang tidak sesuai DTO backend. Beberapa CRUD kelas/paket/jadwal memakai endpoint atau payload yang keliru.
- Periode kelas dan relasi kelas–paket harus disimpan konsisten pada kolom FK dan relasi tabel paket.
- Ada batasan role pada endpoint, tetapi tindakan kaprodi terhadap akun admin/kaprodi perlu dibatasi juga pada operasi delete.
- Swagger yang ada tidak mencakup seluruh operasi runtime dan method KHS sebelumnya tidak sama dengan method aktual.
- Konfigurasi Nginx hanya mem-proxy API; tidak ada layanan yang menyajikan hasil build web-admin. Vite juga belum memiliki proxy API untuk development.
- Dependensi frontend memiliki advisory high pada dependency produksi `follow-redirects`.

## 2. Matriks role dan permission

Role yang benar-benar ditemukan di backend: `admin`, `kaprodi`, `dosen`, `mahasiswa`, dan `orangtua`. Tidak ada role baru yang ditambahkan.

| Role | Akses yang terdaftar | Batasan dan catatan |
|---|---|---|
| `admin` | Seluruh endpoint `adminRoles` dan `allRoles`; statistik admin; mengelola akun termasuk role istimewa; menautkan akun orang tua–mahasiswa. | Statistik dan tautan orang tua khusus admin. |
| `kaprodi` | Endpoint yang diizinkan untuk `admin`/`kaprodi`, termasuk CRUD akademik dan daftar data admin. | Backend kini menolak kaprodi membuat, mengubah, atau menghapus akun `admin`/`kaprodi`. Endpoint list masih memberikan data global, bukan scope per program studi. |
| `dosen` | Endpoint bersama, daftar mahasiswa per kelas yang diajar, input nilai/kehadiran, dan pengelolaan sesi QR miliknya. | QR dicek terhadap dosen pemilik kelas/sesi. Beberapa endpoint list bersama masih bersifat global. |
| `mahasiswa` | Endpoint bersama, enrollment/KRS milik sendiri, nilai/kehadiran dan ringkasan akademik milik sendiri, serta scan/validasi QR. | Kelas untuk mahasiswa dapat dibatasi backend ke periode aktif; endpoint personal menggunakan identitas token. |
| `orangtua` | Endpoint bersama dan endpoint anak yang ditautkan: profil, ringkasan, nilai, kehadiran, jadwal, UKT, dokumen, pengumuman. | Data anak bergantung pada relasi parent–student di backend. |

`allRoles` adalah lima role tersebut; `adminRoles` adalah `admin` dan `kaprodi`. Login/refresh/reset/register bersifat publik sesuai handler. Registrasi publik hanya menerima `dosen`, `mahasiswa`, atau `orangtua`; role `admin`/`kaprodi` tidak dapat dibuat melalui registrasi publik.

**Batas audit:** allow-list route dan beberapa pemeriksaan ownership sudah diperiksa, tetapi batas akses berbasis program studi/row-level untuk data global belum dibuktikan atau diterapkan menyeluruh. Perlu keputusan bisnis dan pengujian tersendiri sebelum memakai akses lintas program pada data produksi.

## 3. Endpoint dan kontrak API yang diaudit

Sumber route/method/allow-list: `backend/main.go`; envelope: `backend/utils/response.go`; dokumentasi spesifikasi: `backend/docs/swagger.json` dan `backend/docs/swagger.yaml`.

| Kelompok | Operasi utama | Role route |
|---|---|---|
| Auth dan sesi | `POST /register`, `/login`, `/refresh-token`, `/logout`, `/change-password`, `/forgot-password`, `/reset-password`; `GET/PUT /users/me` | Publik untuk autentikasi/registrasi/reset/refresh; `allRoles` untuk sesi dan profil |
| Akun web | `GET /admin/users`; `POST /admin/users/create`; `PUT /admin/users/update?id=...`; `DELETE /admin/users/delete?id=...` | `adminRoles`; kaprodi dibatasi dari akun admin/kaprodi |
| Mata kuliah dan kelas | CRUD `/courses` dengan daftar `/courses/list`; CRUD `/classes` dengan daftar `/classes/list` | Mutasi `adminRoles`; daftar kelas juga dipakai `allRoles`; daftar courses `adminRoles` |
| Paket dan jadwal | CRUD `/admin/packages`; CRUD `/admin/schedules`; daftar masing-masing berakhiran `/list` | Mutasi `adminRoles`; daftar jadwal juga tersedia untuk `allRoles` |
| Enrollment/KRS | `POST /enrollments`, `/enrollments/drop`; `GET /enrollments/my`, `/admin/krs/list`, `/classes/students` | Mahasiswa untuk enrollment sendiri; daftar KRS admin `adminRoles`; daftar kelas dosen untuk `adminRoles`/dosen |
| Nilai/kehadiran | `POST /grades`, `/attendances`; GET personal `/grades/my`, `/attendances/my`; daftar admin berakhiran `/list` | Dosen menulis; mahasiswa membaca milik sendiri; daftar admin `adminRoles` |
| UKT, pengumuman, kasus, dokumen | CRUD pada `/admin/ukt`, `/admin/announcements`, `/admin/cases`, `/admin/documents`; daftar berakhiran `/list` | Mutasi `adminRoles`; pembacaan pengumuman juga untuk `allRoles`; daftar lain mengikuti allow-list route |
| KHS dan periode | `GET /admin/khs/list`; `PUT /admin/khs/update`; `GET /admin/academic/period-reconciliation` | `adminRoles` |
| Data mahasiswa | `GET /student/academic/summary`, `/student/khs`, `/student/transcript`, `/student/ukt/my`, `/schedules/my` | Mahasiswa |
| Orang tua | `/parent/children`, `/parent/child/{profile,summary,grades,attendances,schedules,ukt,documents}`, `/parent/announcements` | Orang tua |
| QR | `POST /qr/generate`, `/qr/scan`, `/qr/validate`, `/qr/close`; `GET /qr/session`, `/admin/qr/active` | Generate/session/close dosen; scan/validate mahasiswa; sesi aktif `adminRoles` |
| Umum | `GET /calendar`, `/notifications`, `/api/health`; dashboard role masing-masing | Kalender/notifikasi `allRoles`; dashboard sesuai role; health publik |

Kontrak umum yang diverifikasi:

- Response memakai envelope `{ "status", "message", "data" }`; kesalahan validasi/izin/not-found menggunakan status HTTP yang sesuai dan pesan JSON.
- ID relasi dikirim sebagai angka; endpoint update/delete yang ada memakai query `id`.
- Daftar `/admin/users`, `/courses/list`, dan `/classes/list` memiliki envelope pagination di `data`: `{ data, total_data, page, limit }`. Daftar lain umumnya mengembalikan array langsung di `data`; helper frontend menangani kedua bentuk dan mengambil seluruh halaman yang tersedia.
- Field penting CRUD: kelas memakai `course_id`, `dosen_id`, `year`, `semester` (`Ganjil`/`Genap`), `start_time`, `end_time`, `package_id`; paket memakai `name`, `term`, `status`, `course_ids`, `class_ids`; jadwal memakai `class_id`, `course_id`, `teacher_id`, `semester`; UKT/pengumuman/dokumen memakai tanggal `YYYY-MM-DD`.
- API method kini ditegakkan; method lain mendapat `405 Method Not Allowed` dan header `Allow`.
- Swagger dibangkitkan dari anotasi backend. Pemeriksaan otomatis lokal mencocokkan 85 operasi `/api/v1` (termasuk `GET/PUT /users/me`) dan tidak menemukan operasi yang hilang dari Swagger.

## 4. Daftar temuan dan perbaikan

| Modul/fitur | Lokasi kode | Masalah dan dampak | Solusi | Pengujian |
|---|---|---|---|---|
| Dashboard Prodi | `web-admin/src/prodi/ProdiDashboard.jsx` | Angka/grafik/aktivitas, periode, dan identitas statis terlihat seperti data backend; risiko pengguna mengambil keputusan dari data palsu. | Statistik kini dihitung dari API; grafik dan aktivitas demo dihapus; identitas/periode mengikuti data sesi/API; loading, error, empty dibedakan. | Lint/build; smoke test login pada desktop dan viewport 390px. Dashboard berautentikasi belum dapat diuji tanpa backend/akun. |
| CRUD mahasiswa | `web-admin/src/admin/AdminAcademicDashboard.jsx`, `web-admin/src/prodi/ProdiDashboard.jsx` | Email/password default palsu dan payload tidak memuat semua DTO membuat akun salah atau gagal tersimpan. | Form memakai field aktual, password wajib saat create dan opsional saat update; tidak membuat email/password sintetis; error backend dapat ditampilkan di field yang cocok. | Build/lint; pengujian persistence memerlukan database uji. |
| CRUD kelas–paket | `backend/handlers/class.go`, `backend/handlers/package.go`, kedua dashboard | FK `package_id` dan relasi many-to-many dapat berbeda; formulir mengirim semester gabungan yang salah. | Sinkronisasi relasi kelas–paket dilakukan dalam transaksi; UI mengirim tahun dan semester terpisah serta mengelola relasi paket. | API+DB disposable mengonfirmasi `package_id` dan `package_classes`; kelas/paket dapat dibaca ulang. |
| CRUD paket dan jadwal | `web-admin/src/admin/AdminAcademicDashboard.jsx`, `web-admin/src/prodi/ProdiDashboard.jsx` | Operasi paket pernah memakai endpoint courses; jadwal bisa menyimpan course/dosen yang tidak cocok dengan kelas. | Paket memakai `/admin/packages` dan pilihan relasi; jadwal memakai endpoint jadwal dan mengambil course/dosen dari kelas yang dipilih. | API+DB disposable lulus; form UI selain mahasiswa belum diuji. |
| CRUD UKT/pengumuman/kasus/dokumen | Dashboard admin dan Prodi; handler terkait di `backend/handlers/` | Bentuk tanggal, status, dan nama field tidak konsisten; beberapa payload fallback menghasilkan data yang tidak pernah dipilih pengguna. | Form dipadankan ke DTO; tanggal dikirim `YYYY-MM-DD`; validasi UI/backend dan konfirmasi hapus; kesalahan backend tidak dianggap sukses. | API+DB disposable lulus untuk seluruh operasi yang tersedia; form UI belum diuji end-to-end. |
| KHS | `web-admin/src/admin/AdminAcademicDashboard.jsx`, `backend/handlers/khs.go` | Method frontend/runtime dan spesifikasi berbeda; UI tidak boleh mengklaim IPS yang tak diberikan backend. | Update menggunakan PUT; status divalidasi; UI tidak menghitung atau mengklaim IPS/IPK yang tidak tersedia dari endpoint admin. | Build; spesifikasi Swagger diverifikasi memuat PUT. |
| Hak akses akun | `backend/handlers/admin.go`, `backend/utils/access.go` | Kaprodi dapat mencoba operasi terhadap akun dengan role istimewa, khususnya delete. | Pemeriksaan role hierarchy dipakai create/update/delete; hanya admin dapat mengelola akun admin/kaprodi. | Handler test dan HTTP API disposable lulus; pembuatan akun berhak istimewa oleh kaprodi menghasilkan 403. |
| Sesi dan route | `web-admin/src/services/api.js`, `RequireRole.jsx`, `App.jsx`, `Login.jsx`; `backend/middlewares/auth.go`, `backend/utils/http.go` | Role frontend hanya dari storage dan method API tidak ditegakkan; sesi habis dapat meninggalkan tampilan yang menyesatkan. | Route memverifikasi `/users/me`; token refresh/logout diintegrasikan; middleware mengembalikan envelope JSON; method route dibatasi. | API login admin/kaprodi, 401 tanpa/invalid token, dan unit router diuji. UI admin tidak diuji karena kredensial staging yang valid tidak tersedia; token expired asli belum diuji. |
| Pagination dan error API | `web-admin/src/services/api.js`, `backend/utils/pagination.go` | UI dapat berhenti pada halaman pertama atau menerima bentuk daftar yang salah tanpa penjelasan. | Helper mengambil semua halaman dan menolak bentuk response yang tidak sesuai kontrak; parameter pagination divalidasi. | `go test ./utils`; build frontend. |
| Swagger/API | `backend/main.go`, `backend/handlers/qr.go`, `backend/handlers/khs.go`, `backend/docs/*` | Operasi dashboard/QR tidak terdokumentasi dan method KHS salah. | Menambahkan anotasi endpoint; menghasilkan ulang `docs.go`, JSON, YAML; seluruh 85 operasi route tercakup. | Swagger generation dan pembandingan route otomatis berhasil. Generator memberi warning evaluasi konstanta runtime, tetapi menghasilkan dokumen lengkap. |
| Penyajian web | `web-admin/vite.config.js`, `web-admin/Dockerfile`, `web-admin/nginx.conf`, `docker/nginx/nginx.conf`, `docker/docker-compose.yml` | Nginx sebelumnya tidak menyajikan frontend; Vite development tidak mem-proxy API same-origin. | Menambah static web-admin container dengan fallback SPA; Nginx mem-proxy `/api/` dan `/swagger/`; Vite memiliki target proxy konfigurabel. | `docker compose config`, build image web-admin, dan `nginx -t` berhasil. |
| Dependensi produksi | `web-admin/package-lock.json` | Audit npm menemukan advisory high pada `follow-redirects` versi transitif. | Menjalankan perbaikan kompatibel pada lockfile. | `npm audit`: 0 vulnerability. |

## 5. Perbaikan CRUD web-admin

| Modul | Status implementasi |
|---|---|
| Mahasiswa dan dosen | Create/update/delete memakai endpoint akun; input aktual, tanpa credential default; backend memproteksi role istimewa. |
| Mata kuliah | CRUD admin mengirim `code`, `name`, `sks`, dan semester numerik sesuai DTO backend. |
| Kelas | CRUD memakai course/dosen aktual, periode `year` + `semester`, waktu, ruang, status, dan paket opsional. |
| Paket | CRUD paket memakai `course_ids` wajib dan `class_ids` opsional; frontend admin dan Prodi memakai endpoint paket. |
| Jadwal | CRUD jadwal memakai kelas terpilih; course dan dosen diturunkan dari relasi kelas agar konsisten. |
| UKT | CRUD mengirim nominal numerik dan tanggal jatuh tempo ISO tanggal; UI menghitung tunggakan dari nominal server. |
| Pengumuman | CRUD memakai content, kategori, tanggal mulai/akhir, dan status dari form. |
| Kasus | CRUD memakai mahasiswa, level, alasan, tindak lanjut, dan status yang dikirim ke backend. |
| Dokumen | CRUD tersedia pada dashboard admin menggunakan field DTO backend. |
| KRS, nilai, kehadiran | Ditampilkan sebagai data baca-saja di web-admin karena route tulis yang ada diperuntukkan bagi mahasiswa/dosen, bukan web-admin. |
| KHS | Status publikasi diperbarui melalui endpoint PUT; IPS/IPK tidak dibuat-buat. |
| Pengajuan koreksi dan pengaturan Prodi | Tidak ada endpoint backend terkait. UI menyatakan fitur belum tersedia, bukan menampilkan daftar kosong seolah-olah data server. |

Operasi update/delete tidak menghapus data dari UI sebelum backend memberi respons sukses. Hapus memakai konfirmasi; error backend ditampilkan. Pada operasi list, status loading/error/empty dibedakan dan tidak ada fallback data dummy.

## 6. Perbaikan desain web-admin

- Ringkasan dashboard admin dan Prodi menggunakan data hasil API; grafik statis dan angka demo Prodi dihilangkan.
- Identitas pengguna dan periode tidak lagi memakai nama/periode hardcoded.
- State loading/error/empty dan feedback operasi ditampilkan dengan jelas.
- Form memvalidasi field wajib, relasi, tanggal, nominal, serta menampilkan pesan validasi backend pada field terkait bila pemetaan tersedia.
- Penggunaan tampilan yang sudah ada dipertahankan; perubahan tidak menghapus modul. Fitur tanpa endpoint dinyatakan belum tersedia.
- Web-admin kini memiliki jalur penyajian container dan SPA fallback. Seluruh menu Prodi diperiksa setelah login pada desktop (1280px) dan mobile (390px), tanpa console/page error; CSS membatasi overflow dokumen sambil mempertahankan scroll horizontal di tabel. Dashboard Admin setelah login belum dapat diperiksa karena tidak tersedia kredensial admin staging yang valid.

## 7. File yang diubah pada audit web-admin awal

- **Backend:** `backend/config/{academic.go,jwt.go,session.go}`; `backend/handlers/{admin.go,academic.go,all_test.go,announcement.go,attendance.go,auth.go,case.go,class.go,course.go,document.go,enrollment.go,grade.go,khs.go,package.go,parent.go,qr.go,schedule.go,ukt.go}`; `backend/middlewares/{auth.go,cors.go}`; model `attendance.go`, `class.go`, `course.go`, `enrollment.go`, `grade.go`, `package.go`, `parent_student.go`, `qr_session.go`, `user.go`; `backend/utils/{access.go,access_test.go,http.go,http_test.go,pagination.go,pagination_test.go,response.go,validator.go,email.go}`; `backend/main.go`; `backend/go.sum`; `backend/docs/{docs.go,swagger.json,swagger.yaml}`.
- **Web-admin:** `web-admin/src/App.jsx`, `src/components/RequireRole.jsx`, `src/pages/Login.jsx`, `src/services/api.js`, `src/admin/AdminAcademicDashboard.jsx`, `src/admin/components/{AdminHeader.jsx,AdminSidebar.jsx}`, `src/prodi/ProdiDashboard.jsx`, `src/prodi/ProdiDashboard.css`, `vite.config.js`, `package-lock.json`; ditambahkan `web-admin/Dockerfile`, `web-admin/nginx.conf`, `web-admin/.dockerignore`.
- **Deployment:** `docker/docker-compose.yml`, `docker/nginx/nginx.conf`.
- **Laporan:** `docs/audit/WEB_ADMIN_CRUD_API_REPAIR_REPORT.md`.

Pada audit web-admin awal, tidak ada file di `mobile/` yang diubah. Perubahan mobile dan backend pada pekerjaan integrasi berikutnya dicatat pada §13.

## 8. Hasil pengujian

| Pemeriksaan | Hasil |
|---|---|
| `cd backend && go test ./...` dengan `EDUTRACK_TEST_DATABASE_DSN` ke DB disposable | Lulus terhadap PostgreSQL disposable `edutrack_test`; suite handler hanya dijalankan pada database ini. `TestMain` menjalankan `TRUNCATE ... CASCADE`, sehingga hasil ini bukan pengujian terhadap DB lain. |
| `cd backend && go build ./...` | Lulus. |
| `cd web-admin && npm test` | Lulus, 3 tes helper payload/mutasi. |
| `cd web-admin && npm run lint` | Lulus. |
| `cd web-admin && npm run build` | Lulus setelah perubahan CSS responsif. |
| `cd web-admin && npm audit` | Lulus, 0 vulnerability setelah lockfile diperbarui. |
| `docker compose -f docker/docker-compose.yml config --quiet` | Lulus. |
| `docker compose -f docker/docker-compose.yml build web-admin` | Lulus; image berhasil dibangun. |
| `docker run --rm docker-web-admin:latest nginx -t` | Lulus. |
| Swagger route coverage | 85 operasi API dibandingkan; tidak ada operasi terdaftar yang hilang dari Swagger. |
| API HTTP + database disposable | CRUD API diuji untuk users, courses, classes, packages, schedules, UKT, announcements, cases, dan documents. KHS diuji untuk GET/PUT; endpoint delete memang tidak tersedia. Baca ulang melalui API dan pemeriksaan DB dilakukan untuk perubahan uji. |
| Auth/authorization | Login admin dan kaprodi berhasil pada pengujian API; tanpa token/token invalid menghasilkan 401; kaprodi membuat akun berhak istimewa ditolak 403. Token yang benar-benar kedaluwarsa belum diuji. |
| UI CRUD | Form mahasiswa berhasil create/read/update (termasuk mengosongkan NIM/program studi)/delete dengan konfirmasi; perubahan database diverifikasi. Form UI modul lain belum diuji end-to-end. |
| UI Prodi desktop | Semua 14 menu dibuka; tidak ada console/page error dan tidak ada document overflow di viewport 1280px. |
| UI Prodi mobile | Semua 14 menu dibuka di viewport 390px; tidak ada console/page error. Sebelum perbaikan, halaman Mahasiswa/KHS melebar; sesudahnya dokumen tidak lagi melebar dan tabel tetap memiliki scroll internal. |
| UI Admin | Belum teruji setelah login: kredensial admin yang tersedia untuk percobaan tidak autentikasi ke akun pada DB ini (401); akun staging dengan kredensial yang sah tidak tersedia di sesi. Tidak ada operasi UI admin yang diklaim lulus. |

## 9. Verifikasi integrasi API

Pengujian menggunakan PostgreSQL disposable bernama `edutrack_test` dalam container `edutrack-crud-test-db-20261123`, penyimpanan `tmpfs`, dan port loopback `15439`. Backend uji berjalan pada `127.0.0.1:18080`, web-admin pada `127.0.0.1:15173`. Nama DB dan konfigurasi container diperiksa sebelum menjalankan handler test; tidak ada koneksi ke database/container EduTrack lain. Role `admin` dipakai untuk operasi API CRUD; role `kaprodi` digunakan untuk pemeriksaan login/authorization. Pengujian ini tidak menyentuh production.

Backend pengujian mencatat Redis tidak tersedia di jaringan test dan beralih ke session store process-local. Pengujian ini berjalan pada satu instance; persistensi sesi lintas instance/Redis belum diverifikasi.

| Modul | Endpoint yang diuji | Role | Hasil API + persistence | UI |
|---|---|---|---|---|
| Mahasiswa dan dosen | `/admin/users`, `/admin/users/create`, `/admin/users/update?id=…`, `/admin/users/delete?id=…` | `admin` | CRUD berhasil; GET dan query DB membuktikan data tersimpan/berubah. Update string kosong mengosongkan field opsional. Penghapusan akun yang direferensikan menghasilkan 409 dan record tetap ada. | Mahasiswa: create/read/update/clear optional fields/delete berhasil melalui UI. Dosen: UI belum diuji. |
| Mata kuliah | `GET /courses/list`, `POST /courses`, `PUT /courses/update?id=…`, `DELETE /courses/delete?id=…` | `admin` | CRUD API dan baca ulang berhasil. Delete saat masih direferensikan menghasilkan 409; record tidak hilang. | Belum diuji end-to-end. |
| Kelas | `GET /classes/list`, `POST /classes`, `PUT /classes/update?id=…`, `DELETE /classes/delete?id=…` | `admin` | CRUD API dan baca ulang berhasil; tahun/semester serta `package_id` tersimpan. Relasi FK dan `package_classes` diverifikasi konsisten. Delete saat masih direferensikan menghasilkan 409. | Belum diuji end-to-end. |
| Paket | `GET /admin/packages/list`, `POST /admin/packages`, `PUT /admin/packages/update?id=…`, `DELETE /admin/packages/delete?id=…` | `admin` | CRUD API dan baca ulang berhasil; relasi kelas/mata kuliah diverifikasi. | Belum diuji end-to-end. |
| Jadwal | `GET /admin/schedules/list`, `POST /admin/schedules`, `PUT /admin/schedules/update?id=…`, `DELETE /admin/schedules/delete?id=…` | `admin` | CRUD API dan baca ulang berhasil; mata kuliah dan dosen mengikuti kelas terpilih. | Belum diuji end-to-end. |
| UKT | `GET /admin/ukt/list`, `POST /admin/ukt`, `PUT /admin/ukt/update?id=…`, `DELETE /admin/ukt/delete?id=…` | `admin` | CRUD API dan baca ulang berhasil; format tanggal dan nominal divalidasi. | Belum diuji end-to-end. |
| Pengumuman | `GET /admin/announcements/list`, `POST /admin/announcements`, `PUT /admin/announcements/update?id=…`, `DELETE /admin/announcements/delete?id=…` | `admin` | CRUD API dan baca ulang berhasil. | Belum diuji end-to-end. |
| Kasus | `GET /admin/cases/list`, `POST /admin/cases`, `PUT /admin/cases/update?id=…`, `DELETE /admin/cases/delete?id=…` | `admin` | CRUD API dan baca ulang berhasil. | Belum diuji end-to-end. |
| Dokumen | `GET /admin/documents/list`, `POST /admin/documents`, `PUT /admin/documents/update?id=…`, `DELETE /admin/documents/delete?id=…` | `admin` | CRUD API dan baca ulang berhasil. | Belum diuji end-to-end. |
| KHS | `GET /admin/khs/list`, `PUT /admin/khs/update` | `admin` | GET/PUT dan baca ulang berhasil. Tidak ada endpoint delete pada kontrak/backend; delete tidak dijalankan. | Halaman KHS Prodi dibuka, tetapi update UI belum diuji. |

Pengujian tambahan membuktikan pagination/pencarian, periode tahun/semester, relasi kelas–paket, relasi jadwal, tanggal/nominal UKT, serta perlindungan delete foreign key. Untuk method/status delete berelasi, HTTP 409 dipastikan tidak menghapus data. Token invalid dan tanpa token memberi 401; token kedaluwarsa sebenarnya belum dibuat/dijalankan.

Temuan dan perbaikan yang dipicu pengujian:

- `saveRecord` membentuk payload semua modul sekaligus dan mencoba membaca properti kelas jadwal yang `null`, sehingga create mahasiswa gagal sebelum request. Pemilihan mutasi dipindah ke helper `apiMutations.js`; ditambahkan 3 tes regresi di `apiMutations.test.js`.
- Handler update akun semula tidak dapat membedakan field opsional yang dihilangkan dari field yang sengaja dikosongkan. Field pointer pada `admin.go` memperbaiki semantik tersebut; tes membuktikan nilai kosong tersimpan sementara field yang tidak dikirim tetap terjaga.
- Delete akun, mata kuliah, atau kelas yang masih direferensikan semula menghasilkan 500. `admin.go`, `course.go`, `class.go`, dan `utils/http.go` kini memetakan SQLSTATE FK `23503` menjadi 409 Conflict; handler test memastikan record referensi tetap utuh.
- Sidebar Prodi sebelumnya menampilkan identitas demo; `ProdiSidebar.jsx` dan `ProdiDashboard.jsx` kini menggunakan identitas sesi. Tabel Mahasiswa/KHS sebelumnya melebarkan dokumen pada mobile; `.prodi-table-scroll` di `ProdiDashboard.css` kini membatasi paint overflow hanya pada viewport mobile tanpa mematikan scroll tabel.

Tidak ada klaim bahwa perubahan web sudah terbaca melalui aplikasi mobile. Kode mobile tidak diubah; kompatibilitasnya hanya ditinjau dari route dan struktur kontrak backend. Integrasi mobile runtime masih perlu diuji terpisah.

## 10. Temuan yang belum terselesaikan, risiko, dan pekerjaan lanjutan

1. **Row-level scope Prodi:** route `adminRoles` saat ini memberi akses ke data akademik global; perlu konfirmasi aturan akses lintas program studi sebelum membuka data produksi.
2. **Web-admin Admin UI:** semua endpoint API CRUD telah diuji, tetapi halaman Admin setelah login dan form CRUD-nya belum. Perlu akun admin staging yang valid untuk pengujian UI desktop/mobile, network requests, dan console.
3. **UI CRUD lainnya:** selain alur mahasiswa, form CRUD untuk dosen, mata kuliah, kelas, paket, jadwal, UKT, pengumuman, kasus, dan dokumen belum dibuktikan melalui browser. Hasil API tidak menggantikan pengujian UI tersebut.
4. **Auth:** token invalid/no-token diuji, tetapi expiry/refresh dengan token kedaluwarsa belum diuji.
5. **Mobile:** jalankan smoke test setiap role (`mahasiswa`, `dosen`, `orangtua`) terhadap backend versi ini. Khusus kontrak kelas/periode, KHS, jadwal, pengumuman, sesi QR, refresh token, logout, dan error JSON.
6. **Endpoint yang belum tersedia:** pengajuan koreksi/pengaturan Prodi tetap belum memiliki kontrak backend; KHS tidak menyediakan delete. Fitur tanpa endpoint tidak boleh dianggap memiliki CRUD penuh.
7. Redis tidak tersedia pada jaringan test; verifikasi session store Redis dan sesi lintas instance masih diperlukan pada staging yang menyediakan Redis.
8. Tidak dilakukan deployment, migrasi terhadap database aktif, atau pengujian dengan data produksi. Setelah validasi, backend/Vite uji dihentikan, container DB disposable terhapus, jaringan uji dihapus, dan port 15173/18080/15439 diverifikasi tertutup.

## 11. Langkah menjalankan dan menguji

- Development web: dari `web-admin/`, jalankan `npm ci`, lalu `npm run dev`. Proxy API default mengarah ke `http://localhost:8080`; dapat diubah dengan `VITE_API_PROXY_TARGET`.
- Validasi frontend: dari `web-admin/`, jalankan `npm run lint`, `npm run build`, dan `npm audit`.
- Validasi backend aman: dari `backend/`, jalankan `go test ./utils` dan `go build ./...`.
- Full local stack: isi environment Compose lokal secara aman, lalu dari `docker/` jalankan `docker compose up --build`; buka web-admin di `http://localhost` dan Swagger di `http://localhost/swagger/`. Jangan gunakan environment production untuk langkah ini.
- Handler integration test hanya boleh dijalankan jika `EDUTRACK_TEST_DATABASE_DSN` menunjuk ke database disposable khusus bernama `edutrack_test`.
- Smoke test UI membutuhkan akun staging yang sah untuk masing-masing role web; jangan memakai akun/data production. Hasil pengujian dalam laporan ini hanya mencakup alur UI mahasiswa dan smoke test navigasi Prodi yang disebutkan di bagian 8-9.

## 12. Tahap browser E2E lanjutan — BLOCKED

Waktu pemeriksaan: 2026-11-23 17:31 WIB. Branch `main`, `HEAD` yang diperiksa `cb4e5a6`; revisi ini **tidak diuji E2E**. Perubahan lokal tetap ada dan tidak di-reset. Browser/automation tidak dijalankan. Tidak ada perubahan kode aplikasi, login, request CRUD, atau akses ke database pada tahap ini.

**Pemeriksaan keamanan environment:**

- `README.md` hanya mendokumentasikan stack **development** (`docker compose up`) dan seeder. Dokumentasi tersebut tidak menetapkan database disposable, isolasi dari production, atau prosedur cleanup terbatas untuk browser E2E.
- File `docker/.env` tersedia tetapi **tidak dibuka** karena dapat memuat secret. Tidak ada nilai environment/credential yang dibaca atau dicetak. Akibatnya target database dari file itu tidak dapat diverifikasi aman.
- Docker menampilkan service `edutrack-nginx`, `edutrack-backend`, `edutrack-db`, `edutrack-redis`, dan `edutrack-mailpit` dalam keadaan aktif, dengan port yang dipublikasikan. Status/isi database dan klasifikasi service tersebut sebagai staging/disposable tidak dapat dibuktikan dari dokumentasi yang tersedia; service itu **tidak diakses atau diubah**.
- Container disposable bernama khusus dari pengujian sebelumnya sudah tidak ada; port test `15173`, `18080`, dan `15439` tertutup. Browser tab lokal yang dibagikan tidak memiliki web/backend aktif.
- README juga menyebut akun bawaan seeder, tetapi akun itu tidak dipakai: dokumentasi akun tidak membuktikan bahwa database aktif aman atau disposable. Kredensial Admin staging yang sah belum diberikan. Akun Prodi sebelumnya terikat pada DB disposable yang telah dihapus.

Dengan prasyarat tersebut, status tahap browser adalah **BLOCKED sebelum login**. Tidak ada browser automation yang dijalankan, tidak ada request/response atau screenshot baru, tidak ada data uji yang dibuat, dan tidak ada cleanup data/container aktif. Tidak ada API test sebelumnya yang diulang atau diklaim sebagai browser E2E.

Status operasi: `BLOCKED` = form/halaman yang ada tidak dapat diuji dengan aman sampai environment dan akun tersedia; `N/A` = operasi/halaman memang bukan bagian dari web role tersebut atau endpoint belum tersedia. API/persistence pada kolom terakhir hanya menunjuk ke bukti historis di §9, bukan bukti browser.

| Fitur | Role | Create UI E2E | Read UI E2E | Update UI E2E | Delete UI E2E | Bukti API/persistence historis (bukan E2E tahap ini) |
|---|---|---|---|---|---|---|
| Login/dashboard/navigasi | Admin | N/A | BLOCKED | N/A | N/A | Login API pernah diuji; halaman browser belum. |
| Login/dashboard/navigasi | Kaprodi | N/A | BLOCKED | N/A | N/A | Login API pernah diuji; halaman browser belum. |
| Mahasiswa | Admin | BLOCKED | BLOCKED | BLOCKED | BLOCKED | CRUD API/readback Admin tercatat di §9. Alur UI mahasiswa sebelumnya tercatat, tetapi role sesi tidak terdokumentasi dan tidak diberi status role-specific di sini. |
| Mahasiswa | Kaprodi | BLOCKED | BLOCKED | BLOCKED | BLOCKED | Hak istimewa akun diuji terpisah; CRUD persistence biasa oleh Kaprodi belum diverifikasi per role. |
| Dosen/akun | Admin | BLOCKED | BLOCKED | BLOCKED | BLOCKED | CRUD akun API/readback Admin tercatat di §9; browser belum diuji. |
| Dosen/akun | Kaprodi | N/A | N/A | N/A | N/A | Tidak ada bukti UI Prodi untuk mengelola akun dosen; pembuatan akun berhak istimewa ditolak 403 pada pengujian sebelumnya. |
| Mata kuliah | Admin | BLOCKED | BLOCKED | BLOCKED | BLOCKED | CRUD API/readback Admin tercatat di §9. |
| Mata kuliah | Kaprodi | N/A | BLOCKED | N/A | N/A | Tidak ada halaman CRUD langsung; pemilihan di form terkait belum diuji browser. |
| Kelas | Admin | BLOCKED | BLOCKED | BLOCKED | BLOCKED | CRUD API/readback Admin serta relasi/periode tercatat di §9. |
| Kelas | Kaprodi | BLOCKED | BLOCKED | BLOCKED | BLOCKED | Tidak ada persistence CRUD yang diverifikasi khusus dengan role Kaprodi. |
| Paket | Admin | BLOCKED | BLOCKED | BLOCKED | BLOCKED | CRUD API/readback Admin tercatat di §9. |
| Paket | Kaprodi | BLOCKED | BLOCKED | BLOCKED | BLOCKED | Tidak ada persistence CRUD yang diverifikasi khusus dengan role Kaprodi. |
| Jadwal | Admin | BLOCKED | BLOCKED | BLOCKED | BLOCKED | CRUD API/readback Admin tercatat di §9. |
| Jadwal | Kaprodi | BLOCKED | BLOCKED | BLOCKED | BLOCKED | Tidak ada persistence CRUD yang diverifikasi khusus dengan role Kaprodi. |
| UKT | Admin | BLOCKED | BLOCKED | BLOCKED | BLOCKED | CRUD API/readback Admin tercatat di §9. |
| UKT | Kaprodi | BLOCKED | BLOCKED | BLOCKED | BLOCKED | Tidak ada persistence CRUD yang diverifikasi khusus dengan role Kaprodi. |
| Pengumuman | Admin | BLOCKED | BLOCKED | BLOCKED | BLOCKED | CRUD API/readback Admin tercatat di §9. |
| Pengumuman | Kaprodi | BLOCKED | BLOCKED | BLOCKED | BLOCKED | Tidak ada persistence CRUD yang diverifikasi khusus dengan role Kaprodi. |
| Kasus | Admin | BLOCKED | BLOCKED | BLOCKED | BLOCKED | CRUD API/readback Admin tercatat di §9. |
| Kasus | Kaprodi | BLOCKED | BLOCKED | BLOCKED | BLOCKED | Tidak ada persistence CRUD yang diverifikasi khusus dengan role Kaprodi. |
| Dokumen | Admin | BLOCKED | BLOCKED | BLOCKED | BLOCKED | CRUD API/readback Admin tercatat di §9. |
| Dokumen | Kaprodi | N/A | N/A | N/A | N/A | Tidak ada halaman CRUD dokumen langsung yang teridentifikasi di Prodi. |
| KHS | Admin | N/A | BLOCKED | BLOCKED | N/A | GET/PUT API dan readback tercatat di §9; endpoint delete tidak tersedia. |
| KHS | Kaprodi | N/A | BLOCKED | N/A | N/A | Tampilan Prodi bersifat baca saja; API/persistence KHS oleh Kaprodi belum diverifikasi. |
| KRS/nilai/kehadiran | Admin | N/A | BLOCKED | N/A | N/A | Web bersifat baca saja; hasil API historis tidak diulang. |
| KRS/nilai/kehadiran | Kaprodi | N/A | BLOCKED | N/A | N/A | Web bersifat baca saja; endpoint tulis ditujukan untuk role mobile. |
| Pengajuan koreksi/pengaturan Prodi | Kaprodi | N/A | N/A | N/A | N/A | Endpoint belum tersedia; browser juga tidak dijalankan. |

**Agar E2E dapat dimulai:** pemilik environment perlu menyediakan URL/stack staging atau disposable yang terisolasi dan terdokumentasi; memastikan database tersebut bukan production serta menentukan data uji/cleanup terbatas; menyediakan akun uji resmi Admin dan Kaprodi melalui mekanisme secret yang aman; dan menetapkan scope data Kaprodi. Jangan menjalankan seeder atau `docker compose up` pada service yang sedang aktif sebelum klasifikasi target dan dampaknya dipastikan.

Setelah gate terpenuhi, jalankan browser automation untuk login dan seluruh form sesuai matriks, simpan bukti non-rahasia (status, record uji, hasil baca ulang, dan screenshot yang disanitasi), lalu bersihkan hanya record yang dibuat test. Sampai itu dilakukan, seluruh operasi berstatus `BLOCKED`/`N/A`, bukan `PASS`.

## 13. Addendum audit integrasi Backend–Web–Flutter

Waktu pemeriksaan lokal: 2026-11-23 18:02 WIB. Branch `main`, `HEAD` `cb4e5a6`, ditambah perubahan lokal yang belum di-commit. Hasil pengujian di bawah berlaku untuk worktree tersebut; hash saja tidak merepresentasikan seluruh kode yang diuji.

### Cakupan dan batas bukti

Audit ini memeriksa kode backend, klien web-admin, dan Flutter serta menjalankan test/build lokal. Tidak ada URL staging/disposable yang dikonfirmasi, akun uji resmi Admin/Kaprodi/Mahasiswa/Dosen/Orang Tua tidak tersedia, dan scope program studi Kaprodi belum ditetapkan. Karena itu:

- Tidak ada login, browser automation, request jaringan ke server aplikasi, mutasi API, akses database, container, seeder, atau cleanup.
- Browser E2E Admin/Kaprodi dan runtime Flutter tetap **BLOCKED**. Tidak ada klaim sinkronisasi Admin → Kaprodi → Flutter, Kaprodi → Admin → Flutter, atau Flutter → Web yang lulus.
- Hasil API/persistence historis pada §9 tidak diulang dan bukan bukti runtime untuk revisi worktree ini. Source inspection dan build/test hanya membuktikan integrasi kode/kompilasi, bukan persistence atau tampilan setelah refresh.
- Status `CONNECTED` dalam tabel berarti kode client/endpoint terlihat cocok; status runtime tetap `UNVERIFIED` kecuali ada bukti E2E eksplisit.

### Matriks fitur × role × platform

| Fitur/data | Admin web | Kaprodi web | Flutter | Endpoint/kontrak utama | Status integrasi terkini |
|---|---|---|---|---|---|
| Login, profil, sesi | Login dan route role memakai API backend; CRUD akun tersedia di web. Browser login tidak dijalankan. | Login dan menu Prodi memakai API; belum ada pembuktian browser pada revisi ini. | Login, `/users/me`, refresh token, logout server-side dan retry 401 ada di service. | `/login`, `/users/me`, `/refresh-token`, `/logout` | `PARTIAL` — kode tersedia; login/session runtime `BLOCKED`. |
| Akun pengguna | CRUD Admin terhubung ke endpoint akun. | Operasi dibatasi backend untuk akun role istimewa; scope akun yang boleh dikelola selain itu belum diverifikasi melalui UI. | Tidak ada halaman CRUD akun; sesi/profil saja. | `/admin/users*`, `/users/me` | `PARTIAL` — API/web tersedia; browser dan persistensi revisi ini `UNVERIFIED`. |
| Mata kuliah, kelas, paket | Form CRUD terhubung ke backend. | Form CRUD tersedia; data list masih bersifat global dan scope prodi belum dikonfirmasi. | Tidak ada CRUD master. Dosen membaca kelas yang ditugaskan; mahasiswa membaca jadwal personal. | `/courses*`, `/classes*`, `/admin/packages*`, `/schedules/my` | `PARTIAL` — kontrak kode ada; runtime semua role `UNVERIFIED`; scope Kaprodi perlu keputusan. |
| Jadwal | CRUD Admin tersedia. | CRUD Prodi tersedia, dengan batas data yang belum dikonfirmasi. | Dashboard mahasiswa memakai `/schedules/my`, bukan daftar jadwal admin global. Jadwal Orang Tua dimuat dari endpoint anak tertaut. | `/admin/schedules*`, `/schedules/my`, `/parent/child/schedules` | `PARTIAL` — klien dan endpoint tersambung di kode; tidak ada bukti tampilan/persistence runtime. |
| KRS/enrollment | Daftar baca-saja; tidak ada mutasi KRS web. | Daftar baca-saja. | Daftar KRS tersedia, tetapi UI Flutter belum mengirim create/drop enrollment. | `/admin/krs/list`, `/enrollments/my`, `POST /enrollments`, `/enrollments/drop` | `PARTIAL` — baca tersedia; mutasi Flutter belum terhubung. |
| Nilai dan presensi | Daftar baca-saja. | Daftar baca-saja; data akademik global belum memiliki scope Prodi yang dikonfirmasi. | Mahasiswa membaca nilai/presensi; Dosen memiliki alur input nilai/presensi. Dashboard Orang Tua mengambil ringkasan/nilai dan presensi anak yang tertaut. | `/grades/my`, `/attendances/my`, `/grades`, `/attendances`, `/parent/child/summary`, `/parent/child/attendances` | `PARTIAL` — jalur kode tersedia; mutasi dan baca lintas aplikasi runtime `UNVERIFIED`. |
| IPK, semester, ringkasan akademik | Statistik web menggunakan API. | Statistik Prodi menggunakan API, tetapi cakupan data global belum diputuskan. | IPK berbobot SKS dan SKS terencana berasal dari ringkasan backend; nilai semester Orang Tua dipetakan dari ringkasan yang sama. | `/student/academic/summary`, `/parent/child/summary` | `PARTIAL` — perhitungan/kontrak di kode; belum divalidasi dengan data runtime pada revisi ini. |
| KHS | Admin dapat membaca/mengubah status publikasi; endpoint delete tidak tersedia. | Tampilan baca-saja. | Tidak ada halaman KHS khusus; ringkasan nilai tersedia, tetapi bukan pengganti seluruh alur KHS. | `/admin/khs/list`, `/admin/khs/update`, `/student/khs` | `PARTIAL` — kontrak baca/update tersedia; delete memang tidak didukung dan UI Flutter khusus belum ada. |
| UKT | CRUD Admin tersedia. | CRUD Prodi tersedia; scope belum dipastikan. | Orang Tua membaca data UKT anak untuk periode tahun akademik berjalan; tidak ada pembayaran atau mutasi UKT di Flutter. Status keringanan yang tidak diberikan API tidak direka. | `/admin/ukt*`, `/parent/child/ukt` | `PARTIAL` — kode tersambung; cakupan API terbatas pada data yang tersedia dan runtime `UNVERIFIED`. |
| Pengumuman | CRUD tersedia. | CRUD tersedia. | Mahasiswa/Orang Tua membaca pengumuman; backend membatasi role non-admin/kaprodi ke status `Aktif` yang berada dalam rentang tanggal. | `/admin/announcements*`, `/parent/announcements` | `CONNECTED` pada kode/kontrak; hasil browser/runtime `UNVERIFIED`. |
| Profil dan data anak | Admin dapat mengelola tautan orang tua–mahasiswa. | Tidak ada pengelolaan relasi anak yang teridentifikasi di UI Kaprodi. | Dashboard Orang Tua memakai profil akun, daftar anak tertaut, profil, ringkasan, presensi, jadwal, UKT, dan pengumuman; pilihan anak dibatasi ke daftar dari backend. Backend memvalidasi relasi anak pada endpoint tersebut. | `/admin/parents/link`, `/parent/children`, `/parent/child/*` | `PARTIAL` — permintaan/mapping sudah ada; akses dan tampilan nyata belum diuji. |
| Dokumen | CRUD tersedia di Admin. | Tidak ada CRUD dokumen langsung yang teridentifikasi di UI Prodi. | Endpoint baca dokumen anak ada di backend, tetapi belum dipakai layar Flutter Orang Tua. | `/admin/documents*`, `/parent/child/documents` | `PARTIAL` — Admin terhubung; pemakaian Flutter Orang Tua masih `MISSING`. |
| QR, kasus, pengajuan | Kasus memiliki CRUD web. | Kasus memiliki CRUD web. | Dosen memiliki alur QR/nilai/presensi; scanner mahasiswa belum tersambung pada navigasi. Tidak ada UI kasus atau pengajuan koreksi di Flutter. | `/admin/cases*`, `/qr/*`; endpoint pengajuan koreksi tidak ada | `PARTIAL` — QR perlu runtime; pengajuan koreksi/pengaturan Prodi `MISSING` tanpa endpoint. |

### Keputusan akses dan ketidaksesuaian kontrak

- **Kaprodi:** backend mengizinkan beberapa daftar/CRUD akademik global melalui `adminRoles`. Belum ada aturan bisnis eksplisit atau enforcement row-level per program studi. Status cakupan Kaprodi tetap **UNVERIFIED**; jangan mengasumsikan akses global memang diinginkan.
- **Dosen:** daftar `/classes/list` kini membatasi hasil ke `dosen_id` dari identitas token dan route daftar mengizinkan Admin/Kaprodi/Dosen sesuai konfigurasi. Unit handler baru ditambahkan, tetapi belum dieksekusi terhadap database pada pemeriksaan ini.
- **Mahasiswa:** ringkasan dan jadwal mengambil identitas dari token/endpoints personal. Dashboard tidak lagi mengambil IPK dari rata-rata skor sederhana atau jadwal global.
- **Orang Tua:** endpoint memeriksa tautan orang tua–anak di backend; klien hanya memilih ID yang dikembalikan `/parent/children`. UKT hanya sebesar data yang disediakan endpoint; layar tidak mengklaim riwayat/pengurangan yang tidak tersedia.
- **Pengumuman:** endpoint publik/role non-admin memakai status `Aktif` dan tanggal mulai/akhir; ini menyelaraskan filter dengan nilai status yang dipakai form CRUD.
- Fitur koreksi/pengaturan Prodi tidak memiliki endpoint. KRS create/drop ada di backend, tetapi belum tersedia dari UI Flutter. KHS tidak menyediakan delete. Dokumen anak tersedia di backend tetapi belum dipakai di Flutter.

### Perubahan kode pada integrasi ini

- Flutter API client dapat menerima `EDUTRACK_API_BASE_URL`, menyimpan/merotasi refresh token, menyatukan refresh bersamaan, mencoba ulang request sekali setelah 401, dan memanggil logout backend sebelum membersihkan sesi lokal.
- Dashboard Mahasiswa menggunakan `/student/academic/summary` dan `/schedules/my`; jadwal ringkas diurutkan menurut hari/jam. Dashboard Orang Tua mengambil endpoint backend, mendukung pemilihan anak tertaut, dan menampilkan loading/error/retry. Mapper menjaga field yang tidak disediakan API sebagai tidak diketahui/tidak tersedia, bukan nilai rekaan.
- Android manifest meminta akses Internet; cleartext hanya diizinkan pada manifest debug. Gunakan URL HTTPS untuk build rilis.
- Backend menambahkan ringkasan akademik berbobot SKS dan urutan semester deterministik, memperbaiki filter pengumuman berdasarkan status/tanggal, membatasi daftar kelas Dosen, serta mengembalikan error query kalender/notifikasi/pengumuman sebagai HTTP 500 alih-alih data kosong yang tampak sukses.
- Tes regresi mencakup refresh token Flutter, pemetaan data Orang Tua, helper periode akademik, filter pengumuman, dan scope kelas Dosen. Test handler memakai `TestMain` yang dapat mengosongkan database uji; test tersebut hanya dikompilasi dan **tidak dijalankan**.

### Validasi otomatis pada worktree

| Perintah/pemeriksaan | Hasil |
|---|---|
| `cd mobile && flutter test` | Lulus, 6 test. |
| `cd mobile && flutter analyze` | Exit 1 karena 3 info lint lama `curly_braces_in_flow_control_structures` di `lib/screens/login_screen.dart:31-33`; tidak ada diagnostic lain yang dilaporkan. |
| `cd mobile && flutter build apk --debug` | Lulus. Gradle memberi peringatan SDK XML versi 4 tidak didukung oleh parser versi lokal, tetapi APK debug berhasil dibuat. APK tidak dijalankan pada emulator/perangkat. |
| `cd backend && go test ./config` | Lulus. |
| `cd backend && go build ./...` | Lulus. |
| `cd backend && go test -c -o /tmp/edutrack-handlers.test ./handlers` | Lulus sebagai compile-only; tidak menjalankan `TestMain` atau mengakses DB. File hasil kompilasi dihapus setelahnya. |
| `cd web-admin && npm test` | Lulus, 3 test. |
| `cd web-admin && npm run lint` | Lulus. |
| `cd web-admin && npm run build` | Lulus. |
| Browser E2E, API runtime, database persistence, dan runtime Flutter | **BLOCKED/NOT RUN** — tidak ada environment/akun uji resmi yang dikonfirmasi untuk pemeriksaan ini. |

### Pemeriksaan lanjutan pada worktree

Inspeksi read-only menemukan query hitung pada statistik Admin, pagination user/mata kuliah, daftar mahasiswa per kelas, validasi kuota KRS, status KHS, dan rekonsiliasi periode yang dapat gagal tanpa menghentikan respons sukses. Pencarian kelas untuk KRS juga sebelumnya menyamakan error database dengan kelas yang tidak ditemukan. Perbaikan menggunakan envelope API HTTP 500 generik untuk error query dan tetap mempertahankan sukses dengan data kosong saat query sukses. Tidak ada response parsial pada statistik atau rekonsiliasi; kontrak response sukses tidak berubah.

Helper `RespondQueryError` mempunyai test tanpa database untuk memastikan error internal tidak dikirim pada response, sementara `nil` error tidak ditampilkan sebagai kegagalan. Logger GORM backend dikonfigurasi agar query error tetap terlihat dengan SQL berparameter, tetapi nilai parameter tidak dimasukkan ke log; test memeriksa pemfilteran parameter. Tidak ada detail database yang dikembalikan ke client. Handler tests yang menyentuh database tetap tidak dijalankan.

Validasi setelah perubahan:

| Pemeriksaan | Hasil |
|---|---|
| `cd backend && go test . ./config ./utils` | `PASS`, exit code 0; termasuk test logger dan envelope error generik. |
| `cd backend && go build ./...` | `PASS`, exit code 0. |
| `cd backend && go test -c -o /tmp/edutrack-handlers-followup.test ./handlers` | `PASS`, exit code 0 untuk kompilasi saja. Tidak menjalankan `TestMain`, migrasi, atau `TRUNCATE`; file sementara dihapus. |
| `cd web-admin && npm test && npm run lint && npm run build` | `PASS`, exit code 0; 3 test helper lulus, lint bersih, build berhasil. |
| `cd mobile && flutter test` | `PASS`, exit code 0; 6 test lulus. |
| `cd mobile && flutter analyze` | `FAIL` pada command, exit code 1. Hanya ada 3 diagnostic `INFO` `curly_braces_in_flow_control_structures` di `lib/screens/login_screen.dart:31-33` (aturan berasal dari `flutter_lints` yang di-include); tidak ada diagnostic lain. File tersebut tidak diubah. |
| `git diff --check` | `PASS`, exit code 0. |
| Browser E2E, API runtime, persistence database, dan runtime Flutter | `BLOCKED/NOT RUN` — target disposable/staging dan akun resmi belum dikonfirmasi. Tidak ada login/request aplikasi atau mutasi data. |

### Keputusan produk dan rencana E2E

Temuan dan opsi scope Kaprodi, persetujuan yang diperlukan untuk mutasi KRS Flutter dan dokumen anak, gerbang keamanan, serta skenario E2E dicatat pada [INTEGRATION_DECISIONS_AND_E2E_PLAN.md](./INTEGRATION_DECISIONS_AND_E2E_PLAN.md). Pada waktu addendum §13 ditulis, runner berstatus `NOT IMPLEMENTED`; status itu kemudian diperbarui pada §14. Tidak ada perubahan scope akses atau penambahan fitur KRS/dokumen Flutter. Runtime E2E tetap `BLOCKED`, dan tidak ada klaim bahwa daftar skenario runtime sudah dijalankan.

### Risiko dan prasyarat lanjutan

1. Pemilik sistem perlu menyediakan URL/identitas staging atau disposable yang dapat diverifikasi aman, akun uji resmi tiap role yang diperlukan melalui secret manager, relasi data uji, serta prosedur cleanup terbatas.
2. Pemilik produk perlu menetapkan scope data Kaprodi secara eksplisit sebelum pengujian atau perubahan otorisasi lintas program studi.
3. Setelah prasyarat terpenuhi, jalankan browser E2E Admin dan Kaprodi, smoke test Flutter Mahasiswa/Dosen/Orang Tua, uji readback/persistence sesudah refresh/login ulang, dan uji batas akses lintas Prodi pada environment tersebut. Simpan bukti tanpa credential/PII.
4. Jalankan `go test ./handlers` hanya dengan `EDUTRACK_TEST_DATABASE_DSN` yang secara eksplisit menunjuk database disposable bernama `edutrack_test`; jangan memakai environment production atau environment yang belum diverifikasi.
5. Tidak ada test runtime lintas aplikasi yang dapat diberi status `PASS` pada addendum ini.

Tidak ada commit, push, deployment, perubahan konfigurasi production, akses database production, atau cleanup terhadap container/data pada pemeriksaan ini.

## 14. Addendum — Runner E2E mock dan pemeriksaan analyzer

Pemeriksaan lanjutan pada worktree yang sama (`main`, `cb4e5a6`; perubahan lokal tetap dipertahankan). Implementasi runner bersifat **PARTIAL/API-only**; tidak mengubah otorisasi, kontrak bisnis, atau konfigurasi production.

### Implementasi

- `web-admin/e2e/runner.mjs`: CLI dengan mode mock/runtime, validasi approval manifest, allow-list dua skenario pengumuman, timeout, assertion status/envelope/readback, sanitasi laporan, error jaringan teredaksi, dan cleanup terbatas ke ID hasil create. Ambiguitas create/cleanup ditandai `MANUAL_REVIEW_REQUIRED`.
- `web-admin/e2e/mockTransport.mjs`: route mock melalui protokol `mock://` dan penyimpanan in-memory, termasuk fixture record lama untuk membuktikan cleanup tidak menghapus data lain.
- `web-admin/e2e/runner.test.mjs`: assertion sukses, readback gagal, cleanup, runtime preflight, penolakan target/database/scope/secret-source, redaksi error, adapter browser diagnostics dan larangan manifest di dalam repository.
- `web-admin/package.json`: menambah `npm test` untuk test mutasi + runner dan `npm run e2e:mock`; tidak menambah dependency.
- `mobile/lib/screens/login_screen.dart`: menambahkan braces pada tiga cabang navigasi role; tidak mengubah kondisi maupun perilaku login. Perubahan minimal ini mengatasi tiga diagnostic INFO `curly_braces_in_flow_control_structures`.
- Dokumen keputusan/rencana E2E diperbarui dengan prasyarat runner dan perbedaan bukti mock/runtime.

Mode runtime hanya dapat dipilih eksplisit. Sebelum login/mutasi, preflight menuntut URL yang cocok persis dengan approval eksternal repository, target staging/disposable dengan database disposable, masa approval aktif, scenario/role approval, persetujuan scope baca Kaprodi (dan tulis untuk skenario Kaprodi), referensi akun dari secret manager, dan cleanup `runner-created-records-only`. Credential dibaca dari environment, tidak masuk report. Ketika hasil create atau cleanup tidak pasti, runner tidak melakukan cleanup luas dan memberi status manual review.

### Skenario dan batas bukti

| Skenario | Kode runner | Bukti yang tersedia |
|---|---|---|
| Admin → Kaprodi → Flutter/Mahasiswa untuk pengumuman | Tersedia sebagai API flow: create Admin, readback API Admin/Kaprodi/mahasiswa, cleanup record runner. | Mock `PASS`. Tidak membuktikan akses ke UI Kaprodi atau Flutter; tidak membuktikan DB persistence runtime. |
| Kaprodi → Admin → Flutter/Mahasiswa | Tersedia sebagai API flow, tetapi runtime guard memblokir sampai scope baca/tulis global disetujui. | Mock hanya menguji jalur kode dan tidak membuktikan otorisasi. Runtime `BLOCKED`. |
| Flutter → Web, update record, akses di luar scope | Belum ada skenario runner. | `NOT IMPLEMENTED/BLOCKED`; perlu alur Flutter yang disetujui, scope produk, dan strategi cleanup yang aman. |
| Mutasi KRS dan dokumen anak Flutter | Tidak ditambahkan. | Menunggu keputusan produk pada dokumen keputusan. |
| Browser console/UI serta Flutter runtime | Tidak dijalankan; adapter diagnostics generik diuji dengan event fixture saja. | `NOT RUN`; report API menandai console `NOT_COLLECTED_API_ONLY`. |

Pembacaan ulang endpoint setelah create pada mode runtime kelak merupakan bukti API readback saja; runner saat ini tidak memverifikasi database secara langsung dan tidak mengotomasi browser/Flutter. Persyaratan persistence readback, refresh, navigasi ulang, login ulang, serta validasi UI masih perlu dijalankan terpisah pada environment aman.

### Validasi terbaru

| Command | Hasil |
|---|---|
| `cd web-admin && npm test` | `PASS`, exit 0; 18 assertions/test cases (15 runner, 3 mutasi web). |
| `cd web-admin && npm run e2e:mock` | `PASS`, exit 0; create/readback role Admin/Kaprodi/mahasiswa dan cleanup mock lulus. Console/browser dan Flutter tidak diuji. |
| `cd web-admin && npm run lint` | `PASS`, exit 0. |
| `cd web-admin && npm run build` | `PASS`, exit 0. |
| `cd mobile && flutter test` | `PASS`, exit 0; 6 tests. |
| `cd mobile && flutter analyze` | Sebelum perubahan hanya tiga INFO style di `login_screen.dart:31–33` yang dilaporkan, dengan exit 1 dan tanpa diagnostic lain. Setelah braces ditambahkan: `PASS`, exit 0, `No issues found`. |
| `cd backend && go test . ./config ./utils` | `PASS`, exit 0. Aman dari handler `TestMain`. |
| `cd backend && go build ./...` | `PASS`, exit 0. |
| Runtime CLI dengan seluruh konfigurasi/approval/account env dihilangkan | CLI mengembalikan `BLOCKED`, exit 2 karena manifest approval tidak tersedia; tidak melakukan login, request, atau mutasi. |
| `git diff --check` | `PASS`, exit 0. |
| Handler tests / API runtime / database readback / browser / Flutter runtime | `NOT RUN` atau `BLOCKED`; handler `TestMain` dapat menjalankan `TRUNCATE`, dan tidak ada target/akun resmi terkonfirmasi. |

Kesimpulan: automation harness mock **PASS**, status runner **PARTIAL**. Tidak ada bukti runtime sinkronisasi Admin–Kaprodi–Flutter. Scope Kaprodi, fitur KRS Flutter, dan kebutuhan dokumen anak tetap menunggu keputusan pemilik produk; runtime E2E tetap `BLOCKED`.

Tidak ada akses ke server aplikasi atau database, login, mutasi runtime, container/seeder, deployment, commit, atau push pada pemeriksaan runner ini.

## 15. Addendum — Product approvals dan runtime readiness

Pemeriksaan lanjutan: 2026-11-23. Branch `main`, `HEAD` `cb4e5a6`; worktree masih memiliki banyak perubahan lokal terdahulu. Perubahan tahap ini hanya memperbarui dokumen, mempertahankan worktree tersebut; tidak ada perubahan kode aplikasi atau akses runtime.

### Keputusan produk: PENDING APPROVAL

Dokumen [INTEGRATION_DECISIONS_AND_E2E_PLAN.md](./INTEGRATION_DECISIONS_AND_E2E_PLAN.md) kini mencantumkan opsi, konsekuensi/risiko, rekomendasi teknis yang bukan persetujuan, serta permintaan konfirmasi konkret:

1. **Scope Kaprodi — `PENDING APPROVAL`:** opsi least-privilege per prodi, baca global/tulis per prodi, atau scope khusus. Rekomendasi teknis adalah least-privilege per prodi setelah relasi prodi terstruktur dan enforcement server-side tersedia; tidak ada akses yang diubah. Akses global bukan default.
2. **Mutasi KRS Flutter — `PENDING APPROVAL`:** pertahankan read-only atau setujui create/drop oleh mahasiswa. Endpoint backend ada dan memvalidasi periode/kuota/benturan, tetapi Flutter belum memakai mutasi. Tidak ada mutasi yang ditambahkan.
3. **Dokumen Flutter — `PENDING APPROVAL`:** pilih role target (mahasiswa/orang tua/keduanya), metadata/file, dan operasi. Backend hanya menyediakan metadata anak untuk orang tua tertaut; tidak ada endpoint dokumen milik mahasiswa atau upload/download file yang ditemukan. Tidak ada UI/API baru.

Tidak ada nama pemilik/pemberi persetujuan atau referensi approval yang dicatat; rekomendasi tetap bukan keputusan.

### Checklist dan skenario runtime

[RUNTIME_E2E_READINESS_CHECKLIST.md](./RUNTIME_E2E_READINESS_CHECKLIST.md) memisahkan status gate, evidence yang dibutuhkan, strategi cleanup, dan matriks skenario. Saat pemeriksaan ini environment, database disposable, akun resmi secret-manager, fixture/scope, prosedur reset/cleanup, serta DB read-only verification semuanya **BLOCKED**. Browser/Flutter runtime automation **NOT RUN**; runner tersedia tetapi hanya API/mock.

Inspeksi read-only atas [qr_generator_screen.dart](../../mobile/lib/screens/dosen/qr_generator_screen.dart) menunjukkan Flutter Dosen membuat sesi `/qr/generate`, menyimpan sesi lokal untuk pemulihan, dan menutup lewat `/qr/close`; backend membatasi generate ke kelas dosen dan periode aktif. Mahasiswa memakai `/qr/scan` yang membuat data kehadiran. Tidak ditemukan cleanup API attendance. Karena itu QR→attendance→web adalah kandidat skenario lintas role, tetapi **BLOCKED** sampai ada target disposable sekali-pakai dan prosedur teardown yang disetujui; token QR tidak boleh masuk bukti/log.

| Skenario | Status terkini |
|---|---|
| Admin → backend → Kaprodi/mahasiswa | Mock pengumuman `PASS`; runtime/API persistence/browser/Flutter `BLOCKED/NOT RUN`. |
| Kaprodi → backend → Admin/Flutter | `BLOCKED` sampai scope disetujui dan enforcement diuji. |
| KRS Flutter | Baca runtime `BLOCKED`; mutasi `PENDING APPROVAL` dan belum diimplementasikan. |
| Dokumen | `PENDING APPROVAL`; Flutter tidak memakai endpoint yang ada. |
| Dosen QR → mahasiswa scan → web attendance | Kandidat dari kode; `BLOCKED`, cleanup data attendance belum tersedia. |
| Akses di luar scope, refresh/login ulang, UI loading/error/empty | `NOT RUN`; tidak ada browser/Flutter runtime. |

### Validasi aman sesi ini

| Command | Hasil |
|---|---|
| `cd web-admin && npm test` | `PASS`, exit 0; 18 test (15 runner, 3 mutasi web). |
| `cd web-admin && npm run e2e:mock` | `PASS`, exit 0; in-memory only, API assertion simulation. |
| `cd web-admin && npm run lint` | `PASS`, exit 0. |
| `cd web-admin && npm run build` | `PASS`, exit 0. |
| `cd mobile && flutter test` | `PASS`, exit 0; 6 tests. |
| `cd mobile && flutter analyze` | `PASS`, exit 0; `No issues found`. |
| `cd backend && go test . ./config ./utils` | `PASS`, exit 0; safe packages only. |
| `cd backend && go build ./...` | `PASS`, exit 0. |
| Runtime CLI tanpa approval/account/URL environment | `BLOCKED`, CLI exit 2 sebelum login/request karena approval manifest tidak ada. |
| `git diff --check` | `PASS`, exit 0. |
| Handler/integration tests, API/database/browser/Flutter runtime | `NOT RUN/BLOCKED`; handler test setup dapat menjalankan `TRUNCATE`, dan tidak ada target aman/akun/approval. |

Tidak ada klaim integrasi lintas aplikasi selesai atau runtime persistence terbukti. Tidak ada reset/cleanup, login, request, perubahan production, commit, push, atau deployment.

## 16. Addendum — Paket persetujuan pemilik proyek

Pemeriksaan: 2026-11-23 22:02 WIB. Branch `main`, `HEAD` `cb4e5a6`; worktree masih memiliki perubahan lokal terdahulu dan dipertahankan. Tahap ini hanya memperbarui dokumentasi.

Paket siap dibalas ditempatkan di [INTEGRATION_DECISIONS_AND_E2E_PLAN.md](./INTEGRATION_DECISIONS_AND_E2E_PLAN.md), bukan membuat dokumen keputusan duplikat. Form menyediakan kode `A1–A4` untuk scope Kaprodi, `B1–B4` untuk KRS, dan `C1–C4` untuk dokumen; opsi lain dan `PENDING` dapat dipilih. Rekomendasi dipisahkan dari approval, dan nama/tanggal pemberi persetujuan tetap kosong.

[RUNTIME_E2E_READINESS_CHECKLIST.md](./RUNTIME_E2E_READINESS_CHECKLIST.md) kini menandai prasyarat yang belum diberikan sebagai `PENDING`, memisahkan izin runtime dari persetujuan produk, dan mempertahankan status keseluruhan **BLOCKED / NOT RUN**. Referensi secret manager diminta tanpa nilai rahasia. Skenario, bukti persistensi read-only, scope role, cleanup/teardown, serta izin API/browser/Flutter dicantumkan sebagai gate.

Validasi dokumentasi: `git diff --check` dan pemeriksaan whitespace file dokumentasi baru/terkait **PASS**. Tidak ada test aplikasi yang dijalankan pada tahap dokumentasi ini; validasi lokal terakhir tercatat pada §15. Tidak ada login, request aplikasi, mutasi database, runtime E2E, commit, push, atau deploy.

## 17. Addendum — Pemrosesan approval dan gerbang eksekusi

Pemeriksaan: 2026-11-23 22:09 WIB. Branch `main`, `HEAD` `cb4e5a6`; perubahan lokal terdahulu dipertahankan. Perubahan tahap ini hanya dokumentasi.

[INTEGRATION_DECISIONS_AND_E2E_PLAN.md](./INTEGRATION_DECISIONS_AND_E2E_PLAN.md) kini berisi tata cara mencatat jawaban persis, status per butir (`APPROVED`, `PENDING APPROVAL`, `NEEDS CLARIFICATION`, `NOT APPROVED`), penanganan jawaban parsial/konflik, pencatatan identitas hanya jika diberikan, serta gerbang sebelum implementasi kode. Rekomendasi tidak mengubah status approval.

[RUNTIME_E2E_READINESS_CHECKLIST.md](./RUNTIME_E2E_READINESS_CHECKLIST.md) kini memiliki final admission checklist yang mensyaratkan verifikasi target bukan production, DB disposable terisolasi, akun resmi melalui secret manager, scope dan fixture yang disetujui, readback database read-only, cleanup terbatas, izin per jenis runtime, serta penanganan bukti yang aman. Satu gate yang hilang, ambigu, konflik, kedaluwarsa, atau tidak dapat diverifikasi menghentikan runtime sebelum login/request.

### Status dan validasi

- Keputusan produk A/B/C dan seluruh bukti environment masih `PENDING`; tidak ada form yang diisi atau status approval yang dinaikkan.
- Implementasi perilaku aplikasi belum dilakukan; butir keputusan yang belum `APPROVED` tetap menjadi penghalang.
- API runtime, DB readback, browser E2E, dan Flutter runtime tetap **`BLOCKED/NOT RUN`**. Tidak ada klaim integrasi runtime terbukti.
- Dilakukan inspeksi status/diff dan pembacaan dokumen; pemeriksaan whitespace `git diff --check` serta cek dokumen terkait PASS. Tidak ada aplikasi/server/DB yang diakses dan tidak ada test yang dapat menyentuh DB dijalankan.
- Tidak ada login, request runtime, CRUD, seed, reset, cleanup, browser/Flutter E2E, commit, push, atau deploy.

## 18. Addendum — Implementasi keputusan produk A1/B2/C2

Addendum ini mencatat kondisi implementasi terbaru setelah keputusan produk A1, B2, dan C2 disetujui. Bagian §13–§17 tetap dipertahankan sebagai catatan historis; untuk status implementasi terkini gunakan [APPROVED_PRODUCT_DECISIONS_IMPLEMENTATION_REPORT.md](./APPROVED_PRODUCT_DECISIONS_IMPLEMENTATION_REPORT.md).

- **A1 Kaprodi:** scope server-side ditambahkan pada endpoint yang terhubung ke mahasiswa; operasi berbasis ID juga dibatasi. Endpoint global yang tidak mempunyai relasi prodi ditolak untuk Kaprodi, dan dashboard Prodi tidak lagi memanggil endpoint global yang diblokir. Implementasi tetap **PARTIAL** karena `User.ProgramStudi` hanya string, tidak ada katalog assignment terverifikasi, dan Course/Class/Package/Schedule/Announcement belum memiliki relasi prodi. Handler authorization tests ditambahkan tetapi hanya dikompilasi, tidak dijalankan karena `TestMain` dapat menjalankan migration dan `TRUNCATE`.
- **B2 KRS Flutter:** UI memakai endpoint kelas dan enrollment yang tersedia, melakukan create/drop, menampilkan error validasi backend, dan memuat ulang data setelah sukses. Mock widget tests lulus. Endpoint drop belum menegakkan periode registrasi/kelayakan mahasiswa yang terpisah dari periode akademik; kebijakan backend itu perlu diselesaikan.
- **C2 Dokumen orang tua:** Flutter meminta metadata melalui endpoint anak tertaut yang memvalidasi relasi server-side; UI hanya menampilkan metadata. Mock tests untuk linked/unlinked, empty, dan error lulus. Tidak ada operasi file atau self-service.
- Test lokal yang aman: Flutter tests/analyzer, web-admin tests/lint/build, utility tests, compile-only handler package, dan pemeriksaan whitespace lulus. Handler DB tests serta API/database/browser/Flutter runtime **NOT RUN**.
- Status runtime API, database persistence, browser, dan Flutter E2E tetap **`BLOCKED / NOT RUN`**. Tidak ada klaim sinkronisasi runtime lintas aplikasi.
