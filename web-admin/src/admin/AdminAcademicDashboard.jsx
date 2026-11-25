import { useCallback, useEffect, useMemo, useState } from 'react'
import { useNavigate, useOutletContext } from 'react-router-dom'
import api, { endSession, getAllRecords, getApiError, getApiValidationField } from '../services/api'
import { buildApiMutation } from './apiMutations'

// Constants & data
import { filterLabels, titles } from './constants/adminData'

// Utilities
import { fmtMoney, fmtDate, id, getClassName, studentName, courseName, teacherName } from './utils/adminUtils'

// UI components
import { Icon, Badge, Stat, PageHeading, PanelHeading, ActivityList, Table, Modal, Preference } from './components/AdminUI'

// Layout components
import { AdminSidebar } from './components/AdminSidebar'
import { AdminHeader } from './components/AdminHeader'

function AdminAcademicDashboard() {
  const { user } = useOutletContext()
  const routerNavigate = useNavigate()
  const [page, setPage] = useState('dashboard')
  const [classes, setClasses] = useState([])
  const [students, setStudents] = useState([])
  const [isLoading, setIsLoading] = useState(true)
  const [loadError, setLoadError] = useState('')
  const [teachers, setTeachers] = useState([])
  const [courses, setCourses] = useState([])
  const [activePeriod, setActivePeriod] = useState(null)

  const [packages, setPackages] = useState([])
  const [schedules, setSchedules] = useState([])
  const [grades, setGrades] = useState([])
  const [ukt, setUkt] = useState([])
  const [attendance, setAttendance] = useState([])
  const [cases, setCases] = useState([])
  const [announcements, setAnnouncements] = useState([])
  const [krs, setKrs] = useState([])
  const [khs, setKhs] = useState([])
  const [documents, setDocuments] = useState([])
  const [activities, setActivities] = useState([])
  const [query, setQuery] = useState('')
  const [filters, setFilters] = useState({})
  const [sort, setSort] = useState({ key: '', direction: 'asc' })
  const [pageNumber, setPageNumber] = useState(1)
  const [dialog, setDialog] = useState(null)
  const [toast, setToast] = useState('')
  const [mobileOpen, setMobileOpen] = useState(false)
  const [compact, setCompact] = useState(false)
  const [selectedSemester, setSelectedSemester] = useState('')
  const [reportCategory, setReportCategory] = useState('')

  const semesters = useMemo(() => {
    const values = [
      activePeriod && `${activePeriod.year} ${activePeriod.semester}`,
      ...classes.map((row) => row.semester),
      ...schedules.map((row) => row.semester),
      ...grades.map((row) => row.semester),
      ...krs.map((row) => row.semester),
    ].filter(Boolean)
    return [...new Set(values)].sort((left, right) => right.localeCompare(left, 'id', { numeric: true }))
  }, [activePeriod, classes, schedules, grades, krs])
  const academicYears = useMemo(() => [...new Set(semesters.map((semester) => semester.split(' ')[0]).filter(Boolean))], [semesters])
  const matchesSemester = (recordSemester, selected) => {
    if (!recordSemester || !selected) return true
    if (recordSemester === selected) return true
    const recordYear = recordSemester.split(' ')[0]
    const selectedYear = selected.split(' ')[0]
    return recordYear === selectedYear || recordYear.startsWith(selectedYear) || selectedYear.startsWith(recordYear)
  }

  const packageById = (packageId) => packages.find((row) => row.id === packageId)
  const studentKhs = (student) => {
    const classRow = classes.find((row) => row.id === student.classId)
    const pack = classRow && packageById(classRow.packageId)
    const required = pack?.courseIds || []
    const entries = grades.filter((grade) => grade.studentId === student.id && grade.semester === student.semester && required.includes(grade.courseId))
    const complete = required.length > 0 && required.every((courseId) => entries.some((entry) => entry.courseId === courseId && Number.isFinite(entry.score) && entry.score >= 0 && entry.score <= 100))
    const credits = required.reduce((sum, courseId) => sum + (courses.find((course) => course.id === courseId)?.credits || 0), 0)
    const studentKhsRecord = khs.find((record) => record.studentId === student.id && record.semester === student.semester)
    return { complete, entries, required, credits, ips: '—', status: studentKhsRecord?.status || (complete ? 'Siap dipublikasikan' : 'Perlu diperiksa') }
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
  const attendanceSummaries = attendance.length
  const incompleteGrades = students.filter((student) => student.status === 'Aktif').reduce((total, student) => {
    const pack = packageById(classes.find((row) => row.id === student.classId)?.packageId)
    return total + (pack?.courseIds || []).filter((courseId) => !grades.some((grade) => grade.studentId === student.id && grade.courseId === courseId && grade.semester === student.semester && Number.isFinite(grade.score) && grade.score >= 0 && grade.score <= 100)).length
  }, 0)
  const pendingKrs = krs.filter((record) => record.status !== 'Aktif').length
  const pendingKhs = students.filter((student) => student.status === 'Aktif' && studentKhs(student).status !== 'Dipublikasikan').length
  const classRows = classes.map((row) => ({ ...row, count: students.filter((student) => student.classId === row.id).length, package: packageById(row.packageId)?.name || 'Belum ditetapkan' }))
  const scheduleRows = schedules.map((row) => ({ ...row, class: getClassName(classes, row.classId), course: courseName(courses, row.courseId), teacher: teacherName(teachers, row.teacherId), conflict: conflicts(row, row.id).length ? 'Bentrok' : 'Tidak bentrok' }))
  const gradeRows = grades.map((row) => ({ ...row, nim: row.nim, student: row.student, class: row.class, course: row.course, letter: row.letter || '—' }))
  const khsRows = students.map((student) => ({ id: student.id, nim: student.nim, student: student.name, class: getClassName(classes, student.classId), semester: student.semester, ...studentKhs(student) }))
  const uktRows = ukt.map((row) => ({ ...row, nim: students.find((student) => student.id === row.studentId)?.nim || '—', student: studentName(students, row.studentId), class: getClassName(classes, students.find((student) => student.id === row.studentId)?.classId), debt: Math.max(0, row.billed - row.paid), status: row.paid >= row.billed ? 'Lunas' : row.paid > 0 ? 'Sebagian' : 'Belum lunas', dueStatus: row.paid >= row.billed ? 'Lunas' : row.due < new Date().toISOString().slice(0, 10) ? 'Terlambat' : 'Belum jatuh tempo' }))
  const attendanceRows = attendance.map((row) => ({ ...row, nim: students.find((student) => student.id === row.studentId)?.nim || row.nim, student: row.student, class: row.class, course: row.course, percentage: row.meetings ? Math.round(row.present / row.meetings * 100) : 0, status: 'Tercatat' }))
  const caseRows = cases.map((row) => ({ ...row, nim: students.find((student) => student.id === row.studentId)?.nim || row.nim || '—', student: row.student || studentName(students, row.studentId), class: getClassName(classes, students.find((student) => student.id === row.studentId)?.classId) }))
  const packageRows = packages.map((row) => ({
    ...row,
    credits: (row.courseIds || []).reduce((sum, courseId) => sum + (courses.find((course) => course.id === courseId)?.credits || 0), 0),
  }))
  const teacherRows = teachers.map((row) => {
    const assigned = schedules.filter((schedule) => schedule.teacherId === row.id)
    return { ...row, courses: [...new Set(assigned.map((schedule) => courseName(courses, schedule.courseId)))].join(', ') || 'Belum ditugaskan', classes: [...new Set(assigned.map((schedule) => getClassName(classes, schedule.classId)))].join(', ') || '—', load: assigned.length }
  })

  const notify = useCallback((message) => {
    setToast(message)
    window.setTimeout(() => setToast(''), 3200)
  }, [])

  const fetchAll = useCallback(async () => {
    setIsLoading(true)
    setLoadError('')
    try {
      const [
        users,
        courses,
        classData,
        gradeData,
        attendanceData,
        uktData,
        announcementData,
        scheduleData,
        packageData,
        enrollmentData,
        caseData,
        documentData,
        khsData,
        periodResponse,
      ] = await Promise.all([
        getAllRecords('/admin/users'),
        getAllRecords('/courses/list'),
        getAllRecords('/classes/list'),
        getAllRecords('/admin/grades/list'),
        getAllRecords('/admin/attendances/list'),
        getAllRecords('/admin/ukt/list'),
        getAllRecords('/admin/announcements/list'),
        getAllRecords('/admin/schedules/list'),
        getAllRecords('/admin/packages/list'),
        getAllRecords('/admin/krs/list'),
        getAllRecords('/admin/cases/list'),
        getAllRecords('/admin/documents/list'),
        getAllRecords('/admin/khs/list'),
        api.get('/admin/academic/period-reconciliation'),
      ])
      const activeUsers = users.filter((entry) => entry.role === 'mahasiswa')
      const mapPeriod = (year, semester) => year && semester ? `${year} ${semester}` : ''
      const classById = new Map(classData.map((entry) => [entry.id, entry]))
      const activeEnrollments = enrollmentData
        .filter((entry) => String(entry.status).toLowerCase() === 'active')
        .sort((left, right) => new Date(right.updated_at) - new Date(left.updated_at))
      const enrollmentByStudent = new Map()
      activeEnrollments.forEach((entry) => {
        if (!enrollmentByStudent.has(entry.mahasiswa_id)) enrollmentByStudent.set(entry.mahasiswa_id, entry)
      })

      const mappedStudents = activeUsers.map((entry) => {
        const enrollment = enrollmentByStudent.get(entry.id)
        const classRecord = classById.get(enrollment?.class_id)
        return {
          id: entry.id,
          nim: entry.nim || '—',
          name: entry.name,
          email: entry.email,
          programStudi: entry.program_studi || '',
          classId: enrollment?.class_id ?? null,
          semester: classRecord ? mapPeriod(classRecord.year, classRecord.semester) : '',
          status: enrollment ? 'Aktif' : 'Belum terdaftar',
        }
      })
      setStudents(mappedStudents)
      setTeachers(users.filter((entry) => entry.role === 'dosen').map((entry) => ({
        id: entry.id,
        nidn: entry.nidn || '—',
        nip: entry.nip || '',
        name: entry.name,
        email: entry.email,
        programStudi: entry.program_studi || '',
      })))
      setCourses(courses.map((entry) => ({
        id: entry.id,
        code: entry.code,
        name: entry.name,
        credits: entry.sks,
        term: entry.semester,
      })))
      setClasses(classData.map((entry) => ({
        id: entry.id,
        code: entry.name,
        name: entry.name,
        courseId: entry.course_id,
        course: entry.course?.name || '—',
        dosenId: entry.dosen_id,
        dosen: entry.dosen?.name || '—',
        day: entry.day || '—',
        startTime: entry.start_time ? String(entry.start_time).slice(0, 5) : '',
        endTime: entry.end_time ? String(entry.end_time).slice(0, 5) : '',
        room: entry.room || '—',
        year: entry.year || '',
        semester: mapPeriod(entry.year, entry.semester),
        term: entry.semester || '',
        packageId: entry.package_id || null,
        status: entry.status || '—',
      })))

      const gradeRecords = gradeData.map((entry) => {
        const classRecord = entry.class || {}
        const course = classRecord.course || {}
        const student = entry.mahasiswa || {}
        return {
          id: entry.id,
          studentId: entry.mahasiswa_id,
          nim: student.nim || '—',
          student: student.name || '—',
          classId: entry.class_id,
          class: classRecord.name || '—',
          courseId: classRecord.course_id,
          course: course.name || '—',
          semester: mapPeriod(classRecord.year, classRecord.semester),
          score: entry.score,
          letter: entry.letter,
          status: 'Tersimpan',
        }
      })
      setGrades(gradeRecords)

      const attendanceGroups = new Map()
      attendanceData.forEach((entry) => {
        const classRecord = entry.class || {}
        const student = entry.mahasiswa || {}
        const key = `${entry.mahasiswa_id}:${entry.class_id}`
        const row = attendanceGroups.get(key) || {
          id: key,
          studentId: entry.mahasiswa_id,
          nim: student.nim || '—',
          student: student.name || '—',
          classId: entry.class_id,
          class: classRecord.name || '—',
          course: classRecord.course?.name || '—',
          semester: mapPeriod(classRecord.year, classRecord.semester),
          present: 0,
          permit: 0,
          sick: 0,
          absent: 0,
          meetings: 0,
        }
        row.meetings += 1
        if (entry.status === 'hadir') row.present += 1
        else if (entry.status === 'izin') row.permit += 1
        else if (entry.status === 'sakit') row.sick += 1
        else if (entry.status === 'alpa') row.absent += 1
        attendanceGroups.set(key, row)
      })
      setAttendance([...attendanceGroups.values()])

      setUkt(uktData.map((entry) => {
        const student = entry.student || {}
        const paid = Number(entry.paid)
        const billed = Number(entry.billed)
        return {
          id: entry.id,
          studentId: entry.student_id,
          nim: student.nim || '—',
          student: student.name || '—',
          semester: entry.semester,
          billed,
          paid,
          debt: Math.max(0, billed - paid),
          status: paid >= billed ? 'Lunas' : paid > 0 ? 'Sebagian' : 'Belum lunas',
          dueStatus: entry.due_date ? (entry.due_date.slice(0, 10) < new Date().toISOString().slice(0, 10) ? 'Terlambat' : 'Belum jatuh tempo') : '—',
          due: entry.due_date ? entry.due_date.slice(0, 10) : '',
        }
      }))
      setAnnouncements(announcementData.map((entry) => ({
        id: entry.id,
        title: entry.title,
        category: entry.category,
        content: entry.content,
        start: entry.start_date?.slice(0, 10) || '',
        end: entry.end_date?.slice(0, 10) || '',
        status: entry.status,
      })))
      setSchedules(scheduleData.map((entry) => ({
        id: entry.id,
        semester: entry.semester,
        classId: entry.class_id,
        class: entry.class?.name || '—',
        courseId: entry.course_id,
        course: entry.course?.name || '—',
        teacherId: entry.teacher_id,
        teacher: entry.teacher?.name || '—',
        day: entry.day,
        start: entry.start_time ? String(entry.start_time).slice(0, 5) : '',
        end: entry.end_time ? String(entry.end_time).slice(0, 5) : '',
        room: entry.room || '—',
      })))
      setPackages(packageData.map((entry) => ({
        id: entry.id,
        name: entry.name,
        term: entry.term,
        status: entry.status,
        courseIds: entry.courses?.map((course) => course.id) || [],
        courses: entry.courses?.map((course) => course.name).join(', ') || '—',
        classIds: entry.classes?.map((classRecord) => classRecord.id) || [],
        classes: entry.classes?.map((classRecord) => classRecord.name).join(', ') || '—',
      })))
      setKrs(enrollmentData.map((entry) => {
        const student = entry.mahasiswa || {}
        const classRecord = entry.class || {}
        const pack = packageData.find((candidate) => candidate.id === classRecord.package_id)
        return {
          id: entry.id,
          classId: entry.class_id,
          class: classRecord.name || '—',
          studentId: entry.mahasiswa_id,
          student: student.name || '—',
          nim: student.nim || '—',
          semester: mapPeriod(classRecord.year, classRecord.semester),
          status: entry.status === 'active' ? 'Aktif' : entry.status || '—',
          package: pack?.name || '—',
          courses: pack?.courses?.map((course) => course.name).join(', ') || '—',
          credits: pack?.courses?.reduce((sum, course) => sum + course.sks, 0) || 0,
        }
      }))
      setCases(caseData.map((entry) => ({
        id: entry.id,
        studentId: entry.student_id,
        nim: entry.student?.nim || '—',
        student: entry.student?.name || '—',
        class: classById.get(enrollmentByStudent.get(entry.student_id)?.class_id)?.name || '—',
        level: entry.level,
        reason: entry.reason,
        followup: entry.followup,
        status: entry.status,
      })))
      setDocuments(documentData.map((entry) => ({
        id: entry.id,
        studentId: entry.student_id,
        type: entry.type,
        student: entry.student?.name || '—',
        semester: entry.semester,
        status: entry.status,
        date: entry.date?.slice(0, 10) || '',
      })))
      setKhs(
        khsData.map((item) => ({
          studentId: item.student_id,
          semester: item.semester,
          status: item.status,
        }))
      )
      const period = periodResponse.data?.data?.active_period
      setActivePeriod(period || null)
      if (period?.year && period?.semester) {
        setSelectedSemester((current) => current || `${period.year} ${period.semester}`)
      }
      return true
    } catch (error) {
      const message = getApiError(error, 'Gagal memuat data backend')
      setLoadError(message)
      notify(`Gagal memuat data: ${message}`)
      return false
    } finally {
      setIsLoading(false)
    }
  }, [notify])

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect -- Memulai pemuatan data dari API saat dashboard dibuka.
    fetchAll()
  }, [fetchAll])
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
  async function saveRecord(entity, values, item) {
    const config = pageConfig[entity]
    if (!config || !pageEntity[page]) {
      notify('Modul ini tidak dapat diubah dari halaman ini.')
      return
    }
    const apiMutation = buildApiMutation(entity, values, item, classes)

    if (!apiMutation) {
      if (entity === 'schedule') {
        notify('Kelas yang dipilih tidak ditemukan.')
        return
      }
      notify('Operasi CRUD ini belum tersedia pada backend.')
      return
    }

    try {
      await api[apiMutation.method](apiMutation.url, apiMutation.payload)
      log(config.activity, `${item ? 'Memperbarui' : 'Menambahkan'} ${config.singular}`)
      setDialog(null)
      const refreshed = await fetchAll()
      notify(refreshed
        ? `${config.singular} berhasil ${item ? 'diperbarui' : 'ditambahkan'}.`
        : `${config.singular} tersimpan, tetapi daftar gagal dimuat ulang.`)
    } catch (error) {
      const message = getApiError(error)
      const fieldError = getApiValidationField(error, {
        name: 'name', email: 'email', password: 'password', nim: 'nim',
        program_studi: 'programStudi', code: 'code', sks: 'credits',
        semester: ['class', 'course'].includes(entity) ? 'term' : 'semester', term: 'term', year: 'year',
        course_id: 'courseId', dosen_id: 'dosenId', package_id: 'packageId',
        course_ids: 'courseIds', class_ids: 'classIds', day: 'day',
        start_time: entity === 'schedule' ? 'start' : 'startTime',
        end_time: entity === 'schedule' ? 'end' : 'endTime', room: 'room',
        student_id: 'studentId', billed: 'billed', paid: 'paid',
        due_date: 'due', title: 'title', category: 'category',
        content: 'content', start_date: 'start', end_date: 'end',
        level: 'level', reason: 'reason', followup: 'followup',
        status: 'status', type: 'type', date: 'date',
      })
      notify(`Gagal menyimpan data: ${message}`)
      return fieldError || { message }
    }
  }
  function askConfirm(title, text, action, label = 'Konfirmasi') {
    setDialog({ type: 'confirm', title, text, action, label })
  }
  function updatePublication(target, nextStatus) {
    const student = students.find((row) => row.id === target)
    const result = student && studentKhs(student)
    if (nextStatus === 'Dipublikasikan' && !result?.complete) return notify('KHS belum dapat dipublikasikan: masih ada nilai wajib yang kosong atau tidak valid.')
    askConfirm(`${nextStatus} KHS?`, `Ubah status KHS untuk ${studentName(students, target)}?`, async () => {
      try {
        await api.put('/admin/khs/update', {
          student_id: Number(target),
          semester: student?.semester || selectedSemester,
          status: nextStatus,
        })
        log('KHS', `Status KHS ${studentName(students, target)} diubah menjadi ${nextStatus}`)
        setDialog(null)
        const refreshed = await fetchAll()
        notify(refreshed ? `Status KHS berhasil diperbarui menjadi ${nextStatus}.` : 'Status KHS tersimpan, tetapi daftar gagal dimuat ulang.')
      } catch (error) {
        notify(`Gagal memperbarui status KHS: ${getApiError(error)}`)
      }
    }, 'Ubah status')
  }
  function removeRecord(entity, row) {
    const names = { student: 'mahasiswa', class: 'kelas', teacher: 'dosen', course: 'mata kuliah', package: 'paket', schedule: 'jadwal', grade: 'nilai', ukt: 'data UKT', attendance: 'rekap kehadiran', case: 'kasus SP', announcement: 'pengumuman', document: 'dokumen' }
    
    if (entity === 'grade' || entity === 'attendance') {
      notify('Data ini hanya dapat dibaca dari web-admin.')
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

      if (entity === 'ukt') {
        api.delete(`/admin/ukt/delete?id=${row.id}`)
          .then(() => {
            fetchAll()
            log('Data', `Menghapus ${names[entity]}`)
            setDialog(null)
            notify(`${names[entity]} berhasil dihapus.`)
          })
          .catch((error) => notify(`Gagal menghapus data: ${formatDeleteError(error)}`))
        return
      }

      if (entity === 'announcement') {
        api.delete(`/admin/announcements/delete?id=${row.id}`)
          .then(() => {
            fetchAll()
            log('Data', `Menghapus ${names[entity]}`)
            setDialog(null)
            notify(`${names[entity]} berhasil dihapus.`)
          })
          .catch((error) => notify(`Gagal menghapus data: ${formatDeleteError(error)}`))
        return
      }

      if (entity === 'schedule') {
        api.delete(`/admin/schedules/delete?id=${row.id}`)
          .then(() => {
            fetchAll()
            log('Data', `Menghapus ${names[entity]}`)
            setDialog(null)
            notify(`${names[entity]} berhasil dihapus.`)
          })
          .catch((error) => notify(`Gagal menghapus data: ${formatDeleteError(error)}`))
        return
      }

      if (entity === 'package') {
        api.delete(`/admin/packages/delete?id=${row.id}`)
          .then(() => {
            fetchAll()
            log('Data', `Menghapus ${names[entity]}`)
            setDialog(null)
            notify(`${names[entity]} berhasil dihapus.`)
          })
          .catch((error) => notify(`Gagal menghapus data: ${formatDeleteError(error)}`))
        return
      }

      if (entity === 'case') {
        api.delete(`/admin/cases/delete?id=${row.id}`)
          .then(() => {
            fetchAll()
            log('Data', `Menghapus ${names[entity]}`)
            setDialog(null)
            notify(`${names[entity]} berhasil dihapus.`)
          })
          .catch((error) => notify(`Gagal menghapus data: ${formatDeleteError(error)}`))
        return
      }

      if (entity === 'document') {
        api.delete(`/admin/documents/delete?id=${row.id}`)
          .then(() => {
            fetchAll()
            log('Data', `Menghapus ${names[entity]}`)
            setDialog(null)
            notify(`${names[entity]} berhasil dihapus.`)
          })
          .catch((error) => notify(`Gagal menghapus data: ${formatDeleteError(error)}`))
        return
      }

      if (entity === 'krs') {
        setDialog(null)
        notify('KRS dikelola oleh mahasiswa')
        return
      }

      setDialog(null)
      notify('Penghapusan untuk modul ini belum tersedia pada backend.')
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
    notify('CSV berhasil dibuat dari data yang sedang ditampilkan.')
  }

  function getRows(key) {
    if (key === 'students') return students.map((row) => ({ ...row, class: getClassName(classes, row.classId), program: row.programStudi || '—' }))
    if (key === 'classes') return classRows
    if (key === 'teachers') return teacherRows
    if (key === 'courses') return courses.map((row) => ({ ...row, package: packages.filter((pack) => pack.courseIds.includes(row.id)).map((pack) => pack.name).join(', ') || 'Belum dipaketkan', teacher: teacherName(teachers, schedules.find((schedule) => schedule.courseId === row.id)?.teacherId) }))
    if (key === 'packages') return packageRows
    if (key === 'schedules') return scheduleRows
    if (key === 'krs') return krs
    if (key === 'grades') return gradeRows
    if (key === 'khs') return khsRows
    if (key === 'ukt') return uktRows
    if (key === 'attendance') return attendanceRows
    if (key === 'cases') return caseRows
    if (key === 'documents') return documents.map((row) => ({ ...row, student: row.student || studentName(students, row.studentId) }))
    if (key === 'announcements') return announcements
    if (key === 'activities') return activities
    if (key === 'reports') return activeReportRows
    return []
  }

  const reportRows = [
    ...classRows.map((row) => ({ kategori: 'Kelas', rincian: row.code, jumlah: row.count })),
    { kategori: 'Mahasiswa aktif', rincian: 'Aktif berdasarkan KRS', jumlah: activeStudents },
    { kategori: 'UKT tunggakan', rincian: 'Total tunggakan', jumlah: tuitionDebt },
    { kategori: 'Kehadiran', rincian: 'Rekap mahasiswa dan kelas', jumlah: attendanceSummaries },
    { kategori: 'Surat peringatan', rincian: 'Kasus terbuka', jumlah: cases.filter((row) => row.status !== 'Ditutup').length },
    { kategori: 'Paket', rincian: 'Paket semester', jumlah: packages.length },
    { kategori: 'Jadwal', rincian: 'Jadwal bentrok', jumlah: scheduleConflicts },
    { kategori: 'KRS', rincian: 'Enrollment nonaktif', jumlah: pendingKrs },
    { kategori: 'Nilai', rincian: 'Belum lengkap', jumlah: incompleteGrades },
    { kategori: 'KHS', rincian: 'Belum dipublikasikan', jumlah: pendingKhs },
  ]
  const activeReportRows = reportRows

  const columns = {
    students: [['nim', 'NIM'], ['name', 'Nama'], ['email', 'Email'], ['class', 'Kelas'], ['semester', 'Semester'], ['status', 'Status']],
    classes: [['code', 'Kode kelas'], ['year', 'Angkatan'], ['count', 'Jumlah mahasiswa'], ['semester', 'Semester aktif'], ['package', 'Paket'], ['status', 'Status']],
    teachers: [['nidn', 'NIDN'], ['name', 'Nama dosen'], ['courses', 'Mata kuliah diampu'], ['classes', 'Kelas'], ['load', 'Beban mengajar']],
    courses: [['code', 'Kode'], ['name', 'Mata kuliah'], ['credits', 'SKS'], ['term', 'Semester'], ['teacher', 'Dosen pengampu'], ['package', 'Paket']],
    packages: [['name', 'Nama paket'], ['term', 'Semester'], ['courses', 'Mata kuliah'], ['credits', 'Total SKS'], ['classes', 'Kelas'], ['status', 'Status']],
    schedules: [['semester', 'Semester'], ['class', 'Kelas'], ['course', 'Mata kuliah'], ['teacher', 'Dosen'], ['day', 'Hari'], ['start', 'Mulai'], ['end', 'Selesai'], ['room', 'Ruang'], ['conflict', 'Validasi']],
    krs: [['nim', 'NIM'], ['student', 'Mahasiswa'], ['class', 'Kelas'], ['semester', 'Semester'], ['package', 'Paket'], ['courses', 'Mata kuliah paket'], ['credits', 'SKS'], ['status', 'Status KRS']],
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
  const pageEntity = { students: 'student', classes: 'class', teachers: 'teacher', courses: 'course', packages: 'package', schedules: 'schedule', ukt: 'ukt', cases: 'case', documents: 'document', announcements: 'announcement' }

  function rowsForPage() {
    const all = getRows(page)
    if (page === 'reports') return all.filter((row) => !reportCategory || row.kategori === reportCategory)
    return all.filter((row) => {
      if (['krs', 'khs', 'grades', 'ukt', 'attendance'].includes(page) && row.semester && !matchesSemester(row.semester, selectedSemester)) return false
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
    student: { 
      singular: 'mahasiswa', 
      activity: 'Mahasiswa', 
      fields: [
        ['name', 'Nama Lengkap', 'text'],
        ['email', 'Email', 'email'], 
        ['password', 'Password (min. 8 karakter)', 'password'],
        ['nim', 'NIM (Opsional)', 'text'],
        ['programStudi', 'Program studi', 'text'],
      ] 
    },
    class: { 
      singular: 'kelas', 
      activity: 'Kelas', 
      fields: [
        ['name', 'Nama Kelas (Misal: TRKJ 1A)', 'text'],
        ['courseId', 'Mata Kuliah', 'select', courses.map((row) => [row.id, `${row.code} · ${row.name}`])],
        ['dosenId', 'Dosen Pengampu', 'select', teachers.map((row) => [row.id, row.name])],
        ['day', 'Hari', 'select', ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'].map((row) => [row, row])],
        ['startTime', 'Jam Mulai', 'time'],
        ['endTime', 'Jam Selesai', 'time'],
        ['room', 'Ruang', 'text'],
        ['year', 'Tahun akademik', 'text'],
        ['term', 'Semester', 'select', ['Ganjil', 'Genap'].map((row) => [row, row])],
        ['packageId', 'Paket Semester', 'select', packages.map((row) => [row.id, row.name])],
        ['status', 'Status', 'select', ['Aktif', 'Nonaktif'].map((row) => [row, row])]
      ] 
    },
    teacher: { 
      singular: 'dosen', 
      activity: 'Dosen', 
      fields: [
        ['name', 'Nama dosen', 'text'],
        ['email', 'Email', 'email'],
        ['password', 'Password (min. 8 karakter)', 'password'],
        ['nidn', 'NIDN', 'text'],
        ['nip', 'NIP', 'text'],
        ['programStudi', 'Program studi', 'text'],
      ] 
    },
    course: { singular: 'mata kuliah', activity: 'Mata kuliah', fields: [['code', 'Kode mata kuliah', 'text'], ['name', 'Nama mata kuliah', 'text'], ['credits', 'Jumlah SKS', 'number'], ['term', 'Semester rekomendasi', 'number']] },
    package: { singular: 'paket semester', activity: 'Paket', fields: [['name', 'Nama paket', 'text'], ['term', 'Semester', 'number'], ['status', 'Status paket', 'select', ['Draf', 'Siap'].map((row) => [row, row])]] },
    schedule: { singular: 'jadwal kuliah', activity: 'Jadwal', fields: [['semester', 'Semester', 'select', semesters.map((row) => [row, row])], ['classId', 'Kelas', 'select', classes.map((row) => [row.id, row.code])], ['day', 'Hari', 'select', ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'].map((row) => [row, row])], ['start', 'Jam mulai', 'time'], ['end', 'Jam selesai', 'time'], ['room', 'Ruang', 'text']] },
    grade: { singular: 'nilai', activity: 'Nilai', fields: [['studentId', 'Mahasiswa', 'select', students.map((row) => [row.id, `${row.nim} · ${row.name}`])], ['courseId', 'Mata kuliah', 'select', courses.map((row) => [row.id, row.name])], ['semester', 'Semester', 'select', semesters.map((row) => [row, row])], ['score', 'Nilai angka (0–100)', 'number'], ['status', 'Status', 'select', ['Lengkap', 'Perlu diperiksa'].map((row) => [row, row])]] },
    ukt: { singular: 'data UKT', activity: 'UKT', fields: [['studentId', 'Mahasiswa', 'select', students.map((row) => [row.id, `${row.nim} · ${row.name}`])], ['semester', 'Tahun akademik', 'select', academicYears.map((row) => [row, row])], ['billed', 'Nominal tagihan', 'number'], ['paid', 'Nominal dibayar', 'number'], ['due', 'Tanggal jatuh tempo', 'date']] },
    attendance: { singular: 'rekap kehadiran', activity: 'Kehadiran', fields: [['studentId', 'Mahasiswa', 'select', students.map((row) => [row.id, `${row.nim} · ${row.name}`])], ['courseId', 'Mata kuliah', 'select', courses.map((row) => [row.id, row.name])], ['semester', 'Semester', 'select', semesters.map((row) => [row, row])], ['present', 'Jumlah hadir', 'number'], ['permit', 'Izin', 'number'], ['sick', 'Sakit', 'number'], ['absent', 'Alpa', 'number'], ['meetings', 'Jumlah pertemuan', 'number']] },
    case: { singular: 'kasus SP', activity: 'SP', fields: [['studentId', 'Mahasiswa', 'select', students.map((row) => [row.id, `${row.nim} · ${row.name}`])], ['level', 'Jenjang', 'select', ['SP 1', 'SP 2', 'SP 3'].map((row) => [row, row])], ['reason', 'Dasar/catatan', 'text'], ['followup', 'Riwayat tindak lanjut', 'text'], ['status', 'Status', 'select', ['Draf', 'Diajukan', 'Perlu diperiksa', 'Diterbitkan (simulasi)', 'Ditutup'].map((row) => [row, row])]] },
    document: { singular: 'dokumen', activity: 'Dokumen', fields: [['type', 'Jenis dokumen', 'select', ['KRS', 'KHS', 'Surat Peringatan', 'Dokumen pendukung'].map((row) => [row, row])], ['studentId', 'Mahasiswa', 'select', students.map((row) => [row.id, `${row.nim} · ${row.name}`])], ['semester', 'Semester', 'select', semesters.map((row) => [row, row])], ['status', 'Status', 'select', ['Lengkap', 'Memerlukan perbaikan', 'Draf'].map((row) => [row, row])], ['date', 'Tanggal dokumen', 'date']] },
    announcement: { singular: 'pengumuman', activity: 'Pengumuman', fields: [['title', 'Judul', 'text'], ['category', 'Kategori', 'select', ['Akademik', 'Administrasi', 'Sistem'].map((row) => [row, row])], ['start', 'Tanggal mulai', 'date'], ['end', 'Tanggal akhir', 'date'], ['status', 'Status', 'select', ['Draf', 'Aktif', 'Berakhir'].map((row) => [row, row])], ['content', 'Isi pengumuman', 'textarea']] },
  }

  function detailsFor(row) {
    if (page === 'students') {
      const student = students.find((item) => item.id === row.id)
      const khsRow = studentKhs(student)
      const tuition = uktRows.find((item) => item.studentId === student.id)
      const attend = attendanceRows.find((item) => item.studentId === student.id)
      const enrollment = krs.find((record) => record.studentId === student.id && record.status === 'Aktif')
      return [['Email', student?.email || '—'], ['Program studi', student?.programStudi || '—'], ['UKT', tuition ? `${tuition.status} · ${fmtMoney(tuition.debt)} tunggakan` : 'Belum ada data'], ['Kehadiran', attend ? `${attend.percentage}% · ${attend.status}` : 'Belum ada data'], ['KRS', enrollment?.status || 'Belum terdaftar'], ['KHS', khsRow.status], ['IPS', khsRow.ips]]
    }
    if (page === 'teachers') return [['Jadwal terdaftar', schedules.filter((item) => item.teacherId === row.id).map((item) => `${item.day} ${item.start} · ${getClassName(classes, item.classId)}`).join('; ') || 'Belum ditugaskan'], ['Jumlah jadwal', `${row.load}`]]
    if (page === 'classes') return [['Anggota kelas', students.filter((student) => student.classId === row.id).map((student) => `${student.nim} · ${student.name}`).join('; ') || 'Belum ada mahasiswa'], ['Paket mata kuliah', row.package], ['Jadwal terkait', schedules.filter((schedule) => schedule.classId === row.id).map((schedule) => `${schedule.day} ${schedule.start} · ${courseName(courses, schedule.courseId)}`).join('; ') || 'Belum ada jadwal']]
    if (page === 'packages') return [['Mata kuliah', row.courses], ['Total SKS', row.credits], ['Kelas terkait', row.classes], ['Kelengkapan paket', row.courseIds.every((courseId) => courses.some((item) => item.id === courseId)) ? 'Valid' : 'Ada mata kuliah tidak tersedia']]
    if (page === 'schedules') return [['Validasi bentrok', row.conflict], ['Durasi', `${row.start}–${row.end}`], ['Kelas', row.class], ['Dosen', row.teacher]]
    if (page === 'krs') {
      const classRow = classes.find((item) => item.id === row.classId)
      const pack = classRow && packageById(classRow.packageId)
      const courseDetails = (pack?.courseIds || []).map((courseId) => {
        const course = courses.find((item) => item.id === courseId)
        const schedule = schedules.find((item) => item.classId === row.classId && item.courseId === courseId && item.semester === row.semester)
        return `${course?.code || '—'} ${course?.name || 'Mata kuliah'} · ${course?.credits || 0} SKS · ${schedule ? `${schedule.day} ${schedule.start}–${schedule.end}, ${schedule.room}, ${teacherName(teachers, schedule.teacherId)}` : 'Jadwal belum lengkap'}`
      })
      return [['Status enrollment', row.status], ['Mahasiswa', row.student], ['Paket dan jadwal', courseDetails.join('; ') || 'Paket tidak tersedia'], ['Total SKS', row.credits]]
    }
    if (page === 'grades') return [['Nilai', Number.isFinite(row.score) ? `${row.score} · ${row.letter}` : 'Nilai belum tersedia'], ['Status', row.status]]
    if (page === 'khs') return [['Rekap mata kuliah', row.entries.map((entry) => `${courseName(courses, entry.courseId)}: ${Number.isFinite(entry.score) ? `${entry.score} (${entry.letter || '—'})` : 'nilai belum diisi'}`).join('; ') || 'Belum ada nilai'], ['IPS', 'Tidak disediakan oleh endpoint admin'], ['SKS terhitung', row.complete ? row.credits : 'Belum lengkap'], ['Nilai wajib tersedia', `${row.entries.filter((entry) => Number.isFinite(entry.score)).length} dari ${row.required.length}`]]
    if (page === 'ukt') return [['Tagihan', fmtMoney(row.billed)], ['Dibayar', fmtMoney(row.paid)], ['Tunggakan', fmtMoney(row.debt)], ['Jatuh tempo', fmtDate(row.due)]]
    if (page === 'attendance') return [['Pertemuan tercatat', row.meetings], ['Hadir', row.present], ['Izin / sakit / alpa', `${row.permit} / ${row.sick} / ${row.absent}`]]
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
      return null
    }
    if (page === 'khs') {
      const next = row.status === 'Dipublikasikan' ? 'Draf' : 'Dipublikasikan'
      return <button className="admin-button admin-button--secondary admin-button--small" onClick={() => updatePublication(row.id, next)}>{next === 'Draf' ? 'Batalkan publikasi' : 'Publikasikan'}</button>
    }
    if (page === 'cases') return <select className="admin-inline-select" aria-label={`Status kasus ${row.student}`} value={row.status} onChange={(event) => {
      const status = event.target.value
      api.put(`/admin/cases/update?id=${row.id}`, { student_id: Number(row.studentId), level: row.level, reason: row.reason, followup: row.followup, status })
        .then(() => {
          fetchAll()
          log('SP', `Status kasus ${row.id} diubah menjadi ${status}`)
          notify(`Status kasus SP berhasil diubah menjadi ${status}.`)
        })
        .catch((error) => notify(`Gagal mengubah status kasus: ${getApiError(error)}`))
    }}>{['Draf', 'Diajukan', 'Perlu diperiksa', 'Diterbitkan (simulasi)', 'Ditutup'].map((status) => <option key={status}>{status}</option>)}</select>
    if (page === 'announcements') return <select className="admin-inline-select" aria-label={`Status pengumuman ${row.title}`} value={row.status} onChange={(event) => {
      const newStatus = event.target.value
      api.put(`/admin/announcements/update?id=${row.id}`, { title: row.title, category: row.category, content: row.content, status: newStatus, start_date: row.start, end_date: row.end })
        .then(async () => {
          if (!await fetchAll()) notify('Status tersimpan, tetapi daftar gagal dimuat ulang.')
        })
        .catch((error) => notify(`Gagal mengubah status pengumuman: ${getApiError(error)}`))
    }}>{['Draf', 'Aktif', 'Berakhir'].map((status) => <option key={status}>{status}</option>)}</select>
    if (page === 'ukt') return <button className="admin-row-action" title="Koreksi pembayaran UKT" onClick={() => setDialog({ type: 'form', entity: 'ukt', item: row })}><Icon name="wallet" size={15} /></button>
    return null
  }

  function dashboard() {
    const semesterStudents = students.filter((student) => student.semester === selectedSemester)
    const semesterClasses = classRows.filter((classRow) => classRow.semester === selectedSemester)
    const semesterActiveStudents = semesterStudents.filter((student) => student.status === 'Aktif').length
    const semesterUkt = ukt.filter((row) => matchesSemester(row.semester, selectedSemester))
    const semesterDebt = semesterUkt.reduce((sum, row) => sum + Math.max(0, row.billed - row.paid), 0)
    const semesterAttendanceRows = attendanceRows.filter((row) => matchesSemester(row.semester, selectedSemester)).length
    const semesterScheduleConflicts = scheduleRows.filter((row) => row.semester === selectedSemester && row.conflict === 'Bentrok').length
    const semesterMissingGrades = semesterStudents.filter((student) => student.status === 'Aktif').reduce((total, student) => {
      const pack = packageById(classes.find((row) => row.id === student.classId)?.packageId)
      return total + (pack?.courseIds || []).filter((courseId) => !grades.some((grade) => grade.studentId === student.id && grade.courseId === courseId && grade.semester === selectedSemester && Number.isFinite(grade.score) && grade.score >= 0 && grade.score <= 100)).length
    }, 0)
    const semesterPendingKrs = krs.filter((record) => matchesSemester(record.semester, selectedSemester) && record.status !== 'Aktif').length
    const semesterPendingKhs = semesterStudents.filter((student) => studentKhs(student).status !== 'Dipublikasikan').length
    const unassignedTeachers = teacherRows.filter((teacher) => teacher.load === 0).length
    const teacherConflictIds = new Set(semesterScheduleConflicts ? scheduleRows.filter((schedule) => schedule.semester === selectedSemester && schedule.conflict === 'Bentrok').flatMap((schedule) => schedules.filter((other) => conflicts(schedule, schedule.id).some((conflict) => conflict.id === other.id)).map((other) => other.teacherId)) : [])
    const todo = [
      [semesterScheduleConflicts, 'Bentrok jadwal perlu diperbaiki', 'schedules'],
      [teacherConflictIds.size, 'Dosen memiliki jadwal bentrok', 'teachers'],
      [unassignedTeachers, 'Dosen belum mendapat penugasan', 'teachers'],
      [semesterMissingGrades, 'Nilai belum lengkap', 'grades'],
      [semesterUkt.filter((row) => row.paid < row.billed).length, 'Mahasiswa memiliki tunggakan UKT', 'ukt'],
      [semesterPendingKrs, 'Enrollment KRS tidak aktif', 'krs'],
      [semesterPendingKhs, 'KHS belum dipublikasikan', 'khs'],
    ]
    const classBars = semesterClasses.map((row) => ({ label: row.code, count: students.filter((student) => student.classId === row.id && student.semester === selectedSemester).length }))
    const maxCount = Math.max(1, ...classBars.map((row) => row.count))
    return <>
      <section className="admin-welcome"><div><span className="admin-eyebrow">PANEL ADMINISTRASI AKADEMIK</span><h1>Ringkasan Akademik</h1><p>Ringkasan dihitung dari data yang tersedia di backend.</p></div><label className="admin-semester-select">Semester<select value={selectedSemester} onChange={(event) => setSelectedSemester(event.target.value)}>{semesters.map((semester) => <option key={semester}>{semester}</option>)}</select></label></section>
      <div className="admin-academic-stats">
        <Stat title="Mahasiswa aktif" value={semesterActiveStudents} note={`${semesterStudents.length} terdata`} icon="users" />
        <Stat title="Kelas" value={semesterClasses.length} note="Semester terpilih" icon="grid" />
        <Stat title="Dosen" value={teachers.length} note="Data dosen" icon="users" />
        <Stat title="Tunggakan UKT" value={fmtMoney(semesterDebt)} note={`${semesterUkt.filter((row) => row.paid < row.billed).length} mahasiswa`} icon="wallet" />
        <Stat title="Rekap kehadiran" value={semesterAttendanceRows} note="Data server" icon="check" />
        <Stat title="Jadwal bentrok" value={semesterScheduleConflicts} note="Validasi jadwal" icon="clock" />
        <Stat title="Nilai belum lengkap" value={semesterMissingGrades} note="Wajib diperiksa" icon="chart" />
        <Stat title="KRS nonaktif / KHS pending" value={`${semesterPendingKrs} / ${semesterPendingKhs}`} note="Berdasarkan status data" icon="file" />
      </div>
      <div className="admin-dashboard-grid">
        <section className="admin-panel"><PanelHeading title="Distribusi mahasiswa per kelas" subtitle="Jumlah berdasarkan KRS aktif" /><div className="admin-hbar-chart">{classBars.map((row) => <div className="admin-hbar-row" key={row.label}><span>{row.label}</span><div className="admin-hbar-track"><i style={{ width: `${Math.max(7, row.count / maxCount * 100)}%` }} /></div><strong>{row.count}</strong></div>)}{!classBars.length && <p className="admin-chart-footnote">Belum ada data kelas untuk semester ini.</p>}</div></section>
        <section className="admin-panel"><PanelHeading title="Status administrasi" subtitle="Berdasarkan data terkini" /><div className="admin-admin-status"><p><span>UKT belum lunas</span><strong>{tuitionUnpaid} mahasiswa</strong></p><p><span>KRS tidak aktif</span><strong>{pendingKrs} enrollment</strong></p><p><span>KHS belum dipublikasikan</span><strong>{pendingKhs} mahasiswa</strong></p><p><span>Jadwal bentrok</span><strong>{scheduleConflicts}</strong></p></div></section>
        <section className="admin-panel"><PanelHeading title="Perlu ditindaklanjuti" subtitle="Temuan dihitung dari data sistem" /><div className="admin-task-list">{todo.filter(([count]) => count > 0).map(([count, text, destination]) => <button key={text} onClick={() => navigate(destination)}><span className="admin-task-count">{count}</span><strong>{text}</strong><Icon name="chevron" size={15} /></button>)}{todo.every(([count]) => count === 0) && <p className="admin-chart-footnote">Tidak ada tindak lanjut saat ini.</p>}</div></section>
        <section className="admin-panel"><PanelHeading title="Aktivitas terkini" subtitle="Tercatat lokal selama sesi ini" action={<button className="admin-text-button" onClick={() => navigate('activities')}>Lihat semua</button>} /><ActivityList items={activities.slice(0, 4)} /></section>
      </div>
    </>
  }

  function reports() {
    const rows = rowsForPage()
    const categories = [...new Set(activeReportRows.map((row) => row.kategori))]
    return <><PageHeading title={titles.reports} subtitle="Rekap agregat berdasarkan data backend yang tersedia." actions={<><button className="admin-button admin-button--secondary" onClick={() => window.print()}><Icon name="file" />Cetak</button><button className="admin-button admin-button--primary" onClick={() => exportCsv(rows, 'rekap-akademik.csv')}><Icon name="download" />Ekspor CSV</button></>} /><div className="admin-report-filters"><label>Kategori<select value={reportCategory} onChange={(event) => setReportCategory(event.target.value)}><option value="">Semua kategori</option>{categories.map((category) => <option key={category}>{category}</option>)}</select></label></div><div className="admin-panel admin-report-panel"><PanelHeading title="Rekapitulasi akademik" subtitle="Tidak memuat data kontak pribadi." /><Table columns={columns.reports} rows={rows} onDetail={(row) => setDialog({ type: 'detail', title: row.kategori, row })} /></div></>
  }

  async function handleLogout() {
    const error = await endSession()
    routerNavigate('/', {
      replace: true,
      state: error ? { logoutWarning: 'Token lokal sudah dihapus, tetapi server belum mengonfirmasi logout.' } : undefined,
    })
  }

  function settings() {
    const initials = (user?.name || 'A').split(/\s+/).slice(0, 2).map((part) => part[0]).join('').toUpperCase()
    return <><PageHeading title={titles.settings} subtitle="Preferensi tampilan dashboard." /><div className="admin-settings-grid"><section className="admin-panel"><PanelHeading title="Akun aktif" subtitle="Informasi dari sesi backend." /><div className="admin-profile-card"><span className="admin-avatar admin-avatar--large">{initials}</span><div><strong>{user?.name || '—'}</strong><span>{user?.email || '—'}</span><small>{user?.role || '—'}</small></div></div></section><section className="admin-panel"><PanelHeading title="Preferensi tampilan" subtitle="Berlaku selama sesi ini." /><Preference title="Tabel lebih rapat" checked={compact} onChange={() => setCompact((value) => !value)} /></section><section className="admin-panel admin-settings-wide"><PanelHeading title="Ketersediaan ringkasan" subtitle="Batasan data endpoint admin." /><p className="admin-settings-footnote">Backend admin belum menyediakan nilai IPS terhitung atau ambang tindak lanjut kehadiran. Nilai-nilai tersebut tidak ditampilkan sebagai data resmi.</p></section></div></>
  }

  function renderTablePage() {
    const rows = rowsForPage()
    const entity = pageEntity[page]
    const filterKeys = [...new Set(rows.flatMap((row) => ['class', 'semester', 'status', 'category', 'day', 'teacher', 'course'].filter((key) => row[key] !== undefined)))]
    if (page === 'classes') filterKeys.push('code')
    const report = page === 'reports'
    return <>
      <PageHeading title={page === 'packages' ? 'Paket Semester' : page === 'cases' ? 'Surat Peringatan (SP)' : titles[page]} subtitle={page === 'packages' ? 'Susun paket mata kuliah berdasarkan data backend.' : pageDescriptions[page]} actions={<div className="admin-page-actions">{page === 'courses' && <button className="admin-button admin-button--secondary" onClick={() => navigate('packages')}>Kelola paket semester</button>}{page === 'packages' && <button className="admin-button admin-button--secondary" onClick={() => navigate('courses')}>Katalog mata kuliah</button>}{entity && <button className="admin-button admin-button--primary" onClick={openAdd}><Icon name="plus" />Tambah data</button>}{report && <button className="admin-button admin-button--primary" onClick={() => exportCsv(rows, 'rekap-akademik.csv')}>Ekspor CSV</button>}</div>} />
      {page === 'attendance' && <div className="admin-page-tabs"><button className="is-active" onClick={() => navigate('attendance')}>Rekap kehadiran</button><button onClick={() => navigate('cases')}>Surat Peringatan (SP)</button></div>}
      {page === 'cases' && <div className="admin-page-tabs"><button onClick={() => navigate('attendance')}>Rekap kehadiran</button><button className="is-active" onClick={() => navigate('cases')}>Surat Peringatan (SP)</button></div>}
      {page === 'schedules' && <div className={`admin-relation-notice${scheduleConflicts ? '' : ' admin-notice--ok'}`}><Icon name="clock" /><span><strong>{scheduleConflicts} bentrok terdeteksi otomatis</strong><small>Diperiksa terhadap dosen, ruang, kelas, hari, dan rentang waktu.</small></span></div>}
      {page === 'krs' && <div className="admin-relation-notice"><Icon name="file" /><span><strong>KRS mengikuti paket kelas, bukan pemilihan mata kuliah individual.</strong><small>KRS dikelola dan diajukan oleh mahasiswa.</small></span></div>}
      {page === 'khs' && <div className="admin-relation-notice"><Icon name="chart" /><span><strong>Status KHS disimpan langsung ke server.</strong><small>IPS tidak disediakan oleh endpoint admin dan tidak dihitung di browser.</small></span></div>}
      {page === 'attendance' && <div className="admin-relation-notice"><Icon name="check" /><span><strong>Rekap dikelompokkan dari catatan kehadiran backend.</strong><small>Tidak diterapkan ambang peringatan karena kebijakannya belum tersedia pada API.</small></span></div>}
      {page === 'ukt' && <div className="admin-report-cards"><Stat title="Tagihan" value={fmtMoney(ukt.filter((row) => matchesSemester(row.semester, selectedSemester)).reduce((sum, row) => sum + row.billed, 0))} icon="wallet" /><Stat title="Dibayar" value={fmtMoney(ukt.filter((row) => matchesSemester(row.semester, selectedSemester)).reduce((sum, row) => sum + row.paid, 0))} icon="check" /><Stat title="Total tunggakan" value={fmtMoney(ukt.filter((row) => matchesSemester(row.semester, selectedSemester)).reduce((sum, row) => sum + Math.max(0, row.billed - row.paid), 0))} icon="chart" /></div>}
      <section className="admin-panel admin-table-panel">
        <div className="admin-table-toolbar"><label className="admin-search"><Icon name="search" /><input aria-label="Cari data" placeholder="Cari pada data yang ditampilkan…" value={query} onChange={(event) => { setQuery(event.target.value); setPageNumber(1) }} /></label><div className="admin-filter-group">{filterKeys.map((key) => <select key={key} aria-label={`Filter ${filterLabels[key] || key}`} value={filters[key] || ''} onChange={(event) => { setFilters((current) => ({ ...current, [key]: event.target.value })); setPageNumber(1) }}><option value="">Semua {filterLabels[key] || key}</option>{[...new Set(rows.map((row) => row[key]).filter(Boolean))].map((value) => <option key={value}>{value}</option>)}</select>)}{(query || Object.values(filters).some(Boolean)) && <button className="admin-reset-button" onClick={() => { setQuery(''); setFilters({}); setPageNumber(1) }}>Reset</button>}</div></div>
        {['krs', 'khs', 'grades', 'ukt', 'attendance'].includes(page) && <div className="admin-table-toolbar"><label className="admin-filter-label">Filter semester<select value={selectedSemester} onChange={(event) => { setSelectedSemester(event.target.value); setPageNumber(1) }}>{semesters.map((semester) => <option key={semester}>{semester}</option>)}</select></label></div>}
        <div className="admin-table-wrap"><Table columns={columns[page] || []} rows={currentRows} onSort={(key) => setSort((current) => ({ key, direction: current.key === key && current.direction === 'asc' ? 'desc' : 'asc' }))} sort={sort} renderAction={rowAction} renderCell={(row, key) => {
          const value = row[key]
          if (['status', 'conflict', 'dueStatus'].includes(key)) return <Badge>{value}</Badge>
          if (['billed', 'paid', 'debt'].includes(key)) return fmtMoney(value || 0)
          if (key === 'date' || key === 'start' || key === 'end') return key === 'date' ? fmtDate(value) : value
          if (key === 'score') return Number.isFinite(value) ? value : 'Belum diisi'
          return value ?? '—'
        }} onDetail={(row) => setDialog({ type: 'detail', title: row.name || row.student || row.title || row.class || row.code || row.kategori || 'Detail', row, extra: detailsFor(row) })} emptyMessage={query || Object.values(filters).some(Boolean) ? 'Tidak ada data yang cocok dengan pencarian atau filter.' : 'Belum ada data untuk halaman ini.'} />{!currentRows.length && <div className="admin-empty-state"><strong>Tidak ada data</strong><p>{query ? 'Coba ubah pencarian atau filter.' : entity ? 'Gunakan Tambah data untuk membuat data baru.' : 'Belum ada data yang tersedia dari server.'}</p></div>}</div>
        <div className="admin-table-footer"><span>Menampilkan {currentRows.length ? (Math.min(pageNumber, totalPages) - 1) * pageSize + 1 : 0}–{Math.min(pageNumber * pageSize, visibleRows.length)} dari {visibleRows.length}</span><div className="admin-pagination"><button disabled={pageNumber <= 1} onClick={() => setPageNumber((value) => value - 1)}>‹</button><span>Halaman {Math.min(pageNumber, totalPages)} dari {totalPages}</span><button disabled={pageNumber >= totalPages} onClick={() => setPageNumber((value) => value + 1)}>›</button></div></div>
      </section>
    </>
  }

  const pageDescriptions = {
    students: 'Kelola akun mahasiswa dan lihat ringkasan akademik terkait.',
    classes: 'Kelola kelas, periode akademik, paket, dan relasi kelas.',
    teachers: 'Kelola data dosen serta distribusi beban dan jadwal mengajar.',
    courses: 'Katalog mata kuliah dan paket semester.',
    packages: 'Susun paket kelas; sistem menolak mata kuliah duplikat.',
    schedules: 'Validasi bentrok jadwal dosen, ruang, dan kelas secara otomatis.',
    krs: 'Enrollment mahasiswa yang tersimpan pada backend.',
    grades: 'Periksa kelengkapan nilai akhir mahasiswa per mata kuliah.',
    khs: 'Lihat status KHS dan publikasikan perubahan melalui server.',
    ukt: 'Pantau tagihan dan tunggakan UKT mahasiswa.',
    attendance: 'Pantau kehadiran mahasiswa per mata kuliah.',
    cases: 'Kelola surat peringatan (SP) mahasiswa.',
    documents: 'Kelola metadata dan status dokumen akademik.',
    announcements: 'Kelola informasi dan pengumuman akademik.',
    reports: 'Rekapitulasi data akademik yang tersedia.',
    activities: 'Riwayat perubahan yang terjadi selama sesi browser ini.',
  }

  let content
  if (isLoading) {
    content = <div style={{ padding: '50px', textAlign: 'center' }}>Memuat data dari server...</div>
  } else if (loadError) {
    content = <div className="admin-load-error" role="alert"><strong>Data backend tidak dapat dimuat</strong><p>{loadError}</p><button className="admin-button admin-button--secondary" onClick={fetchAll}>Coba lagi</button></div>
  } else {
    content = page === 'dashboard' ? dashboard() : page === 'settings' ? settings() : page === 'reports' ? reports() : renderTablePage()
  }

  return <div className={`admin-app${compact ? ' admin-app--compact' : ''}`}>
    {mobileOpen && <button className="admin-nav-scrim" aria-label="Tutup navigasi" onClick={() => setMobileOpen(false)} />}
    <AdminSidebar page={page} navigate={navigate} mobileOpen={mobileOpen} setMobileOpen={setMobileOpen} user={user} onLogout={handleLogout} />
    <main className="admin-main">
      <AdminHeader page={page} setMobileOpen={setMobileOpen} user={user} onLogout={handleLogout} />
      <div className="admin-content">{page === 'courses' && <div className="admin-page-tabs"><button className="is-active" onClick={() => navigate('courses')}>Katalog mata kuliah</button><button onClick={() => navigate('packages')}>Paket semester</button></div>}{page === 'packages' && <div className="admin-page-tabs"><button onClick={() => navigate('courses')}>Katalog mata kuliah</button><button className="is-active" onClick={() => navigate('packages')}>Paket semester</button></div>}{content}<footer className="admin-footer"><span>EduTrack Campus · Administrasi akademik</span></footer></div>
    </main>
    {dialog && <Modal title={dialog.type === 'detail' ? dialog.title : dialog.type === 'confirm' ? dialog.title : `${dialog.item ? 'Edit' : 'Tambah'} ${pageConfig[dialog.entity]?.singular || 'data'}`} onClose={() => setDialog(null)}>
      {dialog.type === 'confirm' && <><p className="admin-confirm-copy">{dialog.text}</p><div className="admin-form-actions"><button className="admin-button admin-button--secondary" onClick={() => setDialog(null)}>Batal</button><button className="admin-button admin-button--primary" onClick={dialog.action}>{dialog.label}</button></div></>}
      {dialog.type === 'detail' && <><dl className="admin-detail-list">{[['Ringkasan', Object.entries(dialog.row).filter(([key]) => key !== 'id').map(([key, value]) => `${key}: ${value ?? '—'}`).join(' · ')], ...(dialog.extra || [])].map(([label, value]) => <div key={label}><dt>{label}</dt><dd>{value}</dd></div>)}</dl><div className="admin-form-actions">{pageEntity[page] && <button className="admin-button admin-button--primary" onClick={() => openEdit(dialog.row)}>Edit data</button>}{pageEntity[page] && <button className="admin-button admin-button--danger" onClick={() => { setDialog(null); removeRecord(pageEntity[page], dialog.row) }}>Hapus data</button>}<button className="admin-button admin-button--secondary" onClick={() => setDialog(null)}>Tutup</button></div></>}
      {dialog.type === 'form' && <GenericForm key={`${dialog.entity}-${dialog.item?.id || 'new'}`} config={pageConfig[dialog.entity]} entity={dialog.entity} item={dialog.item} courses={courses} classes={classes} activePeriod={activePeriod} onClose={() => setDialog(null)} onSave={(values) => saveRecord(dialog.entity, values, dialog.item)} />}
    </Modal>}
    {toast && <div className="admin-toast" role="status">{toast}<button onClick={() => setToast('')} aria-label="Tutup notifikasi"><Icon name="close" size={14} /></button></div>}
  </div>
}

function GenericForm({ config, entity, item, courses, classes, activePeriod, onClose, onSave }) {
  const visibleFields = config.fields.filter(([key]) => {
    if (item && key === 'password') return false
    return true
  })

  const [values, setValues] = useState(() => {
    const initial = Object.fromEntries(config.fields.map(([key]) => [key, item?.[key] ?? '']))
    if (entity === 'package' && item) initial.courseIds = item.courseIds || []
    if (entity === 'package') initial.courseIds ||= []
    if (entity === 'package' && item) initial.classIds = item.classIds || []
    if (entity === 'package') initial.classIds ||= []
    if (entity === 'package') initial.status ||= 'Draf'
    if (entity === 'class') {
      initial.year ||= activePeriod?.year || ''
      initial.term ||= activePeriod?.semester || ''
      initial.status ||= 'Aktif'
    }
    if (entity === 'schedule') {
      initial.semester ||= activePeriod?.year && activePeriod?.semester ? `${activePeriod.year} ${activePeriod.semester}` : ''
    }
    if (entity === 'ukt') initial.semester ||= activePeriod?.year || ''
    if (entity === 'case') {
      initial.level ||= 'SP 1'
      initial.status ||= 'Draf'
    }
    if (entity === 'document') {
      initial.type ||= 'Dokumen pendukung'
      initial.status ||= 'Draf'
      initial.semester ||= activePeriod?.year && activePeriod?.semester ? `${activePeriod.year} ${activePeriod.semester}` : ''
    }
    if (entity === 'announcement') initial.status ||= 'Draf'
    return initial
  })
  const [errors, setErrors] = useState({})
  async function submit(event) {
    event.preventDefault()
    const invalid = {}
    visibleFields.forEach(([key, label]) => {
      const isOptional =
        (key === 'status' && entity === 'class') ||
        key === 'nim' ||
        key === 'nidn' ||
        key === 'nip' ||
        key === 'programStudi' ||
        (key === 'password' && item) ||
        (entity === 'class' && key === 'packageId')

      if (!isOptional && (values[key] === '' || values[key] === undefined)) {
        invalid[key] = `${label} wajib diisi.`
      }
    })
    if (entity === 'student' && values.nim && !/^\d{5,15}$/.test(values.nim)) {
      invalid.nim = 'NIM harus terdiri dari 5–15 digit.'
    }
    if (values.email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(values.email)) {
      invalid.email = 'Format email tidak valid.'
    }
    if (!item && ['student', 'teacher'].includes(entity) && String(values.password || '').length < 8) {
      invalid.password = 'Password minimal 8 karakter.'
    }
    if (entity === 'course' && Number(values.credits) > 6) invalid.credits = 'Jumlah SKS maksimal 6.'
    if (entity === 'course' && Number(values.term) < 1) invalid.term = 'Semester harus lebih dari 0.'
    if (entity === 'grade' && (!Number.isFinite(Number(values.score)) || Number(values.score) < 0 || Number(values.score) > 100)) invalid.score = 'Nilai harus 0–100.'
    if (entity === 'package' && !values.courseIds?.length) invalid.courseIds = 'Pilih minimal satu mata kuliah.'
    if (entity === 'ukt' && Number(values.billed) < 0) invalid.billed = 'Tagihan tidak boleh bernilai negatif.'
    if (entity === 'ukt' && Number(values.paid) < 0) invalid.paid = 'Pembayaran tidak boleh bernilai negatif.'
    if (entity === 'ukt' && Number(values.paid) > Number(values.billed)) invalid.paid = 'Jumlah pembayaran tidak boleh melebihi tagihan.'
    if (entity === 'announcement' && values.end < values.start) invalid.end = 'Tanggal berakhir tidak boleh sebelum tanggal mulai.'
    setErrors(invalid)
    if (Object.keys(invalid).length) return
    const normalized = { ...values }
    for (const key of ['credits', 'term', 'score', 'billed', 'paid', 'present', 'permit', 'sick', 'absent', 'meetings']) {
      if (normalized[key] !== '' && normalized[key] !== undefined) normalized[key] = Number(normalized[key])
    }
    if (entity === 'package') {
      normalized.courseIds = (values.courseIds || []).map(Number)
      normalized.classIds = (values.classIds || []).map(Number)
    }
    const serverError = await onSave(normalized)
    if (serverError) {
      if (serverError.field) {
        setErrors((current) => ({ ...current, [serverError.field]: serverError.message }))
      } else {
        setErrors((current) => ({ ...current, _form: serverError.message }))
      }
    }
  }
  return (
    <form className="admin-entity-form" onSubmit={submit} noValidate>
      {errors._form && <p className="admin-field-error" role="alert">{errors._form}</p>}
      <div className="admin-form-grid">
        {visibleFields.map(([key, label, type, options]) => {
          const isOptional =
            (key === 'status' && entity === 'class') ||
            key === 'nim' ||
            key === 'nidn' ||
            key === 'nip' ||
            key === 'programStudi' ||
            (key === 'password' && item) ||
            (entity === 'class' && key === 'packageId')

          return (
            <div className={`admin-form-field${type === 'textarea' ? ' admin-form-field--wide' : ''}`} key={key}>
              <label htmlFor={`field-${key}`}>{label}{!isOptional ? ' *' : ''}</label>
              {type === 'select' ? (
                <select id={`field-${key}`} value={values[key] ?? ''} onChange={(event) => setValues((current) => ({ ...current, [key]: event.target.value }))}>
                  <option value="">Pilih {label.toLowerCase()}</option>
                  {options.map(([value, text]) => <option key={value} value={value}>{text}</option>)}
                </select>
              ) : type === 'textarea' ? (
                <textarea id={`field-${key}`} rows="4" value={values[key] ?? ''} onChange={(event) => setValues((current) => ({ ...current, [key]: event.target.value }))} />
              ) : (
                <input id={`field-${key}`} type={type} min={type === 'number' ? 0 : undefined} value={values[key] ?? ''} onChange={(event) => setValues((current) => ({ ...current, [key]: event.target.value }))} />
              )}
              {errors[key] && <small className="admin-field-error" role="alert">{errors[key]}</small>}
            </div>
          )
        })}
        {entity === 'package' && <>
          <fieldset className="admin-form-field admin-form-field--wide admin-course-picker"><legend>Mata kuliah paket *</legend>{courses.map((course) => <label key={course.id}><input type="checkbox" checked={values.courseIds?.includes(course.id) || false} onChange={(event) => setValues((current) => ({ ...current, courseIds: event.target.checked ? [...(current.courseIds || []), course.id] : current.courseIds.filter((courseId) => courseId !== course.id) }))} />{course.code} · {course.name} ({course.credits} SKS)</label>)}{errors.courseIds && <small className="admin-field-error">{errors.courseIds}</small>}<strong>Total paket: {values.courseIds?.reduce((sum, courseId) => sum + (courses.find((course) => course.id === courseId)?.credits || 0), 0) || 0} SKS</strong></fieldset>
          <fieldset className="admin-form-field admin-form-field--wide admin-course-picker"><legend>Kelas yang menggunakan paket</legend>{classes.map((classRow) => <label key={classRow.id}><input type="checkbox" checked={values.classIds?.includes(classRow.id) || false} onChange={(event) => setValues((current) => ({ ...current, classIds: event.target.checked ? [...(current.classIds || []), classRow.id] : current.classIds.filter((classId) => classId !== classRow.id) }))} />{classRow.code}</label>)}</fieldset>
        </>}
      </div>
      <div className="admin-form-actions">
        <button type="button" className="admin-button admin-button--secondary" onClick={onClose}>Batal</button>
        <button type="submit" className="admin-button admin-button--primary">Simpan data</button>
      </div>
    </form>
  )
}

export default AdminAcademicDashboard
