import { useMemo, useState } from 'react'
import ProdiSidebar from '../components/ProdiSidebar'
import { prodiNavigation } from '../constants/prodiNavigation'
import './ProdiDashboard.css'

const definitions = {
  students: {
    title: 'Mahasiswa TRKJ',
    singular: 'mahasiswa',
    description: 'Pemantauan mahasiswa TRKJ berdasarkan kelas, semester, dan status akademik.',
    search: 'Cari nama atau NIM...',
    searchable: ['nim', 'name', 'className', 'statusAcademic'],
    filters: [
      { key: 'className', label: 'Semua kelas' },
      { key: 'semester', label: 'Semua semester' },
      { key: 'statusAcademic', label: 'Semua status' },
    ],
    columns: [
      ['nim', 'NIM'],
      ['name', 'Mahasiswa'],
      ['className', 'Kelas'],
      ['semester', 'Semester'],
      ['statusAcademic', 'Status akademik'],
      ['attendance', 'Kehadiran'],
      ['ukt', 'UKT'],
      ['krs', 'KRS'],
      ['khs', 'KHS'],
      ['warning', 'Peringatan'],
    ],
    fields: [
      ['nim', 'NIM'],
      ['name', 'Nama lengkap'],
      ['className', 'Kelas'],
      ['semester', 'Semester'],
      ['statusAcademic', 'Status akademik'],
      ['attendance', 'Kehadiran demo'],
      ['ukt', 'Status UKT'],
      ['krs', 'Status KRS'],
      ['khs', 'Status KHS'],
      ['warning', 'Peringatan akademik'],
    ],
    options: {
      className: ['TRKJ-A', 'TRKJ-B', 'TRKJ-C'],
      statusAcademic: ['Aktif', 'Cuti', 'Perbaikan'],
      semester: ['4', '6', '8'],
    },
  },
  classes: {
    title: 'Kelas & Semester',
    singular: 'kelas',
    description: 'Pemantauan kelas TRKJ berdasarkan paket, kehadiran, dan kesiapan KHS.',
    search: 'Cari kelas, paket, atau dosen...',
    searchable: ['className', 'packageName', 'lecturer', 'room'],
    filters: [
      { key: 'semester', label: 'Semua semester' },
      { key: 'status', label: 'Semua status' },
    ],
    columns: [
      ['className', 'Kelas'],
      ['semester', 'Semester'],
      ['totalStudents', 'Mahasiswa'],
      ['packageName', 'Paket'],
      ['lecturer', 'Dosen'],
      ['attendance', 'Kehadiran'],
      ['grades', 'Nilai'],
      ['status', 'Status'],
    ],
    fields: [
      ['className', 'Kelas'],
      ['semester', 'Semester'],
      ['totalStudents', 'Jumlah mahasiswa'],
      ['packageName', 'Paket mata kuliah'],
      ['lecturer', 'Dosen pengampu'],
      ['attendance', 'Rekap kehadiran'],
      ['grades', 'Kelengkapan nilai'],
      ['status', 'Status kelas'],
    ],
    options: {
      semester: ['4', '6', '8'],
      status: ['Siap', 'Perlu review', 'Draft'],
    },
  },
  packages: {
    title: 'Paket Mata Kuliah',
    singular: 'paket',
    description: 'Pemeriksaan paket mata kuliah yang disiapkan TRKJ sesuai semester dan kelas.',
    search: 'Cari kode atau nama paket...',
    searchable: ['code', 'name', 'lecturer', 'semester'],
    filters: [
      { key: 'semester', label: 'Semua semester' },
      { key: 'status', label: 'Semua status' },
    ],
    columns: [
      ['code', 'Kode'],
      ['name', 'Nama paket'],
      ['semester', 'Semester'],
      ['courses', 'Mata kuliah'],
      ['lecturer', 'Dosen pengampu'],
      ['schedule', 'Jadwal'],
      ['status', 'Status'],
    ],
    fields: [
      ['code', 'Kode paket'],
      ['name', 'Nama paket'],
      ['semester', 'Semester'],
      ['courses', 'Daftar mata kuliah'],
      ['lecturer', 'Dosen pengampu'],
      ['schedule', 'Jadwal dan ruang'],
      ['status', 'Status kesiapan'],
    ],
    options: {
      semester: ['4', '6'],
      status: ['Lengkap', 'Perlu revisi', 'Draft'],
    },
  },
  schedule: {
    title: 'Jadwal Kuliah',
    singular: 'jadwal',
    description: 'Pemantauan jadwal TRKJ berdasarkan semester, kelas, dosen, dan ruang.',
    search: 'Cari mata kuliah, dosen, atau ruang...',
    searchable: ['course', 'lecturer', 'room', 'className'],
    filters: [
      { key: 'semester', label: 'Semua semester' },
      { key: 'day', label: 'Semua hari' },
      { key: 'className', label: 'Semua kelas' },
    ],
    columns: [
      ['course', 'Mata kuliah'],
      ['className', 'Kelas'],
      ['semester', 'Semester'],
      ['lecturer', 'Dosen'],
      ['day', 'Hari'],
      ['time', 'Jam'],
      ['room', 'Ruang'],
      ['status', 'Status'],
    ],
    fields: [
      ['course', 'Mata kuliah'],
      ['className', 'Kelas'],
      ['semester', 'Semester'],
      ['lecturer', 'Dosen'],
      ['day', 'Hari'],
      ['time', 'Jam'],
      ['room', 'Ruang'],
      ['status', 'Status jadwal'],
    ],
    options: {
      semester: ['4', '6'],
      day: ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'],
      className: ['TRKJ-A', 'TRKJ-B', 'TRKJ-C'],
    },
  },
  krs: {
    title: 'KRS Paket',
    singular: 'KRS',
    description: 'Pemeriksaan kesiapan KRS paket mahasiswa TRKJ berdasarkan paket dan jadwal yang telah ditetapkan.',
    search: 'Cari nama atau NIM mahasiswa...',
    searchable: ['nim', 'name', 'className'],
    filters: [
      { key: 'semester', label: 'Semua semester' },
      { key: 'status', label: 'Semua status' },
    ],
    columns: [
      ['nim', 'NIM'],
      ['name', 'Mahasiswa'],
      ['className', 'Kelas'],
      ['semester', 'Semester'],
      ['totalCredits', 'SKS'],
      ['scheduleStatus', 'Jadwal'],
      ['status', 'Status KRS'],
      ['publication', 'Publikasi'],
    ],
    fields: [
      ['nim', 'NIM'],
      ['name', 'Nama mahasiswa'],
      ['className', 'Kelas'],
      ['semester', 'Semester'],
      ['totalCredits', 'Total SKS'],
      ['scheduleStatus', 'Kelengkapan jadwal'],
      ['status', 'Status pemeriksaan'],
      ['publication', 'Status publikasi'],
    ],
    options: {
      semester: ['4', '6'],
      status: ['Siap', 'Perlu perbaikan', 'Menunggu data'],
    },
  },
  grades: {
    title: 'Nilai Mahasiswa',
    singular: 'nilai',
    description: 'Pemantauan kelengkapan dan validitas nilai mahasiswa TRKJ per mata kuliah.',
    search: 'Cari mahasiswa, NIM, atau mata kuliah...',
    searchable: ['nim', 'name', 'course', 'status'],
    filters: [
      { key: 'semester', label: 'Semua semester' },
      { key: 'status', label: 'Semua status' },
      { key: 'letter', label: 'Semua huruf' },
    ],
    columns: [
      ['nim', 'NIM'],
      ['name', 'Mahasiswa'],
      ['course', 'Mata kuliah'],
      ['semester', 'Semester'],
      ['assignment', 'Tugas'],
      ['midterm', 'UTS'],
      ['final', 'UAS'],
      ['score', 'Nilai akhir'],
      ['letter', 'Huruf'],
      ['status', 'Status'],
    ],
    fields: [
      ['nim', 'NIM'],
      ['name', 'Nama mahasiswa'],
      ['course', 'Mata kuliah'],
      ['semester', 'Semester'],
      ['assignment', 'Nilai tugas'],
      ['midterm', 'Nilai UTS'],
      ['final', 'Nilai UAS'],
      ['score', 'Nilai akhir'],
      ['letter', 'Nilai huruf'],
      ['status', 'Status kelengkapan'],
    ],
    options: {
      semester: ['4', '6'],
      letter: ['A', 'B', 'C', 'D'],
      status: ['Lengkap', 'Belum lengkap'],
    },
  },
  khs: {
    title: 'KHS & IPS/IPK',
    singular: 'KHS',
    description: 'Pemeriksaan KHS, IPS, IPK, dan status publikasi berdasarkan nilai yang telah lengkap.',
    search: 'Cari nama atau NIM...',
    searchable: ['nim', 'name', 'className'],
    filters: [
      { key: 'semester', label: 'Semua semester' },
      { key: 'status', label: 'Semua status' },
    ],
    columns: [
      ['nim', 'NIM'],
      ['name', 'Mahasiswa'],
      ['className', 'Kelas'],
      ['semester', 'Semester'],
      ['credits', 'SKS'],
      ['ips', 'IPS'],
      ['ipk', 'IPK'],
      ['status', 'Status KHS'],
      ['publication', 'Publikasi'],
    ],
    fields: [
      ['nim', 'NIM'],
      ['name', 'Nama mahasiswa'],
      ['className', 'Kelas'],
      ['semester', 'Semester'],
      ['credits', 'Jumlah SKS'],
      ['ips', 'IPS'],
      ['ipk', 'IPK kumulatif'],
      ['status', 'Status pemeriksaan'],
      ['publication', 'Status publikasi'],
    ],
    options: {
      semester: ['4', '6'],
      status: ['Disetujui', 'Perlu revisi', 'Tunggu nilai'],
    },
  },
  attendance: {
    title: 'Kehadiran Mahasiswa',
    singular: 'rekap absensi',
    description: 'Pemeriksaan kehadiran mahasiswa TRKJ untuk setiap kelas dan mata kuliah.',
    search: 'Cari mahasiswa, NIM, atau mata kuliah...',
    searchable: ['name', 'nim', 'course', 'className'],
    filters: [
      { key: 'semester', label: 'Semua semester' },
      { key: 'status', label: 'Semua status' },
      { key: 'date', label: 'Semua tanggal' },
    ],
    columns: [
      ['date', 'Tanggal'],
      ['nim', 'NIM'],
      ['name', 'Mahasiswa'],
      ['course', 'Mata kuliah'],
      ['className', 'Kelas'],
      ['present', 'Hadir'],
      ['excused', 'Izin/Sakit'],
      ['absent', 'Alpa'],
      ['attendance', 'Persentase'],
    ],
    fields: [
      ['date', 'Tanggal rekap'],
      ['nim', 'NIM'],
      ['name', 'Nama mahasiswa'],
      ['course', 'Mata kuliah'],
      ['className', 'Kelas'],
      ['semester', 'Semester'],
      ['present', 'Hadir'],
      ['excused', 'Izin/Sakit'],
      ['absent', 'Alpa'],
      ['attendance', 'Persentase hadir'],
      ['status', 'Status'],
    ],
    options: {
      semester: ['4', '6'],
      status: ['Aman', 'Perlu perhatian'],
    },
  },
  ukt: {
    title: 'Pemantauan UKT',
    singular: 'UKT',
    description: 'Pemantauan tunggakan UKT mahasiswa TRKJ dan tindak lanjut yang perlu dilakukan.',
    search: 'Cari nama atau NIM...',
    searchable: ['nim', 'name', 'className'],
    filters: [
      { key: 'semester', label: 'Semua semester' },
      { key: 'status', label: 'Semua status' },
    ],
    columns: [
      ['nim', 'NIM'],
      ['name', 'Mahasiswa'],
      ['className', 'Kelas'],
      ['semester', 'Semester'],
      ['bill', 'Tagihan'],
      ['paid', 'Pembayaran'],
      ['due', 'Sisa'],
      ['status', 'Status'],
      ['note', 'Catatan'],
    ],
    fields: [
      ['nim', 'NIM'],
      ['name', 'Nama mahasiswa'],
      ['className', 'Kelas'],
      ['semester', 'Semester'],
      ['bill', 'Nominal tagihan'],
      ['paid', 'Pembayaran demo'],
      ['due', 'Sisa tunggakan'],
      ['status', 'Status pembayaran'],
      ['note', 'Catatan tindak lanjut'],
    ],
    options: {
      semester: ['4', '6'],
      status: ['Lunas', 'Belum lunas', 'Sebagian'],
    },
  },
  cases: {
    title: 'Peringatan & Kasus Akademik',
    singular: 'kasus',
    description: 'Pemantauan kasus akademik, rekomendasi SP, dan tindak lanjut Prodi.',
    search: 'Cari nama, NIM, atau jenis kasus...',
    searchable: ['nim', 'name', 'type', 'recommendation'],
    filters: [
      { key: 'type', label: 'Semua jenis' },
      { key: 'status', label: 'Semua status' },
    ],
    columns: [
      ['nim', 'NIM'],
      ['name', 'Mahasiswa'],
      ['className', 'Kelas'],
      ['type', 'Jenis kasus'],
      ['note', 'Catatan'],
      ['date', 'Tanggal'],
      ['status', 'Status'],
      ['recommendation', 'Rekomendasi'],
    ],
    fields: [
      ['nim', 'NIM'],
      ['name', 'Nama mahasiswa'],
      ['className', 'Kelas'],
      ['type', 'Jenis kasus'],
      ['note', 'Catatan dasar'],
      ['date', 'Tanggal pencatatan'],
      ['status', 'Status tindak lanjut'],
      ['recommendation', 'Rekomendasi SP'],
    ],
    options: {
      type: ['Absensi bermasalah', 'UKT menunggak', 'Nilai tidak lengkap', 'KHS belum lengkap'],
      status: ['Perlu tindak lanjut', 'Diajukan', 'Menunggu review'],
    },
  },
  announcements: {
    title: 'Pengumuman Prodi',
    singular: 'pengumuman',
    description: 'Rilis pengumuman yang relevan untuk kegiatan akademik dan administratif TRKJ.',
    search: 'Cari judul atau kategori...',
    searchable: ['title', 'category', 'audience'],
    filters: [
      { key: 'category', label: 'Semua kategori' },
      { key: 'status', label: 'Semua status' },
    ],
    columns: [
      ['title', 'Judul'],
      ['category', 'Kategori'],
      ['audience', 'Penerima'],
      ['date', 'Tanggal'],
      ['period', 'Periode'],
      ['status', 'Status'],
    ],
    fields: [
      ['title', 'Judul pengumuman'],
      ['body', 'Isi pengumuman'],
      ['category', 'Kategori'],
      ['audience', 'Penerima'],
      ['period', 'Periode berlaku'],
      ['date', 'Tanggal pembuatan'],
      ['status', 'Status'],
    ],
    options: {
      category: ['Akademik', 'Kegiatan', 'Administrasi'],
      audience: ['Mahasiswa TRKJ', 'Dosen', 'Warga Prodi'],
      status: ['Aktif', 'Draf', 'Berakhir'],
    },
  },
  reports: {
    title: 'Laporan Akademik',
    singular: 'laporan',
    description: 'Ringkasan laporan akademik TRKJ yang bisa dipantau dan diekspor ke CSV.',
    search: 'Cari topik laporan...',
    searchable: ['title', 'type'],
    filters: [
      { key: 'type', label: 'Semua kategori' },
      { key: 'semester', label: 'Semua semester' },
    ],
    columns: [
      ['title', 'Judul laporan'],
      ['type', 'Kategori'],
      ['semester', 'Semester'],
      ['date', 'Tanggal'],
      ['status', 'Status'],
    ],
    fields: [
      ['title', 'Judul laporan'],
      ['type', 'Kategori'],
      ['semester', 'Semester'],
      ['date', 'Tanggal pembuatan'],
      ['status', 'Status laporan'],
    ],
    options: {
      type: ['Mahasiswa', 'Kehadiran', 'Nilai', 'UKT'],
      semester: ['4', '6'],
      status: ['Siap', 'Menunggu review'],
    },
  },
  requests: {
    title: 'Pengajuan Koreksi & Tindak Lanjut',
    singular: 'pengajuan',
    description: 'Catatan pengajuan koreksi dan tindak lanjut yang berasal dari Prodi.',
    search: 'Cari nomor atau jenis pengajuan...',
    searchable: ['requestNo', 'type', 'related'],
    filters: [
      { key: 'type', label: 'Semua jenis' },
      { key: 'status', label: 'Semua status' },
    ],
    columns: [
      ['requestNo', 'Nomor'],
      ['type', 'Jenis'],
      ['related', 'Data terkait'],
      ['date', 'Tanggal'],
      ['reason', 'Alasan'],
      ['status', 'Status'],
    ],
    fields: [
      ['requestNo', 'Nomor pengajuan'],
      ['type', 'Jenis pengajuan'],
      ['related', 'Data terkait'],
      ['date', 'Tanggal dibuat'],
      ['reason', 'Alasan koreksi'],
      ['status', 'Status pengajuan'],
      ['note', 'Catatan tindak lanjut'],
    ],
    options: {
      type: ['Koreksi data mahasiswa', 'Koreksi KRS', 'Koreksi jadwal', 'Koreksi nilai', 'Koreksi UKT'],
      status: ['Draf', 'Diajukan', 'Ditinjau', 'Perlu diperbaiki', 'Selesai'],
    },
  },
}

