# Ringkasan Audit Integrasi Flutter–Backend dan Akses Data

**Tanggal:** 24 November 2026
**Status keseluruhan:** `PARTIAL — CONNECTED WITH APPROVAL BLOCKERS`
**Runtime E2E:** `BLOCKED / NOT RUN`

## Hasil Utama

- Alur login, profil, dashboard, KRS, nilai, absensi, QR, dan orang tua sudah terhubung ke backend.
- Backend menegakkan kepemilikan resource untuk dosen, mahasiswa, dan orang tua.
- Kaprodi sudah di-scope ke program studi yang ditugaskan pada list, create, update, dan delete.

## Perbaikan yang Dilakukan

1. **Delete Kaprodi aman** — kasus, dokumen, dan UKT kini memakai query scope lalu menghapus berdasarkan primary key. Sebelumnya `DELETE` ber-join menghasilkan HTTP 500.
2. **Jadwal global ditutup** — `/admin/schedules/list` dan `/calendar` menjadi `admin`-only.
3. **Profil mandiri dibatasi** — `PUT /users/me` tidak lagi mengubah NIM/program studi.
4. **Paginasi dosen diperbaiki** — `ApiService.getAll` mengambil semua halaman kelas dan mahasiswa; pengujian dilakukan melalui helper/unit test dan pemakaian di layar, bukan E2E.
5. **Profil mahasiswa nyata** — memakai `/users/me`, bukan `TRKJ` hardcoded atau `SharedPreferences` saja.
6. **Kontrol dekoratif dihapus** — tombol login Facebook/Google yang tidak berfungsi dihilangkan.
7. **Prodi dosen dari server** — memakai `program_studi` dari `/users/me`.

## Bukti Pengujian

| Pemeriksaan | Hasil |
|---|---|
| `go build ./...` | Lulus |
| `go test ./...` dengan DB `edutrack_test` disposable | Lulus semua paket |
| `flutter analyze` | Tidak ada masalah |
| `flutter test` | 16 tes lulus |
| `web-admin npm test` | 18 tes lulus |
| `web-admin npm run lint` | Lulus |

## Masih Blocked / Perlu Keputusan

1. **Relasi prodi terstruktur** — masih string `users.program_studi`; enforcement server-side ada, model data belum sesuai keputusan A1.
2. **Verifikasi orang tua–anak** — belum ada kolom status verifikasi; relasi hanya dibuat admin.
3. **Registrasi publik role dosen/mahasiswa/orang tua** — belum diverifikasi admin.
4. **Runtime E2E dan inspeksi UI** — belum dijalankan karena checklist environment disposable belum disetujui.

## Status per Peran

| Peran | Status |
|---|---|
| Admin | `CONNECTED` |
| Dosen | `CONNECTED` |
| Mahasiswa | `CONNECTED` |
| Orang tua | `CONNECTED` (verifikasi relasi `BLOCKED`) |
| Kaprodi | `PARTIAL` (enforcement ada, model prodi belum terstruktur) |

## File Laporan Lengkap

`docs/audit/FLUTTER_BACKEND_INTEGRATION_AND_DATA_ACCESS_AUDIT.md`
