import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import 'qr_generator_screen.dart';

class AbsensiDosenTab extends StatefulWidget {
  const AbsensiDosenTab({
    super.key,
    this.previewMode = false,
    this.previewClasses,
    this.previewStudentsByClass,
  });

  final bool previewMode;
  final List<dynamic>? previewClasses;
  final Map<int, List<dynamic>>? previewStudentsByClass;

  @override
  State<AbsensiDosenTab> createState() => _AbsensiDosenTabState();
}

class _AbsensiDosenTabState extends State<AbsensiDosenTab> {
  bool _isLoading = true;
  List<dynamic> _myClasses = [];
  List<dynamic> _students = [];
  int? _selectedClassId;
  bool _classesLoadFailed = false;
  bool _studentsLoadFailed = false;
  int _selectedScheduleTab = DateTime.now().weekday > 5
      ? 0
      : DateTime.now().weekday - 1;
  dynamic _selectedSchedule;

  final Color primaryColor = const Color(0xFF082D5C);
  final Color accentColor = const Color(0xFF159D9B);
  final Color bgColor = const Color(0xFFF1F5FA);
  final Color textPrimary = const Color(0xFF082D5C);
  final Color textSecondary = const Color(0xFF64748B);
  final Color borderColor = const Color(0xFFDCE6F0);

