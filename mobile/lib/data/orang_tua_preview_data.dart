class OrangTuaDashboardData {
  const OrangTuaDashboardData({
    required this.isDemo,
    this.student,
    this.parent,
    this.attendance,
    this.grades = const [],
    this.semesters = const [],
    this.financial,
    this.schedules = const [],
    this.announcements = const [],
  });

  final bool isDemo;
  final StudentProfile? student;
  final ParentAccount? parent;
  final AttendanceOverview? attendance;
  final List<CourseGrade> grades;
  final List<AcademicSemester> semesters;
  final FinancialOverview? financial;
  final List<ClassSchedule> schedules;
  final List<CampusAnnouncement> announcements;

  static const empty = OrangTuaDashboardData(isDemo: false);

  static final demo = OrangTuaDashboardData(
    isDemo: true,
    student: StudentProfile(
      name: 'Nadia Putri',
      nim: 'DEMO-240018',
      studyProgram: 'Sistem Informasi',
      faculty: 'Fakultas Teknologi Informasi',
      semester: 5,
    ),
    parent: ParentAccount(
      name: 'Budi Santoso',
      email: 'orangtua.demo@example.test',
      relation: 'Orang tua',
    ),
    attendance: AttendanceOverview(
      present: 18,
      excused: 2,
      sick: 1,
      absent: 1,
      records: [
        AttendanceRecord(
          date: 'Senin, 9 November 2026',
          course: 'Interaksi Manusia dan Komputer',
          status: AttendanceStatus.present,
        ),
        AttendanceRecord(
          date: 'Jumat, 6 November 2026',
          course: 'Basis Data Lanjut',
          status: AttendanceStatus.excused,
        ),
        AttendanceRecord(
          date: 'Rabu, 4 November 2026',
          course: 'Rekayasa Perangkat Lunak',
          status: AttendanceStatus.present,
        ),
      ],
    ),
    grades: [
      CourseGrade(
        course: 'Interaksi Manusia dan Komputer',
        code: 'IF205',
        credits: 3,
        score: 88,
        letter: 'A',
        gradePoint: 4.0,
        semester: 'Semester 5 · 2026/2027',
      ),
      CourseGrade(
        course: 'Basis Data Lanjut',
        code: 'IF207',
        credits: 3,
        score: 82,
        letter: 'A-',
        gradePoint: 3.7,
        semester: 'Semester 5 · 2026/2027',
      ),
      CourseGrade(
        course: 'Rekayasa Perangkat Lunak',
        code: 'IF209',
        credits: 3,
        score: 76,
        letter: 'B+',
        gradePoint: 3.3,
        semester: 'Semester 5 · 2026/2027',
      ),
    ],
    semesters: [
      AcademicSemester(
        id: '2024-1',
        label: 'Semester 1 · 2024/2025',
        shortLabel: 'S1',
        cumulativeGpa: 3.42,
        grades: [
          CourseGrade(
            course: 'Pengantar Teknologi Informasi',
            code: 'IF101',
            credits: 3,
            score: 85,
            letter: 'A-',
            gradePoint: 3.7,
            semester: 'Semester 1 · 2024/2025',
          ),
          CourseGrade(
            course: 'Matematika Komputasi',
            code: 'IF103',
            credits: 3,
            score: 78,
            letter: 'B+',
            gradePoint: 3.3,
            semester: 'Semester 1 · 2024/2025',
          ),
          CourseGrade(
            course: 'Logika Informatika',
            code: 'IF105',
            credits: 2,
            score: 81,
            letter: 'A-',
            gradePoint: 3.7,
            semester: 'Semester 1 · 2024/2025',
          ),
        ],
      ),
      AcademicSemester(
        id: '2025-1',
        label: 'Semester 2 · 2024/2025',
        shortLabel: 'S2',
        cumulativeGpa: 3.48,
        grades: [
          CourseGrade(
            course: 'Algoritma dan Pemrograman',
            code: 'IF102',
            credits: 3,
            score: 88,
            letter: 'A',
            gradePoint: 4.0,
            semester: 'Semester 2 · 2024/2025',
          ),
          CourseGrade(
            course: 'Struktur Data',
            code: 'IF104',
            credits: 3,
            score: 79,
            letter: 'B+',
            gradePoint: 3.3,
            semester: 'Semester 2 · 2024/2025',
          ),
          CourseGrade(
            course: 'Sistem Digital',
            code: 'IF106',
            credits: 2,
            score: 82,
            letter: 'A-',
            gradePoint: 3.7,
            semester: 'Semester 2 · 2024/2025',
          ),
        ],
      ),
      AcademicSemester(
        id: '2025-2',
        label: 'Semester 3 · 2025/2026',
        shortLabel: 'S3',
        cumulativeGpa: 3.55,
        grades: [
          CourseGrade(
            course: 'Jaringan Komputer',
            code: 'IF201',
            credits: 3,
            score: 84,
            letter: 'A-',
            gradePoint: 3.7,
            semester: 'Semester 3 · 2025/2026',
          ),
          CourseGrade(
            course: 'Analisis dan Desain Sistem',
            code: 'IF203',
            credits: 3,
            score: 80,
            letter: 'A-',
            gradePoint: 3.7,
            semester: 'Semester 3 · 2025/2026',
          ),
          CourseGrade(
            course: 'Statistika',
            code: 'IF205',
            credits: 2,
            score: 75,
            letter: 'B+',
            gradePoint: 3.3,
            semester: 'Semester 3 · 2025/2026',
          ),
        ],
      ),
      AcademicSemester(
        id: '2026-1',
        label: 'Semester 4 · 2025/2026',
        shortLabel: 'S4',
        cumulativeGpa: 3.61,
        grades: [
          CourseGrade(
            course: 'Pemrograman Berorientasi Objek',
            code: 'IF202',
            credits: 3,
            score: 90,
            letter: 'A',
            gradePoint: 4.0,
            semester: 'Semester 4 · 2025/2026',
          ),
          CourseGrade(
            course: 'Interaksi Digital',
            code: 'IF204',
            credits: 3,
            score: 82,
            letter: 'A-',
            gradePoint: 3.7,
            semester: 'Semester 4 · 2025/2026',
          ),
          CourseGrade(
            course: 'Manajemen Proyek TI',
            code: 'IF206',
            credits: 2,
            score: 76,
            letter: 'B+',
            gradePoint: 3.3,
            semester: 'Semester 4 · 2025/2026',
          ),
        ],
      ),
      AcademicSemester(
        id: '2026-2',
        label: 'Semester 5 · 2026/2027',
        shortLabel: 'S5',
        cumulativeGpa: 3.66,
        grades: [
          CourseGrade(
            course: 'Interaksi Manusia dan Komputer',
            code: 'IF205',
            credits: 3,
            score: 88,
            letter: 'A',
            gradePoint: 4.0,
            semester: 'Semester 5 · 2026/2027',
          ),
          CourseGrade(
            course: 'Basis Data Lanjut',
            code: 'IF207',
            credits: 3,
            score: 82,
            letter: 'A-',
            gradePoint: 3.7,
            semester: 'Semester 5 · 2026/2027',
          ),
          CourseGrade(
            course: 'Rekayasa Perangkat Lunak',
            code: 'IF209',
            credits: 3,
            score: 76,
            letter: 'B+',
            gradePoint: 3.3,
            semester: 'Semester 5 · 2026/2027',
          ),
        ],
      ),
    ],
    financial: FinancialOverview(
      activeSemesterId: '2026-2',
      semesterRecords: [
        TuitionSemesterRecord(
          id: '2024-1',
          order: 1,
          academicTerm: 'Semester 1 · 2024/2025',
          initialAmount: 3500000,
          reductionStatus: TuitionReductionStatus.notApplied,
          reductionAmount: 0,
          paymentStatus: TuitionPaymentStatus.paid,
          paymentDate: DateTime(2024, 9, 5),
        ),
        TuitionSemesterRecord(
          id: '2025-1',
          order: 2,
          academicTerm: 'Semester 2 · 2024/2025',
          initialAmount: 3500000,
          reductionStatus: TuitionReductionStatus.notApplied,
          reductionAmount: 0,
          paymentStatus: TuitionPaymentStatus.paid,
          paymentDate: DateTime(2025, 2, 10),
        ),
        TuitionSemesterRecord(
          id: '2025-2',
          order: 3,
          academicTerm: 'Semester 3 · 2025/2026',
          initialAmount: 3500000,
          reductionStatus: TuitionReductionStatus.rejected,
          reductionAmount: 2000000,
          reductionSubmittedAt: DateTime(2025, 8, 2),
          reductionNote: 'Contoh pengajuan ditolak untuk preview DEMO.',
          paymentStatus: TuitionPaymentStatus.paid,
          paymentDate: DateTime(2025, 9, 15),
        ),
        TuitionSemesterRecord(
          id: '2026-1',
          order: 4,
          academicTerm: 'Semester 4 · 2025/2026',
          initialAmount: 3500000,
          reductionStatus: TuitionReductionStatus.notApplied,
          reductionAmount: 0,
          paymentStatus: TuitionPaymentStatus.paid,
          paymentDate: DateTime(2026, 2, 3),
        ),
        TuitionSemesterRecord(
          id: '2026-2-pending',
          order: 5,
          academicTerm: 'Semester 5 · 2026/2027 (ilustrasi riwayat)',
          initialAmount: 3500000,
          reductionStatus: TuitionReductionStatus.processing,
          reductionAmount: 2000000,
          reductionSubmittedAt: DateTime(2026, 8, 3),
          reductionPeriod: 'Periode pengajuan 2026/2027',
          reductionNote:
              'Pengajuan masih diproses. Nominal awal tetap menjadi acuan '
              'sampai pengajuan disetujui.',
          paymentStatus: TuitionPaymentStatus.unpaid,
          dueDate: DateTime(2026, 11, 20),
          billNumber: 'DEMO-UKT-2026-005',
        ),
        TuitionSemesterRecord(
          id: '2026-2',
          order: 6,
          academicTerm: 'Semester 6 · 2026/2027',
          initialAmount: 3500000,
          reductionStatus: TuitionReductionStatus.approved,
          reductionAmount: 2000000,
          reductionSubmittedAt: DateTime(2026, 8, 10),
          reductionPeriod: 'Periode pengajuan 2026/2027',
          reductionNote:
              'Contoh keringanan yang disetujui. UKT final Rp1.500.000 '
              'menjadi acuan semester ini.',
          paymentStatus: TuitionPaymentStatus.unpaid,
          dueDate: DateTime(2026, 11, 20),
          billNumber: 'DEMO-UKT-2026-006',
        ),
      ],
    ),
    schedules: [
      ClassSchedule(
        weekday: 1,
        startTime: '08.00',
        endTime: '09.40',
        course: 'Interaksi Manusia dan Komputer',
        lecturer: 'Dr. Ratna Wulandari, M.Kom.',
        room: 'Gedung A · 203',
      ),
      ClassSchedule(
        weekday: 1,
        startTime: '13.00',
        endTime: '14.40',
        course: 'Basis Data Lanjut',
        lecturer: 'Fajar Pratama, M.T.',
        room: 'Gedung B · 105',
      ),
      ClassSchedule(
        weekday: 3,
        startTime: '10.00',
        endTime: '11.40',
        course: 'Rekayasa Perangkat Lunak',
        lecturer: 'Dewi Anggraini, M.Kom.',
        room: 'Gedung A · 301',
      ),
      ClassSchedule(
        weekday: 4,
        startTime: '09.00',
        endTime: '10.40',
        course: 'Analisis Proses Bisnis',
        lecturer: 'Dr. Riko Saputra, M.M.',
        room: 'Gedung C · 204',
      ),
    ],
    announcements: [
      CampusAnnouncement(
        category: 'Akademik',
        date: '10 Nov 2026',
        title: 'Jadwal ujian tengah semester',
        summary:
            'Jadwal UTS semester ganjil dapat dilihat melalui portal akademik.',
        body:
            'Jadwal Ujian Tengah Semester ganjil 2026/2027 telah tersedia. '
            'Mahasiswa diimbau memeriksa jadwal dan ruang ujian melalui portal '
            'akademik serta menghubungi bagian akademik jika ada data yang '
            'perlu dikonfirmasi.',
      ),
      CampusAnnouncement(
        category: 'Kemahasiswaan',
        date: '7 Nov 2026',
        title: 'Pekan kreativitas kampus',
        summary:
            'Pendaftaran kegiatan dan lokakarya mahasiswa dibuka minggu ini.',
        body:
            'Pekan Kreativitas Kampus akan menghadirkan rangkaian lokakarya, '
            'pameran karya, dan sesi berbagi bersama alumni. Informasi '
            'pendaftaran lebih lanjut tersedia di pusat kemahasiswaan.',
      ),
      CampusAnnouncement(
        category: 'Informasi',
        date: '3 Nov 2026',
        title: 'Pemeliharaan portal akademik',
        summary: 'Portal akademik dijadwalkan menjalani pemeliharaan pada akhir pekan.',
        body:
            'Portal akademik dijadwalkan menjalani pemeliharaan pada Sabtu '
            'pukul 22.00 hingga Minggu pukul 02.00. Mohon menyimpan pekerjaan '
            'yang sedang berlangsung sebelum waktu pemeliharaan.',
      ),
    ],
  );
}

