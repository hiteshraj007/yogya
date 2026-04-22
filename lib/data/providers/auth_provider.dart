// import 'package:flutter_riverpod/flutter_riverpod.dart';

// // Auth Provider stub
// final authProvider = StateNotifierProvider<AuthNotifier, bool>((ref) {
//   return AuthNotifier();
// });

// class AuthNotifier extends StateNotifier<bool> {
//   AuthNotifier() : super(false);

//   void login() => state = true;
//   void logout() => state = false;
// }










import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_service.dart';
import '../local/hive_service.dart';

// ── 1. AuthService singleton ──────────────────────────────
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService.instance;
});

// ── 2. Auth state stream (drives router guard) ────────────
// This rebuilds any widget/provider watching it whenever
// the Firebase auth state changes (login / logout / token refresh)
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// ── 3. Current user convenience provider ─────────────────
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

// ── 4. Auth state model ───────────────────────────────────
class AuthState {
  final bool     isLoading;
  final String?  errorMessage;
  final bool     isAuthenticated;
  final User?    user;

  const AuthState({
    this.isLoading      = false,
    this.errorMessage,
    this.isAuthenticated = false,
    this.user,
  });

  AuthState copyWith({
    bool?   isLoading,
    String? errorMessage,
    bool?   isAuthenticated,
    User?   user,
    bool    clearError = false,
  }) {
    return AuthState(
      isLoading:       isLoading       ?? this.isLoading,
      errorMessage:    clearError ? null : (errorMessage ?? this.errorMessage),
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user:            user            ?? this.user,
    );
  }
}

// ── 5. AuthNotifier — actions ────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState());

  // Email + Password login
  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _authService.signInWithEmail(
      email:    email,
      password: password,
    );

    if (result.success) {
      state = state.copyWith(
        isLoading:       false,
        isAuthenticated: true,
        user:            result.user,
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading:    false,
        errorMessage: result.errorMessage,
      );
      return false;
    }
  }

  // Email + Password sign-up
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _authService.signUpWithEmail(
      email:       email,
      password:    password,
      displayName: displayName,
    );

    if (result.success) {
      state = state.copyWith(
        isLoading:       false,
        isAuthenticated: true,
        user:            result.user,
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading:    false,
        errorMessage: result.errorMessage,
      );
      return false;
    }
  }

  // Google OAuth
  Future<bool> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _authService.signInWithGoogle();

    if (result.success) {
      state = state.copyWith(
        isLoading:       false,
        isAuthenticated: true,
        user:            result.user,
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading:    false,
        errorMessage: result.errorMessage,
      );
      return false;
    }
  }

  // Password reset email
  Future<bool> sendPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _authService.sendPasswordReset(email);
    state = state.copyWith(
      isLoading:    false,
      errorMessage: result.success ? null : result.errorMessage,
    );
    return result.success;
  }

  // Sign out — router will redirect to /login automatically
  // via authStateProvider stream
  Future<void> logout() async {
    await _authService.signOut();
    await HiveService.clearUserSessionData();
    state = const AuthState();
  }

  // Clear error (e.g. when user starts typing again)
  void clearError() => state = state.copyWith(clearError: true);
}

// ── 6. AuthNotifier provider ─────────────────────────────
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});
