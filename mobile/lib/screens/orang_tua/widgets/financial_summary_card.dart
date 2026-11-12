import 'package:flutter/material.dart';

import '../../../data/orang_tua_preview_data.dart';
import 'orang_tua_theme.dart';
import 'parent_formatters.dart';
import 'parent_card.dart';

class FinancialSummaryCard extends StatelessWidget {
  const FinancialSummaryCard({
    super.key,
    required this.financial,
    required this.isDemo,
    required this.onTap,
  });

  final FinancialOverview? financial;
  final bool isDemo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ParentCard(
    padding: EdgeInsets.zero,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: financial == null || financial!.activeSemester == null
            ? const _NoFinancialData()
            : _FinancialDetails(financial: financial!, isDemo: isDemo),
      ),
    ),
  );
}

class _NoFinancialData extends StatelessWidget {
  const _NoFinancialData();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      _IconBox(icon: Icons.account_balance_wallet_outlined),
      SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informasi UKT',
              style: TextStyle(
                color: OrangTuaColors.forest,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Belum ada data pembayaran yang tersedia.',
              style: TextStyle(color: OrangTuaColors.muted, fontSize: 11),
            ),
          ],
        ),
      ),
      Icon(Icons.chevron_right_rounded, color: OrangTuaColors.muted),
    ],
  );
}

class _FinancialDetails extends StatelessWidget {
  const _FinancialDetails({required this.financial, required this.isDemo});

  final FinancialOverview financial;
  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    final semester = financial.activeSemester!;
    final isPaid = semester.paymentStatus == TuitionPaymentStatus.paid;
    final reductionApproved =
        semester.reductionStatus == TuitionReductionStatus.approved;
    final statusColor = isPaid
        ? OrangTuaColors.emeraldDark
        : const Color(0xFF9A5148);
    final statusBackground = isPaid
        ? OrangTuaColors.paleGreen
        : const Color(0xFFF9EAE6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _IconBox(icon: Icons.account_balance_wallet_outlined),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'UKT semester berjalan',
                    style: TextStyle(
                      color: OrangTuaColors.forest,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${semester.academicTerm}${isDemo ? ' · DEMO' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: OrangTuaColors.muted,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: statusBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isPaid ? 'LUNAS' : 'BELUM LUNAS',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: OrangTuaColors.paleGreen,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'UKT FINAL YANG WAJIB DIBAYAR',
                style: TextStyle(
                  color: OrangTuaColors.emeraldDark,
                  fontSize: 8,
                  letterSpacing: .45,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatRupiah(semester.finalAmount),
                style: const TextStyle(
                  color: OrangTuaColors.forest,
                  fontSize: 22,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              _AmountRow(
                label: 'UKT awal',
                value: formatRupiah(semester.initialAmount),
              ),
              const SizedBox(height: 4),
              _AmountRow(
                label: 'Keringanan disetujui',
                value: reductionApproved
                    ? '− ${formatRupiah(semester.approvedReductionAmount)}'
                    : 'Tidak ada',
                highlight: reductionApproved,
              ),
            ],
          ),
        ),
        if (semester.reductionStatus != TuitionReductionStatus.approved) ...[
          const SizedBox(height: 7),
          Text(
            _reductionStatusMessage(semester.reductionStatus),
            style: const TextStyle(color: OrangTuaColors.muted, fontSize: 9),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SummaryCount(
                label: 'Lunas',
                count: financial.paidSemesterCount,
                color: OrangTuaColors.emeraldDark,
              ),
            ),
            Expanded(
              child: _SummaryCount(
                label: 'Belum lunas',
                count: financial.unpaidSemesterCount,
                color: const Color(0xFF9A5148),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Total kewajiban belum dibayar',
                style: TextStyle(
                  color: OrangTuaColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              formatRupiah(financial.outstandingAmount),
              style: const TextStyle(
                color: OrangTuaColors.forest,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(height: 1, color: OrangTuaColors.border),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Lihat riwayat UKT',
              style: TextStyle(
                color: OrangTuaColors.emeraldDark,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(width: 2),
            Icon(
              Icons.chevron_right_rounded,
              color: OrangTuaColors.emeraldDark,
              size: 17,
            ),
          ],
        ),
      ],
    );
  }

  String _reductionStatusMessage(TuitionReductionStatus status) =>
      switch (status) {
        TuitionReductionStatus.notApplied => 'Belum mengajukan keringanan.',
        TuitionReductionStatus.processing =>
          'Pengajuan diproses; belum mengurangi UKT.',
        TuitionReductionStatus.rejected =>
          'Pengajuan ditolak; UKT awal tetap berlaku.',
        TuitionReductionStatus.approved => 'Keringanan telah disetujui.',
      };
}

class _SummaryCount extends StatelessWidget {
  const _SummaryCount({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(Icons.circle, color: color, size: 7),
      const SizedBox(width: 5),
      Text(
        '$count $label',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
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
            fontSize: 9,
            fontWeight: highlight ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
      Text(
        value,
        style: TextStyle(
          color: highlight ? OrangTuaColors.emeraldDark : OrangTuaColors.forest,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 38,
    height: 38,
    decoration: BoxDecoration(
      color: OrangTuaColors.paleGreen,
      borderRadius: BorderRadius.circular(13),
    ),
    child: Icon(icon, color: OrangTuaColors.emeraldDark, size: 20),
  );
}
