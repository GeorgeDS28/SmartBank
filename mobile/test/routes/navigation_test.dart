import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbank/core/network/providers.dart';
import 'package:smartbank/features/auth/data/models/login_request.dart';
import 'package:smartbank/routes/app_router.dart';
import 'package:smartbank/providers/auth_provider.dart';

import '../support/fakes.dart';

void main() {
  testWidgets('protected routes redirect an unauthenticated visitor to login', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(buildFakeClient({})),
        tokenStorageProvider.overrideWithValue(FakeTokenStorage(token: null)),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: container.read(appRouterProvider),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);

    final router = container.read(appRouterProvider);
    router.go('/accounts');
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.path, '/login');
    expect(find.text('Welcome Back'), findsOneWidget);
  });

  testWidgets('auth pages redirect an authenticated user to the dashboard', (
    tester,
  ) async {
    final stubs = <String, StubbedResponse>{
      'GET /api/analytics/dashboard': const StubbedResponse.ok({
        'totalBalance': 24850.75,
        'numberOfAccounts': 3,
        'totalTransactions': 12,
        'recentTransactions': [],
      }),
      'GET /api/accounts': const StubbedResponse.ok([]),
    };

    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(buildFakeClient(stubs)),
        tokenStorageProvider.overrideWithValue(FakeTokenStorage(token: 'jwt')),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: container.read(appRouterProvider),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final router = container.read(appRouterProvider);
    router.go('/login');
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.path, '/dashboard');
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('\$24,850.75'), findsOneWidget);
  });

  testWidgets('the shell exposes all six destinations', (tester) async {
    final stubs = <String, StubbedResponse>{
      'GET /api/analytics/dashboard': const StubbedResponse.ok({
        'totalBalance': 0,
        'numberOfAccounts': 0,
        'totalTransactions': 0,
        'recentTransactions': [],
      }),
      'GET /api/accounts': const StubbedResponse.ok([]),
      'GET /api/goals': const StubbedResponse.ok([]),
      'GET /api/analytics/financial-summary': const StubbedResponse.ok({
        'totalBalance': 0,
        'totalDeposits': 0,
        'totalWithdrawals': 0,
        'totalTransferredIn': 0,
        'totalTransferredOut': 0,
        'netCashFlow': 0,
        'totalGoalSavings': 0,
      }),
      'GET /api/analytics/monthly': const StubbedResponse.ok([]),
      'GET /api/analytics/goals': const StubbedResponse.ok({
        'totalGoals': 0,
        'activeGoals': 0,
        'completedGoals': 0,
        'totalTargetAmount': 0,
        'totalSavedAmount': 0,
        'overallProgress': 0,
      }),
      'GET /api/analytics/transfers': const StubbedResponse.ok({
        'totalTransfers': 0,
        'totalTransferredIn': 0,
        'totalTransferredOut': 0,
        'netTransferAmount': 0,
      }),
    };

    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(buildFakeClient(stubs)),
        tokenStorageProvider.overrideWithValue(FakeTokenStorage(token: 'jwt')),
      ],
    );
    addTearDown(container.dispose);

    // A phone-width surface so the shell renders the bottom navigation bar.
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: container.read(appRouterProvider),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final label in const [
      'Dashboard',
      'Accounts',
      'Transactions',
      'Goals',
      'Analytics',
      'Profile',
    ]) {
      expect(find.text(label), findsWidgets, reason: '$label is unreachable');
    }

    final router = container.read(appRouterProvider);
    router.go('/analytics');
    await tester.pumpAndSettle();

    expect(find.text('Money in versus money out'), findsOneWidget);
  });

  testWidgets('logout clears the token and returns to login', (tester) async {
    final tokenStorage = FakeTokenStorage(token: 'jwt');
    final stubs = <String, StubbedResponse>{
      'GET /api/analytics/dashboard': const StubbedResponse.ok({
        'totalBalance': 0,
        'numberOfAccounts': 0,
        'totalTransactions': 0,
        'recentTransactions': [],
      }),
      'GET /api/accounts': const StubbedResponse.ok([]),
    };

    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(buildFakeClient(stubs)),
        tokenStorageProvider.overrideWithValue(tokenStorage),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: container.read(appRouterProvider),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await container.read(authProvider.notifier).logout();
    await tester.pumpAndSettle();

    expect(tokenStorage.token, isNull);
    expect(
      container
          .read(appRouterProvider)
          .routerDelegate
          .currentConfiguration
          .uri
          .path,
      '/login',
    );
  });

  test('login stores the issued token before flipping auth state', () async {
    final tokenStorage = FakeTokenStorage(token: null);
    final client = buildFakeClient({
      'POST /api/auth/login': const StubbedResponse.ok({'token': 'fresh-jwt'}),
    }, token: null);

    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(client),
        tokenStorageProvider.overrideWithValue(tokenStorage),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(authProvider.notifier)
        .login(LoginRequest(email: 'a@b.com', password: 'password1'));

    expect(tokenStorage.token, 'fresh-jwt');
    expect(container.read(authProvider).status, AuthStatus.authenticated);
  });
}
