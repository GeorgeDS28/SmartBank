//authprovider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartbank/core/network/providers.dart';
import 'package:smartbank/core/storage/token_storage.dart';
import 'package:smartbank/core/utils/token_claims.dart';
import 'package:smartbank/features/auth/data/models/login_request.dart';
import 'package:smartbank/features/auth/data/models/register_request.dart';
import 'package:smartbank/features/auth/data/models/register_response.dart';
import 'package:smartbank/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:smartbank/features/auth/domain/repositories/auth_repository.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;

  /// Email read back from the issued token, so the app can show which account
  /// is signed in. The backend has no endpoint that returns it.
  final String? email;

  const AuthState({required this.status, this.email});

  const AuthState.loading() : this(status: AuthStatus.loading);

  const AuthState.authenticated({String? email})
    : this(status: AuthStatus.authenticated, email: email);

  const AuthState.unauthenticated() : this(status: AuthStatus.unauthenticated);
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _checkAuthentication();
    return const AuthState.loading();
  }

  TokenStorage get _tokenStorage => ref.read(tokenStorageProvider);

  AuthRepository get _authRepository =>
      AuthRepositoryImpl(ref.read(apiClientProvider));

  Future<void> _checkAuthentication() async {
    final token = await _tokenStorage.getToken();

    if (token != null && token.isNotEmpty) {
      state = AuthState.authenticated(email: emailFromToken(token));
    } else {
      state = const AuthState.unauthenticated();
    }
  }

  Future<RegisterResponse> register(RegisterRequest request) =>
      _authRepository.register(request);

  /// Stores the issued token before flipping state, so the router redirect
  /// cannot run while secure storage is still writing.
  Future<void> login(LoginRequest request) async {
    final response = await _authRepository.login(request);
    await _tokenStorage.saveToken(response.token);
    _startSession();
    state = AuthState.authenticated(email: emailFromToken(response.token));
  }

  Future<void> logout() async {
    await _tokenStorage.deleteToken();
    _startSession();
    state = const AuthState.unauthenticated();
  }

  /// Drops everything the previous user had cached, including this user's own
  /// data so nothing is shown before it has been re-read from the backend.
  void _startSession() => ref.read(sessionIdProvider.notifier).next();
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
