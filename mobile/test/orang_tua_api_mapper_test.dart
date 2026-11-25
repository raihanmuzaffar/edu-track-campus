import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/orang_tua_api_mapper.dart';
import 'package:mobile/data/orang_tua_preview_data.dart';

void main() {
  test('maps linked parent data without inventing unavailable fields', () {
    final data = OrangTuaApiMapper.fromResponses(
      parent: {'name': 'Orang Tua Uji', 'email': 'parent@example.test'},
      children: [
        {'id': 9, 'name': 'Zahra Uji', 'nim': 'TEST-09'},
        {'id': 4, 'name': 'Alya Uji', 'nim': 'TEST-04'},
      ],
      childProfile: {
        'name': 'Alya Uji',
        'nim': 'TEST-04',
        'program_studi': 'Sistem Informasi',
      },
      academicSummary: {
        'graded_sks': 6,
        'ipk': 3.5,
        'semesters': [
          {
            'year': '2025/2026',
            'semester': 'Genap',
            'courses': [
              {
                'course': 'Basis Data',
                'code': 'IF101',
                'sks': 3,
                'score': 88,
                'letter': 'A',
                'point': 4,
              },
            ],
          },
          {
            'year': '2024/2025',
            'semester': 'Ganjil',
            'courses': [
              {
                'course': 'Algoritma',
                'code': 'IF100',
                'sks': 3,
                'score': 80,
                'letter': 'B',
                'point': 3.3,
              },
            ],
          },
        ],
      },
      attendanceRecords: [
        {
          'date': '2025-03-10T00:00:00Z',
          'status': 'hadir',
          'class': {
            'course': {'name': 'Basis Data'},
          },
        },
        {
          'date': '2025-03-11T00:00:00Z',
          'status': 'izin',
          'class': {
            'course': {'name': 'Algoritma'},
          },
        },
      ],
      schedules: [
        {
          'course': 'Basis Data',
          'day': 'Senin',
          'start_time': '08:00',
          'end_time': '10:00',
          'room': 'Ruang Uji',
          'lecturer': 'Dosen Uji',
        },
      ],
      uktRecords: [
        {
          'id': 7,
          'semester': '2025/2026',
          'billed': 1000000,
          'paid': 250000,
          'due_date': '2025-04-15T00:00:00Z',
        },
      ],
      announcements: [
        {
          'title': 'Informasi Akademik',
          'category': 'Akademik',
          'content': 'Informasi uji.',
          'start_date': '2025-03-01T00:00:00Z',
        },
      ],
    );

    expect(data.linkedChildren.map((child) => child.id), ['4', '9']);
    expect(data.student?.faculty, isNull);
    expect(data.student?.semester, isNull);
    expect(data.semesters.map((semester) => semester.label), [
      '2024/2025 Ganjil',
      '2025/2026 Genap',
    ]);
    expect(
      data.semesters.every((semester) => semester.cumulativeGpa == null),
      isTrue,
    );
    expect(data.overallGpa, 3.5);
    expect(data.semesters.last.semesterGpa, 4);
    expect(data.attendance?.present, 1);
    expect(data.attendance?.excused, 1);
    expect(data.schedules.single.weekdayName, 'Senin');
    expect(
      data.financial?.activeSemester?.reductionStatus,
      TuitionReductionStatus.unknown,
    );
    expect(data.financial?.activeSemester?.paymentAmount, 250000);
    expect(data.financial?.outstandingAmount, 750000);
    expect(data.financial?.currentPeriodOnly, isTrue);
    expect(data.announcements.single.title, 'Informasi Akademik');
  });

  test('keeps an unlinked parent account distinct from empty API data', () {
    final data = OrangTuaApiMapper.fromResponses(
      parent: {'name': 'Orang Tua Uji', 'email': 'parent@example.test'},
      children: [],
      announcements: [],
    );

    expect(data.student, isNull);
    expect(data.linkedChildren, isEmpty);
    expect(data.parent?.name, 'Orang Tua Uji');
    expect(data.isDemo, isFalse);
  });

  test('maps linked child document metadata without file fields', () {
    final data = OrangTuaApiMapper.fromResponses(
      parent: {'name': 'Orang Tua Uji', 'email': 'parent@example.test'},
      children: [
        {'id': 12, 'name': 'Anak Uji', 'nim': 'TEST-12'},
      ],
      announcements: [],
      documents: [
        {
          'id': 8,
          'student_id': 12,
          'type': 'Transkrip',
          'semester': '2025/2026',
          'status': 'Lengkap',
          'date': '2026-02-10T00:00:00Z',
        },
      ],
    );

    expect(data.documents, hasLength(1));
    expect(data.documents.single.type, 'Transkrip');
    expect(data.documents.single.semester, '2025/2026');
    expect(data.documents.single.status, 'Lengkap');
    expect(data.documents.single.date, '10 Feb 2026');
  });

  test('maps an empty document response to an empty metadata state', () {
    final data = OrangTuaApiMapper.fromResponses(
      parent: {'name': 'Orang Tua Uji', 'email': 'parent@example.test'},
      children: [
        {'id': 12, 'name': 'Anak Uji', 'nim': 'TEST-12'},
      ],
      announcements: [],
      documents: [],
    );

    expect(data.documents, isEmpty);
  });
}
