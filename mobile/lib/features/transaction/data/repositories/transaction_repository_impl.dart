import 'package:smartbank/core/network/api_client.dart';
import 'package:smartbank/core/network/api_exception.dart';
import 'package:smartbank/features/account/domain/repositories/account_repository.dart';
import 'package:smartbank/features/transaction/data/models/money_models.dart';
import 'package:smartbank/features/transaction/data/models/transaction_model.dart';
import 'package:smartbank/features/transaction/domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final ApiClient _apiClient;
  final AccountRepository _accountRepository;

  TransactionRepositoryImpl(this._apiClient, this._accountRepository);

  @override
  Future<List<TransactionModel>> getTransactions({
    String? accountNumber,
  }) async {
    try {
      if (accountNumber != null && accountNumber.isNotEmpty) {
        return await _accountRepository.getTransactions(accountNumber);
      }

      final accounts = await _accountRepository.getAccounts();
      final grouped = await Future.wait(
        accounts.map(
          (account) =>
              _accountRepository.getTransactions(account.accountNumber),
        ),
      );

      final all = grouped.expand((list) => list).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return all;
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  @override
  Future<DepositResult> deposit({
    required String accountNumber,
    required double amount,
    required String pin,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/accounts/$accountNumber/deposit',
        data: {'amount': amount, 'pin': pin},
      );
      return DepositResult.fromJson(response.data as Map<String, dynamic>);
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  @override
  Future<WithdrawResult> withdraw({
    required String accountNumber,
    required double amount,
    required String pin,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/accounts/$accountNumber/withdraw',
        data: {'amount': amount, 'pin': pin},
      );
      return WithdrawResult.fromJson(response.data as Map<String, dynamic>);
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  @override
  Future<TransferResult> transfer({
    required String fromAccountNumber,
    required String toAccountNumber,
    required double amount,
    required String pin,
    String? description,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/accounts/transfer',
        data: {
          'fromAccountNumber': fromAccountNumber,
          'toAccountNumber': toAccountNumber,
          'amount': amount,
          'pin': pin,
          if (description != null && description.isNotEmpty)
            'description': description,
        },
      );
      return TransferResult.fromJson(response.data as Map<String, dynamic>);
    } catch (error) {
      throw ApiException.from(error);
    }
  }
}
