import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:controle_de_gastos/core/routes/app_router.dart';
import 'package:controle_de_gastos/presentation/notifiers/new_entry_notifier.dart';
import 'package:controle_de_gastos/presentation/widgets/voice_input_button.dart';
import 'package:controle_de_gastos/domain/enums/category_enum.dart';
import 'package:controle_de_gastos/domain/enums/payment_method_enum.dart';
import 'package:controle_de_gastos/domain/entities/expense_entity.dart';
import 'package:controle_de_gastos/domain/enums/sync_status_enum.dart';
import 'package:uuid/uuid.dart';

class NewEntryScreen extends ConsumerStatefulWidget {
  const NewEntryScreen({super.key});

  @override
  ConsumerState<NewEntryScreen> createState() => _NewEntryScreenState();
}

class _NewEntryScreenState extends ConsumerState<NewEntryScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Novo gasto'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              ref.read(newEntryProvider.notifier).reset();
              if (context.canPop()) context.pop();
            },
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Mágica', icon: Icon(Icons.auto_awesome)),
              Tab(text: 'Manual', icon: Icon(Icons.edit_note)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AITab(),
            _ManualTab(),
          ],
        ),
      ),
    );
  }
}

class _AITab extends ConsumerStatefulWidget {
  const _AITab();

  @override
  ConsumerState<_AITab> createState() => _AITabState();
}

class _AITabState extends ConsumerState<_AITab> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _parse() {
    FocusScope.of(context).unfocus();
    ref.read(newEntryProvider.notifier).parsePhrase(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(newEntryProvider);

    ref.listen(newEntryProvider, (prev, next) {
      if (prev?.status != NewEntryStatus.parsed &&
          next.status == NewEntryStatus.parsed &&
          next.parsedExpense != null) {
        context.pushNamed(
          AppRoutes.confirmation,
          extra: next.parsedExpense,
        );
      }
    });

    final isLoading = state.status == NewEntryStatus.parsing;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Descreva o gasto em português:',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Ex: "45 reais de gasolina no pix"',
                    alignLabelWithHint: true,
                  ),
                  onSubmitted: (_) => _parse(),
                ),
              ),
              const SizedBox(width: 8),
              VoiceInputButton(
                onVoiceResult: (text) {
                  _controller.text = text;
                  _parse();
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          _ExamplesCard(
            onTap: (example) {
              _controller.text = example;
              _focusNode.requestFocus();
            },
          ),

          const SizedBox(height: 16),

          if (state.status == NewEntryStatus.error &&
              state.errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_outlined,
                      color: colorScheme.onErrorContainer, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const Spacer(),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _controller.clear();
                    ref.read(newEntryProvider.notifier).reset();
                  },
                  child: const Text('Limpar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: isLoading ? null : _parse,
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(isLoading ? 'Interpretando...' : 'Interpretar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ManualTab extends ConsumerStatefulWidget {
  const _ManualTab();

  @override
  ConsumerState<_ManualTab> createState() => _ManualTabState();
}

class _ManualTabState extends ConsumerState<_ManualTab> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  
  CategoryEnum _category = CategoryEnum.outros;
  PaymentMethod _payment = PaymentMethod.pix;

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text.replaceAll(',', '.'));
      
      final expense = ExpenseEntity(
        id: const Uuid().v4(),
        category: _category,
        paymentMethod: _payment,
        originalText: _descController.text, // Para manual, description = originalText
        amount: amount,
        dateTime: DateTime.now(),
        syncStatus: SyncStatus.pending,
        createdAt: DateTime.now(),
      );

      // Manda direto a etapa de confirmacao pois ja é entrada manual
      // Pula o fluxo de IA e apenas confirma
      ref.read(newEntryProvider.notifier).confirmExpense(expense).then((_) {
         context.goNamed(AppRoutes.home);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Descrição do gasto', border: OutlineInputBorder()),
              validator: (val) => val == null || val.isEmpty ? 'Informe a descrição' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Valor', prefixText: 'R\$ ', border: OutlineInputBorder()),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Informe o valor';
                if (double.tryParse(val.replaceAll(',', '.')) == null) return 'Valor inválido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CategoryEnum>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Categoria', border: OutlineInputBorder()),
              items: CategoryEnum.values.map((c) => DropdownMenuItem(
                value: c,
                child: Row(children: [Text(c.icon), const SizedBox(width: 8), Text(c.displayName)]),
              )).toList(),
              onChanged: (val) => setState(() => _category = val!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PaymentMethod>(
              value: _payment,
              decoration: const InputDecoration(labelText: 'Forma de Pagamento', border: OutlineInputBorder()),
              items: PaymentMethod.values.map((p) => DropdownMenuItem(
                value: p,
                child: Row(children: [Text(p.icon), const SizedBox(width: 8), Text(p.displayName)]),
              )).toList(),
              onChanged: (val) => setState(() => _payment = val!),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Salvar Lançamento'),
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamplesCard extends StatelessWidget {
  final void Function(String) onTap;

  const _ExamplesCard({required this.onTap});

  static const _examples = [
    '45 reais de gasolina no pix',
    '120 no mercado no cartão',
    '39,90 netflix no crédito',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exemplos (toque para usar):',
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: _examples.map((e) {
            return ActionChip(
              label: Text(e, style: const TextStyle(fontSize: 12)),
              onPressed: () => onTap(e),
            );
          }).toList(),
        ),
      ],
    );
  }
}