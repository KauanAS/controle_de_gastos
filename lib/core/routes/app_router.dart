import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:controle_de_gastos/presentation/screens/home/home_screen.dart';
import 'package:controle_de_gastos/presentation/screens/new_entry/new_entry_screen.dart';
import 'package:controle_de_gastos/presentation/screens/confirmation/confirmation_screen.dart';
import 'package:controle_de_gastos/presentation/screens/history/history_screen.dart';
import 'package:controle_de_gastos/domain/entities/expense_entity.dart';

class AppRoutes {
  AppRoutes._();
  static const String home = 'home';
  static const String newEntry = 'new-entry';
  static const String confirmation = 'confirmation';
  static const String history = 'history';
}

final appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: false,
  routes: [
    GoRoute(
      path: '/',
      name: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/new-entry',
      name: AppRoutes.newEntry,
      builder: (context, state) => const NewEntryScreen(),
    ),
    GoRoute(
      path: '/confirmation',
      name: AppRoutes.confirmation,
      builder: (context, state) {
        final expense = state.extra as ExpenseEntity;
        return ConfirmationScreen(expense: expense);
      },
    ),
    GoRoute(
      path: '/history',
      name: AppRoutes.history,
      builder: (context, state) => const HistoryScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Página não encontrada: ${state.error}'),
    ),
  ),
);
