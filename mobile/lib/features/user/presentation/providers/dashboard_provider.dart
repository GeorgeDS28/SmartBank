import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbank/core/network/providers.dart';
import 'package:smartbank/features/user/data/models/dashboard_model.dart';
import 'package:smartbank/features/user/data/repositories/user_repository_impl.dart';
import 'package:smartbank/features/user/domain/repositories/user_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  ref.watch(sessionIdProvider);
  return UserRepositoryImpl(ref.watch(apiClientProvider));
});

final dashboardProvider = FutureProvider<DashboardModel>((ref) {
  return ref.watch(userRepositoryProvider).getDashboard();
});
