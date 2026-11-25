import 'orang_tua_preview_data.dart';

class OrangTuaApiMapper {
  static List<LinkedStudent> linkedStudents(Object? value) {
    final children = _objects(value, 'daftar anak')
        .map(
          (student) => LinkedStudent(
            id: _requiredId(student['id'], 'id anak'),
            name: _string(student['name'], 'Nama belum tersedia'),
            nim: _string(student['nim'], 'NIM belum tersedia'),
          ),
        )
        .toList();
    children.sort((left, right) => left.name.compareTo(right.name));
    return children;
  }

  static OrangTuaDashboardData fromResponses({
    required Map<String, dynamic> parent,
    required Object? children,
    required Object? announcements,
    Map<String, dynamic>? childProfile,
    Map<String, dynamic>? academicSummary,
    Object? attendanceRecords,
    Object? schedules,
    Object? uktRecords,
    Object? documents,
  }) {
    final linkedChildren = linkedStudents(children);
    final student = childProfile == null
        ? null
        : StudentProfile(
            name: _string(childProfile['name'], 'Nama belum tersedia'),
            nim: _string(childProfile['nim'], 'NIM belum tersedia'),
            studyProgram: _string(
              childProfile['program_studi'],
              'Program studi belum tersedia',
            ),
          );
    final semesters = _academicSemesters(academicSummary);
    final grades = semesters.expand((semester) => semester.grades).toList();
    final attendance = _attendanceOverview(attendanceRecords);
    final financial = _financialOverview(uktRecords);
    final hasGrades = (academicSummary?['graded_sks'] as num? ?? 0) > 0;
    final overallGpa = hasGrades
        ? (academicSummary?['ipk'] as num?)?.toDouble()
        : null;

    return OrangTuaDashboardData(
      isDemo: false,
      linkedChildren: linkedChildren,
      student: student,
      parent: ParentAccount(
        name: _string(parent['name'], 'Nama belum tersedia'),
        email: _string(parent['email'], 'Email belum tersedia'),
        relation: 'Orang tua',
      ),
      attendance: attendance,
      overallGpa: overallGpa,
      grades: grades,
      semesters: semesters,
      financial: financial,
      schedules: _classSchedules(schedules),
      announcements: _announcements(announcements),
      documents: _documents(documents),
    );
  }

  static List<AcademicSemester> _academicSemesters(
    Map<String, dynamic>? summary,
  ) {
    if (summary == null) return [];
    final semesters = _objects(summary['semesters'], 'semester akademik')
      ..sort(_compareSemesters);
    return semesters.map(_academicSemester).toList();
  }

  static int _compareSemesters(
    Map<String, dynamic> left,
    Map<String, dynamic> right,
  ) {
    final yearOrder = _string(
      left['year'],
      '',
    ).compareTo(_string(right['year'], ''));
    if (yearOrder != 0) return yearOrder;

    final leftTerm = _termOrder(_string(left['semester'], ''));
    final rightTerm = _termOrder(_string(right['semester'], ''));
    if (leftTerm != rightTerm) return leftTerm.compareTo(rightTerm);
    return _string(
      left['semester'],
      '',
    ).compareTo(_string(right['semester'], ''));
  }

  static int _termOrder(String semester) => switch (semester.toLowerCase()) {
    'ganjil' => 0,
    'genap' => 1,
    _ => 2,
  };

  static AcademicSemester _academicSemester(Map<String, dynamic> semester) {
    final year = _string(semester['year'], '');
    final term = _string(semester['semester'], '');
    final label = [year, term].where((part) => part.isNotEmpty).join(' ');
    final courseGrades = _objects(semester['courses'], 'nilai semester')
        .map(
          (course) => CourseGrade(
            course: _string(course['course'], 'Mata kuliah belum tersedia'),
            code: _string(course['code'], '-'),
            credits: (course['sks'] as num? ?? 0).toInt(),
            score: course['score'] as num?,
            letter: course['letter']?.toString(),
            gradePoint: (course['point'] as num?)?.toDouble(),
            semester: label,
          ),
        )
        .toList();

    return AcademicSemester(
      id: '$year-$term',
      label: label.isEmpty ? 'Periode belum tersedia' : label,
      shortLabel: term.isEmpty ? year : '$term $year',
      cumulativeGpa: null,
      grades: courseGrades,
    );
  }

  static AttendanceOverview? _attendanceOverview(Object? value) {
    if (value == null) return null;
    final records = _objects(value, 'riwayat absensi').map((record) {
      final date = _requiredDate(record['date'], 'tanggal absensi');
      final classData = _object(record['class']);
      final courseData = _object(classData?['course']);
      return _DatedAttendance(
        date,
        AttendanceRecord(
          date: _formatDate(date),
          course: _string(courseData?['name'], 'Mata kuliah belum tersedia'),
          status: _attendanceStatus(record['status']),
        ),
      );
    }).toList()..sort((left, right) => right.date.compareTo(left.date));
    if (records.isEmpty) return null;

    var present = 0;
    var excused = 0;
    var sick = 0;
    var absent = 0;
    for (final record in records) {
      switch (record.record.status) {
        case AttendanceStatus.present:
          present++;
        case AttendanceStatus.excused:
          excused++;
        case AttendanceStatus.sick:
          sick++;
        case AttendanceStatus.absent:
          absent++;
      }
    }

    return AttendanceOverview(
      present: present,
      excused: excused,
      sick: sick,
      absent: absent,
      records: records.map((record) => record.record).toList(),
    );
  }

