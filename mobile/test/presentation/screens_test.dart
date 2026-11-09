import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smartbank/core/network/providers.dart';
import 'package:smartbank/features/account/presentation/pages/account_details_page.dart';
import 'package:smartbank/features/account/presentation/pages/accounts_page.dart';
import 'package:smartbank/features/account/presentation/providers/accounts_provider.dart';
import 'package:smartbank/features/auth/presentation/pages/change_password_page.dart';
import 'package:smartbank/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:smartbank/features/auth/presentation/pages/reset_password_page.dart';
import 'package:smartbank/features/goal/presentation/pages/goals_page.dart';
import 'package:smartbank/features/goal/presentation/providers/goals_provider.dart';
import 'package:smartbank/features/user/presentation/pages/profile_page.dart';
import 'package:smartbank/features/transaction/presentation/pages/new_transaction_page.dart';
import 'package:smartbank/features/transaction/presentation/pages/transactions_page.dart';
import 'package:smartbank/features/transaction/presentation/providers/transactions_provider.dart';
import 'package:smartbank/features/transactionpin/presentation/pages/pin_reset_page.dart';
import 'package:smartbank/features/transactionpin/presentation/pages/transaction_pin_page.dart';

import '../support/fakes.dart';

/// Builds a ProviderScope wired to the fake adapter and a fake token store so
/// no screen touches the network or platform channels.
Widget wrap(
  Widget page, {
  required Map<String, StubbedResponse> stubs,
  String token = 'jwt',
}) {
  final client = buildFakeClient(stubs);

  return ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(client),
      tokenStorageProvider.overrideWithValue(FakeTokenStorage(token: token)),
    ],
    child: MaterialApp(home: page),
  );
}

