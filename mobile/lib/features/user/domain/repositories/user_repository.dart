//user_repository.dart
import 'package:smartbank/features/user/data/models/dashboard_model.dart';
import 'package:smartbank/features/user/data/models/user_profile.dart';

import 'package:smartbank/features/user/data/models/account_model.dart';

abstract class UserRepository {
  Future<UserProfile> getProfile();

  Future<DashboardModel> getDashboard();

  Future<List<AccountModel>> getAccounts();
}
