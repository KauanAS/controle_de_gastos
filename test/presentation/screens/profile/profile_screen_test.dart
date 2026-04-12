import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:controle_de_gastos/presentation/screens/profile/profile_screen.dart';
import 'package:controle_de_gastos/presentation/notifiers/auth_notifier.dart';

void main() {
  group('ProfileScreen', () {
    testWidgets('deve renderizar botao de sair e aviso LGPD', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith((ref) => MockAuthNotifier()),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      expect(find.text('Perfil'), findsOneWidget);
      expect(find.text('Sair'), findsOneWidget);
      expect(find.text('Excluir minha conta e dados'), findsOneWidget);
    });
  });
}

class MockAuthNotifier extends AuthNotifier {
  MockAuthNotifier() : super(null) {
    state = const AuthState(status: AuthStatus.authenticated);
  }
}
