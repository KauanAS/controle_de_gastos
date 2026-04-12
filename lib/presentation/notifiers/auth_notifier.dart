import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:equatable/equatable.dart';

enum AuthStatus { initial, unauthenticated, loading, authenticated, error }

class AuthState extends Equatable {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage];
}

class AuthNotifier extends StateNotifier<AuthState> {
  final dynamic _authService;

  AuthNotifier(this._authService) : super(const AuthState()) {
    checkSession();
  }

  void checkSession() {
    User? user;
    try {
      // Diferenciar Mock do Serviço Real do Supabase para manter testabilidade simples no Dart
      if (_authService.runtimeType.toString() == 'MockAuthService') {
        user = _authService.currentUser;
      } else if (_authService is GoTrueClient) {
        user = _authService.currentUser;
      }
      
      if (user != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          clearError: true,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          clearUser: true,
          clearError: true,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
      );
    }
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    
    try {
      if (_authService.runtimeType.toString() == 'MockAuthService') {
        final user = await _authService.signIn(email, password);
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );
      } else if (_authService is GoTrueClient) {
        final response = await _authService.signInWithPassword(email: email, password: password);
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: response.user,
        );
      }
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Erro inesperado ao fazer login: $e',
      );
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      if (_authService.runtimeType.toString() == 'MockAuthService') {
        await _authService.signOut();
      } else if (_authService is GoTrueClient) {
        await _authService.signOut();
      }
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Erro ao sair: $e',
      );
    }
  }
}

// Provider global
final authServiceProvider = Provider<dynamic>((ref) {
  // Retorna a instância do GoTrueClient
  return Supabase.instance.client.auth;
});

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
