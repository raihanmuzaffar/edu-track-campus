import 'package:flutter/material.dart';

import '../../data/orang_tua_preview_data.dart';
import 'widgets/empty_state.dart';
import 'widgets/orang_tua_theme.dart';
import 'widgets/parent_card.dart';
import 'widgets/parent_formatters.dart';
import 'widgets/section_header.dart';

class KeuanganTab extends StatelessWidget {
  const KeuanganTab({super.key, required this.data});

  final OrangTuaDashboardData data;

  @override
  Widget build(BuildContext context) {
    final financial = data.financial;
    final activeSemester = financial?.activeSemester;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      children: [
        SectionHeader(
          title: 'Keuangan & UKT',
          subtitle: 'Lihat UKT final, status pembayaran, dan riwayat semester.',
          isDemo: data.isDemo,
        ),
        if (financial == null || activeSemester == null)
          const EmptyState(
            title: 'Informasi UKT belum tersedia',
            message:
                'Rincian UKT per semester akan tampil ketika data tersedia. '
                'Belum ada informasi pembayaran yang dapat ditampilkan.',
            icon: Icons.account_balance_wallet_outlined,
          )
        else ...[
          if (data.isDemo) ...[const _DemoNotice(), const SizedBox(height: 13)],
          _ActiveSemesterCard(semester: activeSemester, isDemo: data.isDemo),
          if (data.isDemo) ...[
            const SizedBox(height: 10),
            const _OtherReductionExample(),
          ],
          if (_shouldShowDueNotice(activeSemester)) ...[
            const SizedBox(height: 11),
            _DueNotice(dueDate: activeSemester.dueDate!),
          ],
          const SizedBox(height: 13),
          _OverallSummary(financial: financial),
          const SizedBox(height: 22),
          const _SectionTitle(
            title: 'Riwayat UKT per semester',
            subtitle: 'Urut dari semester pertama hingga yang terbaru.',
          ),
          const SizedBox(height: 11),
          ...financial.semesterRecords.map(
            (record) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SemesterHistoryCard(
                semester: record,
                isActive: record.id == financial.activeSemesterId,
              ),
            ),
          ),
          if (data.isDemo) ...[
            const SizedBox(height: 4),
            const Text(
              'Semua nominal, status, dan tanggal pada halaman ini adalah '
              'ilustrasi DEMO, bukan data pembayaran nyata. UKT dibayar lunas '
              'satu kali per semester; aplikasi ini tidak memproses pembayaran.',
              style: TextStyle(
                color: OrangTuaColors.muted,
                fontSize: 11,
                height: 1.55,
              ),
            ),
          ],
        ],
      ],
    );
  }

  bool _shouldShowDueNotice(TuitionSemesterRecord semester) {
    final dueDate = semester.dueDate;
    if (dueDate == null ||
        semester.paymentStatus == TuitionPaymentStatus.paid) {
      return false;
    }
    final today = DateTime.now();
    final remainingDays = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
    ).difference(DateTime(today.year, today.month, today.day)).inDays;
    return remainingDays >= 0 && remainingDays <= 14;
  }
}

