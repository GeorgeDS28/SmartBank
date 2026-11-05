import 'package:smartbank/core/network/api_client.dart';
import 'package:smartbank/core/network/api_exception.dart';
import 'package:smartbank/features/account/domain/repositories/account_repository.dart';
import 'package:smartbank/features/transaction/data/models/transaction_model.dart';
import 'package:smartbank/features/user/data/models/account_model.dart';

class AccountRepositoryImpl implements AccountRepository {
  final ApiClient _apiClient;

  AccountRepositoryImpl(this._apiClient);

  @override
  Future<List<AccountModel>> getAccounts() async {
    try {
      final response = await _apiClient.dio.get('/api/accounts');
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => AccountModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  @override
  Future<AccountModel> getAccount(String accountNumber) async {
    try {
      final response = await _apiClient.dio.get('/api/accounts/$accountNumber');
      return AccountModel.fromJson(response.data as Map<String, dynamic>);
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  @override
  Future<AccountModel> createAccount(String accountType) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/accounts',
        data: {'accountType': accountType},
      );
      return AccountModel.fromJson(response.data as Map<String, dynamic>);
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  @override
  Future<AccountModel> closeAccount(String accountNumber) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/accounts/$accountNumber/close',
      );
      return AccountModel.fromJson(response.data as Map<String, dynamic>);
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  @override
  Future<List<TransactionModel>> getTransactions(String accountNumber) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/accounts/$accountNumber/transactions',
      );
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map(
            (json) => TransactionModel.fromJson(
              json as Map<String, dynamic>,
              accountNumber: accountNumber,
            ),
          )
          .toList();
    } catch (error) {
      throw ApiException.from(error);
    }
  }
}