const seedData = {
  students: [
    { id: 1, nim: '24TRKJ001', name: 'Alya Nabila', className: 'TRKJ-A', semester: '4', statusAcademic: 'Aktif', attendance: '95%', ukt: 'Lunas', krs: 'Siap', khs: 'Lengkap', warning: '—' },
    { id: 2, nim: '24TRKJ002', name: 'Bima Putra', className: 'TRKJ-A', semester: '4', statusAcademic: 'Aktif', attendance: '92%', ukt: 'Sebagian', krs: 'Siap', khs: 'Lengkap', warning: '—' },
    { id: 3, nim: '23TRKJ014', name: 'Citra Maharani', className: 'TRKJ-B', semester: '6', statusAcademic: 'Aktif', attendance: '89%', ukt: 'Lunas', krs: 'Siap', khs: 'Lengkap', warning: '—' },
    { id: 4, nim: '23TRKJ021', name: 'Dian Wahyu', className: 'TRKJ-B', semester: '6', statusAcademic: 'Aktif', attendance: '81%', ukt: 'Belum lunas', krs: 'Perbaikan', khs: 'Belum lengkap', warning: 'Absensi' },
    { id: 5, nim: '22TRKJ009', name: 'Eka Saputra', className: 'TRKJ-C', semester: '8', statusAcademic: 'Perbaikan', attendance: '74%', ukt: 'Belum lunas', krs: 'Perbaikan', khs: 'Perlu review', warning: 'KHS & absensi' },
    { id: 6, nim: '24TRKJ003', name: 'Fadli Rahman', className: 'TRKJ-A', semester: '4', statusAcademic: 'Aktif', attendance: '96%', ukt: 'Lunas', krs: 'Siap', khs: 'Lengkap', warning: '—' },
    { id: 7, nim: '23TRKJ017', name: 'Gina Hertina', className: 'TRKJ-B', semester: '6', statusAcademic: 'Aktif', attendance: '90%', ukt: 'Lunas', krs: 'Siap', khs: 'Lengkap', warning: '—' },
    { id: 8, nim: '24TRKJ005', name: 'Hafiz Ramadhan', className: 'TRKJ-C', semester: '8', statusAcademic: 'Aktif', attendance: '88%', ukt: 'Belum lunas', krs: 'Siap', khs: 'Lengkap', warning: 'UKT' },
  ],
  classes: [
    { id: 1, className: 'TRKJ-A', semester: '4', totalStudents: '31', packageName: 'Paket TRKJ Sem 4', lecturer: 'Rizki Hidayat', attendance: '92%', grades: '85%', status: 'Siap', krs: 'Siap', khs: 'Lengkap', day: 'Senin', time: '08.00–10.30', room: 'Lab Jarkom 1' },
    { id: 2, className: 'TRKJ-B', semester: '6', totalStudents: '29', packageName: 'Paket TRKJ Sem 6', lecturer: 'Santi Handayani', attendance: '88%', grades: '74%', status: 'Perlu review', krs: 'Perbaikan', khs: 'Belum lengkap', day: 'Rabu', time: '13.00–15.30', room: 'Lab Jarkom 3' },
    { id: 3, className: 'TRKJ-C', semester: '8', totalStudents: '24', packageName: 'Paket TRKJ Sem 8', lecturer: 'Deny Mustofa', attendance: '82%', grades: '79%', status: 'Draft', krs: 'Draft', khs: 'Belum lengkap', day: 'Kamis', time: '09.00–12.00', room: 'Ruang 3' },
  ],
  packages: [
    { id: 1, code: 'TRKJ-4A', name: 'Paket Semester 4', semester: '4', courses: 'Jaringan Dasar, Sistem Operasi, Basis Data', lecturer: 'Rizki Hidayat', schedule: 'Senin 08.00 – Lab Jarkom 1', status: 'Lengkap' },
    { id: 2, code: 'TRKJ-4B', name: 'Paket Semester 4 Lab', semester: '4', courses: 'Pemrograman Lanjut, Jaringan Komputer', lecturer: 'Ayu Lestari', schedule: 'Selasa 08.00 – Lab Jarkom 2', status: 'Perlu revisi' },
    { id: 3, code: 'TRKJ-6A', name: 'Paket Semester 6', semester: '6', courses: 'Keamanan Jaringan, Virtualisasi, Administrasi Server', lecturer: 'Santi Handayani', schedule: 'Rabu 13.00 – Lab Server', status: 'Lengkap' },
    { id: 4, code: 'TRKJ-8A', name: 'Paket Semester 8', semester: '8', courses: 'Proyek Akhir, Kerja Praktik', lecturer: 'Deny Mustofa', schedule: 'Kamis 09.00 – Ruang 3', status: 'Draft' },
  ],
  schedule: [
    { id: 1, course: 'Jaringan Dasar', className: 'TRKJ-A', semester: '4', lecturer: 'Rizki Hidayat', day: 'Senin', time: '08.00–10.30', room: 'Lab Jarkom 1', status: 'Lengkap' },
    { id: 2, course: 'Basis Data', className: 'TRKJ-A', semester: '4', lecturer: 'Ayu Lestari', day: 'Selasa', time: '10.00–12.30', room: 'Ruang 204', status: 'Lengkap' },
    { id: 3, course: 'Keamanan Jaringan', className: 'TRKJ-B', semester: '6', lecturer: 'Santi Handayani', day: 'Rabu', time: '13.00–15.30', room: 'Lab Jarkom 3', status: 'Perlu revisi' },
    { id: 4, course: 'Proyek Akhir', className: 'TRKJ-C', semester: '8', lecturer: 'Deny Mustofa', day: 'Kamis', time: '09.00–12.00', room: 'Ruang 3', status: 'Draft' },
  ],
  krs: [
    { id: 1, nim: '24TRKJ001', name: 'Alya Nabila', className: 'TRKJ-A', semester: '4', totalCredits: '20', scheduleStatus: 'Lengkap', status: 'Siap', publication: 'Belum' },
    { id: 2, nim: '24TRKJ002', name: 'Bima Putra', className: 'TRKJ-A', semester: '4', totalCredits: '20', scheduleStatus: 'Lengkap', status: 'Siap', publication: 'Belum' },
    { id: 3, nim: '23TRKJ021', name: 'Dian Wahyu', className: 'TRKJ-B', semester: '6', totalCredits: '18', scheduleStatus: 'Perlu perbaikan', status: 'Perlu perbaikan', publication: 'Tunggu review' },
    { id: 4, nim: '22TRKJ009', name: 'Eka Saputra', className: 'TRKJ-C', semester: '8', totalCredits: '16', scheduleStatus: 'Draft', status: 'Menunggu data', publication: 'Draft' },
  ],
  grades: [
    { id: 1, nim: '24TRKJ001', name: 'Alya Nabila', course: 'Jaringan Dasar', semester: '4', assignment: '88', midterm: '90', final: '91', score: '90', letter: 'A', status: 'Lengkap' },
    { id: 2, nim: '24TRKJ002', name: 'Bima Putra', course: 'Jaringan Dasar', semester: '4', assignment: '82', midterm: '80', final: '84', score: '82', letter: 'A', status: 'Lengkap' },
    { id: 3, nim: '23TRKJ021', name: 'Dian Wahyu', course: 'Keamanan Jaringan', semester: '6', assignment: '73', midterm: '71', final: '0', score: '57', letter: 'D', status: 'Belum lengkap' },
    { id: 4, nim: '22TRKJ009', name: 'Eka Saputra', course: 'Proyek Akhir', semester: '8', assignment: '0', midterm: '0', final: '0', score: '0', letter: '—', status: 'Belum lengkap' },
  ],
  khs: [
    { id: 1, nim: '24TRKJ001', name: 'Alya Nabila', className: 'TRKJ-A', semester: '4', credits: '20', ips: '3.80', ipk: '3.72', status: 'Disetujui', publication: 'Telah dipublikasikan' },
    { id: 2, nim: '24TRKJ002', name: 'Bima Putra', className: 'TRKJ-A', semester: '4', credits: '20', ips: '3.62', ipk: '3.58', status: 'Disetujui', publication: 'Telah dipublikasikan' },
    { id: 3, nim: '23TRKJ021', name: 'Dian Wahyu', className: 'TRKJ-B', semester: '6', credits: '18', ips: '2.94', ipk: '3.12', status: 'Perlu revisi', publication: 'Belum' },
    { id: 4, nim: '22TRKJ009', name: 'Eka Saputra', className: 'TRKJ-C', semester: '8', credits: '16', ips: '2.35', ipk: '2.66', status: 'Tunggu nilai', publication: 'Draft' },
  ],
  attendance: [
    { id: 1, date: '12 Agu 2025', nim: '24TRKJ001', name: 'Alya Nabila', course: 'Jaringan Dasar', className: 'TRKJ-A', semester: '4', present: '13', excused: '1', absent: '0', attendance: '93%', status: 'Aman' },
    { id: 2, date: '12 Agu 2025', nim: '24TRKJ002', name: 'Bima Putra', course: 'Jaringan Dasar', className: 'TRKJ-A', semester: '4', present: '12', excused: '2', absent: '0', attendance: '86%', status: 'Aman' },
    { id: 3, date: '13 Agu 2025', nim: '23TRKJ021', name: 'Dian Wahyu', course: 'Keamanan Jaringan', className: 'TRKJ-B', semester: '6', present: '10', excused: '1', absent: '3', attendance: '71%', status: 'Perlu perhatian' },
    { id: 4, date: '13 Agu 2025', nim: '22TRKJ009', name: 'Eka Saputra', course: 'Proyek Akhir', className: 'TRKJ-C', semester: '8', present: '9', excused: '1', absent: '4', attendance: '64%', status: 'Perlu perhatian' },
  ],
  ukt: [
    { id: 1, nim: '24TRKJ001', name: 'Alya Nabila', className: 'TRKJ-A', semester: '4', bill: 'Rp 1.800.000', paid: 'Rp 1.800.000', due: 'Rp 0', status: 'Lunas', note: 'Pembayaran sesuai tagihan' },
    { id: 2, nim: '24TRKJ002', name: 'Bima Putra', className: 'TRKJ-A', semester: '4', bill: 'Rp 1.800.000', paid: 'Rp 1.050.000', due: 'Rp 750.000', status: 'Sebagian', note: 'Tindak lanjut: cek keuangan' },
    { id: 3, nim: '23TRKJ021', name: 'Dian Wahyu', className: 'TRKJ-B', semester: '6', bill: 'Rp 2.000.000', paid: 'Rp 0', due: 'Rp 2.000.000', status: 'Belum lunas', note: 'Panggilan orang tua' },
    { id: 4, nim: '22TRKJ009', name: 'Eka Saputra', className: 'TRKJ-C', semester: '8', bill: 'Rp 2.200.000', paid: 'Rp 1.500.000', due: 'Rp 700.000', status: 'Sebagian', note: 'Jatuh tempo minggu depan' },
  ],
  cases: [
    { id: 1, nim: '23TRKJ021', name: 'Dian Wahyu', className: 'TRKJ-B', type: 'Absensi bermasalah', note: 'Tiga alpa pada 2 minggu terakhir', date: '11 Agu 2025', status: 'Perlu tindak lanjut', recommendation: 'SP1' },
    { id: 2, nim: '22TRKJ009', name: 'Eka Saputra', className: 'TRKJ-C', type: 'KHS belum lengkap', note: 'Nilai UAS belum masuk di dua mata kuliah', date: '08 Agu 2025', status: 'Diajukan', recommendation: 'SP2' },
    { id: 3, nim: '24TRKJ002', name: 'Bima Putra', className: 'TRKJ-A', type: 'UKT menunggak', note: 'Pembayaran belum sesuai jadwal', date: '05 Agu 2025', status: 'Menunggu review', recommendation: 'Panggilan wali' },
  ],
  announcements: [
    { id: 1, title: 'Validasi KRS Paket Semester 4', category: 'Akademik', audience: 'Mahasiswa TRKJ', date: '12 Agu 2025', period: '12–17 Agu 2025', status: 'Aktif', body: 'Validasi KRS paket untuk mahasiswa TRKJ semester 4 akan dipantau oleh prodi.' },
    { id: 2, title: 'Rapat Koordinasi Prodi dan Dosen TRKJ', category: 'Kegiatan', audience: 'Dosen', date: '15 Agu 2025', period: '15 Agu 2025', status: 'Draf', body: 'Agenda rapat koordinasi pembahasan jadwal dan kelengkapan paket.' },
    { id: 3, title: 'Pemberitahuan hasil review UKT penjaringan', category: 'Administrasi', audience: 'Warga Prodi', date: '10 Agu 2025', period: '10–20 Agu 2025', status: 'Aktif', body: 'Rekap tunggakan UKT semester ini menjadi perhatian khusus prodi.' },
  ],
  reports: [
    { id: 1, title: 'Rekap mahasiswa per kelas', type: 'Mahasiswa', semester: '4', date: '15 Agu 2025', status: 'Siap' },
    { id: 2, title: 'Rekap kehadiran TRKJ', type: 'Kehadiran', semester: '6', date: '14 Agu 2025', status: 'Menunggu review' },
    { id: 3, title: 'Daftar nilai per mata kuliah', type: 'Nilai', semester: '4', date: '12 Agu 2025', status: 'Siap' },
  ],
  requests: [
    { id: 1, requestNo: 'PRODI/TRKJ/2025-001', type: 'Koreksi KRS', related: 'Dian Wahyu', date: '12 Agu 2025', reason: 'Data paket mata kuliah pada KRS belum sesuai jadwal', status: 'Diajukan', note: 'Menunggu tinjauan admin' },
    { id: 2, requestNo: 'PRODI/TRKJ/2025-002', type: 'Koreksi nilai', related: 'Eka Saputra – Proyek Akhir', date: '11 Agu 2025', reason: 'Nilai UAS belum tercatat akibat data kosong', status: 'Ditinjau', note: 'Konfirmasi data nilai dari dosen' },
    { id: 3, requestNo: 'PRODI/TRKJ/2025-003', type: 'Tindak lanjut kasus akademik', related: 'Dian Wahyu', date: '09 Agu 2025', reason: 'Rekomendasi SP1 untuk masalah absensi', status: 'Draf', note: 'Belum final' },
  ],
}

