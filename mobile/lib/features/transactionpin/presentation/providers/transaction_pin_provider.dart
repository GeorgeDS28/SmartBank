import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbank/core/network/providers.dart';
import 'package:smartbank/features/transactionpin/data/models/pin_status_model.dart';
import 'package:smartbank/features/transactionpin/data/repositories/transaction_pin_repository_impl.dart';
import 'package:smartbank/features/transactionpin/domain/repositories/transaction_pin_repository.dart';

final transactionPinRepositoryProvider = Provider<TransactionPinRepository>((
  ref,
) {
  ref.watch(sessionIdProvider);
  return TransactionPinRepositoryImpl(ref.watch(apiClientProvider));
});

final pinStatusProvider = FutureProvider<PinStatusModel>((ref) {
  return ref.watch(transactionPinRepositoryProvider).getStatus();
});

class PinActionNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> setup({required String pin, required String confirmPin}) =>
      _run((repository) => repository.setup(pin: pin, confirmPin: confirmPin));

  Future<void> change({
    required String currentPin,
    required String newPin,
    required String confirmNewPin,
  }) => _run(
    (repository) => repository.change(
      currentPin: currentPin,
      newPin: newPin,
      confirmNewPin: confirmNewPin,
    ),
  );

  Future<void> reset({
    required String password,
    required String newPin,
    required String confirmNewPin,
  }) => _run(
    (repository) => repository.reset(
      password: password,
      newPin: newPin,
      confirmNewPin: confirmNewPin,
    ),
  );

  /// The backend hashes the PIN and answers only with a status, so nothing is
  /// kept in state - and the entered value never leaves this call.
  Future<void> _run(
    Future<void> Function(TransactionPinRepository repository) action,
  ) async {
    state = const AsyncLoading();
    try {
      await action(ref.read(transactionPinRepositoryProvider));
      ref.invalidate(pinStatusProvider);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

final pinActionProvider = NotifierProvider<PinActionNotifier, AsyncValue<void>>(
  PinActionNotifier.new,
);
