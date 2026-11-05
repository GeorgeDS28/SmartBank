import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/account/presentation/pages/account_details_page.dart';
import '../features/account/presentation/pages/accounts_page.dart';
import '../features/analytics/presentation/pages/analytics_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/goal/presentation/pages/goal_details_page.dart';
import '../features/goal/presentation/pages/goals_page.dart';
import '../features/shell/presentation/pages/app_shell.dart';
import '../features/transaction/presentation/pages/new_transaction_page.dart';
import '../features/transaction/presentation/pages/transaction_details_page.dart';
import '../features/transaction/presentation/pages/transactions_page.dart';
import '../features/transactionpin/presentation/pages/pin_reset_page.dart';
import '../features/transactionpin/presentation/pages/transaction_pin_page.dart';
import '../features/user/presentation/pages/profile_page.dart';
import '../features/user/presentation/pages/settings_page.dart';
import '../providers/auth_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      // Read rather than watch: a new GoRouter per auth change would discard
      // the navigation stack, so the router stays alive and re-runs this
      // redirect whenever the auth state changes.
      final status = ref.read(authProvider).status;
      final location = state.matchedLocation;

      if (status == AuthStatus.loading) {
        return null;
      }

      final isAuthenticated = status == AuthStatus.authenticated;
      final isAuthPage = location == '/login' || location == '/register';

      if (!isAuthenticated && !isAuthPage) {
        return '/login';
      }

      if (isAuthenticated && isAuthPage) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/transaction-pin',
        builder: (context, state) => const TransactionPinPage(),
        routes: [
          GoRoute(
            path: 'reset',
            builder: (context, state) => const PinResetPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/accounts/:accountNumber',
        builder: (context, state) => AccountDetailsPage(
          accountNumber: state.pathParameters['accountNumber']!,
        ),
      ),
      GoRoute(
        path: '/goals/:goalId',
        builder: (context, state) => GoalDetailsPage(
          goalId: int.tryParse(state.pathParameters['goalId'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: '/transactions/new',
        builder: (context, state) {
          final action = switch (state.uri.queryParameters['action']) {
            'withdraw' => MoneyAction.withdraw,
            'transfer' => MoneyAction.transfer,
            _ => MoneyAction.deposit,
          };
          return NewTransactionPage(
            initialAction: action,
            initialAccountNumber: state.uri.queryParameters['account'],
          );
        },
      ),
      GoRoute(
        path: '/transactions/:reference',
        builder: (context, state) => TransactionDetailsPage(
          transactionReference: state.pathParameters['reference']!,
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(
          selectedIndex: navigationShell.currentIndex,
          child: navigationShell,
        ),
        branches: [
          _branch('/dashboard', const DashboardPage()),
          _branch('/accounts', const AccountsPage()),
          _branch('/transactions', const TransactionsPage()),
          _branch('/goals', const GoalsPage()),
          _branch('/analytics', const AnalyticsPage()),
          _branch('/profile', const ProfilePage()),
        ],
      ),
    ],
  );

  ref.listen<AuthState>(authProvider, (_, _) => router.refresh());

  return router;
});

StatefulShellBranch _branch(String path, Widget page) {
  return StatefulShellBranch(
    routes: [GoRoute(path: path, builder: (context, state) => page)],
  );
}