class _DemoNotice extends StatelessWidget {
  const _DemoNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: OrangTuaColors.paleOrange,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, color: Color(0xFF9A5728), size: 19),
        SizedBox(width: 9),
        Expanded(
          child: Text(
            'MODE DEMO — informasi UKT, keringanan, dan pembayaran hanya data '
            'contoh. Tidak ada transaksi yang dilakukan.',
            style: TextStyle(
              color: Color(0xFF80552F),
              fontSize: 11,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _OtherReductionExample extends StatelessWidget {
  const _OtherReductionExample();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: OrangTuaColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: OrangTuaColors.border),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.lightbulb_outline_rounded,
          color: OrangTuaColors.orange,
          size: 19,
        ),
        SizedBox(width: 9),
        Expanded(
          child: Text(
            'Contoh DEMO lain: jika keringanan Rp3.000.000 disetujui dari '
            'UKT awal Rp3.500.000, UKT final menjadi Rp500.000. Ini hanya '
            'ilustrasi, bukan riwayat atau pengajuan mahasiswa.',
            style: TextStyle(
              color: OrangTuaColors.forest,
              fontSize: 10,
              height: 1.45,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ActiveSemesterCard extends StatelessWidget {
  const _ActiveSemesterCard({required this.semester, required this.isDemo});

  final TuitionSemesterRecord semester;
  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    final isPaid = semester.paymentStatus == TuitionPaymentStatus.paid;
    final reductionApproved =
        semester.reductionStatus == TuitionReductionStatus.approved;

    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [OrangTuaColors.emeraldDark, OrangTuaColors.emerald],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: OrangTuaColors.emeraldDark.withValues(alpha: .18),
            blurRadius: 19,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'UKT SEMESTER BERJALAN',
                  style: TextStyle(
                    color: Color(0xFFD8EEE4),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .9,
                  ),
                ),
              ),
              _PaymentStatusBadge(isPaid: isPaid, prominent: true),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            semester.academicTerm,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 17),
          const Text(
            'UKT FINAL YANG WAJIB DIBAYAR',
            style: TextStyle(
              color: Color(0xFFD8EEE4),
              fontSize: 9,
              letterSpacing: .6,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatRupiah(semester.finalAmount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              height: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isPaid
                ? 'Kewajiban semester ini sudah dibayar lunas.'
                : 'Nominal yang masih harus dibayar semester ini.',
            style: const TextStyle(color: Color(0xFFDCEDE5), fontSize: 11),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: .12)),
            ),
            child: Column(
              children: [
                _HeroAmountRow(
                  label: 'UKT awal',
                  value: formatRupiah(semester.initialAmount),
                ),
                const SizedBox(height: 8),
                _HeroAmountRow(
                  label: 'Keringanan disetujui',
                  value: reductionApproved
                      ? '− ${formatRupiah(semester.approvedReductionAmount)}'
                      : 'Belum ada',
                  highlight: reductionApproved,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 9),
                  child: Divider(height: 1, color: Color(0x44FFFFFF)),
                ),
                _HeroAmountRow(
                  label: 'UKT final',
                  value: formatRupiah(semester.finalAmount),
                  bold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _ReductionMessage(semester: semester, isDark: true),
          if (semester.dueDate != null || semester.billNumber != null) ...[
            const SizedBox(height: 11),
            const Divider(height: 1, color: Color(0x44FFFFFF)),
            const SizedBox(height: 9),
            if (semester.billNumber != null)
              _HeroSmallDetail(
                label: 'Nomor tagihan',
                value: semester.billNumber!,
              ),
            if (semester.billNumber != null && semester.dueDate != null)
              const SizedBox(height: 6),
            if (semester.dueDate != null)
              _HeroSmallDetail(
                label: 'Jatuh tempo',
                value: formatParentDate(semester.dueDate!),
              ),
          ],
          if (isDemo) ...[
            const SizedBox(height: 11),
            const Text(
              'Ilustrasi DEMO · bukan catatan pembayaran nyata',
              style: TextStyle(
                color: Color(0xFFDCEDE5),
                fontSize: 9,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroAmountRow extends StatelessWidget {
  const _HeroAmountRow({
    required this.label,
    required this.value,
    this.highlight = false,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool highlight;
  final bool bold;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            color: highlight
                ? const Color(0xFFFFD3A5)
                : const Color(0xFFE1F0E9),
            fontSize: 10,
            fontWeight: bold || highlight ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
      Text(
        value,
        style: TextStyle(
          color: highlight ? const Color(0xFFFFD3A5) : Colors.white,
          fontSize: bold ? 12 : 10,
          fontWeight: bold || highlight ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    ],
  );
}

class _HeroSmallDetail extends StatelessWidget {
  const _HeroSmallDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(color: Color(0xFFD8EEE4), fontSize: 9),
        ),
      ),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _ReductionMessage extends StatelessWidget {
  const _ReductionMessage({required this.semester, required this.isDark});

  final TuitionSemesterRecord semester;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final status = semester.reductionStatus;
    final (label, icon, color) = switch (status) {
      TuitionReductionStatus.notApplied => (
        'Belum mengajukan keringanan UKT.',
        Icons.info_outline_rounded,
        OrangTuaColors.muted,
      ),
      TuitionReductionStatus.processing => (
        'Pengajuan ${formatRupiah(semester.reductionAmount)} sedang diproses. '
            'UKT awal tetap menjadi acuan.',
        Icons.hourglass_top_rounded,
        const Color(0xFF9A672E),
      ),
      TuitionReductionStatus.approved => (
        'Keringanan disetujui: ${formatRupiah(semester.approvedReductionAmount)}.',
        Icons.check_circle_outline_rounded,
        OrangTuaColors.emeraldDark,
      ),
      TuitionReductionStatus.rejected => (
        'Pengajuan penurunan UKT ditolak. UKT awal tetap menjadi acuan.',
        Icons.cancel_outlined,
        const Color(0xFF9A5148),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: .1)
            : color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: isDark ? const Color(0xFFFFD3A5) : color, size: 15),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white : color,
                fontSize: 10,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverallSummary extends StatelessWidget {
  const _OverallSummary({required this.financial});

  final FinancialOverview financial;

  @override
  Widget build(BuildContext context) => ParentCard(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ringkasan semua semester',
          style: TextStyle(
            color: OrangTuaColors.forest,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _CountMetric(
                label: 'Sudah lunas',
                count: financial.paidSemesterCount,
                icon: Icons.check_circle_outline_rounded,
                color: OrangTuaColors.emerald,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _CountMetric(
                label: 'Belum lunas',
                count: financial.unpaidSemesterCount,
                icon: Icons.error_outline_rounded,
                color: const Color(0xFFBD6C63),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: OrangTuaColors.paleOrange,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: Color(0xFF9A5728),
                size: 20,
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Total UKT yang belum dibayar',
                  style: TextStyle(
                    color: OrangTuaColors.forest,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                formatRupiah(financial.outstandingAmount),
                style: const TextStyle(
                  color: OrangTuaColors.forest,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Total dihitung dari UKT final semester yang belum lunas. '
          'Pengajuan yang masih diproses tidak mengurangi tagihan.',
          style: TextStyle(
            color: OrangTuaColors.muted,
            fontSize: 10,
            height: 1.45,
          ),
        ),
      ],
    ),
  );
}

class _CountMetric extends StatelessWidget {
  const _CountMetric({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count semester',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: OrangTuaColors.muted,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DueNotice extends StatelessWidget {
  const _DueNotice({required this.dueDate});

  final DateTime dueDate;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysLeft = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
    final message = daysLeft == 0
        ? 'UKT semester berjalan jatuh tempo hari ini.'
        : 'Tanggal jatuh tempo UKT ${daysLeft == 1 ? 'besok' : 'dalam $daysLeft hari'}.';

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: OrangTuaColors.paleOrange,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OrangTuaColors.orange.withValues(alpha: .25)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_active_outlined,
            color: Color(0xFF9A5728),
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF80552F),
                fontSize: 11,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: OrangTuaColors.forest,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        subtitle,
        style: const TextStyle(color: OrangTuaColors.muted, fontSize: 11),
      ),
    ],
  );
}

class _SemesterHistoryCard extends StatelessWidget {
  const _SemesterHistoryCard({required this.semester, required this.isActive});

  final TuitionSemesterRecord semester;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final isPaid = semester.paymentStatus == TuitionPaymentStatus.paid;
    final hasReduction =
        semester.reductionStatus == TuitionReductionStatus.approved;

    return ParentCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isPaid
                      ? OrangTuaColors.paleGreen
                      : const Color(0xFFF9EAE6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isPaid
                      ? Icons.check_circle_outline_rounded
                      : Icons.receipt_long_outlined,
                  color: isPaid
                      ? OrangTuaColors.emeraldDark
                      : const Color(0xFF9A5148),
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      semester.academicTerm,
                      style: const TextStyle(
                        color: OrangTuaColors.forest,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(height: 3),
                      const Text(
                        'SEMESTER BERJALAN',
                        style: TextStyle(
                          color: OrangTuaColors.emerald,
                          fontSize: 8,
                          letterSpacing: .6,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 5),
              _PaymentStatusBadge(isPaid: isPaid),
            ],
          ),
          const SizedBox(height: 13),
          const Divider(height: 1, color: OrangTuaColors.border),
          const SizedBox(height: 11),
          _HistoryAmountRow(
            label: 'UKT awal',
            value: formatRupiah(semester.initialAmount),
          ),
          if (hasReduction) ...[
            const SizedBox(height: 7),
            _HistoryAmountRow(
              label: 'Keringanan disetujui',
              value: '− ${formatRupiah(semester.approvedReductionAmount)}',
              highlight: true,
            ),
          ],
          const SizedBox(height: 9),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
            decoration: BoxDecoration(
              color: OrangTuaColors.paleGreen,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'UKT FINAL',
                    style: TextStyle(
                      color: OrangTuaColors.emeraldDark,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .5,
                    ),
                  ),
                ),
                Text(
                  formatRupiah(semester.finalAmount),
                  style: const TextStyle(
                    color: OrangTuaColors.emeraldDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          _ReductionMessage(semester: semester, isDark: false),
          if (isPaid) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: OrangTuaColors.border),
            const SizedBox(height: 9),
            _HistoryAmountRow(
              label: 'Tanggal pembayaran',
              value: semester.paymentDate == null
                  ? 'Belum tersedia'
                  : formatParentDate(semester.paymentDate!),
            ),
            const SizedBox(height: 6),
            _HistoryAmountRow(
              label: 'Nominal dibayar',
              value: formatRupiah(semester.paymentAmount),
            ),
          ] else if (semester.billNumber != null ||
              semester.dueDate != null) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: OrangTuaColors.border),
            const SizedBox(height: 9),
            if (semester.billNumber != null)
              _HistoryAmountRow(
                label: 'Nomor tagihan',
                value: semester.billNumber!,
              ),
            if (semester.billNumber != null && semester.dueDate != null)
              const SizedBox(height: 6),
            if (semester.dueDate != null)
              _HistoryAmountRow(
                label: 'Jatuh tempo',
                value: formatParentDate(semester.dueDate!),
              ),
          ],
        ],
      ),
    );
  }
}

class _HistoryAmountRow extends StatelessWidget {
  const _HistoryAmountRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            color: highlight
                ? OrangTuaColors.emeraldDark
                : OrangTuaColors.muted,
            fontSize: 10,
            fontWeight: highlight ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: TextStyle(
            color: highlight
                ? OrangTuaColors.emeraldDark
                : OrangTuaColors.forest,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}

class _PaymentStatusBadge extends StatelessWidget {
  const _PaymentStatusBadge({required this.isPaid, this.prominent = false});

  final bool isPaid;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final foreground = prominent
        ? isPaid
              ? OrangTuaColors.emeraldDark
              : const Color(0xFF9A5148)
        : isPaid
        ? OrangTuaColors.emeraldDark
        : const Color(0xFF9A5148);
    final background = prominent
        ? isPaid
              ? const Color(0xFFE2F2E9)
              : const Color(0xFFFFE7E1)
        : isPaid
        ? OrangTuaColors.paleGreen
        : const Color(0xFFF9EAE6);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: prominent ? 11 : 9,
        vertical: prominent ? 7 : 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        isPaid ? 'LUNAS' : 'BELUM LUNAS',
        style: TextStyle(
          color: foreground,
          fontSize: prominent ? 10 : 9,
          fontWeight: FontWeight.w900,
          letterSpacing: .3,
        ),
      ),
    );
  }
}
