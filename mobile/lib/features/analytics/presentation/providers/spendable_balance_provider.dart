import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbank/features/account/presentation/providers/accounts_provider.dart';
import 'package:smartbank/features/goal/presentation/providers/goals_provider.dart';

/// The envelope the backend reserves money against: everything on the active
/// accounts minus what the savings goals already hold a claim on.
class SpendableBalance {
  final double totalBalance;
  final double reservedInGoals;

  const SpendableBalance({
    required this.totalBalance,
    required this.reservedInGoals,
  });

  double get available => totalBalance - reservedInGoals;

  /// Goals created before the reservation rule can claim more than the accounts
  /// hold. The backend releases nothing in that case, so the app never shows a
  /// negative amount as if it were spendable.
  double get spendable => available < 0 ? 0 : available;

  bool get isOverReserved => available < 0;

  bool covers(double amount) => spendable >= amount - 0.0001;
}

final spendableBalanceProvider = FutureProvider<SpendableBalance>((ref) async {
  final accounts = await ref.watch(accountsProvider.future);
  final goals = await ref.watch(goalsProvider.future);

  final total = accounts
      .where((account) => account.status == 'ACTIVE')
      .fold<double>(0, (sum, account) => sum + account.balance);

  final reserved = goals
      .where((goal) => goal.status != 'CANCELLED')
      .fold<double>(0, (sum, goal) => sum + goal.currentAmount);

  return SpendableBalance(totalBalance: total, reservedInGoals: reserved);
});
