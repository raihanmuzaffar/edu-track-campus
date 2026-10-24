// =============================================================================
// adminData.js — Static data & constants for the Admin Academic Dashboard
// =============================================================================

export const semesters = ['2024 Ganjil', '2024 Genap', '2025 Ganjil', '2025 Genap', '2026 Ganjil']
export const currentSemester = '2026 Ganjil'
export const classNames = [
  'TRKJ 1A', 'TRKJ 1B', 'TRKJ 1C', 'TRKJ 1D',
  'TRKJ 2A', 'TRKJ 2B', 'TRKJ 2C', 'TRKJ 2D',
  'TRKJ 3A', 'TRKJ 3B', 'TRKJ 3C', 'TRKJ 3D',
  'TRKJ 4A', 'TRKJ 4B', 'TRKJ 4C', 'TRKJ 4D',
]
export const program = 'Teknologi Rekayasa Komputer Jaringan (TRKJ)'

export const initialClasses = [
  { id: 'c26a', code: 'TRKJ 1A', year: '2026', semester: '2026 Ganjil', status: 'Aktif', packageId: 'p1' },
  { id: 'c26b', code: 'TRKJ 1B', year: '2026', semester: '2026 Ganjil', status: 'Aktif', packageId: '' },
  { id: 'c26c', code: 'TRKJ 1C', year: '2026', semester: '2026 Ganjil', status: 'Aktif', packageId: '' },
  { id: 'c26d', code: 'TRKJ 1D', year: '2026', semester: '2026 Ganjil', status: 'Aktif', packageId: '' },
  { id: 'c2a', code: 'TRKJ 2A', year: '2025', semester: '2026 Ganjil', status: 'Aktif', packageId: '' },
  { id: 'c2b', code: 'TRKJ 2B', year: '2025', semester: '2026 Ganjil', status: 'Aktif', packageId: '' },
  { id: 'c2c', code: 'TRKJ 2C', year: '2025', semester: '2026 Ganjil', status: 'Aktif', packageId: '' },
  { id: 'c2d', code: 'TRKJ 2D', year: '2025', semester: '2026 Ganjil', status: 'Aktif', packageId: '' },
  { id: 'c25a', code: 'TRKJ 3A', year: '2025', semester: '2026 Ganjil', status: 'Aktif', packageId: 'p3' },
  { id: 'c25b', code: 'TRKJ 3B', year: '2025', semester: '2026 Ganjil', status: 'Aktif', packageId: 'p3' },
  { id: 'c25c', code: 'TRKJ 3C', year: '2025', semester: '2026 Ganjil', status: 'Aktif', packageId: '' },
  { id: 'c25d', code: 'TRKJ 3D', year: '2025', semester: '2026 Ganjil', status: 'Aktif', packageId: '' },
  { id: 'c24a', code: 'TRKJ 4A', year: '2024', semester: '2026 Ganjil', status: 'Aktif', packageId: 'p5' },
  { id: 'c24b', code: 'TRKJ 4B', year: '2024', semester: '2026 Ganjil', status: 'Aktif', packageId: 'p5' },
  { id: 'c24c', code: 'TRKJ 4C', year: '2024', semester: '2026 Ganjil', status: 'Aktif', packageId: '' },
  { id: 'c24d', code: 'TRKJ 4D', year: '2024', semester: '2026 Ganjil', status: 'Aktif', packageId: '' },
]

export const initialStudents = [
  { id: 'm1', nim: '2401001', name: 'Aditya Pratama', classId: 'c24a', semester: '2026 Ganjil', status: 'Aktif' },
  { id: 'm2', nim: '2401002', name: 'Nadia Putri', classId: 'c24a', semester: '2026 Ganjil', status: 'Aktif' },
  { id: 'm3', nim: '2401003', name: 'Raka Mahendra', classId: 'c24b', semester: '2026 Ganjil', status: 'Aktif' },
  { id: 'm4', nim: '2501001', name: 'Salsabila Azzahra', classId: 'c25a', semester: '2026 Ganjil', status: 'Aktif' },
  { id: 'm5', nim: '2501002', name: 'Fajar Ramadhan', classId: 'c25a', semester: '2026 Ganjil', status: 'Cuti' },
  { id: 'm6', nim: '2501003', name: 'Intan Permata', classId: 'c25b', semester: '2026 Ganjil', status: 'Aktif' },
  { id: 'm7', nim: '2601001', name: 'Bima Saputra', classId: 'c26a', semester: '2026 Ganjil', status: 'Aktif' },
  { id: 'm8', nim: '2601002', name: 'Citra Lestari', classId: 'c26a', semester: '2026 Ganjil', status: 'Aktif' },
]

