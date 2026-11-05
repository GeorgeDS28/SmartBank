class TransactionModel {
  final String transactionReference;
  final String transactionType;
  final double amount;
  final String description;
  final DateTime createdAt;
  final String? accountNumber;

  const TransactionModel({
    required this.transactionReference,
    required this.transactionType,
    required this.amount,
    required this.description,
    required this.createdAt,
    this.accountNumber,
  });

  factory TransactionModel.fromJson(
    Map<String, dynamic> json, {
    String? accountNumber,
  }) {
    return TransactionModel(
      transactionReference: json['transactionReference'] as String? ?? '',
      transactionType: json['transactionType'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      description: json['description'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      accountNumber: accountNumber ?? json['accountNumber'] as String?,
    );
  }
}
