import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:controle_de_gastos/core/routes/app_router.dart';
import 'package:controle_de_gastos/presentation/providers/expense_providers.dart';
import 'package:controle_de_gastos/presentation/widgets/monthly_summary_card.dart';
import 'package:controle_de_gastos/presentation/widgets/expense_list_tile.dart';
import 'package:controle_de_gastos/presentation/widgets/empty_state_widget.dart';
import 'package:controle_de_gastos/presentation/notifiers/history_notifier.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(monthlySummaryProvider);
    final expensesAsync = ref.watch(allExpensesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gastos',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allExpensesProvider);
          ref.invalidate(currentMonthExpensesProvider);
          ref.invalidate(monthlySummaryProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ── Resumo mensal ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: summaryAsync.when(
                data: (summary) => MonthlySummaryCard(summary: summary),
                loading: () => const _SummaryCardSkeleton(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            // ── Header da lista ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Lançamentos recentes',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Lista de gastos ────────────────────────────────────────
            expensesAsync.when(
              data: (expenses) {
                if (expenses.isEmpty) {
                  return SliverFillRemaining(
                    child: EmptyStateWidget(
                      icon: Icons.receipt_long_outlined,
                      title: 'Nenhum lançamento ainda',
                      subtitle:
                          'Toque no botão + para registrar seu primeiro gasto.',
                    ),
                  );
                }

                // Mostra no máximo 20 itens recentes na home
                final recent = expenses.take(20).toList();

                return SliverList.builder(
                  itemCount: recent.length,
                  itemBuilder: (context, index) {
                    final expense = recent[index];
                    return ExpenseListTile(expense: expense);
                  },
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Center(child: Text('Erro: $e')),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => SafeArea(
              child: Wrap(
                children: [
                  ListTile(
                    leading: const Icon(Icons.money_off, color: Colors.red),
                    title: const Text('Novo Gasto'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.newEntry);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.attach_money, color: Colors.green),
                    title: const Text('Nova Receita'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.newIncome);
                    },
                  ),
                ],
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SummaryCardSkeleton extends StatelessWidget {
  const _SummaryCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 130,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}