export const initialTeachers = [
  { id: 'd1', nidn: '0012038001', name: 'Dimas Santoso, M.Kom.', expertise: 'Jaringan komputer', status: 'Aktif' },
  { id: 'd2', nidn: '0015078502', name: 'Rina Kurnia, M.T.', expertise: 'Sistem operasi', status: 'Aktif' },
  { id: 'd3', nidn: '0021097903', name: 'Agus Setiawan, M.Kom.', expertise: 'Keamanan jaringan', status: 'Aktif' },
  { id: 'd4', nidn: '0018119004', name: 'Maya Lestari, M.T.', expertise: 'Pemrograman', status: 'Aktif' },
]

export const initialCourses = [
  { id: 'mk1', code: 'TRKJ101', name: 'Dasar Jaringan Komputer', credits: 3, term: 1, type: 'Wajib', status: 'Aktif' },
  { id: 'mk2', code: 'TRKJ103', name: 'Sistem Operasi Jaringan', credits: 3, term: 3, type: 'Wajib', status: 'Aktif' },
  { id: 'mk3', code: 'TRKJ105', name: 'Administrasi Server', credits: 4, term: 4, type: 'Wajib', status: 'Aktif' },
  { id: 'mk4', code: 'TRKJ107', name: 'Keamanan Jaringan', credits: 3, term: 4, type: 'Wajib', status: 'Aktif' },
  { id: 'mk5', code: 'TRKJ109', name: 'Praktik Infrastruktur Jaringan', credits: 4, term: 1, type: 'Praktik', status: 'Aktif' },
]

export const initialPackages = [
  { id: 'p1', name: 'Paket Semester 1 · TRKJ', term: 1, courseIds: ['mk1', 'mk5'], classIds: ['c26a'], status: 'Siap' },
  { id: 'p3', name: 'Paket Semester 3 · TRKJ', term: 3, courseIds: ['mk2'], classIds: ['c25a', 'c25b'], status: 'Siap' },
  { id: 'p5', name: 'Paket Semester 4 · TRKJ', term: 4, courseIds: ['mk3', 'mk4'], classIds: ['c24a', 'c24b'], status: 'Draf' },
]

export const initialSchedules = [
  { id: 'j1', semester: '2026 Ganjil', classId: 'c26a', courseId: 'mk1', teacherId: 'd1', day: 'Senin', start: '08:00', end: '10:30', room: 'Lab Jaringan 1' },
  { id: 'j2', semester: '2026 Ganjil', classId: 'c26a', courseId: 'mk5', teacherId: 'd3', day: 'Rabu', start: '13:00', end: '16:00', room: 'Lab Jaringan 2' },
  { id: 'j3', semester: '2026 Ganjil', classId: 'c25a', courseId: 'mk2', teacherId: 'd2', day: 'Selasa', start: '08:00', end: '10:30', room: 'Lab Jaringan 1' },
  { id: 'j4', semester: '2026 Ganjil', classId: 'c25b', courseId: 'mk2', teacherId: 'd2', day: 'Selasa', start: '09:00', end: '11:30', room: 'Lab Jaringan 1' },
  { id: 'j5', semester: '2026 Ganjil', classId: 'c24a', courseId: 'mk3', teacherId: 'd1', day: 'Kamis', start: '08:00', end: '11:00', room: 'Lab Server' },
  { id: 'j6', semester: '2026 Ganjil', classId: 'c24a', courseId: 'mk4', teacherId: 'd3', day: 'Jumat', start: '13:00', end: '15:30', room: 'Lab Keamanan' },
]

export const initialGrades = [
  { id: 'g1', studentId: 'm1', courseId: 'mk3', semester: '2026 Ganjil', score: 85, status: 'Lengkap' },
  { id: 'g2', studentId: 'm1', courseId: 'mk4', semester: '2026 Ganjil', score: 91, status: 'Lengkap' },
  { id: 'g3', studentId: 'm2', courseId: 'mk3', semester: '2026 Ganjil', score: 78, status: 'Lengkap' },
  { id: 'g4', studentId: 'm2', courseId: 'mk4', semester: '2026 Ganjil', score: null, status: 'Belum diisi' },
  { id: 'g5', studentId: 'm3', courseId: 'mk3', semester: '2026 Ganjil', score: 82, status: 'Lengkap' },
  { id: 'g6', studentId: 'm3', courseId: 'mk4', semester: '2026 Ganjil', score: 74, status: 'Lengkap' },
  { id: 'g7', studentId: 'm4', courseId: 'mk2', semester: '2026 Ganjil', score: 88, status: 'Lengkap' },
  { id: 'g8', studentId: 'm6', courseId: 'mk2', semester: '2026 Ganjil', score: null, status: 'Belum diisi' },
]