/// Password recovery spans two screens that push each other, so the tests run
/// against a router that carries the real '/forgot-password' and
/// '/reset-password' locations.
Future<FakeApiAdapter> pumpRecoveryRoute(
  WidgetTester tester,
  Map<String, StubbedResponse> stubs,
  String start,
) async {
  final client = buildFakeClient(stubs);
  final container = ProviderContainer(
    overrides: [
      apiClientProvider.overrideWithValue(client),
      tokenStorageProvider.overrideWithValue(FakeTokenStorage(token: null)),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: start,
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const SizedBox.shrink(),
              routes: [
                GoRoute(
                  path: 'login',
                  builder: (context, state) => const SizedBox.shrink(),
                ),
                GoRoute(
                  path: 'forgot-password',
                  builder: (context, state) => const ForgotPasswordPage(),
                ),
                GoRoute(
                  path: 'reset-password',
                  builder: (context, state) => ResetPasswordPage(
                    email: state.extra is String ? state.extra! as String : '',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return client.dio.httpClientAdapter as FakeApiAdapter;
}

void main() {
  group('AccountsPage', () {
    testWidgets('renders real account data with masked numbers', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const AccountsPage(),
          stubs: {
            'GET /api/accounts': const StubbedResponse.ok([
              {
                'accountNumber': 'SB12345678',
                'accountType': 'SAVINGS',
                'balance': 12450.6,
                'status': 'ACTIVE',
              },
            ]),
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Savings'), findsOneWidget);
      expect(find.text('••••5678'), findsOneWidget);
      // Rendered both as the aggregate balance and on the account card.
      expect(find.text('\$12,450.60'), findsWidgets);
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('shows the empty state when the user has no accounts', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const AccountsPage(),
          stubs: {'GET /api/accounts': const StubbedResponse.ok([])},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('no accounts yet'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Open account'), findsOneWidget);
    });

    testWidgets('shows a retryable error when the API fails', (tester) async {
      await tester.pumpWidget(
        wrap(
          const AccountsPage(),
          stubs: {
            'GET /api/accounts': const StubbedResponse(500, {
              'message': 'Database unavailable',
            }),
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Database unavailable'), findsNothing);
      expect(
        find.textContaining('SmartBank could not complete the request'),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
    });
  });

  group('TransactionsPage', () {
    testWidgets('lists aggregated transactions across accounts', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const TransactionsPage(),
          stubs: {
            'GET /api/accounts': const StubbedResponse.ok([
              {
                'accountNumber': 'SB1',
                'accountType': 'SAVINGS',
                'balance': 100,
                'status': 'ACTIVE',
              },
            ]),
            'GET /api/accounts/SB1/transactions': const StubbedResponse.ok([
              {
                'transactionReference': 'TXN1',
                'transactionType': 'DEPOSIT',
                'amount': 5000.00,
                'description': 'Cash Deposit',
                'createdAt': '2026-06-14T09:00:00',
              },
              {
                'transactionReference': 'TXN2',
                'transactionType': 'WITHDRAW',
                'amount': 86.45,
                'description': 'Groceries',
                'createdAt': '2026-06-13T09:00:00',
              },
            ]),
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Deposit'), findsOneWidget);
      expect(find.text('Withdraw'), findsOneWidget);
      expect(find.text('+\$5,000.00'), findsOneWidget);
      expect(find.text('-\$86.45'), findsOneWidget);
    });

    testWidgets('filtering by type hides non-matching transactions', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const TransactionsPage(),
          stubs: {
            'GET /api/accounts': const StubbedResponse.ok([
              {
                'accountNumber': 'SB1',
                'accountType': 'SAVINGS',
                'balance': 100,
                'status': 'ACTIVE',
              },
            ]),
            'GET /api/accounts/SB1/transactions': const StubbedResponse.ok([
              {
                'transactionReference': 'TXN1',
                'transactionType': 'DEPOSIT',
                'amount': 100,
                'description': 'Cash Deposit',
                'createdAt': '2026-06-14T09:00:00',
              },
              {
                'transactionReference': 'TXN2',
                'transactionType': 'WITHDRAW',
                'amount': 50,
                'description': 'Cash Withdrawal',
                'createdAt': '2026-06-13T09:00:00',
              },
            ]),
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Deposits'));
      await tester.pumpAndSettle();

      expect(find.text('Deposit'), findsOneWidget);
      expect(find.text('Withdraw'), findsNothing);
    });
  });

  group('GoalsPage', () {
    testWidgets('renders goal progress from the API', (tester) async {
      await tester.pumpWidget(
        wrap(
          const GoalsPage(),
          stubs: {
            'GET /api/goals': const StubbedResponse.ok([
              {
                'id': 4,
                'goalName': 'Dream Vacation',
                'targetAmount': 3000.00,
                'currentAmount': 1500.00,
                'progressPercentage': 50,
                'status': 'IN_PROGRESS',
                'targetDate': '2026-12-31',
                'createdAt': '2026-01-01T00:00:00',
              },
            ]),
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dream Vacation'), findsOneWidget);
      expect(find.text('50% complete'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('offers creation when no goals exist', (tester) async {
      await tester.pumpWidget(
        wrap(
          const GoalsPage(),
          stubs: {'GET /api/goals': const StubbedResponse.ok([])},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('no savings goals'), findsOneWidget);
    });

    testWidgets('deletes a goal only after an explicit confirmation', (
      tester,
    ) async {
      final client = buildFakeClient({
        'GET /api/goals': const StubbedResponse.ok([
          {
            'id': 4,
            'goalName': 'Dream Vacation',
            'targetAmount': 3000.00,
            'currentAmount': 1500.00,
            'progressPercentage': 50,
            'status': 'COMPLETED',
            'targetDate': '2026-12-31',
            'createdAt': '2026-01-01T00:00:00',
          },
        ]),
        'DELETE /api/goals/4': const StubbedResponse(204, ''),
      });
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(client),
          tokenStorageProvider.overrideWithValue(
            FakeTokenStorage(token: 'jwt'),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: GoalsPage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('\$1,500.00, which becomes spendable'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(
        (client.dio.httpClientAdapter as FakeApiAdapter).log.where(
          (entry) => entry.key == 'DELETE /api/goals/4',
        ),
        isEmpty,
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Goal deleted'), findsOneWidget);
      expect(
        (client.dio.httpClientAdapter as FakeApiAdapter).log.where(
          (entry) => entry.key == 'DELETE /api/goals/4',
        ),
        hasLength(1),
      );
    });
  });

  group('AccountDetailsPage', () {
    const account = {
      'accountNumber': 'SB11111111',
      'accountType': 'SAVINGS',
      'balance': 0.0,
      'status': 'ACTIVE',
    };

    const closedAccount = {
      'accountNumber': 'SB11111111',
      'accountType': 'SAVINGS',
      'balance': 0.0,
      'status': 'CLOSED',
    };

    testWidgets('closes an account only after an explicit confirmation', (
      tester,
    ) async {
      final client = buildFakeClient({
        'GET /api/accounts/SB11111111': const StubbedResponse.ok(account),
        'GET /api/accounts/SB11111111/transactions': const StubbedResponse.ok(
          [],
        ),
        'POST /api/accounts/SB11111111/close': const StubbedResponse.ok(
          closedAccount,
        ),
      });
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(client),
          tokenStorageProvider.overrideWithValue(
            FakeTokenStorage(token: 'jwt'),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AccountDetailsPage(accountNumber: 'SB11111111'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Close account'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(
        (client.dio.httpClientAdapter as FakeApiAdapter).log.where(
          (e) => e.key.endsWith('/close'),
        ),
        isEmpty,
      );

      await tester.tap(find.byTooltip('Close account'));
      await tester.pumpAndSettle();
      expect(find.text('This cannot be undone.'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Close account'));
      await tester.pumpAndSettle();

      expect(find.text('Account closed'), findsOneWidget);
      expect(
        (client.dio.httpClientAdapter as FakeApiAdapter).log
            .where(
              (entry) => entry.key == 'POST /api/accounts/SB11111111/close',
            )
            .length,
        1,
      );
    });

    testWidgets(
      'surfaces the backend reason when an account still holds money',
      (tester) async {
        final client = buildFakeClient({
          'GET /api/accounts/SB11111111': const StubbedResponse.ok(account),
          'GET /api/accounts/SB11111111/transactions': const StubbedResponse.ok(
            [],
          ),
          'POST /api/accounts/SB11111111/close': const StubbedResponse(400, {
            'message':
                'Withdraw the remaining balance before closing this account.',
          }),
        });
        final container = ProviderContainer(
          overrides: [
            apiClientProvider.overrideWithValue(client),
            tokenStorageProvider.overrideWithValue(
              FakeTokenStorage(token: 'jwt'),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: AccountDetailsPage(accountNumber: 'SB11111111'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Close account'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Close account'));
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Withdraw the remaining balance before closing this account.',
          ),
          findsOneWidget,
        );
        expect(find.text('Account closed'), findsNothing);
      },
    );

    testWidgets('hides the close action once the account is closed', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const AccountDetailsPage(accountNumber: 'SB11111111'),
          stubs: {
            'GET /api/accounts/SB11111111': const StubbedResponse.ok(
              closedAccount,
            ),
            'GET /api/accounts/SB11111111/transactions':
                const StubbedResponse.ok([]),
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Close account'), findsNothing);
    });
  });

  group('Provider invalidation', () {
    test('a successful deposit refreshes accounts and transactions', () async {
      final client = buildFakeClient({
        'GET /api/accounts': const StubbedResponse.ok([
          {
            'accountNumber': 'SB1',
            'accountType': 'SAVINGS',
            'balance': 500,
            'status': 'ACTIVE',
          },
        ]),
        'POST /api/accounts/SB1/deposit': const StubbedResponse.ok({
          'accountNumber': 'SB1',
          'depositedAmount': 500,
          'currentBalance': 1000.00,
          'message': 'Deposit successful',
        }),
        'GET /api/analytics/dashboard': const StubbedResponse.ok({
          'totalBalance': 1000,
          'numberOfAccounts': 1,
          'totalTransactions': 1,
          'recentTransactions': [],
        }),
      });

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(client),
          tokenStorageProvider.overrideWithValue(
            FakeTokenStorage(token: 'jwt'),
          ),
        ],
      );
      addTearDown(container.dispose);

      // First read populates the accounts cache.
      await container.read(accountsProvider.future);
      expect(container.read(accountsProvider).value!.single.balance, 500);

      await container
          .read(moneyActionProvider.notifier)
          .deposit(accountNumber: 'SB1', amount: 500, pin: '246810');

      await container.read(accountsProvider.future);
      final calls = (client.dio.httpClientAdapter as FakeApiAdapter).log
          .map((entry) => entry.key)
          .toList();

      // The deposit must invalidate the accounts cache, so the list is
      // requested again rather than reusing the stale balance.
      expect(
        calls.where((call) => call == 'GET /api/accounts').length,
        greaterThan(1),
      );
      expect(calls, contains('POST /api/accounts/SB1/deposit'));
    });

    test('goal creation invalidates the goals list', () async {
      final client = buildFakeClient({
        'GET /api/goals': const StubbedResponse.ok([]),
        'POST /api/goals': const StubbedResponse(201, {
          'id': 9,
          'goalName': 'New Laptop',
          'targetAmount': 1500,
          'currentAmount': 0,
          'progressPercentage': 0,
          'status': 'IN_PROGRESS',
          'targetDate': '2026-06-30',
          'createdAt': '2026-01-01T00:00:00',
        }),
        'GET /api/analytics/goals': const StubbedResponse.ok({
          'totalGoals': 1,
          'activeGoals': 1,
          'completedGoals': 0,
          'totalTargetAmount': 1500,
          'totalSavedAmount': 0,
          'overallProgress': 0,
        }),
        'GET /api/analytics/dashboard': const StubbedResponse.ok({
          'totalBalance': 0,
          'numberOfAccounts': 0,
          'totalTransactions': 0,
          'recentTransactions': [],
        }),
      });

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(client),
          tokenStorageProvider.overrideWithValue(
            FakeTokenStorage(token: 'jwt'),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(await container.read(goalsProvider.future), isEmpty);

      await container
          .read(goalActionProvider.notifier)
          .create(
            goalName: 'New Laptop',
            targetAmount: 1500,
            targetDate: DateTime(2026, 6, 30),
          );

      // Invalidation only marks the cache dirty; the list is re-requested on
      // the next read.
      await container.read(goalsProvider.future);

      final calls = (client.dio.httpClientAdapter as FakeApiAdapter).log
          .map((entry) => entry.key)
          .toList();

      expect(calls, contains('POST /api/goals'));
      expect(
        calls.where((call) => call == 'GET /api/goals').length,
        greaterThan(1),
        reason: 'the list must be re-fetched after a create',
      );
    });
  });

  group('NewTransactionPage', () {
    const ownAccounts = [
      {
        'accountNumber': 'SB11111111',
        'accountType': 'SAVINGS',
        'balance': 1000,
        'status': 'ACTIVE',
      },
    ];

    testWidgets(
      'transfers to an account the user does not own, by typed number',
      (tester) async {
        final client = buildFakeClient({
          'GET /api/accounts': const StubbedResponse.ok(ownAccounts),
          'GET /api/goals': const StubbedResponse.ok([]),
          'GET /api/transaction-pin/status': const StubbedResponse.ok({
            'pinConfigured': true,
            'message': 'Transaction PIN already configured',
          }),
          'POST /api/accounts/transfer': const StubbedResponse.ok({
            'message': 'Transfer successful',
            'fromAccountNumber': 'SB11111111',
            'toAccountNumber': 'SB22222222',
            'amount': 250,
          }),
        });

        final container = ProviderContainer(
          overrides: [
            apiClientProvider.overrideWithValue(client),
            tokenStorageProvider.overrideWithValue(
              FakeTokenStorage(token: 'jwt'),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              routerConfig: GoRouter(
                initialLocation: '/transactions/new',
                routes: [
                  GoRoute(
                    path: '/',
                    builder: (context, state) => const SizedBox.shrink(),
                    routes: [
                      GoRoute(
                        path: 'transactions/new',
                        builder: (context, state) => const NewTransactionPage(
                          initialAction: MoneyAction.transfer,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // The destination is a free-text field, not a list of own accounts,
        // because GET /api/accounts only ever returns the caller's accounts.
        expect(find.text('To account number'), findsOneWidget);
        await tester.enterText(
          find.widgetWithText(TextFormField, 'To account number'),
          'sb22222222',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Amount'),
          '250',
        );

        await tester.tap(find.widgetWithText(FilledButton, 'Transfer'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
        await tester.pumpAndSettle();

        // Money only moves once the transaction PIN is supplied.
        expect(find.text('Transaction PIN'), findsOneWidget);
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Transaction PIN'),
          '246810',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
        await tester.pumpAndSettle();

        final request = (client.dio.httpClientAdapter as FakeApiAdapter).log
            .firstWhere((entry) => entry.key == 'POST /api/accounts/transfer')
            .body;

        expect(request['toAccountNumber'], 'SB22222222');
        expect(request['fromAccountNumber'], 'SB11111111');
        expect(request['pin'], '246810');
      },
    );

    testWidgets('sends nothing when the PIN prompt is cancelled', (
      tester,
    ) async {
      final client = buildFakeClient({
        'GET /api/accounts': const StubbedResponse.ok(ownAccounts),
        'GET /api/goals': const StubbedResponse.ok([]),
        'GET /api/transaction-pin/status': const StubbedResponse.ok({
          'pinConfigured': true,
          'message': 'Transaction PIN already configured',
        }),
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: ProviderContainer(
            overrides: [
              apiClientProvider.overrideWithValue(client),
              tokenStorageProvider.overrideWithValue(
                FakeTokenStorage(token: 'jwt'),
              ),
            ],
          ),
          child: const MaterialApp(
            home: NewTransactionPage(initialAction: MoneyAction.withdraw),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount'),
        '100',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Withdraw'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      final calls = (client.dio.httpClientAdapter as FakeApiAdapter).log
          .map((entry) => entry.key)
          .toList();
      expect(
        calls.where((call) => call == 'POST /api/accounts/SB11111111/withdraw'),
        isEmpty,
      );
    });

    testWidgets('tells a user with no PIN to create one before transacting', (
      tester,
    ) async {
      final client = buildFakeClient({
        'GET /api/accounts': const StubbedResponse.ok(ownAccounts),
        'GET /api/goals': const StubbedResponse.ok([]),
        'GET /api/transaction-pin/status': const StubbedResponse.ok({
          'pinConfigured': false,
          'message': 'Transaction PIN not configured',
        }),
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: ProviderContainer(
            overrides: [
              apiClientProvider.overrideWithValue(client),
              tokenStorageProvider.overrideWithValue(
                FakeTokenStorage(token: 'jwt'),
              ),
            ],
          ),
          child: const MaterialApp(
            home: NewTransactionPage(initialAction: MoneyAction.deposit),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount'),
        '100',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Deposit'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
      await tester.pumpAndSettle();

      expect(find.text('Create transaction PIN'), findsOneWidget);
      expect(find.text('Transaction PIN'), findsNothing);
    });

    testWidgets('rejects a malformed destination before calling the API', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const NewTransactionPage(initialAction: MoneyAction.transfer),
          stubs: {'GET /api/accounts': const StubbedResponse.ok(ownAccounts)},
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'To account number'),
        'SB1',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount'),
        '10',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Transfer'));
      await tester.pumpAndSettle();

      expect(find.textContaining('SB12345678'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Confirm'), findsNothing);
    });

    testWidgets('keeps money reserved in a goal out of reach', (tester) async {
      final client = buildFakeClient({
        'GET /api/accounts': const StubbedResponse.ok(ownAccounts),
        'GET /api/goals': const StubbedResponse.ok([
          {
            'id': 1,
            'goalName': 'Emergency fund',
            'targetAmount': 2000,
            'currentAmount': 900,
            'progressPercentage': 45,
            'status': 'IN_PROGRESS',
            'targetDate': '2027-01-01',
            'createdAt': '2026-01-01',
          },
        ]),
      });

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(client),
          tokenStorageProvider.overrideWithValue(
            FakeTokenStorage(token: 'jwt'),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const NewTransactionPage(initialAction: MoneyAction.withdraw),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1000 on the account, 900 of it held by the goal.
      expect(
        find.textContaining('Available to spend: \$100.00'),
        findsOneWidget,
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount'),
        '250',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Withdraw'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Only \$100.00 is spendable'), findsOneWidget);
      expect(
        (client.dio.httpClientAdapter as FakeApiAdapter).log.where(
          (entry) => entry.key == 'POST /api/accounts/SB11111111/withdraw',
        ),
        isEmpty,
        reason: 'the app must not even ask the backend to spend reserved money',
      );
    });
  });

  group('TransactionPinPage', () {
    const statusMissing = StubbedResponse.ok({
      'pinConfigured': false,
      'message': 'Transaction PIN not configured',
    });
    const statusConfigured = StubbedResponse.ok({
      'pinConfigured': true,
      'message': 'Transaction PIN already configured',
    });

    /// Returns the request log so a test can prove what left the device.
    Future<FakeApiAdapter> pumpPinPage(
      WidgetTester tester,
      Map<String, StubbedResponse> stubs,
    ) async {
      final client = buildFakeClient(stubs);
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(client),
          tokenStorageProvider.overrideWithValue(
            FakeTokenStorage(token: 'jwt'),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: TransactionPinPage()),
        ),
      );
      await tester.pumpAndSettle();

      return client.dio.httpClientAdapter as FakeApiAdapter;
    }

    testWidgets('offers setup, with no current-PIN field, when none exists', (
      tester,
    ) async {
      final log = await pumpPinPage(tester, {
        'GET /api/transaction-pin/status': statusMissing,
        'POST /api/transaction-pin/setup': const StubbedResponse(
          201,
          'Transaction PIN created successfully',
        ),
      });

      expect(find.text('No PIN yet'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Current PIN'), findsNothing);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'PIN'),
        '246810',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm PIN'),
        '246810',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Create PIN'));
      await tester.pumpAndSettle();

      expect(find.text('Transaction PIN created'), findsOneWidget);

      final setup = log.log.firstWhere(
        (entry) => entry.key == 'POST /api/transaction-pin/setup',
      );
      expect(setup.body, {'pin': '246810', 'confirmPin': '246810'});

      // The status is re-read after a save instead of the screen assuming it.
      expect(
        log.log
            .where((entry) => entry.key == 'GET /api/transaction-pin/status')
            .length,
        2,
      );
    });

    testWidgets('refuses a PIN that is not six digits, without a request', (
      tester,
    ) async {
      final log = await pumpPinPage(tester, {
        'GET /api/transaction-pin/status': statusMissing,
      });

      await tester.enterText(
        find.widgetWithText(TextFormField, 'PIN'),
        '12345',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm PIN'),
        '12345',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Create PIN'));
      await tester.pumpAndSettle();

      expect(find.text('PIN must contain exactly 6 digits'), findsOneWidget);
      expect(log.log.where((e) => e.key.contains('setup')), isEmpty);
    });

    testWidgets('asks for the current PIN once one is configured', (
      tester,
    ) async {
      await pumpPinPage(tester, {
        'GET /api/transaction-pin/status': statusConfigured,
      });

      expect(find.text('PIN configured'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Current PIN'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Change PIN'), findsOneWidget);
    });

    testWidgets('reports an incorrect PIN and wipes the entered values', (
      tester,
    ) async {
      await pumpPinPage(tester, {
        'GET /api/transaction-pin/status': statusConfigured,
        'PUT /api/transaction-pin/change': const StubbedResponse(403, {
          'status': 403,
          'error': 'Incorrect Transaction PIN',
          'message': 'Incorrect transaction PIN',
        }),
      });

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Current PIN'),
        '111111',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'New PIN'),
        '246810',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm new PIN'),
        '246810',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Change PIN'));
      await tester.pumpAndSettle();

      expect(find.text('Incorrect transaction PIN'), findsOneWidget);
      for (final label in ['Current PIN', 'New PIN', 'Confirm new PIN']) {
        final field = tester.widget<TextFormField>(
          find.widgetWithText(TextFormField, label),
        );
        expect(field.controller!.text, isEmpty, reason: label);
      }
    });

    testWidgets('shows the locked-PIN reason from the backend', (tester) async {
      await pumpPinPage(tester, {
        'GET /api/transaction-pin/status': statusConfigured,
        'PUT /api/transaction-pin/change': const StubbedResponse(423, {
          'status': 423,
          'error': 'Transaction PIN Locked',
          'message': 'Too many incorrect PIN attempts. Try again later.',
        }),
      });

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Current PIN'),
        '111111',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'New PIN'),
        '246810',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm new PIN'),
        '246810',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Change PIN'));
      await tester.pumpAndSettle();

      expect(
        find.text('Too many incorrect PIN attempts. Try again later.'),
        findsOneWidget,
      );
    });
  });

  group('PinResetPage', () {
    /// The screen pops itself on success, so it needs a real router with the
    /// location the app actually pushes ('/transaction-pin/reset').
    Future<FakeApiAdapter> pumpResetPage(
      WidgetTester tester,
      Map<String, StubbedResponse> stubs,
    ) async {
      final client = buildFakeClient(stubs);
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(client),
          tokenStorageProvider.overrideWithValue(
            FakeTokenStorage(token: 'jwt'),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/transaction-pin/reset',
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const SizedBox.shrink(),
                  routes: [
                    GoRoute(
                      path: 'transaction-pin',
                      builder: (context, state) => const SizedBox.shrink(),
                      routes: [
                        GoRoute(
                          path: 'reset',
                          builder: (context, state) => const PinResetPage(),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      return client.dio.httpClientAdapter as FakeApiAdapter;
    }

    Future<void> fillResetForm(WidgetTester tester) async {
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Account password'),
        'GateTest!23',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'New PIN'),
        '135790',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm new PIN'),
        '135790',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Reset PIN'));
    }

    testWidgets('puts the password and both PIN entries in one request', (
      tester,
    ) async {
      final log = await pumpResetPage(tester, {
        'PUT /api/transaction-pin/reset': const StubbedResponse(
          200,
          'Transaction PIN reset successfully',
        ),
      });

      await fillResetForm(tester);
      await tester.pumpAndSettle();

      final body = log.log
          .firstWhere((entry) => entry.key == 'PUT /api/transaction-pin/reset')
          .body;
      expect(body.keys, ['password', 'newPin', 'confirmNewPin']);
      expect(body['password'], 'GateTest!23');

      expect(
        find.text('Reset transaction PIN'),
        findsNothing,
        reason: 'only a 2xx may leave the screen',
      );
    });

    testWidgets('shows the reason a wrong password is rejected, and stays', (
      tester,
    ) async {
      await pumpResetPage(tester, {
        'PUT /api/transaction-pin/reset': const StubbedResponse(401, {
          'status': 401,
          'error': 'Unauthorized',
          'message': 'Account password does not match',
        }),
      });

      await fillResetForm(tester);
      await tester.pumpAndSettle();

      expect(find.text('Account password does not match'), findsOneWidget);
      expect(find.text('Reset transaction PIN'), findsOneWidget);

      for (final label in ['Account password', 'New PIN', 'Confirm new PIN']) {
        final field = tester.widget<TextFormField>(
          find.widgetWithText(TextFormField, label),
        );
        expect(field.controller!.text, isEmpty, reason: label);
      }
    });

    testWidgets('catches mismatched PINs before the network is involved', (
      tester,
    ) async {
      final log = await pumpResetPage(tester, {
        'PUT /api/transaction-pin/reset': const StubbedResponse(
          200,
          'Transaction PIN reset successfully',
        ),
      });

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Account password'),
        'GateTest!23',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'New PIN'),
        '135790',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm new PIN'),
        '135791',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Reset PIN'));
      await tester.pumpAndSettle();

      expect(
        log.log.where((entry) => entry.key == 'PUT /api/transaction-pin/reset'),
        isEmpty,
      );
    });
  });

  group('ForgotPasswordPage', () {
    Future<FakeApiAdapter> pumpRecoveryPages(
      WidgetTester tester,
      Map<String, StubbedResponse> stubs,
    ) => pumpRecoveryRoute(tester, stubs, '/forgot-password');

    const requested = StubbedResponse.ok({
      'message':
          'If that email belongs to an account, a reset code has been sent.',
    });

    testWidgets('posts only the email and carries it to the code screen', (
      tester,
    ) async {
      final log = await pumpRecoveryPages(tester, {
        'POST /api/auth/forgot-password': requested,
      });

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Registered email'),
        'george@example.com',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Send reset code'));
      await tester.pumpAndSettle();

      expect(
        log.log
            .where((entry) => entry.key == 'POST /api/auth/forgot-password')
            .single
            .body,
        {'email': 'george@example.com'},
      );

      expect(find.text('Set a new password'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(
              find.widgetWithText(TextFormField, 'Registered email'),
            )
            .controller!
            .text,
        'george@example.com',
        reason: 'the address the code was sent to carries over',
      );
    });

    testWidgets('stays put when the server cannot deliver the code', (
      tester,
    ) async {
      await pumpRecoveryPages(tester, {
        'POST /api/auth/forgot-password': const StubbedResponse(503, {
          'message': 'Email delivery is not configured on this server',
        }),
      });

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Registered email'),
        'george@example.com',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Send reset code'));
      await tester.pumpAndSettle();

      // 5xx bodies are never repeated to the user, so the app-wide fault
      // message appears instead - and, importantly, no success is claimed.
      expect(
        find.text(
          'SmartBank could not complete the request. Please try again.',
        ),
        findsOneWidget,
      );
      expect(find.text('Forgot password'), findsOneWidget);
      expect(find.text('Set a new password'), findsNothing);
    });

    testWidgets('rejects a malformed address without a request', (
      tester,
    ) async {
      final log = await pumpRecoveryPages(tester, {
        'POST /api/auth/forgot-password': requested,
      });

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Registered email'),
        'not-an-email',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Send reset code'));
      await tester.pumpAndSettle();

      expect(log.log, isEmpty);
      expect(find.text('Enter a valid email address'), findsOneWidget);
    });
  });

  group('ResetPasswordPage', () {
    const resetStubs = <String, StubbedResponse>{
      'POST /api/auth/reset-password': StubbedResponse.ok({
        'message': 'Password reset successfully',
      }),
    };

    Future<FakeApiAdapter> pumpReset(
      WidgetTester tester,
      Map<String, StubbedResponse> stubs,
    ) => pumpRecoveryRoute(tester, stubs, '/reset-password');

    Future<void> fillRecoveryForm(
      WidgetTester tester, {
      String code = '246813',
      String fresh = 'Recovered!23',
      String confirm = 'Recovered!23',
    }) async {
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Registered email'),
        'george@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Reset code'),
        code,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'New password'),
        fresh,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm new password'),
        confirm,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Reset password'));
    }

    testWidgets('exchanges the code for a password and ends at login', (
      tester,
    ) async {
      final log = await pumpReset(tester, resetStubs);

      await fillRecoveryForm(tester);
      await tester.pumpAndSettle();

      final body = log.log
          .firstWhere((entry) => entry.key == 'POST /api/auth/reset-password')
          .body;
      expect(body.keys, ['email', 'code', 'newPassword', 'confirmPassword']);
      expect(body['code'], '246813');

      expect(find.text('Set a new password'), findsNothing);
    });

    testWidgets('a wrong code is refused, and the secrets are wiped', (
      tester,
    ) async {
      await pumpReset(tester, {
        'POST /api/auth/reset-password': const StubbedResponse(401, {
          'message': 'Reset code does not match',
        }),
      });

      await fillRecoveryForm(tester, code: '111111');
      await tester.pumpAndSettle();

      expect(find.text('Reset code does not match'), findsOneWidget);
      expect(find.text('Set a new password'), findsOneWidget);

      for (final label in [
        'Reset code',
        'New password',
        'Confirm new password',
      ]) {
        final field = tester.widget<TextFormField>(
          find.widgetWithText(TextFormField, label),
        );
        expect(field.controller!.text, isEmpty, reason: label);
      }

      expect(
        tester
            .widget<TextFormField>(
              find.widgetWithText(TextFormField, 'Registered email'),
            )
            .controller!
            .text,
        'george@example.com',
        reason: 'the address is not a secret worth retyping',
      );
    });

    testWidgets('catches mismatched passwords before the network', (
      tester,
    ) async {
      final log = await pumpReset(tester, resetStubs);

      await fillRecoveryForm(tester, confirm: 'SomethingElse!23');
      await tester.pumpAndSettle();

      expect(
        log.log.where((entry) => entry.key == 'POST /api/auth/reset-password'),
        isEmpty,
      );
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('rejects a code that is not six digits, without a request', (
      tester,
    ) async {
      final log = await pumpReset(tester, resetStubs);

      await fillRecoveryForm(tester, code: '12345');
      await tester.pumpAndSettle();

      expect(
        log.log.where((entry) => entry.key == 'POST /api/auth/reset-password'),
        isEmpty,
      );
    });
  });

  group('ChangePasswordPage', () {
    Future<FakeApiAdapter> pumpChangePasswordPage(
      WidgetTester tester,
      Map<String, StubbedResponse> stubs,
    ) async {
      final client = buildFakeClient(stubs);
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(client),
          tokenStorageProvider.overrideWithValue(
            FakeTokenStorage(token: 'jwt'),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/change-password',
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const SizedBox.shrink(),
                  routes: [
                    GoRoute(
                      path: 'change-password',
                      builder: (context, state) => const ChangePasswordPage(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      return client.dio.httpClientAdapter as FakeApiAdapter;
    }

    Future<void> fillChangeForm(
      WidgetTester tester, {
      String current = 'OldPass!23',
      String fresh = 'NewPass!23',
      String confirm = 'NewPass!23',
    }) async {
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Current password'),
        current,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'New password'),
        fresh,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm new password'),
        confirm,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Update password'));
    }

    testWidgets('puts all three entries in one request and leaves on 2xx', (
      tester,
    ) async {
      final log = await pumpChangePasswordPage(tester, {
        'PUT /api/auth/change-password': const StubbedResponse(200, {
          'message': 'Password changed successfully',
        }),
      });

      await fillChangeForm(tester);
      await tester.pumpAndSettle();

      final body = log.log
          .firstWhere((entry) => entry.key == 'PUT /api/auth/change-password')
          .body;
      expect(body.keys, ['currentPassword', 'newPassword', 'confirmPassword']);
      expect(body['currentPassword'], 'OldPass!23');
      expect(body['newPassword'], 'NewPass!23');

      expect(
        find.text('Change password'),
        findsNothing,
        reason: 'only a 2xx may leave the screen',
      );
    });

    testWidgets('shows why a wrong current password is refused, and stays', (
      tester,
    ) async {
      await pumpChangePasswordPage(tester, {
        'PUT /api/auth/change-password': const StubbedResponse(401, {
          'message': 'Current password does not match',
        }),
      });

      await fillChangeForm(tester, current: 'not-the-password');
      await tester.pumpAndSettle();

      expect(find.text('Current password does not match'), findsOneWidget);
      expect(find.text('Change password'), findsOneWidget);

      for (final label in [
        'Current password',
        'New password',
        'Confirm new password',
      ]) {
        final field = tester.widget<TextFormField>(
          find.widgetWithText(TextFormField, label),
        );
        expect(field.controller!.text, isEmpty, reason: label);
      }
    });

    testWidgets('catches a mistyped confirmation before the network', (
      tester,
    ) async {
      final log = await pumpChangePasswordPage(tester, {
        'PUT /api/auth/change-password': const StubbedResponse(200, {
          'message': 'Password changed successfully',
        }),
      });

      await fillChangeForm(tester, confirm: 'NewPass!24');
      await tester.pumpAndSettle();

      expect(
        log.log.where((entry) => entry.key == 'PUT /api/auth/change-password'),
        isEmpty,
      );
      expect(find.text('Passwords do not match'), findsOneWidget);
    });
  });

  group('ProfilePage', () {
    const dashboard = StubbedResponse.ok({
      'totalBalance': 0,
      'numberOfAccounts': 0,
      'totalTransactions': 0,
      'recentTransactions': [],
    });

    testWidgets('shows the email of the signed-in account', (tester) async {
      await tester.pumpWidget(
        wrap(
          const ProfilePage(),
          token: tokenFor('george@gmail.com'),
          stubs: {
            'GET /api/accounts': const StubbedResponse.ok([]),
            'GET /api/analytics/dashboard': dashboard,
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('george@gmail.com'), findsOneWidget);
      expect(find.text('Your session is active.'), findsOneWidget);
    });

    testWidgets('falls back when the token carries no email', (tester) async {
      await tester.pumpWidget(
        wrap(
          const ProfilePage(),
          stubs: {
            'GET /api/accounts': const StubbedResponse.ok([]),
            'GET /api/analytics/dashboard': dashboard,
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SmartBank account'), findsOneWidget);
    });
  });
}
