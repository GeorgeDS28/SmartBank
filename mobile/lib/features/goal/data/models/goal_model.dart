class GoalModel {
  final int id;
  final String goalName;
  final double targetAmount;
  final double currentAmount;
  final int progressPercentage;
  final String status;
  final DateTime targetDate;
  final DateTime createdAt;

  const GoalModel({
    required this.id,
    required this.goalName,
    required this.targetAmount,
    required this.currentAmount,
    required this.progressPercentage,
    required this.status,
    required this.targetDate,
    required this.createdAt,
  });

  double get progressRatio => targetAmount <= 0
      ? 0
      : (currentAmount / targetAmount).clamp(0.0, 1.0).toDouble();

  double get remainingAmount =>
      (targetAmount - currentAmount) < 0 ? 0 : targetAmount - currentAmount;

  bool get isCompleted => status == 'COMPLETED';

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      id: (json['id'] as num).toInt(),
      goalName: json['goalName'] as String? ?? '',
      targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 0,
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0,
      progressPercentage: (json['progressPercentage'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'IN_PROGRESS',
      targetDate: DateTime.parse(json['targetDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
