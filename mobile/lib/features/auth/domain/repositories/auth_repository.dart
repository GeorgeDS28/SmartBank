//auth_repository.dart

import 'package:smartbank/features/auth/data/models/auth_response.dart';
import 'package:smartbank/features/auth/data/models/login_request.dart';
import 'package:smartbank/features/auth/data/models/register_request.dart';
import 'package:smartbank/features/auth/data/models/register_response.dart';

abstract class AuthRepository {
  Future<AuthResponse> login(LoginRequest request);

  Future<RegisterResponse> register(RegisterRequest request);
}
