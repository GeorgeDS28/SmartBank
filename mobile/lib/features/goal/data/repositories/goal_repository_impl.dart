import 'package:intl/intl.dart';

import 'package:smartbank/core/network/api_client.dart';
import 'package:smartbank/core/network/api_exception.dart';
import 'package:smartbank/features/goal/data/models/goal_model.dart';
import 'package:smartbank/features/goal/domain/repositories/goal_repository.dart';

class GoalRepositoryImpl implements GoalRepository {
  static final _isoDate = DateFormat('yyyy-MM-dd');

  final ApiClient _apiClient;

  GoalRepositoryImpl(this._apiClient);

  Future<List<GoalModel>> _list(String path) async {
    try {
      final response = await _apiClient.dio.get(path);
      return (response.data as List)
          .map((json) => GoalModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  Future<GoalModel> _single(String path, {Map<String, dynamic>? body}) async {
    try {
      final response = await _apiClient.dio.post(path, data: body);
      return GoalModel.fromJson(response.data as Map<String, dynamic>);
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  @override
  Future<List<GoalModel>> getGoals() => _list('/api/goals');

  @override
  Future<GoalModel> getGoal(int id) async {
    try {
      final response = await _apiClient.dio.get('/api/goals/$id');
      return GoalModel.fromJson(response.data as Map<String, dynamic>);
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  @override
  Future<GoalModel> createGoal({
    required String goalName,
    required double targetAmount,
    required DateTime targetDate,
  }) => _single(
    '/api/goals',
    body: {
      'goalName': goalName,
      'targetAmount': targetAmount,
      'targetDate': _isoDate.format(targetDate),
    },
  );

  @override
  Future<GoalModel> updateGoal(
    int id, {
    required String goalName,
    required double targetAmount,
    required DateTime targetDate,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '/api/goals/$id',
        data: {
          'goalName': goalName,
          'targetAmount': targetAmount,
          'targetDate': _isoDate.format(targetDate),
        },
      );
      return GoalModel.fromJson(response.data as Map<String, dynamic>);
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  @override
  Future<GoalModel> contribute(int id, double amount) =>
      _single('/api/goals/$id/contribute', body: {'amount': amount});

  @override
  Future<void> deleteGoal(int id) async {
    try {
      await _apiClient.dio.delete('/api/goals/$id');
    } catch (error) {
      throw ApiException.from(error);
    }
  }
}
