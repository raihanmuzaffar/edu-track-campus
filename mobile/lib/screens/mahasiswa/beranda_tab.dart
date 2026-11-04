import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class BerandaTab extends StatefulWidget {
  const BerandaTab({super.key});

  @override
  State<BerandaTab> createState() => _BerandaTabState();
}

class _BerandaTabState extends State<BerandaTab> {
  bool _isLoading = true;
  String _userName = 'Mahasiswa';
  int _totalSKS = 0;
  double _ipk = 0.0;
  List<dynamic> _schedules = [];
  List<dynamic> _announcements = [];

  final Color primaryColor = const Color(0xFF145A4A);
  final Color bgColor = const Color(0xFFF4F6F8);
  final Color textPrimary = const Color(0xFF1F2937);
  final Color textSecondary = const Color(0xFF6B7280);
  final Color borderColor = const Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Ambil Nama User
      final meResponse = await ApiService.get('/users/me');
      _userName = meResponse['data']?['name'] ?? 'Mahasiswa';

      // 2. Ambil KRS untuk hitung Total SKS
      final krsResponse = await ApiService.get('/enrollments/my');
      final List krsList = krsResponse['data'] ?? [];
      int sks = 0;
      for (var item in krsList) {
        // PERBAIKAN: Mengubah 'Class' dan 'Course' menjadi huruf kecil
        sks += (item['class']?['course']?['sks'] ?? 0) as int;
      }
      _totalSKS = sks;

      // 3. Ambil Nilai untuk hitung IPK
      final gradesResponse = await ApiService.get('/grades/my');
      final List gradesList = gradesResponse['data'] ?? [];
      double totalScore = 0;
      int gradeCount = 0;
      for (var grade in gradesList) {
        if (grade['score'] != null) {
          totalScore += (grade['score'] as num).toDouble();
          gradeCount++;
        }
      }
      double avgScore = gradeCount > 0 ? (totalScore / gradeCount) : 0;
      _ipk = double.parse(((avgScore / 100) * 4).toStringAsFixed(2));

      // 4. Ambil Jadwal (Ambil 2 teratas)
      final scheduleResponse = await ApiService.get('/admin/schedules/list');
      final List scheduleList = scheduleResponse['data'] ?? [];
      _schedules = scheduleList.take(2).toList();

      // 5. Ambil Pengumuman (Ambil 2 teratas)
      final announcementResponse = await ApiService.get('/admin/announcements/list');
      final List announcementList = announcementResponse['data'] ?? [];
      _announcements = announcementList.take(2).toList();

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint("Error fetching dashboard data: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.school, color: primaryColor, size: 24),
            const SizedBox(width: 8),
            Text('EduTrack', style: TextStyle(color: primaryColor, fontSize: 20, fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          IconButton(icon: Icon(Icons.search, color: textPrimary), onPressed: () {}),
          IconButton(icon: Icon(Icons.notifications_outlined, color: textPrimary), onPressed: () {}),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 1),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : RefreshIndicator(
              color: primaryColor,
              onRefresh: _fetchData,
              child: ListView(
                padding: const EdgeInsets.all(20.0),
                children: [
                  // Header Sapaan
                  Text('Halo, Selamat Datang 👋', style: TextStyle(fontSize: 14, color: textSecondary)),
                  const SizedBox(height: 4),
                  Text(_userName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary)),
                  const SizedBox(height: 24),

                  // Kartu Statistik 3 Kolom
                  Row(
                    children: [
                      _buildSmallStatCard('IPK', _ipk.toString(), 'Dari 4.00', primaryColor, true),
                      const SizedBox(width: 12),
                      _buildSmallStatCard('Total SKS', '$_totalSKS', 'SKS Lulus', primaryColor, false),
                      const SizedBox(width: 12),
                      _buildSmallStatCard('Kehadiran', '98%', 'Semester Ini', primaryColor, false),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Jadwal Hari Ini
                  _buildSectionHeader('Jadwal Terbaru', 'Lihat Semua'),
                  const SizedBox(height: 12),
                  if (_schedules.isEmpty)
                    Text('Tidak ada jadwal untuk saat ini', style: TextStyle(color: textSecondary))
                  else
                    ..._schedules.map((s) => _buildScheduleListItem(
                          // PERBAIKAN: Mengubah 'Course' menjadi huruf kecil
                          s['course']?['name'] ?? 'Mata Kuliah',
                          '${s['start_time']} - ${s['end_time']}',
                          s['room'] ?? '-',
                          s['day'] ?? '-',
                          Icons.schedule,
                        )),

                  const SizedBox(height: 24),

                  // Pengumuman
                  _buildSectionHeader('Informasi Terbaru', 'Lihat Semua'),
                  const SizedBox(height: 12),
                  if (_announcements.isEmpty)
                    Text('Tidak ada pengumuman terbaru', style: TextStyle(color: textSecondary))
                  else
                    ..._announcements.map((a) => _buildAnnouncementItem(
                          a['title'] ?? 'Pengumuman',
                          a['category'] ?? 'Umum',
                          a['start_date']?.toString().substring(0, 10) ?? '-',
                          Icons.info_outline,
                          Colors.blue,
                        )),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, String actionText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
        if (actionText.isNotEmpty)
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(foregroundColor: primaryColor, padding: EdgeInsets.zero, minimumSize: Size.zero),
            child: Text(actionText, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }

  Widget _buildSmallStatCard(String title, String value, String subtitle, Color primary, bool isHighlighted) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isHighlighted ? primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isHighlighted ? primary : borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 12, color: isHighlighted ? Colors.white70 : textSecondary)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isHighlighted ? Colors.white : textPrimary)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 10, color: isHighlighted ? Colors.white60 : textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleListItem(String title, String time, String room, String day, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: textSecondary),
                    const SizedBox(width: 4),
                    Text(day, style: TextStyle(fontSize: 13, color: textSecondary)),
                    const SizedBox(width: 12),
                    Icon(Icons.access_time, size: 14, color: textSecondary),
                    const SizedBox(width: 4),
                    Text(time, style: TextStyle(fontSize: 13, color: textSecondary)),
                    const SizedBox(width: 12),
                    Icon(Icons.location_on_outlined, size: 14, color: textSecondary),
                    const SizedBox(width: 4),
                    Text(room, style: TextStyle(fontSize: 13, color: textSecondary)),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementItem(String title, String category, String date, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textPrimary)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(category, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Text('•', style: TextStyle(color: textSecondary)),
                    const SizedBox(width: 8),
                    Text(date, style: TextStyle(fontSize: 12, color: textSecondary)),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}