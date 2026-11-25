# EduTrack — Keputusan Produk dan Persetujuan Runtime

## 1. Ringkasan status dan batas persetujuan

| Lapisan keputusan | Status | Arti |
|---|---|---|
| Keputusan produk A1/B2/C2 | `APPROVED` | Kebijakan produk di bawah telah disetujui berdasarkan naskah pemilik proyek yang diberikan. Ini bukan bukti implementasi atau pengujian. |
| Implementasi kebijakan | `PARTIAL / NEEDS VERIFICATION` | Kode, scope, validasi, serta akses negatif masih harus diverifikasi. |
| Persetujuan perilaku produk untuk E2E | `APPROVED WITH CONDITIONS` | Skenario boleh dipertimbangkan pada target aman setelah seluruh prasyarat terpenuhi. |
| Izin eksekusi runtime pada target tertentu | `NOT GRANTED` | Belum ada target, scope skenario, dan otorisasi eksekusi spesifik yang terverifikasi. |
| Eksekusi saat ini | `BLOCKED / NOT RUN` | Tidak ada login, request runtime, mutasi, browser E2E, atau Flutter runtime yang dijalankan. |

Keputusan produk dicatat dari naskah yang diberikan pemilik proyek dalam percakapan. Identitas, tanda tangan, dan tanggal formal pemilik belum dapat diverifikasi; kolom otorisasi tetap kosong. Persetujuan produk sebelumnya bukan izin runtime atau bukti keamanan.

## 2. Keputusan produk A1/B2/C2

### A1 — Scope Kaprodi

**Disetujui:** Kaprodi hanya boleh mengakses data program studi yang secara sah ditugaskan kepadanya. Backend harus menegakkan scope pada operasi yang tersedia, termasuk list dan akses berbasis ID. Data lintas program tidak diizinkan. Persetujuan ini tidak membuktikan scope saat ini lengkap atau tervalidasi.

### B2 — KRS Mahasiswa di Flutter

**Disetujui:** Mahasiswa boleh membuat dan membatalkan KRS miliknya melalui Flutter dengan backend sebagai sumber kebenaran. Backend harus memvalidasi periode registrasi, kelayakan, kepemilikan, benturan jadwal, kapasitas, SKS, dan aturan enrollment. Pembatalan mempertahankan histori; reaktivasi hanya boleh jika aturan backend mengizinkan. Flutter hanya menyatakan sukses setelah respons backend sukses dan membaca ulang data.

**Batas verifikasi:** Route create/drop tersedia di kode. Create memeriksa periode akademik kelas, status kelas, enrollment duplikat, benturan jadwal, kapasitas, dan batas SKS. Namun pemeriksaan jendela registrasi terpisah, kelayakan mahasiswa, dan prasyarat mata kuliah tidak ditunjukkan handler yang diperiksa. Handler drop memeriksa kepemilikan enrollment tetapi tidak menunjukkan validasi periode registrasi. Hal-hal ini tetap `NEEDS VERIFICATION` sebelum perilaku B2 dinyatakan lengkap.

### C2 — Metadata dokumen anak

**Disetujui:** Orang Tua/Wali boleh membaca metadata dokumen untuk anak yang tertaut. Backend wajib memvalidasi relasi pada setiap request. Persetujuan tidak mencakup akses file, URL berkas, upload, download, delete file, atau self-service dokumen Mahasiswa.

## 3. Persetujuan implementasi

**Status:** `APPROVED` untuk implementasi yang diperlukan agar A1/B2/C2 terpenuhi, sesuai batas keputusan produk.

Persetujuan ini bukan bukti bahwa kode, model, authorization, validasi, UI, atau test telah memenuhi kebijakan. Gap yang belum selesai harus tetap ditandai `NEEDS VERIFICATION`; perubahan di luar keputusan ini perlu klarifikasi tersendiri.

## 4. Persetujuan runtime E2E dan batasnya

- **Perilaku produk:** `APPROVED WITH CONDITIONS`.
- **Izin eksekusi pada target tertentu:** `NOT GRANTED`.
- **Status eksekusi:** `BLOCKED / NOT RUN`.

`APPROVED WITH CONDITIONS` bukan izin untuk login, mengirim request API, mengubah database, menjalankan browser E2E, atau menjalankan Flutter runtime. Izin eksekusi baru dapat dipertimbangkan setelah target, isolasi, scope, akun, fixture, readback, cleanup, dan izin spesifik diverifikasi. Persetujuan ini tidak mengizinkan pengujian production, deployment, commit, atau push.

## 5. Temuan environment yang menghalangi pengujian

Bukti repository yang telah diperiksa belum membuktikan adanya target staging/disposable yang aman:

