import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbank/core/theme/app_theme.dart';
import 'package:smartbank/core/widgets/app_async_views.dart';
import 'package:smartbank/core/widgets/balance_card.dart';
import 'package:smartbank/core/widgets/quick_action_button.dart';
import 'package:smartbank/core/widgets/responsive.dart';
import 'package:smartbank/core/widgets/section_header.dart';
import 'package:smartbank/core/widgets/transaction_tile.dart';
import 'package:smartbank/features/account/presentation/providers/accounts_provider.dart';
import 'package:smartbank/features/user/presentation/providers/dashboard_provider.dart';
import 'package:smartbank/features/user/presentation/providers/settings_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(dashboardProvider);
    ref.invalidate(accountsProvider);
    await ref.read(dashboardProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final hideBalances = ref.watch(hideBalancesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartBank'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => _refresh(ref),
          ),
        ],
      ),
      body: dashboardAsync.when(
        loading: () => const LoadingView(message: 'Loading your dashboard...'),
        error: (error, _) => ErrorView(
          message: 'Failed to load dashboard:\n$error',
          onRetry: () => _refresh(ref),
        ),
        data: (dashboard) {
          final accounts = accountsAsync.value ?? const [];

          return RefreshIndicator(
            onRefresh: () => _refresh(ref),
            child: ContentContainer(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                children: [
                  Text(
                    'Welcome back',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Here is your financial overview.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  BalanceCard(
                    totalBalance: dashboard.totalBalance,
                    numberOfAccounts: dashboard.numberOfAccounts,
                    totalTransactions: dashboard.totalTransactions,
                    masked: hideBalances,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const SectionHeader(title: 'Quick actions'),
                  ResponsiveGrid(
                    minColumnWidth: 240,
                    children: [
                      QuickActionButton(
                        icon: Icons.south_west_rounded,
                        label: 'Deposit',
                        color: AppColors.positive,
                        onTap: () =>
                            context.push('/transactions/new?action=deposit'),
                      ),
                      QuickActionButton(
                        icon: Icons.north_east_rounded,
                        label: 'Withdraw',
                        color: AppColors.negative,
                        onTap: () =>
                            context.push('/transactions/new?action=withdraw'),
                      ),
                      QuickActionButton(
                        icon: Icons.swap_horiz_rounded,
                        label: 'Transfer',
                        color: AppColors.primary,
                        onTap: () =>
                            context.push('/transactions/new?action=transfer'),
                      ),
                      QuickActionButton(
                        icon: Icons.account_balance_outlined,
                        label: 'Accounts',
                        color: AppColors.violet,
                        onTap: () => context.go('/accounts'),
                      ),
                      QuickActionButton(
                        icon: Icons.flag_outlined,
                        label: 'Goals',
                        color: AppColors.amber,
                        onTap: () => context.go('/goals'),
                      ),
                      QuickActionButton(
                        icon: Icons.insights_outlined,
                        label: 'Analytics',
                        color: AppColors.navy,
                        onTap: () => context.go('/analytics'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SectionHeader(
                    title: 'Your accounts',
                    actionLabel: 'View all',
                    onAction: () => context.go('/accounts'),
                  ),
                  if (accounts.isEmpty)
                    const EmptyView(
                      icon: Icons.account_balance_outlined,
                      message: 'No accounts yet. Open one to start banking.',
                    )
                  else
                    for (final account in accounts.take(3))
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.sm + 4,
                        ),
                        child: _AccountRow(
                          accountNumber: account.accountNumber,
                          label: account.accountType,
                          balance: account.balance,
                          masked: hideBalances,
                          onTap: () => context.push(
                            '/accounts/${account.accountNumber}',
                          ),
                        ),
                      ),
                  const SizedBox(height: AppSpacing.lg),
                  SectionHeader(
                    title: 'Recent transactions',
                    actionLabel: 'View all',
                    onAction: () => context.go('/transactions'),
                  ),
                  if (dashboard.recentTransactions.isEmpty)
                    const EmptyView(
                      icon: Icons.receipt_long_outlined,
                      message: 'No transactions yet.',
                    )
                  else
                    for (final recent in dashboard.recentTransactions)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.sm + 4,
                        ),
                        child: TransactionTile(
                          transaction: recent.toModel(),
                          showAccount: true,
                          onTap: () => context.push(
                            '/transactions/${recent.transactionReference}',
                          ),
                        ),
                      ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final String accountNumber;
  final String label;
  final double balance;
  final bool masked;
  final VoidCallback onTap;

  const _AccountRow({
    required this.accountNumber,
    required this.label,
    required this.balance,
    required this.masked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.account_balance_outlined),
        title: Text(label),
        subtitle: Text(accountNumber),
        trailing: Text(
          masked ? '••••••' : balance.toStringAsFixed(2),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
