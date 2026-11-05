//api_client.dart

import 'package:dio/dio.dart';

import 'package:smartbank/core/storage/token_storage.dart';

class ApiClient {
  /// Baked in at compile time, so a hosted build needs
  /// `--dart-define=API_BASE_URL=https://api.example.com`.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  final Dio dio;
  final TokenStorage _tokenStorage;

  ApiClient({TokenStorage? tokenStorage})
    : _tokenStorage = tokenStorage ?? TokenStorage(),
      dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final isAuthRequest = options.path.startsWith('/api/auth/');

          if (!isAuthRequest) {
            final token = await _tokenStorage.getToken();

            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }

          handler.next(options);
        },
      ),
    );
  }
}
