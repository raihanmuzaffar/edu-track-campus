import assert from 'node:assert/strict'
import test from 'node:test'
import { buildApiMutation } from './apiMutations.js'

test('builds non-schedule CRUD mutations without requiring a selected class', () => {
  const mutation = buildApiMutation('student', {
    name: 'Mahasiswa Test',
    email: 'student.test@example.local',
    password: 'test-password',
    nim: '202600001',
    programStudi: 'TRKJ',
  }, null, [])

  assert.deepEqual(mutation, {
    url: '/admin/users/create',
    method: 'post',
    payload: {
      name: 'Mahasiswa Test',
      email: 'student.test@example.local',
      role: 'mahasiswa',
      password: 'test-password',
      nim: '202600001',
      program_studi: 'TRKJ',
    },
  })
})

test('derives schedule course and teacher from the selected class', () => {
  const mutation = buildApiMutation('schedule', {
    semester: '2026 Ganjil',
    classId: '4',
    day: 'Senin',
    start: '08:00',
    end: '10:00',
    room: 'Lab 1',
  }, null, [{ id: 4, courseId: 7, dosenId: 9 }])

  assert.equal(mutation.url, '/admin/schedules')
  assert.equal(mutation.method, 'post')
  assert.deepEqual(mutation.payload, {
    semester: '2026 Ganjil',
    class_id: 4,
    course_id: 7,
    teacher_id: 9,
    day: 'Senin',
    start_time: '08:00',
    end_time: '10:00',
    room: 'Lab 1',
  })
})

test('does not build a schedule mutation without a matching class', () => {
  assert.equal(buildApiMutation('schedule', { classId: 'missing' }, null, []), null)
})