- Docker Compose adalah konfigurasi development dengan PostgreSQL dan volume persisten; jangan gunakan sebagai disposable tanpa bukti isolasi terpisah.
- Identitas runtime database dan hubungan target aktual Web/Mobile ke backend/database yang sama belum diverifikasi.
- Belum ada bukti akun uji resmi dan secret-manager reference.
- Belum ada fixture unik dan relasi antar-role yang disetujui.
- Belum ada metode readback database read-only yang disetujui beserta operatornya.
- Belum ada cleanup exact-ID atau prosedur teardown disposable dan owner yang disetujui.
- Izin API, Web browser, dan Flutter runtime belum diberikan secara terpisah untuk target tertentu.
- Handler test database dapat menjalankan migration dan `TRUNCATE`; test tersebut tidak boleh dijalankan tanpa target disposable yang dibuktikan terisolasi.
- Grade dan attendance tidak memiliki delete yang terdaftar; enrollment drop dan relasi wali-anak juga tidak menghapus histori/relasi melalui endpoint terverifikasi. Fixture ini membutuhkan teardown disposable yang disetujui.

## 6. Identitas target

Isi hanya identitas non-secret dan referensi bukti. Jangan mencatat password, token, cookie, secret, atau credential.

| Konfirmasi pemilik | Isi | Status |
|---|---|---|
| Identitas target/stack staging atau disposable | [isi identitas persis] | `PENDING` |
| Owner environment dan referensi persetujuan | [isi nama/jabatan dan referensi] | `PENDING` |
| Bukti independen bahwa target bukan production/shared | [isi referensi bukti] | `PENDING` |
| Masa berlaku/expiry persetujuan | [isi rentang waktu/tanggal] | `PENDING` |
| Base URL API Web | [isi URL persis] | `PENDING` |
| Base URL API Mobile/Flutter | [isi URL persis] | `PENDING` |
| Identitas/service backend yang melayani kedua klien | [isi identitas non-secret] | `PENDING` |
| Identitas database dan bukti bukan database bersama | [isi identitas/referensi bukti] | `PENDING` |
| Volume database yang terpisah | [isi identitas dan referensi bukti] | `PENDING` |
| Jaringan backend/database yang terpisah | [isi identitas dan referensi bukti] | `PENDING` |
| Session store terisolasi bila dibutuhkan skenario | [isi identitas/referensi bukti] | `PENDING` |

Nama environment atau service saja tidak membuktikan isolation. Bukti harus dapat ditinjau tanpa menyambungkan audit ini ke target.

## 7. Akun uji dan fixture

Credential harus disimpan di secret manager yang disetujui. Di dokumen ini hanya cantumkan reference, bukan nilainya.

| Role | Referensi akun uji resmi | Scope/fixture | Status |
|---|---|---|---|
| Admin Web | [isi secret-manager reference] | Pengelolaan record uji yang disetujui | `PENDING` |
| Kaprodi Web | [isi secret-manager reference] | Penugasan prodi terverifikasi dan kasus akses negatif | `PENDING` |
| Mahasiswa | [isi secret-manager reference] | KRS, nilai, absensi, dan profil uji | `PENDING` |
| Dosen | [isi secret-manager reference] | Kelas yang benar-benar diampu serta Mahasiswa enrolled | `PENDING` |
| Orang Tua/Wali | [isi secret-manager reference] | Anak uji yang tertaut; negative case anak yang tidak tertaut | `PENDING` |

Fixture harus dummy, unik per run, dapat dikenali tanpa PII, dan tidak bercampur dengan data nyata.

| Fixture/relasi | Konfirmasi yang diperlukan | Status |
|---|---|---|
| Mahasiswa uji dan Mahasiswa pembanding | Identitas fixture non-PII serta pemakaian untuk uji isolasi | `PENDING` |
| Dosen dan kelas uji | Relasi dosen-kelas yang benar, periode, kapasitas, dan jadwal | `PENDING` |
| Enrollment/KRS uji | Kelas yang memenuhi kebijakan periode dan eligibility | `PENDING` |
| Program Kaprodi | Penugasan yang tervalidasi serta record in-scope/out-of-scope | `PENDING` |
| Orang Tua/Wali dan anak tertaut | Relasi fixture eksplisit | `PENDING` |
| Orang Tua/Wali dan anak tidak tertaut | Negative fixture untuk memastikan penolakan akses | `PENDING` |
| Nilai/absensi, pengumuman, UKT, metadata dokumen | Record dummy dan hubungan ke fixture yang relevan | `PENDING` |

## 8. Readback database dan cleanup

