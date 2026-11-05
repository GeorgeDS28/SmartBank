import 'package:smartbank/features/analytics/data/models/analytics_models.dart';

abstract class AnalyticsRepository {
  Future<FinancialSummaryModel> getFinancialSummary();

  Future<List<MonthlyActivityModel>> getMonthlyActivity();

  Future<GoalAnalyticsModel> getGoalAnalytics();

  Future<TransferAnalyticsModel> getTransferAnalytics();
}
