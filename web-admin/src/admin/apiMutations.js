export function buildApiMutation(entity, values, item, classes) {
  const recordId = item?.id
  const mutation = (createUrl, updateUrl, payload) => ({
    url: recordId ? `${updateUrl}?id=${recordId}` : createUrl,
    method: recordId ? 'put' : 'post',
    payload,
  })

  if (entity === 'schedule') {
    const selectedClass = classes.find((classRow) => String(classRow.id) === String(values.classId))
    if (!selectedClass) return null
    return mutation(
      '/admin/schedules',
      '/admin/schedules/update',
      {
        semester: values.semester, class_id: Number(values.classId), course_id: Number(selectedClass.courseId),
        teacher_id: Number(selectedClass.dosenId), day: values.day, start_time: values.start,
        end_time: values.end, room: values.room,
      },
    )
  }

  const mutations = {
    student: () => mutation('/admin/users/create', '/admin/users/update', {
      name: values.name, email: values.email, role: 'mahasiswa',
      password: values.password || undefined, nim: values.nim || '',
      program_studi: values.programStudi || '',
    }),
    teacher: () => mutation('/admin/users/create', '/admin/users/update', {
      name: values.name, email: values.email, role: 'dosen',
      password: values.password || undefined, nidn: values.nidn || '',
      nip: values.nip || '', program_studi: values.programStudi || '',
    }),
    course: () => mutation('/courses', '/courses/update', {
      code: values.code, name: values.name, sks: Number(values.credits), semester: Number(values.term),
    }),
    class: () => mutation('/classes', '/classes/update', {
      name: values.name, course_id: Number(values.courseId), dosen_id: Number(values.dosenId),
      day: values.day, start_time: values.startTime, end_time: values.endTime, room: values.room,
      year: values.year, semester: values.term, status: values.status || 'Aktif',
      package_id: values.packageId ? Number(values.packageId) : null,
    }),
    package: () => mutation('/admin/packages', '/admin/packages/update', {
      name: values.name, term: Number(values.term), status: values.status,
      course_ids: (values.courseIds || []).map(Number), class_ids: (values.classIds || []).map(Number),
    }),
    ukt: () => mutation('/admin/ukt', '/admin/ukt/update', {
      student_id: Number(values.studentId), semester: values.semester,
      billed: Number(values.billed), paid: Number(values.paid), due_date: values.due,
    }),
    announcement: () => mutation('/admin/announcements', '/admin/announcements/update', {
      title: values.title, category: values.category, content: values.content,
      start_date: values.start, end_date: values.end, status: values.status,
    }),
    case: () => mutation('/admin/cases', '/admin/cases/update', {
      student_id: Number(values.studentId), level: values.level,
      reason: values.reason, followup: values.followup, status: values.status,
    }),
    document: () => mutation('/admin/documents', '/admin/documents/update', {
      student_id: Number(values.studentId), type: values.type, semester: values.semester,
      status: values.status, date: values.date,
    }),
  }

  return mutations[entity]?.() || null
}
