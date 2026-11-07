import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/api_service.dart';

class QrGeneratorScreen extends StatefulWidget {
  final int classId;
  final String className;

  const QrGeneratorScreen({super.key, required this.classId, required this.className});

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  String? _qrToken;
  int _secondsRemaining = 0;
  Timer? _timer;
  int? _sessionId;

  final Color primaryColor = const Color(0xFF145A4A);
  final Color textPrimary = const Color(0xFF1F2937);
  final Color textSecondary = const Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _generateQR();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _generateQR() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.post('/qr/generate', {'class_id': widget.classId});
      final data = response['data'];
      
      setState(() {
        _qrToken = data['token'];
        _sessionId = data['id'];
        // Hitung sisa waktu (default 15 menit / 900 detik dari backend)
        _secondsRemaining = 15 * 60; 
        _isLoading = false;
      });

      _startTimer();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        setState(() => _qrToken = null); // Sembunyikan QR jika expired
      }
    });
  }

  Future<void> _closeSession() async {
    if (_sessionId == null) return;
    try {
      await ApiService.post('/qr/close?id=$_sessionId', {});
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menutup sesi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('QR Absensi - ${widget.className}', style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: textPrimary),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE5E7EB), height: 1),
        ),
      ),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator(color: primaryColor)
            : _errorMessage != null
                ? Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 16)),
                  )
                : _qrToken == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.timer_off, size: 80, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('Sesi QR telah berakhir', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _generateQR,
                            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                            child: const Text('Buat QR Baru'),
                          )
                        ],
                      )
                    : SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            Text('Pindai QR Code ini untuk absensi', style: TextStyle(color: textSecondary, fontSize: 16)),
                            const SizedBox(height: 32),
                            
                            // --- KOTAK QR CODE & TOKEN TEXT ---
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  QrImageView(
                                    data: _qrToken!,
                                    version: QrVersions.auto,
                                    size: 250.0,
                                    eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: primaryColor),
                                    dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: primaryColor),
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  // TAMBAHAN: Teks token asli untuk testing
                                  const Text(
                                    'DEV MODE - Copy Token Ini:',
                                    style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  SelectableText(
                                    _qrToken!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // --- TIMER MUNDUR ---
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.timer, color: Colors.red),
                                const SizedBox(width: 8),
                                Text(
                                  'Berlaku: ${_formatTime(_secondsRemaining)}',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 40),
                            
                            // --- TOMBOL TUTUP SESI ---
                            TextButton.icon(
                              onPressed: _closeSession,
                              icon: const Icon(Icons.stop_circle, color: Colors.red),
                              label: const Text('Tutup Sesi Sekarang', style: TextStyle(color: Colors.red, fontSize: 16)),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
      ),
    );
  }
}