const emptyRows = []
const statusTone = (value = '') => {
  const normalized = value.toLocaleLowerCase('id')
  if (normalized.includes('aktif') || normalized.includes('aman') || normalized.includes('hadir') || normalized.includes('terbit') || normalized.includes('disetujui') || normalized === 'a') return 'success'
  if (normalized.includes('perhatian') || normalized.includes('penting') || normalized.includes('menunggu') || normalized.includes('terjadwal') || normalized.includes('izin') || normalized === 'b') return 'warning'
  if (normalized.includes('tolak') || normalized.includes('alpa') || normalized.includes('tidak hadir') || normalized === 'd' || normalized === 'e') return 'danger'
  if (normalized.includes('arsip') || normalized.includes('nonaktif') || normalized.includes('cuti') || normalized.includes('lulus') || normalized.includes('draf') || normalized.includes('batal')) return 'neutral'
  return 'info'
}

function Badge({ children }) {
  return <span className={`prodi-badge prodi-badge--${statusTone(String(children))}`}>{children || '—'}</span>
}

function initials(name = '') {
  return name
    .split(/[ ,]+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0])
    .join('')
    .toUpperCase()
}

function formatCell(key, value, row) {
  if (key === 'name') {
    return (
      <span className="prodi-person">
        <span className="prodi-avatar" aria-hidden="true">{initials(value)}</span>
        <span><strong>{value}</strong>{row.program && <small>{row.program}</small>}</span>
      </span>
    )
  }
  if (key === 'nim' || key === 'nidn' || key === 'code' || key === 'number') {
    return <span className="prodi-code">{value || '—'}</span>
  }
  if (key === 'status' || key === 'priority' || key === 'letter') return <Badge>{value}</Badge>
  if (key === 'attendance') {
    const percentage = Number.parseInt(value, 10) || 0
    return (
      <span className="prodi-progress-cell">
        <span className="prodi-progress"><span style={{ width: `${Math.min(100, percentage)}%` }} /></span>
        <small>{value}</small>
      </span>
    )
  }
  if (key === 'title' || key === 'course' || key === 'subject') {
    return <span className="prodi-cell-title">{value || '—'}</span>
  }
  return value || '—'
}

