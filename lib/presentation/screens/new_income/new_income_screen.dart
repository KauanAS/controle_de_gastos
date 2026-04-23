import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:controle_de_gastos/domain/enums/income_category_enum.dart';
import 'package:controle_de_gastos/presentation/notifiers/income_notifier.dart';

class NewIncomeScreen extends ConsumerStatefulWidget {
  const NewIncomeScreen({super.key});

  @override
  ConsumerState<NewIncomeScreen> createState() => _NewIncomeScreenState();
}

class _NewIncomeScreenState extends ConsumerState<NewIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _observationController = TextEditingController();
  IncomeCategoryEnum _selectedCategory = IncomeCategoryEnum.salario;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final amountRaw = _amountController.text.replaceAll(',', '.');
      final amount = double.tryParse(amountRaw) ?? 0.0;

      ref.read(incomeNotifierProvider.notifier).addIncome(
        description: _descriptionController.text.trim(),
        amount: amount,
        category: _selectedCategory,
        dateTime: _selectedDate,
        observation: _observationController.text.trim().isEmpty ? null : _observationController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(incomeNotifierProvider);

    ref.listen(incomeNotifierProvider, (prev, next) {
      if (prev?.status != IncomeStatus.success && next.status == IncomeStatus.success) {
        if (mounted && context.canPop()) context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receita cadastrada com sucesso!'), backgroundColor: Colors.green),
        );
      } else if (next.status == IncomeStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!), backgroundColor: Colors.red),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Receita'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Valor (R\$)',
                  border: OutlineInputBorder(),
                  prefixText: 'R\$ ',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Informe um valor';
                  final parsed = double.tryParse(val.replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) return 'Valor inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Informe uma descrição';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<IncomeCategoryEnum>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  border: OutlineInputBorder(),
                ),
                items: IncomeCategoryEnum.values.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Row(
                      children: [
                        Text(cat.icon),
                        const SizedBox(width: 8),
                        Text(cat.displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _observationController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Observação (Opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: state.status == IncomeStatus.saving ? null : _submit,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: state.status == IncomeStatus.saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Cadastrar Receita', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
