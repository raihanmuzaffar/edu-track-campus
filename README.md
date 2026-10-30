# EduTrack Campus 🎓

Sistem Informasi Tracking Akademik (Backend API) yang dirancang untuk mengelola data akademik kampus (Mahasiswa, Dosen, Kaprodi, Admin, dan Orang Tua).

## 🚀 Tech Stack
- **Language**: Go (Golang)
- **Database**: PostgreSQL 16
- **Cache**: Redis 7
- **Web Server**: Nginx (Reverse Proxy)
- **Containerization**: Docker & Docker Compose
- **API Documentation**: Swagger (OpenAPI)
- **Testing**: Go Testing (Integration Test)

---

## 🛠️ Cara Menjalankan Proyek (Development)

### Prasyarat
- Docker & Docker Compose terinstal.
- Go 1.22+ terinstal (untuk menjalankan *seeder* dan *testing*).

### 1. Nyalakan Docker (Backend, DB, Redis, Nginx)
Buka terminal, masuk ke folder `docker`, lalu jalankan:
```bash
cd docker
docker compose up -d --build
```
Tunggu hingga semua container berstatus `Started` atau `Healthy`.

### 2. Isi Database dengan Data Dummy (Seeding)
Agar QA atau Frontend tidak kebingungan karena database kosong, kita sudah menyiapkan *script seeder*.
Buka **terminal baru** (biarkan Docker berjalan), lalu jalankan:
```bash
cd backend
go run seed/main.go
```
*(Script ini akan otomatis mengisi data Admin, Kaprodi, Dosen, Mahasiswa, Kelas, Mata Kuliah, Nilai, dll).*

---

## 📚 Dokumentasi API (Swagger)
Kita sudah mengintegrasikan Swagger untuk memudahkan pengujian API.
- **URL**: `http://localhost:8080/swagger/index.html`
- **Cara Pakai**: 
  1. Klik endpoint yang ingin diuji (misal: `POST /login`).
  2. Klik tombol **"Try it out"**.
  3. Isi data JSON, lalu klik **"Execute"**.
  4. Untuk endpoint yang butuh login (ada ikon gembok), klik tombol **"Authorize"** di pojok kanan atas, lalu masukkan `Bearer <token_anda>`.

---

## 🔑 Akun untuk Testing (Bawaan Seeder)
Gunakan akun-akun ini untuk menguji fitur di Swagger, Postman, atau Frontend/Mobile.

| Role | Email | Password |
| :--- | :--- | :--- |
| **Admin** | `admin@edutrack.com` | `password123` |
| **Kaprodi** | `kaprodi@edutrack.com` | `password123` |
| **Dosen** | `dosen1@edutrack.com` | `password123` |
| **Mahasiswa** | `mhs1@edutrack.com` | `password123` |
| **Orang Tua** | *(Daftarkan manual via API Register)* | `password123` |

---

## 🧪 Cara Menjalankan Automated Testing
Kita sudah menulis 15 *Integration Test* untuk memastikan API tidak *crash* saat menerima data yang salah (validasi).

Buka terminal baru, masuk ke folder `backend`, dan pastikan Docker PostgreSQL sedang menyala. Lalu jalankan:
```bash
cd backend
go test ./handlers/... -v
```
Jika semua tes berhasil, Anda akan melihat tulisan **PASS** berwarna hijau.

---

## 📂 Struktur Repositori
- `/backend` : Source code REST API (Go), Seeder, dan Testing.
- `/web-admin` : Source code Dashboard Web (React) untuk Admin & Kaprodi.
- `/mobile` : Source code Aplikasi Mobile (Flutter) untuk Dosen, Mahasiswa, Ortu.
- `/docker` : Konfigurasi Nginx dan Docker Compose.

---

## 👨‍💻 Developer
- **Nama**: Raihan Muzaffar
- **Kontak**: [MohdRaihanMuzhaffar](https://github.com/MohdRaihanMuzhaffar)

- **Nama**: Indri Ariska 
- **Kontak**: [indriariska](https://github.com/indriariska)

- **Nama**: Fitri
- **Kontak**: [Fitri](https://github.com/Fitri-zr)
 

