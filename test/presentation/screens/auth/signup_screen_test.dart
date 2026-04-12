import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:controle_de_gastos/presentation/screens/auth/signup_screen.dart';
import 'package:controle_de_gastos/presentation/notifiers/auth_notifier.dart';

class MockAuthNotifier extends AuthNotifier {
  MockAuthNotifier() : super(null) {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

void main() {
  group('SignupScreen', () {
    testWidgets('deve exibir os campos de email e senha, alem do botao de Google e criar conta', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith((ref) => MockAuthNotifier()),
          ],
          child: const MaterialApp(
            home: SignupScreen(),
          ),
        ),
      );

      // Verify Texts and fields
      expect(find.text('Criar uma Conta'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Senha'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      
      // Verify buttons
      expect(find.text('Cadastrar'), findsOneWidget);
      expect(find.text('Entrar com o Google'), findsOneWidget);
      expect(find.text('Já tem uma conta? Entrar'), findsOneWidget);
    });

    testWidgets('mostrar validacao quando form for submetido vazio', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith((ref) => MockAuthNotifier()),
          ],
          child: const MaterialApp(
            home: SignupScreen(),
          ),
        ),
      );

      // Submit without entering data
      await tester.tap(find.text('Cadastrar'));
      await tester.pump();

      // Find validation warnings
      expect(find.text('Informe o seu email'), findsOneWidget);
      expect(find.text('Informe a sua senha'), findsOneWidget);
    });
  });
}
