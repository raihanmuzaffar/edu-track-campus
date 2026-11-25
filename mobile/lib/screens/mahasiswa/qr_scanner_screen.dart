import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../services/api_service.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _isProcessing = false;
  bool _hasScanned = false;
  bool _sessionExpired = false;
  final Color primaryColor = const Color(0xFF145A4A);

  // Fungsi untuk mengirim token QR ke Backend
  Future<void> _processQrCode(String token) async {
    if (_hasScanned) return;
    if (token.trim().isEmpty) return;

    setState(() {
      _hasScanned = true;
      _isProcessing = true;
    });

    try {
      final response = await ApiService.post('/qr/scan', {'token': token});
      final attendance = response['data'];
      if (attendance is! Map || attendance['status'] != 'hadir') {
        throw const FormatException('Konfirmasi absensi tidak valid.');
      }

      if (!mounted) return;
      _showResultDialog(
        isSuccess: true,
        title: 'Absensi Berhasil!',
        message: 'Kehadiran Anda telah dicatat oleh sistem.',
      );
    } catch (e) {
      if (!mounted) return;
      _sessionExpired = e is SessionExpiredException;
      _showResultDialog(
        isSuccess: false,
        title: _sessionExpired ? 'Sesi berakhir' : 'Absensi Gagal',
        message: e.toString().replaceAll('Exception: ', ''),
        sessionExpired: _sessionExpired,
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // Dialog untuk menampilkan hasil
  void _showResultDialog({
    required bool isSuccess,
    required String title,
    required String message,
    bool sessionExpired = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Icon(
          isSuccess ? Icons.check_circle : Icons.error,
          color: isSuccess ? Colors.green : Colors.red,
          size: 60,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                if (isSuccess) {
                  Navigator.pop(this.context, true);
                } else if (sessionExpired) {
                  Navigator.pushNamedAndRemoveUntil(
                    this.context,
                    '/login',
                    (route) => false,
                  );
                } else {
                  setState(() => _hasScanned = false);
                }
              },
              child: Text(
                isSuccess
                    ? 'Selesai'
                    : sessionExpired
                    ? 'Login kembali'
                    : 'Coba Lagi',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan QR Absensi'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // --- KAMERA SCANNER ---
          MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _processQrCode(barcode.rawValue!);
                  break;
                }
              }
            },
            // PERBAIKAN: Menghapus parameter 'child'
            errorBuilder: (context, error) {
              return Center(
                child: Text(
                  'Kamera tidak dapat diakses. Periksa izin kamera atau coba lagi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              );
            },
          ),

          // --- OVERLAY (Garis Bantu & Teks) ---
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Arahkan kamera ke QR Code Dosen',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ==========================================
          // --- LOADING OVERLAY ---
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: primaryColor),
                    const SizedBox(height: 20),
                    const Text(
                      'Memproses absensi...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
