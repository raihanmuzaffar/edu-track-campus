import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';

const Color qrGeneratorNavy = Color(0xFF142B4A);
const Color qrGeneratorAccent = Color(0xFFFFD34E);
const Color qrGeneratorBackground = Color(0xFFF4F6F8);
const Color qrGeneratorText = Color(0xFF1F2937);
const Color qrGeneratorMuted = Color(0xFF6B7280);

class QrGeneratorScreen extends StatefulWidget {
  final int classId;
  final String className;
  final String? qrToken;
  final int? sessionId;
  final DateTime? expiresAt;
  final String? courseName;
  final String? programName;
  final String? courseCode;
  final String? schedule;
  final String? lecturerName;
  final String? sessionLabel;

  const QrGeneratorScreen({
    super.key,
    required this.classId,
    required this.className,
    this.qrToken,
    this.sessionId,
    this.expiresAt,
    this.courseName,
    this.programName,
    this.courseCode,
    this.schedule,
    this.lecturerName,
    this.sessionLabel,
  });

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  static const _sessionLifetime = Duration(minutes: 15);

  bool _isLoading = false;
  bool _isClosing = false;
  bool _isRestoredUnverified = false;
  bool _sessionExpired = false;
  String? _errorMessage;
  String? _qrToken;
  DateTime? _expiresAt;
  int _secondsRemaining = 0;
  Timer? _timer;
  int? _sessionId;

  String get _sessionStorageKey => 'qr_generator_session_${widget.classId}';

  @override
  void initState() {
    super.initState();
    if (widget.classId <= 0) {
      _errorMessage = 'ID kelas tidak valid. QR tidak dapat ditampilkan.';
    } else if (widget.className.trim().isEmpty) {
      _errorMessage = 'Data kelas tidak tersedia. QR tidak dapat ditampilkan.';
    } else {
      _isLoading = true;
      unawaited(_restoreSession());
    }
  }

