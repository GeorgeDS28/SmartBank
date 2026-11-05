import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbank/core/network/providers.dart';
import 'package:smartbank/features/account/presentation/providers/accounts_provider.dart';
import 'package:smartbank/features/transaction/data/models/money_models.dart';
import 'package:smartbank/features/transaction/data/models/transaction_model.dart';
import 'package:smartbank/features/transaction/data/repositories/transaction_repository_impl.dart';
import 'package:smartbank/features/transaction/domain/repositories/transaction_repository.dart';
import 'package:smartbank/features/user/presentation/providers/dashboard_provider.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  ref.watch(sessionIdProvider);
  return TransactionRepositoryImpl(
    ref.watch(apiClientProvider),
    ref.watch(accountRepositoryProvider),
  );
});

final transactionsProvider = FutureProvider<List<TransactionModel>>((ref) {
  return ref.watch(transactionRepositoryProvider).getTransactions();
});

class MoneyActionNotifier extends Notifier<AsyncValue<String?>> {
  @override
  AsyncValue<String?> build() => const AsyncData(null);

  void _invalidateBalances() {
    ref.invalidate(accountsProvider);
    ref.invalidate(accountProvider);
    ref.invalidate(accountTransactionsProvider);
    ref.invalidate(transactionsProvider);
    ref.invalidate(dashboardProvider);
  }

  Future<String> deposit({
    required String accountNumber,
    required double amount,
    required String pin,
  }) async {
    state = const AsyncLoading();
    try {
      final DepositResult result = await ref
          .read(transactionRepositoryProvider)
          .deposit(accountNumber: accountNumber, amount: amount, pin: pin);
      _invalidateBalances();
      state = AsyncData(result.message);
      return result.message;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<String> withdraw({
    required String accountNumber,
    required double amount,
    required String pin,
  }) async {
    state = const AsyncLoading();
    try {
      final WithdrawResult result = await ref
          .read(transactionRepositoryProvider)
          .withdraw(accountNumber: accountNumber, amount: amount, pin: pin);
      _invalidateBalances();
      state = AsyncData(result.message);
      return result.message;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<String> transfer({
    required String fromAccountNumber,
    required String toAccountNumber,
    required double amount,
    required String pin,
    String? description,
  }) async {
    state = const AsyncLoading();
    try {
      final TransferResult result = await ref
          .read(transactionRepositoryProvider)
          .transfer(
            fromAccountNumber: fromAccountNumber,
            toAccountNumber: toAccountNumber,
            amount: amount,
            pin: pin,
            description: description,
          );
      _invalidateBalances();
      state = AsyncData(result.message);
      return result.message;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

final moneyActionProvider =
    NotifierProvider<MoneyActionNotifier, AsyncValue<String?>>(
      MoneyActionNotifier.new,
    );
