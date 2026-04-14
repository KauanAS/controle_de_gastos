import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:controle_de_gastos/presentation/notifiers/auth_notifier.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;

    // Busca o nome do perfil do Supabase
    final profileAsync = ref.watch(_profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.person_pin, size: 80, color: Colors.blue),
            const SizedBox(height: 12),

            // Nome do usuário
            profileAsync.when(
              data: (profile) => Text(
                profile?['full_name'] ?? 'Usuário',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              loading: () => const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, __) => Text(
                'Usuário',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? '',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),

            // Opção: Editar nome
            ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: const Text('Alterar nome'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _editName(context, ref),
            ),
            const Divider(height: 1),

            // Opção: Alterar email
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Alterar email'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _editEmail(context),
            ),
            const Divider(height: 1),

            // Opção: Alterar senha
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Alterar senha'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _editPassword(context),
            ),
            const Divider(height: 1),

            const SizedBox(height: 24),

            // Sair
            FilledButton.icon(
              onPressed: () {
                ref.read(authNotifierProvider.notifier).signOut();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sair'),
            ),

            const SizedBox(height: 32),

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

  // ─── Editar nome ───────────────────────────────────────────────────────────

  void _editName(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Alterar nome'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Novo nome',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(context);

              try {
                final userId = Supabase.instance.client.auth.currentUser!.id;
                
                // Atualiza na tabela profiles
                await Supabase.instance.client
                    .from('profiles')
                    .update({'full_name': name})
                    .eq('id', userId);
                
                // Atualiza user_metadata do Auth
                await Supabase.instance.client.auth.updateUser(
                  UserAttributes(data: {'full_name': name}),
                );
                
                ref.invalidate(_profileProvider);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nome atualizado!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao atualizar nome: $e')),
                  );
                }
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  // ─── Editar email ──────────────────────────────────────────────────────────

  void _editEmail(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Alterar email'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Novo email',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final email = controller.text.trim();
              if (email.isEmpty) return;
              Navigator.pop(context);
              
              try {
                await Supabase.instance.client.auth.updateUser(
                  UserAttributes(email: email),
                );
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Um email de confirmação foi enviado para o novo endereço.',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao atualizar email: $e')),
                  );
                }
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  // ─── Editar senha ──────────────────────────────────────────────────────────

  void _editPassword(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Alterar senha'),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Nova senha',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final password = controller.text;
              if (password.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('A senha deve ter no mínimo 6 caracteres.'),
                  ),
                );
                return;
              }
              Navigator.pop(context);

              try {
                await Supabase.instance.client.auth.updateUser(
                  UserAttributes(password: password),
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Senha atualizada!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao atualizar senha: $e')),
                  );
                }
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  // ─── Exclusão de conta ─────────────────────────────────────────────────────

  void _confirmAccountDeletion(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir conta?'),
        content: const Text(
          'Tem certeza? Esta ação removerá definitivamente todos os seus dados e não poderá ser desfeita.',
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

// ─── Provider para buscar o perfil no Supabase ─────────────────────────────

final _profileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;
  
  try {
    final response = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    return response;
  } catch (_) {
    return null;
  }
});