  Future<void> _restoreSession() async {
    try {
      final suppliedToken = widget.qrToken?.trim();
      Map<String, dynamic>? session;
      final suppliedSession =
          suppliedToken != null &&
          suppliedToken.isNotEmpty &&
          widget.sessionId != null &&
          widget.sessionId! > 0 &&
          widget.expiresAt != null;

      if (suppliedSession) {
        session = {
          'token': suppliedToken,
          'id': widget.sessionId,
          'class_id': widget.classId,
          'expires_at': widget.expiresAt!.toIso8601String(),
        };
      } else {
        final preferences = await SharedPreferences.getInstance();
        final storedSession = preferences.getString(_sessionStorageKey);
        if (storedSession != null) {
          final decoded = jsonDecode(storedSession);
          if (decoded is! Map<String, dynamic>) {
            throw const FormatException('Format sesi QR tersimpan tidak valid.');
          }
          session = decoded;
        }
      }

      if (!mounted) return;
      if (session == null) {
        setState(() => _isLoading = false);
        return;
      }

      final token = session['token'];
      final sessionId = _parseInt(session['id']);
      final storedClassId = _parseInt(session['class_id']);
      final expiresAt = DateTime.tryParse(
        session['expires_at']?.toString() ?? '',
      );
      if (token is! String ||
          token.trim().isEmpty ||
          sessionId == null ||
          sessionId <= 0 ||
          storedClassId != widget.classId ||
          expiresAt == null) {
        throw const FormatException('Data sesi QR tersimpan tidak lengkap.');
      }

      final remaining = expiresAt.difference(DateTime.now()).inSeconds;
      if (remaining <= 0) {
        await _removeSavedSession();
        if (!mounted) return;
        setState(() {
          _sessionExpired = true;
          _isLoading = false;
        });
        return;
      }

      String? persistenceWarning;
      if (suppliedSession) {
        try {
          await _saveSession(
            token: token,
            sessionId: sessionId,
            expiresAt: expiresAt,
          );
        } catch (error) {
          persistenceWarning =
              'QR tersedia, tetapi tidak dapat disimpan untuk dibuka kembali: '
              '${_errorText(error)}';
        }
      }
      if (!mounted) return;
      setState(() {
        _qrToken = token;
        _sessionId = sessionId;
        _expiresAt = expiresAt;
        _secondsRemaining = remaining
            .clamp(0, _sessionLifetime.inSeconds)
            .toInt();
        _isRestoredUnverified = true;
        _isLoading = false;
      });
      _startTimer();
      if (persistenceWarning != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(persistenceWarning)),
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Sesi tersimpan tidak dapat diperiksa: ${_errorText(error)}';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _generateQR() async {
    if (_isLoading ||
        _isClosing ||
        (_qrToken != null && _secondsRemaining > 0)) {
      return;
    }
    if (widget.classId <= 0) {
      setState(() {
        _errorMessage = 'ID kelas tidak valid. QR tidak dapat dibuat.';
      });
      return;
    }
    if (widget.className.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Data kelas tidak tersedia. QR tidak dapat dibuat.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.post('/qr/generate', {
        'class_id': widget.classId,
      });
      final data = response is Map<String, dynamic> ? response['data'] : null;
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Respons pembuatan QR tidak valid.');
      }
      final token = data['token'];
      final sessionId = _parseInt(data['id']);
      final responseClassId = _parseInt(data['class_id']);
      final expiryValue = data['expires_at'];
      final expiresAt = expiryValue == null
          ? DateTime.now().add(_sessionLifetime)
          : DateTime.tryParse(expiryValue.toString());
      if (token is! String ||
          token.trim().isEmpty ||
          sessionId == null ||
          sessionId <= 0 ||
          responseClassId != widget.classId ||
          expiresAt == null) {
        throw const FormatException(
          'Respons QR tidak cocok dengan kelas yang sedang dibuka.',
        );
      }
      final remaining = expiresAt.difference(DateTime.now()).inSeconds;
      if (remaining <= 0) {
        throw const FormatException('Sesi QR sudah kedaluwarsa.');
      }

      String? persistenceWarning;
      try {
        await _saveSession(
          token: token,
          sessionId: sessionId,
          expiresAt: expiresAt,
        );
      } catch (error) {
        persistenceWarning =
            'QR berhasil dibuat, tetapi tidak dapat disimpan untuk dibuka kembali: '
            '${_errorText(error)}';
      }
      if (!mounted) return;
      setState(() {
        _qrToken = token;
        _sessionId = sessionId;
        _expiresAt = expiresAt;
        _secondsRemaining = remaining
            .clamp(0, _sessionLifetime.inSeconds)
            .toInt();
        _isRestoredUnverified = false;
        _sessionExpired = false;
        _isLoading = false;
      });
      _startTimer();
      if (persistenceWarning != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(persistenceWarning)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _errorText(e);
        _isLoading = false;
      });
    }
  }

  int? _parseInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  String _errorText(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  Future<void> _saveSession({
    required String token,
    required int sessionId,
    required DateTime expiresAt,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _sessionStorageKey,
      jsonEncode({
        'token': token,
        'id': sessionId,
        'class_id': widget.classId,
        'expires_at': expiresAt.toIso8601String(),
      }),
    );
    if (!saved) {
      throw StateError('Penyimpanan lokal menolak data sesi.');
    }
  }

  Future<void> _removeSavedSession() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_sessionStorageKey);
  }

  Future<void> _removeExpiredSession() async {
    try {
      await _removeSavedSession();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Data QR kedaluwarsa gagal dihapus: ${_errorText(error)}',
          ),
        ),
      );
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final remaining =
          _expiresAt?.difference(DateTime.now()).inSeconds ?? 0;
      if (remaining > 0) {
        setState(() {
          _secondsRemaining = remaining
              .clamp(0, _sessionLifetime.inSeconds)
              .toInt();
        });
      } else {
        timer.cancel();
        setState(() {
          _qrToken = null;
          _secondsRemaining = 0;
          _isRestoredUnverified = false;
          _sessionExpired = true;
        });
        unawaited(_removeExpiredSession());
      }
    });
  }

  Future<void> _closeSession() async {
    if (_sessionId == null ||
        _isClosing ||
        _qrToken == null ||
        _secondsRemaining <= 0) {
      return;
    }
    setState(() => _isClosing = true);
    try {
      await ApiService.post('/qr/close?id=$_sessionId', {});
      if (!mounted) return;
      _timer?.cancel();
      String? persistenceWarning;
      try {
        await _removeSavedSession();
      } catch (error) {
        persistenceWarning =
            'Sesi ditutup, tetapi data pemulihan lokal tidak dapat dihapus: '
            '${_errorText(error)}';
      }
      if (!mounted) return;
      if (persistenceWarning != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(persistenceWarning)),
        );
      }
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menutup sesi: ${_errorText(e)}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isClosing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return QrGeneratorPageView(
      className: widget.className,
      courseName: widget.courseName,
      programName: widget.programName,
      courseCode: widget.courseCode,
      schedule: widget.schedule,
      lecturerName: widget.lecturerName,
      sessionLabel: widget.sessionLabel,
      isLoading: _isLoading,
      isClosing: _isClosing,
      errorMessage: _errorMessage,
      qrToken: _qrToken,
      secondsRemaining: _secondsRemaining,
      sessionId: _sessionId,
      onGenerate: _generateQR,
      onClose: _sessionId == null ? null : _closeSession,
      isRestoredUnverified: _isRestoredUnverified,
      emptyStatusLabel: _sessionExpired ? 'Sesi berakhir' : 'Belum dibuat',
      generateButtonLabel: _sessionExpired ? 'Buat QR Baru' : 'Buat QR',
    );
  }
}

