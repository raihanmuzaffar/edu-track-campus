import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/orang_tua_preview_data.dart';
import '../../services/api_service.dart';
import 'widgets/orang_tua_theme.dart';
import 'widgets/parent_card.dart';
import 'widgets/section_header.dart';

class ProfilOrangTuaTab extends StatefulWidget {
  const ProfilOrangTuaTab({
    super.key,
    required this.data,
    required this.isDemo,
  });

  final OrangTuaDashboardData data;
  final bool isDemo;

  @override
  State<ProfilOrangTuaTab> createState() => _ProfilOrangTuaTabState();
}

class _ProfilOrangTuaTabState extends State<ProfilOrangTuaTab> {
  late Future<String?> _emailFuture;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _emailFuture = _readEmail();
  }

  @override
  void didUpdateWidget(covariant ProfilOrangTuaTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDemo != widget.isDemo) {
      _emailFuture = _readEmail();
    }
  }

  Future<String?> _readEmail() async {
    if (widget.isDemo) return widget.data.parent?.email;
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString('email');
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: OrangTuaColors.surface,
        title: const Text('Keluar dari akun?'),
        content: const Text('Sesi akun akan diakhiri pada perangkat ini.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: OrangTuaColors.emeraldDark,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (shouldLogout != true || !mounted) return;

    setState(() => _isLoggingOut = true);
    try {
      await ApiService.logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal keluar dari akun: $error')));
      setState(() => _isLoggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final parent = widget.data.parent;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      children: [
        SectionHeader(
          title: 'Profil orang tua',
          subtitle: 'Informasi akun dan preferensi aplikasi.',
          isDemo: widget.isDemo,
        ),
        ParentCard(
          padding: const EdgeInsets.fromLTRB(19, 21, 19, 18),
          child: Column(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: OrangTuaColors.paleGreen,
                  borderRadius: BorderRadius.circular(23),
                ),
                child: const Icon(
                  Icons.family_restroom_rounded,
                  color: OrangTuaColors.emeraldDark,
                  size: 34,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                parent?.name ?? 'Akun Orang Tua',
                style: const TextStyle(
                  color: OrangTuaColors.forest,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                parent?.relation ?? 'Orang tua mahasiswa',
                style: const TextStyle(
                  color: OrangTuaColors.muted,
                  fontSize: 12,
                ),
              ),
              if (widget.isDemo) ...[
                const SizedBox(height: 11),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: OrangTuaColors.paleOrange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'AKUN CONTOH · DEMO',
                    style: TextStyle(
                      color: Color(0xFF9A5728),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        ParentCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informasi akun',
                style: TextStyle(
                  color: OrangTuaColors.forest,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              _AccountRow(
                icon: Icons.email_outlined,
                label: 'Email',
                child: FutureBuilder<String?>(
                  future: _emailFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text(
                        'Gagal memuat email: ${snapshot.error}',
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          color: Color(0xFFBD6C63),
                          fontSize: 11,
                        ),
                      );
                    }
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }
                    return Text(
                      snapshot.data ?? 'Belum tersedia',
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: OrangTuaColors.forest,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 21, color: OrangTuaColors.border),
              _AccountRow(
                icon: Icons.shield_outlined,
                label: 'Jenis akun',
                child: const Text(
                  'Orang tua',
                  style: TextStyle(
                    color: OrangTuaColors.forest,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ParentCard(
          padding: const EdgeInsets.all(16),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                color: OrangTuaColors.emerald,
                size: 20,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Data akun ditampilkan dari sesi yang sudah ada. '
                  'Pengaturan autentikasi tetap mengikuti aplikasi utama.',
                  style: TextStyle(
                    color: OrangTuaColors.muted,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (widget.isDemo)
          ParentCard(
            color: OrangTuaColors.paleOrange,
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.visibility_outlined,
                  color: Color(0xFF9A5728),
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Mode preview tidak membuat atau mengakhiri sesi login. '
                    'Tombol keluar hanya tersedia pada aplikasi utama.',
                    style: TextStyle(
                      color: Color(0xFF80552F),
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoggingOut ? null : _logout,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFAD5049),
                side: const BorderSide(color: Color(0xFFE7C7C2)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: _isLoggingOut
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout_rounded, size: 19),
              label: Text(_isLoggingOut ? 'Memproses...' : 'Keluar dari akun'),
            ),
          ),
        const SizedBox(height: 24),
        const Center(
          child: Text(
            'EduTrack Campus  ·  Mobile Orang Tua',
            style: TextStyle(
              color: OrangTuaColors.muted,
              fontSize: 10,
              letterSpacing: .2,
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.icon,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: OrangTuaColors.muted, size: 18),
      const SizedBox(width: 9),
      Text(
        label,
        style: const TextStyle(color: OrangTuaColors.muted, fontSize: 12),
      ),
      const Spacer(),
      Flexible(child: child),
    ],
  );
}
