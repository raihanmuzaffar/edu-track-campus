import 'package:flutter/material.dart';

import '../../services/api_service.dart';

const _navy = Color(0xFF082D5C);
const _turquoise = Color(0xFF159D9B);
const _lightTurquoise = Color(0xFFD7F1F0);
const _offWhite = Color(0xFFF1F5FA);
const _textSecondary = Color(0xFF68778B);
const _border = Color(0xFFE2E9F1);

class NilaiDosenTab extends StatefulWidget {
  const NilaiDosenTab({super.key});

  @override
  State<NilaiDosenTab> createState() => _NilaiDosenTabState();
}

class _NilaiDosenTabState extends State<NilaiDosenTab> {
  bool _isLoading = true;
  List<dynamic> _myClasses = [];
  final Map<int, List<dynamic>> _studentsByClass = {};
  final Set<int> _loadingClassIds = {};
  final Map<int, String> _classErrors = {};
  final Map<String, Map<String, dynamic>> _sessionGrades = {};
  final TextEditingController _searchController = TextEditingController();
  int? _selectedClassId;
  String _searchQuery = '';
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  static int? _asInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static int? _classId(dynamic classItem) => _asInt(_asMap(classItem)['id']);

  static String _className(dynamic classItem) {
    final value = _asMap(classItem)['name']?.toString().trim();
    return value == null || value.isEmpty ? 'Kelas' : value;
  }

  static String _courseName(dynamic classItem) {
    final course = _asMap(_asMap(classItem)['course']);
    final value = course['name']?.toString().trim();
    return value == null || value.isEmpty ? 'Mata Kuliah' : value;
  }