class StudentProfile {
  const StudentProfile({
    required this.name,
    required this.nim,
    required this.studyProgram,
    required this.faculty,
    required this.semester,
  });

  final String name;
  final String nim;
  final String studyProgram;
  final String faculty;
  final int semester;
}

class ParentAccount {
  const ParentAccount({
    required this.name,
    required this.email,
    required this.relation,
  });

  final String name;
  final String email;
  final String relation;
}

class AttendanceOverview {
  const AttendanceOverview({
    required this.present,
    required this.excused,
    required this.sick,
    required this.absent,
    this.records = const [],
  });

  final int present;
  final int excused;
  final int sick;
  final int absent;
  final List<AttendanceRecord> records;

  int get total => present + excused + sick + absent;

  double get attendanceRate => total == 0 ? 0 : present / total;
}

enum AttendanceStatus { present, excused, sick, absent }

class AttendanceRecord {
  const AttendanceRecord({
    required this.date,
    required this.course,
    required this.status,
  });

  final String date;
  final String course;
  final AttendanceStatus status;
}

class CourseGrade {
  const CourseGrade({
    required this.course,
    required this.code,
    required this.credits,
    required this.semester,
    this.score,
    this.letter,
    this.gradePoint,
  });

  final String course;
  final String code;
  final int credits;
  final num? score;
  final String? letter;
  final double? gradePoint;
  final String semester;
}

