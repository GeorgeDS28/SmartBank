import 'package:smartbank/features/transaction/data/models/transaction_model.dart';
import 'package:smartbank/features/user/data/models/account_model.dart';

abstract class AccountRepository {
  Future<List<AccountModel>> getAccounts();

  Future<AccountModel> getAccount(String accountNumber);

  Future<AccountModel> createAccount(String accountType);

  Future<AccountModel> closeAccount(String accountNumber);

  Future<List<TransactionModel>> getTransactions(String accountNumber);
}
