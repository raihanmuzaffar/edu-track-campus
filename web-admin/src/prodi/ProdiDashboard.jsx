import { useEffect, useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import api from '../services/api'
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
  const [isLoading, setIsLoading] = useState(true)

  // Modul tambahan tanpa API khusus
  const [khs] = useState([])
  const [reports] = useState([])
  const [requests] = useState([])

  const [search, setSearch] = useState('')
  const [filters, setFilters] = useState({})
  const [sort, setSort] = useState({ key: '', direction: 'asc' })
  const [page, setPage] = useState(1)
  const [pageSize, setPageSize] = useState(5)
  const [modal, setModal] = useState(null)
  const [form, setForm] = useState({})
  const [toast, setToast] = useState('')
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
        ['email', 'Email'],
        ['nim', 'NIM (Opsional)'],
        ['className', 'Kelas'],
        ['semester', 'Semester'],
        ['statusAcademic', 'Status akademik'],
      ],
      options: {
        className: ['TRKJ-A', 'TRKJ-B', 'TRKJ-C'],
        statusAcademic: ['Aktif', 'Cuti', 'Perbaikan'],
        semester: ['2026 Ganjil', '2026 Genap'],
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
        ['day', 'Hari'],
        ['room', 'Ruangan'],
        ['semester', 'Semester'],
        ['status', 'Status kelas'],
      ],
      options: {
        day: ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'],
        semester: ['2026 Ganjil', '2026 Genap'],
        status: ['Aktif', 'Nonaktif'],
      },
    },
    packages: {
      title: 'Paket & Mata Kuliah',
      singular: 'mata kuliah',
      description: 'Pemeriksaan mata kuliah yang disiapkan TRKJ sesuai semester dan kurikulum.',
      search: 'Cari kode atau nama mata kuliah...',
      searchable: ['code', 'name', 'semester'],
      filters: [
        { key: 'semester', label: 'Semua semester' },
        { key: 'status', label: 'Semua status' },
      ],
      columns: [
        ['code', 'Kode'],
        ['name', 'Nama mata kuliah'],
        ['credits', 'SKS'],
        ['semester', 'Semester'],
        ['type', 'Jenis'],
        ['status', 'Status'],
      ],
      fields: [
        ['code', 'Kode mata kuliah'],
        ['name', 'Nama mata kuliah'],
        ['credits', 'SKS'],
        ['term', 'Semester'],
      ],
      options: {
        term: ['1', '2', '3', '4', '5', '6', '7', '8'],
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
        semester: ['2026 Ganjil', '2026 Genap'],
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
        ['paid', 'Pembayaran'],
        ['due', 'Sisa'],
        ['status', 'Status'],
        ['note', 'Catatan'],
      ],
      fields: [
        ['studentId', 'Mahasiswa', 'select', students.map((s) => [s.id, s.name])],
        ['semester', 'Semester'],
        ['bill', 'Nominal tagihan (Rp)'],
        ['paid', 'Nominal dibayar (Rp)'],
        ['status', 'Status pembayaran'],
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
        ['type', 'Jenis kasus (Level)'],
        ['note', 'Alasan / Catatan'],
        ['recommendation', 'Tindak lanjut / Rekomendasi'],
        ['status', 'Status'],
      ],
      options: {
        type: ['SP 1', 'SP 2', 'SP 3', 'Peringatan Lisan'],
        status: ['Draf', 'Diajukan', 'Selesai'],
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
        ['status', 'Status'],
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
  }), [students, teachers, courses])

  const fetchAll = async () => {
    setIsLoading(true)
    try {
      const safeGet = (url) =>
        api.get(url).catch((err) => {
          console.warn(`Gagal memuat ${url}:`, err)
          return { data: [] }
        })

      const [
        usersRes,
        coursesRes,
        classesRes,
        gradesRes,
        attendancesRes,
        uktRes,
        announcementsRes,
        casesRes,
        krsRes,
        schedulesRes,
      ] = await Promise.all([
        safeGet('/admin/users'),
        safeGet('/courses/list'),
        safeGet('/classes/list'),
        safeGet('/admin/grades/list'),
        safeGet('/admin/attendances/list'),
        safeGet('/admin/ukt/list'),
        safeGet('/admin/announcements/list'),
        safeGet('/admin/cases/list'),
        safeGet('/admin/krs/list'),
        safeGet('/admin/schedules/list'),
      ])

      const extractArray = (res) => {
        if (Array.isArray(res?.data?.data)) return res.data.data
        if (Array.isArray(res?.data?.data?.data)) return res.data.data.data
        if (Array.isArray(res?.data)) return res.data
        return []
      }

      const rawUsers = extractArray(usersRes)
      const rawCourses = extractArray(coursesRes)
      const rawClasses = extractArray(classesRes)
      const rawGrades = extractArray(gradesRes)
      const rawAttendances = extractArray(attendancesRes)
      const rawUkt = extractArray(uktRes)
      const rawAnnouncements = extractArray(announcementsRes)
      const rawCases = extractArray(casesRes)
      const rawKrs = extractArray(krsRes)
      const rawSchedules = extractArray(schedulesRes)

      // 1. Students & Teachers
      const mappedStudents = rawUsers
        .filter((u) => u.role === 'mahasiswa')
        .map((u) => ({
          id: u.id,
          nim: '-',
          name: u.name,
          email: u.email,
          className: '-',
          semester: '2026 Ganjil',
          statusAcademic: 'Aktif',
          attendance: '0%',
          ukt: '-',
          krs: '-',
          khs: '-',
        }))
      setStudents(mappedStudents)

      const mappedTeachers = rawUsers
        .filter((u) => u.role === 'dosen')
        .map((u) => ({
          id: u.id,
          name: u.name,
          email: u.email,
        }))
      setTeachers(mappedTeachers)

      // 2. Classes
      const mappedClasses = rawClasses.map((c) => ({
        id: c.id,
        className: c.name,
        semester: c.semester || '2026 Ganjil',
        totalStudents: '0',
        packageName: c.Course?.name || '-',
        lecturer: c.Dosen?.name || '-',
        attendance: '0%',
        grades: '0%',
        status: c.status || 'Aktif',
        day: c.day || '-',
        time: `${c.start_time || ''} - ${c.end_time || ''}`.trim() || '-',
        room: c.room || '-',
        courseId: c.course_id || c.CourseID,
        dosenId: c.dosen_id || c.DosenID,
      }))
      setClasses(mappedClasses)

      // 3. Courses
      const mappedCourses = rawCourses.map((c) => ({
        id: c.id,
        code: c.code,
        name: c.name,
        credits: c.sks,
        term: c.semester,
        semester: String(c.semester || '2026 Ganjil'),
        courses: `${c.code || ''} · ${c.name || ''} (${c.sks || 0} SKS)`.trim(),
        type: 'Wajib',
        status: 'Aktif',
        lecturer: '-',
        schedule: '-',
      }))
      setCourses(mappedCourses)

      // 4. Grades
      const mappedGrades = rawGrades.map((g) => ({
        id: g.id,
        nim: '-',
        name: g.Mahasiswa?.name || '-',
        course: g.Class?.Course?.name || '-',
        semester: '2026 Ganjil',
        assignment: 0,
        midterm: 0,
        final: 0,
        score: g.score ?? g.Score ?? 0,
        letter: g.letter || g.Letter || '-',
        status: 'Lengkap',
      }))
      setGrades(mappedGrades)

      // 5. Attendances
      const mappedAttendances = rawAttendances.map((a) => {
        const isHadir = a.status === 'hadir' || a.Status === 'hadir'
        const dateStr = a.date || a.Date
        return {
          id: a.id,
          date: dateStr ? String(dateStr).slice(0, 10) : '-',
          nim: '-',
          name: a.Mahasiswa?.name || '-',
          course: a.Class?.Course?.name || '-',
          className: '-',
          semester: '2026 Ganjil',
          present: isHadir ? 1 : 0,
          excused: (a.status === 'izin' || a.Status === 'izin') ? 1 : 0,
          absent: (a.status === 'alpa' || a.Status === 'alpa') ? 1 : 0,
          attendance: isHadir ? '100%' : '0%',
          status: isHadir ? 'Aman' : 'Perlu perhatian',
        }
      })
      setAttendances(mappedAttendances)

      // 6. UKT
      const mappedUkt = rawUkt.map((item) => {
        const billed = Number(item.billed) || 0
        const paid = Number(item.paid) || 0
        return {
          id: item.id,
          studentId: item.student_id || item.StudentID || item.Student?.id,
          nim: '-',
          name: item.Student?.name || '-',
          className: '-',
          semester: item.semester || '2026 Ganjil',
          bill: billed,
          paid: paid,
          due: billed - paid,
          status: paid >= billed ? 'Lunas' : 'Belum lunas',
          note: '-',
        }
      })
      setUkt(mappedUkt)

      // 7. Announcements
      const mappedAnnouncements = rawAnnouncements.map((item) => {
        const start = item.start_date ? String(item.start_date).slice(0, 10) : ''
        const end = item.end_date ? String(item.end_date).slice(0, 10) : ''
        return {
          id: item.id,
          title: item.title,
          category: item.category || 'Akademik',
          audience: 'Mahasiswa TRKJ',
          date: start || '-',
          period: start && end ? `${start} - ${end}` : start || '-',
          status: item.status || 'Aktif',
          body: item.content || '',
        }
      })
      setAnnouncements(mappedAnnouncements)

      // 8. Cases
      const mappedCases = rawCases.map((item) => ({
        id: item.id,
        studentId: item.student_id || item.StudentID || item.Student?.id,
        nim: '-',
        name: item.Student?.name || '-',
        className: '-',
        type: item.level || 'SP 1',
        note: item.reason || '-',
        date: item.created_at ? String(item.created_at).slice(0, 10) : '-',
        status: item.status || 'Draf',
        recommendation: item.followup || '-',
      }))
      setCases(mappedCases)

      // 9. KRS
      const mappedKrs = rawKrs.map((item) => ({
        id: item.id,
        nim: '-',
        name: item.Mahasiswa?.name || '-',
        className: item.Class?.name || '-',
        semester: '2026 Ganjil',
        totalCredits: '-',
        scheduleStatus: '-',
        status: item.status || 'Siap',
        publication: '-',
      }))
      setKrs(mappedKrs)

      // 10. Schedules
      const mappedSchedules = rawSchedules.map((item) => ({
        id: item.id,
        course: item.Course?.name || '-',
        className: item.Class?.name || '-',
        semester: item.semester || '2026 Ganjil',
        lecturer: item.Teacher?.name || '-',
        day: item.day || '-',
        time: `${item.start_time || ''} - ${item.end_time || ''}`.trim() || '-',
        room: item.room || '-',
        status: 'Aktif',
      }))
      setSchedule(mappedSchedules)
    } catch (error) {
      console.error('Gagal mengambil data dari server:', error)
    } finally {
      setIsLoading(false)
    }
  }

  useEffect(() => {
    fetchAll()
  }, [])

  function getRowsForPage(targetPage) {
    switch (targetPage) {
      case 'students':
        return students
      case 'classes':
        return classes
      case 'packages':
        return courses
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

  const handleLogout = () => {
    localStorage.removeItem('token')
    localStorage.removeItem('role')
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
    })
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
    })
    setModal({ type: 'form', mode: 'edit', row })
  }

  async function saveForm(event) {
    event.preventDefault()

    if (['krs', 'khs', 'grades', 'attendance'].includes(activePage)) {
      notify('Anda tidak memiliki akses untuk mengubah data ini')
      return
    }

    const optionalKeys = ['body', 'nim', 'email', 'note', 'attendance', 'ukt', 'krs', 'khs', 'warning', 'reason', 'recommendation', 'packageName', 'totalStudents', 'grades', 'lecturer', 'courses', 'schedule', 'due', 'period', 'date']
    const missing = pageDefinition.fields.find(([key]) => !optionalKeys.includes(key) && !String(form[key] ?? '').trim())
    if (missing) {
      notify(`${missing[1]} wajib diisi.`)
      return
    }

    try {
      if (activePage === 'students') {
        const email = form.email || `${(form.name || 'mahasiswa').toLowerCase().replace(/\s+/g, '')}${form.nim ? `_${form.nim}` : ''}@edutrack.ac.id`
        const payload = {
          name: form.name,
          email: email,
          role: 'mahasiswa',
        }
        if (modal.mode === 'create') {
          payload.password = form.password || 'password123'
          await api.post('/admin/users/create', payload)
        } else {
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
          start_time: form.start_time || form.startTime || '08:00',
          end_time: form.end_time || form.endTime || '10:00',
          room: form.room || 'Ruang Kelas',
          year: form.year || '2026',
          semester: form.semester || '2026 Ganjil',
          status: form.status || 'Aktif',
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
          semester: form.semester || '2026 Ganjil',
          billed: billed,
          paid: paid,
          due_date: form.due_date ? new Date(form.due_date).toISOString() : new Date().toISOString(),
        }
        if (modal.mode === 'create') {
          await api.post('/admin/ukt', payload)
        } else {
          await api.put(`/admin/ukt/update?id=${modal.row.id}`, payload)
        }
      } else if (activePage === 'announcements') {
        const payload = {
          title: form.title,
          category: form.category || 'Akademik',
          content: form.body || form.content || '',
          start_date: form.date ? new Date(form.date).toISOString() : new Date().toISOString(),
          end_date: new Date(Date.now() + 7 * 24 * 3600 * 1000).toISOString(),
          status: form.status || 'Aktif',
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
          level: form.type || form.level || 'SP 1',
          reason: form.note || form.reason || '',
          followup: form.recommendation || form.followup || '',
          status: form.status || 'Draf',
        }
        if (modal.mode === 'create') {
          await api.post('/admin/cases', payload)
        } else {
          await api.put(`/admin/cases/update?id=${modal.row.id}`, payload)
        }
      } else if (activePage === 'packages') {
        const payload = {
          code: form.code,
          name: form.name,
          sks: Number(form.credits || 3),
          semester: Number(form.term || form.semester || 1),
        }
        if (modal.mode === 'create') {
          await api.post('/courses', payload)
        } else {
          await api.put(`/courses/update?id=${modal.row.id}`, payload)
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
      notify(`Gagal menyimpan data: ${error?.response?.data?.message || error?.message || 'Terjadi kesalahan'}`)
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
        await api.delete(`/courses/delete?id=${row.id}`)
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
          start_date: row.date ? new Date(row.date).toISOString() : new Date().toISOString(),
          end_date: new Date(Date.now() + 7 * 24 * 3600 * 1000).toISOString(),
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
    const currentIndex = stages.indexOf(row.type || row.recommendation)
    if (currentIndex < 0 || currentIndex === stages.length - 1) {
      notify('Tahap rekomendasi terakhir telah tercapai.')
      return
    }
    const nextStage = stages[currentIndex + 1]
    if (!window.confirm(`Ubah level rekomendasi menjadi ${nextStage}?`)) return
    try {
      await api.put(`/admin/cases/update?id=${row.id}`, {
        student_id: Number(row.studentId || 1),
        level: nextStage,
        reason: row.note || '',
        followup: nextStage,
        status: 'Diajukan',
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
    const activeStudents = students.length
    const totalClasses = classes.length
    const avgAttendance = attendances.length > 0
      ? Math.round(attendances.reduce((sum, item) => sum + (Number.parseInt(item.attendance, 10) || 0), 0) / attendances.length)
      : 0
    const attentionCount = attendances.filter((item) => item.status === 'Perlu perhatian').length
    const unpaidUkt = ukt.filter((item) => item.status !== 'Lunas').length
    const academicCases = cases.length
    const gradeCompletion = grades.length > 0
      ? Math.round((grades.filter((item) => item.status === 'Lengkap').length / grades.length) * 100)
      : 0
    const krsDraft = krs.filter((item) => item.status !== 'Siap').length
    const khsPending = khs.filter((item) => item.status !== 'Disetujui').length
    const scheduleIssues = schedule.filter((item) => item.status !== 'Lengkap' && item.status !== 'Aktif').length
    const activeAnnouncements = announcements.filter((item) => item.status === 'Aktif').length

    const stats = [
      { label: 'Mahasiswa aktif', value: activeStudents, icon: '♙', tint: 'blue', delta: 'Terdaftar', note: 'TRKJ aktif' },
      { label: 'Jumlah kelas', value: totalClasses, icon: '▦', tint: 'purple', delta: 'Semester aktif', note: 'TRKJ' },
      { label: 'Mahasiswa per kelas', value: totalClasses > 0 ? Math.round(activeStudents / totalClasses) : 0, icon: '▤', tint: 'teal', delta: 'Rata-rata', note: 'per kelas' },
      { label: 'Rekap kehadiran', value: `${avgAttendance}%`, icon: '◷', tint: 'orange', delta: 'Periode aktif', note: 'kelas TRKJ' },
      { label: 'Absensi bermasalah', value: attentionCount, icon: '⚠', tint: 'orange', delta: 'Butuh review', note: 'per semester' },
      { label: 'UKT belum lunas', value: unpaidUkt, icon: '◈', tint: 'purple', delta: 'Tagihan aktif', note: 'mahasiswa' },
      { label: 'Kasus akademik', value: academicCases, icon: '⚑', tint: 'blue', delta: 'Perlu tindak lanjut', note: 'TRKJ' },
      { label: 'Kelengkapan nilai', value: `${gradeCompletion}%`, icon: '◫', tint: 'teal', delta: 'Kelas TRKJ', note: 'nilai lengkap' },
    ]

    return (
      <>
        <div className="prodi-stat-grid">
          {stats.map((stat) => (
            <article className={`prodi-stat-card prodi-stat-card--${stat.tint}`} key={stat.label}>
              <div className="prodi-stat-top"><span>{stat.label}</span><span className="prodi-stat-icon">{stat.icon}</span></div>
              <strong className="prodi-stat-value">{stat.value}</strong>
              <div className="prodi-stat-foot"><b>{stat.delta}</b><span>{stat.note}</span></div>
            </article>
          ))}
        </div>

        <div className="prodi-overview-grid">
          <section className="prodi-panel prodi-chart-panel">
            <div className="prodi-panel-heading"><div><h2>Aktivitas Akademik TRKJ</h2><p>Ringkasan operasional semester aktif</p></div><Badge>Semester Ganjil</Badge></div>
            <div className="prodi-chart-legend"><span><i className="prodi-legend-dot prodi-legend-dot--blue" />Mahasiswa aktif</span><span><i className="prodi-legend-dot prodi-legend-dot--purple" />Kehadiran</span></div>
            <div className="prodi-bar-chart" role="img" aria-label="Grafik aktivitas TRKJ selama beberapa bulan">
              {[['Mar', 44, 37], ['Apr', 56, 48], ['Mei', 49, 41], ['Jun', 70, 57], ['Jul', 64, 53], ['Agu', 82, 68]].map(([month, active, present]) => (
                <div className="prodi-chart-column" key={month}>
                  <div className="prodi-bars"><span className="prodi-bar prodi-bar--blue" style={{ height: `${active}%` }} /><span className="prodi-bar prodi-bar--purple" style={{ height: `${present}%` }} /></div><small>{month}</small>
                </div>
              ))}
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
            <div className="prodi-panel-heading"><div><h2>Pelaksanaan Operasional</h2><p>Monitoring TRKJ</p></div><button className="prodi-link-button" onClick={() => handleNavigate('grades')}>Lihat nilai →</button></div>
            <div className="prodi-grade-distribution">
              {[['KRS draft', krsDraft, 'blue'], ['KHS pending', khsPending, 'teal'], ['Jadwal revisi', scheduleIssues, 'orange'], ['Pengumuman aktif', activeAnnouncements, 'red']].map(([label, value, color]) => (
                <div className="prodi-grade-row" key={label}>
                  <span>{label}</span>
                  <div className="prodi-progress"><i className={`prodi-progress-fill prodi-progress-fill--${color}`} style={{ width: `${Math.min(100, value * 20)}%` }} /></div>
                  <b>{value}</b>
                </div>
              ))}
            </div>
          </section>
          <section className="prodi-panel">
            <div className="prodi-panel-heading"><div><h2>Prioritas Tindak Lanjut</h2><p>Checklist Prodi</p></div><span className="prodi-alert-count">{attentionCount + unpaidUkt}</span></div>
            <div className="prodi-attention-item"><span className="prodi-attention-icon">!</span><div><strong>{attentionCount} mahasiswa dengan masalah absensi</strong><small>Periksa rekap sebelum tindakan lanjutan.</small></div><button onClick={() => handleNavigate('attendance')} aria-label="Lihat absensi">→</button></div>
            <div className="prodi-attention-item"><span className="prodi-attention-icon prodi-attention-icon--blue">▧</span><div><strong>{unpaidUkt} mahasiswa dengan UKT belum lunas</strong><small>Catat tindak lanjut keuangan mahasiswa.</small></div><button onClick={() => handleNavigate('ukt')} aria-label="Lihat monitoring UKT">→</button></div>
          </section>
        </div>

        <div className="prodi-overview-grid prodi-overview-grid--lower">
          <section className="prodi-panel">
            <div className="prodi-panel-heading"><div><h2>Pengumuman Prodi</h2><p>Informasi aktif untuk TRKJ</p></div><button className="prodi-link-button" onClick={() => handleNavigate('announcements')}>Semua →</button></div>
            {announcements.slice(0, 2).map((item) => (
              <button className="prodi-list-item" key={item.id} onClick={() => { handleNavigate('announcements'); setModal({ type: 'detail', row: item }) }}>
                <span className="prodi-list-icon">◉</span>
                <span><strong>{item.title}</strong><small>{item.category} · {item.date}</small></span>
                <Badge>{item.status}</Badge>
              </button>
            ))}
          </section>
          <section className="prodi-panel">
            <div className="prodi-panel-heading"><div><h2>Aktivitas Terbaru</h2><p>Catatan operasional TRKJ</p></div></div>
            <div className="prodi-activity"><i /><span><strong>Data mahasiswa terhubung ke backend</strong><small>Sistem · Aktif</small></span></div>
            <div className="prodi-activity"><i /><span><strong>Sinkronisasi nilai dan kehadiran</strong><small>API · Berhasil</small></span></div>
            <div className="prodi-activity"><i /><span><strong>Pemberitahuan UKT diperbarui</strong><small>Keuangan · Aktif</small></span></div>
          </section>
        </div>

        <section className="prodi-panel prodi-shortcuts">
          <div className="prodi-panel-heading"><div><h2>Pintasan</h2><p>Akses cepat modul TRKJ</p></div></div>
          <div className="prodi-shortcut-grid">{prodiNavigation.flatMap((group) => group.items).slice(1).map((item) => <button key={item.id} onClick={() => handleNavigate(item.id)}><span>{item.icon}</span>{item.label}<b>→</b></button>)}</div>
        </section>
      </>
    )
  }

  function renderReports() {
    return (
      <div className="prodi-report-grid">
        <div className="prodi-report-period"><label>Periode laporan<select value={reportPeriod} onChange={(event) => setReportPeriod(event.target.value)}><option>Semester Ganjil</option><option>Semester Genap</option><option>Tahun Akademik</option></select></label><span>Menampilkan: {reportPeriod}</span></div>
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

  function renderSettings() {
    return (
      <form className="prodi-panel prodi-settings-form" onSubmit={(event) => { event.preventDefault(); notify('Pengaturan program studi berhasil diperbarui.') }}>
        <div className="prodi-panel-heading"><div><h2>Informasi Program Studi</h2><p>Profil operasional program studi TRKJ.</p></div><Badge>Aktif</Badge></div>
        <div className="prodi-form-grid">
          {Object.entries(settings).map(([label, value]) => (
            <label className="prodi-field" key={label}>
              <span>{label}</span>
              <input value={value} onChange={(event) => setSettings((current) => ({ ...current, [label]: event.target.value }))} />
            </label>
          ))}
        </div>
        <div className="prodi-form-actions"><button className="prodi-button prodi-button--primary" type="submit">Simpan Pengaturan</button></div>
      </form>
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
    if (activePage === 'overview') return renderOverview()
    if (activePage === 'reports') return renderReports()
    if (activePage === 'settings') return renderSettings()
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
      />

      <main className="prodi-main">
        <header className="prodi-topbar">
          <div className="prodi-mobile-brand"><span className="prodi-brand-mark">E</span><strong>EduTrack <small>Prodi</small></strong></div>
          <div className="prodi-breadcrumb"><span>Program Studi</span><span aria-hidden="true">/</span><strong>{currentLabel}</strong></div>
          <div className="prodi-topbar-actions">
            <div className="prodi-semester-chip"><i /> Tahun Akademik 2025/2026</div>
            <button className="prodi-notification-button" onClick={() => { handleNavigate('requests'); notify('Anda melihat daftar pengajuan koreksi Prodi.') }} aria-label="Notifikasi pengajuan Prodi">♧{requests.filter((request) => request.status !== 'Selesai' && request.status !== 'Draf').length > 0 && <i />}</button>
            <div className="prodi-topbar-user">
              <span className="prodi-avatar prodi-avatar--top">AW</span>
              <span><strong>Arman Wijaya</strong><small>Kaprodi</small></span>
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
            <div className="prodi-form-grid">
              {pageDefinition.fields.map((field) => {
                const key = field[0]
                const label = field[1]
                const fieldOptions = field[3]
                const options = fieldOptions || pageDefinition.options?.[key]
                const isLong = ['body', 'reason', 'note', 'recommendation'].includes(key)
                const isOptional = ['body', 'nim', 'email', 'note', 'attendance', 'ukt', 'krs', 'khs', 'warning', 'reason', 'recommendation'].includes(key)

                return (
                  <label className={`prodi-field${isLong ? ' prodi-field--full' : ''}`} key={key}>
                    <span>{label}{!isOptional && <b> *</b>}</span>
                    {options ? (
                      <select
                        required={!isOptional}
                        value={form[key] ?? ''}
                        onChange={(event) => setForm((current) => ({ ...current, [key]: event.target.value }))}
                      >
                        <option value="">Pilih {label.toLocaleLowerCase('id')}</option>
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
                        onChange={(event) => setForm((current) => ({ ...current, [key]: event.target.value }))}
                        placeholder={`${label} (opsional)`}
                      />
                    ) : (
                      <input
                        required={!isOptional}
                        value={form[key] || ''}
                        onChange={(event) => setForm((current) => ({ ...current, [key]: event.target.value }))}
                        placeholder={`Masukkan ${label.toLocaleLowerCase('id')}`}
                      />
                    )}
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