//auth_repository_impl.dart

import 'package:smartbank/core/network/api_client.dart';
import 'package:smartbank/core/network/api_exception.dart';
import 'package:smartbank/features/auth/data/models/auth_response.dart';
import 'package:smartbank/features/auth/data/models/register_response.dart';
import 'package:smartbank/features/auth/data/models/login_request.dart';
import 'package:smartbank/features/auth/data/models/register_request.dart';

import 'package:smartbank/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient apiClient;

  AuthRepositoryImpl(this.apiClient);

  @override
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await apiClient.dio.post(
        '/api/auth/login',
        data: request.toJson(),
      );

      return AuthResponse.fromJson(response.data);
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  @override
  Future<RegisterResponse> register(RegisterRequest request) async {
    try {
      final response = await apiClient.dio.post(
        '/api/auth/register',
        data: request.toJson(),
      );

      return RegisterResponse.fromJson(response.data);
    } catch (error) {
      throw ApiException.from(error);
    }
  }
}
