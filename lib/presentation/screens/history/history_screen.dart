import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:controle_de_gastos/domain/enums/category_enum.dart';
import 'package:controle_de_gastos/domain/enums/sync_status_enum.dart';
import 'package:controle_de_gastos/presentation/notifiers/history_notifier.dart';
import 'package:controle_de_gastos/presentation/widgets/expense_list_tile.dart';
import 'package:controle_de_gastos/presentation/widgets/empty_state_widget.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(historyProvider);
    final notifier = ref.read(historyProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        actions: [
          if (state.filter.hasActiveFilters)
            TextButton.icon(
              onPressed: notifier.clearFilters,
              icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
              label: const Text('Limpar'),
            ),
          IconButton(
            icon: const Icon(Icons.filter_list_outlined),
            tooltip: 'Filtrar',
            onPressed: () => _showFilterSheet(context, ref, state.filter),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: notifier.refresh,
        child: Builder(builder: (context) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.errorMessage != null) {
            return Center(child: Text(state.errorMessage!));
          }

          if (state.expenses.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.receipt_long_outlined,
              title: 'Nenhum lançamento encontrado',
              subtitle: state.filter.hasActiveFilters
                  ? 'Tente remover os filtros.'
                  : 'Adicione seu primeiro gasto.',
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dica de swipe — aparece sempre que houver itens
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.swipe_left_outlined,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      'Deslize para a esquerda para excluir',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: state.expenses.length,
                  itemBuilder: (context, index) {
                    final expense = state.expenses[index];
                    final isRetrying = state.retryingId == expense.id;

                    return ExpenseListTile(
                      expense: expense,
                      isRetrying: isRetrying,
                      onRetrySync: (expense.syncStatus == SyncStatus.failed ||
                              expense.syncStatus == SyncStatus.pending)
                          ? () => notifier.retrySync(expense)
                          : null,
                      // Swipe para deletar: pede confirmação antes de excluir
                      onDelete: () => _confirmDelete(
                        context: context,
                        expenseId: expense.id,
                        notifier: notifier,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  /// Exibe diálogo de confirmação antes de excluir definitivamente.
  void _confirmDelete({
    required BuildContext context,
    required String expenseId,
    required HistoryNotifier notifier,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir lançamento'),
        content: const Text(
          'Tem certeza que deseja excluir este lançamento? '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Recarrega lista para o item voltar (dismissible já o removeu)
              notifier.refresh();
            },
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () {
              Navigator.pop(context);
              notifier.deleteExpense(expenseId);
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(
      BuildContext context, WidgetRef ref, HistoryFilter current) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(current: current, ref: ref),
    );
  }
}

// ─── Bottom sheet de filtros ───────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final HistoryFilter current;
  final WidgetRef ref;

  const _FilterSheet({required this.current, required this.ref});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late int? _selectedMonth;
  late int? _selectedYear;
  late CategoryEnum? _selectedCategory;
  late SyncStatus? _selectedSyncStatus;

  final _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedMonth = widget.current.month;
    _selectedYear = widget.current.year;
    _selectedCategory = widget.current.category;
    _selectedSyncStatus = widget.current.syncStatus;
  }

  static const _months = [
    (1, 'Janeiro'), (2, 'Fevereiro'), (3, 'Março'), (4, 'Abril'),
    (5, 'Maio'), (6, 'Junho'), (7, 'Julho'), (8, 'Agosto'),
    (9, 'Setembro'), (10, 'Outubro'), (11, 'Novembro'), (12, 'Dezembro'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Filtros',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),

          Text('Mês', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _months.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final (num, name) = _months[i];
                final selected = _selectedMonth == num;
                return ChoiceChip(
                  label: Text(name.substring(0, 3)),
                  selected: selected,
                  onSelected: (_) =>
                      setState(() => _selectedMonth = selected ? null : num),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          Text('Categoria', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: CategoryEnum.values.map((c) {
              final selected = _selectedCategory == c;
              return ChoiceChip(
                label: Text('${c.icon} ${c.displayName}'),
                selected: selected,
                onSelected: (_) =>
                    setState(() => _selectedCategory = selected ? null : c),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          Text('Sincronização', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: SyncStatus.values.map((s) {
              final selected = _selectedSyncStatus == s;
              return ChoiceChip(
                label: Text(s.displayName),
                selected: selected,
                selectedColor: s.color.withOpacity(0.2),
                onSelected: (_) =>
                    setState(() => _selectedSyncStatus = selected ? null : s),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          FilledButton(
            onPressed: () {
              widget.ref.read(historyProvider.notifier).applyFilter(
                    HistoryFilter(
                      year: _selectedMonth != null ? _now.year : null,
                      month: _selectedMonth,
                      category: _selectedCategory,
                      syncStatus: _selectedSyncStatus,
                    ),
                  );
              Navigator.pop(context);
            },
            child: const Text('Aplicar filtros'),
          ),
        ],
      ),
    );
  }
}