class AcademicSemester {
  const AcademicSemester({
    required this.id,
    required this.label,
    required this.shortLabel,
    required this.cumulativeGpa,
    required this.grades,
  });

  final String id;
  final String label;
  final String shortLabel;
  final double cumulativeGpa;
  final List<CourseGrade> grades;

  int get totalCredits =>
      grades.fold(0, (total, grade) => total + grade.credits);

  double? get semesterGpa {
    final graded = grades.where((grade) => grade.gradePoint != null);
    final credits = graded.fold<int>(
      0,
      (total, grade) => total + grade.credits,
    );
    if (credits == 0) return null;
    final weightedPoints = graded.fold<double>(
      0,
      (total, grade) => total + grade.gradePoint! * grade.credits,
    );
    return weightedPoints / credits;
  }
}

enum TuitionPaymentStatus { paid, unpaid }

enum TuitionReductionStatus { notApplied, processing, approved, rejected }

class FinancialOverview {
  const FinancialOverview({
    required this.activeSemesterId,
    required this.semesterRecords,
  });

  final String activeSemesterId;
  final List<TuitionSemesterRecord> semesterRecords;

  TuitionSemesterRecord? get activeSemester {
    for (final record in semesterRecords) {
      if (record.id == activeSemesterId) return record;
    }
    return semesterRecords.isEmpty ? null : semesterRecords.last;
  }

