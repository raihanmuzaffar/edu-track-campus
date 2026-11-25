import BrandLogo from '../components/BrandLogo'
import { useCallback, useEffect, useMemo, useState } from 'react'
import { useNavigate, useOutletContext } from 'react-router-dom'
import api, { endSession, getAllRecords, getApiError, getApiValidationField } from '../services/api'
import ProdiSidebar from '../components/ProdiSidebar'
import { prodiNavigation } from '../constants/prodiNavigation'
import './ProdiDashboard.css'

const emptyRows = []

const statusTone = (value = '') => {
  const normalized = String(value).toLocaleLowerCase('id')
  if (normalized.includes('aktif') || normalized.includes('aman') || normalized.includes('hadir') || normalized.includes('terbit') || normalized.includes('disetujui') || normalized.includes('lunas') || normalized === 'a') return 'success'
  if (normalized.includes('perhatian') || normalized.includes('penting') || normalized.includes('menunggu') || normalized.includes('terjadwal') || normalized.includes('izin') || normalized.includes('sebagian') || normalized === 'b') return 'warning'
  if (normalized.includes('tolak') || normalized.includes('alpa') || normalized.includes('tidak hadir') || normalized.includes('belum') || normalized === 'd' || normalized === 'e') return 'danger'
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
  if (key === 'bill' || key === 'paid' || key === 'due') {
    if (typeof value === 'number') {
      return `Rp ${value.toLocaleString('id-ID')}`
    }
  }
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
          <div><span className="prodi-eyebrow">SISTEM AKADEMIK</span><h2 id="prodi-modal-title">{title}</h2></div>
          <button className="prodi-icon-button" onClick={onClose} aria-label="Tutup dialog">×</button>
        </header>
        <div className="prodi-modal-body">{children}</div>
      </section>
    </div>
  )
}

