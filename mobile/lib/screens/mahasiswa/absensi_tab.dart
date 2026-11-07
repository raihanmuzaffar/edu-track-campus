import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'qr_scanner_screen.dart'; // <--- IMPORT HALAMAN SCANNER

class AbsensiTab extends StatefulWidget {
  const AbsensiTab({super.key});

  @override
  State<AbsensiTab> createState() => _AbsensiTabState();
}

class _AbsensiTabState extends State<AbsensiTab> {
  bool _isLoading = true;
  List<dynamic> _attendanceData = [];
  final Color primaryColor = const Color(0xFF145A4A);
  final Color textPrimary = const Color(0xFF1F2937);
  final Color textSecondary = const Color(0xFF6B7280);
  final Color borderColor = const Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    _fetchAttendance();
  }

  Future<void> _fetchAttendance() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/attendances/my');
      setState(() {
        _attendanceData = response['data'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching Attendance: $e");
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'hadir': return Colors.green;
      case 'izin': return Colors.blue;
      case 'sakit': return Colors.orange;
      case 'alpa': return Colors.red;
      default: return textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Rekap Kehadiran', style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 1),
        ),
      ),
      // --- TAMBAHAN TOMBOL SCAN QR ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QrScannerScreen()),
          );
          _fetchAttendance(); // Refresh data setelah kembali dari scanner
        },
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan QR', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      // -------------------------------
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _attendanceData.isEmpty
              ? Center(child: Text('Belum ada data kehadiran', style: TextStyle(color: textSecondary)))
              : RefreshIndicator(
                  color: primaryColor,
                  onRefresh: _fetchAttendance,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _attendanceData.length,
                    itemBuilder: (context, index) {
                      final item = _attendanceData[index];
                      // PERBAIKAN: Mengubah 'Class' dan 'Course' menjadi huruf kecil
                      final course = item['class']?['course'] ?? {};
                      final date = item['date'] != null ? item['date'].toString().substring(0, 10) : '-';
                      final status = item['status'] ?? '-';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(course['name'] ?? 'Mata Kuliah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary)),
                                  const SizedBox(height: 4),
                                  Text('Tanggal: $date', style: TextStyle(color: textSecondary, fontSize: 13)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  color: _getStatusColor(status),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}