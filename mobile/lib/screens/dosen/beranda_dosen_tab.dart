import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'qr_generator_screen.dart';

class BerandaDosenTab extends StatefulWidget {
  const BerandaDosenTab({super.key});

  @override
  State<BerandaDosenTab> createState() => _BerandaDosenTabState();
}

class _BerandaDosenTabState extends State<BerandaDosenTab> {
  bool _isLoading = true;
  List<dynamic> _myClasses = [];
  String _dosenName = 'Dosen';
  
  // Palet warna Enterprise
  final Color primaryColor = const Color(0xFF145A4A);
  final Color bgColor = const Color(0xFFF4F6F8);
  final Color textPrimary = const Color(0xFF1F2937);
  final Color textSecondary = const Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final meResponse = await ApiService.get('/users/me');
      _dosenName = meResponse['data']['name'] ?? 'Dosen';
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

  // Fungsi bantuan untuk mendapatkan ikon berdasarkan nama mata kuliah
  IconData _getCourseIcon(String courseName) {
    final name = courseName.toLowerCase();
    if (name.contains('pemrograman') || name.contains('coding')) return Icons.code;
    if (name.contains('basis data') || name.contains('database')) return Icons.storage;
    if (name.contains('jaringan') || name.contains('network')) return Icons.router;
    if (name.contains('desain') || name.contains('ui')) return Icons.design_services;
    return Icons.book; // Ikon default
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: primaryColor))
            : RefreshIndicator(
                color: primaryColor,
                onRefresh: _fetchData,
                child: CustomScrollView(
                  slivers: [
                    // --- HEADER ---
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selamat Datang,',
                                  style: TextStyle(fontSize: 14, color: textSecondary, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _dosenName,
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary),
                                ),
                              ],
                            ),
                            // Avatar Profil
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: primaryColor.withValues(alpha: 0.2), width: 2),
                              ),
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: primaryColor.withValues(alpha: 0.1),
                                child: Icon(Icons.person, color: primaryColor, size: 28),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),

                    // --- BANNER INFO (Opsional, untuk mempercantik) ---
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF145A4A), Color(0xFF1E7B67)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Portal Dosen',
                                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Kelola absensi dan nilai mahasiswa dengan mudah dalam satu genggaman.',
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(Icons.workspace_premium, color: Colors.white.withValues(alpha: 0.3), size: 60),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // --- SECTION TITLE ---
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Kelas Mengajar',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_myClasses.length} Kelas',
                                style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),

                    // --- LIST KELAS ---
                    _myClasses.isEmpty
                        ? SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.class_outlined, size: 80, color: textSecondary.withValues(alpha: 0.3)),
                                  const SizedBox(height: 16),
                                  Text('Belum ada kelas yang ditugaskan.', style: TextStyle(color: textSecondary, fontSize: 16)),
                                ],
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final c = _myClasses[index];
                                final course = c['course'] ?? {};
                                final courseName = course['name'] ?? 'Mata Kuliah';
                                final className = c['name'] ?? 'Kelas';
                                final day = c['day'] ?? '-';
                                final time = "${c['start_time']} - ${c['end_time']}";
                                final room = c['room'] ?? '-';

                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.04),
                                          blurRadius: 20,
                                          offset: const Offset(0, 4),
                                        )
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: () {
                                          // Aksi jika kartu diklik (opsional)
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Top Row: Icon & Title
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                      color: primaryColor.withValues(alpha: 0.1),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Icon(
                                                      _getCourseIcon(courseName),
                                                      color: primaryColor,
                                                      size: 24,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          courseName,
                                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Text(
                                                          'Kelas: $className',
                                                          style: TextStyle(fontSize: 13, color: primaryColor, fontWeight: FontWeight.w600),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 16),
                                              
                                              // Middle Row: Schedule Info
                                              Row(
                                                children: [
                                                  Icon(Icons.calendar_today, size: 14, color: textSecondary),
                                                  const SizedBox(width: 6),
                                                  Text(day, style: TextStyle(fontSize: 13, color: textSecondary)),
                                                  const SizedBox(width: 16),
                                                  Icon(Icons.access_time, size: 14, color: textSecondary),
                                                  const SizedBox(width: 6),
                                                  Text(time, style: TextStyle(fontSize: 13, color: textSecondary)),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Icon(Icons.location_on_outlined, size: 14, color: textSecondary),
                                                  const SizedBox(width: 6),
                                                  Text(room, style: TextStyle(fontSize: 13, color: textSecondary)),
                                                ],
                                              ),
                                              
                                              const SizedBox(height: 20),
                                              Divider(height: 1, color: Colors.grey.shade200),
                                              const SizedBox(height: 16),
                                              
                                              // Bottom Row: Action Button
                                              SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: primaryColor,
                                                    foregroundColor: Colors.white,
                                                    elevation: 0,
                                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                  ),
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => QrGeneratorScreen(classId: c['id'], className: className),
                                                      ),
                                                    );
                                                  },
                                                  icon: const Icon(Icons.qr_code_scanner, size: 20),
                                                  label: const Text('Buka Sesi QR Absensi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              childCount: _myClasses.length,
                            ),
                          ),
                    
                    // Spasi bawah
                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                ),
              ),
      ),
    );
  }
}