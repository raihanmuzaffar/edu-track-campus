class MahasiswaDemoData {
  const MahasiswaDemoData._();

  static const Map<String, dynamic> student = {
    'name': 'Nadia Putri Rahma',
    'nim': '2311042',
    'program_studi': 'Teknologi Rekayasa Komputer Jaringan',
    'email': 'nadia.putri@demo.edutrack.id',
    'role': 'mahasiswa',
  };

  static const List<Map<String, dynamic>> schedules = [
    {
      'course': {'name': 'Pemrograman Mobile'},
      'day': 'Senin',
      'start_time': '08:00',
      'end_time': '10:30',
      'room': 'Lab Komputer 2',
    },
    {
      'course': {'name': 'Basis Data'},
      'day': 'Senin',
      'start_time': '13:00',
      'end_time': '15:30',
      'room': 'Ruang 204',
    },
  ];

  static const List<Map<String, dynamic>> announcements = [
    {
      'title': 'Pengisian KRS semester berikutnya',
      'category': 'Akademik',
      'start_date': '2026-11-12',
    },
    {
      'title': 'Jadwal evaluasi tengah semester',
      'category': 'Informasi',
      'start_date': '2026-11-18',
    },
  ];

  static const List<Map<String, dynamic>> krsEnrollments = [
    {
      'class': {
        'name': 'Kelas B',
        'year': '2026/2027',
        'semester': '6',
        'day': 'Senin',
        'start_time': '08:00',
        'end_time': '10:30',
        'course': {
          'code': 'IF310',
          'name': 'Kecerdasan Buatan',
          'semester': 6,
          'sks': 3,
        },
      },
    },
    {
      'class': {
        'name': 'Kelas B',
        'year': '2026/2027',
        'semester': '6',
        'day': 'Rabu',
        'start_time': '10:00',
        'end_time': '13:20',
        'course': {
          'code': 'IF315',
          'name': 'Rekayasa Perangkat Lunak',
          'semester': 6,
          'sks': 4,
        },
      },
    },
    {
      'class': {
        'name': 'Kelas A',
        'year': '2026/2027',
        'semester': '5',
        'day': 'Selasa',
        'start_time': '08:00',
        'end_time': '10:30',
        'course': {
          'code': 'IF221',
          'name': 'Struktur Data',
          'semester': 5,
          'sks': 3,
        },
      },
    },
    {
      'class': {
        'name': 'Kelas A',
        'year': '2026/2027',
        'semester': '5',
        'day': 'Kamis',
        'start_time': '10:00',
        'end_time': '12:30',
        'course': {
          'code': 'IF224',
          'name': 'Interaksi Manusia dan Komputer',
          'semester': 5,
          'sks': 3,
        },
      },
    },
    {
      'class': {
        'name': 'Kelas B',
        'year': '2025/2026',
        'semester': '4',
        'day': 'Senin',
        'start_time': '10:00',
        'end_time': '13:20',
        'course': {
          'code': 'IF215',
          'name': 'Pemrograman Berorientasi Objek',
          'semester': 4,
          'sks': 4,
        },
      },
    },
    {
      'class': {
        'name': 'Kelas B',
        'year': '2025/2026',
        'semester': '4',
        'day': 'Rabu',
        'start_time': '08:00',
        'end_time': '10:30',
        'course': {
          'code': 'IF218',
          'name': 'Jaringan Komputer',
          'semester': 4,
          'sks': 3,
        },
      },
    },
    {
      'class': {
        'name': 'Kelas C',
        'year': '2025/2026',
        'semester': '3',
        'day': 'Selasa',
        'start_time': '08:00',
        'end_time': '10:30',
        'course': {
          'code': 'IF101',
          'name': 'Pengantar Teknologi Informasi',
          'semester': 3,
          'sks': 3,
        },
      },
    },
    {
      'class': {
        'name': 'Kelas C',
        'year': '2025/2026',
        'semester': '3',
        'day': 'Kamis',
        'start_time': '10:00',
        'end_time': '12:30',
        'course': {
          'code': 'MT101',
          'name': 'Matematika Dasar',
          'semester': 3,
          'sks': 3,
        },
      },
    },
    {
      'class': {
        'name': 'Kelas B',
        'year': '2024/2025',
        'semester': '2',
        'day': 'Senin',
        'start_time': '08:00',
        'end_time': '11:20',
        'course': {
          'code': 'IF105',
          'name': 'Algoritma dan Pemrograman',
          'semester': 2,
          'sks': 4,
        },
      },
    },
    {
      'class': {
        'name': 'Kelas B',
        'year': '2024/2025',
        'semester': '2',
        'day': 'Rabu',
        'start_time': '08:00',
        'end_time': '10:30',
        'course': {
          'code': 'MT102',
          'name': 'Matematika Diskrit',
          'semester': 2,
          'sks': 3,
        },
      },
    },
    {
      'class': {
        'name': 'Kelas A',
        'year': '2024/2025',
        'semester': '1',
        'day': 'Selasa',
        'start_time': '08:00',
        'end_time': '09:40',
        'course': {
          'code': 'IF100',
          'name': 'Pengantar Ilmu Komputer',
          'semester': 1,
          'sks': 2,
        },
      },
    },
    {
      'class': {
        'name': 'Kelas A',
        'year': '2024/2025',
        'semester': '1',
        'day': 'Kamis',
        'start_time': '08:00',
        'end_time': '11:20',
        'course': {
          'code': 'MT100',
          'name': 'Kalkulus I',
          'semester': 1,
          'sks': 4,
        },
      },
    },
  ];

  static const List<Map<String, dynamic>> attendances = [
    {
      'class_id': 101,
      'date': '2026-08-24',
      'status': 'hadir',
      'class': {
        'name': 'Kelas A',
        'day': 'Senin',
        'start_time': '08:00',
        'end_time': '10:30',
        'room': 'Lab Mobile',
        'dosen': {'name': 'Ratna Puspita, M.Kom.'},
        'course': {'code': 'IF301', 'name': 'Pemrograman Mobile', 'sks': 3},
      },
    },
    {
      'class_id': 101,
      'date': '2026-08-31',
      'status': 'hadir',
      'class': {
        'name': 'Kelas A',
        'course': {'code': 'IF301', 'name': 'Pemrograman Mobile', 'sks': 3},
      },
    },
    {
      'class_id': 101,
      'date': '2026-09-07',
      'status': 'alpa',
      'class': {
        'name': 'Kelas A',
        'course': {'code': 'IF301', 'name': 'Pemrograman Mobile', 'sks': 3},
      },
    },
    {
      'class_id': 101,
      'date': '2026-09-14',
      'status': 'hadir',
      'class': {
        'name': 'Kelas A',
        'course': {'code': 'IF301', 'name': 'Pemrograman Mobile', 'sks': 3},
      },
    },
    {
      'class_id': 101,
      'date': '2026-09-21',
      'status': 'hadir',
      'class': {
        'name': 'Kelas A',
        'course': {'code': 'IF301', 'name': 'Pemrograman Mobile', 'sks': 3},
      },
    },
    {
      'class_id': 101,
      'date': '2026-09-28',
      'status': 'izin',
      'class': {
        'name': 'Kelas A',
        'course': {'code': 'IF301', 'name': 'Pemrograman Mobile', 'sks': 3},
      },
    },
    {
      'class_id': 202,
      'date': '2026-08-25',
      'status': 'hadir',
      'class': {
        'name': 'Kelas B',
        'day': 'Selasa',
        'start_time': '13:00',
        'end_time': '15:30',
        'room': 'Ruang 204',
        'dosen': {'name': 'Dimas Pratama, M.T.'},
        'course': {'code': 'IF302', 'name': 'Basis Data', 'sks': 3},
      },
    },
    {
      'class_id': 202,
      'date': '2026-09-01',
      'status': 'hadir',
      'class': {
        'name': 'Kelas B',
        'course': {'code': 'IF302', 'name': 'Basis Data', 'sks': 3},
      },
    },
    {
      'class_id': 202,
      'date': '2026-09-08',
      'status': 'hadir',
      'class': {
        'name': 'Kelas B',
        'course': {'code': 'IF302', 'name': 'Basis Data', 'sks': 3},
      },
    },
    {
      'class_id': 202,
      'date': '2026-09-15',
      'status': 'hadir',
      'class': {
        'name': 'Kelas B',
        'course': {'code': 'IF302', 'name': 'Basis Data', 'sks': 3},
      },
    },
    {
      'class_id': 202,
      'date': '2026-09-22',
      'status': 'sakit',
      'class': {
        'name': 'Kelas B',
        'course': {'code': 'IF302', 'name': 'Basis Data', 'sks': 3},
      },
    },
  ];

  static const List<Map<String, dynamic>> grades = [
    {
      'score': 92.5,
      'letter': 'A',
      'class': {
        'year': '2026/2027',
        'semester': '6',
        'name': 'Kelas A',
        'course': {'code': 'IF301', 'name': 'Pemrograman Mobile', 'sks': 3},
      },
    },
    {
      'score': 87,
      'letter': 'A',
      'class': {
        'year': '2026/2027',
        'semester': '6',
        'name': 'Kelas A',
        'course': {'code': 'IF302', 'name': 'Basis Data', 'sks': 3},
      },
    },
    {
      'score': 81,
      'letter': 'B',
      'class': {
        'year': '2026/2027',
        'semester': '6',
        'name': 'Kelas B',
        'course': {'code': 'IF303', 'name': 'Jaringan Komputer', 'sks': 2},
      },
    },
    {
      'score': 89,
      'letter': 'A',
      'class': {
        'year': '2025/2026',
        'semester': '5',
        'name': 'Kelas A',
        'course': {'code': 'IF221', 'name': 'Struktur Data', 'sks': 3},
      },
    },
    {
      'score': 78,
      'letter': 'B',
      'class': {
        'year': '2025/2026',
        'semester': '5',
        'name': 'Kelas A',
        'course': {
          'code': 'IF224',
          'name': 'Interaksi Manusia dan Komputer',
          'sks': 3,
        },
      },
    },
  ];
}