export default function ProdiDashboard() {
  const navigate = useNavigate()
  const { user } = useOutletContext()
  const [activePage, setActivePage] = useState('overview')
  const [students, setStudents] = useState([])
  const [teachers, setTeachers] = useState([])
  const [classes, setClasses] = useState([])
  const [courses, setCourses] = useState([])
  const [schedule, setSchedule] = useState([])
  const [grades, setGrades] = useState([])
  const [attendances, setAttendances] = useState([])
  const [ukt, setUkt] = useState([])
  const [announcements, setAnnouncements] = useState([])
  const [cases, setCases] = useState([])
  const [krs, setKrs] = useState([])
  const [packages, setPackages] = useState([])
  const [activePeriod, setActivePeriod] = useState(null)
  const [isLoading, setIsLoading] = useState(true)
  const [loadError, setLoadError] = useState('')
  const [unavailablePages, setUnavailablePages] = useState([])

  const [khs, setKhs] = useState([])
  const [reports] = useState([])
  const [requests] = useState([])

  const [search, setSearch] = useState('')
  const [filters, setFilters] = useState({})
  const [sort, setSort] = useState({ key: '', direction: 'asc' })
  const [page, setPage] = useState(1)
  const [pageSize, setPageSize] = useState(5)
  const [modal, setModal] = useState(null)
  const [form, setForm] = useState({})
  const [formErrors, setFormErrors] = useState({})
  const [toast, setToast] = useState('')
  const [openMenu, setOpenMenu] = useState(null)
  const [classView, setClassView] = useState('table')
  const semesterOptions = useMemo(() => [...new Set([
    activePeriod?.year && activePeriod?.semester ? `${activePeriod.year} ${activePeriod.semester}` : '',
    ...classes.map((classRecord) => classRecord.semester),
    ...schedule.map((scheduleRecord) => scheduleRecord.semester),
  ].filter(Boolean))], [activePeriod, classes, schedule])
  const academicYears = useMemo(
    () => [...new Set(semesterOptions.map((semester) => semester.split(' ')[0]))],
    [semesterOptions],
  )
  const definitions = useMemo(() => ({
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
      ],
      fields: [
        ['name', 'Nama lengkap'],
        ['email', 'Email', 'email'],
        ['password', 'Password', 'password'],
        ['nim', 'NIM (Opsional)'],
        ['program', 'Program studi'],
      ],
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
        ['packageName', 'Mata Kuliah'],
        ['lecturer', 'Dosen Pengampu'],
        ['semester', 'Semester'],
        ['day', 'Hari'],
        ['time', 'Waktu'],
        ['room', 'Ruangan'],
        ['status', 'Status'],
      ],
      fields: [
        ['className', 'Nama Kelas'],
        ['courseId', 'Mata Kuliah', 'select', courses.map((c) => [c.id, `${c.code ? `${c.code} - ` : ''}${c.name}`])],
        ['dosenId', 'Dosen Pengampu', 'select', teachers.map((t) => [t.id, t.name])],
        ['day', 'Hari', 'select', ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu']],
        ['startTime', 'Jam mulai', 'time'],
        ['endTime', 'Jam selesai', 'time'],
        ['room', 'Ruangan'],
        ['year', 'Tahun akademik'],
        ['term', 'Semester', 'select', ['Ganjil', 'Genap']],
        ['packageId', 'Paket semester', 'select', packages.map((entry) => [entry.id, entry.name])],
        ['status', 'Status kelas', 'select', ['Aktif', 'Nonaktif']],
      ],
      options: {
        day: ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'],
        semester: ['Ganjil', 'Genap'],
        status: ['Aktif', 'Nonaktif'],
      },
    },
    packages: {
      title: 'Paket Mata Kuliah',
      singular: 'paket',
      description: 'Paket mata kuliah dan relasi kelas dari backend.',
      search: 'Cari nama paket...',
      searchable: ['name', 'courses', 'classes'],
      filters: [
        { key: 'semester', label: 'Semua semester' },
        { key: 'status', label: 'Semua status' },
      ],
      columns: [
        ['name', 'Nama paket'],
        ['term', 'Semester'],
        ['courses', 'Mata kuliah'],
        ['classes', 'Kelas'],
        ['status', 'Status'],
      ],
      fields: [
        ['name', 'Nama paket'],
        ['term', 'Semester paket', 'number'],
        ['status', 'Status', 'select', ['Draf', 'Siap']],
        ['courseIds', 'Mata kuliah paket', 'multiselect', courses.map((c) => [c.id, `${c.code} · ${c.name}`])],
        ['classIds', 'Kelas terkait', 'multiselect', classes.map((classRecord) => [classRecord.id, classRecord.className])],
      ],
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
        ['semester', 'Semester', 'select', semesterOptions],
        ['classId', 'Kelas', 'select', classes.map((classRecord) => [classRecord.id, classRecord.className])],
        ['day', 'Hari', 'select', ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu']],
        ['start_time', 'Jam mulai', 'time'],
        ['end_time', 'Jam selesai', 'time'],
        ['room', 'Ruang'],
      ],
      options: {
        semester: semesterOptions,
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
        ['course', 'Mata kuliah'],
        ['status', 'Status enrollment'],
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
        semester: ['2026 Ganjil', '2026 Genap'],
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
        semester: ['2026 Ganjil', '2026 Genap'],
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
        semester: ['2026 Ganjil', '2026 Genap'],
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
        ['status', 'Status'],
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
        semester: ['2026 Ganjil', '2026 Genap'],
        status: ['Aman', 'Perlu perhatian'],
      },
    },
    ukt: {
      title: 'Pemantauan UKT',
      singular: 'data UKT',
      description: 'Pemantauan tunggakan UKT mahasiswa TRKJ dan tindak lanjut pembayaran.',
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
        ['paid', 'Dibayar'],
        ['due', 'Tunggakan'],
        ['dueDate', 'Jatuh tempo'],
        ['status', 'Status'],
      ],
      fields: [
        ['studentId', 'Mahasiswa', 'select', students.map((s) => [s.id, s.name])],
        ['semester', 'Tahun akademik', 'select', academicYears],
        ['bill', 'Nominal tagihan (Rp)', 'number'],
        ['paid', 'Nominal dibayar (Rp)', 'number'],
        ['due_date', 'Tanggal jatuh tempo', 'date'],
      ],
      options: {
        semester: ['2026 Ganjil', '2026 Genap'],
        status: ['Lunas', 'Belum lunas'],
      },
    },
    cases: {
      title: 'Peringatan & Kasus Akademik',
      singular: 'kasus akademik',
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
        ['studentId', 'Mahasiswa', 'select', students.map((s) => [s.id, s.name])],
        ['level', 'Jenjang SP', 'select', ['SP 1', 'SP 2', 'SP 3']],
        ['reason', 'Alasan / Catatan'],
        ['followup', 'Tindak lanjut'],
        ['status', 'Status', 'select', ['Draf', 'Diajukan', 'Perlu diperiksa', 'Diterbitkan (simulasi)', 'Ditutup']],
      ],
      options: {
        level: ['SP 1', 'SP 2', 'SP 3'],
        status: ['Draf', 'Diajukan', 'Perlu diperiksa', 'Diterbitkan (simulasi)', 'Ditutup'],
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
        ['date', 'Tanggal'],
        ['end_date', 'Berakhir'],
        ['status', 'Status'],
      ],
      fields: [
        ['title', 'Judul pengumuman'],
        ['content', 'Isi pengumuman', 'textarea'],
        ['category', 'Kategori', 'select', ['Akademik', 'Kegiatan', 'Administrasi']],
        ['start_date', 'Tanggal mulai', 'date'],
        ['end_date', 'Tanggal akhir', 'date'],
        ['status', 'Status', 'select', ['Draf', 'Aktif', 'Berakhir']],
      ],
      options: {
        category: ['Akademik', 'Kegiatan', 'Administrasi'],
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
        semester: ['2026 Ganjil', '2026 Genap'],
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
  }), [students, teachers, courses, classes, packages, semesterOptions, academicYears])

  const fetchAll = useCallback(async () => {
    setIsLoading(true)
    setLoadError('')
    const isKaprodi = user?.role === 'kaprodi'
    setUnavailablePages(isKaprodi ? ['classes', 'packages', 'schedule', 'announcements'] : [])
    try {
      const [
        rawUsers,
        rawCourses,
        rawClasses,
        rawGrades,
        rawAttendances,
        rawUkt,
        rawAnnouncements,
        rawCases,
        rawKrs,
        rawSchedules,
        rawPackages,
        rawKhs,
        periodResponse,
      ] = await Promise.all([
        getAllRecords('/admin/users'),
        isKaprodi ? Promise.resolve(null) : getAllRecords('/courses/list'),
        isKaprodi ? Promise.resolve(null) : getAllRecords('/classes/list'),
        getAllRecords('/admin/grades/list'),
        getAllRecords('/admin/attendances/list'),
        getAllRecords('/admin/ukt/list'),
        isKaprodi ? Promise.resolve(null) : getAllRecords('/admin/announcements/list'),
        getAllRecords('/admin/cases/list'),
        getAllRecords('/admin/krs/list'),
        isKaprodi ? Promise.resolve(null) : getAllRecords('/admin/schedules/list'),
        isKaprodi ? Promise.resolve(null) : getAllRecords('/admin/packages/list'),
        getAllRecords('/admin/khs/list'),
        isKaprodi ? Promise.resolve(null) : api.get('/admin/academic/period-reconciliation'),
      ])

      const rawCoursesData = rawCourses || []
      const rawClassesData = rawClasses || []
      const rawAnnouncementsData = rawAnnouncements || []
      const rawSchedulesData = rawSchedules || []
      const rawPackagesData = rawPackages || []
      const period = periodResponse?.data?.data?.active_period
      setActivePeriod(period || null)
      const classById = new Map(rawClassesData.map((classRecord) => [classRecord.id, classRecord]))
      const activeEnrollments = rawKrs
        .filter((entry) => String(entry.status).toLowerCase() === 'active')
        .sort((left, right) => new Date(right.updated_at) - new Date(left.updated_at))
      const enrollmentByStudent = new Map()
      activeEnrollments.forEach((entry) => {
        if (!enrollmentByStudent.has(entry.mahasiswa_id)) enrollmentByStudent.set(entry.mahasiswa_id, entry)
      })

      const mappedStudents = rawUsers
        .filter((u) => u.role === 'mahasiswa')
        .map((u) => {
          const enrollment = enrollmentByStudent.get(u.id)
          const classRecord = classById.get(enrollment?.class_id)
          return {
            id: u.id,
            nim: u.nim || '—',
            name: u.name,
            email: u.email,
            program: u.program_studi || '',
            className: classRecord?.name || '—',
            semester: classRecord?.year && classRecord?.semester ? `${classRecord.year} ${classRecord.semester}` : '—',
            statusAcademic: enrollment ? 'Aktif' : 'Belum terdaftar',
            attendance: '—',
            ukt: '—',
            krs: enrollment?.status || '—',
            khs: '—',
          }
        })
      setStudents(mappedStudents)

      setTeachers(rawUsers.filter((u) => u.role === 'dosen').map((u) => ({
        id: u.id, name: u.name, email: u.email, nidn: u.nidn || '—',
      })))

      setPackages(rawPackagesData.map((entry) => ({
        id: entry.id,
        name: entry.name,
        term: entry.term,
        status: entry.status,
        courseIds: entry.courses?.map((course) => course.id) || [],
        courses: entry.courses?.map((course) => course.name).join(', ') || '—',
        classIds: entry.classes?.map((classRecord) => classRecord.id) || [],
        classes: entry.classes?.map((classRecord) => classRecord.name).join(', ') || '—',
      })))

      const mappedClasses = rawClassesData.map((c) => ({
        id: c.id,
        className: c.name,
        semester: c.year && c.semester ? `${c.year} ${c.semester}` : '—',
        totalStudents: rawKrs.filter((entry) => entry.class_id === c.id && String(entry.status).toLowerCase() === 'active').length,
        packageName: rawPackagesData.find((entry) => entry.id === c.package_id)?.name || '—',
        lecturer: c.dosen?.name || '—',
        status: c.status || '—',
        day: c.day || '—',
        time: `${c.start_time || ''} - ${c.end_time || ''}`.trim() || '—',
        room: c.room || '—',
        courseId: c.course_id,
        dosenId: c.dosen_id,
        year: c.year || '',
        term: c.semester || '',
        startTime: c.start_time ? String(c.start_time).slice(0, 5) : '',
        endTime: c.end_time ? String(c.end_time).slice(0, 5) : '',
        packageId: c.package_id || '',
      }))
      setClasses(mappedClasses)

      setCourses(rawCoursesData.map((c) => ({
        id: c.id,
        code: c.code,
        name: c.name,
        credits: c.sks,
        term: c.semester,
        semester: String(c.semester || ''),
      })))

      setGrades(rawGrades.map((g) => ({
        id: g.id,
        nim: g.mahasiswa?.nim || '—',
        name: g.mahasiswa?.name || '—',
        course: g.class?.course?.name || '—',
        semester: g.class?.year && g.class?.semester ? `${g.class.year} ${g.class.semester}` : '—',
        score: Number(g.score),
        letter: g.letter || '—',
        status: 'Tersimpan',
      })))

      setAttendances(rawAttendances.map((a) => {
        return {
          id: a.id,
          date: a.date ? String(a.date).slice(0, 10) : '—',
          nim: a.mahasiswa?.nim || '—',
          name: a.mahasiswa?.name || '—',
          course: a.class?.course?.name || '—',
          className: a.class?.name || '—',
          semester: a.class?.year && a.class?.semester ? `${a.class.year} ${a.class.semester}` : '—',
          status: a.status || '—',
        }
      }))

      setUkt(rawUkt.map((item) => {
        const billed = Number(item.billed)
        const paid = Number(item.paid)
        return {
          id: item.id,
          studentId: item.student_id,
          nim: item.student?.nim || '—',
          name: item.student?.name || '—',
          className: mappedStudents.find((student) => student.id === item.student_id)?.className || '—',
          semester: item.semester || '—',
          bill: billed,
          paid: paid,
          due: billed - paid,
          status: paid >= billed ? 'Lunas' : 'Belum lunas',
          note: '',
          due_date: item.due_date ? String(item.due_date).slice(0, 10) : '',
          dueDate: item.due_date ? String(item.due_date).slice(0, 10) : '—',
        }
      }))

      setAnnouncements(rawAnnouncementsData.map((item) => {
        const start = item.start_date ? String(item.start_date).slice(0, 10) : ''
        const end = item.end_date ? String(item.end_date).slice(0, 10) : ''
        return {
          id: item.id,
          title: item.title,
          category: item.category,
          date: start || '-',
          end_date: end,
          status: item.status,
          body: item.content || '',
          content: item.content || '',
        }
      }))

      setCases(rawCases.map((item) => ({
        id: item.id,
        studentId: item.student_id,
        nim: item.student?.nim || '—',
        name: item.student?.name || '—',
        className: mappedStudents.find((student) => student.id === item.student_id)?.className || '—',
        type: item.level,
        level: item.level,
        note: item.reason,
        reason: item.reason,
        date: item.created_at ? String(item.created_at).slice(0, 10) : '—',
        status: item.status,
        recommendation: item.followup,
        followup: item.followup,
      })))

      setKrs(rawKrs.map((item) => ({
        id: item.id,
        nim: item.mahasiswa?.nim || '—',
        name: item.mahasiswa?.name || '—',
        className: item.class?.name || '—',
        course: item.class?.course?.name || '—',
        semester: item.class?.year && item.class?.semester ? `${item.class.year} ${item.class.semester}` : '—',
        status: String(item.status).toLowerCase() === 'active' ? 'Aktif' : item.status,
      })))

      setSchedule(rawSchedulesData.map((item) => ({
        id: item.id,
        classId: item.class_id,
        courseId: item.course_id,
        teacherId: item.teacher_id,
        course: item.course?.name || '—',
        className: item.class?.name || '—',
        semester: item.semester || '—',
        lecturer: item.teacher?.name || '—',
        day: item.day || '—',
        time: `${item.start_time || ''} - ${item.end_time || ''}`.trim() || '—',
        start_time: item.start_time ? String(item.start_time).slice(0, 5) : '',
        end_time: item.end_time ? String(item.end_time).slice(0, 5) : '',
        room: item.room || '—',
        status: 'Tersimpan',
      })))
      setKhs(rawKhs.map((entry) => {
        const student = rawUsers.find((candidate) => candidate.id === entry.student_id)
        const enrollment = activeEnrollments.find((candidate) => candidate.mahasiswa_id === entry.student_id)
        const classRecord = classById.get(enrollment?.class_id)
        return {
          id: entry.id,
          nim: student?.nim || '—',
          name: student?.name || '—',
          className: classRecord?.name || '—',
          semester: entry.semester,
          credits: '—',
          ips: '—',
          ipk: '—',
          status: entry.status,
          publication: entry.status,
        }
      }))
      return true
    } catch (error) {
      const message = getApiError(error, 'Gagal memuat data backend')
      setLoadError(message)
      return false
    } finally {
      setIsLoading(false)
    }
  }, [user?.role])

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect -- Memulai pemuatan data dari API saat dashboard dibuka.
    fetchAll()
  }, [fetchAll])

  function getRowsForPage(targetPage) {
    switch (targetPage) {
      case 'students':
        return students
      case 'classes':
        return classes
      case 'packages':
        return packages
      case 'schedule':
        return schedule
      case 'grades':
        return grades
      case 'attendance':
        return attendances
      case 'krs':
        return krs
      case 'khs':
        return khs
      case 'ukt':
        return ukt
      case 'cases':
        return cases
      case 'announcements':
        return announcements
      case 'reports':
        return reports
      case 'requests':
        return requests
      default:
        return emptyRows
    }
  }

  const pageDefinition = definitions[activePage]
  const rows = getRowsForPage(activePage)
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

  const handleLogout = async () => {
    const error = await endSession()
    if (error) console.error('Gagal mengakhiri sesi di server:', error)
    navigate('/')
  }

  function notify(message) {
    setToast(message)
    window.setTimeout(() => setToast(''), 2800)
  }

  function handleNavigate(id) {
    setActivePage(id)
    setSearch('')
    setFilters({})
    setSort({ key: '', direction: 'asc' })
    setPage(1)
    setOpenMenu(null)
    if (id !== 'classes') setClassView('table')
  }

  function openCreate() {
    if (['krs', 'khs', 'grades', 'attendance'].includes(activePage)) {
      notify('Anda tidak memiliki akses untuk mengubah data ini')
      return
    }
    setForm({
      courseId: courses[0]?.id ? String(courses[0].id) : '',
      dosenId: teachers[0]?.id ? String(teachers[0].id) : '',
      studentId: students[0]?.id ? String(students[0].id) : '',
      classId: classes[0]?.id ? String(classes[0].id) : '',
      teacherId: teachers[0]?.id ? String(teachers[0].id) : '',
      semester: semesterOptions[0] || '',
      term: '1',
      courseIds: [],
      classIds: [],
      status: activePage === 'packages' ? 'Draf' : 'Aktif',
    })
    setFormErrors({})
    setModal({ type: 'form', mode: 'create' })
  }

  function openEdit(row) {
    if (['krs', 'khs', 'grades', 'attendance'].includes(activePage)) {
      notify('Anda tidak memiliki akses untuk mengubah data ini')
      return
    }
    const studentMatch = students.find((s) => s.name === row.name)
    setForm({
      ...row,
      studentId: row.studentId || row.student_id || studentMatch?.id || '',
      courseId: row.courseId || row.course_id || '',
      dosenId: row.dosenId || row.dosen_id || '',
      teacherId: row.teacherId || row.teacher_id || '',
      classId: row.classId || row.class_id || '',
      courseIds: row.courseIds || [],
      classIds: row.classIds || [],
    })
    setFormErrors({})
    setModal({ type: 'form', mode: 'edit', row })
  }

  async function saveForm(event) {
    event.preventDefault()
    setFormErrors({})

    if (['krs', 'khs', 'grades', 'attendance'].includes(activePage)) {
      notify('Anda tidak memiliki akses untuk mengubah data ini')
      return
    }

    const optionalKeys = ['nim', 'program', 'packageId']
    const missing = pageDefinition.fields.find(([key]) => (
      !(modal.mode === 'edit' && key === 'password') &&
      !optionalKeys.includes(key) &&
      (Array.isArray(form[key]) ? form[key].length === 0 : !String(form[key] ?? '').trim())
    ))
    if (missing) {
      notify(`${missing[1]} wajib diisi.`)
      return
    }

    try {
      if (activePage === 'students') {
        const payload = {
          name: form.name,
          email: form.email,
          role: 'mahasiswa',
          nim: form.nim || '',
          program_studi: form.program || '',
        }
        if (modal.mode === 'create') {
          payload.password = form.password
          await api.post('/admin/users/create', payload)
        } else {
          if (form.password) payload.password = form.password
          await api.put(`/admin/users/update?id=${modal.row.id}`, payload)
        }
      } else if (activePage === 'classes') {
        if (!form.courseId) {
          notify('Mata Kuliah wajib dipilih.')
          return
        }
        if (!form.dosenId) {
          notify('Dosen Pengampu wajib dipilih.')
          return
        }
        const payload = {
          name: form.className || form.name,
          course_id: Number(form.courseId),
          dosen_id: Number(form.dosenId),
          day: form.day || 'Senin',
          start_time: form.startTime,
          end_time: form.endTime,
          room: form.room,
          year: form.year || '',
          semester: form.term,
          package_id: form.packageId ? Number(form.packageId) : null,
          status: form.status,
        }
        if (modal.mode === 'create') {
          await api.post('/classes', payload)
        } else {
          await api.put(`/classes/update?id=${modal.row.id}`, payload)
        }
      } else if (activePage === 'ukt') {
        if (!form.studentId) {
          notify('Mahasiswa wajib dipilih.')
          return
        }
        const billed = Number(String(form.bill || form.billed || 0).replace(/[^0-9.-]+/g, '')) || 0
        const paid = Number(String(form.paid || 0).replace(/[^0-9.-]+/g, '')) || 0
        const payload = {
          student_id: Number(form.studentId),
          semester: form.semester,
          billed,
          paid,
          due_date: form.due_date,
        }
        if (modal.mode === 'create') {
          await api.post('/admin/ukt', payload)
        } else {
          await api.put(`/admin/ukt/update?id=${modal.row.id}`, payload)
        }
      } else if (activePage === 'announcements') {
        const payload = {
          title: form.title,
          category: form.category,
          content: form.content,
          start_date: form.start_date,
          end_date: form.end_date,
          status: form.status,
        }
        if (modal.mode === 'create') {
          await api.post('/admin/announcements', payload)
        } else {
          await api.put(`/admin/announcements/update?id=${modal.row.id}`, payload)
        }
      } else if (activePage === 'cases') {
        if (!form.studentId) {
          notify('Mahasiswa wajib dipilih.')
          return
        }
        const payload = {
          student_id: Number(form.studentId),
          level: form.level,
          reason: form.reason,
          followup: form.followup,
          status: form.status,
        }
        if (modal.mode === 'create') {
          await api.post('/admin/cases', payload)
        } else {
          await api.put(`/admin/cases/update?id=${modal.row.id}`, payload)
        }
      } else if (activePage === 'packages') {
        const payload = {
          name: form.name,
          term: Number(form.term),
          status: form.status,
          course_ids: form.courseIds.map(Number),
          class_ids: form.classIds.map(Number),
        }
        if (modal.mode === 'create') {
          await api.post('/admin/packages', payload)
        } else {
          await api.put(`/admin/packages/update?id=${modal.row.id}`, payload)
        }
      } else if (activePage === 'schedule') {
        const classRecord = classes.find((entry) => String(entry.id) === String(form.classId))
        if (!classRecord) {
          notify('Kelas yang dipilih tidak ditemukan.')
          return
        }
        const payload = {
          semester: form.semester,
          class_id: Number(form.classId),
          course_id: Number(classRecord.courseId),
          teacher_id: Number(classRecord.dosenId),
          day: form.day,
          start_time: form.start_time,
          end_time: form.end_time,
          room: form.room,
        }
        if (modal.mode === 'create') {
          await api.post('/admin/schedules', payload)
        } else {
          await api.put(`/admin/schedules/update?id=${modal.row.id}`, payload)
        }
      } else {
        notify('Modul ini belum mendukung penyimpanan ke server.')
        return
      }

      await fetchAll()
      setModal(null)
      notify(`${pageDefinition.singular} berhasil ${modal.mode === 'edit' ? 'diperbarui' : 'ditambahkan'}.`)
    } catch (error) {
      console.error('Gagal menyimpan data:', error)
      const message = getApiError(error)
      const fieldError = getApiValidationField(error, {
        name: 'name', email: 'email', password: 'password', nim: 'nim',
        program_studi: 'program', code: 'code', sks: 'credits',
        year: 'year', semester: activePage === 'classes' ? 'term' : 'semester',
        term: 'term',
        course_id: 'courseId', dosen_id: 'dosenId', package_id: 'packageId',
        course_ids: 'courseIds', class_ids: 'classIds', day: 'day',
        start_time: activePage === 'schedule' ? 'start_time' : 'startTime',
        end_time: activePage === 'schedule' ? 'end_time' : 'endTime',
        room: 'room', student_id: 'studentId', billed: 'bill',
        paid: 'paid', due_date: 'due_date', title: 'title',
        category: 'category', content: 'content', start_date: 'start_date',
        end_date: 'end_date', level: 'level', reason: 'reason',
        followup: 'followup', status: 'status',
      })
      if (fieldError) setFormErrors((current) => ({ ...current, [fieldError.field]: fieldError.message }))
      else setFormErrors((current) => ({ ...current, _form: message }))
      notify(`Gagal menyimpan data: ${message}`)
    }
  }

  async function removeRow(row) {
    if (['krs', 'khs', 'grades', 'attendance'].includes(activePage)) {
      notify('Anda tidak memiliki akses untuk mengubah data ini')
      return
    }

    const approved = window.confirm(`Hapus ${pageDefinition.singular} "${row.name || row.title || row.subject || row.course || row.code || ''}"?`)
    if (!approved) return

    try {
      if (activePage === 'students') {
        await api.delete(`/admin/users/delete?id=${row.id}`)
      } else if (activePage === 'classes') {
        await api.delete(`/classes/delete?id=${row.id}`)
      } else if (activePage === 'ukt') {
        await api.delete(`/admin/ukt/delete?id=${row.id}`)
      } else if (activePage === 'announcements') {
        await api.delete(`/admin/announcements/delete?id=${row.id}`)
      } else if (activePage === 'cases') {
        await api.delete(`/admin/cases/delete?id=${row.id}`)
      } else if (activePage === 'packages') {
        await api.delete(`/admin/packages/delete?id=${row.id}`)
      } else if (activePage === 'schedule') {
        await api.delete(`/admin/schedules/delete?id=${row.id}`)
      } else {
        notify('Modul ini belum mendukung penghapusan dari server.')
        return
      }

      await fetchAll()
      setModal(null)
      notify(`${pageDefinition.singular} berhasil dihapus dari server.`)
    } catch (error) {
      console.error('Gagal menghapus data:', error)
      notify(`Gagal menghapus data: ${error?.response?.data?.message || error?.message || 'Terjadi kesalahan'}`)
    }
  }

  async function updateStatus(row, status) {
    if (activePage === 'announcements') {
      try {
        await api.put(`/admin/announcements/update?id=${row.id}`, {
          title: row.title,
          category: row.category,
          content: row.body || '',
          start_date: row.date,
          end_date: row.end_date,
          status,
        })
        await fetchAll()
        setModal(null)
        notify(`Status pengumuman diubah menjadi ${status}.`)
      } catch (err) {
        console.error(err)
        notify('Gagal mengubah status pengumuman.')
      }
      return
    }
    notify(`Status diubah menjadi: ${status}.`)
    setModal(null)
  }

  function openDetail(row) {
    setModal({ type: 'detail', row })
  }

  function exportCsv(target = activePage, exportRows = sortedRows) {
    const exportDefinition = definitions[target]
    const columns = exportDefinition.columns
    const rowsToExport = exportRows || getRowsForPage(target)
    const csvRows = [
      columns.map(([, label]) => label),
      ...rowsToExport.map((row) => columns.map(([key]) => String(row[key] ?? ''))),
    ]
    const csv = `\uFEFF${csvRows.map((line) => line.map((cell) => `"${cell.replaceAll('"', '""')}"`).join(',')).join('\r\n')}`
    const url = URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8' }))
    const anchor = document.createElement('a')
    anchor.href = url
    anchor.download = `data-${target}.csv`
    anchor.click()
    URL.revokeObjectURL(url)
    notify('CSV data berhasil disiapkan.')
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

  async function simulateStage(row) {
    const stages = ['Audit awal', 'SP 1', 'SP 2', 'SP 3']
    const currentIndex = stages.indexOf(row.level || row.type)
    if (currentIndex < 0 || currentIndex === stages.length - 1) {
      notify('Tahap rekomendasi terakhir telah tercapai.')
      return
    }
    const nextStage = stages[currentIndex + 1]
    if (!window.confirm(`Ubah level rekomendasi menjadi ${nextStage}?`)) return
    try {
      await api.put(`/admin/cases/update?id=${row.id}`, {
        student_id: Number(row.studentId),
        level: nextStage,
        reason: row.reason || row.note || '',
        followup: nextStage,
        status: row.status,
      })
      await fetchAll()
      setModal(null)
      notify(`Rekomendasi ${nextStage} berhasil diajukan ke server.`)
    } catch (err) {
      console.error(err)
      notify('Gagal memperbarui status kasus.')
    }
  }

  function renderTable() {
    if (!visibleRows.length) {
      return (
        <StatePanel
          type="empty"
          title="Belum ada data"
          detail="Data dari server masih kosong atau tidak cocok dengan filter pencarian."
        />
      )
    }

    const isReadOnly = ['krs', 'khs', 'grades', 'attendance'].includes(activePage)

    return (
      <div className="prodi-table-scroll">
        <table className="prodi-table">
          <thead>
            <tr>
              {pageDefinition.columns.map(([key, label]) => (
                <th key={key} scope="col">
                  <button className="prodi-sort-button" onClick={() => toggleSort(key)} aria-label={`Urutkan berdasarkan ${label}`}>
                    {label}<span aria-hidden="true">{sort.key === key ? (sort.direction === 'asc' ? ' ↑' : ' ↓') : ' ↕'}</span>
                  </button>
                </th>
              ))}
              <th scope="col"><span className="prodi-visually-hidden">Aksi</span></th>
            </tr>
          </thead>
          <tbody>
            {visibleRows.map((row) => (
              <tr key={row.id} onDoubleClick={() => openDetail(row)}>
                {pageDefinition.columns.map(([key]) => <td key={key}>{formatCell(key, row[key], row)}</td>)}
                <td className={`prodi-row-actions${openMenu === row.id ? ' is-open' : ''}`}>
                  <button className="prodi-icon-button prodi-icon-button--small" onClick={() => setOpenMenu((current) => current === row.id ? null : row.id)} aria-expanded={openMenu === row.id} aria-label={`Aksi ${row.name || row.title || row.course || ''}`}>···</button>
                  <div className="prodi-row-action-menu">
                    <button onClick={() => handleRowAction(row, 'view')}>Lihat detail</button>
                    {!isReadOnly && (
                      <>
                        <button onClick={() => handleRowAction(row, 'edit')}>Edit</button>
                        {activePage === 'announcements' && <button onClick={() => handleRowAction(row, 'approve')}>Aktifkan</button>}
                        {activePage === 'announcements' && <button onClick={() => handleRowAction(row, 'archive')}>Arsipkan</button>}
                        {activePage === 'cases' && <button onClick={() => handleRowAction(row, 'stage')}>Tingkatkan SP</button>}
                        <button className="is-danger" onClick={() => handleRowAction(row, 'delete')}>Hapus</button>
                      </>
                    )}
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
    const isReadOnly = ['krs', 'khs', 'grades', 'attendance'].includes(activePage)

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
            {!isReadOnly && pageDefinition.fields && (
              <button className="prodi-button prodi-button--primary" onClick={openCreate}>
                ＋ <span>Tambah {pageDefinition.singular}</span>
              </button>
            )}
            {activePage === 'classes' && (
              <div className="prodi-view-toggle" role="group" aria-label="Tampilan kelas">
                <button className={classView === 'table' ? 'is-selected' : ''} onClick={() => setClassView('table')}>Tabel</button>
                <button className={classView === 'week' ? 'is-selected' : ''} onClick={() => setClassView('week')}>Jadwal</button>
              </div>
            )}
          </div>
        </div>
        {activePage === 'classes' && classView === 'week' ? (
          <div className="prodi-week-grid">
            {['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'].map((day) => (
              <section key={day}>
                <h3>{day}</h3>
                {sortedRows.filter((item) => item.day === day).map((item) => (
                  <article key={item.id}>
                    <strong>{item.time || '-'}</strong>
                    <span>{item.className}</span>
                    <small>{item.room}</small>
                  </article>
                ))}
              </section>
            ))}
          </div>
        ) : renderTable()}
        <div className="prodi-pagination">
          <span>Menampilkan <strong>{sortedRows.length ? (page - 1) * pageSize + 1 : 0}–{Math.min(page * pageSize, sortedRows.length)}</strong> dari <strong>{sortedRows.length}</strong> data</span>
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
    const stats = [
      ['Akun mahasiswa', students.length],
      ['Kelas', unavailablePages.includes('classes') ? '—' : classes.length],
      ['Mata kuliah', unavailablePages.includes('classes') ? '—' : courses.length],
      [
        'Pengumuman aktif',
        unavailablePages.includes('announcements')
          ? '—'
          : announcements.filter((item) => item.status === 'Aktif').length,
      ],
      ['Data kehadiran', attendances.length],
      ['Data nilai', grades.length],
      ['UKT belum lunas', ukt.filter((item) => item.due > 0).length],
      ['Kasus akademik', cases.length],
    ]

    return (
      <>
        <section className="prodi-panel">
          <div className="prodi-panel-heading">
            <div>
              <h2>Ringkasan akademik</h2>
              <p>Jumlah data operasional yang berhasil dimuat dari backend.</p>
            </div>
            <Badge>{activePeriod ? `${activePeriod.year} ${activePeriod.semester}` : 'Periode belum ditetapkan'}</Badge>
          </div>
          <div className="prodi-stat-grid">
            {stats.map(([label, value]) => (
              <article className="prodi-stat-card" key={label}>
                <div className="prodi-stat-top"><span>{label}</span></div>
                <strong className="prodi-stat-value">{value}</strong>
              </article>
            ))}
          </div>
        </section>

        <section className="prodi-panel">
          <div className="prodi-panel-heading">
            <div><h2>Pengumuman terbaru</h2><p>Data pengumuman yang tercatat di backend.</p></div>
            <button className="prodi-link-button" onClick={() => handleNavigate('announcements')}>Buka pengumuman →</button>
          </div>
          {unavailablePages.includes('announcements') ? (
            <p>Cakupan prodi belum tersedia untuk data pengumuman.</p>
          ) : announcements.length ? announcements.slice(0, 3).map((item) => (
            <button className="prodi-list-item" key={item.id} onClick={() => { handleNavigate('announcements'); setModal({ type: 'detail', row: item }) }}>
              <span className="prodi-list-icon">◉</span>
              <span><strong>{item.title}</strong><small>{item.category} · {item.date}</small></span>
              <Badge>{item.status}</Badge>
            </button>
          )) : <p>Belum ada pengumuman dari backend.</p>}
        </section>

        <section className="prodi-panel prodi-shortcuts">
          <div className="prodi-panel-heading"><div><h2>Pintasan</h2><p>Akses cepat modul akademik.</p></div></div>
          <div className="prodi-shortcut-grid">
            {prodiNavigation.flatMap((group) => group.items).filter((item) => !['overview', 'reports', 'settings', 'requests'].includes(item.id)).map((item) => (
              <button key={item.id} onClick={() => handleNavigate(item.id)}><span>{item.icon}</span>{item.label}<b>→</b></button>
            ))}
          </div>
        </section>
      </>
    )
  }

  function renderReports() {
    return (
      <div className="prodi-report-grid">
        <div className="prodi-report-period"><span>Periode aktif: {activePeriod ? `${activePeriod.year} ${activePeriod.semester}` : 'Tidak tersedia'}</span><span>Ekspor memakai data yang dimuat dari backend.</span></div>
        {[
          ['Mahasiswa TRKJ', `${students.length} mahasiswa`, 'students'],
          ['Rekap Kehadiran', `${attendances.length} data rekap`, 'attendance'],
          ['Nilai Mahasiswa', `${grades.length} data nilai`, 'grades'],
          ['Monitoring UKT', `${ukt.length} status tagihan`, 'ukt'],
        ].map(([title, detail, target]) => (
          <article className="prodi-panel prodi-report-card" key={title}>
            <span className="prodi-report-icon">▨</span>
            <h3>{title}</h3>
            <p>{detail}</p>
            <div className="prodi-report-actions">
              <button className="prodi-button prodi-button--outline" onClick={() => { handleNavigate(target); window.setTimeout(() => window.print(), 0) }}>Cetak</button>
              <button className="prodi-button prodi-button--primary" onClick={() => exportCsv(target, getRowsForPage(target))}>Ekspor CSV</button>
            </div>
          </article>
        ))}
        <div className="prodi-demo-note"><strong>Catatan:</strong> Laporan ini bersumber dari data operasional terverifikasi di server.</div>
      </div>
    )
  }

  function renderSpecialPage() {
    if (isLoading) {
      return (
        <div style={{ padding: '50px', textAlign: 'center' }}>
          Memuat data dari server...
        </div>
      )
    }
    if (loadError) {
      return <StatePanel type="error" title="Data backend tidak dapat dimuat" detail={loadError} action={fetchAll} />
    }
    if (unavailablePages.includes(activePage)) {
      return (
        <StatePanel
          type="empty"
          title="Cakupan prodi belum tersedia"
          detail="Backend belum memiliki relasi prodi yang dapat membatasi data ini. Akses Kaprodi ditolak sampai scope server-side dapat diverifikasi."
        />
      )
    }
    if (activePage === 'overview') return renderOverview()
    if (activePage === 'reports') return renderReports()
    if (activePage === 'settings' || activePage === 'requests') {
      return <StatePanel type="empty" title="Fitur belum tersedia" detail="Backend belum menyediakan endpoint untuk menampilkan atau menyimpan data modul ini." />
    }
    return renderModule()
  }

  const currentLabel = prodiNavigation.flatMap((group) => group.items).find((item) => item.id === activePage)?.label || 'Beranda'
  const title = pageDefinition?.title || (activePage === 'reports' ? 'Laporan Akademik' : 'Pengaturan Prodi')
  const hasUnreadRequests = requests.some((request) => request.status !== 'Selesai' && request.status !== 'Draf')
  const isReadOnly = ['krs', 'khs', 'grades', 'attendance'].includes(activePage)

  return (
    <div className="prodi-app">
      {/* SIDEBAR COMPONENT */}
      <ProdiSidebar 
        activePage={activePage} 
        onNavigate={handleNavigate} 
        hasUnreadRequests={hasUnreadRequests} 
        onLogout={handleLogout}
        user={user}
      />

      <main className="prodi-main">
        <header className="prodi-topbar">
          <div className="prodi-mobile-brand"><BrandLogo compact /></div>
          <div className="prodi-breadcrumb"><span>Program Studi</span><span aria-hidden="true">/</span><strong>{currentLabel}</strong></div>
          <div className="prodi-topbar-actions">
            <div className="prodi-semester-chip"><i /> {activePeriod ? `${activePeriod.year} ${activePeriod.semester}` : 'Periode akademik belum tersedia'}</div>
            <button className="prodi-notification-button" onClick={() => handleNavigate('requests')} aria-label="Pengajuan koreksi Prodi">♧</button>
            <div className="prodi-topbar-user">
              <span className="prodi-avatar prodi-avatar--top">{initials(user?.name || '')}</span>
              <span><strong>{user?.name || 'Pengguna'}</strong><small>{user?.role || 'kaprodi'}</small></span>
              <button
                type="button"
                className="prodi-topbar-logout-btn"
                title="Keluar dari sistem"
                aria-label="Logout"
                onClick={handleLogout}
              >
                <svg
                  width="13"
                  height="13"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="2"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  aria-hidden="true"
                >
                  <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
                  <polyline points="16 17 21 12 16 7" />
                  <line x1="21" y1="12" x2="9" y2="12" />
                </svg>
                <span>Keluar</span>
              </button>
            </div>
          </div>
        </header>

        <div className="prodi-content">
          <div className="prodi-demo-banner">
            <span className="prodi-demo-pulse" />
            <span><strong>SISTEM AKADEMIK</strong><span>Data terhubung ke server.</span></span>
          </div>

          <section className="prodi-page-heading">
            <div>
              <div className="prodi-eyebrow">MANAJEMEN PROGRAM STUDI</div>
              <h1>{title}</h1>
              <p>{pageDefinition?.description || (activePage === 'reports' ? 'Ringkasan dan ekspor laporan akademik.' : 'Pengaturan informasi program studi.')}</p>
            </div>
            {pageDefinition && (
              <div className="prodi-page-heading-actions">
                {['announcements', 'cases', 'requests'].includes(activePage) && (
                  <button className="prodi-button prodi-button--outline" onClick={() => setModal({ type: 'workflow' })}>Alur & panduan</button>
                )}
                {!isReadOnly && pageDefinition.fields && (
                  <button className="prodi-button prodi-button--primary" onClick={openCreate}>＋ Tambah {pageDefinition.singular}</button>
                )}
              </div>
            )}
          </section>

          {renderSpecialPage()}

          <footer className="prodi-footer">
            <span>EduTrack Campus <b>·</b> Portal Program Studi</span>
            <span>Sistem Akademik · Terhubung ke server</span>
          </footer>
        </div>
      </main>

      {modal?.type === 'form' && (
        <Modal title={`${modal.mode === 'edit' ? 'Edit' : 'Tambah'} ${pageDefinition.singular}`} onClose={() => setModal(null)}>
          <form onSubmit={saveForm}>
            {formErrors._form && <p className="prodi-field-error" role="alert">{formErrors._form}</p>}
            <div className="prodi-form-grid">
              {pageDefinition.fields.map((field) => {
                const key = field[0]
                const label = field[1]
                const fieldType = field[2]
                const fieldOptions = field[3]
                const options = fieldOptions || pageDefinition.options?.[key]
                const isMultiple = fieldType === 'multiselect'
                const isLong = fieldType === 'textarea' || ['reason', 'note', 'recommendation'].includes(key)
                const isOptional = ['nim', 'program', 'packageId'].includes(key) || (modal.mode === 'edit' && key === 'password')
                if (modal.mode === 'edit' && key === 'password') return null

                return (
                  <label className={`prodi-field${isLong ? ' prodi-field--full' : ''}`} key={key}>
                    <span>{label}{!isOptional && <b> *</b>}</span>
                    {options ? (
                      <select
                        multiple={isMultiple}
                        required={!isOptional}
                        value={isMultiple ? form[key] || [] : form[key] ?? ''}
                        onChange={(event) => {
                          setFormErrors((current) => ({ ...current, [key]: undefined }))
                          setForm((current) => ({
                            ...current,
                            [key]: isMultiple
                              ? Array.from(event.target.selectedOptions, (option) => option.value)
                              : event.target.value,
                          }))
                        }}
                      >
                        {!isMultiple && <option value="">Pilih {label.toLocaleLowerCase('id')}</option>}
                        {options.map((option) => {
                          const isArray = Array.isArray(option)
                          const optValue = isArray ? option[0] : option
                          const optLabel = isArray ? option[1] : option
                          return (
                            <option key={optValue} value={optValue}>
                              {optLabel}
                            </option>
                          )
                        })}
                      </select>
                    ) : isLong ? (
                      <textarea
                        rows="4"
                        value={form[key] || ''}
                        onChange={(event) => {
                          setFormErrors((current) => ({ ...current, [key]: undefined }))
                          setForm((current) => ({ ...current, [key]: event.target.value }))
                        }}
                        placeholder={`${label} (opsional)`}
                      />
                    ) : (
                      <input
                        type={fieldType || 'text'}
                        minLength={fieldType === 'password' ? 8 : undefined}
                        required={!isOptional}
                        value={form[key] || ''}
                        onChange={(event) => {
                          setFormErrors((current) => ({ ...current, [key]: undefined }))
                          setForm((current) => ({ ...current, [key]: event.target.value }))
                        }}
                        placeholder={`Masukkan ${label.toLocaleLowerCase('id')}`}
                      />
                    )}
                    {formErrors[key] && <small className="prodi-field-error" role="alert">{formErrors[key]}</small>}
                  </label>
                )
              })}
            </div>
            <div className="prodi-modal-actions">
              <button type="button" className="prodi-button prodi-button--outline" onClick={() => setModal(null)}>Batal</button>
              <button className="prodi-button prodi-button--primary" type="submit">Simpan ke server</button>
            </div>
          </form>
        </Modal>
      )}

      {modal?.type === 'detail' && (
        <Modal title="Detail data" wide onClose={() => setModal(null)}>
          <div className="prodi-detail-banner">
            <span className="prodi-avatar prodi-avatar--detail">{initials(modal.row.name || modal.row.title || modal.row.course || modal.row.subject)}</span>
            <div>
              <strong>{modal.row.name || modal.row.title || modal.row.course || modal.row.subject || modal.row.code}</strong>
              <small>Informasi resmi terdaftar di sistem</small>
            </div>
            {modal.row.status && <Badge>{modal.row.status}</Badge>}
          </div>

          <div className="prodi-detail-grid">
            {Object.entries(modal.row).filter(([key]) => key !== 'id').map(([key, value]) => (
              <div key={key}>
                <small>{definitions[activePage]?.fields?.find(([field]) => field === key)?.[1] || key}</small>
                <strong>{String(value || '—')}</strong>
              </div>
            ))}
          </div>

          {activePage === 'students' && (
            <div className="prodi-detail-extra">
              <h3>Ringkasan akademik mahasiswa</h3>
              <p>Kehadiran {modal.row.attendance} · Status KRS {modal.row.krs}</p>
              <div className="prodi-progress"><span style={{ width: modal.row.attendance }} /></div>
            </div>
          )}

          <div className="prodi-modal-actions">
            {!isReadOnly && (
              <>
                <button className="prodi-button prodi-button--outline" onClick={() => openEdit(modal.row)}>Edit</button>
                <button className="prodi-button prodi-button--outline is-danger" onClick={() => removeRow(modal.row)}>Hapus</button>
              </>
            )}
            {activePage === 'announcements' && (
              <button className="prodi-button prodi-button--outline" onClick={() => updateStatus(modal.row, 'Berakhir')}>Arsipkan</button>
            )}
            {activePage === 'cases' && (
              <button className="prodi-button prodi-button--outline" onClick={() => simulateStage(modal.row)}>Tingkatkan SP</button>
            )}
          </div>
        </Modal>
      )}

      {modal?.type === 'workflow' && (
        <Modal title="Panduan alur operasional" onClose={() => setModal(null)}>
          <div className="prodi-workflow-content">
            <p>
              {activePage === 'cases'
                ? 'Kasus akademik dan rekomendasi SP dicatat langsung ke database untuk ditinjau oleh pihak kemahasiswaan dan pimpinan fakultas.'
                : activePage === 'requests'
                ? 'Pengajuan koreksi dicatat untuk ditindaklanjuti oleh Administrator Akademik.'
                : 'Pengumuman yang diterbitkan akan langsung terdistribusi kepada mahasiswa dan dosen terkait.'}
            </p>
          </div>
        </Modal>
      )}

      {toast && <div className="prodi-toast" role="status">{toast}</div>}
    </div>
  )
}

function StatePanel({ type, title, detail, action }) {
  return (
    <div className={`prodi-state prodi-state--${type}`} role={type === 'error' ? 'alert' : type === 'loading' ? 'status' : undefined}>
      <span className="prodi-state-illustration" aria-hidden="true">{type === 'loading' ? <i /> : type === 'error' ? '!' : '⌕'}</span>
      <h3>{title}</h3>
      <p>{detail}</p>
      {action && <button className="prodi-button prodi-button--outline" onClick={action}>Coba lagi</button>}
    </div>
  )
}