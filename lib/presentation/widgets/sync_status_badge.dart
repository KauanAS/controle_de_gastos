import 'package:flutter/material.dart';
import 'package:controle_de_gastos/domain/enums/sync_status_enum.dart';

class SyncStatusBadge extends StatelessWidget {
  final SyncStatus status;
  final bool showLabel;

  const SyncStatusBadge({
    super.key,
    required this.status,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = status.color;

    if (!showLabel) {
      return Icon(status.icon, size: 16, color: color);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(status.icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          status.displayName,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}