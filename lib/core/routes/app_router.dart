import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:controle_de_gastos/presentation/screens/home/home_screen.dart';
import 'package:controle_de_gastos/presentation/screens/new_entry/new_entry_screen.dart';
import 'package:controle_de_gastos/presentation/screens/confirmation/confirmation_screen.dart';
import 'package:controle_de_gastos/presentation/screens/history/history_screen.dart';
import 'package:controle_de_gastos/presentation/screens/layout/main_layout.dart';
import 'package:controle_de_gastos/presentation/screens/auth/login_screen.dart';
import 'package:controle_de_gastos/presentation/screens/auth/signup_screen.dart';
import 'package:controle_de_gastos/presentation/screens/splash_screen.dart';
import 'package:controle_de_gastos/presentation/screens/profile/profile_screen.dart';
import 'package:controle_de_gastos/presentation/screens/new_income/new_income_screen.dart';
import 'package:controle_de_gastos/domain/entities/expense_entity.dart';
import 'package:controle_de_gastos/presentation/notifiers/auth_notifier.dart';

class AppRoutes {
  AppRoutes._();
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String history = '/history';
  static const String profile = '/profile';
  static const String newEntry = '/new-entry';
  static const String newIncome = '/new-income';
  static const String confirmation = '/confirmation';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isSplash = state.matchedLocation == AppRoutes.splash;
      final isLoggingIn = state.matchedLocation == AppRoutes.login;

      final isSigningUp = state.matchedLocation == AppRoutes.signup;

      if (authState.status == AuthStatus.initial || authState.status == AuthStatus.loading) {
        return null; // Deixa rolar (geralmente splash tela)
      }

      if (authState.status == AuthStatus.unauthenticated) {
        return (isLoggingIn || isSigningUp) ? null : AppRoutes.login;
      }

      if (authState.status == AuthStatus.authenticated) {
        if (isLoggingIn || isSigningUp || isSplash) {
          return AppRoutes.home;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      // Rotas protegidas (Main Layout)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainLayout(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.history,
                name: 'history',
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      // Rotas sobrepostas ao layout (telas completas)
      GoRoute(
        path: AppRoutes.newEntry,
        name: 'newEntry',
        builder: (context, state) => const NewEntryScreen(),
      ),
      GoRoute(
        path: AppRoutes.newIncome,
        name: 'newIncome',
        builder: (context, state) => const NewIncomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.confirmation,
        name: 'confirmation',
        builder: (context, state) {
          final expense = state.extra as ExpenseEntity;
          return ConfirmationScreen(expense: expense);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Página não encontrada: ${state.error}'),
      ),
    ),
  );
});
