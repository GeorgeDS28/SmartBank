//user_repository_impl.dart

import 'package:dio/dio.dart';
import 'package:smartbank/core/network/api_client.dart';
import 'package:smartbank/features/user/data/models/dashboard_model.dart';
import 'package:smartbank/features/user/data/models/user_profile.dart';
import 'package:smartbank/features/user/domain/repositories/user_repository.dart';
import 'package:smartbank/features/user/data/models/account_model.dart';

class UserRepositoryImpl implements UserRepository {
  final ApiClient apiClient;

  UserRepositoryImpl(this.apiClient);

  @override
  Future<UserProfile> getProfile() async {
    final response = await apiClient.dio.get(
      '/api/user/profile',
      options: Options(responseType: ResponseType.plain),
    );

    return UserProfile.fromResponse(response.data);
  }

  @override
  Future<DashboardModel> getDashboard() async {
    final response = await apiClient.dio.get('/api/analytics/dashboard');

    return DashboardModel.fromJson(response.data);
  }

  @override
  Future<List<AccountModel>> getAccounts() async {
    final response = await apiClient.dio.get('/api/accounts');

    return (response.data as List)
        .map((json) => AccountModel.fromJson(json))
        .toList();
  }
}
