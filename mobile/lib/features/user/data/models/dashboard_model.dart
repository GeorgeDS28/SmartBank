//dashboard_model.dart

import 'package:smartbank/features/transaction/data/models/transaction_model.dart';

class DashboardModel {
  final double totalBalance;
  final int numberOfAccounts;
  final int totalTransactions;
  final List<RecentTransactionModel> recentTransactions;

  DashboardModel({
    required this.totalBalance,
    required this.numberOfAccounts,
    required this.totalTransactions,
    required this.recentTransactions,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      totalBalance: (json['totalBalance'] ?? 0).toDouble(),
      numberOfAccounts: json['numberOfAccounts'] ?? 0,
      totalTransactions: json['totalTransactions'] ?? 0,
      recentTransactions: (json['recentTransactions'] as List<dynamic>? ?? [])
          .map((transaction) => RecentTransactionModel.fromJson(transaction))
          .toList(),
    );
  }
}

class RecentTransactionModel {
  final String transactionReference;
  final String transactionType;
  final double amount;
  final String description;
  final String accountNumber;
  final DateTime createdAt;

  RecentTransactionModel({
    required this.transactionReference,
    required this.transactionType,
    required this.amount,
    required this.description,
    required this.accountNumber,
    required this.createdAt,
  });

  factory RecentTransactionModel.fromJson(Map<String, dynamic> json) {
    return RecentTransactionModel(
      transactionReference: json['transactionReference'] ?? '',
      transactionType: json['transactionType'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  /// The dashboard payload carries the same fields as the transaction list
  /// response plus the owning account, so tiles can be reused unchanged.
  TransactionModel toModel() => TransactionModel(
    transactionReference: transactionReference,
    transactionType: transactionType,
    amount: amount,
    description: description,
    createdAt: createdAt,
    accountNumber: accountNumber.isEmpty ? null : accountNumber,
  );
}