| Gate | Isi pemilik | Status |
|---|---|---|
| Metode/query readback database read-only | [isi metode, batas record, dan operator] | `PENDING` |
| Izin readback dan pihak yang memberi izin | [isi nama/jabatan dan referensi] | `PENDING` |
| Bukti pembatasan readback hanya ke fixture | [isi metode/bukti] | `PENDING` |
| Cleanup exact-ID untuk tiap jenis record | [isi prosedur yang aman dan scope ID] | `PENDING` |
| Teardown disposable untuk record tanpa delete aman | [isi prosedur owner-controlled] | `PENDING` |
| Owner yang bertanggung jawab atas cleanup/teardown | [isi nama/jabatan] | `PENDING` |
| Bukti verifikasi setelah cleanup | [isi readback/bukti yang akan disimpan] | `PENDING` |

Jangan gunakan broad delete, `TRUNCATE`, reset database, seeding, atau pencarian berdasarkan nama/PII untuk cleanup. Sebelum skenario tanpa delete exact-ID dijalankan, harus ada disposable one-use dan teardown yang dilakukan/diotorisasi owner.

## 9. Izin runtime terpisah

Setiap izin harus menyebut target persis, role, skenario, alat/build, masa berlaku, serta referensi pemberi izin.

| Jenis izin | Referensi persetujuan | Target/build/device | Role dan skenario | Berlaku sampai | Status |
|---|---|---|---|---|---|
| API runtime | [isi referensi] | [isi target API] | [isi scope] | [isi expiry] | `PENDING` |
| Web browser runtime | [isi referensi] | [isi URL/build browser] | [isi role/scope] | [isi expiry] | `PENDING` |
| Flutter runtime | [isi referensi] | [isi build/device/emulator] | [isi role/scope] | [isi expiry] | `PENDING` |

Satu izin tidak mencakup jenis runtime lainnya.

## 10. Checklist gate sebelum runtime

Semua gate berikut berstatus `PENDING` sampai ada bukti yang dapat ditinjau. Keputusan produk atau pengisian template saja tidak memenuhi gate.

- [ ] `PENDING` — Target dan owner teridentifikasi; bukti independen menunjukkan bukan production/shared.
- [ ] `PENDING` — Backend, database, volume, dan jaringan uji terpisah; jalur Web/Mobile ke target yang dimaksud dibuktikan dari konfigurasi yang disetujui.
- [ ] `PENDING` — Akun uji resmi untuk setiap role tersedia lewat secret manager yang disetujui.
- [ ] `PENDING` — Fixture unik, role, relasi, operasi yang diizinkan, dan expected allow/deny ditetapkan.
- [ ] `PENDING` — Metode readback database read-only dan operator disetujui.
- [ ] `PENDING` — Cleanup exact-ID atau teardown disposable mencakup semua mutasi, termasuk attendance, grade, enrollment history, dan relasi wali-anak.
- [ ] `PENDING` — Izin API runtime spesifik telah diberikan.
- [ ] `PENDING` — Izin Web browser runtime spesifik telah diberikan.
- [ ] `PENDING` — Izin Flutter runtime spesifik telah diberikan.
- [ ] `PENDING` — Masa berlaku belum lewat dan bukti diperiksa ulang sebelum eksekusi.
- [ ] `PENDING` — Prosedur penghentian, eskalasi, dan penanggung jawab ditetapkan.
- [ ] `PENDING` — Penanganan bukti dibatasi ke status dan ID non-PII; tidak merekam credential, token, QR, payload mentah, atau screenshot tanpa redaksi.

Jika ada gate yang `PENDING`, `REJECTED`, kedaluwarsa, ambigu, atau tidak dapat diverifikasi, status keseluruhan tetap `BLOCKED / NOT RUN`. Target yang ternyata production/shared harus `REJECTED` untuk paket ini. Hentikan jika target berubah, autentikasi/role tidak sesuai, readback gagal, cleanup tidak pasti, atau terjadi perubahan di luar fixture.

## 11. Otorisasi pemilik

Tidak ada tanda tangan atau konfirmasi formal yang dapat diverifikasi dalam dokumen ini. Isi hanya setelah diberikan oleh pihak berwenang.

| Otorisasi | Isi pemilik | Status |
|---|---|---|
| Nama pemilik proyek dan jabatan | [isi] | `PENDING` |
| Kontak resmi/penanggung jawab eskalasi | [isi] | `PENDING` |
| Owner environment | [isi] | `PENDING` |
| Owner database/readback | [isi] | `PENDING` |
| Owner cleanup/teardown | [isi] | `PENDING` |
| Referensi persetujuan runtime spesifik | [isi] | `PENDING` |
| Tanggal dan masa berlaku | [isi] | `PENDING` |
| Tanda tangan atau bukti persetujuan yang dapat diverifikasi | [isi referensi; jangan menaruh secret] | `PENDING` |