  static AttendanceStatus _attendanceStatus(Object? value) =>
      switch (value?.toString().trim().toLowerCase()) {
        'hadir' => AttendanceStatus.present,
        'izin' => AttendanceStatus.excused,
        'sakit' => AttendanceStatus.sick,
        'alpa' => AttendanceStatus.absent,
        _ => throw const FormatException('Status absensi tidak dikenali.'),
      };

  static List<ClassSchedule> _classSchedules(Object? value) {
    final schedules = _objects(value, 'jadwal');
    return schedules.map((schedule) {
      final weekday = switch (_string(schedule['day'], '').toLowerCase()) {
        'senin' => 1,
        'selasa' => 2,
        'rabu' => 3,
        'kamis' => 4,
        'jumat' => 5,
        'sabtu' => 6,
        'minggu' => 7,
        _ => 0,
      };
      return ClassSchedule(
        weekday: weekday,
        startTime: _string(schedule['start_time'], '-'),
        endTime: _string(schedule['end_time'], '-'),
        course: _string(schedule['course'], 'Mata kuliah belum tersedia'),
        lecturer: _string(schedule['lecturer'], ''),
        room: _string(schedule['room'], ''),
      );
    }).toList();
  }

  static FinancialOverview? _financialOverview(Object? value) {
    final records = _objects(value, 'data UKT')
      ..sort((left, right) {
        final leftId = (left['id'] as num? ?? 0).toInt();
        final rightId = (right['id'] as num? ?? 0).toInt();
        return leftId.compareTo(rightId);
      });
    if (records.isEmpty) return null;

    final mappedRecords = [
      for (var index = 0; index < records.length; index++)
        _tuitionRecord(records[index], index),
    ];
    return FinancialOverview(
      activeSemesterId: mappedRecords.last.id,
      semesterRecords: mappedRecords,
      currentPeriodOnly: true,
    );
  }

  static TuitionSemesterRecord _tuitionRecord(
    Map<String, dynamic> record,
    int index,
  ) {
    final billed = (record['billed'] as num? ?? 0).round();
    final paid = (record['paid'] as num? ?? 0).round();
    final id = _string(record['id'], '${index + 1}');
    return TuitionSemesterRecord(
      id: id,
      order: index + 1,
      academicTerm: _string(record['semester'], 'Periode belum tersedia'),
      initialAmount: billed,
      reductionStatus: TuitionReductionStatus.unknown,
      reductionAmount: 0,
      paymentStatus: billed > 0 && paid >= billed
          ? TuitionPaymentStatus.paid
          : TuitionPaymentStatus.unpaid,
      paidAmount: paid,
      dueDate: _optionalDate(record['due_date']),
    );
  }

  static List<CampusAnnouncement> _announcements(Object? value) {
    return _objects(value, 'pengumuman').map((announcement) {
      final content = _string(announcement['content'], '');
      final startDate = _optionalDate(announcement['start_date']);
      return CampusAnnouncement(
        category: _string(announcement['category'], 'Informasi'),
        date: startDate == null
            ? 'Tanggal belum tersedia'
            : _formatDate(startDate),
        title: _string(announcement['title'], 'Pengumuman'),
        summary: content,
        body: content,
      );
    }).toList();
  }

  static List<StudentDocument> _documents(Object? value) {
    return _objects(value, 'dokumen anak').map((document) {
      final date = _optionalDate(document['date']);
      return StudentDocument(
        type: _string(document['type'], 'Jenis dokumen belum tersedia'),
        semester: _string(document['semester'], 'Periode belum tersedia'),
        status: _string(document['status'], 'Status belum tersedia'),
        date: date == null ? 'Tanggal belum tersedia' : _formatDate(date),
      );
    }).toList();
  }

  static Map<String, dynamic>? _object(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static List<Map<String, dynamic>> _objects(Object? value, String field) {
    if (value == null) return [];
    if (value is! List) {
      throw FormatException('Format $field tidak valid.');
    }
    return value.map((item) {
      final object = _object(item);
      if (object == null) throw FormatException('Format $field tidak valid.');
      return object;
    }).toList();
  }

  static String _requiredId(Object? value, String field) {
    if (value is num && value > 0) return value.toString();
    if (value is String && value.trim().isNotEmpty) return value.trim();
    throw FormatException('Format $field tidak valid.');
  }

  static String _string(Object? value, String fallback) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static DateTime _requiredDate(Object? value, String field) {
    final date = _optionalDate(value);
    if (date == null) throw FormatException('Format $field tidak valid.');
    return date;
  }

  static DateTime? _optionalDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    final date = DateTime.tryParse(value);
    if (date == null || date.year < 1900) return null;
    return date;
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _DatedAttendance {
  const _DatedAttendance(this.date, this.record);

  final DateTime date;
  final AttendanceRecord record;
}
