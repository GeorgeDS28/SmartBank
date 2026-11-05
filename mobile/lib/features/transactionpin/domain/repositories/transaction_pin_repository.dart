import 'package:smartbank/features/transactionpin/data/models/pin_status_model.dart';

/// The backend exposes no endpoint that verifies a PIN on its own; a PIN is
/// checked by attempting the transaction that needs it.
abstract class TransactionPinRepository {
  Future<PinStatusModel> getStatus();

  Future<void> setup({required String pin, required String confirmPin});

  Future<void> change({
    required String currentPin,
    required String newPin,
    required String confirmNewPin,
  });

  /// For a forgotten PIN: the backend re-checks the login password before it
  /// accepts a new PIN and clears any lock.
  Future<void> reset({
    required String password,
    required String newPin,
    required String confirmNewPin,
  });
}
