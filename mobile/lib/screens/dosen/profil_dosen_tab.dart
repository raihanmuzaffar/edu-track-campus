import 'package:flutter/material.dart';

import '../../services/api_service.dart';

const dosenProfileNavy = Color(0xFF14263D);
const dosenProfileNavyMedium = Color(0xFF304966);
const dosenProfileNavyMuted = Color(0xFFB7C4D1);
const _primaryColor = dosenProfileNavy;
const _accentColor = Color(0xFF294663);
const _backgroundColor = Color(0xFFF4F6F8);
const _textPrimary = Color(0xFF17283D);
const _textSecondary = Color(0xFF617186);
const _borderColor = Color(0xFFDCE4EC);
const _softColor = Color(0xFFEAF0F6);
const _dangerColor = Color(0xFFB54747);
const _programStudy = 'Teknologi Rekayasa Komputer Jaringan';
const _department = 'Teknologi Informasi dan Komputer';
const _university = 'Politeknik Negeri Lhokseumawe';

ThemeData dosenProfileTheme(ThemeData baseTheme) {
  final colorScheme = baseTheme.colorScheme.copyWith(
    primary: dosenProfileNavy,
    secondary: dosenProfileNavyMedium,
    onPrimary: Colors.white,
    surface: Colors.white,
    onSurface: _textPrimary,
  );

  return baseTheme.copyWith(
    primaryColor: dosenProfileNavy,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: _backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: dosenProfileNavy,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: dosenProfileNavy, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _dangerColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _dangerColor, width: 1.5),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: const TextStyle(
        color: _textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: const TextStyle(
        color: _textSecondary,
        fontSize: 14,
        height: 1.5,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: dosenProfileNavy,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: dosenProfileNavy),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? Colors.white
            : _textSecondary;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? dosenProfileNavyMedium
            : _softColor;
      }),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: dosenProfileNavy,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: dosenProfileNavy,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    dividerColor: _borderColor,
  );
}

class DosenProfileData {
  const DosenProfileData({
    required this.name,
    required this.email,
    this.role,
    this.nidn,
    this.nidk,
    this.academicPosition,
    this.phone,
    this.accountStatus,
    this.photoUrl,
  });

  final String name;
  final String email;
  final String? role;
  final String? nidn;
  final String? nidk;
  final String? academicPosition;
  final String? phone;
  final String? accountStatus;
  final String? photoUrl;

  factory DosenProfileData.fromJson(Map<String, dynamic> user) {
    return DosenProfileData(
      name: _firstText(user, const ['name']) ?? 'Nama belum tersedia',
      email: _firstText(user, const ['email']) ?? 'Belum tersedia',
      role: _firstText(user, const ['role']),
      nidn: _firstText(user, const ['nidn']),
      nidk: _firstText(user, const ['nidk']),
      academicPosition: _firstText(user, const [
        'jabatan_akademik',
        'academic_position',
      ]),
      phone: _firstText(user, const ['nomor_telepon', 'no_hp', 'phone']),
      accountStatus: _firstText(user, const ['status_akun', 'account_status']),
      photoUrl: _firstText(user, const [
        'foto_profil_url',
        'photo_url',
        'avatar_url',
      ]),
    );
  }
}

String? _firstText(Map<String, dynamic> values, List<String> keys) {
  for (final key in keys) {
    final value = values[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    if (value is num) {
      return value.toString();
    }
  }
  return null;
}

DosenProfileData _updatedProfile({
  required DosenProfileData current,
  required String name,
  required String email,
  required String phone,
}) {
  return DosenProfileData(
    name: name,
    email: email,
    role: current.role,
    nidn: current.nidn,
    nidk: current.nidk,
    academicPosition: current.academicPosition,
    phone: phone.isEmpty ? null : phone,
    accountStatus: current.accountStatus,
    photoUrl: current.photoUrl,
  );
}

class ProfilDosenTab extends StatefulWidget {
  const ProfilDosenTab({super.key});

  @override
  State<ProfilDosenTab> createState() => _ProfilDosenTabState();
}

class _ProfilDosenTabState extends State<ProfilDosenTab> {
  DosenProfileData? _profile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.get('/users/me');
      final user = response['data'];
      if (user is! Map) {
        throw const FormatException('Data profil tidak valid.');
      }

      if (!mounted) return;
      setState(() {
        _profile = DosenProfileData.fromJson(Map<String, dynamic>.from(user));
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Gagal memuat profil dosen: $error');
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Profil belum dapat dimuat. Periksa koneksi lalu coba lagi.';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleAction(String action) async {
    switch (action) {
      case 'change_password':
        Navigator.pushNamed(context, '/forgot-password');
      case 'logout':
        try {
          await ApiService.logout();
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/login');
        } catch (error) {
          debugPrint('Gagal keluar dari akun: $error');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: dosenProfileNavy,
              content: Text(
                'Gagal keluar. Silakan coba lagi.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }
      default:
        final message = switch (action) {
          'edit_profile' => 'Fitur edit profil belum tersedia.',
          'account_settings' => 'Pengaturan akun belum tersedia.',
          'help' => 'Pusat bantuan belum tersedia.',
          _ => 'Menu ini belum tersedia.',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: dosenProfileNavy,
            content: Text(message, style: const TextStyle(color: Colors.white)),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DosenProfileContent(
      profile: _profile,
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      onRetry: _loadUserData,
      onAction: _handleAction,
    );
  }
}

class DosenProfileContent extends StatelessWidget {
  const DosenProfileContent({
    required this.profile,
    required this.onAction,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    super.key,
  });

  final DosenProfileData? profile;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function()? onRetry;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: dosenProfileTheme(Theme.of(context)),
      child: Scaffold(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          title: const Text(
            'Profil Dosen',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: dosenProfileNavyMedium),
          ),
        ),
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: _primaryColor),
              )
            : errorMessage != null
            ? _ProfileErrorState(message: errorMessage!, onRetry: onRetry)
            : profile == null
            ? _ProfileErrorState(
                message: 'Data profil tidak tersedia.',
                onRetry: onRetry,
              )
            : _ProfileDetails(
                profile: profile!,
                onAction: onAction,
                onRetry: onRetry,
              ),
      ),
    );
  }
}

