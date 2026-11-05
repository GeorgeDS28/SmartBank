class DepositResult {
  final String accountNumber;
  final double depositedAmount;
  final double currentBalance;
  final String message;

  const DepositResult({
    required this.accountNumber,
    required this.depositedAmount,
    required this.currentBalance,
    required this.message,
  });

  factory DepositResult.fromJson(Map<String, dynamic> json) {
    return DepositResult(
      accountNumber: json['accountNumber'] as String? ?? '',
      depositedAmount: (json['depositedAmount'] as num?)?.toDouble() ?? 0,
      currentBalance: (json['currentBalance'] as num?)?.toDouble() ?? 0,
      message: json['message'] as String? ?? 'Deposit successful',
    );
  }
}

class WithdrawResult {
  final String message;
  final String accountNumber;
  final double withdrawnAmount;
  final double updatedBalance;

  const WithdrawResult({
    required this.message,
    required this.accountNumber,
    required this.withdrawnAmount,
    required this.updatedBalance,
  });

  factory WithdrawResult.fromJson(Map<String, dynamic> json) {
    return WithdrawResult(
      message: json['message'] as String? ?? 'Withdrawal successful',
      accountNumber: json['accountNumber'] as String? ?? '',
      withdrawnAmount: (json['withdrawnAmount'] as num?)?.toDouble() ?? 0,
      updatedBalance: (json['updatedBalance'] as num?)?.toDouble() ?? 0,
    );
  }
}

class TransferResult {
  final String message;
  final String fromAccountNumber;
  final String toAccountNumber;
  final double amount;

  const TransferResult({
    required this.message,
    required this.fromAccountNumber,
    required this.toAccountNumber,
    required this.amount,
  });

  factory TransferResult.fromJson(Map<String, dynamic> json) {
    return TransferResult(
      message: json['message'] as String? ?? 'Transfer successful',
      fromAccountNumber: json['fromAccountNumber'] as String? ?? '',
      toAccountNumber: json['toAccountNumber'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }
}
