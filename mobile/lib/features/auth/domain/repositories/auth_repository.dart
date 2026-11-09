//auth_repository.dart

import 'package:smartbank/features/auth/data/models/auth_response.dart';
import 'package:smartbank/features/auth/data/models/login_request.dart';
import 'package:smartbank/features/auth/data/models/register_request.dart';
import 'package:smartbank/features/auth/data/models/register_response.dart';

abstract class AuthRepository {
  Future<AuthResponse> login(LoginRequest request);

  Future<RegisterResponse> register(RegisterRequest request);

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });

  /// Returns the message the backend sent, which is deliberately the same
  /// whether or not the address belongs to an account.
  Future<String> forgotPassword({required String email});

  Future<String> resetPassword({
    required String email,
    required String code,
    required String newPassword,
    required String confirmPassword,
  });
}
