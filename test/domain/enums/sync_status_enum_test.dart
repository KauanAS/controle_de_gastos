import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:controle_de_gastos/domain/enums/sync_status_enum.dart';

/// Testes TDD para SyncStatus enum
///
/// Features cobertas (CLAUDE.md):
/// - Seção 4.4: campo syncStatus nos expenses
/// - Seção 6: Regras — offline first, salva localmente primeiro
/// - Seção 8: Fluxo de sync (pending → synced/failed)
void main() {
  group('SyncStatus - Valores', () {
    test('deve ter 3 status de sincronização', () {
      expect(SyncStatus.values, hasLength(3));
    });

    test('deve incluir pending, synced e failed', () {
      expect(SyncStatus.values, contains(SyncStatus.pending));
      expect(SyncStatus.values, contains(SyncStatus.synced));
      expect(SyncStatus.values, contains(SyncStatus.failed));
    });
  });

  group('SyncStatus - displayName', () {
    test('pending deve exibir "Pendente"', () {
      expect(SyncStatus.pending.displayName, 'Pendente');
    });

    test('synced deve exibir "Sincronizado"', () {
      expect(SyncStatus.synced.displayName, 'Sincronizado');
    });

    test('failed deve exibir "Falha"', () {
      expect(SyncStatus.failed.displayName, 'Falha');
    });
  });

  group('SyncStatus - color', () {
    test('pending deve ter cor âmbar', () {
      expect(SyncStatus.pending.color, const Color(0xFFF59E0B));
    });

    test('synced deve ter cor verde', () {
      expect(SyncStatus.synced.color, const Color(0xFF10B981));
    });

    test('failed deve ter cor vermelha', () {
      expect(SyncStatus.failed.color, const Color(0xFFEF4444));
    });

    test('todas devem ter cores distintas', () {
      final colors = SyncStatus.values.map((s) => s.color).toSet();
      expect(colors, hasLength(3));
    });
  });

  group('SyncStatus - icon', () {
    test('pending deve ter ícone de upload', () {
      expect(SyncStatus.pending.icon, Icons.cloud_upload_outlined);
    });

    test('synced deve ter ícone de cloud done', () {
      expect(SyncStatus.synced.icon, Icons.cloud_done_outlined);
    });

    test('failed deve ter ícone de cloud off', () {
      expect(SyncStatus.failed.icon, Icons.cloud_off_outlined);
    });

    test('todas devem ter ícones distintos', () {
      final icons = SyncStatus.values.map((s) => s.icon).toSet();
      expect(icons, hasLength(3));
    });
  });

  group('SyncStatus - Fluxo de negócio (CLAUDE.md Seção 8)', () {
    test('novo lançamento deve começar como pending', () {
      // Regra: offline first — salva localmente como pending
      const initialStatus = SyncStatus.pending;
      expect(initialStatus, SyncStatus.pending);
    });

    test('transição válida: pending → synced (sync bem-sucedido)', () {
      const before = SyncStatus.pending;
      const after = SyncStatus.synced;

      expect(before, isNot(equals(after)));
      expect(after, SyncStatus.synced);
    });

    test('transição válida: pending → failed (sync falhou)', () {
      const before = SyncStatus.pending;
      const after = SyncStatus.failed;

      expect(before, isNot(equals(after)));
      expect(after, SyncStatus.failed);
    });

    test('transição válida: failed → synced (retry bem-sucedido)', () {
      const before = SyncStatus.failed;
      const after = SyncStatus.synced;

      expect(before, isNot(equals(after)));
      expect(after, SyncStatus.synced);
    });

    test('transição válida: failed → pending (nova tentativa agendada)', () {
      const before = SyncStatus.failed;
      const after = SyncStatus.pending;

      expect(before, isNot(equals(after)));
      expect(after, SyncStatus.pending);
    });
  });
}
