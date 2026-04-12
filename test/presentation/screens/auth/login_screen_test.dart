import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:controle_de_gastos/presentation/screens/auth/login_screen.dart';
import 'package:controle_de_gastos/presentation/notifiers/auth_notifier.dart';

class MockAuthNotifier extends AuthNotifier {
  MockAuthNotifier({AuthStatus status = AuthStatus.unauthenticated}) : super(null) {
    state = AuthState(status: status);
  }
}

void main() {
  group('LoginScreen', () {
    testWidgets('deve renderizar os campos de email e senha, e botao de login', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith((ref) => MockAuthNotifier()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: LoginScreen()),
          ),
        ),
      );

      expect(find.byType(TextFormField), findsNWidgets(2)); // email e senha
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Senha'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
    });

    testWidgets('deve mostrar mensagem de erro se tentar logar com email vazio', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith((ref) => MockAuthNotifier()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: LoginScreen()),
          ),
        ),
      );

      await tester.tap(find.text('Entrar'));
      await tester.pump();

      expect(find.text('Informe o seu email'), findsOneWidget);
    });

    testWidgets('deve exibir CircularProgressIndicator quando isLoading é true', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith((ref) => MockAuthNotifier(status: AuthStatus.loading)),
          ],
          child: const MaterialApp(
            home: Scaffold(body: LoginScreen()),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
