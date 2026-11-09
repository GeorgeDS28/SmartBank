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

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await apiClient.dio.put(
        '/api/auth/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
      );
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  @override
  Future<String> forgotPassword({required String email}) async {
    try {
      final response = await apiClient.dio.post(
        '/api/auth/forgot-password',
        data: {'email': email},
      );

      return _messageOf(response.data);
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  @override
  Future<String> resetPassword({
    required String email,
    required String code,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/api/auth/reset-password',
        data: {
          'email': email,
          'code': code,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
      );

      return _messageOf(response.data);
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  /// The recovery endpoints reply with a message the UI repeats verbatim, so
  /// the user reads the server's own wording rather than a promise made here.
  static String _messageOf(dynamic data) {
    if (data is Map) return data['message']?.toString() ?? '';
    return data?.toString() ?? '';
  }
}