class _ProfileDetails extends StatefulWidget {
  const _ProfileDetails({
    required this.profile,
    required this.onAction,
    required this.onRetry,
  });

  final DosenProfileData profile;
  final ValueChanged<String> onAction;
  final Future<void> Function()? onRetry;

  @override
  State<_ProfileDetails> createState() => _ProfileDetailsState();
}

class _ProfileDetailsState extends State<_ProfileDetails> {
  late DosenProfileData _profile;
  bool _attendanceNotifications = true;
  bool _announcementNotifications = true;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
  }

  @override
  void didUpdateWidget(covariant _ProfileDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile) {
      _profile = widget.profile;
    }
  }

  Future<void> _handleAction(String action) async {
    switch (action) {
      case 'edit_profile':
        await _showEditProfile();
      case 'account_settings':
        await _showNotificationSettings();
      case 'help':
        await _showHelp();
      case 'logout':
        final shouldLogout = await _confirmLogout();
        if (shouldLogout && mounted) widget.onAction(action);
      default:
        widget.onAction(action);
    }
  }

  Future<bool> _confirmLogout() async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Keluar dari akun?'),
            content: const Text(
              'Anda perlu masuk kembali untuk mengakses profil.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Keluar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _showEditProfile() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: _profile.name);
    final emailController = TextEditingController(text: _profile.email);
    final phoneController = TextEditingController(text: _profile.phone ?? '');

    final updatedProfile = await showDialog<DosenProfileData>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit profil'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nama lengkap',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().length < 3) {
                        return 'Nama minimal 3 karakter.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email institusi',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                          .hasMatch(email)) {
                        return 'Masukkan alamat email yang valid.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Nomor telepon (opsional)',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (value) {
                      final phone = value?.trim() ?? '';
                      if (phone.isEmpty) return null;
                      final digits = phone.replaceAll(RegExp(r'\D'), '');
                      if (digits.length < 8 || digits.length > 15) {
                        return 'Nomor telepon harus memiliki 8–15 digit.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Perubahan hanya berlaku sementara di tampilan ini dan '
                    'belum tersimpan ke server.',
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _primaryColor),
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(
                dialogContext,
                _updatedProfile(
                  current: _profile,
                  name: nameController.text.trim(),
                  email: emailController.text.trim(),
                  phone: phoneController.text.trim(),
                ),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();

    if (updatedProfile == null || !mounted) return;
    setState(() => _profile = updatedProfile);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: dosenProfileNavy,
        content: Text(
          'Perubahan ditampilkan sementara dan belum tersimpan ke server.',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _showNotificationSettings() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Pengaturan notifikasi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: _primaryColor,
                title: const Text('Informasi absensi'),
                subtitle: const Text('Pengingat terkait kegiatan perkuliahan'),
                value: _attendanceNotifications,
                onChanged: (value) {
                  setDialogState(() => _attendanceNotifications = value);
                  setState(() => _attendanceNotifications = value);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: _primaryColor,
                title: const Text('Pengumuman akademik'),
                subtitle: const Text('Informasi dan pengumuman kampus'),
                value: _announcementNotifications,
                onChanged: (value) {
                  setDialogState(() => _announcementNotifications = value);
                  setState(() => _announcementNotifications = value);
                },
              ),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pilihan ini hanya berlaku sementara dan tidak tersimpan '
                  'secara permanen.',
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _primaryColor),
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Selesai'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showHelp() {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.support_agent_rounded, color: _primaryColor),
        title: const Text('Bantuan dosen'),
        content: const Text(
          'Untuk kendala akses akun, data akademik, absensi, atau nilai, '
          'silakan hubungi administrator akademik di kampus. Jangan '
          'membagikan kata sandi kepada siapa pun.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: _primaryColor,
      onRefresh: () async {
        final retry = widget.onRetry;
        if (retry != null) await retry();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          _ProfileHero(profile: _profile),
          const SizedBox(height: 28),
          const _SectionHeading(
            title: 'Identitas Akademik',
            subtitle: 'Program studi dan afiliasi institusi',
          ),
          const SizedBox(height: 12),
          _AcademicInformation(profile: _profile),
          const SizedBox(height: 28),
          const _SectionHeading(
            title: 'Pengaturan',
            subtitle: 'Kelola profil, notifikasi, dan akses akun',
          ),
          const SizedBox(height: 12),
          _ProfileSettings(onAction: _handleAction),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'EduTrack Campus',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.profile});

  final DosenProfileData profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryColor, _accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _ProfileAvatar(photoUrl: profile.photoUrl),
          const SizedBox(height: 16),
          Text(
            profile.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              height: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (profile.academicPosition != null) ...[
            const SizedBox(height: 6),
            Text(
              profile.academicPosition!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.84),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 14),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                profile.accountStatus ??
                    (profile.role == 'dosen' ? 'Dosen' : 'Tenaga Pendidik'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final image = photoUrl == null
        ? null
        : Image.network(
            photoUrl!,
            width: 84,
            height: 84,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _placeholder(),
          );

    return Container(
      width: 92,
      height: 92,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
      ),
      child: ClipOval(
        child:
            image ??
            Container(
              color: Colors.white.withValues(alpha: 0.16),
              child: _placeholder(),
            ),
      ),
    );
  }

  Widget _placeholder() {
    return const ColoredBox(
      color: _softColor,
      child: Icon(Icons.person_rounded, color: _primaryColor, size: 46),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(color: _textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _AcademicInformation extends StatelessWidget {
  const _AcademicInformation({required this.profile});

  final DosenProfileData profile;

  @override
  Widget build(BuildContext context) {
    final rows = <_ProfileInfoItem>[
      const _ProfileInfoItem(
        icon: Icons.menu_book_outlined,
        label: 'Program studi',
        value: _programStudy,
      ),
      const _ProfileInfoItem(
        icon: Icons.account_balance_outlined,
        label: 'Jurusan',
        value: _department,
      ),
      const _ProfileInfoItem(
        icon: Icons.school_outlined,
        label: 'Perguruan tinggi',
        value: _university,
      ),
      _ProfileInfoItem(
        icon: Icons.badge_outlined,
        label: 'NIDN / NIDK',
        value: profile.nidn ?? profile.nidk ?? 'Belum tersedia',
      ),
      if (profile.academicPosition != null)
        _ProfileInfoItem(
          icon: Icons.workspace_premium_outlined,
          label: 'Jabatan akademik',
          value: profile.academicPosition!,
        ),
      _ProfileInfoItem(
        icon: Icons.mail_outline_rounded,
        label: 'Email institusi',
        value: profile.email,
      ),
      _ProfileInfoItem(
        icon: Icons.phone_outlined,
        label: 'Nomor telepon',
        value: profile.phone ?? 'Belum tersedia',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            _ProfileInfoRow(item: rows[index]),
            if (index != rows.length - 1)
              const Divider(
                height: 1,
                indent: 64,
                endIndent: 16,
                color: _borderColor,
              ),
          ],
        ],
      ),
    );
  }
}

class _ProfileInfoItem {
  const _ProfileInfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({required this.item});

  final _ProfileInfoItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _softColor,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(item.icon, size: 19, color: _primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.value,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 14,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
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

class _ProfileSettings extends StatelessWidget {
  const _ProfileSettings({required this.onAction});

  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.edit_outlined,
            title: 'Edit profil',
            onTap: () => onAction('edit_profile'),
          ),
          const _SettingsDivider(),
          _SettingsTile(
            icon: Icons.lock_outline_rounded,
            title: 'Ubah kata sandi',
            onTap: () => onAction('change_password'),
          ),
          const _SettingsDivider(),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Pengaturan notifikasi',
            onTap: () => onAction('account_settings'),
          ),
          const _SettingsDivider(),
          _SettingsTile(
            icon: Icons.help_outline_rounded,
            title: 'Bantuan',
            onTap: () => onAction('help'),
          ),
          const _SettingsDivider(),
          _SettingsTile(
            icon: Icons.logout_rounded,
            title: 'Keluar',
            color: _dangerColor,
            showChevron: false,
            onTap: () => onAction('logout'),
          ),
        ],
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: 56,
      endIndent: 16,
      color: _borderColor,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color = _textPrimary,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color color;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
      leading: Icon(icon, color: color, size: 21),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: showChevron
          ? const Icon(Icons.chevron_right_rounded, color: _textSecondary)
          : null,
      onTap: onTap,
    );
  }
}

class _ProfileErrorState extends StatelessWidget {
  const _ProfileErrorState({required this.message, this.onRetry});

  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: _textSecondary,
              size: 42,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textSecondary, height: 1.4),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba lagi'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryColor,
                  side: const BorderSide(color: _primaryColor),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
