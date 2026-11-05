import 'package:smartbank/core/network/api_client.dart';
import 'package:smartbank/core/network/api_exception.dart';
import 'package:smartbank/features/transactionpin/data/models/pin_status_model.dart';
import 'package:smartbank/features/transactionpin/domain/repositories/transaction_pin_repository.dart';

class TransactionPinRepositoryImpl implements TransactionPinRepository {
  static const _base = '/api/transaction-pin';

  final ApiClient _apiClient;

  TransactionPinRepositoryImpl(this._apiClient);

  @override
  Future<PinStatusModel> getStatus() async {
    try {
      final response = await _apiClient.dio.get('$_base/status');
      return PinStatusModel.fromJson(response.data as Map<String, dynamic>);
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  @override
  Future<void> setup({required String pin, required String confirmPin}) async {
    try {
      await _apiClient.dio.post(
        '$_base/setup',
        data: {'pin': pin, 'confirmPin': confirmPin},
      );
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  @override
  Future<void> change({
    required String currentPin,
    required String newPin,
    required String confirmNewPin,
  }) async {
    try {
      await _apiClient.dio.put(
        '$_base/change',
        data: {
          'currentPin': currentPin,
          'newPin': newPin,
          'confirmNewPin': confirmNewPin,
        },
      );
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  @override
  Future<void> reset({
    required String password,
    required String newPin,
    required String confirmNewPin,
  }) async {
    try {
      await _apiClient.dio.put(
        '$_base/reset',
        data: {
          'password': password,
          'newPin': newPin,
          'confirmNewPin': confirmNewPin,
        },
      );
    } catch (error) {
      throw ApiException.from(error);
    }
  }
}
