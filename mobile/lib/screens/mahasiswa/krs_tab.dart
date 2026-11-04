import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class KrsTab extends StatefulWidget {
  const KrsTab({super.key});

  @override
  State<KrsTab> createState() => _KrsTabState();
}

class _KrsTabState extends State<KrsTab> {
  bool _isLoading = true;
  List<dynamic> _krsData = [];
  final Color primaryColor = const Color(0xFF145A4A);
  final Color textPrimary = const Color(0xFF1F2937);
  final Color textSecondary = const Color(0xFF6B7280);
  final Color borderColor = const Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    _fetchKRS();
  }

  Future<void> _fetchKRS() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/enrollments/my');
      setState(() {
        _krsData = response['data'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching KRS: $e");
      setState(() => _isLoading = false);
    }
  }

  // Fungsi untuk membuka modal daftar kelas
  void _showAvailableClasses() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAvailableClassesModal(),
    ).then((_) => _fetchKRS()); // Refresh KRS setelah modal ditutup
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Kartu Rencana Studi', style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 1),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAvailableClasses,
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Ambil Kelas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _krsData.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: primaryColor,
                  onRefresh: _fetchKRS,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _krsData.length,
                    itemBuilder: (context, index) {
                      final item = _krsData[index];
                      // PERBAIKAN: Mengubah 'Class', 'Course', dan 'Dosen' menjadi huruf kecil
                      final course = item['class']?['course'] ?? {};
                      final classData = item['class'] ?? {};
                      final dosen = classData['dosen'] ?? {};

                      return _buildKrsCard(
                        course['name'] ?? 'Mata Kuliah',
                        course['code'] ?? '-',
                        course['sks']?.toString() ?? '0',
                        dosen['name'] ?? 'Dosen Belum Ditentukan',
                        classData['day'] ?? '-',
                        "${classData['start_time'] ?? ''} - ${classData['end_time'] ?? ''}",
                        classData['room'] ?? '-',
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, size: 80, color: textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('Belum ada KRS yang diambil', style: TextStyle(color: textSecondary, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildKrsCard(String name, String code, String sks, String dosen, String day, String time, String room) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text('$sks SKS', style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 4),
          Text('Kode: $code', style: TextStyle(color: textSecondary, fontSize: 13)),
          const Divider(height: 24, color: Color(0xFFE5E7EB)),
          Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: textSecondary),
              const SizedBox(width: 6),
              Expanded(child: Text(dosen, style: TextStyle(fontSize: 13, color: textSecondary))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: textSecondary),
              const SizedBox(width: 6),
              Text('$day, $time', style: TextStyle(fontSize: 13, color: textSecondary)),
              const SizedBox(width: 16),
              Icon(Icons.location_on_outlined, size: 14, color: textSecondary),
              const SizedBox(width: 6),
              Text(room, style: TextStyle(fontSize: 13, color: textSecondary)),
            ],
          )
        ],
      ),
    );
  }

  // --- MODAL DAFTAR KELAS TERSEDIA ---
  Widget _buildAvailableClassesModal() {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle Bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              Text('Daftar Kelas Tersedia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
              const SizedBox(height: 16),
              const Divider(height: 1),
              
              // List Kelas
              Expanded(
                child: FutureBuilder(
                  future: ApiService.get('/classes/list'),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: primaryColor));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Gagal memuat kelas', style: TextStyle(color: Colors.red)));
                    }

                    final classes = snapshot.data['data']['data'] as List? ?? [];
                    
                    if (classes.isEmpty) return const Center(child: Text('Tidak ada kelas tersedia'));

                    return ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.all(16),
                      itemCount: classes.length,
                      itemBuilder: (context, index) {
                        final c = classes[index];
                        // PERBAIKAN: Mengubah 'Course' dan 'Dosen' menjadi huruf kecil
                        final course = c['course'] ?? {};
                        final dosen = c['dosen'] ?? {};
                        
                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: borderColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            title: Text(course['name'] ?? 'Mata Kuliah', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('Dosen: ${dosen['name'] ?? '-'}'),
                                Text('Jadwal: ${c['day']}, ${c['start_time']} - ${c['end_time']}'),
                                Text('Ruang: ${c['room'] ?? '-'}'),
                              ],
                            ),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _enrollClass(c['id']),
                              child: const Text('Ambil'),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              )
            ],
          ),
        );
      },
    );
  }

  // Fungsi untuk mengeksekusi Enroll
  Future<void> _enrollClass(int classId) async {
    try {
      await ApiService.post('/enrollments', {'class_id': classId});
      if (!mounted) return;
      Navigator.pop(context); // Tutup modal
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berhasil mengambil kelas!'), backgroundColor: Colors.green),
      );
      _fetchKRS(); // Refresh daftar KRS
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }
}