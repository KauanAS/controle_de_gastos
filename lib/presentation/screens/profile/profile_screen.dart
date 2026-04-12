import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:controle_de_gastos/presentation/notifiers/auth_notifier.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final autoState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.person_pin, size: 80, color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              autoState.user?.email ?? 'Usuário',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 48),

            // Sair
            FilledButton.icon(
              onPressed: () {
                ref.read(authNotifierProvider.notifier).signOut();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sair'),
            ),

            const Spacer(),

            // Área de Perigo (LGPD)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.error),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: colorScheme.error),
                      const SizedBox(width: 8),
                      Text(
                        'Área de Perigo',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Caso deseje encerrar seu uso do aplicativo conforme as regras da LGPD, você pode excluir sua conta. '
                    'Todos os seus gastos e informações serão deletados permanentemente de nossos servidores.',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => _confirmAccountDeletion(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(color: colorScheme.error),
                    ),
                    child: const Text('Excluir minha conta e dados'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmAccountDeletion(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir conta?'),
        content: const Text(
          'Tem certeza? Esta ação removerá definitivamente todos os seus dados e não poderá ser desfeita.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () {
               Navigator.pop(context);
               // TODO: Chamar backend para soft-delete/LGPD purge
            },
            child: const Text('Sim, Excluir'),
          ),
        ],
      ),
    );
  }
}
