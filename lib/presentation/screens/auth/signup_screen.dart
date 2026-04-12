import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:controle_de_gastos/presentation/notifiers/auth_notifier.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ref.read(authNotifierProvider.notifier).signUp(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }
  }

  void _submitGoogle() {
    ref.read(authNotifierProvider.notifier).signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    // Escuta erros para exibir SnackBar
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastre-se'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
             padding: const EdgeInsets.all(24),
             child: Form(
               key: _formKey,
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 crossAxisAlignment: CrossAxisAlignment.stretch,
                 children: [
                   const Icon(Icons.person_add, size: 80, color: Colors.blue),
                   const SizedBox(height: 24),
                   const Text(
                     'Criar uma Conta',
                     textAlign: TextAlign.center,
                     style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                   ),
                   const SizedBox(height: 32),
                   TextFormField(
                     controller: _emailController,
                     keyboardType: TextInputType.emailAddress,
                     decoration: const InputDecoration(
                       labelText: 'Email',
                       border: OutlineInputBorder(),
                     ),
                     validator: (value) {
                       if (value == null || value.trim().isEmpty) {
                         return 'Informe o seu email';
                       }
                       return null;
                     },
                   ),
                   const SizedBox(height: 16),
                   TextFormField(
                     controller: _passwordController,
                     obscureText: true,
                     decoration: const InputDecoration(
                       labelText: 'Senha',
                       border: OutlineInputBorder(),
                     ),
                     validator: (value) {
                       if (value == null || value.isEmpty) {
                         return 'Informe a sua senha';
                       }
                       if (value.length < 6) {
                         return 'A senha deve ter no mínimo 6 caracteres';
                       }
                       return null;
                     },
                   ),
                   const SizedBox(height: 24),
                   if (authState.status == AuthStatus.loading)
                     const Center(child: CircularProgressIndicator())
                   else
                     Column(
                       crossAxisAlignment: CrossAxisAlignment.stretch,
                       children: [
                         ElevatedButton(
                           onPressed: _submit,
                           style: ElevatedButton.styleFrom(
                             padding: const EdgeInsets.symmetric(vertical: 16),
                           ),
                           child: const Text('Cadastrar', style: TextStyle(fontSize: 16)),
                         ),
                         const SizedBox(height: 16),
                         OutlinedButton.icon(
                           onPressed: _submitGoogle,
                           icon: const Icon(Icons.g_mobiledata, size: 28),
                           label: const Text('Entrar com o Google'),
                           style: OutlinedButton.styleFrom(
                             padding: const EdgeInsets.symmetric(vertical: 14),
                           ),
                         ),
                         const SizedBox(height: 16),
                         TextButton(
                           onPressed: () => context.pop(),
                           child: const Text('Já tem uma conta? Entrar'),
                         ),
                       ],
                     ),
                 ],
               ),
             ),
          ),
        ),
      ),
    );
  }
}
