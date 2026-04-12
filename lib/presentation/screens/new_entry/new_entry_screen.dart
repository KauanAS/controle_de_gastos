import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:controle_de_gastos/core/routes/app_router.dart';
import 'package:controle_de_gastos/presentation/notifiers/new_entry_notifier.dart';
import 'package:controle_de_gastos/presentation/widgets/voice_input_button.dart';

class NewEntryScreen extends ConsumerStatefulWidget {
  const NewEntryScreen({super.key});

  @override
  ConsumerState<NewEntryScreen> createState() => _NewEntryScreenState();
}

class _NewEntryScreenState extends ConsumerState<NewEntryScreen> {
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

    // Navega para confirmação quando o parse é bem-sucedido.
    // Usamos listen fora do build — seguro pois ConsumerStatefulWidget
    // garante que o listener só dispara enquanto o widget está montado.
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo gasto'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(newEntryProvider.notifier).reset();
            if (context.canPop()) context.pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Instrução ──────────────────────────────────────────────
            Text(
              'Descreva o gasto em português:',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),

            // ── Campo de texto + botão de voz ──────────────────────────
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
                      hintText:
                          'Ex: "45 reais de gasolina no pix"',
                      alignLabelWithHint: true,
                    ),
                    onSubmitted: (_) => _parse(),
                  ),
                ),
                const SizedBox(width: 8),
                // PONTO DE EXTENSÃO: VoiceInputButton conecta ao STT aqui
                VoiceInputButton(
                  onVoiceResult: (text) {
                    _controller.text = text;
                    _parse();
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Exemplos de frases ─────────────────────────────────────
            _ExamplesCard(
              onTap: (example) {
                _controller.text = example;
                _focusNode.requestFocus();
              },
            ),

            const SizedBox(height: 16),

            // ── Mensagem de erro ───────────────────────────────────────
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

            // ── Botões de ação ─────────────────────────────────────────
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
                    label:
                        Text(isLoading ? 'Interpretando...' : 'Interpretar'),
                  ),
                ),
              ],
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
    '15 de café no débito',
    '200 aluguel no boleto',
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