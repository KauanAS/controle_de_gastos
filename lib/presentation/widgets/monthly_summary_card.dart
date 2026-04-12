import 'package:flutter/material.dart';
import 'package:controle_de_gastos/core/utils/currency_formatter.dart';
import 'package:controle_de_gastos/core/utils/date_formatter.dart';
import 'package:controle_de_gastos/presentation/providers/expense_providers.dart';

class MonthlySummaryCard extends StatelessWidget {
  final MonthlySummary summary;

  const MonthlySummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = DateTime.now();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormatter.formatMonthYear(now),
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onPrimary.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(summary.total),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Chip(
                label: '${summary.count} lançamentos',
                icon: Icons.receipt_long_outlined,
                onPrimary: colorScheme.onPrimary,
              ),
              if (summary.pendingSyncCount > 0) ...[
                const SizedBox(width: 8),
                _Chip(
                  label: '${summary.pendingSyncCount} pendente(s)',
                  icon: Icons.cloud_upload_outlined,
                  onPrimary: colorScheme.onPrimary,
                  isWarning: true,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color onPrimary;
  final bool isWarning;

  const _Chip({
    required this.label,
    required this.icon,
    required this.onPrimary,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isWarning
            ? const Color(0xFFF59E0B).withOpacity(0.25)
            : onPrimary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: onPrimary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: onPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}