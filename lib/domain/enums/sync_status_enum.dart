import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'package:controle_de_gastos/core/constants/app_constants.dart';

part 'sync_status_enum.g.dart';

@HiveType(typeId: AppConstants.hiveAdapterSyncStatus)
enum SyncStatus {
  /// Salvo localmente, aguardando envio ao backend.
  @HiveField(0)
  pending,

  /// Enviado e confirmado pelo backend com sucesso.
  @HiveField(1)
  synced,

  /// Tentativa de envio falhou. Aguardando retry.
  @HiveField(2)
  failed,
}

extension SyncStatusExtension on SyncStatus {
  String get displayName {
    switch (this) {
      case SyncStatus.pending:
        return 'Pendente';
      case SyncStatus.synced:
        return 'Sincronizado';
      case SyncStatus.failed:
        return 'Falha';
    }
  }

  Color get color {
    switch (this) {
      case SyncStatus.pending:
        return const Color(0xFFF59E0B); // âmbar
      case SyncStatus.synced:
        return const Color(0xFF10B981); // verde
      case SyncStatus.failed:
        return const Color(0xFFEF4444); // vermelho
    }
  }

  IconData get icon {
    switch (this) {
      case SyncStatus.pending:
        return Icons.cloud_upload_outlined;
      case SyncStatus.synced:
        return Icons.cloud_done_outlined;
      case SyncStatus.failed:
        return Icons.cloud_off_outlined;
    }
  }
}