import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class NilaiDosenTab extends StatefulWidget {
  const NilaiDosenTab({super.key});

  @override
  State<NilaiDosenTab> createState() => _NilaiDosenTabState();
}

class _NilaiDosenTabState extends State<NilaiDosenTab> {
  bool _isLoading = true;
  List<dynamic> _myClasses = [];
  List<dynamic> _students = [];
  int? _selectedClassId;
  
  final Color primaryColor = const Color(0xFF145A4A);
  final Color bgColor = const Color(0xFFF4F6F8);
  final Color textPrimary = const Color(0xFF1F2937);
  final Color textSecondary = const Color(0xFF6B7280);
  final Color borderColor = const Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    try {
      final meResponse = await ApiService.get('/users/me');
      final int myId = meResponse['data']['id'];

      final classesResponse = await ApiService.get('/classes/list');
      // Pastikan mengambil dari data.data karena ada pagination
      final List allClasses = classesResponse['data']?['data'] ?? [];
      
      setState(() {
        _myClasses = allClasses.where((c) => c['dosen_id'] == myId).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching classes: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchStudents(int classId) async {
    setState(() {
      _isLoading = true;
      _selectedClassId = classId;
      _students = [];
    });
    
    try {
      final krsResponse = await ApiService.get('/classes/students?class_id=$classId');
      // Ambil data array-nya
      final List studentsList = krsResponse['data'] ?? [];
      
      setState(() {
        _students = studentsList;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching students: $e");
      setState(() => _isLoading = false);
    }
  }

  // Fungsi untuk membuka modal input nilai
  void _showInputNilaiDialog(dynamic enrollment) {
    // Pastikan data tidak null sebelum diproses
    final student = enrollment['mahasiswa'] ?? {};
    final studentName = student['name'] ?? 'Mahasiswa';
    final studentId = enrollment['mahasiswa_id'];

    if (studentId == null) return;

    String selectedLetter = 'A';
    final scoreController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Input Nilai\n$studentName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: scoreController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Nilai Angka (0-100)',
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
                        DropdownMenuItem(value: 'B', child: Text('B')),
                        DropdownMenuItem(value: 'C', child: Text('C')),
                        DropdownMenuItem(value: 'D', child: Text('D')),
                        DropdownMenuItem(value: 'E', child: Text('E')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setStateDialog(() => selectedLetter = val);
                        }
                      },
                    ),
                  ],
                ),
              );
            }
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
              onPressed: () async {
                final score = double.tryParse(scoreController.text);
                if (score == null || score < 0 || score > 100) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nilai harus berupa angka 0-100'), backgroundColor: Colors.red),
                  );
                  return;
                }
                
                Navigator.pop(context); // Tutup dialog
                // Pastikan _selectedClassId tidak null
                if (_selectedClassId != null) {
                  await _submitGrade(studentId, _selectedClassId!, score, selectedLetter);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitGrade(int mahasiswaId, int classId, double score, String letter) async {
    try {
      await ApiService.post('/grades', {
        'mahasiswa_id': mahasiswaId,
        'class_id': classId,
        'score': score,
        'letter': letter,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nilai berhasil disimpan!'), backgroundColor: Colors.green),
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Input Nilai Mahasiswa', style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 1),
        ),
      ),
      body: Column(
        children: [
          // Dropdown Pilih Kelas
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'Pilih Kelas',
                prefixIcon: Icon(Icons.class_outlined),
              ),
              initialValue: _selectedClassId,
              items: _myClasses.map((c) {
                final courseName = c['course']?['name'] ?? 'Mata Kuliah';
                final className = c['name'] ?? 'Kelas';
                return DropdownMenuItem<int>(
                  value: c['id'],
                  child: Text('$courseName - $className', overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) _fetchStudents(val);
              },
            ),
          ),
          
          // List Mahasiswa
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : _selectedClassId == null
                    ? Center(child: Text('Silakan pilih kelas terlebih dahulu', style: TextStyle(color: textSecondary)))
                    : _students.isEmpty
                        ? Center(child: Text('Tidak ada mahasiswa di kelas ini', style: TextStyle(color: textSecondary)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: _students.length,
                            itemBuilder: (context, index) {
                              final enrollment = _students[index];
                              // Pengecekan null yang aman
                              final student = enrollment['mahasiswa'] ?? {};
                              final studentName = student['name'] ?? 'Mahasiswa';
                              final studentNim = student['nim'] ?? '-';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: primaryColor.withValues(alpha: 0.1),
                                      child: Text(
                                        studentName.isNotEmpty ? studentName.substring(0, 1).toUpperCase() : '?',
                                        style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(studentName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary)),
                                          const SizedBox(height: 4),
                                          Text(studentNim, style: TextStyle(color: textSecondary, fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor.withValues(alpha: 0.1),
                                        foregroundColor: primaryColor,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: () => _showInputNilaiDialog(enrollment),
                                      child: const Text('Input Nilai', style: TextStyle(fontWeight: FontWeight.bold)),
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
          )
        ],
      ),
    );
  }
}