function Modal({ title, children, onClose, wide = false }) {
  return (
    <div className="prodi-modal-backdrop" onMouseDown={(event) => event.target === event.currentTarget && onClose()}>
      <section className={`prodi-modal${wide ? ' prodi-modal--wide' : ''}`} role="dialog" aria-modal="true" aria-labelledby="prodi-modal-title">
        <header className="prodi-modal-header">
          <div><span className="prodi-eyebrow">MODE DEMO</span><h2 id="prodi-modal-title">{title}</h2></div>
          <button className="prodi-icon-button" onClick={onClose} aria-label="Tutup dialog">×</button>
        </header>
        <div className="prodi-modal-body">{children}</div>
      </section>
    </div>
  )
}

export default function ProdiDashboard() {
  const [activePage, setActivePage] = useState('overview')
  const [data, setData] = useState(() => Object.fromEntries(Object.entries(seedData).map(([key, rows]) => [key, [...rows]])))
  const [search, setSearch] = useState('')
  const [filters, setFilters] = useState({})
  const [sort, setSort] = useState({ key: '', direction: 'asc' })
  const [page, setPage] = useState(1)
  const [pageSize, setPageSize] = useState(5)
  const [modal, setModal] = useState(null)
  const [form, setForm] = useState({})
  const [toast, setToast] = useState('')
  const [demoState, setDemoState] = useState('ready')
  const [openMenu, setOpenMenu] = useState(null)
  const [classView, setClassView] = useState('table')
  const [reportPeriod, setReportPeriod] = useState('Semester Ganjil')
  const [settings, setSettings] = useState({
    'Program Studi': 'Informatika',
    Fakultas: 'Fakultas Sains dan Teknologi',
    'Ketua Program Studi': 'Dr. Arman Wijaya, M.Kom.',
    'Tahun Akademik': '2025 / 2026',
    'Semester Aktif': 'Ganjil',
    'Email Prodi': 'informatika@example.test',
  })

  const pageDefinition = definitions[activePage]
  const rows = data[activePage] || emptyRows
  const query = search.trim().toLocaleLowerCase('id')

  const filteredRows = useMemo(() => {
    if (!pageDefinition) return []
    return rows.filter((row) => {
      const matchesQuery = !query || pageDefinition.searchable.some((key) => String(row[key] ?? '').toLocaleLowerCase('id').includes(query))
      const matchesFilters = pageDefinition.filters.every(({ key }) => !filters[key] || String(row[key]) === filters[key])
      return matchesQuery && matchesFilters
    })
  }, [rows, query, filters, pageDefinition])

  const sortedRows = useMemo(() => {
    if (!sort.key) return filteredRows
    return [...filteredRows].sort((a, b) => {
      const left = String(a[sort.key] ?? '')
      const right = String(b[sort.key] ?? '')
      const numericLeft = Number.parseFloat(left)
      const numericRight = Number.parseFloat(right)
      const comparison = Number.isNaN(numericLeft) || Number.isNaN(numericRight)
        ? left.localeCompare(right, 'id', { numeric: true })
        : numericLeft - numericRight
      return sort.direction === 'asc' ? comparison : -comparison
    })
  }, [filteredRows, sort])

  const pageCount = Math.max(1, Math.ceil(sortedRows.length / pageSize))
  const visibleRows = sortedRows.slice((page - 1) * pageSize, page * pageSize)

  function notify(message) {
    setToast(message)
    window.setTimeout(() => setToast(''), 2800)
  }

  function navigate(id) {
    setActivePage(id)
    setSearch('')
    setFilters({})
    setSort({ key: '', direction: 'asc' })
    setPage(1)
    setDemoState('ready')
    setOpenMenu(null)
    if (id !== 'classes') setClassView('table')
  }

  function openCreate() {
    setForm({})
    setModal({ type: 'form', mode: 'create' })
  }

  function openEdit(row) {
    setForm({ ...row })
    setModal({ type: 'form', mode: 'edit', row })
  }

  function saveForm(event) {
    event.preventDefault()
    const missing = pageDefinition.fields.find(([key]) => !String(form[key] ?? '').trim() && key !== 'body')
    if (missing) {
      notify(`${missing[1]} wajib diisi.`)
      return
    }

    if (activePage === 'students' && modal.mode === 'edit' && form.status !== modal.row.status) {
      if (!window.confirm(`Simulasikan perubahan status menjadi "${form.status}"? Perubahan ini bukan status resmi.`)) return
    }

    if (activePage === 'classes') {
      const toMinutes = (time) => {
        const [hours, minutes] = time.split('.').map(Number)
        return hours * 60 + minutes
      }
      const [start, end] = String(form.schedule).split(/[–-]/).map((time) => time.trim())
      const conflict = data.classes.some((item) => {
        if (modal.mode === 'edit' && item.id === modal.row.id) return false
        if (item.day !== form.day) return false
        const [otherStart, otherEnd] = String(item.schedule).split(/[–-]/).map((time) => time.trim())
        if (!otherStart || !otherEnd || !start || !end) return false
        const overlaps = toMinutes(start) < toMinutes(otherEnd) && toMinutes(end) > toMinutes(otherStart)
        return overlaps && (item.room === form.room || item.lecturer === form.lecturer)
      })
      if (conflict) {
        notify('Jadwal bertabrakan dengan kelas demo pada dosen atau ruang yang sama.')
        return
      }
    }

    if (activePage === 'grades') {
      const scores = ['assignment', 'midterm', 'final'].map((key) => Number(form[key]))
      if (scores.some((score) => !Number.isFinite(score) || score < 0 || score > 100)) {
        notify('Nilai tugas, UTS, dan UAS harus berada pada rentang 0–100.')
        return
      }
    }

    const next = { ...form, id: modal.mode === 'edit' ? modal.row.id : Date.now() }
    if (activePage === 'grades' && next.assignment && next.midterm && next.final) {
      const score = Math.round(Number(next.assignment) * 0.3 + Number(next.midterm) * 0.3 + Number(next.final) * 0.4)
      next.score = String(score)
      next.letter = score >= 85 ? 'A' : score >= 75 ? 'B' : score >= 60 ? 'C' : 'D'
    }
    setData((current) => ({
      ...current,
      [activePage]: modal.mode === 'edit'
        ? current[activePage].map((row) => row.id === modal.row.id ? next : row)
        : [next, ...current[activePage]],
    }))
    setModal(null)
    notify(`${pageDefinition.singular} demo ${modal.mode === 'edit' ? 'diperbarui' : 'ditambahkan'}.`)
  }

  function removeRow(row) {
    const approved = window.confirm(`Hapus ${pageDefinition.singular} demo "${row.name || row.title || row.subject || row.course || row.code || ''}"?`)
    if (!approved) return
    setData((current) => ({ ...current, [activePage]: current[activePage].filter((item) => item.id !== row.id) }))
    setModal(null)
    notify('Data demo dihapus dari tampilan ini.')
  }

  function updateStatus(row, status) {
    const action = `Ubah status demo menjadi "${status}"?`
    if (!window.confirm(`${action} Tindakan ini hanya simulasi dan bukan persetujuan resmi.`)) return
    let decisionReason = ''
    if (status === 'Ditolak demo') {
      decisionReason = window.prompt('Masukkan alasan penolakan simulasi:')
      if (!decisionReason?.trim()) {
        notify('Alasan diperlukan untuk simulasi penolakan.')
        return
      }
    }
    setData((current) => ({ ...current, [activePage]: current[activePage].map((item) => item.id === row.id ? { ...item, status, ...(decisionReason ? { decisionReason } : {}) } : item) }))
    setModal(null)
    notify(`Status simulasi: ${status}. Tidak ada tindakan resmi dilakukan.`)
  }

  function openDetail(row) {
    setModal({ type: 'detail', row })
  }

  function exportCsv(target = activePage, exportRows = sortedRows) {
    const exportDefinition = definitions[target]
    const columns = exportDefinition.columns
    const csvRows = [
      columns.map(([, label]) => label),
      ...exportRows.map((row) => columns.map(([key]) => String(row[key] ?? ''))),
    ]
    const csv = `\uFEFF${csvRows.map((line) => line.map((cell) => `"${cell.replaceAll('"', '""')}"`).join(',')).join('\r\n')}`
    const url = URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8' }))
    const anchor = document.createElement('a')
    anchor.href = url
    anchor.download = `demo-${target}.csv`
    anchor.click()
    URL.revokeObjectURL(url)
    notify('CSV data demonstrasi berhasil disiapkan.')
  }

  function setFilter(key, value) {
    setFilters((current) => ({ ...current, [key]: value }))
    setPage(1)
  }

  function toggleSort(key) {
    setSort((current) => ({
      key,
      direction: current.key === key && current.direction === 'asc' ? 'desc' : 'asc',
    }))
  }

  function handleRowAction(row, action) {
    setOpenMenu(null)
    if (action === 'view') openDetail(row)
    if (action === 'edit') openEdit(row)
    if (action === 'delete') removeRow(row)
    if (action === 'approve') updateStatus(row, activePage === 'requests' ? 'Selesai' : activePage === 'announcements' ? 'Aktif' : 'Diajukan')
    if (action === 'archive') updateStatus(row, 'Berakhir')
    if (action === 'reject') updateStatus(row, activePage === 'requests' ? 'Perlu diperbaiki' : activePage === 'announcements' ? 'Berakhir' : 'Draf')
    if (action === 'stage') simulateStage(row)
  }

  function simulateStage(row) {
    const stages = ['Audit awal', 'SP1', 'SP2', 'SP3']
    const currentIndex = stages.indexOf(row.recommendation)
    if (currentIndex < 0 || currentIndex === stages.length - 1) {
      notify('Tahap rekomendasi terakhir telah tercapai; tinjauan manual tetap diperlukan.')
      return
    }
    const nextStage = stages[currentIndex + 1]
    if (!window.confirm(`Simulasikan perubahan rekomendasi menjadi ${nextStage}? Ini hanya untuk pratinjau frontend.`)) return
    setData((current) => ({
      ...current,
      cases: current.cases.map((item) => item.id === row.id
        ? { ...item, recommendation: nextStage, status: 'Diajukan' }
        : item),
    }))
    setModal(null)
    notify(`Rekomendasi ${nextStage} disimulasikan untuk ditinjau.`)
  }

  function renderTable() {
    if (demoState === 'loading') {
      return <StatePanel type="loading" title="Memuat data demonstrasi" detail="Simulasi lokal; tidak ada koneksi ke server." />
    }
    if (demoState === 'error') {
      return <StatePanel type="error" title="Data tidak dapat ditampilkan" detail="Contoh tampilan error untuk demonstrasi." action={() => setDemoState('ready')} />
    }
    if (demoState === 'empty' || !visibleRows.length) {
      return <StatePanel type="empty" title={demoState === 'empty' ? 'Belum ada data' : 'Data tidak ditemukan'} detail="Ubah pencarian atau filter, atau tampilkan data demo kembali." action={demoState === 'empty' ? () => setDemoState('ready') : undefined} />
    }

    return (
      <div className="prodi-table-scroll">
        <table className="prodi-table">
          <thead><tr>
            {pageDefinition.columns.map(([key, label]) => (
              <th key={key} scope="col">
                <button className="prodi-sort-button" onClick={() => toggleSort(key)} aria-label={`Urutkan berdasarkan ${label}`}>
                  {label}<span aria-hidden="true">{sort.key === key ? (sort.direction === 'asc' ? ' ↑' : ' ↓') : ' ↕'}</span>
                </button>
              </th>
            ))}
            <th scope="col"><span className="prodi-visually-hidden">Aksi</span></th>
          </tr></thead>
          <tbody>
            {visibleRows.map((row) => (
              <tr key={row.id} onDoubleClick={() => openDetail(row)}>
                {pageDefinition.columns.map(([key]) => <td key={key}>{formatCell(key, row[key], row)}</td>)}
                <td className={`prodi-row-actions${openMenu === row.id ? ' is-open' : ''}`}>
                  <button className="prodi-icon-button prodi-icon-button--small" onClick={() => setOpenMenu((current) => current === row.id ? null : row.id)} aria-expanded={openMenu === row.id} aria-label={`Aksi ${row.name || row.title || row.course || ''}`}>···</button>
                  <div className="prodi-row-action-menu">
                    <button onClick={() => handleRowAction(row, 'view')}>Lihat detail</button>
                    <button onClick={() => handleRowAction(row, 'edit')}>Edit demo</button>
                    {(activePage === 'announcements' || activePage === 'requests') && <button onClick={() => handleRowAction(row, 'approve')}>{activePage === 'requests' ? 'Tandai selesai' : 'Aktifkan pengumuman'}</button>}
                    {(activePage === 'requests' || activePage === 'announcements') && <button onClick={() => handleRowAction(row, 'reject')}>{activePage === 'requests' ? 'Tandai perlu diperbaiki' : 'Tutup pengumuman'}</button>}
                    {activePage === 'announcements' && <button onClick={() => handleRowAction(row, 'archive')}>Arsipkan demo</button>}
                    {activePage === 'cases' && <button onClick={() => handleRowAction(row, 'stage')}>Usulkan review lanjutan</button>}
                    <button className="is-danger" onClick={() => handleRowAction(row, 'delete')}>Hapus demo</button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    )
  }

  function renderModule() {
    return (
      <section className="prodi-panel">
        <div className="prodi-toolbar">
          <label className="prodi-search">
            <span aria-hidden="true">⌕</span>
            <span className="prodi-visually-hidden">Cari {pageDefinition.singular}</span>
            <input value={search} onChange={(event) => { setSearch(event.target.value); setPage(1) }} placeholder={pageDefinition.search} />
            {search && <button type="button" onClick={() => setSearch('')} aria-label="Hapus pencarian">×</button>}
          </label>
          <div className="prodi-toolbar-actions">
            {pageDefinition.filters.map(({ key, label }) => {
              const options = [...new Set(rows.map((row) => row[key]).filter(Boolean))]
              return (
                <label className="prodi-filter" key={key}>
                  <span className="prodi-visually-hidden">{label}</span>
                  <select value={filters[key] || ''} onChange={(event) => setFilter(key, event.target.value)}>
                    <option value="">{label}</option>
                    {options.map((option) => <option key={option} value={option}>{key === 'cohort' ? `Angkatan ${option}` : key === 'semester' ? `Semester ${option}` : option}</option>)}
                  </select>
                </label>
              )
            })}
            <button className="prodi-button prodi-button--outline" onClick={exportCsv}>↓ <span>Ekspor CSV</span></button>
            {pageDefinition.fields && <button className="prodi-button prodi-button--primary" onClick={openCreate}>＋ <span>Tambah {pageDefinition.singular}</span></button>}
            {activePage === 'classes' && <div className="prodi-view-toggle" role="group" aria-label="Tampilan kelas">
              <button className={classView === 'table' ? 'is-selected' : ''} onClick={() => setClassView('table')}>Tabel</button>
              <button className={classView === 'week' ? 'is-selected' : ''} onClick={() => setClassView('week')}>Jadwal</button>
            </div>}
          </div>
        </div>
        {activePage === 'classes' && classView === 'week' ? <div className="prodi-week-grid">
          {['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'].map((day) => <section key={day}><h3>{day}</h3>{sortedRows.filter((item) => item.day === day).map((item) => <article key={item.id}><strong>{item.schedule}</strong><span>{item.course}</span><small>{item.group} · {item.lecturer}</small><small>{item.room}</small></article>)}</section>)}
        </div> : renderTable()}
        <div className="prodi-pagination">
          <span>Menampilkan <strong>{sortedRows.length ? (page - 1) * pageSize + 1 : 0}–{Math.min(page * pageSize, sortedRows.length)}</strong> dari <strong>{sortedRows.length}</strong> data demo</span>
          <div className="prodi-pagination-controls">
            <label>Baris
              <select value={pageSize} onChange={(event) => { setPageSize(Number(event.target.value)); setPage(1) }}>
                <option value="5">5</option><option value="10">10</option>
              </select>
            </label>
            <button onClick={() => setPage((current) => Math.max(1, current - 1))} disabled={page <= 1} aria-label="Halaman sebelumnya">‹</button>
            <span>{page} / {pageCount}</span>
            <button onClick={() => setPage((current) => Math.min(pageCount, current + 1))} disabled={page >= pageCount} aria-label="Halaman berikutnya">›</button>
          </div>
        </div>
      </section>
    )
  }

  function renderOverview() {
    const activeStudents = data.students.filter((student) => student.statusAcademic === 'Aktif').length
    const totalClasses = data.classes.length
    const avgAttendance = Math.round(data.attendance.reduce((sum, item) => sum + Number.parseInt(item.attendance, 10), 0) / data.attendance.length)
    const attentionCount = data.attendance.filter((item) => item.status === 'Perlu perhatian').length
    const unpaidUkt = data.ukt.filter((item) => item.status !== 'Lunas').length
    const academicCases = data.cases.length
    const gradeCompletion = Math.round((data.grades.filter((item) => item.status === 'Lengkap').length / data.grades.length) * 100)
    const krsDraft = data.krs.filter((item) => item.status !== 'Siap').length
    const khsPending = data.khs.filter((item) => item.status !== 'Disetujui').length
    const scheduleIssues = data.schedule.filter((item) => item.status !== 'Lengkap').length
    const activeAnnouncements = data.announcements.filter((item) => item.status === 'Aktif').length
    const stats = [
      { label: 'Mahasiswa aktif', value: activeStudents, icon: '♙', tint: 'blue', delta: '+8.2%', note: 'TRKJ aktif' },
      { label: 'Jumlah kelas', value: totalClasses, icon: '▦', tint: 'purple', delta: 'Semester aktif', note: 'TRKJ' },
      { label: 'Mahasiswa per kelas', value: Math.round(activeStudents / totalClasses), icon: '▤', tint: 'teal', delta: 'Rata-rata', note: 'per kelas' },
      { label: 'Rekap kehadiran', value: `${avgAttendance}%`, icon: '◷', tint: 'orange', delta: 'Periode demo', note: 'kelas TRKJ' },
      { label: 'Absensi bermasalah', value: attentionCount, icon: '⚠', tint: 'orange', delta: 'Butuh review', note: 'per semester' },
      { label: 'UKT belum lunas', value: unpaidUkt, icon: '◈', tint: 'purple', delta: 'Tagihan aktif', note: 'mahasiswa' },
      { label: 'Perlu tindak lanjut', value: academicCases, icon: '⚑', tint: 'blue', delta: 'Kasus akademik', note: 'TRKJ' },
      { label: 'Kelengkapan nilai', value: `${gradeCompletion}%`, icon: '◫', tint: 'teal', delta: 'Kelas TRKJ', note: 'nilai lengkap' },
    ]

    return (
      <>
        <div className="prodi-stat-grid">
          {stats.map((stat) => <article className={`prodi-stat-card prodi-stat-card--${stat.tint}`} key={stat.label}>
            <div className="prodi-stat-top"><span>{stat.label}</span><span className="prodi-stat-icon">{stat.icon}</span></div>
            <strong className="prodi-stat-value">{stat.value}</strong>
            <div className="prodi-stat-foot"><b>{stat.delta}</b><span>{stat.note}</span></div>
          </article>)}
        </div>

        <div className="prodi-overview-grid">
          <section className="prodi-panel prodi-chart-panel">
            <div className="prodi-panel-heading"><div><h2>Aktivitas Akademik TRKJ</h2><p>Ringkasan operasional semester aktif</p></div><Badge>Semester Ganjil</Badge></div>
            <div className="prodi-chart-legend"><span><i className="prodi-legend-dot prodi-legend-dot--blue" />Mahasiswa aktif</span><span><i className="prodi-legend-dot prodi-legend-dot--purple" />Kehadiran</span></div>
            <div className="prodi-bar-chart" role="img" aria-label="Grafik aktivitas TRKJ selama beberapa bulan">
              {[['Mar', 44, 37], ['Apr', 56, 48], ['Mei', 49, 41], ['Jun', 70, 57], ['Jul', 64, 53], ['Agu', 82, 68]].map(([month, active, present]) => <div className="prodi-chart-column" key={month}>
                <div className="prodi-bars"><span className="prodi-bar prodi-bar--blue" style={{ height: `${active}%` }} /><span className="prodi-bar prodi-bar--purple" style={{ height: `${present}%` }} /></div><small>{month}</small>
              </div>)}
            </div>
          </section>
          <section className="prodi-panel prodi-attendance-panel">
            <div className="prodi-panel-heading"><div><h2>Rekap Kehadiran</h2><p>Rata-rata kehadiran TRKJ</p></div><span className="prodi-mini-icon">◷</span></div>
            <div className="prodi-donut-wrap"><div className="prodi-donut"><div><strong>{avgAttendance}%</strong><small>Rata-rata</small></div></div></div>
            <div className="prodi-attendance-legend"><span><i className="prodi-legend-dot prodi-legend-dot--teal" />Hadir <b>{avgAttendance}%</b></span><span><i className="prodi-legend-dot prodi-legend-dot--gray" />Lainnya <b>{100 - avgAttendance}%</b></span></div>
          </section>
        </div>

        <div className="prodi-overview-grid prodi-overview-grid--lower">
          <section className="prodi-panel">
            <div className="prodi-panel-heading"><div><h2>Pelaksanaan Operasional</h2><p>Monitoring TRKJ</p></div><button className="prodi-link-button" onClick={() => navigate('grades')}>Lihat nilai →</button></div>
            <div className="prodi-grade-distribution">
              {[['KRS draft', krsDraft, 'blue'], ['KHS pending', khsPending, 'teal'], ['Jadwal revisi', scheduleIssues, 'orange'], ['Pengumuman aktif', activeAnnouncements, 'red']].map(([label, value, color]) => <div className="prodi-grade-row" key={label}><span>{label}</span><div className="prodi-progress"><i className={`prodi-progress-fill prodi-progress-fill--${color}`} style={{ width: `${Math.min(100, value * 20)}%` }} /></div><b>{value}</b></div>)}
            </div>
          </section>
          <section className="prodi-panel">
            <div className="prodi-panel-heading"><div><h2>Prioritas Tindak Lanjut</h2><p>Checklist Prodi</p></div><span className="prodi-alert-count">{attentionCount + unpaidUkt}</span></div>
            <div className="prodi-attention-item"><span className="prodi-attention-icon">!</span><div><strong>{attentionCount} mahasiswa dengan masalah absensi</strong><small>Periksa rekap sebelum tindakan lanjutan.</small></div><button onClick={() => navigate('attendance')} aria-label="Lihat absensi">→</button></div>
            <div className="prodi-attention-item"><span className="prodi-attention-icon prodi-attention-icon--blue">▧</span><div><strong>{unpaidUkt} mahasiswa dengan UKT belum lunas</strong><small>Catat tindak lanjut keuangan mahasiswa.</small></div><button onClick={() => navigate('ukt')} aria-label="Lihat monitoring UKT">→</button></div>
          </section>
        </div>

        <div className="prodi-overview-grid prodi-overview-grid--lower">
          <section className="prodi-panel">
            <div className="prodi-panel-heading"><div><h2>Pengumuman Prodi</h2><p>Informasi aktif untuk TRKJ</p></div><button className="prodi-link-button" onClick={() => navigate('announcements')}>Semua →</button></div>
            {data.announcements.slice(0, 2).map((item) => <button className="prodi-list-item" key={item.id} onClick={() => { navigate('announcements'); setModal({ type: 'detail', row: item }) }}><span className="prodi-list-icon">◉</span><span><strong>{item.title}</strong><small>{item.category} · {item.date}</small></span><Badge>{item.status}</Badge></button>)}
          </section>
          <section className="prodi-panel">
            <div className="prodi-panel-heading"><div><h2>Aktivitas Terbaru</h2><p>Catatan operation TRKJ</p></div></div>
            <div className="prodi-activity"><i /><span><strong>Rekap nilai kelas diperbarui</strong><small>TRKJ-A · 10.30</small></span></div>
            <div className="prodi-activity"><i /><span><strong>Review KRS semester 4 ditutup</strong><small>Prodi · kemarin</small></span></div>
            <div className="prodi-activity"><i /><span><strong>Pengumuman aktif disiapkan</strong><small>TRKJ · 2 hari lalu</small></span></div>
          </section>
        </div>

        <section className="prodi-panel prodi-shortcuts">
          <div className="prodi-panel-heading"><div><h2>Pintasan</h2><p>Akses cepat modul TRKJ</p></div></div>
          <div className="prodi-shortcut-grid">{prodiNavigation.flatMap((group) => group.items).slice(1).map((item) => <button key={item.id} onClick={() => navigate(item.id)}><span>{item.icon}</span>{item.label}<b>→</b></button>)}</div>
        </section>
      </>
    )
  }

  function renderReports() {
    return (
      <div className="prodi-report-grid">
        <div className="prodi-report-period"><label>Periode laporan<select value={reportPeriod} onChange={(event) => setReportPeriod(event.target.value)}><option>Semester Ganjil</option><option>Semester Genap</option><option>Tahun Akademik</option></select></label><span>Menampilkan: {reportPeriod}</span></div>
        {[
          ['Mahasiswa TRKJ', `${data.students.length} mahasiswa`, 'students'],
          ['Rekap Kehadiran', `${data.attendance.length} data rekap`, 'attendance'],
          ['Nilai Mahasiswa', `${data.grades.length} data nilai`, 'grades'],
          ['Monitoring UKT', `${data.ukt.length} status tagihan`, 'ukt'],
        ].map(([title, detail, target]) => <article className="prodi-panel prodi-report-card" key={title}><span className="prodi-report-icon">▨</span><h3>{title}</h3><p>{detail}</p><div className="prodi-report-actions"><button className="prodi-button prodi-button--outline" onClick={() => { navigate(target); window.setTimeout(() => window.print(), 0) }}>Cetak</button><button className="prodi-button prodi-button--primary" onClick={() => exportCsv(target, data[target])}>Ekspor CSV</button></div></article>)}
        <div className="prodi-demo-note"><strong>Catatan:</strong> laporan ini hanya menggunakan data simulasi frontend TRKJ, bukan data resmi yang dipublikasikan.</div>
      </div>
    )
  }

  function renderSettings() {
    return <form className="prodi-panel prodi-settings-form" onSubmit={(event) => { event.preventDefault(); notify('Pengaturan tampilan demo berhasil diperbarui sementara.') }}>
      <div className="prodi-panel-heading"><div><h2>Informasi Program Studi</h2><p>Profil tampilan contoh; tidak mengubah akun atau data tersimpan.</p></div><Badge>Demo</Badge></div>
      <div className="prodi-form-grid">
        {Object.entries(settings).map(([label, value]) => <label className="prodi-field" key={label}><span>{label}</span><input value={value} onChange={(event) => setSettings((current) => ({ ...current, [label]: event.target.value }))} /></label>)}
      </div>
      <div className="prodi-form-actions"><button className="prodi-button prodi-button--primary" type="submit">Simpan tampilan demo</button></div>
      <div className="prodi-demo-note">Perubahan hanya berlaku sementara selama halaman ini terbuka. Tidak ada informasi akun asli.</div>
    </form>
  }

  function renderSpecialPage() {
    if (activePage === 'overview') return renderOverview()
    if (activePage === 'reports') return renderReports()
    if (activePage === 'settings') return renderSettings()
    return renderModule()
  }

  const currentLabel = prodiNavigation.flatMap((group) => group.items).find((item) => item.id === activePage)?.label || 'Beranda'
  const title = pageDefinition?.title || (activePage === 'reports' ? 'Laporan Akademik' : 'Pengaturan Prodi')
  
  const hasUnreadRequests = data.requests.some((request) => request.status !== 'Selesai' && request.status !== 'Draf')

  return (
    <div className="prodi-app">
      
      {/* SIDEBAR COMPONENT */}
      <ProdiSidebar 
        activePage={activePage} 
        onNavigate={navigate} 
        hasUnreadRequests={hasUnreadRequests} 
      />

      <main className="prodi-main">
        <header className="prodi-topbar">
          <div className="prodi-mobile-brand"><span className="prodi-brand-mark">E</span><strong>EduTrack <small>Prodi</small></strong></div>
          <div className="prodi-breadcrumb"><span>Program Studi</span><span aria-hidden="true">/</span><strong>{currentLabel}</strong></div>
          <div className="prodi-topbar-actions">
            <div className="prodi-semester-chip"><i /> Tahun Akademik 2025/2026</div>
            <button className="prodi-notification-button" onClick={() => { navigate('requests'); notify('Anda melihat daftar pengajuan koreksi Prodi.') }} aria-label="Notifikasi pengajuan Prodi">♧{data.requests.filter((request) => request.status !== 'Selesai' && request.status !== 'Draf').length > 0 && <i />}</button>
            <div className="prodi-topbar-user"><span className="prodi-avatar prodi-avatar--top">AW</span><span><strong>Arman Wijaya</strong><small>Kaprodi</small></span></div>
          </div>
        </header>

        <div className="prodi-content">
          <div className="prodi-demo-banner"><span className="prodi-demo-pulse" /><span><strong>MODE DEMO</strong><span>Data simulasi, belum terhubung ke server. Aksi tidak resmi dan hanya berlaku selama halaman terbuka.</span></span></div>
          <section className="prodi-page-heading">
            <div><div className="prodi-eyebrow">MANAJEMEN PROGRAM STUDI</div><h1>{title}</h1><p>{pageDefinition?.description || (activePage === 'reports' ? 'Ringkasan dan ekspor laporan simulasi akademik.' : 'Pengaturan informasi tampilan demo program studi.')}</p></div>
            {pageDefinition && <div className="prodi-page-heading-actions">
              {['announcements', 'cases', 'requests'].includes(activePage) && <button className="prodi-button prodi-button--outline" onClick={() => setModal({ type: 'workflow' })}>Alur & panduan</button>}
              {['students', 'classes', 'packages', 'schedule', 'krs', 'grades', 'khs', 'attendance', 'ukt', 'announcements', 'requests'].includes(activePage) && <button className="prodi-button prodi-button--primary" onClick={openCreate}>＋ Tambah {pageDefinition.singular}</button>}
            </div>}
          </section>

          {activePage !== 'overview' && activePage !== 'reports' && activePage !== 'settings' && <div className="prodi-demo-statebar">
            <span><strong>Pratinjau state</strong><small>Simulasikan tampilan tanpa API</small></span>
            <div role="group" aria-label="Pilih state demonstrasi">{[['ready', 'Normal'], ['loading', 'Loading'], ['error', 'Error'], ['empty', 'Kosong']].map(([key, label]) => <button key={key} className={demoState === key ? 'is-selected' : ''} onClick={() => setDemoState(key)} aria-pressed={demoState === key}>{label}</button>)}</div>
          </div>}

          {renderSpecialPage()}
          <footer className="prodi-footer"><span>EduTrack Campus <b>·</b> Portal Program Studi</span><span>Mode demonstrasi · Seluruh data bersifat fiktif</span></footer>
        </div>
      </main>

      {modal?.type === 'form' && <Modal title={`${modal.mode === 'edit' ? 'Edit' : 'Tambah'} ${pageDefinition.singular} demo`} onClose={() => setModal(null)}>
        <form onSubmit={saveForm}>
          <div className="prodi-form-grid">{pageDefinition.fields.map(([key, label]) => {
            const isLong = ['body', 'reason', 'followUp'].includes(key)
            const options = pageDefinition.options?.[key]
            return <label className={`prodi-field${isLong ? ' prodi-field--full' : ''}`} key={key}>
              <span>{label}{key !== 'body' && <b> *</b>}</span>
              {options ? <select value={form[key] || ''} onChange={(event) => setForm((current) => ({ ...current, [key]: event.target.value }))}><option value="">Pilih {label.toLocaleLowerCase('id')}</option>{options.map((option) => <option key={option}>{option}</option>)}</select>
                : isLong ? <textarea rows="4" value={form[key] || ''} onChange={(event) => setForm((current) => ({ ...current, [key]: event.target.value }))} placeholder={`${label} (opsional)`} />
                  : <input required value={form[key] || ''} onChange={(event) => setForm((current) => ({ ...current, [key]: event.target.value }))} placeholder={`Masukkan ${label.toLocaleLowerCase('id')}`} />}
            </label>
          })}</div>
          {activePage === 'grades' && <div className="prodi-demo-note">Nilai akhir dihitung demo: tugas 30%, UTS 30%, UAS 40%. Nilai tidak resmi.</div>}
          {activePage === 'cases' && <div className="prodi-demo-note prodi-demo-note--warning">Rekomendasi SP hanya simulasi dan perlu persetujuan kampus. Keputusan final belum otomatis diproses.</div>}
          {activePage === 'requests' && <div className="prodi-demo-note">Nomor dan isi pengajuan hanya contoh; tidak dikirim ke sistem atau admin utama.</div>}
          <div className="prodi-modal-actions"><button type="button" className="prodi-button prodi-button--outline" onClick={() => setModal(null)}>Batal</button><button className="prodi-button prodi-button--primary" type="submit">Simpan demo</button></div>
        </form>
      </Modal>}

      {modal?.type === 'detail' && <Modal title="Detail data demonstrasi" wide onClose={() => setModal(null)}>
        <div className="prodi-detail-banner"><span className="prodi-avatar prodi-avatar--detail">{initials(modal.row.name || modal.row.title || modal.row.course || modal.row.subject)}</span><div><strong>{modal.row.name || modal.row.title || modal.row.course || modal.row.subject || modal.row.code}</strong><small>Informasi contoh · bukan data resmi</small></div>{modal.row.status && <Badge>{modal.row.status}</Badge>}</div>
          <div className="prodi-detail-grid">{Object.entries(modal.row).filter(([key]) => key !== 'id').map(([key, value]) => <div key={key}><small>{definitions[activePage]?.fields.find(([field]) => field === key)?.[1] || key}</small><strong>{String(value || '—')}</strong></div>)}</div>
        {activePage === 'students' && <div className="prodi-detail-extra"><h3>Ringkasan akademik demo</h3><p>Kehadiran {modal.row.attendance} · Status KRS {modal.row.krs}</p><div className="prodi-progress"><span style={{ width: modal.row.attendance }} /></div><small>Riwayat akademik ini hanya contoh dan tidak menggantikan data utama.</small><div className="prodi-history"><span>Semester sebelumnya <b>IPK 3.52</b></span><span>Semester berjalan <b>{modal.row.khs}</b></span><span>UKT <b>{modal.row.ukt}</b></span></div></div>}
        {activePage === 'cases' && <div className="prodi-timeline"><h3>Alur review kasus</h3><p>● Catatan Prodi <span>→</span> ● Rekomendasi <span>→</span> ○ Review final</p><button className="prodi-button prodi-button--outline" onClick={() => window.print()}>Cetak pratinjau</button></div>}
        {activePage === 'requests' && <div className="prodi-demo-note prodi-demo-note--warning">Pengajuan hanya merepresentasikan alur frontend. Tidak ada integrasi ke backend atau admin utama.</div>}
        <div className="prodi-modal-actions">
          <button className="prodi-button prodi-button--outline" onClick={() => openEdit(modal.row)}>Edit demo</button>
          <button className="prodi-button prodi-button--outline" onClick={() => removeRow(modal.row)}>Hapus demo</button>
          {activePage === 'requests' && modal.row.status !== 'Selesai' && <>
            <button className="prodi-button prodi-button--outline" onClick={() => updateStatus(modal.row, 'Perlu diperbaiki')}>Tandai perlu diperbaiki</button>
            <button className="prodi-button prodi-button--primary" onClick={() => updateStatus(modal.row, 'Selesai')}>Tandai selesai</button>
          </>}
          {activePage === 'cases' && <button className="prodi-button prodi-button--outline" onClick={() => simulateStage(modal.row)}>Usulkan tahap berikutnya</button>}
          {activePage === 'announcements' && <button className="prodi-button prodi-button--outline" onClick={() => updateStatus(modal.row, 'Berakhir')}>Arsipkan demo</button>}
        </div>
      </Modal>}

      {modal?.type === 'workflow' && <Modal title="Panduan alur demonstrasi" onClose={() => setModal(null)}>
        <div className="prodi-workflow-content"><p>{activePage === 'cases' ? 'Kasus akademik dan rekomendasi SP hanya simulasi. Keputusan final tetap berada di luar kewenangan Prodi.' : activePage === 'requests' ? 'Pengajuan koreksi hanya merekam alur frontend, bukan sinkronisasi dengan admin atau sistem inti.' : 'Pengumuman hanya pratinjau lokal. Tidak ada penerima yang mendapat notifikasi resmi.'}</p><div className="prodi-demo-note prodi-demo-note--warning">Pastikan kebijakan dan kewenangan resmi kampus diikuti di luar mode demonstrasi ini.</div></div>
      </Modal>}
      {toast && <div className="prodi-toast" role="status">{toast}</div>}
    </div>
  )
}

function StatePanel({ type, title, detail, action }) {
  return <div className={`prodi-state prodi-state--${type}`} role={type === 'error' ? 'alert' : type === 'loading' ? 'status' : undefined}>
    <span className="prodi-state-illustration" aria-hidden="true">{type === 'loading' ? <i /> : type === 'error' ? '!' : '⌕'}</span>
    <h3>{title}</h3><p>{detail}</p>{action && <button className="prodi-button prodi-button--outline" onClick={action}>{type === 'error' ? 'Coba lagi' : 'Tampilkan data demo'}</button>}
  </div>
}