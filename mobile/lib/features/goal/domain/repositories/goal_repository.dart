import 'package:smartbank/features/goal/data/models/goal_model.dart';

abstract class GoalRepository {
  Future<List<GoalModel>> getGoals();

  Future<GoalModel> getGoal(int id);

  Future<GoalModel> createGoal({
    required String goalName,
    required double targetAmount,
    required DateTime targetDate,
  });

  Future<GoalModel> updateGoal(
    int id, {
    required String goalName,
    required double targetAmount,
    required DateTime targetDate,
  });

  Future<GoalModel> contribute(int id, double amount);

  Future<void> deleteGoal(int id);
}
