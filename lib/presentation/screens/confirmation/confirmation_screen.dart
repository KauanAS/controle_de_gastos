import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:controle_de_gastos/core/routes/app_router.dart';
import 'package:controle_de_gastos/core/utils/currency_formatter.dart';
import 'package:controle_de_gastos/core/utils/date_formatter.dart';
import 'package:controle_de_gastos/domain/entities/expense_entity.dart';
import 'package:controle_de_gastos/domain/enums/category_enum.dart';
import 'package:controle_de_gastos/domain/enums/payment_method_enum.dart';
import 'package:controle_de_gastos/domain/enums/sync_status_enum.dart';
import 'package:controle_de_gastos/presentation/notifiers/new_entry_notifier.dart';

class ConfirmationScreen extends ConsumerStatefulWidget {
  final ExpenseEntity expense;

  const ConfirmationScreen({super.key, required this.expense});

  @override
  ConsumerState<ConfirmationScreen> createState() =>
      _ConfirmationScreenState();
}

class _ConfirmationScreenState extends ConsumerState<ConfirmationScreen> {
  late ExpenseEntity _expense;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    _expense = widget.expense;
  }

  void _confirm() async {
    setState(() => _confirmed = true);
    await ref.read(newEntryProvider.notifier).confirmExpense(_expense);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(newEntryProvider);

    // Navega para home após salvar com sucesso
    ref.listen(newEntryProvider, (prev, next) {
      if (prev?.status != NewEntryStatus.success &&
          next.status == NewEntryStatus.success) {
        final String message;
        final Color bg;
        if (next.syncSuccess) {
          message = 'Lançamento salvo. Sincronizado com sucesso!';
          bg = colorScheme.primary;
        } else if (next.errorMessage != null) {
          message = 'Salvo localmente. Falha ao enviar: ${next.errorMessage}';
          bg = colorScheme.error;
        } else {
          message = 'Salvo localmente. Sincronização pendente.';
          bg = Colors.orange;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: bg,
            duration: const Duration(seconds: 6),
          ),
        );

        // Reset antes de navegar para evitar reentrada
        ref.read(newEntryProvider.notifier).reset();
        // go limpa a pilha inteira e volta para home
        context.go(AppRoutes.home);
      }
    });

    final isSaving = state.status == NewEntryStatus.saving || _confirmed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar gasto'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: isSaving
              ? null
              : () {
                  if (context.canPop()) context.pop();
                },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Texto original ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Frase original',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '"${_expense.originalText}"',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Campos editáveis ───────────────────────────────────────
            Text(
              'Dados interpretados',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            // Valor
            _FieldCard(
              label: 'Valor',
              value: CurrencyFormatter.format(_expense.amount),
              icon: Icons.attach_money,
              onEdit: () => _editAmount(context),
            ),
            const SizedBox(height: 8),

            // Categoria
            _FieldCard(
              label: 'Categoria',
              value:
                  '${_expense.category.icon}  ${_expense.category.displayName}',
              icon: Icons.category_outlined,
              onEdit: () => _editCategory(context),
            ),
            const SizedBox(height: 8),

            // Forma de pagamento
            _FieldCard(
              label: 'Pagamento',
              value:
                  '${_expense.paymentMethod.icon}  ${_expense.paymentMethod.displayName}',
              icon: Icons.payment_outlined,
              onEdit: () => _editPayment(context),
            ),
            const SizedBox(height: 8),

            // Data
            _FieldCard(
              label: 'Data e hora',
              value: DateFormatter.formatDateTime(_expense.dateTime),
              icon: Icons.calendar_today_outlined,
              onEdit: null, // data automática no MVP
            ),

            const SizedBox(height: 24),

            // ── Indicador de sync inicial ──────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(SyncStatus.pending.icon,
                    size: 14, color: SyncStatus.pending.color),
                const SizedBox(width: 6),
                Text(
                  'Será enviado ao servidor após confirmar',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Botões ─────────────────────────────────────────────────
            FilledButton.icon(
              onPressed: isSaving ? null : _confirm,
              icon: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(isSaving ? 'Salvando...' : 'Confirmar'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: isSaving
                  ? null
                  : () {
                      if (context.canPop()) context.pop();
                    },
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Diálogos de edição ─────────────────────────────────────────────────

  Future<void> _editAmount(BuildContext context) async {
    final controller = TextEditingController(
      text: _expense.amount.toStringAsFixed(2).replaceAll('.', ','),
    );
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar valor'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: 'R\$ '),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('OK')),
        ],
      ),
    );
    if (result != null) {
      final value = double.tryParse(result.replaceAll(',', '.'));
      if (value != null && value > 0) {
        setState(() => _expense = _expense.copyWith(amount: value));
      }
    }
  }

  Future<void> _editCategory(BuildContext context) async {
    final result = await showDialog<CategoryEnum>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Escolher categoria'),
        children: CategoryEnum.values.map((c) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, c),
            child: Row(
              children: [
                Text(c.icon),
                const SizedBox(width: 10),
                Text(c.displayName),
              ],
            ),
          );
        }).toList(),
      ),
    );
    if (result != null) {
      setState(() => _expense = _expense.copyWith(category: result));
    }
  }

  Future<void> _editPayment(BuildContext context) async {
    final result = await showDialog<PaymentMethod>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Forma de pagamento'),
        children: PaymentMethod.values.map((p) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, p),
            child: Row(
              children: [
                Text(p.icon),
                const SizedBox(width: 10),
                Text(p.displayName),
              ],
            ),
          );
        }).toList(),
      ),
    );
    if (result != null) {
      setState(() => _expense = _expense.copyWith(paymentMethod: result));
    }
  }
}

class _FieldCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onEdit;

  const _FieldCard({
    required this.label,
    required this.value,
    required this.icon,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 2),
                  Text(value, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            if (onEdit != null)
              IconButton(
                icon: Icon(Icons.edit_outlined,
                    size: 18, color: colorScheme.primary),
                onPressed: onEdit,
                tooltip: 'Editar',
              ),
          ],
        ),
      ),
    );
  }
}