Melengkapi bagian ini tidak otomatis membuat runtime `READY`; seluruh gate pada bagian 10 tetap harus diverifikasi.

## 12. Matriks skenario uji

Seluruh skenario berstatus **`NOT RUN`**. Path/method/permission/body berikut dicocokkan dengan registrasi di `backend/main.go` dan handler saat ini. Status ini membuktikan kontrak source yang ditemukan, bukan keberhasilan runtime. Sebelum eksekusi, verifikasi ulang source, izin, dan status keamanan target.

| Skenario | Kontrak route/handler yang ditemukan | Role dan fixture | Verifikasi UI/API/DB yang direncanakan | Risiko, cleanup, dan status |
|---|---|---|---|---|
| KRS create/drop | `POST /api/v1/enrollments` dan `POST /api/v1/enrollments/drop`, body `{ "class_id": uint }`, role `mahasiswa`; `GET /api/v1/enrollments/my`, role `mahasiswa`; Web `GET /api/v1/admin/krs/list`, role `admin, kaprodi`. Handler memakai ID mahasiswa dari sesi. Drop mengubah status ke `dropped`, bukan menghapus. | Akun Mahasiswa; kelas/periode uji; Admin/Kaprodi untuk Web readback sesuai izin. | Buat KRS di Flutter, baca ulang Mobile/Web, drop dan baca ulang status; DB read-only mencocokkan mahasiswa, kelas, status, dan histori. | Pemeriksaan eligibility, prasyarat, dan jendela registrasi belum terbukti; handler drop tidak menunjukkan pemeriksaan periode. Tidak ada delete enrollment; perlu teardown disposable. Negative case: role non-mahasiswa ditolak untuk mutasi; `/enrollments/my` hanya menampilkan data akun terautentikasi saat ada record milik Mahasiswa pembanding. `NOT RUN`; kebijakan `NEEDS VERIFICATION`. |
| Input dan baca nilai | `POST /api/v1/grades`, body `{ "mahasiswa_id": uint, "class_id": uint, "score": number, "letter": string }`, role `dosen`; `GET /api/v1/grades/my`, role `mahasiswa`; Web `GET /api/v1/admin/grades/list`, role `admin, kaprodi`. Handler hanya mengizinkan kelas milik Dosen dan enrollment mahasiswa aktif. | Dosen pemilik kelas; Mahasiswa enrolled; Admin/Kaprodi untuk Web readback sesuai scope. | Input/update nilai, refresh Mobile dan Web, DB read-only memeriksa nilai/kelas/mahasiswa. | Tidak ada route delete grade. Negative case: Dosen lain atau Mahasiswa tidak enrolled harus ditolak. Perlu disposable teardown. `NOT RUN`. |
| Absensi manual | `POST /api/v1/attendances`, body `{ "class_id": uint, "mahasiswa_id": uint, "date": "YYYY-MM-DD", "status": "hadir|izin|sakit|alpa" }`, role `dosen`; `GET /api/v1/attendances/my`, role `mahasiswa`; Web `GET /api/v1/admin/attendances/list`, role `admin, kaprodi`. Handler memeriksa kelas milik Dosen dan enrollment aktif. | Dosen pemilik kelas; Mahasiswa enrolled; Admin/Kaprodi untuk Web readback sesuai scope. | Input absensi, refresh Mobile/Web, DB read-only memeriksa tanggal, status, mahasiswa dan kelas. | Tidak ada route delete attendance; duplikasi per mahasiswa/kelas/tanggal ditolak. Negative case: Dosen lintas kelas dan mahasiswa tidak enrolled. Perlu disposable teardown. `NOT RUN`. |
| Absensi QR | Dosen `POST /api/v1/qr/generate`, body `{ "class_id": uint }`; Mahasiswa `POST /api/v1/qr/scan`, body `{ "token": string }`; Dosen `POST /api/v1/qr/close?id={session_id}`. Readback attendance memakai route `/attendances/my` dan `/admin/attendances/list` sesuai role di atas. | Dosen pemilik kelas aktif; Mahasiswa enrolled; session/attendance fixture sementara. | Generate/scan/close di Flutter, refresh Mobile/Web, DB read-only memeriksa session status dan attendance. | QR token tidak boleh dicatat. Attendance tidak punya delete; session close bukan penghapusannya. Perlu disposable one-use dan teardown owner. Negative case: Mahasiswa tidak enrolled, Dosen bukan pemilik kelas. `NOT RUN`. |
| Pengumuman | Web Admin `POST /api/v1/admin/announcements` dengan body `{title,category,content,start_date,end_date,status}`; `PUT /api/v1/admin/announcements/update?id={id}` dengan field yang sama; `DELETE /api/v1/admin/announcements/delete?id={id}`. Mutasi `admin`-only menurut `main.go`; daftar `GET /api/v1/admin/announcements/list` mengizinkan Admin/Dosen/Mahasiswa/Orang Tua, tidak Kaprodi. `GET /api/v1/notifications` mengizinkan shared roles tanpa Kaprodi. | Admin; Mahasiswa/Dosen/Orang Tua untuk pembacaan sesuai audience/izin; pengumuman fixture unik. | Create/update di Web; baca ulang di Web dan Mobile; DB read-only memeriksa status/tanggal/konten fixture. | Exact-ID delete tersedia untuk record uji. Negative case: role yang tak diizinkan tidak boleh mengubah; jangan mengasumsikan notifikasi mencakup konten selain kontrak. `NOT RUN`. |
| UKT | Web: `POST /api/v1/admin/ukt` body `{student_id,semester,billed,paid,due_date}`; `PUT /api/v1/admin/ukt/update?id={id}` body sama; `DELETE /api/v1/admin/ukt/delete?id={id}`; `GET /api/v1/admin/ukt/list`. Role `admin, kaprodi`; Kaprodi dibatasi scope mahasiswa. Mobile: `GET /api/v1/parent/child/ukt?child_id={id}` role `orangtua`; `GET /api/v1/student/ukt/my` role `mahasiswa`. | Admin/Kaprodi sesuai scope; Mahasiswa; Orang Tua tertaut; UKT fixture dummy. | Mutasi Web, baca ulang pada klien yang berhak, DB read-only memeriksa student, periode, tagihan, pembayaran, dan tanggal. | Mutasi menyangkut data keuangan; gunakan fixture disposable. Delete exact-ID route ada tetapi tetap perlu persetujuan cleanup. Negative case: Orang Tua dengan anak tak tertaut dan Kaprodi di luar scope. `NOT RUN`. |
| Metadata dokumen | Web: `POST /api/v1/admin/documents` body `{student_id,type,semester,status,date}`; `PUT /api/v1/admin/documents/update?id={id}` body sama; `DELETE /api/v1/admin/documents/delete?id={id}`; `GET /api/v1/admin/documents/list`. Role `admin, kaprodi`, Kaprodi scoped. Orang Tua: `GET /api/v1/parent/child/documents?child_id={id}` role `orangtua`. Model/handler mengembalikan metadata, bukan file. | Admin/Kaprodi sesuai scope; Orang Tua tertaut dan negative case Orang Tua/anak tak tertaut; dokumen metadata fixture. | Kelola metadata Web; baca metadata Mobile; DB read-only memeriksa student relation dan metadata; pastikan ID anak tak tertaut ditolak. | Exact-ID delete metadata tersedia; file access tidak termasuk dan tidak ada URL/file route yang ditemukan. `NOT RUN`. |
| Profil dan relasi wali-anak | Profil: `GET /api/v1/users/me` dan `PUT /api/v1/users/me`, role semua role terdaftar; PUT menerima `name`, `email`, `nim`, `program_studi` (`name`/`email` wajib di DTO). Link: Admin `POST /api/v1/admin/parents/link`, body `{ "parent_id": uint, "student_id": uint }`; Orang Tua `GET /api/v1/parent/children` dan GET `/api/v1/parent/child/profile`, `/grades`, `/attendances`, `/summary`, `/schedules`, `/ukt`, `/documents` dengan query `child_id` opsional. Backend memeriksa relasi anak pada request. | Akun fixture terpisah untuk profil; Admin; Orang Tua tertaut; Orang Tua/anak tidak tertaut sebagai negative case. | Baca/update profil fixture dan baca ulang; buat relasi hanya pada disposable; validasi daftar anak dan akses child ID tertaut vs tidak tertaut; DB read-only memeriksa kepemilikan dan relasi. | Tidak ada unlink route terverifikasi; profile update harus dipulihkan atau dibuang bersama disposable. Link hanya pada disposable dan perlu teardown owner. Negative role/ID harus ditolak, status aktual dicatat saat runtime yang telah diizinkan. `NOT RUN`. |

Semua pemeriksaan UI, API runtime, DB readback, akses negatif, dan cleanup pada matriks di atas belum dijalankan. Jangan menafsirkan route yang terdaftar sebagai bukti persistensi atau sinkronisasi lintas platform.
