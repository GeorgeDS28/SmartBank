import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbank/core/network/providers.dart';
import 'package:smartbank/features/account/data/repositories/account_repository_impl.dart';
import 'package:smartbank/features/account/domain/repositories/account_repository.dart';
import 'package:smartbank/features/transaction/data/models/transaction_model.dart';
import 'package:smartbank/features/transaction/presentation/providers/transactions_provider.dart';
import 'package:smartbank/features/user/data/models/account_model.dart';
import 'package:smartbank/features/user/presentation/providers/dashboard_provider.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  ref.watch(sessionIdProvider);
  return AccountRepositoryImpl(ref.watch(apiClientProvider));
});

final accountsProvider = FutureProvider<List<AccountModel>>((ref) {
  return ref.watch(accountRepositoryProvider).getAccounts();
});

final accountProvider = FutureProvider.family<AccountModel, String>((
  ref,
  accountNumber,
) {
  return ref.watch(accountRepositoryProvider).getAccount(accountNumber);
});

final accountTransactionsProvider =
    FutureProvider.family<List<TransactionModel>, String>((ref, accountNumber) {
      return ref
          .watch(accountRepositoryProvider)
          .getTransactions(accountNumber);
    });

class AccountActionNotifier extends Notifier<AsyncValue<AccountModel?>> {
  @override
  AsyncValue<AccountModel?> build() => const AsyncData(null);

  Future<AccountModel> create(String accountType) async {
    state = const AsyncLoading();
    try {
      final account = await ref
          .read(accountRepositoryProvider)
          .createAccount(accountType);
      state = AsyncData(account);
      _refresh();
      return account;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<AccountModel> close(String accountNumber) async {
    state = const AsyncLoading();
    try {
      final account = await ref
          .read(accountRepositoryProvider)
          .closeAccount(accountNumber);
      state = AsyncData(account);
      _refresh();
      return account;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  /// The backend owns the balances, so every screen re-reads them rather than
  /// keeping a locally edited copy of a closed account.
  void _refresh() {
    ref.invalidate(accountsProvider);
    ref.invalidate(accountProvider);
    ref.invalidate(accountTransactionsProvider);
    ref.invalidate(transactionsProvider);
    ref.invalidate(dashboardProvider);
  }
}

final accountActionProvider =
    NotifierProvider<AccountActionNotifier, AsyncValue<AccountModel?>>(
      AccountActionNotifier.new,
    );