  Future<void> _fetchInitialData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _loadError = null;
      _classErrors.clear();
      _studentsByClass.clear();
      _loadingClassIds.clear();
    });

    try {
      final meResponse = await ApiService.get('/users/me');
      final myId = _asInt(_asMap(meResponse['data'])['id']);
      if (myId == null) {
        throw const FormatException('ID dosen tidak ditemukan.');
      }

      final classesResponse = await ApiService.get('/classes/list');
      final classesEnvelope = _asMap(classesResponse['data']);
      final allClasses = classesEnvelope['data'];
      if (allClasses is! List) {
        throw const FormatException('Format daftar kelas tidak sesuai.');
      }
      final assignedClasses = allClasses.where((item) {
        return _asInt(_asMap(item)['dosen_id']) == myId;
      }).toList();
      final ids = assignedClasses
          .map(_classId)
          .whereType<int>()
          .toSet()
          .toList();

      if (!mounted) return;
      setState(() {
        _myClasses = assignedClasses;
        if (!ids.contains(_selectedClassId)) {
          _selectedClassId = ids.isEmpty ? null : ids.first;
        }
        _isLoading = false;
      });

      await Future.wait(ids.map(_fetchStudents));
    } catch (error) {
      debugPrint('Error fetching lecturer grade data: $error');
      if (!mounted) return;
      setState(() {
        _loadError = 'Daftar mata kuliah belum dapat dimuat. Periksa koneksi lalu coba lagi.';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchStudents(int classId) async {
    if (_studentsByClass.containsKey(classId) ||
        _loadingClassIds.contains(classId)) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _loadingClassIds.add(classId);
      _classErrors.remove(classId);
    });

    try {
      final response = await ApiService.get(
        '/classes/students?class_id=$classId',
      );
      final students = response['data'];
      if (students is! List) {
        throw const FormatException('Format daftar mahasiswa tidak sesuai.');
      }
      if (!mounted) return;
      setState(() {
        _studentsByClass[classId] = students;
      });
    } catch (error) {
      debugPrint('Error fetching students for class $classId: $error');
      if (!mounted) return;
      setState(() {
        _classErrors[classId] = 'Daftar mahasiswa kelas ini gagal dimuat. Ketuk untuk mencoba lagi.';
      });
    } finally {
      if (mounted) {
        setState(() => _loadingClassIds.remove(classId));
      }
    }
  }

  int get _studentCount => _studentsByClass.values.fold(
    0,
    (total, students) => total + students.length,
  );

  int get _savedGradeCount => _sessionGrades.length;

  int get _pendingGradeCount =>
      (_studentCount - _savedGradeCount).clamp(0, _studentCount);

  String _gradeKey(int classId, dynamic studentId) =>
      '$classId:${studentId.toString()}';

  Map<String, dynamic>? _gradeFor(int classId, dynamic studentId) {
    if (studentId == null) return null;
    return _sessionGrades[_gradeKey(classId, studentId)];
  }

  int _savedCountForClass(int classId) {
    final prefix = '$classId:';
    return _sessionGrades.keys.where((key) => key.startsWith(prefix)).length;
  }

  List<MapEntry<dynamic, dynamic>> get _visibleStudents {
    final query = _searchQuery.trim().toLowerCase();
    final visible = <MapEntry<dynamic, dynamic>>[];

    for (final classItem in _myClasses) {
      final classId = _classId(classItem);
      if (classId == null ||
          (_selectedClassId != null && classId != _selectedClassId)) {
        continue;
      }
      for (final enrollment in _studentsByClass[classId] ?? const []) {
        final student = _asMap(_asMap(enrollment)['mahasiswa']);
        final name = student['name']?.toString() ?? '';
        final nim = student['nim']?.toString() ?? '';
        if (query.isEmpty ||
            name.toLowerCase().contains(query) ||
            nim.toLowerCase().contains(query)) {
          visible.add(MapEntry(classItem, enrollment));
        }
      }
    }
    return visible;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _offWhite,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _turquoise))
            : RefreshIndicator(
                color: _turquoise,
                onRefresh: _fetchInitialData,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildHeader(),
                          const SizedBox(height: 18),
                          if (_loadError != null) ...[
                            _buildLoadError(),
                            const SizedBox(height: 16),
                          ],
                          _buildApiNotice(),
                          const SizedBox(height: 22),
                          _buildSectionTitle(
                            'Ringkasan Nilai',
                            'Pantau progres penilaian kelas Anda',
                          ),
                          const SizedBox(height: 12),
                          _buildSummaryGrid(),
                          const SizedBox(height: 24),
                          _buildSectionTitle(
                            'Mata Kuliah Diampu',
                            'Pilih kelas untuk menyaring daftar mahasiswa',
                          ),
                          const SizedBox(height: 12),
                          _buildClassFilters(),
                          const SizedBox(height: 24),
                          _buildSectionTitle(
                            'Daftar Mahasiswa',
                            _selectedClassId == null
                                ? 'Semua kelas • ${_visibleStudents.length} mahasiswa'
                                : 'Kelas ${_selectedClassName()} • '
                                      '${_visibleStudents.length} mahasiswa',
                          ),
                          const SizedBox(height: 12),
                          _buildSearchField(),
                          const SizedBox(height: 12),
                          if (_myClasses.isEmpty)
                            _buildEmptyState(
                              icon: Icons.menu_book_outlined,
                              title: 'Belum ada mata kuliah',
                              subtitle: 'Mata kuliah yang diampu akan tampil di sini.',
                            )
                          else if (_visibleStudents.isEmpty &&
                              _selectedClassId != null &&
                              _classErrors.containsKey(_selectedClassId))
                            _buildClassError(_selectedClassId!)
                          else if (_visibleStudents.isEmpty &&
                              _loadingClassIds.any(
                                (id) =>
                                    _selectedClassId == null ||
                                    id == _selectedClassId,
                              ))
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 28),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: _turquoise,
                                ),
                              ),
                            )
                          else if (_visibleStudents.isEmpty)
                            _buildEmptyState(
                              icon: Icons.search_off_rounded,
                              title: _searchQuery.isEmpty
                                  ? 'Belum ada mahasiswa di kelas ini'
                                  : 'Mahasiswa tidak ditemukan',
                              subtitle: _searchQuery.isEmpty
                                  ? 'Daftar mahasiswa kelas ini masih kosong.'
                                  : 'Coba kata kunci nama atau NIM lain.',
                            )
                          else
                            ..._visibleStudents.map(_buildStudentCard),
                          if (_selectedClassId == null &&
                              _loadingClassIds.isNotEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 4, bottom: 12),
                              child: Center(
                                child: Text(
                                  'Memuat daftar mahasiswa dari kelas lain…',
                                  style: TextStyle(
                                    color: _textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  String _selectedClassName() {
    for (final classItem in _myClasses) {
      if (_classId(classItem) == _selectedClassId) {
        return _className(classItem);
      }
    }
    return '-';
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.grade_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'PENGELOLAAN AKADEMIK',
                  style: TextStyle(
                    color: Color(0xFF9CE0DC),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Muat ulang nilai',
                onPressed: _fetchInitialData,
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Nilai Mahasiswa',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Kelola dan pantau hasil penilaian mahasiswa di setiap kelas.',
            style: TextStyle(
              color: Color(0xFFDCE8F4),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: 42,
            height: 3,
            decoration: BoxDecoration(
              color: _turquoise,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFF2E3BD)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFF986515), size: 18),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'API saat ini menyediakan satu nilai akhir dan huruf mutu. '
              'Nilai tugas, UTS, UAS, serta nilai lama per kelas belum tersedia.',
              style: TextStyle(
                color: Color(0xFF775600),
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadError() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEEE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1CACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, color: Color(0xFFB54747)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _loadError!,
              style: const TextStyle(color: Color(0xFF8C3636), fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: _fetchInitialData,
            child: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _navy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(color: _textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSummaryGrid() {
    final isLoadingStudents = _loadingClassIds.isNotEmpty;
    final items = [
      (
        'Mata kuliah',
        '${_myClasses.length}',
        Icons.menu_book_rounded,
        _turquoise,
      ),
      (
        'Mahasiswa',
        isLoadingStudents ? '…' : '$_studentCount',
        Icons.groups_rounded,
        _navy,
      ),
      (
        'Tersimpan sesi ini',
        '$_savedGradeCount',
        Icons.task_alt_rounded,
        const Color(0xFF27845B),
      ),
      (
        'Belum diinput',
        isLoadingStudents ? '…' : '$_pendingGradeCount',
        Icons.pending_actions_rounded,
        const Color(0xFFB7791F),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items.map((item) {
            return SizedBox(
              width: cardWidth,
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: item.$4.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(item.$3, color: item.$4, size: 19),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.$2,
                            style: const TextStyle(
                              color: _navy,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            item.$1,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildClassFilters() {
    if (_myClasses.isEmpty) {
      return _buildEmptyState(
        icon: Icons.menu_book_outlined,
        title: 'Belum ada mata kuliah',
        subtitle: 'Mata kuliah yang diampu akan tampil di sini.',
      );
    }

    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: FilterChip(
            label: const Text('Semua kelas'),
            selected: _selectedClassId == null,
            onSelected: (_) => setState(() => _selectedClassId = null),
            selectedColor: _lightTurquoise,
            checkmarkColor: _turquoise,
            side: BorderSide(
              color: _selectedClassId == null ? _turquoise : _border,
            ),
            labelStyle: TextStyle(
              color: _selectedClassId == null ? _turquoise : _textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(height: 5),
        ..._myClasses.map(_buildClassCard),
      ],
    );
  }

  Widget _buildClassCard(dynamic classItem) {
    final classId = _classId(classItem);
    if (classId == null) return const SizedBox.shrink();
    final selected = _selectedClassId == classId;
    final students = _studentsByClass[classId];
    final savedCount = _savedCountForClass(classId);
    final pendingCount = students == null
        ? null
        : (students.length - savedCount).clamp(0, students.length);

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() => _selectedClassId = classId);
            _fetchStudents(classId);
          },
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? _turquoise : _border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selected ? _lightTurquoise : const Color(0xFFEAF2FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: selected ? _turquoise : _navy,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _courseName(classItem),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _navy,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_className(classItem)}  •  '
                        '${students == null ? '—' : '${students.length}'} mahasiswa',
                        style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 7),
                      if (_classErrors.containsKey(classId))
                        Text(
                          _classErrors[classId]!,
                          style: const TextStyle(
                            color: Color(0xFFB54747),
                            fontSize: 10,
                          ),
                        )
                      else
                        _StatusBadge(
                          label: pendingCount == null
                              ? 'Memuat progres penilaian'
                              : '$savedCount tersimpan sesi ini  •  '
                                    '$pendingCount belum diinput',
                          done: pendingCount == 0,
                        ),
                    ],
                  ),
                ),
                if (_loadingClassIds.contains(classId))
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _turquoise,
                    ),
                  )
                else if (_classErrors.containsKey(classId))
                  IconButton(
                    tooltip: 'Coba muat ulang kelas',
                    onPressed: () => _fetchStudents(classId),
                    icon: const Icon(Icons.refresh_rounded, color: _turquoise),
                  )
                else
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.chevron_right_rounded,
                    color: selected ? _turquoise : _textSecondary,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _searchQuery = value),
      decoration: InputDecoration(
        hintText: 'Cari nama atau NIM mahasiswa',
        hintStyle: const TextStyle(color: _textSecondary, fontSize: 12),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: _textSecondary,
          size: 20,
        ),
        suffixIcon: _searchQuery.isEmpty
            ? null
            : IconButton(
                tooltip: 'Hapus pencarian',
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _turquoise, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildStudentCard(MapEntry<dynamic, dynamic> entry) {
    final classItem = entry.key;
    final enrollment = _asMap(entry.value);
    final student = _asMap(enrollment['mahasiswa']);
    final name = student['name']?.toString().trim();
    final studentName = name == null || name.isEmpty ? 'Mahasiswa' : name;
    final nim = student['nim']?.toString() ?? '-';
    final classId = _classId(classItem);
    final studentId = enrollment['mahasiswa_id'];
    final grade = classId == null ? null : _gradeFor(classId, studentId);
    final score = grade?['score'] as double?;
    final letter = grade?['letter']?.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showStudentDetails(
            studentName: studentName,
            nim: nim,
            className: '${_courseName(classItem)} • ${_className(classItem)}',
            score: score,
            letter: letter,
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 21,
                      backgroundColor: _lightTurquoise,
                      child: Text(
                        studentName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: _turquoise,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            studentName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _navy,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            nim,
                            style: const TextStyle(
                              color: _textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          if (_selectedClassId == null) ...[
                            const SizedBox(height: 3),
                            Text(
                              '${_courseName(classItem)} • ${_className(classItem)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    _StatusBadge(
                      label: grade == null ? 'Belum diinput' : 'Sudah dinilai',
                      done: grade != null,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const _ScoreCell(label: 'Tugas', value: '—'),
                    const _ScoreCell(label: 'UTS', value: '—'),
                    const _ScoreCell(label: 'UAS', value: '—'),
                    _ScoreCell(
                      label: 'Nilai akhir',
                      value: score?.toStringAsFixed(1) ?? '—',
                      emphasize: true,
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: _textSecondary,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        grade == null
                            ? 'Status nilai lama belum tersedia'
                            : 'Huruf mutu: ${letter ?? '-'}',
                        style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: classId == null || studentId == null
                          ? null
                          : () => _showInputNilaiDialog(
                              enrollment: enrollment,
                              classId: classId,
                              studentName: studentName,
                              currentGrade: grade,
                            ),
                      icon: Icon(
                        grade == null ? Icons.add_rounded : Icons.edit_outlined,
                        size: 16,
                      ),
                      label: Text(grade == null ? 'Input nilai' : 'Perbarui'),
                      style: TextButton.styleFrom(
                        foregroundColor: _turquoise,
                        textStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showInputNilaiDialog({
    required Map<String, dynamic> enrollment,
    required int classId,
    required String studentName,
    required Map<String, dynamic>? currentGrade,
  }) async {
    final studentId = enrollment['mahasiswa_id'];
    if (studentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID mahasiswa tidak tersedia.')),
      );
      return;
    }

    final scoreController = TextEditingController(
      text: currentGrade?['score']?.toString() ?? '',
    );
    var selectedLetter = currentGrade?['letter']?.toString() ?? 'A';

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(
              'Input Nilai Akhir\n$studentName',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: scoreController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Nilai Akhir (0-100)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedLetter,
                    decoration: const InputDecoration(
                      labelText: 'Huruf Mutu',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'A', child: Text('A')),
                      DropdownMenuItem(value: 'AB', child: Text('AB')),
                      DropdownMenuItem(value: 'B', child: Text('B')),
                      DropdownMenuItem(value: 'BC', child: Text('BC')),
                      DropdownMenuItem(value: 'C', child: Text('C')),
                      DropdownMenuItem(value: 'D', child: Text('D')),
                      DropdownMenuItem(value: 'E', child: Text('E')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedLetter = value);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _turquoise,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final score = double.tryParse(
                    scoreController.text.trim().replaceAll(',', '.'),
                  );
                  if (score == null || score < 0 || score > 100) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Nilai harus berupa angka 0-100'),
                        backgroundColor: Color(0xFFB54747),
                      ),
                    );
                    return;
                  }
                  final saved = await _submitGrade(
                    studentId: studentId,
                    classId: classId,
                    score: score,
                    letter: selectedLetter,
                  );
                  if (saved && dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          ),
        ),
      );
    } finally {
      scoreController.dispose();
    }
  }

  Future<bool> _submitGrade({
    required dynamic studentId,
    required int classId,
    required double score,
    required String letter,
  }) async {
    try {
      await ApiService.post('/grades', {
        'mahasiswa_id': studentId,
        'class_id': classId,
        'score': score,
        'letter': letter,
      });

      if (!mounted) return false;
      setState(() {
        _sessionGrades[_gradeKey(classId, studentId)] = {
          'score': score,
          'letter': letter,
        };
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nilai berhasil disimpan.'),
          backgroundColor: Color(0xFF27845B),
        ),
      );
      return true;
    } catch (error) {
      debugPrint('Error saving student grade: $error');
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nilai gagal disimpan: $error'),
          backgroundColor: const Color(0xFFB54747),
        ),
      );
      return false;
    }
  }

  void _showStudentDetails({
    required String studentName,
    required String nim,
    required String className,
    required double? score,
    required String? letter,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _lightTurquoise,
                    child: Text(
                      studentName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: _turquoise,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          studentName,
                          style: const TextStyle(
                            color: _navy,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'NIM $nim',
                          style: const TextStyle(
                            color: _textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(
                    label: score == null ? 'Belum diinput' : 'Sudah dinilai',
                    done: score != null,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                className,
                style: const TextStyle(color: _textSecondary, fontSize: 11),
              ),
              const SizedBox(height: 20),
              const Text(
                'Rincian Penilaian',
                style: TextStyle(
                  color: _navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const _DetailScoreRow(label: 'Nilai Tugas', value: '—'),
              const _DetailScoreRow(label: 'Ujian Tengah Semester', value: '—'),
              const _DetailScoreRow(label: 'Ujian Akhir Semester', value: '—'),
              const Divider(height: 20, color: _border),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Nilai Akhir',
                      style: TextStyle(
                        color: _navy,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    score?.toStringAsFixed(1) ?? 'Belum diinput',
                    style: TextStyle(
                      color: score == null ? _textSecondary : _turquoise,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              if (letter != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Huruf mutu: $letter',
                    style: const TextStyle(color: _textSecondary, fontSize: 12),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Text(
                'Rincian nilai tugas, UTS, dan UAS belum dikirim oleh API.',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _navy,
                    side: const BorderSide(color: _border),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassError(int classId) {
    return _buildEmptyState(
      icon: Icons.cloud_off_outlined,
      title: 'Daftar mahasiswa gagal dimuat',
      subtitle: _classErrors[classId] ?? 'Periksa koneksi lalu coba lagi.',
      action: TextButton(
        onPressed: () => _fetchStudents(classId),
        child: const Text('Coba lagi'),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Icon(icon, color: _textSecondary, size: 30),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _navy, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _textSecondary, fontSize: 12),
          ),
          ?action,
        ],
      ),
    );
  }
}

class _ScoreCell extends StatelessWidget {
  const _ScoreCell({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _textSecondary, fontSize: 9),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: emphasize ? _turquoise : _navy,
              fontSize: emphasize ? 14 : 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailScoreRow extends StatelessWidget {
  const _DetailScoreRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: _navy,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.done});

  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final foreground = done ? const Color(0xFF27845B) : const Color(0xFF986515);
    final background = done ? const Color(0xFFE7F5EC) : const Color(0xFFFFF4D6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
