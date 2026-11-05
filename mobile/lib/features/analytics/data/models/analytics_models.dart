class FinancialSummaryModel {
  final double totalBalance;
  final double totalDeposits;
  final double totalWithdrawals;
  final double totalTransferredIn;
  final double totalTransferredOut;
  final double netCashFlow;
  final double totalGoalSavings;

  const FinancialSummaryModel({
    required this.totalBalance,
    required this.totalDeposits,
    required this.totalWithdrawals,
    required this.totalTransferredIn,
    required this.totalTransferredOut,
    required this.netCashFlow,
    required this.totalGoalSavings,
  });

  /// Money that left the account, counting withdrawals and outbound transfers.
  double get totalOutflow => totalWithdrawals + totalTransferredOut;

  /// Money that arrived, counting deposits and inbound transfers.
  double get totalInflow => totalDeposits + totalTransferredIn;

  factory FinancialSummaryModel.fromJson(Map<String, dynamic> json) {
    double read(String key) => (json[key] as num?)?.toDouble() ?? 0;

    return FinancialSummaryModel(
      totalBalance: read('totalBalance'),
      totalDeposits: read('totalDeposits'),
      totalWithdrawals: read('totalWithdrawals'),
      totalTransferredIn: read('totalTransferredIn'),
      totalTransferredOut: read('totalTransferredOut'),
      netCashFlow: read('netCashFlow'),
      totalGoalSavings: read('totalGoalSavings'),
    );
  }
}

class MonthlyActivityModel {
  final String month;
  final double deposits;
  final double withdrawals;
  final double transfersIn;
  final double transfersOut;

  const MonthlyActivityModel({
    required this.month,
    required this.deposits,
    required this.withdrawals,
    required this.transfersIn,
    required this.transfersOut,
  });

  double get inflow => deposits + transfersIn;
  double get outflow => withdrawals + transfersOut;

  factory MonthlyActivityModel.fromJson(Map<String, dynamic> json) {
    double read(String key) => (json[key] as num?)?.toDouble() ?? 0;

    return MonthlyActivityModel(
      month: json['month'] as String? ?? '',
      deposits: read('deposits'),
      withdrawals: read('withdrawals'),
      transfersIn: read('transfersIn'),
      transfersOut: read('transfersOut'),
    );
  }
}

class GoalAnalyticsModel {
  final int totalGoals;
  final int activeGoals;
  final int completedGoals;
  final double totalTargetAmount;
  final double totalSavedAmount;
  final double overallProgress;

  const GoalAnalyticsModel({
    required this.totalGoals,
    required this.activeGoals,
    required this.completedGoals,
    required this.totalTargetAmount,
    required this.totalSavedAmount,
    required this.overallProgress,
  });

  factory GoalAnalyticsModel.fromJson(Map<String, dynamic> json) {
    double readDouble(String key) => (json[key] as num?)?.toDouble() ?? 0;
    int readInt(String key) => (json[key] as num?)?.toInt() ?? 0;

    return GoalAnalyticsModel(
      totalGoals: readInt('totalGoals'),
      activeGoals: readInt('activeGoals'),
      completedGoals: readInt('completedGoals'),
      totalTargetAmount: readDouble('totalTargetAmount'),
      totalSavedAmount: readDouble('totalSavedAmount'),
      overallProgress: readDouble('overallProgress'),
    );
  }
}

class TransferAnalyticsModel {
  final int totalTransfers;
  final double totalTransferredIn;
  final double totalTransferredOut;
  final double netTransferAmount;

  const TransferAnalyticsModel({
    required this.totalTransfers,
    required this.totalTransferredIn,
    required this.totalTransferredOut,
    required this.netTransferAmount,
  });

  factory TransferAnalyticsModel.fromJson(Map<String, dynamic> json) {
    double readDouble(String key) => (json[key] as num?)?.toDouble() ?? 0;

    return TransferAnalyticsModel(
      totalTransfers: (json['totalTransfers'] as num?)?.toInt() ?? 0,
      totalTransferredIn: readDouble('totalTransferredIn'),
      totalTransferredOut: readDouble('totalTransferredOut'),
      netTransferAmount: readDouble('netTransferAmount'),
    );
  }
}