class QrGeneratorPageView extends StatelessWidget {
  final String className;
  final String? courseName;
  final String? programName;
  final String? courseCode;
  final String? schedule;
  final String? lecturerName;
  final String? sessionLabel;
  final bool isLoading;
  final bool isClosing;
  final String? errorMessage;
  final String? qrToken;
  final int secondsRemaining;
  final int? sessionId;
  final VoidCallback onGenerate;
  final VoidCallback? onClose;
  final bool isSimulation;
  final bool isRestoredUnverified;
  final String emptyStatusLabel;
  final String generateButtonLabel;
  final String? simulationNotice;

  const QrGeneratorPageView({
    super.key,
    required this.className,
    required this.isLoading,
    required this.errorMessage,
    required this.qrToken,
    required this.secondsRemaining,
    required this.sessionId,
    required this.onGenerate,
    required this.onClose,
    this.isClosing = false,
    this.courseName,
    this.programName,
    this.courseCode,
    this.schedule,
    this.lecturerName,
    this.sessionLabel,
    this.isSimulation = false,
    this.isRestoredUnverified = false,
    this.emptyStatusLabel = 'Belum dibuat',
    this.generateButtonLabel = 'Buat QR',
    this.simulationNotice,
  });

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final hasQr =
        !isLoading &&
        errorMessage == null &&
        qrToken != null &&
        secondsRemaining > 0;
    final isActive = hasQr && !isRestoredUnverified;
    final statusLabel = isLoading
        ? 'Menyiapkan QR'
        : errorMessage != null
        ? 'QR gagal dibuat'
        : isRestoredUnverified && hasQr
        ? 'Sesi tersimpan · belum diverifikasi'
        : isActive
        ? (isSimulation ? 'Simulasi aktif' : 'Sesi absensi aktif')
        : emptyStatusLabel;
    final statusColor = isLoading
        ? qrGeneratorNavy
        : errorMessage != null
        ? const Color(0xFFB42318)
        : isRestoredUnverified && hasQr
        ? const Color(0xFF9A6700)
        : isActive
        ? const Color(0xFF16845B)
        : const Color(0xFF9A6700);
    final qrSize = (MediaQuery.sizeOf(context).width - 64)
        .clamp(160.0, 420.0)
        .toDouble();

    return Scaffold(
      backgroundColor: qrGeneratorBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: qrGeneratorNavy,
        elevation: 0,
        title: const Text(
          'QR Generator',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE7EAF0)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _QrStatusCard(
                  label: statusLabel,
                  message: isRestoredUnverified && hasQr
                      ? 'QR tersimpan, tetapi status sesi pada server tidak dapat diverifikasi.'
                      : isActive
                      ? 'Tunjukkan QR ini kepada mahasiswa.'
                      : isLoading
                      ? 'Sedang menyiapkan sesi absensi.'
                      : errorMessage ?? 'Buat QR untuk memulai sesi absensi.',
                  color: statusColor,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE1E7EF)),
                  ),
                  child: Column(
                    children: [
                      if (isLoading)
                        SizedBox(
                          width: qrSize,
                          height: qrSize,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: qrGeneratorNavy,
                            ),
                          ),
                        )
                      else if (hasQr)
                        QrImageView(
                          data: qrToken!,
                          version: QrVersions.auto,
                          size: qrSize,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: qrGeneratorNavy,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: qrGeneratorNavy,
                          ),
                        )
                      else
                        SizedBox(
                          width: qrSize,
                          height: qrSize,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  errorMessage == null
                                      ? Icons.qr_code_2_rounded
                                      : Icons.error_outline_rounded,
                                  color: const Color(0xFF9AA5B4),
                                  size: 46,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  errorMessage == null
                                      ? 'QR belum tersedia'
                                      : 'QR belum dapat dibuat',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: qrGeneratorText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (simulationNotice != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          simulationNotice!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF8A5A00),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                      if (hasQr) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 19,
                              color: secondsRemaining <= 60
                                  ? const Color(0xFFB54708)
                                  : qrGeneratorNavy,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              'Berlaku ${_formatTime(secondsRemaining)}',
                              style: TextStyle(
                                color: secondsRemaining <= 60
                                    ? const Color(0xFFB54708)
                                    : qrGeneratorNavy,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _ClassInformationCard(
                  className: className,
                  courseName: courseName,
                  programName: programName,
                  courseCode: courseCode,
                  schedule: schedule,
                  lecturerName: lecturerName,
                  sessionLabel: sessionLabel,
                  sessionId: sessionId,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading || isClosing
                        ? null
                        : hasQr
                        ? onClose
                        : onGenerate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: qrGeneratorAccent,
                      foregroundColor: qrGeneratorNavy,
                      disabledBackgroundColor: qrGeneratorAccent,
                      disabledForegroundColor: qrGeneratorNavy.withValues(
                        alpha: 0.6,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: isClosing
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: qrGeneratorNavy,
                                ),
                              ),
                              SizedBox(width: 9),
                              Text('Menyelesaikan...'),
                            ],
                          )
                        : Text(hasQr ? 'Selesai' : generateButtonLabel),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => _showDetails(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: qrGeneratorNavy,
                      side: const BorderSide(color: qrGeneratorNavy),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Cek Detail Pertemuan'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => _SessionDetailsDialog(
        className: className,
        courseName: courseName,
        programName: programName,
        courseCode: courseCode,
        schedule: schedule,
        lecturerName: lecturerName,
        sessionLabel: sessionLabel,
        sessionId: sessionId,
      ),
    );
  }
}

