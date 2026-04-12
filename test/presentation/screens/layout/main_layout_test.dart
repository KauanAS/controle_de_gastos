import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:controle_de_gastos/presentation/screens/layout/main_layout.dart';

void main() {
  testWidgets('MainLayout deve renderizar BottomNavigationBar com Home, Histórico e Perfil', (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainLayout(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, state) => const Scaffold(body: Text('Home Page')),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/history',
                  builder: (context, state) => const Scaffold(body: Text('History Page')),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (context, state) => const Scaffold(body: Text('Profile Page')),
                ),
              ],
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Início'), findsOneWidget);
    expect(find.text('Histórico'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('Home Page'), findsOneWidget);

    // Clica no histórico
    await tester.tap(find.text('Histórico'));
    await tester.pumpAndSettle();
    expect(find.text('History Page'), findsOneWidget);
  });
}
