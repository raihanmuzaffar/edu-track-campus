import { useEffect, useState } from 'react'
import api from '../services/api'

// Constants & data
import {
  semesters, currentSemester, classNames, program,
  initialClasses, initialTeachers, initialCourses,
  initialPackages, initialSchedules, initialGrades, initialUkt,
  initialAttendance, initialCases, initialAnnouncements, initialDocuments,
  initialKrs, initialKhs, filterLabels, titles,
} from './constants/adminData'

// Utilities
import { fmtMoney, fmtDate, id, getClassName, studentName, courseName, teacherName, letterGrade } from './utils/adminUtils'

// UI components
import { Icon, Badge, Stat, PageHeading, PanelHeading, ActivityList, Table, Modal, Preference } from './components/AdminUI'

// Layout components
import { AdminSidebar } from './components/AdminSidebar'
import { AdminHeader } from './components/AdminHeader'

function AdminAcademicDashboard() {
  const [page, setPage] = useState('dashboard')
  const [classes, setClasses] = useState(initialClasses)
  const [students, setStudents] = useState([])
  const [isLoading, setIsLoading] = useState(true)
  const [teachers, setTeachers] = useState(initialTeachers)
  const [courses, setCourses] = useState(initialCourses)

  // FALLBACK MODULES - No admin-level API endpoints available (as of investigation):
  // - krs/enrollments: only POST /api/v1/enrollments (mahasiswa) and GET /api/v1/enrollments/my (mahasiswa)
  // When admin endpoints become available, remove from this list and add API calls in saveRecord/removeRecord.
  const FALLBACK_MODULES = ['packages', 'schedules', 'krs', 'khs', 'ukt', 'cases', 'announcements', 'documents']
  const [packages, setPackages] = useState(initialPackages)
  const [schedules, setSchedules] = useState(initialSchedules)
  const [grades, setGrades] = useState([])
  const [ukt, setUkt] = useState(initialUkt)
  const [attendance, setAttendance] = useState([])
  const [cases, setCases] = useState(initialCases)
  const [announcements, setAnnouncements] = useState(initialAnnouncements)
  const [krs, setKrs] = useState(initialKrs)
  const [khs, setKhs] = useState(initialKhs)
  const [documents, setDocuments] = useState(initialDocuments)
  const [activities, setActivities] = useState([{ id: 'act1', time: '2026-10-23T08:30:00', category: 'Akademik', message: 'Data demo semester 2026 Ganjil disiapkan', status: 'Berhasil' }])
  const [query, setQuery] = useState('')
  const [filters, setFilters] = useState({})
  const [sort, setSort] = useState({ key: '', direction: 'asc' })
  const [pageNumber, setPageNumber] = useState(1)
  const [dialog, setDialog] = useState(null)
  const [toast, setToast] = useState('')
  const [mobileOpen, setMobileOpen] = useState(false)
  const [compact, setCompact] = useState(false)
  const [selectedSemester, setSelectedSemester] = useState(currentSemester)
  const [importResult, setImportResult] = useState(null)
  const [reportCategory, setReportCategory] = useState('')

  const packageById = (packageId) => packages.find((row) => row.id === packageId)
  const schedulesForPackage = (classId) => {
    const classRow = classes.find((row) => row.id === classId)
    const pack = classRow && packageById(classRow.packageId)
    if (!pack) return []
    return schedules.filter((row) => row.classId === classId && row.semester === classRow.semester && pack.courseIds.includes(row.courseId))
  }
  const classKrsReadiness = (classId) => {
    const row = classes.find((item) => item.id === classId)
    const pack = row && packageById(row.packageId)
    if (!row || !pack || !pack.courseIds.length) return { ready: false, reason: 'Kelas belum memiliki paket mata kuliah yang lengkap.' }
    const classSchedules = schedulesForPackage(classId)
    const missing = pack.courseIds.filter((courseId) => !classSchedules.some((schedule) => schedule.courseId === courseId && schedule.teacherId && schedule.room && schedule.start && schedule.end))
    const clashes = classSchedules.filter((schedule) => conflicts(schedule, schedule.id).length)
    if (missing.length) return { ready: false, reason: `Jadwal belum lengkap: ${missing.map((courseId) => courseName(courses, courseId)).join(', ')}.` }
    if (clashes.length) return { ready: false, reason: 'Jadwal kelas memiliki bentrok dosen atau ruang.' }
    return { ready: true, reason: 'Paket dan seluruh jadwal kelas lengkap.' }
  }
  const studentKhs = (student) => {
    const classRow = classes.find((row) => row.id === student.classId)
    const pack = classRow && packageById(classRow.packageId)
    const required = pack?.courseIds || []
    const entries = grades.filter((grade) => grade.studentId === student.id && grade.semester === student.semester && required.includes(grade.courseId))
    const complete = required.length > 0 && required.every((courseId) => entries.some((entry) => entry.courseId === courseId && Number.isFinite(entry.score) && entry.score >= 0 && entry.score <= 100))
    const credits = required.reduce((sum, courseId) => sum + (courses.find((course) => course.id === courseId)?.credits || 0), 0)
    const points = entries.filter((entry) => required.includes(entry.courseId) && Number.isFinite(entry.score)).reduce((sum, entry) => sum + letterGrade(entry.score)[1] * (courses.find((course) => course.id === entry.courseId)?.credits || 0), 0)
    return { complete, entries, required, credits, ips: complete && credits ? (points / credits).toFixed(2) : '—', status: complete ? khs[student.id] || 'Siap dipublikasikan' : 'Perlu diperiksa' }
  }
  const conflicts = (schedule, ignoreId) => schedules.filter((other) => {
    if (other.id === ignoreId || other.semester !== schedule.semester || other.day !== schedule.day) return false
    const overlaps = schedule.start < other.end && schedule.end > other.start
    return overlaps && (other.teacherId === schedule.teacherId || other.room === schedule.room || other.classId === schedule.classId)
  })
  const scheduleConflicts = schedules.flatMap((schedule) => conflicts(schedule, schedule.id).filter((other) => other.id > schedule.id).map((other) => `${schedule.id}:${other.id}`)).length
  const activeStudents = students.filter((student) => student.status === 'Aktif').length
  const tuitionDebt = ukt.reduce((sum, row) => sum + Math.max(0, row.billed - row.paid), 0)
  const tuitionUnpaid = ukt.filter((row) => row.paid < row.billed).length
  const attendanceIssues = attendance.filter((row) => row.meetings > 0 && row.present / row.meetings < 0.75).length
  const incompleteGrades = students.filter((student) => student.status === 'Aktif').reduce((total, student) => {
    const pack = packageById(classes.find((row) => row.id === student.classId)?.packageId)
    return total + (pack?.courseIds || []).filter((courseId) => !grades.some((grade) => grade.studentId === student.id && grade.courseId === courseId && grade.semester === student.semester && Number.isFinite(grade.score) && grade.score >= 0 && grade.score <= 100)).length
  }, 0)
  const pendingKrs = Object.values(krs).filter((status) => status !== 'Dipublikasikan').length
  const pendingKhs = students.filter((student) => studentKhs(student).status !== 'Dipublikasikan').length
  const classRows = classes.map((row) => ({ ...row, count: students.filter((student) => student.classId === row.id).length, package: packageById(row.packageId)?.name || 'Belum ditetapkan' }))
  const scheduleRows = schedules.map((row) => ({ ...row, class: getClassName(classes, row.classId), course: courseName(courses, row.courseId), teacher: teacherName(teachers, row.teacherId), conflict: conflicts(row, row.id).length ? 'Bentrok' : 'Tidak bentrok' }))
  const gradeRows = grades.map((row) => ({ ...row, nim: students.find((student) => student.id === row.studentId)?.nim || '—', student: studentName(students, row.studentId), class: getClassName(classes, students.find((student) => student.id === row.studentId)?.classId), course: courseName(courses, row.courseId), letter: Number.isFinite(row.score) ? letterGrade(row.score)[0] : '—' }))
  const khsRows = students.map((student) => ({ id: student.id, nim: student.nim, student: student.name, class: getClassName(classes, student.classId), semester: student.semester, ...studentKhs(student) }))
  const uktRows = ukt.map((row) => ({ ...row, nim: students.find((student) => student.id === row.studentId)?.nim || '—', student: studentName(students, row.studentId), class: getClassName(classes, students.find((student) => student.id === row.studentId)?.classId), debt: Math.max(0, row.billed - row.paid), status: row.paid >= row.billed ? 'Lunas' : row.paid > 0 ? 'Sebagian' : 'Belum lunas', dueStatus: row.paid >= row.billed ? 'Lunas' : row.due < new Date().toISOString().slice(0, 10) ? 'Terlambat' : 'Belum jatuh tempo' }))
  const attendanceRows = attendance.map((row) => ({ ...row, nim: students.find((student) => student.id === row.studentId)?.nim || '—', student: studentName(students, row.studentId), class: getClassName(classes, students.find((student) => student.id === row.studentId)?.classId), course: courseName(courses, row.courseId), percentage: row.meetings ? Math.round(row.present / row.meetings * 100) : 0, status: row.meetings && row.present / row.meetings < 0.75 ? 'Perlu tindak lanjut' : 'Aman' }))
  const caseRows = cases.map((row) => ({ ...row, nim: students.find((student) => student.id === row.studentId)?.nim || '—', student: studentName(students, row.studentId), class: getClassName(classes, students.find((student) => student.id === row.studentId)?.classId) }))
  const packageRows = packages.map((row) => ({ ...row, courses: row.courseIds.map((courseId) => courseName(courses, courseId)).join(', '), credits: row.courseIds.reduce((sum, courseId) => sum + (courses.find((course) => course.id === courseId)?.credits || 0), 0), classes: row.classIds.map((classId) => getClassName(classes, classId)).join(', ') }))
  const teacherRows = teachers.map((row) => {
    const assigned = schedules.filter((schedule) => schedule.teacherId === row.id)
    return { ...row, courses: [...new Set(assigned.map((schedule) => courseName(courses, schedule.courseId)))].join(', ') || 'Belum ditugaskan', classes: [...new Set(assigned.map((schedule) => getClassName(classes, schedule.classId)))].join(', ') || '—', load: assigned.length }
  })

  function notify(message) {
    setToast(message)
    window.setTimeout(() => setToast(''), 3200)
  }

  const fetchAll = async () => {
    setIsLoading(true)
    try {
      const [usersRes, coursesRes, classesRes, gradesRes, attendancesRes] = await Promise.all([
        api.get('/admin/users'),
        api.get('/courses/list'),
        api.get('/classes/list'),
        api.get('/admin/grades/list'),
        api.get('/admin/attendances/list'),
      ])
      const users = usersRes?.data?.data?.data || []
      setStudents(
        users
          .filter((u) => u.role === 'mahasiswa')
          .map((u) => ({
            id: u.id,
            nim: '-',
            name: u.name,
            email: u.email,
            classId: null,
            semester: '2026 Ganjil',
            status: 'Aktif',
          }))
      )
      setTeachers(
        users
          .filter((u) => u.role === 'dosen')
          .map((u) => ({
            id: u.id,
            nidn: '-',
            name: u.name,
            email: u.email,
            expertise: u.expertise || '-',
            status: 'Aktif',
          }))
      )
      const courses = coursesRes?.data?.data?.data || []
      setCourses(
        courses.map((c) => ({
          id: c.id,
          code: c.code,
          name: c.name,
          credits: c.sks,
          term: c.semester,
          type: 'Wajib',
          status: 'Aktif',
        }))
      )
      const classData = classesRes?.data?.data?.data || []
      setClasses(
        classData.map((c) => ({
          id: c.id,
          code: c.name,
          year: '-',
          semester: '2026 Ganjil',
          packageId: null,
          status: 'Aktif',
        }))
      )

      // Map grades from API
      const gradesData = gradesRes?.data?.data?.data || []
      setGrades(
        gradesData.map((item) => ({
          id: item.id,
          nim: '-',
          student: item.Mahasiswa?.name || 'Unknown',
          class: '-',
          course: item.Class?.Course?.name || 'Unknown',
          semester: '2026 Ganjil',
          score: item.score,
          letter: item.letter,
          status: 'Lengkap',
        }))
      )

      // Map attendance from API
      const attendancesData = attendancesRes?.data?.data?.data || []
      setAttendance(
        attendancesData.map((item) => ({
          id: item.id,
          date: item.date,
          nim: '-',
          student: item.Mahasiswa?.name || 'Unknown',
          class: '-',
          course: item.Class?.Course?.name || 'Unknown',
          present: item.status === 'hadir' ? 1 : 0,
          permit: item.status === 'izin' ? 1 : 0,
          sick: item.status === 'sakit' ? 1 : 0,
          absent: item.status === 'alpa' ? 1 : 0,
          meetings: 1,
          percentage: item.status === 'hadir' ? 100 : 0,
          status: item.status === 'hadir' ? 'Aman' : 'Perlu tindak lanjut',
        }))
      )

      // Clear derived state that may contain orphaned references
      setKhs({})
      setCases((rows) => rows.filter((row) => users.some((u) => u.id === row.studentId)))
      setDocuments((rows) => rows.filter((row) => users.some((u) => u.id === row.studentId)))
      setUkt((rows) => rows.filter((row) => users.some((u) => u.id === row.studentId)))
      setKrs({})
    } catch (error) {
      const statusCode = error?.response?.status
      let message = 'Gagal memuat data dari server'
      if (statusCode === 404) message = 'Data tidak ditemukan di server (404)'
      else if (statusCode === 500) message = 'Server mengalami kesalahan (500)'
      else if (statusCode >= 400 && statusCode < 500) message = 'Permintaan tidak valid (validasi server)'
      else if (!error?.response) message = 'Tidak dapat terhubung ke server (koneksi gagal)'
      notify(message)
    } finally {
      setIsLoading(false)
    }
  }

  useEffect(() => {
    fetchAll()
  }, [])
  function log(category, message) {
    setActivities((rows) => [{ id: id(), time: new Date().toISOString(), category, message, status: 'Berhasil' }, ...rows])
  }
  function navigate(nextPage) {
    setPage(nextPage)
    setMobileOpen(false)
    setQuery('')
    setFilters({})
    setSort({ key: '', direction: 'asc' })
    setPageNumber(1)
  }
  function saveRecord(entity, values, item) {
    const config = pageConfig[entity]
    const setter = setters[entity]
    if (!setter || !config) return

    // Check for fallback modules first
    if (FALLBACK_MODULES.includes(entity)) {
      notify('Fitur ini belum tersedia di server')
      return
    }

    // Explicit guard for grade and attendance
    if (entity === 'grade' || entity === 'attendance') {
      notify('Fitur tambah/edit khusus admin belum tersedia')
      return
    }

    const result = { ...values, id: item?.id || id() }
    
    // Keep existing validations for non-API entities only
    // For API-backed entities (student, teacher, course, class), server is authoritative for duplicates
    if (entity === 'class' && !classNames.includes(values.code)) return notify('Pilih kelas resmi TRKJ semester 1 sampai 4.')
    if (entity === 'class' && values.packageId) {
      const assignedPackage = packages.find((pack) => pack.id === values.packageId)
      if (assignedPackage && Number(values.code.match(/^TRKJ ([1-4])/i)?.[1]) !== Number(assignedPackage.term)) return notify('Paket semester tidak sesuai dengan tingkat kelas.')
    }

    const persistLocally = () => {
      setter((rows) => item ? rows.map((row) => row.id === item.id ? result : row) : [result, ...rows])
      if (entity === 'grade') setGrades((rows) => rows.map((row) => row.id === result.id ? { ...result, score: result.score === '' ? null : Number(result.score), status: result.score === '' ? 'Belum diisi' : 'Lengkap' } : row))
      if (entity === 'grade') setKhs((rows) => ({ ...rows, [result.studentId]: 'Perlu diperiksa' }))
      if (entity === 'student') setKhs((rows) => ({ ...rows, [result.id]: 'Perlu diperiksa' }))
      if (entity === 'class') setKrs((rows) => ({ ...rows, [result.id]: item && item.packageId === result.packageId ? rows[result.id] || 'Draf' : 'Draf' }))
      if (entity === 'class') setPackages((rows) => rows.map((pack) => ({
        ...pack,
        classIds: pack.id === result.packageId
          ? [...new Set([...pack.classIds.filter((classId) => classId !== result.id), result.id])]
          : pack.classIds.filter((classId) => classId !== result.id),
      })))
      if (entity === 'schedule') setKrs((rows) => ({ ...rows, ...(item && item.classId !== result.classId ? { [item.classId]: 'Perlu diperbaiki' } : {}), [result.classId]: 'Perlu diperbaiki' }))
      if (entity === 'package') {
        const affectedClassIds = classes.filter((classRow) => classRow.packageId === result.id || result.classIds.includes(classRow.id)).map((classRow) => classRow.id)
        setClasses((rows) => rows.map((classRow) => {
          if (result.classIds.includes(classRow.id)) return { ...classRow, packageId: result.id }
          if (classRow.packageId === result.id) return { ...classRow, packageId: '' }
          return classRow
        }))
        setKrs((rows) => Object.fromEntries(Object.entries(rows).map(([classId, status]) => affectedClassIds.includes(classId) ? [classId, 'Draf'] : [classId, status])))
        setKhs((rows) => Object.fromEntries(Object.entries(rows).map(([studentId, status]) => students.some((student) => student.id === studentId && affectedClassIds.includes(student.classId)) ? [studentId, 'Perlu diperiksa'] : [studentId, status])))
      }
      log(config.activity, `${item ? 'Memperbarui' : 'Menambahkan'} ${config.singular}`)
      setDialog(null)
      notify(`${config.singular} berhasil ${item ? 'diperbarui' : 'ditambahkan'}.`)
    }

    // Helper function for specific error messages
    const formatApiError = (error) => {
      const statusCode = error?.response?.status
      const backendMsg = error?.response?.data?.message
      if (statusCode === 404) return 'Data tidak ditemukan (404)'
      if (statusCode === 409) return `Data sudah ada atau duplikat: ${backendMsg || 'Periksa kembali input'}`
      if (statusCode === 400) return `Input tidak valid: ${backendMsg || 'Periksa format data'}`
      if (statusCode === 500) return 'Server mengalami kesalahan (500)'
      if (statusCode >= 400 && statusCode < 500) return `Galat validasi (${statusCode}): ${backendMsg || 'Periksa input'}`
      if (!error?.response) return 'Tidak dapat terhubung ke server'
      return `${backendMsg || error?.message || 'Terjadi kesalahan'}`
    }

    // API integration for student, teacher, course, class
    if (entity === 'student') {
      const payload = {
        name: values.name,
        email: values.email,
        role: 'mahasiswa',
      }
      if (!item) payload.password = values.password || '12345678'

      const apiCall = item
        ? api.put(`/admin/users/update?id=${item.id}`, { name: values.name, email: values.email, role: 'mahasiswa' })
        : api.post('/admin/users/create', payload)

      apiCall
        .then(() => {
          fetchAll()
          log(config.activity, `${item ? 'Memperbarui' : 'Menambahkan'} ${config.singular}`)
          setDialog(null)
          notify(`${config.singular} berhasil ${item ? 'diperbarui' : 'ditambahkan'}.`)
        })
        .catch((error) => notify(`Gagal menyimpan data: ${formatApiError(error)}`))
      return
    }

    if (entity === 'teacher') {
      const payload = {
        name: values.name,
        email: values.email,
        role: 'dosen',
      }
      if (!item) payload.password = values.password || '12345678'

      const apiCall = item
        ? api.put(`/admin/users/update?id=${item.id}`, { name: values.name, email: values.email, role: 'dosen' })
        : api.post('/admin/users/create', payload)

      apiCall
        .then(() => {
          fetchAll()
          log(config.activity, `${item ? 'Memperbarui' : 'Menambahkan'} ${config.singular}`)
          setDialog(null)
          notify(`${config.singular} berhasil ${item ? 'diperbarui' : 'ditambahkan'}.`)
        })
        .catch((error) => notify(`Gagal menyimpan data: ${formatApiError(error)}`))
      return
    }

    if (entity === 'course') {
      const payload = {
        code: values.code,
        name: values.name,
        sks: values.credits,
        semester: values.term,
      }

      const apiCall = item
        ? api.put(`/courses/update?id=${item.id}`, payload)
        : api.post('/courses', payload)

      apiCall
        .then(() => {
          fetchAll()
          log(config.activity, `${item ? 'Memperbarui' : 'Menambahkan'} ${config.singular}`)
          setDialog(null)
          notify(`${config.singular} berhasil ${item ? 'diperbarui' : 'ditambahkan'}.`)
        })
        .catch((error) => notify(`Gagal menyimpan data: ${formatApiError(error)}`))
      return
    }

    if (entity === 'class') {
      const payload = {
        course_id: values.courseId || '',
        dosen_id: values.teacherId || '',
        name: values.code,
        day: values.day || '',
        start_time: values.start_time || '',
        end_time: values.end_time || '',
        room: values.room || '',
      }

      const apiCall = item
        ? api.put(`/classes/update?id=${item.id}`, payload)
        : api.post('/classes', payload)

      apiCall
        .then(() => {
          fetchAll()
          log(config.activity, `${item ? 'Memperbarui' : 'Menambahkan'} ${config.singular}`)
          setDialog(null)
          notify(`${config.singular} berhasil ${item ? 'diperbarui' : 'ditambahkan'}.`)
        })
        .catch((error) => notify(`Gagal menyimpan data: ${formatApiError(error)}`))
      return
    }

    // For demo-only entities (not in API yet), use local persist
    if (entity === 'ukt' && item) {
      askConfirm('Konfirmasi koreksi UKT demo', 'Perubahan nominal tagihan atau pembayaran hanya memperbarui data simulasi, bukan transaksi yang diterima.', persistLocally, 'Simpan koreksi')
      return
    }
    persistLocally()
  }
  function askConfirm(title, text, action, label = 'Konfirmasi') {
    setDialog({ type: 'confirm', title, text, action, label })
  }
  function updatePublication(kind, target, nextStatus) {
    const label = kind === 'krs' ? 'KRS' : 'KHS'
    if (kind === 'krs') {
      const ready = classKrsReadiness(target)
      if (nextStatus === 'Dipublikasikan' && !ready.ready) return notify(ready.reason)
      askConfirm(`${nextStatus} ${label}?`, `Perubahan status ${label} kelas ${getClassName(classes, target)} hanya terjadi dalam demo frontend.`, () => {
        setKrs((rows) => ({ ...rows, [target]: nextStatus }))
        log(label, `Status ${label} ${getClassName(classes, target)} diubah menjadi ${nextStatus}`)
        setDialog(null)
        notify(`${label} diperbarui dalam demo.`)
      }, 'Ubah status')
    } else {
      const student = students.find((row) => row.id === target)
      const result = student && studentKhs(student)
      if (nextStatus === 'Dipublikasikan' && !result?.complete) return notify('KHS belum dapat dipublikasikan: masih ada nilai wajib yang kosong atau tidak valid.')
      askConfirm(`${nextStatus} KHS?`, `Publikasi KHS untuk ${studentName(students, target)} hanya simulasi frontend. Tidak ada data yang dikirim.`, () => {
        setKhs((rows) => ({ ...rows, [target]: nextStatus }))
        log('KHS', `Status KHS ${studentName(students, target)} diubah menjadi ${nextStatus}`)
        setDialog(null)
        notify('Status KHS demo diperbarui.')
      }, 'Ubah status')
    }
  }
  function removeRecord(entity, row) {
    const names = { student: 'mahasiswa', class: 'kelas', teacher: 'dosen', course: 'mata kuliah', package: 'paket', schedule: 'jadwal', grade: 'nilai', ukt: 'data UKT', attendance: 'rekap kehadiran', case: 'kasus SP', announcement: 'pengumuman', document: 'dokumen' }
    
    // Check for fallback modules first - notify directly without confirmation
    if (FALLBACK_MODULES.includes(entity)) {
      notify('Fitur ini belum tersedia di server')
      return
    }

    // Explicit guard for grade and attendance
    if (entity === 'grade' || entity === 'attendance') {
      notify('Fitur tambah/edit khusus admin belum tersedia')
      return
    }

    askConfirm(`Hapus ${names[entity]}?`, 'Data akan dihapus dari server. Tindakan ini tidak dapat dibatalkan.', () => {
      // Helper for consistent error messages
      const formatDeleteError = (error) => {
        const statusCode = error?.response?.status
        const backendMsg = error?.response?.data?.message
        if (statusCode === 404) return 'Data tidak ditemukan (404)'
        if (statusCode === 409) return `Data masih direferensikan atau terkunci: ${backendMsg || 'Periksa dependensi'}`
        if (statusCode === 400) return `Permintaan tidak valid: ${backendMsg || 'Periksa data'}`
        if (statusCode === 500) return 'Server mengalami kesalahan (500)'
        if (!error?.response) return 'Tidak dapat terhubung ke server'
        return `${backendMsg || error?.message || 'Terjadi kesalahan'}`
      }

      // API integration for student, teacher, course, class
      if (entity === 'student' || entity === 'teacher') {
        api.delete(`/admin/users/delete?id=${row.id}`)
          .then(() => {
            fetchAll()
            log('Data', `Menghapus ${names[entity]}`)
            setDialog(null)
            notify(`${names[entity]} berhasil dihapus.`)
          })
          .catch((error) => notify(`Gagal menghapus data: ${formatDeleteError(error)}`))
        return
      }

      if (entity === 'course') {
        api.delete(`/courses/delete?id=${row.id}`)
          .then(() => {
            fetchAll()
            log('Data', `Menghapus ${names[entity]}`)
            setDialog(null)
            notify(`${names[entity]} berhasil dihapus.`)
          })
          .catch((error) => notify(`Gagal menghapus data: ${formatDeleteError(error)}`))
        return
      }

      if (entity === 'class') {
        // Keep the local check for students
        if (students.some((student) => student.classId === row.id)) {
          setDialog(null)
          return notify('Kelas belum dapat dihapus karena masih memiliki mahasiswa. Pindahkan mahasiswa terlebih dahulu.')
        }

        api.delete(`/classes/delete?id=${row.id}`)
          .then(() => {
            fetchAll()
            log('Data', `Menghapus ${names[entity]}`)
            setDialog(null)
            notify(`${names[entity]} berhasil dihapus.`)
          })
          .catch((error) => notify(`Gagal menghapus data: ${formatDeleteError(error)}`))
        return
      }

      // For demo-only entities, use local removal
      setters[entity]?.((rows) => rows.filter((item) => item.id !== row.id))
      if (entity === 'student') {
        setGrades((rows) => rows.filter((item) => item.studentId !== row.id))
        setUkt((rows) => rows.filter((item) => item.studentId !== row.id))
        setAttendance((rows) => rows.filter((item) => item.studentId !== row.id))
        setCases((rows) => rows.filter((item) => item.studentId !== row.id))
        setDocuments((rows) => rows.filter((item) => item.studentId !== row.id))
        setKhs((rows) => Object.fromEntries(Object.entries(rows).filter(([studentId]) => studentId !== row.id)))
      }
      if (entity === 'class') {
        setSchedules((rows) => rows.filter((item) => item.classId !== row.id))
        setPackages((rows) => rows.map((pack) => ({ ...pack, classIds: pack.classIds.filter((classId) => classId !== row.id) })))
        setKrs((rows) => Object.fromEntries(Object.entries(rows).filter(([classId]) => classId !== row.id)))
      }
      if (entity === 'schedule') setKrs((rows) => ({ ...rows, [row.classId]: 'Perlu diperbaiki' }))
      if (entity === 'teacher') {
        const affectedClasses = schedules.filter((schedule) => schedule.teacherId === row.id).map((schedule) => schedule.classId)
        setSchedules((rows) => rows.filter((item) => item.teacherId !== row.id))
        setKrs((rows) => Object.fromEntries(Object.entries(rows).map(([classId, status]) => affectedClasses.includes(classId) ? [classId, 'Perlu diperbaiki'] : [classId, status])))
      }
      if (entity === 'course') {
        const affectedClasses = schedules.filter((schedule) => schedule.courseId === row.id).map((schedule) => schedule.classId)
        setSchedules((rows) => rows.filter((item) => item.courseId !== row.id))
        setGrades((rows) => rows.filter((item) => item.courseId !== row.id))
        setAttendance((rows) => rows.filter((item) => item.courseId !== row.id))
        setPackages((rows) => rows.map((pack) => ({ ...pack, courseIds: pack.courseIds.filter((courseId) => courseId !== row.id) })))
        setKrs((rows) => Object.fromEntries(Object.entries(rows).map(([classId, status]) => affectedClasses.includes(classId) ? [classId, 'Perlu diperbaiki'] : [classId, status])))
        setKhs((rows) => Object.fromEntries(Object.keys(rows).map((studentId) => [studentId, 'Perlu diperiksa'])))
      }
      if (entity === 'package') {
        setClasses((rows) => rows.map((classRow) => classRow.packageId === row.id ? { ...classRow, packageId: '' } : classRow))
        setKrs((rows) => Object.fromEntries(Object.entries(rows).filter(([classId]) => !classes.some((classRow) => classRow.id === classId && classRow.packageId === row.id))))
      }
      log('Data', `Menghapus ${names[entity]}`)
      setDialog(null)
      notify(`${names[entity]} dihapus.`)
    }, 'Hapus data')
  }
  function exportCsv(rows, filename) {
    const fields = Object.keys(rows[0] || {})
    const escape = (value) => `"${String(value ?? '').replaceAll('"', '""')}"`
    const contents = [fields.map(escape).join(','), ...rows.map((row) => fields.map((field) => escape(Array.isArray(row[field]) ? row[field].join('; ') : row[field])).join(','))].join('\r\n')
    const url = URL.createObjectURL(new Blob(['\uFEFF', contents], { type: 'text/csv;charset=utf-8' }))
    const link = document.createElement('a')
    link.href = url
    link.download = filename
    document.body.appendChild(link)
    link.click()
    link.remove()
    window.setTimeout(() => URL.revokeObjectURL(url), 1000)
    notify('CSV berhasil dibuat dari data simulasi yang sedang ditampilkan.')
  }

  const setters = { student: setStudents, class: setClasses, teacher: setTeachers, course: setCourses, package: setPackages, schedule: setSchedules, grade: setGrades, ukt: setUkt, attendance: setAttendance, case: setCases, announcement: setAnnouncements, document: setDocuments }

  function getRows(key) {
    if (key === 'students') return students.map((row) => ({ ...row, class: getClassName(classes, row.classId), program, nim: row.nim }))
    if (key === 'classes') return classRows
    if (key === 'teachers') return teacherRows
    if (key === 'courses') return courses.map((row) => ({ ...row, package: packages.filter((pack) => pack.courseIds.includes(row.id)).map((pack) => pack.name).join(', ') || 'Belum dipaketkan', teacher: teacherName(teachers, schedules.find((schedule) => schedule.courseId === row.id)?.teacherId) }))
    if (key === 'packages') return packageRows
    if (key === 'schedules') return scheduleRows
    if (key === 'krs') return classes.map((row) => {
      const pack = packageById(row.packageId)
      const ready = classKrsReadiness(row.id)
      return { id: row.id, class: row.code, semester: row.semester, package: pack?.name || '—', courses: pack?.courseIds.length || 0, credits: pack?.courseIds.reduce((sum, courseId) => sum + (courses.find((course) => course.id === courseId)?.credits || 0), 0) || 0, status: krs[row.id] || 'Draf', readiness: ready.reason }
    })
    if (key === 'grades') return gradeRows
    if (key === 'khs') return khsRows
    if (key === 'ukt') return uktRows
    if (key === 'attendance') return attendanceRows
    if (key === 'cases') return caseRows
    if (key === 'documents') return documents.map((row) => ({ ...row, student: studentName(students, row.studentId) }))
    if (key === 'announcements') return announcements
    if (key === 'activities') return activities
    if (key === 'reports') return activeReportRows
    return []
  }

  const reportRows = [
    ...classRows.map((row) => ({ kategori: 'Kelas', rincian: row.code, jumlah: row.count })),
    { kategori: 'Mahasiswa aktif', rincian: 'TRKJ', jumlah: activeStudents },
    { kategori: 'UKT tunggakan', rincian: 'Total tunggakan', jumlah: tuitionDebt },
    { kategori: 'Kehadiran', rincian: 'Di bawah ambang demo 75%', jumlah: attendanceIssues },
    { kategori: 'Surat peringatan', rincian: 'Kasus terbuka', jumlah: cases.filter((row) => row.status !== 'Ditutup').length },
    { kategori: 'Paket', rincian: 'Paket semester', jumlah: packages.length },
    { kategori: 'Jadwal', rincian: 'Jadwal bentrok', jumlah: scheduleConflicts },
    { kategori: 'KRS', rincian: 'Belum dipublikasikan', jumlah: pendingKrs },
    { kategori: 'Nilai', rincian: 'Belum lengkap', jumlah: incompleteGrades },
    { kategori: 'KHS', rincian: 'Belum dipublikasikan', jumlah: pendingKhs },
  ]
  const activeReportRows = selectedSemester === currentSemester ? reportRows : reportRows.map((row) => ({ ...row, jumlah: 0 }))

  const columns = {
    students: [['nim', 'NIM'], ['name', 'Nama'], ['class', 'Kelas'], ['semester', 'Semester'], ['status', 'Status']],
    classes: [['code', 'Kode kelas'], ['year', 'Angkatan'], ['count', 'Jumlah mahasiswa'], ['semester', 'Semester aktif'], ['package', 'Paket'], ['status', 'Status']],
    teachers: [['nidn', 'NIDN'], ['name', 'Nama dosen'], ['expertise', 'Bidang keahlian'], ['courses', 'Mata kuliah diampu'], ['classes', 'Kelas'], ['load', 'Beban mengajar'], ['status', 'Status']],
    courses: [['code', 'Kode'], ['name', 'Mata kuliah'], ['credits', 'SKS'], ['term', 'Semester'], ['type', 'Jenis'], ['teacher', 'Dosen pengampu'], ['package', 'Paket']],
    packages: [['name', 'Nama paket'], ['term', 'Semester'], ['courses', 'Mata kuliah'], ['credits', 'Total SKS'], ['classes', 'Kelas'], ['status', 'Status']],
    schedules: [['semester', 'Semester'], ['class', 'Kelas'], ['course', 'Mata kuliah'], ['teacher', 'Dosen'], ['day', 'Hari'], ['start', 'Mulai'], ['end', 'Selesai'], ['room', 'Ruang'], ['conflict', 'Validasi']],
    krs: [['class', 'Kelas'], ['semester', 'Semester'], ['package', 'Paket'], ['courses', 'Jumlah MK'], ['credits', 'Total SKS'], ['readiness', 'Kelengkapan'], ['status', 'Status KRS']],
    grades: [['nim', 'NIM'], ['student', 'Mahasiswa'], ['class', 'Kelas'], ['course', 'Mata kuliah'], ['semester', 'Semester'], ['score', 'Nilai angka'], ['letter', 'Huruf'], ['status', 'Status']],
    khs: [['nim', 'NIM'], ['student', 'Mahasiswa'], ['class', 'Kelas'], ['semester', 'Semester'], ['credits', 'SKS'], ['ips', 'IPS'], ['status', 'Status KHS']],
    ukt: [['nim', 'NIM'], ['student', 'Mahasiswa'], ['class', 'Kelas'], ['semester', 'Semester'], ['billed', 'Tagihan'], ['paid', 'Dibayar'], ['debt', 'Tunggakan'], ['dueStatus', 'Jatuh tempo'], ['status', 'Status']],
    attendance: [['nim', 'NIM'], ['student', 'Mahasiswa'], ['class', 'Kelas'], ['course', 'Mata kuliah'], ['present', 'Hadir'], ['permit', 'Izin'], ['sick', 'Sakit'], ['absent', 'Alpa'], ['percentage', 'Kehadiran %'], ['status', 'Tindak lanjut']],
    cases: [['nim', 'NIM'], ['student', 'Mahasiswa'], ['class', 'Kelas'], ['level', 'Jenjang SP'], ['reason', 'Dasar/catatan'], ['followup', 'Tindak lanjut'], ['status', 'Status']],
    documents: [['type', 'Jenis dokumen'], ['student', 'Mahasiswa'], ['semester', 'Semester'], ['status', 'Status'], ['date', 'Tanggal']],
    announcements: [['title', 'Judul'], ['category', 'Kategori'], ['start', 'Mulai'], ['end', 'Berakhir'], ['status', 'Status']],
    activities: [['time', 'Waktu'], ['category', 'Kategori'], ['message', 'Aktivitas'], ['status', 'Status']],
    reports: [['kategori', 'Kategori'], ['rincian', 'Rincian'], ['jumlah', 'Jumlah']],
  }
  const pageEntity = { students: 'student', classes: 'class', teachers: 'teacher', courses: 'course', packages: 'package', schedules: 'schedule', grades: 'grade', ukt: 'ukt', attendance: 'attendance', cases: 'case', documents: 'document', announcements: 'announcement' }

  function rowsForPage() {
    const all = getRows(page)
    if (page === 'reports') return all.filter((row) => !reportCategory || row.kategori === reportCategory)
    return all.filter((row) => {
      if (['krs', 'khs', 'grades', 'ukt', 'attendance'].includes(page) && row.semester && row.semester !== selectedSemester) return false
      const text = Object.values(row).join(' ').toLowerCase()
      if (query && !text.includes(query.toLowerCase())) return false
      return Object.entries(filters).every(([key, value]) => !value || String(row[key] ?? '') === value)
    })
  }
  const visibleRows = rowsForPage()
  if (sort.key) visibleRows.sort((a, b) => String(a[sort.key] ?? '').localeCompare(String(b[sort.key] ?? ''), 'id', { numeric: true }) * (sort.direction === 'asc' ? 1 : -1))
  const pageSize = 8
  const totalPages = Math.max(1, Math.ceil(visibleRows.length / pageSize))
  const currentRows = visibleRows.slice((Math.min(pageNumber, totalPages) - 1) * pageSize, Math.min(pageNumber, totalPages) * pageSize)

  const pageConfig = {
    student: { singular: 'mahasiswa', activity: 'Mahasiswa', fields: [['nim', 'NIM', 'text'], ['name', 'Nama mahasiswa', 'text'], ['classId', 'Kelas', 'select', classes.map((row) => [row.id, row.code])], ['semester', 'Semester', 'select', semesters.map((row) => [row, row])], ['status', 'Status mahasiswa', 'select', ['Aktif', 'Cuti', 'Nonaktif'].map((row) => [row, row])]] },
    class: { singular: 'kelas', activity: 'Kelas', fields: [['code', 'Kode kelas', 'select', classNames.map((row) => [row, row])], ['year', 'Angkatan', 'text'], ['semester', 'Semester aktif', 'select', semesters.map((row) => [row, row])], ['packageId', 'Paket semester', 'select', packages.map((row) => [row.id, row.name])], ['status', 'Status kelas', 'select', ['Aktif', 'Nonaktif'].map((row) => [row, row])]] },
    teacher: { singular: 'dosen', activity: 'Dosen', fields: [['nidn', 'NIDN demo', 'text'], ['name', 'Nama dosen', 'text'], ['expertise', 'Bidang keahlian', 'text'], ['status', 'Status', 'select', ['Aktif', 'Nonaktif'].map((row) => [row, row])]] },
    course: { singular: 'mata kuliah', activity: 'Paket', fields: [['code', 'Kode mata kuliah', 'text'], ['name', 'Nama mata kuliah', 'text'], ['credits', 'Jumlah SKS', 'number'], ['term', 'Semester rekomendasi', 'number'], ['type', 'Jenis mata kuliah', 'select', ['Wajib', 'Praktik', 'Teori'].map((row) => [row, row])], ['status', 'Status', 'select', ['Aktif', 'Nonaktif'].map((row) => [row, row])]] },
    package: { singular: 'paket semester', activity: 'Paket', fields: [['name', 'Nama paket', 'text'], ['term', 'Semester', 'number'], ['status', 'Status paket', 'select', ['Draf', 'Siap'].map((row) => [row, row])]] },
    schedule: { singular: 'jadwal kuliah', activity: 'Jadwal', fields: [['semester', 'Semester', 'select', semesters.map((row) => [row, row])], ['classId', 'Kelas', 'select', classes.map((row) => [row.id, row.code])], ['courseId', 'Mata kuliah', 'select', courses.map((row) => [row.id, `${row.code} · ${row.name}`])], ['teacherId', 'Dosen', 'select', teachers.map((row) => [row.id, row.name])], ['day', 'Hari', 'select', ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'].map((row) => [row, row])], ['start', 'Jam mulai', 'time'], ['end', 'Jam selesai', 'time'], ['room', 'Ruang', 'text']] },
    grade: { singular: 'nilai', activity: 'Nilai', fields: [['studentId', 'Mahasiswa', 'select', students.map((row) => [row.id, `${row.nim} · ${row.name}`])], ['courseId', 'Mata kuliah', 'select', courses.map((row) => [row.id, row.name])], ['semester', 'Semester', 'select', semesters.map((row) => [row, row])], ['score', 'Nilai angka (0–100)', 'number'], ['status', 'Status', 'select', ['Lengkap', 'Perlu diperiksa'].map((row) => [row, row])]] },
    ukt: { singular: 'data UKT', activity: 'UKT', fields: [['studentId', 'Mahasiswa', 'select', students.map((row) => [row.id, `${row.nim} · ${row.name}`])], ['semester', 'Semester', 'select', semesters.map((row) => [row, row])], ['billed', 'Nominal tagihan demo', 'number'], ['paid', 'Nominal dibayar demo', 'number'], ['due', 'Tanggal jatuh tempo', 'date']] },
    attendance: { singular: 'rekap kehadiran', activity: 'Kehadiran', fields: [['studentId', 'Mahasiswa', 'select', students.map((row) => [row.id, `${row.nim} · ${row.name}`])], ['courseId', 'Mata kuliah', 'select', courses.map((row) => [row.id, row.name])], ['semester', 'Semester', 'select', semesters.map((row) => [row, row])], ['present', 'Jumlah hadir', 'number'], ['permit', 'Izin', 'number'], ['sick', 'Sakit', 'number'], ['absent', 'Alpa', 'number'], ['meetings', 'Jumlah pertemuan', 'number']] },
    case: { singular: 'kasus SP', activity: 'SP', fields: [['studentId', 'Mahasiswa', 'select', students.map((row) => [row.id, `${row.nim} · ${row.name}`])], ['level', 'Jenjang', 'select', ['SP 1', 'SP 2', 'SP 3'].map((row) => [row, row])], ['reason', 'Dasar/catatan', 'text'], ['followup', 'Riwayat tindak lanjut', 'text'], ['status', 'Status', 'select', ['Draf', 'Diajukan', 'Perlu diperiksa', 'Diterbitkan (simulasi)', 'Ditutup'].map((row) => [row, row])]] },
    document: { singular: 'dokumen', activity: 'Dokumen', fields: [['type', 'Jenis dokumen', 'select', ['KRS', 'KHS', 'Surat Peringatan', 'Dokumen pendukung'].map((row) => [row, row])], ['studentId', 'Mahasiswa', 'select', students.map((row) => [row.id, `${row.nim} · ${row.name}`])], ['semester', 'Semester', 'select', semesters.map((row) => [row, row])], ['status', 'Status', 'select', ['Lengkap', 'Memerlukan perbaikan', 'Draf'].map((row) => [row, row])], ['date', 'Tanggal demo', 'date']] },
    announcement: { singular: 'pengumuman', activity: 'Pengumuman', fields: [['title', 'Judul', 'text'], ['category', 'Kategori', 'select', ['Akademik', 'Administrasi', 'Sistem'].map((row) => [row, row])], ['start', 'Tanggal mulai', 'date'], ['end', 'Tanggal akhir', 'date'], ['status', 'Status', 'select', ['Draf', 'Aktif', 'Berakhir'].map((row) => [row, row])], ['content', 'Isi pengumuman', 'textarea']] },
  }

  function detailsFor(row) {
    if (page === 'students') {
      const student = students.find((item) => item.id === row.id)
      const khsRow = studentKhs(student)
      const tuition = uktRows.find((item) => item.studentId === student.id)
      const attend = attendanceRows.find((item) => item.studentId === student.id)
      return [['Program studi', program], ['UKT demo', tuition ? `${tuition.status} · ${fmtMoney(tuition.debt)} tunggakan` : 'Belum ada data'], ['Kehadiran', attend ? `${attend.percentage}% · ${attend.status}` : 'Belum ada data'], ['KRS paket', krs[student.classId] || 'Draf'], ['KHS', khsRow.status], ['IPS demo', khsRow.ips]]
    }
    if (page === 'teachers') return [['Jadwal aktif', schedules.filter((item) => item.teacherId === row.id).map((item) => `${item.day} ${item.start} · ${getClassName(classes, item.classId)}`).join('; ') || 'Belum ditugaskan'], ['Beban mengajar demo', `${row.load} sesi terjadwal`]]
    if (page === 'classes') return [['Anggota kelas', students.filter((student) => student.classId === row.id).map((student) => `${student.nim} · ${student.name}`).join('; ') || 'Belum ada mahasiswa'], ['Paket mata kuliah', row.package], ['Jadwal terkait', schedules.filter((schedule) => schedule.classId === row.id).map((schedule) => `${schedule.day} ${schedule.start} · ${courseName(courses, schedule.courseId)}`).join('; ') || 'Belum ada jadwal']]
    if (page === 'packages') return [['Mata kuliah', row.courses], ['Total SKS', row.credits], ['Kelas terkait', row.classes], ['Kelengkapan paket', row.courseIds.every((courseId) => courses.some((item) => item.id === courseId)) ? 'Valid' : 'Ada mata kuliah tidak tersedia']]
    if (page === 'schedules') return [['Validasi bentrok', row.conflict], ['Durasi', `${row.start}–${row.end}`], ['Kelas', row.class], ['Dosen', row.teacher]]
    if (page === 'krs') {
      const classRow = classes.find((item) => item.id === row.id)
      const pack = classRow && packageById(classRow.packageId)
      const courseDetails = (pack?.courseIds || []).map((courseId) => {
        const course = courses.find((item) => item.id === courseId)
        const schedule = schedules.find((item) => item.classId === row.id && item.courseId === courseId && item.semester === row.semester)
        return `${course?.code || '—'} ${course?.name || 'Mata kuliah'} · ${course?.credits || 0} SKS · ${schedule ? `${schedule.day} ${schedule.start}–${schedule.end}, ${schedule.room}, ${teacherName(teachers, schedule.teacherId)}` : 'Jadwal belum lengkap'}`
      })
      const roster = students.filter((student) => student.classId === row.id).map((student) => `${student.nim} · ${student.name}`)
      return [['Status kesiapan', row.readiness], ['Mahasiswa kelas', roster.join('; ') || 'Belum ada mahasiswa'], ['Daftar paket dan jadwal', courseDetails.join('; ') || 'Paket kosong'], ['Total SKS', row.credits], ['Publikasi demo', row.status]]
    }
    if (page === 'grades') return [['Rentang nilai demo', Number.isFinite(row.score) ? `${row.score} · ${row.letter}` : 'Nilai belum tersedia'], ['Status kelengkapan', row.status]]
    if (page === 'khs') return [['Rekap mata kuliah', row.entries.map((entry) => `${courseName(courses, entry.courseId)}: ${Number.isFinite(entry.score) ? `${entry.score} (${letterGrade(entry.score)[0]})` : 'nilai belum diisi'}`).join('; ') || 'Belum ada nilai'], ['IPS semester', row.ips], ['SKS terhitung', row.complete ? row.credits : 'Belum lengkap'], ['Nilai wajib tersedia', `${row.entries.filter((entry) => Number.isFinite(entry.score)).length} dari ${row.required.length}`], ['Asumsi', 'IPS berbobot SKS; nilai huruf A≥85, AB≥80, B≥75, BC≥70, C≥65, D≥50, E<50. IPK tidak dihitung karena data lintas semester belum lengkap.']]
    if (page === 'ukt') return [['Tagihan demo', fmtMoney(row.billed)], ['Dibayar (simulasi)', fmtMoney(row.paid)], ['Tunggakan demo', fmtMoney(row.debt)], ['Jatuh tempo demo', fmtDate(row.due)]]
    if (page === 'attendance') return [['Pertemuan tersedia', row.meetings], ['Hadir', row.present], ['Izin / sakit / alpa', `${row.permit} / ${row.sick} / ${row.absent}`], ['Ambang tindak lanjut demo', '75% (bukan kebijakan resmi)']]
    return Object.entries(row).filter(([key]) => key !== 'id').map(([key, value]) => [key, typeof value === 'object' ? JSON.stringify(value) : String(value ?? '—')])
  }
  function openEdit(row) {
    const entity = pageEntity[page]
    if (entity) setDialog({ type: 'form', entity, item: row })
  }
  function openAdd() {
    const entity = pageEntity[page]
    if (entity) setDialog({ type: 'form', entity, item: null })
  }
  function rowAction(row) {
    if (page === 'krs') {
      const next = row.status === 'Dipublikasikan' ? 'Draf' : 'Dipublikasikan'
      return <button className="admin-button admin-button--secondary admin-button--small" onClick={() => updatePublication('krs', row.id, next)}>{next === 'Draf' ? 'Batalkan publikasi' : 'Publikasikan'}</button>
    }
    if (page === 'khs') {
      const next = row.status === 'Dipublikasikan' ? 'Draf' : 'Dipublikasikan'
      return <button className="admin-button admin-button--secondary admin-button--small" onClick={() => updatePublication('khs', row.id, next)}>{next === 'Draf' ? 'Batalkan publikasi' : 'Publikasikan'}</button>
    }
    if (page === 'cases') return <select className="admin-inline-select" aria-label={`Status kasus ${row.student}`} value={row.status} onChange={(event) => {
      const status = event.target.value
      if (status === 'Diterbitkan (simulasi)') askConfirm('Terbitkan SP demo?', 'SP hanya pratinjau simulasi dan bukan surat resmi.', () => { setCases((rows) => rows.map((item) => item.id === row.id ? { ...item, status } : item)); log('SP', `Status kasus ${row.id} diubah menjadi ${status}`); setDialog(null) }, 'Terbitkan demo')
      else {
        setCases((rows) => rows.map((item) => item.id === row.id ? { ...item, status } : item))
        log('SP', `Status kasus ${row.id} diubah menjadi ${status}`)
        notify('Status kasus SP demo diperbarui.')
      }
    }}>{['Draf', 'Diajukan', 'Perlu diperiksa', 'Diterbitkan (simulasi)', 'Ditutup'].map((status) => <option key={status}>{status}</option>)}</select>
    if (page === 'announcements') return <select className="admin-inline-select" aria-label={`Status pengumuman ${row.title}`} value={row.status} onChange={(event) => askConfirm('Ubah status pengumuman?', 'Perubahan hanya simulasi frontend.', () => { setAnnouncements((rows) => rows.map((item) => item.id === row.id ? { ...item, status: event.target.value } : item)); log('Pengumuman', `${row.title} menjadi ${event.target.value}`); setDialog(null) }, 'Simpan status')}>{['Draf', 'Aktif', 'Berakhir'].map((status) => <option key={status}>{status}</option>)}</select>
    if (page === 'ukt') return <button className="admin-row-action" title="Koreksi pembayaran demo" onClick={() => setDialog({ type: 'form', entity: 'ukt', item: row })}><Icon name="wallet" size={15} /></button>
    return null
  }

  function dashboard() {
    const semesterStudents = students.filter((student) => student.semester === selectedSemester)
    const semesterClasses = classRows.filter((classRow) => classRow.semester === selectedSemester)
    const semesterActiveStudents = semesterStudents.filter((student) => student.status === 'Aktif').length
    const semesterUkt = ukt.filter((row) => row.semester === selectedSemester)
    const semesterDebt = semesterUkt.reduce((sum, row) => sum + Math.max(0, row.billed - row.paid), 0)
    const semesterAttendanceIssues = attendanceRows.filter((row) => row.semester === selectedSemester && row.status === 'Perlu tindak lanjut').length
    const semesterScheduleConflicts = scheduleRows.filter((row) => row.semester === selectedSemester && row.conflict === 'Bentrok').length
    const semesterMissingGrades = semesterStudents.filter((student) => student.status === 'Aktif').reduce((total, student) => {
      const pack = packageById(classes.find((row) => row.id === student.classId)?.packageId)
      return total + (pack?.courseIds || []).filter((courseId) => !grades.some((grade) => grade.studentId === student.id && grade.courseId === courseId && grade.semester === selectedSemester && Number.isFinite(grade.score) && grade.score >= 0 && grade.score <= 100)).length
    }, 0)
    const semesterPendingKrs = semesterClasses.filter((classRow) => krs[classRow.id] !== 'Dipublikasikan').length
    const semesterPendingKhs = semesterStudents.filter((student) => studentKhs(student).status !== 'Dipublikasikan').length
    const unassignedTeachers = teacherRows.filter((teacher) => teacher.load === 0).length
    const teacherConflictIds = new Set(semesterScheduleConflicts ? scheduleRows.filter((schedule) => schedule.semester === selectedSemester && schedule.conflict === 'Bentrok').flatMap((schedule) => schedules.filter((other) => conflicts(schedule, schedule.id).some((conflict) => conflict.id === other.id)).map((other) => other.teacherId)) : [])
    const todo = [
      [semesterScheduleConflicts, 'Bentrok jadwal perlu diperbaiki', 'schedules'],
      [teacherConflictIds.size, 'Dosen memiliki jadwal bentrok', 'teachers'],
      [unassignedTeachers, 'Dosen belum mendapat penugasan', 'teachers'],
      [semesterMissingGrades, 'Nilai belum lengkap', 'grades'],
      [semesterUkt.filter((row) => row.paid < row.billed).length, 'Mahasiswa memiliki tunggakan UKT demo', 'ukt'],
      [semesterPendingKrs, 'KRS paket menunggu pemeriksaan/publikasi', 'krs'],
      [semesterPendingKhs, 'KHS belum dipublikasikan', 'khs'],
    ]
    const classBars = semesterClasses.map((row) => ({ label: row.code, count: students.filter((student) => student.classId === row.id && student.semester === selectedSemester).length }))
    const maxCount = Math.max(1, ...classBars.map((row) => row.count))
    return <>
      <section className="admin-welcome"><div><span className="admin-eyebrow">PANEL ADMINISTRASI AKADEMIK · TRKJ</span><h1>Ringkasan Akademik</h1><p>Pemantauan akademik dan administrasi untuk satu program studi.</p></div><label className="admin-semester-select">Semester<select value={selectedSemester} onChange={(event) => setSelectedSemester(event.target.value)}>{semesters.map((semester) => <option key={semester}>{semester}</option>)}</select></label></section>
      <div className="admin-academic-stats">
        <Stat title="Mahasiswa aktif" value={semesterActiveStudents} note={`${semesterStudents.length} terdata`} icon="users" />
        <Stat title="Kelas" value={semesterClasses.length} note="TRKJ" icon="grid" />
        <Stat title="Dosen" value={teachers.length} note="Data demo" icon="users" />
        <Stat title="Tunggakan UKT" value={fmtMoney(semesterDebt)} note={`${semesterUkt.filter((row) => row.paid < row.billed).length} mahasiswa`} icon="wallet" />
        <Stat title="Masalah kehadiran" value={semesterAttendanceIssues} note="Ambang demo 75%" icon="check" />
        <Stat title="Jadwal bentrok" value={semesterScheduleConflicts} note="Hitung otomatis demo" icon="clock" />
        <Stat title="Nilai belum lengkap" value={semesterMissingGrades} note="Wajib diperiksa" icon="chart" />
        <Stat title="KRS / KHS pending" value={`${semesterPendingKrs} / ${semesterPendingKhs}`} note="Belum dipublikasikan" icon="file" />
      </div>
      <div className="admin-dashboard-grid">
        <section className="admin-panel"><PanelHeading title="Distribusi mahasiswa per kelas" subtitle="Jumlah berdasarkan data mahasiswa demo" /><div className="admin-hbar-chart">{classBars.map((row) => <div className="admin-hbar-row" key={row.label}><span>{row.label}</span><div className="admin-hbar-track"><i style={{ width: `${Math.max(7, row.count / maxCount * 100)}%` }} /></div><strong>{row.count}</strong></div>)}</div><p className="admin-chart-footnote">Satu program studi: {program}</p></section>
        <section className="admin-panel"><PanelHeading title="Status administrasi" subtitle="Berdasarkan state demo saat ini" /><div className="admin-admin-status"><p><span>UKT belum lunas</span><strong>{tuitionUnpaid} mahasiswa</strong></p><p><span>KRS belum dipublikasikan</span><strong>{pendingKrs} kelas</strong></p><p><span>KHS belum dipublikasikan</span><strong>{pendingKhs} mahasiswa</strong></p><p><span>Jadwal bentrok</span><strong>{scheduleConflicts}</strong></p></div></section>
        <section className="admin-panel"><PanelHeading title="Perlu ditindaklanjuti" subtitle="Temuan dihitung dari data demo" /><div className="admin-task-list">{todo.filter(([count]) => count > 0).map(([count, text, destination]) => <button key={text} onClick={() => navigate(destination)}><span className="admin-task-count">{count}</span><strong>{text}</strong><Icon name="chevron" size={15} /></button>)}{todo.every(([count]) => count === 0) && <p className="admin-chart-footnote">Tidak ada tindak lanjut demo.</p>}</div></section>
        <section className="admin-panel"><PanelHeading title="Aktivitas terkini" subtitle="Tercatat lokal selama sesi ini" action={<button className="admin-text-button" onClick={() => navigate('activities')}>Lihat semua</button>} /><ActivityList items={activities.slice(0, 4)} /></section>
      </div>
    </>
  }

  function reports() {
    const rows = rowsForPage()
    const categories = [...new Set(activeReportRows.map((row) => row.kategori))]
    return <><PageHeading title={titles.reports} subtitle={`Rekap terhitung dari data demo · semester ${selectedSemester}`} actions={<><button className="admin-button admin-button--secondary" onClick={() => window.print()}><Icon name="file" />Cetak</button><button className="admin-button admin-button--primary" onClick={() => exportCsv(rows, 'rekap-akademik-trkj-demo.csv')}><Icon name="download" />Ekspor CSV</button></>} /><div className="admin-report-filters"><label>Semester laporan<select value={selectedSemester} onChange={(event) => { setSelectedSemester(event.target.value); setReportCategory('') }}>{semesters.map((semester) => <option key={semester}>{semester}</option>)}</select></label><label>Kategori<select value={reportCategory} onChange={(event) => setReportCategory(event.target.value)}><option value="">Semua kategori</option>{categories.map((category) => <option key={category}>{category}</option>)}</select></label></div><div className="admin-panel admin-report-panel"><PanelHeading title="Rekapitulasi akademik" subtitle="Tidak memuat data kontak pribadi." /><Table columns={columns.reports} rows={rows} onDetail={(row) => setDialog({ type: 'detail', title: row.kategori, row })} /></div></>
  }

  function settings() {
    return <><PageHeading title={titles.settings} subtitle="Preferensi lokal dashboard demo ini." /><div className="admin-settings-grid"><section className="admin-panel"><PanelHeading title="Profil tampilan" subtitle="Identitas contoh, bukan akun autentikasi." /><div className="admin-profile-card"><span className="admin-avatar admin-avatar--large">AD</span><div><strong>Admin Demo</strong><span>Administrasi akademik TRKJ</span><small>Data tidak terhubung ke server.</small></div></div></section><section className="admin-panel"><PanelHeading title="Preferensi tampilan" subtitle="Berlaku selama sesi ini." /><Preference title="Tabel lebih rapat" checked={compact} onChange={() => setCompact((value) => !value)} /></section><section className="admin-panel admin-settings-wide"><PanelHeading title="Aturan demo akademik" subtitle="Asumsi transparan, bukan kebijakan resmi kampus." /><p className="admin-settings-footnote">Ambang tindak lanjut kehadiran: 75%. IPS dihitung sebagai jumlah (bobot nilai huruf × SKS) dibagi total SKS, hanya saat nilai seluruh mata kuliah paket lengkap dan valid. Skema demo: A ≥ 85, AB ≥ 80, B ≥ 75, BC ≥ 70, C ≥ 65, D ≥ 50, E &lt; 50. IPK tidak ditampilkan karena data lintas semester belum tersedia. UKT, KRS, KHS, SP, pembayaran, publikasi, dan dokumen seluruhnya simulasi frontend.</p></section></div></>
  }

  function handleImport(file) {
    if (!file) return
    file.text().then((text) => {
      const lines = text.split(/\r?\n/).filter(Boolean)
      const headers = lines.length ? lines[0].replace(/^\uFEFF/, '').split(',').map((header) => header.trim().toLowerCase()) : []
      if (headers.join(',') !== 'nim,kode_mata_kuliah,nilai') {
        setImportResult({ imported: 0, invalid: ['Header wajib: nim,kode_mata_kuliah,nilai.'] })
        return
      }
      const parse = (line) => {
        const result = []
        let token = ''
        let quoted = false
        for (let index = 0; index < line.length; index += 1) {
          const char = line[index]
          if (char === '"' && quoted && line[index + 1] === '"') { token += '"'; index += 1 }
          else if (char === '"') quoted = !quoted
          else if (char === ',' && !quoted) { result.push(token.trim()); token = '' }
          else token += char
        }
        result.push(token.trim())
        return result
      }
      const records = lines.slice(1).map(parse)
      let imported = 0
      const invalid = []
      const nextGrades = [...grades]
      records.forEach((record, index) => {
        const [nim, code, score] = record
        const student = students.find((row) => row.nim === nim)
        const course = courses.find((row) => row.code === code)
        const value = Number(score)
        const grade = nextGrades.find((row) => row.studentId === student?.id && row.courseId === course?.id)
        if (!student || !course || !Number.isFinite(value) || value < 0 || value > 100 || !grade) invalid.push(`Baris ${index + 2}: mahasiswa/mata kuliah tidak cocok atau nilai tidak valid.`)
        else {
          grade.score = value
          grade.status = 'Lengkap'
          imported += 1
        }
      })
      setGrades(nextGrades)
      setImportResult({ imported, invalid })
      if (imported) log('Nilai', `${imported} nilai demo diimpor dari CSV`)
      notify(`${imported} baris valid diimpor; ${invalid.length} baris perlu diperiksa.`)
    }).catch(() => notify('Berkas CSV tidak dapat dibaca.'))
  }

  function renderTablePage() {
    const rows = rowsForPage()
    const entity = pageEntity[page]
    const filterKeys = [...new Set(rows.flatMap((row) => ['class', 'semester', 'status', 'category', 'day', 'teacher', 'course'].filter((key) => row[key] !== undefined)))]
    if (page === 'classes') filterKeys.push('code')
    const report = page === 'reports'
    return <>
      <PageHeading title={page === 'packages' ? 'Paket Semester' : page === 'cases' ? 'Surat Peringatan (SP)' : titles[page]} subtitle={page === 'packages' ? 'Susun paket mata kuliah tetap per semester dan kelas TRKJ.' : pageDescriptions[page]} actions={<div className="admin-page-actions">{page === 'courses' && <button className="admin-button admin-button--secondary" onClick={() => navigate('packages')}>Kelola paket semester</button>}{page === 'packages' && <button className="admin-button admin-button--secondary" onClick={() => navigate('courses')}>Katalog mata kuliah</button>}{page === 'grades' && <label className="admin-button admin-button--secondary admin-file-button"><Icon name="upload" />Impor CSV<input type="file" accept=".csv,text/csv" onChange={(event) => handleImport(event.target.files?.[0])} /></label>}{entity && <button className="admin-button admin-button--primary" onClick={openAdd}><Icon name="plus" />Tambah data</button>}{report && <button className="admin-button admin-button--primary" onClick={() => exportCsv(rows, 'rekap-akademik-trkj-demo.csv')}>Ekspor CSV</button>}</div>} />
      {page === 'attendance' && <div className="admin-page-tabs"><button className="is-active" onClick={() => navigate('attendance')}>Rekap kehadiran</button><button onClick={() => navigate('cases')}>Surat Peringatan (SP)</button></div>}
      {page === 'cases' && <div className="admin-page-tabs"><button onClick={() => navigate('attendance')}>Rekap kehadiran</button><button className="is-active" onClick={() => navigate('cases')}>Surat Peringatan (SP)</button></div>}
      {page === 'schedules' && <div className={`admin-relation-notice${scheduleConflicts ? '' : ' admin-notice--ok'}`}><Icon name="clock" /><span><strong>{scheduleConflicts} bentrok terdeteksi otomatis</strong><small>Diperiksa terhadap dosen, ruang, kelas, hari, dan rentang waktu.</small></span></div>}
      {page === 'krs' && <div className="admin-relation-notice"><Icon name="file" /><span><strong>KRS mengikuti paket kelas, bukan pemilihan mata kuliah individual.</strong><small>KRS tidak dikirim ke aplikasi mobile. Jadwal belum lengkap menghalangi publikasi.</small></span></div>}
      {page === 'khs' && <div className="admin-relation-notice"><Icon name="chart" /><span><strong>IPS hanya tersedia bila seluruh nilai wajib valid.</strong><small>IPK tidak dihitung karena data semester sebelumnya tidak lengkap.</small></span></div>}
      {page === 'attendance' && <div className="admin-relation-notice"><Icon name="check" /><span><strong>Ambang peringatan demo: 75% kehadiran.</strong><small>Nilai ini ilustratif, bukan kebijakan resmi kampus.</small></span></div>}
      {page === 'ukt' && <div className="admin-report-cards"><Stat title="Tagihan demo" value={fmtMoney(ukt.filter((row) => row.semester === selectedSemester).reduce((sum, row) => sum + row.billed, 0))} icon="wallet" /><Stat title="Dibayar (simulasi)" value={fmtMoney(ukt.filter((row) => row.semester === selectedSemester).reduce((sum, row) => sum + row.paid, 0))} icon="check" /><Stat title="Total tunggakan" value={fmtMoney(ukt.filter((row) => row.semester === selectedSemester).reduce((sum, row) => sum + Math.max(0, row.billed - row.paid), 0))} icon="chart" /></div>}
      {importResult && page === 'grades' && <div className="admin-import-result" role="status"><strong>{importResult.imported} baris valid diimpor.</strong>{importResult.invalid.map((message) => <span key={message}>{message}</span>)}<button onClick={() => setImportResult(null)}>Tutup</button></div>}
      <section className="admin-panel admin-table-panel">
        <div className="admin-table-toolbar"><label className="admin-search"><Icon name="search" /><input aria-label="Cari data" placeholder="Cari pada data yang ditampilkan…" value={query} onChange={(event) => { setQuery(event.target.value); setPageNumber(1) }} /></label><div className="admin-filter-group">{filterKeys.map((key) => <select key={key} aria-label={`Filter ${filterLabels[key] || key}`} value={filters[key] || ''} onChange={(event) => { setFilters((current) => ({ ...current, [key]: event.target.value })); setPageNumber(1) }}><option value="">Semua {filterLabels[key] || key}</option>{(key === 'semester' ? semesters : key === 'class' || (page === 'classes' && key === 'code') ? classNames : [...new Set(rows.map((row) => row[key]).filter(Boolean))]).map((value) => <option key={value}>{value}</option>)}</select>)}{(query || Object.values(filters).some(Boolean)) && <button className="admin-reset-button" onClick={() => { setQuery(''); setFilters({}); setPageNumber(1) }}>Reset</button>}</div></div>
        {['krs', 'khs', 'grades', 'ukt', 'attendance'].includes(page) && <div className="admin-table-toolbar"><label className="admin-filter-label">Filter semester<select value={selectedSemester} onChange={(event) => { setSelectedSemester(event.target.value); setPageNumber(1) }}>{semesters.map((semester) => <option key={semester}>{semester}</option>)}</select></label></div>}
        <div className="admin-table-wrap"><Table columns={columns[page] || []} rows={currentRows} onSort={(key) => setSort((current) => ({ key, direction: current.key === key && current.direction === 'asc' ? 'desc' : 'asc' }))} sort={sort} renderAction={rowAction} renderCell={(row, key) => {
          const value = row[key]
          if (['status', 'conflict', 'dueStatus', 'readiness'].includes(key)) return <Badge>{value}</Badge>
          if (['billed', 'paid', 'debt'].includes(key)) return fmtMoney(value || 0)
          if (key === 'date' || key === 'start' || key === 'end') return key === 'date' ? fmtDate(value) : value
          if (key === 'score') return Number.isFinite(value) ? value : 'Belum diisi'
          return value ?? '—'
        }} onDetail={(row) => setDialog({ type: 'detail', title: row.name || row.student || row.title || row.class || row.code || row.kategori || 'Detail', row, extra: detailsFor(row) })} emptyMessage={query || Object.values(filters).some(Boolean) ? 'Tidak ada data yang cocok dengan pencarian atau filter.' : 'Belum ada data demo untuk halaman ini.'} />{!currentRows.length && <div className="admin-empty-state"><strong>Tidak ada data</strong><p>{query ? 'Coba ubah pencarian atau filter.' : 'Tambahkan data untuk memulai.'}</p></div>}</div>
        <div className="admin-table-footer"><span>Menampilkan {currentRows.length ? (Math.min(pageNumber, totalPages) - 1) * pageSize + 1 : 0}–{Math.min(pageNumber * pageSize, rows.length)} dari {rows.length}</span><div className="admin-pagination"><button disabled={pageNumber <= 1} onClick={() => setPageNumber((value) => value - 1)}>‹</button><span>Halaman {Math.min(pageNumber, totalPages)} dari {totalPages}</span><button disabled={pageNumber >= totalPages} onClick={() => setPageNumber((value) => value + 1)}>›</button></div></div>
      </section>
    </>
  }

  const pageDescriptions = {
    students: 'Kelola mahasiswa TRKJ dan ringkasan akademik terkait.',
    classes: 'Kelola kelas TRKJ, angkatan, paket semester, dan anggota kelas.',
    teachers: 'Kelola data dosen serta distribusi beban dan jadwal mengajar demo.',
    courses: 'Katalog mata kuliah TRKJ dan paket mata kuliah per semester.',
    packages: 'Susun paket kelas; sistem menolak mata kuliah duplikat.',
    schedules: 'Validasi bentrok jadwal dosen, ruang, dan kelas secara otomatis.',
    krs: 'Pratinjau dan publikasi KRS berbasis paket per kelas.',
    grades: 'Periksa kelengkapan nilai akhir mahasiswa per mata kuliah.',
    khs: 'Hitung IPS secara bersyarat dan simulasi publikasi KHS.',
    ukt: 'Pantau tagihan dan tunggakan UKT pada data demo.',
    attendance: 'Pantau kehadiran dan kasus yang melewati ambang demo.',
    cases: 'Kelola status kasus surat peringatan simulasi.',
    documents: 'Kelola metadata dan status dokumen akademik demo.',
    announcements: 'Kelola informasi akademik umum dalam sesi demo.',
    reports: 'Rekapitulasi mengikuti data simulasi pada sesi aktif.',
    activities: 'Riwayat perubahan yang terjadi selama sesi browser ini.',
  }

  let content
  if (isLoading) {
    content = <div style={{ padding: '50px', textAlign: 'center' }}>Memuat data dari server...</div>
  } else {
    content = page === 'dashboard' ? dashboard() : page === 'settings' ? settings() : page === 'reports' ? reports() : renderTablePage()
  }

  return <div className={`admin-app${compact ? ' admin-app--compact' : ''}`}>
    {mobileOpen && <button className="admin-nav-scrim" aria-label="Tutup navigasi" onClick={() => setMobileOpen(false)} />}
    <AdminSidebar page={page} navigate={navigate} mobileOpen={mobileOpen} setMobileOpen={setMobileOpen} />
    <main className="admin-main">
      <AdminHeader page={page} setMobileOpen={setMobileOpen} />
      <div className="admin-content"><div className="admin-demo-banner"><span className="admin-demo-banner__icon"><Icon name="check" size={15} /></span><strong>MODE DEMO —</strong><span>Data simulasi frontend, belum terhubung ke server atau mobile.</span></div>{page === 'courses' && <div className="admin-page-tabs"><button className="is-active" onClick={() => navigate('courses')}>Katalog mata kuliah</button><button onClick={() => navigate('packages')}>Paket semester</button></div>}{page === 'packages' && <div className="admin-page-tabs"><button onClick={() => navigate('courses')}>Katalog mata kuliah</button><button className="is-active" onClick={() => navigate('packages')}>Paket semester</button></div>}{content}<footer className="admin-footer"><span>EduTrack Campus · Administrasi akademik TRKJ</span><span>Data demo hanya bertahan selama sesi ini.</span></footer></div>
    </main>
    {dialog && <Modal title={dialog.type === 'detail' ? dialog.title : dialog.type === 'confirm' ? dialog.title : `${dialog.item ? 'Edit' : 'Tambah'} ${pageConfig[dialog.entity]?.singular || 'data'}`} onClose={() => setDialog(null)}>
      {dialog.type === 'confirm' && <><p className="admin-confirm-copy">{dialog.text}</p><div className="admin-form-actions"><button className="admin-button admin-button--secondary" onClick={() => setDialog(null)}>Batal</button><button className="admin-button admin-button--primary" onClick={dialog.action}>{dialog.label}</button></div></>}
      {dialog.type === 'detail' && <><dl className="admin-detail-list">{[['Ringkasan', Object.entries(dialog.row).filter(([key]) => key !== 'id').map(([key, value]) => `${key}: ${value ?? '—'}`).join(' · ')], ...(dialog.extra || [])].map(([label, value]) => <div key={label}><dt>{label}</dt><dd>{value}</dd></div>)}</dl><div className="admin-form-actions">{pageEntity[page] && <button className="admin-button admin-button--primary" onClick={() => openEdit(dialog.row)}>Edit data</button>}{pageEntity[page] && <button className="admin-button admin-button--danger" onClick={() => { setDialog(null); removeRecord(pageEntity[page], dialog.row) }}>Hapus data</button>}<button className="admin-button admin-button--secondary" onClick={() => setDialog(null)}>Tutup</button></div></>}
      {dialog.type === 'form' && <GenericForm key={`${dialog.entity}-${dialog.item?.id || 'new'}`} config={pageConfig[dialog.entity]} entity={dialog.entity} item={dialog.item} courses={courses} classes={classes} onClose={() => setDialog(null)} onSave={(values) => saveRecord(dialog.entity, values, dialog.item)} />}
    </Modal>}
    {toast && <div className="admin-toast" role="status">{toast}<button onClick={() => setToast('')} aria-label="Tutup notifikasi"><Icon name="close" size={14} /></button></div>}
  </div>
}

function GenericForm({ config, entity, item, courses, classes, onClose, onSave }) {
  const [values, setValues] = useState(() => {
    const initial = Object.fromEntries(config.fields.map(([key]) => [key, item?.[key] ?? '']))
    if (entity === 'grade' && item) initial.score = item.score ?? ''
    if (entity === 'package' && item) initial.courseIds = item.courseIds || []
    if (entity === 'package') initial.courseIds ||= []
    if (entity === 'package' && item) initial.classIds = item.classIds || []
    if (entity === 'package') initial.classIds ||= []
    if (entity === 'schedule') {
      initial.start ||= '08:00'
      initial.end ||= '10:00'
    }
    if (entity === 'ukt') {
      initial.billed ||= 5000000
      initial.paid ||= 0
    }
    return initial
  })
  const [errors, setErrors] = useState({})
  function submit(event) {
    event.preventDefault()
    const invalid = {}
    config.fields.forEach(([key, label]) => {
      if (key !== 'status' && !(entity === 'class' && key === 'packageId') && (values[key] === '' || values[key] === undefined)) invalid[key] = `${label} wajib diisi.`
    })
    if (entity === 'student' && !/^\d{5,15}$/.test(values.nim)) invalid.nim = 'NIM harus terdiri dari 5–15 digit.'
    if (entity === 'grade' && (!Number.isFinite(Number(values.score)) || Number(values.score) < 0 || Number(values.score) > 100)) invalid.score = 'Nilai harus 0–100.'
    if (entity === 'package' && !values.courseIds?.length) invalid.courseIds = 'Pilih minimal satu mata kuliah.'
    if (entity === 'ukt' && Number(values.paid) > Number(values.billed)) invalid.paid = 'Jumlah pembayaran tidak boleh melebihi tagihan demo.'
    setErrors(invalid)
    if (Object.keys(invalid).length) return
    const normalized = { ...values }
    for (const key of ['credits', 'term', 'score', 'billed', 'paid', 'present', 'permit', 'sick', 'absent', 'meetings']) {
      if (normalized[key] !== '' && normalized[key] !== undefined) normalized[key] = Number(normalized[key])
    }
    if (entity === 'package') normalized.courseIds = values.courseIds || []
    onSave(normalized)
  }
  return <form className="admin-entity-form" onSubmit={submit} noValidate><div className="admin-form-grid">{config.fields.map(([key, label, type, options]) => <div className={`admin-form-field${type === 'textarea' ? ' admin-form-field--wide' : ''}`} key={key}><label htmlFor={`field-${key}`}>{label} *</label>{type === 'select' ? <select id={`field-${key}`} value={values[key] ?? ''} onChange={(event) => setValues((current) => ({ ...current, [key]: event.target.value }))}><option value="">Pilih {label.toLowerCase()}</option>{options.map(([value, text]) => <option key={value} value={value}>{text}</option>)}</select> : type === 'textarea' ? <textarea id={`field-${key}`} rows="4" value={values[key] ?? ''} onChange={(event) => setValues((current) => ({ ...current, [key]: event.target.value }))} /> : <input id={`field-${key}`} type={type} min={type === 'number' ? 0 : undefined} value={values[key] ?? ''} onChange={(event) => setValues((current) => ({ ...current, [key]: event.target.value }))} />}{errors[key] && <small className="admin-field-error" role="alert">{errors[key]}</small>}</div>)}
    {entity === 'package' && <>
      <fieldset className="admin-form-field admin-form-field--wide admin-course-picker"><legend>Mata kuliah paket *</legend>{courses.map((course) => <label key={course.id}><input type="checkbox" checked={values.courseIds?.includes(course.id) || false} onChange={(event) => setValues((current) => ({ ...current, courseIds: event.target.checked ? [...(current.courseIds || []), course.id] : current.courseIds.filter((courseId) => courseId !== course.id) }))} />{course.code} · {course.name} ({course.credits} SKS)</label>)}{errors.courseIds && <small className="admin-field-error">{errors.courseIds}</small>}<strong>Total paket: {values.courseIds?.reduce((sum, courseId) => sum + (courses.find((course) => course.id === courseId)?.credits || 0), 0) || 0} SKS</strong></fieldset>
      <fieldset className="admin-form-field admin-form-field--wide admin-course-picker"><legend>Kelas yang menggunakan paket</legend>{classes.map((classRow) => <label key={classRow.id}><input type="checkbox" checked={values.classIds?.includes(classRow.id) || false} onChange={(event) => setValues((current) => ({ ...current, classIds: event.target.checked ? [...(current.classIds || []), classRow.id] : current.classIds.filter((classId) => classId !== classRow.id) }))} />{classRow.code}</label>)}</fieldset>
    </>}
  </div><p className="admin-form-hint">Data hanya tersimpan sementara dalam state demo browser. Tidak ada koneksi ke server.</p><div className="admin-form-actions"><button type="button" className="admin-button admin-button--secondary" onClick={onClose}>Batal</button><button type="submit" className="admin-button admin-button--primary">Simpan demo</button></div></form>
}

export default AdminAcademicDashboard
