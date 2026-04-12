import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:controle_de_gastos/main.dart';
import 'package:controle_de_gastos/presentation/notifiers/auth_notifier.dart';
import 'package:flutter/material.dart';

class MockAuthNotifier extends AuthNotifier {
  MockAuthNotifier() : super(null) {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

void main() {
  testWidgets('GastosApp renders properly', (tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith((ref) => MockAuthNotifier()),
        ],
        child: const GastosApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify app opens without crashing and finds MaterialApp/Router
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
