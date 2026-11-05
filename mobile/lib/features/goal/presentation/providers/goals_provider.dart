import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbank/core/network/providers.dart';
import 'package:smartbank/features/goal/data/models/goal_model.dart';
import 'package:smartbank/features/goal/data/repositories/goal_repository_impl.dart';
import 'package:smartbank/features/goal/domain/repositories/goal_repository.dart';
import 'package:smartbank/features/analytics/presentation/providers/analytics_provider.dart';
import 'package:smartbank/features/user/presentation/providers/dashboard_provider.dart';

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  ref.watch(sessionIdProvider);
  return GoalRepositoryImpl(ref.watch(apiClientProvider));
});

final goalsProvider = FutureProvider<List<GoalModel>>((ref) {
  return ref.watch(goalRepositoryProvider).getGoals();
});

final goalProvider = FutureProvider.family<GoalModel, int>((ref, id) {
  return ref.watch(goalRepositoryProvider).getGoal(id);
});

class GoalActionNotifier extends Notifier<AsyncValue<String?>> {
  @override
  AsyncValue<String?> build() => const AsyncData(null);

  void _invalidate() {
    ref.invalidate(goalsProvider);
    ref.invalidate(goalProvider);
    ref.invalidate(goalAnalyticsProvider);
    ref.invalidate(dashboardProvider);
  }

  Future<GoalModel> _run(
    Future<GoalModel> Function(GoalRepository repository) action,
    String successMessage,
  ) async {
    state = const AsyncLoading();
    try {
      final goal = await action(ref.read(goalRepositoryProvider));
      _invalidate();
      state = AsyncData(successMessage);
      return goal;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<GoalModel> create({
    required String goalName,
    required double targetAmount,
    required DateTime targetDate,
  }) => _run(
    (repository) => repository.createGoal(
      goalName: goalName,
      targetAmount: targetAmount,
      targetDate: targetDate,
    ),
    'Goal created',
  );

  Future<GoalModel> update(
    int id, {
    required String goalName,
    required double targetAmount,
    required DateTime targetDate,
  }) => _run(
    (repository) => repository.updateGoal(
      id,
      goalName: goalName,
      targetAmount: targetAmount,
      targetDate: targetDate,
    ),
    'Goal updated',
  );

  Future<GoalModel> contribute(int id, double amount) => _run(
    (repository) => repository.contribute(id, amount),
    'Contribution added',
  );

  Future<void> delete(int id) async {
    state = const AsyncLoading();
    try {
      await ref.read(goalRepositoryProvider).deleteGoal(id);
      _invalidate();
      state = const AsyncData('Goal deleted');
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

final goalActionProvider =
    NotifierProvider<GoalActionNotifier, AsyncValue<String?>>(
      GoalActionNotifier.new,
    );