  int get paidSemesterCount => semesterRecords
      .where((record) => record.paymentStatus == TuitionPaymentStatus.paid)
      .length;

  int get unpaidSemesterCount => semesterRecords
      .where((record) => record.paymentStatus == TuitionPaymentStatus.unpaid)
      .length;

  int get outstandingAmount => semesterRecords
      .where((record) => record.paymentStatus == TuitionPaymentStatus.unpaid)
      .fold(0, (total, record) => total + record.finalAmount);
}

class TuitionSemesterRecord {
  const TuitionSemesterRecord({
    required this.id,
    required this.order,
    required this.academicTerm,
    required this.initialAmount,
    required this.reductionStatus,
    required this.reductionAmount,
    required this.paymentStatus,
    this.paymentDate,
    this.dueDate,
    this.billNumber,
    this.reductionSubmittedAt,
    this.reductionPeriod,
    this.reductionNote,
  });

  final String id;
  final int order;
  final String academicTerm;
  final int initialAmount;
  final int reductionAmount;
  final TuitionReductionStatus reductionStatus;
  final TuitionPaymentStatus paymentStatus;
  final DateTime? paymentDate;
  final DateTime? dueDate;
  final String? billNumber;
  final DateTime? reductionSubmittedAt;
  final String? reductionPeriod;
  final String? reductionNote;

  int get approvedReductionAmount =>
      reductionStatus == TuitionReductionStatus.approved
      ? reductionAmount.clamp(0, initialAmount)
      : 0;

  int get finalAmount => initialAmount - approvedReductionAmount;

  int get paymentAmount =>
      paymentStatus == TuitionPaymentStatus.paid ? finalAmount : 0;
}

class ClassSchedule {
  const ClassSchedule({
    required this.weekday,
    required this.startTime,
    required this.endTime,
    required this.course,
    this.lecturer,
    this.room,
  });

  final int weekday;
  final String startTime;
  final String endTime;
  final String course;
  final String? lecturer;
  final String? room;

  String get weekdayName => switch (weekday) {
    1 => 'Senin',
    2 => 'Selasa',
    3 => 'Rabu',
    4 => 'Kamis',
    5 => 'Jumat',
    6 => 'Sabtu',
    7 => 'Minggu',
    _ => 'Hari belum tersedia',
  };
}

class CampusAnnouncement {
  const CampusAnnouncement({
    required this.category,
    required this.date,
    required this.title,
    required this.summary,
    required this.body,
  });

  final String category;
  final String date;
  final String title;
  final String summary;
  final String body;
}
