import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class NilaiTab extends StatefulWidget {
  const NilaiTab({super.key});

  @override
  State<NilaiTab> createState() => _NilaiTabState();
}

class _NilaiTabState extends State<NilaiTab> {
  bool _isLoading = true;
  List<dynamic> _gradesData = [];
  final Color primaryColor = const Color(0xFF145A4A);
  final Color textPrimary = const Color(0xFF1F2937);
  final Color textSecondary = const Color(0xFF6B7280);
  final Color borderColor = const Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    _fetchGrades();
  }

  Future<void> _fetchGrades() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/grades/my');
      setState(() {
        _gradesData = response['data'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching Grades: $e");
      setState(() => _isLoading = false);
    }
  }

  Color _getGradeColor(String letter) {
    switch (letter) {
      case 'A': return Colors.green;
      case 'B': return Colors.blue;
      case 'C': return Colors.orange;
      case 'D': case 'E': return Colors.red;
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
        title: Text('Transkrip Nilai', style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 1),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _gradesData.isEmpty
              ? Center(child: Text('Belum ada nilai', style: TextStyle(color: textSecondary)))
              : RefreshIndicator(
                  color: primaryColor,
                  onRefresh: _fetchGrades,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _gradesData.length,
                    itemBuilder: (context, index) {
                      final item = _gradesData[index];
                      // PERBAIKAN: Mengubah 'Class' dan 'Course' menjadi huruf kecil
                      final course = item['class']?['course'] ?? {};
                      final score = item['score']?.toString() ?? '-';
                      final letter = item['letter']?.toString() ?? '-';

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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(course['name'] ?? 'Mata Kuliah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary)),
                                  const SizedBox(height: 4),
                                  Text('${course['code'] ?? '-'} • ${course['sks'] ?? 0} SKS', style: TextStyle(color: textSecondary, fontSize: 13)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(score, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getGradeColor(letter).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    letter,
                                    style: TextStyle(fontWeight: FontWeight.bold, color: _getGradeColor(letter)),
                                  ),
                                )
                              ],
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