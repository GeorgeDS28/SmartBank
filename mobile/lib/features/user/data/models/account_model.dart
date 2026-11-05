//lib/features/user/data/models/account_model.dart
//account_model.dart

class AccountModel {
  final String accountNumber;
  final String accountType;
  final double balance;
  final String status;

  AccountModel({
    required this.accountNumber,
    required this.accountType,
    required this.balance,
    required this.status,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      accountNumber: json['accountNumber'] as String,
      accountType: json['accountType'] as String,
      balance: (json['balance'] as num).toDouble(),
      status: json['status'] as String,
    );
  }
}
