import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:equatable/equatable.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
    _listenToAuthState();
  }

  void _listenToAuthState() {
    if (_authService is GoTrueClient) {
      _authService.onAuthStateChange.listen((data) {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;

        if (event == AuthChangeEvent.signedIn && session != null) {
          state = state.copyWith(
            status: AuthStatus.authenticated,
            user: session.user,
            clearError: true,
          );
        } else if (event == AuthChangeEvent.signedOut) {
          state = state.copyWith(
            status: AuthStatus.unauthenticated,
            clearUser: true,
            clearError: true,
          );
        }
      });
    }
  }

  void checkSession() {
    User? user;
    try {
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

  Future<void> signUp(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    
    try {
      if (_authService.runtimeType.toString() == 'MockAuthService') {
        final user = await _authService.signUp(email, password);
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );
      } else if (_authService is GoTrueClient) {
        final response = await _authService.signUp(email: email, password: password);
        if (response.user != null) {
          state = state.copyWith(
            status: AuthStatus.authenticated,
            user: response.user,
          );
        } else {
          state = state.copyWith(status: AuthStatus.unauthenticated);
        }
      }
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Erro inesperado ao criar conta: $e',
      );
    }
  }

  /// Login nativo com Google usando google_sign_in + Supabase signInWithIdToken.
  /// Este fluxo funciona em Android/iOS sem abrir navegador externo.
  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      if (_authService.runtimeType.toString() == 'MockAuthService') {
        await _authService.signInWithGoogle();
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: _authService.currentUser,
        );
        return;
      }

      if (_authService is GoTrueClient) {
        // Web Client ID do Google Cloud (o mesmo configurado no Supabase)
        const webClientId =
            '102265062478-gi3deor4b81s5p0op90sdi380bu5v80t.apps.googleusercontent.com';

        final googleSignIn = GoogleSignIn(
          serverClientId: webClientId,
        );

        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          // Usuário cancelou o popup
          state = state.copyWith(status: AuthStatus.unauthenticated);
          return;
        }

        final googleAuth = await googleUser.authentication;
        final idToken = googleAuth.idToken;
        final accessToken = googleAuth.accessToken;

        if (idToken == null) {
          state = state.copyWith(
            status: AuthStatus.error,
            errorMessage: 'Não foi possível obter o token do Google.',
          );
          return;
        }

        // Usa o idToken para logar no Supabase diretamente
        final response = await _authService.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );

        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: response.user,
          clearError: true,
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
        errorMessage: 'Erro ao fazer login com o Google: $e',
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
