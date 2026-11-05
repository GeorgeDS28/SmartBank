import 'package:smartbank/core/network/api_client.dart';
import 'package:smartbank/core/network/api_exception.dart';
import 'package:smartbank/features/analytics/data/models/analytics_models.dart';
import 'package:smartbank/features/analytics/domain/repositories/analytics_repository.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final ApiClient _apiClient;

  AnalyticsRepositoryImpl(this._apiClient);

  Future<Map<String, dynamic>> _get(String path) async {
    try {
      final response = await _apiClient.dio.get(path);
      return response.data as Map<String, dynamic>;
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  @override
  Future<FinancialSummaryModel> getFinancialSummary() async {
    final json = await _get('/api/analytics/financial-summary');
    return FinancialSummaryModel.fromJson(json);
  }

  @override
  Future<List<MonthlyActivityModel>> getMonthlyActivity() async {
    try {
      final response = await _apiClient.dio.get('/api/analytics/monthly');
      return (response.data as List)
          .map(
            (json) =>
                MonthlyActivityModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  @override
  Future<GoalAnalyticsModel> getGoalAnalytics() async {
    final json = await _get('/api/analytics/goals');
    return GoalAnalyticsModel.fromJson(json);
  }

  @override
  Future<TransferAnalyticsModel> getTransferAnalytics() async {
    final json = await _get('/api/analytics/transfers');
    return TransferAnalyticsModel.fromJson(json);
  }
}