export const initialUkt = initialStudents.map((student, index) => ({
  id: `u${index + 1}`,
  studentId: student.id,
  semester: '2026 Ganjil',
  billed: 5000000,
  paid: [5000000, 3500000, 0, 5000000, 0, 2500000, 5000000, 0][index],
  due: '2026-09-30',
}))

export const initialAttendance = initialStudents.map((student, index) => ({
  id: `h${index + 1}`,
  studentId: student.id,
  courseId: 'mk3',
  semester: '2026 Ganjil',
  present: [12, 11, 8, 13, 5, 10, 9, 7][index],
  permit: 1,
  sick: 1,
  absent: [0, 1, 3, 0, 4, 2, 2, 3][index],
  meetings: 14,
}))

export const initialCases = [
  { id: 'sp1', studentId: 'm5', level: 'SP 1', reason: 'Ambang kehadiran demo terlampaui', status: 'Draf', followup: 'Verifikasi data wali kelas sebelum tindak lanjut.' },
  { id: 'sp2', studentId: 'm7', level: 'SP 1', reason: 'Kehadiran di bawah batas demo', status: 'Perlu diperiksa', followup: 'Menunggu pemeriksaan administrasi.' },
]

export const initialAnnouncements = [
  { id: 'a1', title: 'Jadwal praktikum semester ganjil', category: 'Akademik', start: '2026-10-20', end: '2026-11-15', status: 'Aktif', content: 'Periksa jadwal praktikum pada panel demo.' },
  { id: 'a2', title: 'Pemeriksaan data akademik', category: 'Administrasi', start: '2026-10-18', end: '2026-10-30', status: 'Aktif', content: 'Pastikan data akademik kelas telah diperiksa.' },
]

export const initialDocuments = [
  { id: 'doc1', type: 'KRS', studentId: 'm1', semester: '2026 Ganjil', status: 'Draf', date: '2026-10-01' },
  { id: 'doc2', type: 'KHS', studentId: 'm4', semester: '2026 Ganjil', status: 'Memerlukan perbaikan', date: '2026-10-02' },
  { id: 'doc3', type: 'Surat Peringatan', studentId: 'm5', semester: '2026 Ganjil', status: 'Draf', date: '2026-10-03' },
]

export const initialKrs = {
  c24a: 'Draf', c24b: 'Draf', c25a: 'Perlu diperbaiki', c25b: 'Draf', c26a: 'Siap dipublikasikan',
}

export const initialKhs = {
  m1: 'Siap dipublikasikan', m2: 'Perlu diperiksa', m3: 'Siap dipublikasikan',
  m4: 'Siap dipublikasikan', m5: 'Perlu diperiksa', m6: 'Perlu diperiksa',
  m7: 'Perlu diperiksa', m8: 'Perlu diperiksa',
}

export const menuGroups = [
  { title: 'RINGKASAN', items: [['dashboard', 'Dashboard', 'grid']] },
  { title: 'DATA AKADEMIK', items: [['students', 'Data Mahasiswa', 'users'], ['classes', 'Kelas dan Data Akademik', 'grid'], ['teachers', 'Dosen', 'users'], ['courses', 'Mata Kuliah dan Paket', 'book'], ['schedules', 'Jadwal Kuliah dan Ruang', 'clock']] },
  { title: 'PROSES AKADEMIK', items: [['krs', 'KRS Paket', 'file'], ['grades', 'Nilai Mahasiswa', 'chart'], ['khs', 'KHS dan Publikasi', 'file'], ['ukt', 'UKT dan Tunggakan', 'wallet'], ['attendance', 'Kehadiran dan SP', 'check'], ['documents', 'Dokumen Akademik', 'file']] },
  { title: 'ADMINISTRASI', items: [['announcements', 'Pengumuman', 'megaphone'], ['reports', 'Laporan dan Rekapitulasi', 'chart'], ['activities', 'Riwayat Aktivitas', 'clock'], ['settings', 'Pengaturan Dashboard', 'settings']] },
]

export const filterLabels = {
  class: 'kelas', code: 'kelas', semester: 'semester',
  status: 'status', category: 'kategori', day: 'hari',
}

export const titles = Object.fromEntries(
  menuGroups.flatMap((group) => group.items.map(([key, label]) => [key, label]))
)