class _QrStatusCard extends StatelessWidget {
  final String label;
  final String message;
  final Color color;

  const _QrStatusCard({
    required this.label,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E7EF)),
      ),
      child: Row(
        children: [
          Icon(
            color == const Color(0xFF16845B)
                ? Icons.check_circle_rounded
                : color == const Color(0xFFB42318)
                ? Icons.error_rounded
                : Icons.event_available_rounded,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: qrGeneratorMuted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassInformationCard extends StatelessWidget {
  final String className;
  final String? courseName;
  final String? programName;
  final String? courseCode;
  final String? schedule;
  final String? lecturerName;
  final String? sessionLabel;
  final int? sessionId;

  const _ClassInformationCard({
    required this.className,
    required this.courseName,
    required this.programName,
    required this.courseCode,
    required this.schedule,
    required this.lecturerName,
    required this.sessionLabel,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E7EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            courseName == null || courseName!.trim().isEmpty
                ? 'Informasi perkuliahan'
                : courseName!,
            style: const TextStyle(
              color: qrGeneratorText,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (programName != null && programName!.trim().isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              programName!,
              style: const TextStyle(color: qrGeneratorMuted, fontSize: 12),
            ),
          ],
          const Divider(height: 22, color: Color(0xFFEEF1F5)),
          _InformationRow(label: 'Kelas', value: className),
          if (courseCode != null && courseCode!.trim().isNotEmpty)
            _InformationRow(label: 'Kode', value: courseCode!),
          if (schedule != null && schedule!.trim().isNotEmpty)
            _InformationRow(label: 'Jadwal', value: schedule!),
          if (lecturerName != null && lecturerName!.trim().isNotEmpty)
            _InformationRow(label: 'Dosen', value: lecturerName!),
          if (sessionLabel != null && sessionLabel!.trim().isNotEmpty)
            _InformationRow(label: 'Sesi', value: sessionLabel!),
          if (sessionId != null)
            _InformationRow(label: 'ID sesi', value: sessionId.toString()),
        ],
      ),
    );
  }
}

class _InformationRow extends StatelessWidget {
  final String label;
  final String value;

  const _InformationRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: const TextStyle(color: qrGeneratorMuted, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: qrGeneratorText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _SessionDetailsDialog extends StatelessWidget {
  final String className;
  final String? courseName;
  final String? programName;
  final String? courseCode;
  final String? schedule;
  final String? lecturerName;
  final String? sessionLabel;
  final int? sessionId;

  const _SessionDetailsDialog({
    required this.className,
    required this.courseName,
    required this.programName,
    required this.courseCode,
    required this.schedule,
    required this.lecturerName,
    required this.sessionLabel,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context) {
    final details = <(String, String)>[
      if (courseName != null && courseName!.isNotEmpty)
        ('Mata kuliah', courseName!),
      if (programName != null && programName!.isNotEmpty)
        ('Program studi', programName!),
      if (courseCode != null && courseCode!.isNotEmpty) ('Kode', courseCode!),
      ('Kelas', className),
      if (schedule != null && schedule!.isNotEmpty) ('Jadwal', schedule!),
      if (lecturerName != null && lecturerName!.isNotEmpty)
        ('Dosen', lecturerName!),
      if (sessionLabel != null && sessionLabel!.isNotEmpty)
        ('Sesi', sessionLabel!),
      if (sessionId != null) ('ID sesi', sessionId.toString()),
    ];

    return AlertDialog(
      title: const Text('Detail Pertemuan'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < details.length; index++) ...[
            if (index > 0) const Divider(height: 18),
            _InformationRow(label: details[index].$1, value: details[index].$2),
          ],
          if (details.length == 1)
            const Text(
              'Informasi mata kuliah, jadwal, dan dosen belum tersedia.',
              style: TextStyle(color: qrGeneratorMuted),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}
