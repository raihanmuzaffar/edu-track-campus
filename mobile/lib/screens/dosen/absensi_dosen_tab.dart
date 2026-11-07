import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AbsensiDosenTab extends StatefulWidget {
  const AbsensiDosenTab({super.key});

  @override
  State<AbsensiDosenTab> createState() => _AbsensiDosenTabState();
}

class _AbsensiDosenTabState extends State<AbsensiDosenTab> {
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
      final List allClasses = classesResponse['data']['data'] ?? [];
      
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
      // PERBAIKAN: Memanggil endpoint yang sesuai untuk Dosen
      final krsResponse = await ApiService.get('/classes/students?class_id=$classId');
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

  // Fungsi untuk membuka modal input absensi
  void _showInputAbsensiDialog(dynamic enrollment) {
    String selectedStatus = 'hadir';
    final student = enrollment['mahasiswa'] ?? {};
    final studentName = student['name'] ?? 'Mahasiswa';
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Input Absensi\n$studentName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Pilih status kehadiran:', style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedStatus,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    items: const [
                      DropdownMenuItem(value: 'hadir', child: Text('Hadir')),
                      DropdownMenuItem(value: 'izin', child: Text('Izin')),
                      DropdownMenuItem(value: 'sakit', child: Text('Sakit')),
                      DropdownMenuItem(value: 'alpa', child: Text('Alpa')),
                    ],
                    onChanged: (val) {
                      setStateDialog(() => selectedStatus = val!);
                    },
                  ),
                ],
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
                Navigator.pop(context); // Tutup dialog
                await _submitAttendance(enrollment['mahasiswa_id'], selectedStatus);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitAttendance(int mahasiswaId, String status) async {
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
        const SnackBar(content: Text('Absensi berhasil disimpan!'), backgroundColor: Colors.green),
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
        title: Text('Absensi Manual', style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
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
                              final student = enrollment['mahasiswa'] ?? {};
                              
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
                                        (student['name'] != null && student['name'].isNotEmpty) 
                                            ? student['name'].substring(0, 1).toUpperCase() 
                                            : '?',
                                        style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(student['name'] ?? 'Mahasiswa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary)),
                                          const SizedBox(height: 4),
                                          Text(student['email'] ?? '-', style: TextStyle(color: textSecondary, fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_document, color: Colors.blue),
                                      onPressed: () => _showInputAbsensiDialog(enrollment),
                                      tooltip: 'Input Absensi',
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