  static const List<String> _weekdays = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
  ];

  static int _classId(dynamic classItem) {
    final id = classItem['id'];
    return id is int ? id : int.tryParse(id.toString()) ?? 0;
  }

  List<dynamic> _copyPreviewEnrollments(int classId) {
    final enrollments = widget.previewStudentsByClass?[classId] ?? [];
    return enrollments.map((enrollment) {
      final copied = Map<String, dynamic>.from(enrollment as Map);
      copied['mahasiswa'] = Map<String, dynamic>.from(
        (copied['mahasiswa'] as Map?) ?? {},
      );
      return copied;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    if (widget.previewMode) {
      _myClasses = widget.previewClasses ?? [];
      _students = [];
      _selectedClassId = null;
      _isLoading = false;
    } else {
      _fetchInitialData();
    }
  }

  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoading = true;
      _classesLoadFailed = false;
    });
    try {
      final meResponse = await ApiService.get('/users/me');
      final int myId = meResponse['data']['id'];

      final classesResponse = await ApiService.get('/classes/list');
      final List allClasses = classesResponse['data']['data'] ?? [];

      setState(() {
        _myClasses = allClasses.where((c) => c['dosen_id'] == myId).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching classes: $e");
      setState(() {
        _isLoading = false;
        _classesLoadFailed = true;
      });
    }
  }

  Future<void> _fetchStudents(int classId) async {
    if (widget.previewMode) {
      setState(() {
        _selectedClassId = classId;
        _students = _copyPreviewEnrollments(classId);
        _studentsLoadFailed = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _selectedClassId = classId;
      _students = [];
      _studentsLoadFailed = false;
    });

    try {
      // PERBAIKAN: Memanggil endpoint yang sesuai untuk Dosen
      final krsResponse = await ApiService.get(
        '/classes/students?class_id=$classId',
      );
      final List studentsList = krsResponse['data'] ?? [];

      setState(() {
        _students = studentsList;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching students: $e");
      setState(() {
        _isLoading = false;
        _studentsLoadFailed = true;
      });
    }
  }

  // Fungsi untuk membuka modal input absensi
  void _showInputAbsensiDialog(dynamic enrollment) {
    String selectedStatus = 'hadir';
    final student = enrollment['mahasiswa'] ?? {};
    final studentName = student['name'] ?? 'Mahasiswa';

    final statuses = [
      (
        value: 'hadir',
        label: 'Hadir',
        icon: Icons.check_circle_outline_rounded,
        color: const Color(0xFF21805C),
        background: const Color(0xFFE7F5EE),
      ),
      (
        value: 'izin',
        label: 'Izin',
        icon: Icons.event_available_outlined,
        color: const Color(0xFF1F5F9D),
        background: const Color(0xFFEAF2FA),
      ),
      (
        value: 'sakit',
        label: 'Sakit',
        icon: Icons.medical_services_outlined,
        color: const Color(0xFFC77718),
        background: const Color(0xFFFFF3E2),
      ),
      (
        value: 'alpa',
        label: 'Alpa',
        icon: Icons.cancel_outlined,
        color: const Color(0xFFC2413B),
        background: const Color(0xFFFCEBEA),
      ),
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 8),
          contentPadding: const EdgeInsets.fromLTRB(22, 8, 22, 12),
          actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FA),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.fact_check_outlined,
                  color: primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Input Kehadiran',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    studentName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Pilih status kehadiran mahasiswa',
                    style: TextStyle(color: textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final tileWidth = (constraints.maxWidth - 9) / 2;
                      return Wrap(
                        spacing: 9,
                        runSpacing: 9,
                        children: statuses.map((status) {
                          final isSelected = selectedStatus == status.value;
                          return SizedBox(
                            width: tileWidth,
                            child: InkWell(
                              onTap: () => setStateDialog(
                                () => selectedStatus = status.value,
                              ),
                              borderRadius: BorderRadius.circular(13),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? status.background
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(13),
                                  border: Border.all(
                                    color: isSelected
                                        ? status.color
                                        : borderColor,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      status.icon,
                                      color: status.color,
                                      size: 19,
                                    ),
                                    const SizedBox(width: 7),
                                    Expanded(
                                      child: Text(
                                        status.label,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: status.color,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_rounded,
                                        color: status.color,
                                        size: 16,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: textSecondary,
                minimumSize: const Size(88, 44),
              ),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(110, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              onPressed: () async {
                Navigator.pop(context); // Tutup dialog
                await _submitAttendance(
                  enrollment['mahasiswa_id'],
                  selectedStatus,
                );
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitAttendance(int mahasiswaId, String status) async {
    if (widget.previewMode) {
      setState(() {
        for (final enrollment in _students) {
          if (enrollment['mahasiswa_id'] == mahasiswaId) {
            enrollment['status'] = status;
            break;
          }
        }
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preview: status kehadiran diperbarui secara lokal.'),
          backgroundColor: Color(0xFF159D9B),
        ),
      );
      return;
    }

    try {
      // Format tanggal hari ini (YYYY-MM-DD)
      final today = DateTime.now().toIso8601String().split('T')[0];

      await ApiService.post('/attendances', {
        'class_id': _selectedClassId,
        'mahasiswa_id': mahasiswaId,
        'date': today,
        'status': status,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Absensi berhasil disimpan!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.16),
                            ),
                          ),
                          child: const Icon(
                            Icons.fact_check_outlined,
                            color: Colors.white,
                            size: 25,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Text(
                            'PRESENSI PERKULIAHAN',
                            style: TextStyle(
                              color: const Color(0xFF9CE0DC),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 17),
                    const Text(
                      'Absensi Dosen',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Kelola jadwal perkuliahan dan kehadiran mahasiswa.',
                      style: TextStyle(
                        color: Color(0xFFDCE8F4),
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    if (widget.previewMode) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF159D9B)
                              .withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF9CE0DC)),
                        ),
                        child: const Text(
                          'MODE PREVIEW • DATA CONTOH',
                          style: TextStyle(
                            color: Color(0xFFB7F0EA),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 17),
                    Container(
                      width: 44,
                      height: 3,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeading(
                icon: Icons.menu_book_outlined,
                title: 'Pilih Kelas',
                subtitle: 'Pilih kelas untuk melihat daftar mahasiswa',
              ),
              const SizedBox(height: 12),
              _buildClassSelector(),
              if (!_classesLoadFailed && !_isLoading && _myClasses.isEmpty) ...[
                const SizedBox(height: 12),
                _buildInfoCard(
                  icon: Icons.class_outlined,
                  title: 'Belum ada kelas yang ditugaskan',
                  message: 'Kelas yang Anda ampu akan muncul di sini setelah tersedia.',
                  iconColor: primaryColor,
                ),
              ],
              if (_classesLoadFailed) ...[
                const SizedBox(height: 12),
                _buildInfoCard(
                  icon: Icons.cloud_off_outlined,
                  title: 'Kelas gagal dimuat',
                  message: 'Periksa koneksi internet, kemudian coba muat ulang data kelas.',
                  iconColor: const Color(0xFFC2413B),
                  actionLabel: 'Coba Lagi',
                  onAction: _fetchInitialData,
                ),
              ],
              if (_myClasses.isNotEmpty) ...[
                const SizedBox(height: 24),
                if (_selectedSchedule == null)
                  _buildScheduleSection()
                else
                  _buildMeetingDetail(_selectedSchedule),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassSelector() {
    if (_isLoading && _myClasses.isEmpty && !_classesLoadFailed) {
      return _buildLoadingCard('Memuat kelas perkuliahan...');
    }

    if (_classesLoadFailed || _myClasses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonFormField<int>(
        isExpanded: true,
        initialValue: _selectedClassId,
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryColor),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.class_outlined, color: primaryColor),
          hintText: 'Pilih kelas perkuliahan',
          hintStyle: TextStyle(color: textSecondary, fontSize: 14),
          filled: true,
          fillColor: const Color(0xFFF6F9FC),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: accentColor, width: 1.5),
          ),
        ),
        items: _myClasses.map((c) {
          final courseName = c['course']?['name'] ?? 'Mata Kuliah';
          final className = c['name'] ?? 'Kelas';
          final room = c['room'];
          final day = c['day'];
          final details = [
            if (day != null && day.toString().isNotEmpty) day.toString(),
            if (room != null && room.toString().isNotEmpty)
              'Ruang ${room.toString()}',
          ].join(' • ');

          return DropdownMenuItem<int>(
            value: c['id'],
            child: Text(
              details.isEmpty
                  ? '$courseName - $className'
                  : '$courseName - $className ($details)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        selectedItemBuilder: (context) => _myClasses.map((c) {
          final courseName = c['course']?['name'] ?? 'Mata Kuliah';
          final className = c['name'] ?? 'Kelas';
          return Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '$courseName - $className',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
        onChanged: (val) {
          if (val != null) {
            setState(() {
              _selectedClassId = val;
              _selectedSchedule = null;
            });
            _fetchStudents(val);
          }
        },
      ),
    );
  }

  Widget _buildScheduleSection() {
    final selectedDay = _weekdays[_selectedScheduleTab];
    final List<dynamic> scheduleItems = [];

    for (final classItem in _myClasses) {
      if (_selectedClassId != null && _classId(classItem) != _selectedClassId) {
        continue;
      }

      if (widget.previewMode) {
        final previewSchedules =
            classItem['preview_schedules'] as List<dynamic>? ?? [];
        scheduleItems.addAll(
          previewSchedules.where(
            (schedule) => _normalizeDay(schedule['day']) == selectedDay,
          ),
        );
      } else if (_normalizeDay(classItem['day']) == selectedDay) {
        scheduleItems.add(classItem);
      }
    }

    scheduleItems.sort((a, b) {
      final aTime = (a['time'] ?? a['jam'] ?? '').toString();
      final bTime = (b['time'] ?? b['jam'] ?? '').toString();
      return aTime.compareTo(bTime);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeading(
          icon: Icons.calendar_today_outlined,
          title: 'Jadwal Perkuliahan',
          subtitle: 'Kelola jadwal kelas dan sesi presensi yang tersedia',
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _weekdays.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) =>
                _buildScheduleTab(_weekdays[index], index),
          ),
        ),
        const SizedBox(height: 12),
        if (scheduleItems.isEmpty)
          _buildInfoCard(
            icon: Icons.calendar_month_outlined,
            title: 'Tidak ada jadwal pada hari $selectedDay',
            message: 'Jadwal kelas yang ditugaskan pada hari ini akan tampil di sini.',
            iconColor: primaryColor,
          )
        else
          ...scheduleItems.map(_buildScheduleCard),
      ],
    );
  }

  Widget _buildScheduleTab(String label, int index) {
    final isSelected = _selectedScheduleTab == index;

    return InkWell(
      onTap: () => setState(() => _selectedScheduleTab = index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: isSelected ? primaryColor : borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleCard(dynamic item) {
    final courseName =
        item['course_name'] ?? item['course']?['name'] ?? 'Mata Kuliah';
    final className = item['class_name'] ?? item['name'] ?? 'Kelas';
    final day = item['day'];
    final time = item['time'] ?? item['jam'];
    final room = item['room'];
    final statusName = _resolveScheduleStatus(item);
    final statusColor = _scheduleStatusColor(statusName);

    return InkWell(
      onTap: () {
        final classId = _scheduleClassId(item);
        setState(() => _selectedSchedule = item);
        _fetchStudents(classId);
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    courseName.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _buildScheduleBadge(statusName, statusColor),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              className.toString(),
              style: TextStyle(
                color: primaryColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (day != null && day.toString().trim().isNotEmpty)
              _buildScheduleMeta(Icons.calendar_today_outlined, day.toString()),
            if (time != null && time.toString().trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              _buildScheduleMeta(Icons.access_time_rounded, time.toString()),
            ],
            if (room != null && room.toString().trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              _buildScheduleMeta(Icons.location_on_outlined, room.toString()),
            ],
            const SizedBox(height: 13),
            Row(
              children: [
                Text(
                  'Lihat detail pertemuan',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_rounded, color: accentColor, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 132),
        child: Text(
          status,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }

  int _scheduleClassId(dynamic schedule) {
    final rawId = schedule['class_id'] ?? schedule['id'];
    if (rawId is int) return rawId;
    return int.tryParse(rawId?.toString() ?? '') ?? 0;
  }

  String? _normalizeDay(dynamic day) {
    if (day == null) return null;
    final value = day.toString().trim().toLowerCase();
    for (final weekday in _weekdays) {
      if (weekday.toLowerCase() == value) return weekday;
    }

    const englishDays = {
      'monday': 'Senin',
      'tuesday': 'Selasa',
      'wednesday': 'Rabu',
      'thursday': 'Kamis',
      'friday': 'Jumat',
    };
    return englishDays[value];
  }

  Widget _buildMeetingDetail(dynamic schedule) {
    final courseName =
        schedule['course_name'] ?? schedule['course']?['name'] ?? 'Mata Kuliah';
    final className = schedule['class_name'] ?? schedule['name'] ?? 'Kelas';
    final time = schedule['time'] ?? schedule['jam'] ?? 'Jam belum tersedia';
    final room = schedule['room'];
    final programStudy =
        schedule['program_study'] ??
        schedule['program_studi'] ??
        schedule['prodi'];
    final meetings = schedule['meetings'] as List<dynamic>?;
    final currentMeeting = schedule['meeting_number'];
    final configuredCount = schedule['meeting_count'];
    final meetingCount = configuredCount is int
        ? configuredCount
        : int.tryParse(configuredCount?.toString() ?? '') ?? 0;
    final punctuality = _lecturerAttendancePreview(schedule);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _selectedSchedule = null),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Icon(Icons.arrow_back_rounded, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Kembali ke jadwal',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      courseName.toString(),
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _buildScheduleBadge(
                    _resolveScheduleStatus(schedule),
                    _scheduleStatusColor(_resolveScheduleStatus(schedule)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                className.toString(),
                style: TextStyle(
                  color: accentColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              _buildScheduleMeta(
                Icons.calendar_today_outlined,
                schedule['day']?.toString() ?? _weekdays[_selectedScheduleTab],
              ),
              const SizedBox(height: 8),
              _buildScheduleMeta(Icons.access_time_rounded, time.toString()),
              if (room != null && room.toString().trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildScheduleMeta(Icons.location_on_outlined, room.toString()),
              ],
              if (programStudy != null &&
                  programStudy.toString().trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildScheduleMeta(
                  Icons.account_balance_outlined,
                  programStudy.toString(),
                ),
              ],
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.event_note_outlined, color: primaryColor),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Informasi Pertemuan',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (currentMeeting != null ||
                  (meetingCount > 0) ||
                  (meetings?.isNotEmpty ?? false)) ...[
                const SizedBox(height: 12),
                Text(
                  [
                    if (currentMeeting != null) 'Pertemuan ke-$currentMeeting',
                    if (meetingCount > 0) '$meetingCount pertemuan',
                    if (meetingCount == 0 && (meetings?.isNotEmpty ?? false))
                      '${meetings!.length} pertemuan tercatat',
                  ].join(' • '),
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildMeetingGrid(meetings, meetingCount),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _openQrGenerator(schedule),
            icon: const Icon(Icons.qr_code_2_rounded, size: 19),
            label: const Text('Buat QR Presensi'),
            style: FilledButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildLecturerAttendanceHint(punctuality),
        const SizedBox(height: 22),
        _buildSectionHeading(
          icon: Icons.groups_2_outlined,
          title: 'Daftar Mahasiswa',
          subtitle: 'Mahasiswa pada kelas $className',
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          _buildLoadingCard('Memuat daftar mahasiswa...')
        else if (_studentsLoadFailed)
          _buildInfoCard(
            icon: Icons.wifi_off_outlined,
            title: 'Mahasiswa gagal dimuat',
            message: 'Terjadi kendala saat mengambil data mahasiswa untuk kelas ini.',
            iconColor: const Color(0xFFC2413B),
            actionLabel: 'Coba Lagi',
            onAction: () => _fetchStudents(_scheduleClassId(schedule)),
          )
        else if (_students.isEmpty)
          _buildInfoCard(
            icon: Icons.groups_2_outlined,
            title: 'Belum ada mahasiswa',
            message: 'Belum ada mahasiswa terdaftar pada kelas yang dipilih.',
            iconColor: primaryColor,
          )
        else
          ..._students.map(_buildStudentCard),
      ],
    );
  }

  void _openQrGenerator(dynamic schedule) {
    if (widget.previewMode) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('QR Presensi'),
          content: const Text(
            'QR Generator memerlukan sesi autentikasi dan layanan API aplikasi. '
            'Preview ini tidak membuat QR atau mengirim data.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );
      return;
    }

    final classId = _scheduleClassId(schedule);
    final classItem = _myClasses.firstWhere(
      (item) => _classId(item) == classId,
      orElse: () => schedule,
    );
    final className =
        schedule['course_name'] ??
        classItem['course']?['name'] ??
        classItem['name'] ??
        schedule['class_name'] ??
        'Kelas';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QrGeneratorScreen(
          classId: classId,
          className: className.toString(),
        ),
      ),
    );
  }

  Widget _buildMeetingGrid(List<dynamic>? meetings, int meetingCount) {
    final meetingItems =
        meetings ??
        List<dynamic>.generate(meetingCount, (index) => {'number': index + 1});

    if (meetingItems.isEmpty) {
      return _buildInfoCard(
        icon: Icons.event_busy_outlined,
        title: 'Data pertemuan belum tersedia',
        message: 'Informasi jumlah dan status pertemuan akan tampil setelah disediakan sistem.',
        iconColor: primaryColor,
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daftar Kehadiran Pertemuan',
            style: TextStyle(
              color: textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: meetingItems.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.2,
            ),
            itemBuilder: (context, index) {
              final meeting = meetingItems[index];
              final meetingData = meeting is Map
                  ? meeting
                  : <String, dynamic>{};
              final label =
                  meetingData['label']?.toString() ??
                  meetingData['number']?.toString() ??
                  '${index + 1}';
              final status = meetingData['status']?.toString() ?? '';
              final color = _meetingStatusColor(label, status);
              final isUnmarked = status.isEmpty || status == 'belum absen';

              return Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: isUnmarked ? borderColor : color),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isUnmarked ? textPrimary : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _buildMeetingLegend('Hadir', const Color(0xFF21805C)),
              _buildMeetingLegend('Alpa', const Color(0xFFC2413B)),
              _buildMeetingLegend('Izin', const Color(0xFFE0A51B)),
              _buildMeetingLegend('Sakit', const Color(0xFF1F5F9D)),
              _buildMeetingLegend('Terlambat', const Color(0xFFE77C24)),
              _buildMeetingLegend('Libur', const Color(0xFF94A3B8)),
              _buildMeetingLegend('Belum Absen', Colors.white, outlined: true),
              _buildMeetingLegend('UAS', Colors.black),
            ],
          ),
        ],
      ),
    );
  }

  Color _meetingStatusColor(String label, String status) {
    if (label.toUpperCase() == 'UAS' || status.toLowerCase() == 'uas') {
      return Colors.black;
    }
    switch (status.toLowerCase()) {
      case 'hadir':
        return const Color(0xFF21805C);
      case 'alpa':
        return const Color(0xFFC2413B);
      case 'izin':
        return const Color(0xFFE0A51B);
      case 'sakit':
        return const Color(0xFF1F5F9D);
      case 'terlambat':
        return const Color(0xFFE77C24);
      case 'libur':
        return const Color(0xFF94A3B8);
      default:
        return Colors.white;
    }
  }

  Widget _buildMeetingLegend(
    String label,
    Color color, {
    bool outlined = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: outlined ? Border.all(color: borderColor) : null,
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: textSecondary, fontSize: 10)),
      ],
    );
  }

  String? _lecturerAttendancePreview(dynamic schedule) {
    if (DateTime.now().weekday > 5 ||
        _normalizeDay(schedule['day']) !=
            _weekdays[DateTime.now().weekday - 1]) {
      return null;
    }
    final timeText = (schedule['time'] ?? schedule['jam'] ?? '').toString();
    final match = RegExp(r'(\d{1,2})[:.](\d{2})').firstMatch(timeText);
    if (match == null) return null;

    final now = TimeOfDay.now();
    final startMinutes =
        int.parse(match.group(1)!) * 60 + int.parse(match.group(2)!);
    final nowMinutes = now.hour * 60 + now.minute;
    if (nowMinutes < startMinutes) return 'Belum Mulai';
    if (nowMinutes <= startMinutes + 10) return 'Tepat Waktu';
    return 'Terlambat';
  }

  Widget _buildLecturerAttendanceHint(String? status) {
    final statusColor = status == 'Tepat Waktu'
        ? const Color(0xFF21805C)
        : status == 'Terlambat'
        ? const Color(0xFFE77C24)
        : textSecondary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FA),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: primaryColor, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              status == null
                  ? 'Status presensi dosen akan dihitung dari jadwal. Status ini hanya estimasi tampilan dan tidak disimpan.'
                  : 'Estimasi status presensi dosen: $status. Batas toleransi 10 menit; status ini tidak dikirim atau disimpan.',
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleMeta(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: textSecondary, fontSize: 12),
          ),
        ),
      ],
    );
  }

  String _resolveScheduleStatus(dynamic item) {
    if (widget.previewMode && item['preview_status'] != null) {
      return item['preview_status'].toString();
    }

    final rawStatus = item['status']?.toString().trim().toLowerCase();
    switch (rawStatus) {
      case 'sedang berlangsung':
      case 'ongoing':
        return 'Sedang Berlangsung';
      case 'selesai':
      case 'ended':
      case 'completed':
        return 'Selesai';
      case 'akan datang':
      case 'upcoming':
        return 'Akan Datang';
      case 'belum berlangsung':
      case 'not_started':
        return 'Belum Berlangsung';
    }

    final isActive = item['is_active'] == true || item['status'] == 'active';
    final isEnded = item['is_ended'] == true || item['status'] == 'ended';

    if (isActive) return 'Sedang Berlangsung';
    if (isEnded) return 'Selesai';

    final today = DateTime.now();
    if (today.weekday <= 5 &&
        _normalizeDay(item['day']) == _weekdays[today.weekday - 1]) {
      final timeText = (item['time'] ?? item['jam'] ?? '').toString();
      final times = RegExp(r'(\d{1,2})[:.](\d{2})').allMatches(timeText);
      if (times.isNotEmpty) {
        final start = _timeMatchToMinutes(times.first);
        final now = today.hour * 60 + today.minute;
        if (now < start) return 'Belum Berlangsung';
        if (times.length > 1) {
          final end = _timeMatchToMinutes(times.elementAt(1));
          if (now >= end) return 'Selesai';
        }
        return 'Sedang Berlangsung';
      }
    }

    return 'Belum Berlangsung';
  }

  int _timeMatchToMinutes(RegExpMatch match) {
    return int.parse(match.group(1)!) * 60 + int.parse(match.group(2)!);
  }

  Color _scheduleStatusColor(String status) {
    switch (status) {
      case 'Sedang Berlangsung':
        return const Color(0xFF159D9B);
      case 'Selesai':
        return const Color(0xFF64748B);
      case 'Akan Datang':
      case 'Belum Berlangsung':
      default:
        return const Color(0xFF1F5F9D);
    }
  }

  Widget _buildSectionHeading({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFD7F1F0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              color: accentColor,
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String message,
    required Color iconColor,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: textSecondary, fontSize: 12, height: 1.45),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 13),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(actionLabel),
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(140, 42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStudentCard(dynamic enrollment) {
    final student = enrollment['mahasiswa'] ?? {};
    final studentName = student['name'] ?? 'Mahasiswa';
    final nim = student['nim'];
    final email = student['email'];
    final attendanceStatus = _buildAttendanceStatus(enrollment['status']);
    final initial = studentName.toString().trim().isNotEmpty
        ? studentName.toString().trim().substring(0, 1).toUpperCase()
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFD7F1F0),
            child: Text(
              initial,
              style: TextStyle(
                color: primaryColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName.toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (nim != null && nim.toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    'NIM ${nim.toString()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: textSecondary, fontSize: 11),
                  ),
                ] else if (email != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    email.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: textSecondary, fontSize: 11),
                  ),
                ],
                if (attendanceStatus != null) ...[
                  const SizedBox(height: 7),
                  attendanceStatus,
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => _showInputAbsensiDialog(enrollment),
            style: FilledButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(68, 42),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Atur',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildAttendanceStatus(dynamic status) {
    final normalizedStatus = status?.toString().toLowerCase();
    final statusStyle = switch (normalizedStatus) {
      'hadir' => (
        label: 'Hadir',
        icon: Icons.check_circle_outline_rounded,
        color: const Color(0xFF21805C),
        background: const Color(0xFFE7F5EE),
      ),
      'izin' => (
        label: 'Izin',
        icon: Icons.event_available_outlined,
        color: const Color(0xFF1F5F9D),
        background: const Color(0xFFEAF2FA),
      ),
      'sakit' => (
        label: 'Sakit',
        icon: Icons.medical_services_outlined,
        color: const Color(0xFFC77718),
        background: const Color(0xFFFFF3E2),
      ),
      'alpa' => (
        label: 'Alpa',
        icon: Icons.cancel_outlined,
        color: const Color(0xFFC2413B),
        background: const Color(0xFFFCEBEA),
      ),
      'terlambat' => (
        label: 'Terlambat',
        icon: Icons.schedule_rounded,
        color: const Color(0xFFE77C24),
        background: const Color(0xFFFFF0E4),
      ),
      'libur' => (
        label: 'Libur',
        icon: Icons.event_busy_outlined,
        color: const Color(0xFF64748B),
        background: const Color(0xFFF1F5F9),
      ),
      null || '' => (
        label: 'Belum Absen',
        icon: Icons.radio_button_unchecked_rounded,
        color: const Color(0xFF64748B),
        background: const Color(0xFFF1F5F9),
      ),
      'belum presensi' || 'belum_presensi' || 'belum absen' => (
        label: 'Belum Presensi',
        icon: Icons.radio_button_unchecked_rounded,
        color: const Color(0xFF64748B),
        background: const Color(0xFFF1F5F9),
      ),
      _ => null,
    };

    if (statusStyle == null) return null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusStyle.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusStyle.icon, color: statusStyle.color, size: 13),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              statusStyle.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: statusStyle.color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
