import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbank/core/network/providers.dart';
import 'package:smartbank/features/analytics/presentation/providers/spendable_balance_provider.dart';

import '../support/fakes.dart';

Map<String, dynamic> account(
  String number,
  double balance, {
  String status = 'ACTIVE',
}) => {
  'accountNumber': number,
  'accountType': 'SAVINGS',
  'balance': balance,
  'status': status,
};

Map<String, dynamic> goal(double saved, {String status = 'IN_PROGRESS'}) => {
  'id': 1,
  'goalName': 'Emergency fund',
  'targetAmount': 2000,
  'currentAmount': saved,
  'progressPercentage': 45,
  'status': status,
  'targetDate': '2027-01-01',
  'createdAt': '2026-01-01',
};

void main() {
  Future<SpendableBalance> readBalance(
    List<Map<String, dynamic>> accounts,
    List<Map<String, dynamic>> goals,
  ) async {
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(
          buildFakeClient({
            'GET /api/accounts': StubbedResponse.ok(accounts),
            'GET /api/goals': StubbedResponse.ok(goals),
          }),
        ),
        tokenStorageProvider.overrideWithValue(FakeTokenStorage(token: 'jwt')),
      ],
    );
    addTearDown(container.dispose);

    return container.read(spendableBalanceProvider.future);
  }

  group('spendableBalanceProvider', () {
    test('goals take their share before anything is spendable', () async {
      final balance = await readBalance(
        [account('SB11111111', 1000)],
        [goal(900)],
      );

      expect(balance.totalBalance, 1000);
      expect(balance.reservedInGoals, 900);
      expect(balance.available, closeTo(100, 0.001));
      expect(balance.covers(250), isFalse);
      expect(balance.covers(100), isTrue);
    });

    test(
      'a closed account backs nothing, even though its history remains',
      () async {
        final balance = await readBalance(
          [
            account('SB11111111', 1000),
            account('SB22222222', 5000, status: 'CLOSED'),
          ],
          [goal(400)],
        );

        expect(balance.totalBalance, 1000);
        expect(balance.available, closeTo(600, 0.001));
      },
    );

    test('a cancelled goal frees its money again', () async {
      final balance = await readBalance(
        [account('SB11111111', 1000)],
        [goal(900, status: 'CANCELLED')],
      );

      expect(balance.reservedInGoals, 0);
      expect(balance.available, closeTo(1000, 0.001));
    });

    test('goals older than the balances leave nothing spendable', () async {
      final balance = await readBalance(
        [account('SB11111111', 1000)],
        [goal(2400)],
      );

      expect(balance.available, closeTo(-1400, 0.001));
      expect(balance.spendable, 0);
      expect(balance.isOverReserved, isTrue);
      expect(balance.covers(1), isFalse);
    });
  });
}
