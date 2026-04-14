import 'package:flutter/material.dart';
import 'package:controle_de_gastos/domain/entities/expense_entity.dart';
import 'package:controle_de_gastos/domain/enums/category_enum.dart';
import 'package:controle_de_gastos/domain/enums/payment_method_enum.dart';
import 'package:controle_de_gastos/domain/enums/sync_status_enum.dart';
import 'package:controle_de_gastos/core/utils/currency_formatter.dart';
import 'package:controle_de_gastos/core/utils/date_formatter.dart';
import 'package:controle_de_gastos/presentation/widgets/sync_status_badge.dart';

class ExpenseListTile extends StatelessWidget {
  final ExpenseEntity expense;
  final VoidCallback? onRetrySync;
  final VoidCallback? onDelete;
  final bool isRetrying;

  const ExpenseListTile({
    super.key,
    required this.expense,
    this.onRetrySync,
    this.onDelete,
    this.isRetrying = false,
  });

  // ── Helpers internos (não dependem de extension) ───────────────────────

  static String _categoryIcon(CategoryEnum c) {
    switch (c) {
      case CategoryEnum.alimentacao: return '🍽️';
      case CategoryEnum.mercado:     return '🛒';
      case CategoryEnum.gasolina:    return '⛽';
      case CategoryEnum.transporte:  return '🚌';
      case CategoryEnum.lazer:       return '🎬';
      case CategoryEnum.assinaturas: return '📱';
      case CategoryEnum.saude:       return '🏥';
      case CategoryEnum.educacao:    return '📚';
      case CategoryEnum.moradia:     return '🏠';
      case CategoryEnum.outros:      return '📦';
    }
  }

  static String _categoryName(CategoryEnum c) {
    switch (c) {
      case CategoryEnum.alimentacao: return 'Alimentação';
      case CategoryEnum.mercado:     return 'Mercado';
      case CategoryEnum.gasolina:    return 'Gasolina';
      case CategoryEnum.transporte:  return 'Transporte';
      case CategoryEnum.lazer:       return 'Lazer';
      case CategoryEnum.assinaturas: return 'Assinaturas';
      case CategoryEnum.saude:       return 'Saúde';
      case CategoryEnum.educacao:    return 'Educação';
      case CategoryEnum.moradia:     return 'Moradia';
      case CategoryEnum.outros:      return 'Outros';
    }
  }

  static String _paymentName(PaymentMethod p) {
    switch (p) {
      case PaymentMethod.pix:      return 'Pix';
      case PaymentMethod.dinheiro: return 'Dinheiro';
      case PaymentMethod.debito:   return 'Débito';
      case PaymentMethod.credito:  return 'Crédito';
      case PaymentMethod.boleto:   return 'Boleto';
      case PaymentMethod.outro:    return 'Outro';
    }
  }

  static Color _syncColor(SyncStatus s) {
    switch (s) {
      case SyncStatus.pending: return const Color(0xFFF59E0B);
      case SyncStatus.synced:  return const Color(0xFF10B981);
      case SyncStatus.failed:  return const Color(0xFFEF4444);
    }
  }

  static IconData _syncIcon(SyncStatus s) {
    switch (s) {
      case SyncStatus.pending: return Icons.cloud_upload_outlined;
      case SyncStatus.synced:  return Icons.cloud_done_outlined;
      case SyncStatus.failed:  return Icons.cloud_off_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canRetry = expense.syncStatus == SyncStatus.failed ||
        expense.syncStatus == SyncStatus.pending;

    final tile = Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Ícone da categoria
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  _categoryIcon(expense.category),
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Categoria + data + pagamento
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          expense.originalText,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _syncIcon(expense.syncStatus),
                        size: 14,
                        color: _syncColor(expense.syncStatus),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_categoryName(expense.category)} · ${DateFormatter.formatRelative(expense.dateTime)} · ${_paymentName(expense.paymentMethod)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Valor + botão retry
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(expense.amount),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
                if (canRetry && onRetrySync != null) ...[
                  const SizedBox(height: 4),
                  if (isRetrying)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    GestureDetector(
                      onTap: onRetrySync,
                      child: Text(
                        'Reenviar',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );

    // Swipe para deletar (só aparece quando onDelete é fornecido)
    if (onDelete != null) {
      return Dismissible(
        key: ValueKey(expense.id),
        direction: DismissDirection.endToStart,
        background: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: Icon(
            Icons.delete_outline,
            color: colorScheme.onErrorContainer,
            size: 26,
          ),
        ),
        confirmDismiss: (_) async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Excluir lançamento'),
              content: const Text(
                'Tem certeza que deseja excluir este lançamento? '
                'Esta ação não pode ser desfeita.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Excluir'),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            onDelete!();
          }
          return confirmed == true;
        },
        child: tile,
      );
    }

    return tile;
  }
}
