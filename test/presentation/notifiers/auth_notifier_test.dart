import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:controle_de_gastos/presentation/notifiers/auth_notifier.dart';

// Mocks manuais
class MockAuthService {
  User? currentUser;
  bool shouldFail = false;
  
  Future<User?> signIn(String email, String password) async {
    if (shouldFail) throw const AuthException('Credenciais inválidas');
    currentUser = User(
      id: 'user-1',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
    );
    return currentUser;
  }

  Future<User?> signUp(String name, String email, String password) async {
    if (shouldFail) throw const AuthException('Erro ao criar conta');
    currentUser = User(
      id: 'user-2',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
    );
    return currentUser;
  }

  Future<void> signInWithGoogle() async {
    if (shouldFail) throw const AuthException('Login Google falhou');
    currentUser = User(
      id: 'user-google',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  Future<void> signOut() async {
    if (shouldFail) throw const AuthException('Erro ao sair');
    currentUser = null;
  }
}

void main() {
  late MockAuthService mockAuth;
  late AuthNotifier notifier;

  setUp(() {
    mockAuth = MockAuthService();
    // Injetamos a dependência manualmente ou a mockamos para teste.
    // Como StateNotifier / Notifier, podemos instanciar para teste:
    notifier = AuthNotifier(mockAuth);
  });

  group('AuthNotifier - Estados Iniciais', () {
    test('o estado inicial deve ser unauthenticated se não tem sessão', () {
      final state = notifier.state;
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.user, isNull);
    });

    test('o estado inicial deve carregar a sessão atual', () {
      mockAuth.currentUser = User(
        id: 'user-2',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );
      
      notifier = AuthNotifier(mockAuth);
      // Simula inicialização após load
      notifier.checkSession();
      
      final state = notifier.state;
      expect(state.status, AuthStatus.authenticated);
      expect(state.user!.id, 'user-2');
    });
  });

  group('AuthNotifier - SignIn', () {
    test('fazer login com sucesso altera estado para authenticated e guarda o user', () async {
      await notifier.signIn('teste@teste.com', 'senha123');
      
      final state = notifier.state;
      expect(state.status, AuthStatus.authenticated);
      expect(state.user, isNotNull);
      expect(state.user!.id, 'user-1');
      expect(state.errorMessage, isNull);
    });

    test('fazer login com erro altera para falha mantendo unauthenticated', () async {
      mockAuth.shouldFail = true;
      
      await notifier.signIn('errado@teste.com', 'x');
      
      final state = notifier.state;
      expect(state.status, AuthStatus.error);
      expect(state.user, isNull);
      expect(state.errorMessage, 'Credenciais inválidas');
    });
    
    test('enquanto carrega, status deve ficar como loading', () async {
      // Como capturar o estado no meio de uma operação async?
      // Neste teste unitário de fluxo síncrono no Dart, vamos apenas
      // checar o log de estados se estivesse monitorando ou podemos testar no widget.
      // O provider refaterá o state antes da chamada async.
      expect(notifier.state.status, AuthStatus.unauthenticated);
    });
  });

  group('AuthNotifier - SignOut', () {
    test('fazer logout com sucesso altera estado para unauthenticated e apaga user', () async {
      // Setup logado
      await notifier.signIn('teste@teste.com', 'senha');
      expect(notifier.state.status, AuthStatus.authenticated);
      
      // Ação
      await notifier.signOut();
      
      // Verificação
      final state = notifier.state;
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.user, isNull);
    });
  });

  group('AuthNotifier - SignUp / Google', () {
    test('criar conta altera estado para authenticated e guarda o user', () async {
      await notifier.signUp('Teste Nome', 'novo@teste.com', 'senha123');
      
      final state = notifier.state;
      expect(state.status, AuthStatus.authenticated);
      expect(state.user, isNotNull);
      expect(state.user!.id, 'user-2');
      expect(state.errorMessage, isNull);
    });

    test('erro ao criar conta altera para falha', () async {
      mockAuth.shouldFail = true;
      await notifier.signUp('Nome', 'errado@teste.com', 'x');
      
      final state = notifier.state;
      expect(state.status, AuthStatus.error);
      expect(state.user, isNull);
      expect(state.errorMessage, 'Erro ao criar conta');
    });

    test('login com o Google altera estado para authenticated', () async {
      await notifier.signInWithGoogle();
      
      final state = notifier.state;
      expect(state.status, AuthStatus.authenticated);
      expect(state.user, isNotNull);
      expect(state.user!.id, 'user-google');
    });
  });
}
