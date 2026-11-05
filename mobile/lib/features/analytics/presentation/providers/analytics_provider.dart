import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbank/core/network/providers.dart';
import 'package:smartbank/features/analytics/data/models/analytics_models.dart';
import 'package:smartbank/features/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:smartbank/features/analytics/domain/repositories/analytics_repository.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  ref.watch(sessionIdProvider);
  return AnalyticsRepositoryImpl(ref.watch(apiClientProvider));
});

final financialSummaryProvider = FutureProvider<FinancialSummaryModel>((ref) {
  return ref.watch(analyticsRepositoryProvider).getFinancialSummary();
});

final monthlyActivityProvider = FutureProvider<List<MonthlyActivityModel>>((
  ref,
) {
  return ref.watch(analyticsRepositoryProvider).getMonthlyActivity();
});

final goalAnalyticsProvider = FutureProvider<GoalAnalyticsModel>((ref) {
  return ref.watch(analyticsRepositoryProvider).getGoalAnalytics();
});

final transferAnalyticsProvider = FutureProvider<TransferAnalyticsModel>((ref) {
  return ref.watch(analyticsRepositoryProvider).getTransferAnalytics();
});
