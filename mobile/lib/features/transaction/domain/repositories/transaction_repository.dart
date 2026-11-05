import 'package:smartbank/features/transaction/data/models/money_models.dart';
import 'package:smartbank/features/transaction/data/models/transaction_model.dart';

abstract class TransactionRepository {
  Future<List<TransactionModel>> getTransactions({String? accountNumber});

  /// Every money movement needs the transaction PIN; the backend declines the
  /// request without it.
  Future<DepositResult> deposit({
    required String accountNumber,
    required double amount,
    required String pin,
  });

  Future<WithdrawResult> withdraw({
    required String accountNumber,
    required double amount,
    required String pin,
  });

  Future<TransferResult> transfer({
    required String fromAccountNumber,
    required String toAccountNumber,
    required double amount,
    required String pin,
    String? description,
  });
}
