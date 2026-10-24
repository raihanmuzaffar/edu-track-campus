// =============================================================================
// adminUtils.js — Helper / pure functions for the Admin Academic Dashboard
// =============================================================================

/** Format angka sebagai mata uang Rupiah */
export const fmtMoney = (n) =>
  new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(n)

/** Format string tanggal ISO (YYYY-MM-DD) ke tanggal lokal Indonesia */
export const fmtDate = (value) =>
  value
    ? new Intl.DateTimeFormat('id-ID', { day: 'numeric', month: 'short', year: 'numeric' }).format(
        new Date(`${value}T00:00:00`)
      )
    : '—'

/** Generate ID unik untuk data demo */
export const id = () => `demo-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`

/**
 * Cari nama kelas berdasarkan classId.
 * Nama fungsi diubah dari `className` menjadi `getClassName` agar tidak
 * konflik dengan prop `className` milik React.
 */
export const getClassName = (rows, classId) =>
  rows.find((row) => row.id === classId)?.code || 'Kelas tidak tersedia'

/** Cari nama mahasiswa berdasarkan studentId */
export const studentName = (rows, studentId) =>
  rows.find((row) => row.id === studentId)?.name || 'Mahasiswa tidak tersedia'

/** Cari nama mata kuliah berdasarkan courseId */
export const courseName = (rows, courseId) =>
  rows.find((row) => row.id === courseId)?.name || 'Mata kuliah tidak tersedia'

/** Cari nama dosen berdasarkan teacherId */
export const teacherName = (rows, teacherId) =>
  rows.find((row) => row.id === teacherId)?.name || 'Belum ditetapkan'

/**
 * Konversi nilai angka (0–100) ke huruf mutu dan bobot.
 * Mengembalikan tuple [huruf, bobot].
 */
export const letterGrade = (score) =>
  score >= 85 ? ['A', 4]
  : score >= 80 ? ['AB', 3.5]
  : score >= 75 ? ['B', 3]
  : score >= 70 ? ['BC', 2.5]
  : score >= 65 ? ['C', 2]
  : score >= 50 ? ['D', 1]
  : ['E', 0]
