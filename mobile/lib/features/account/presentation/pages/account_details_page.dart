import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbank/core/network/api_exception.dart';
import 'package:smartbank/core/theme/app_theme.dart';
import 'package:smartbank/core/utils/format.dart';
import 'package:smartbank/core/widgets/app_async_views.dart';
import 'package:smartbank/core/widgets/balance_card.dart';
import 'package:smartbank/core/widgets/confirm_dialog.dart';
import 'package:smartbank/core/widgets/quick_action_button.dart';
import 'package:smartbank/core/widgets/responsive.dart';
import 'package:smartbank/core/widgets/section_header.dart';
import 'package:smartbank/core/widgets/transaction_tile.dart';
import 'package:smartbank/features/account/presentation/providers/accounts_provider.dart';

class AccountDetailsPage extends ConsumerWidget {
  final String accountNumber;

  const AccountDetailsPage({super.key, required this.accountNumber});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(accountProvider(accountNumber));
    ref.invalidate(accountTransactionsProvider(accountNumber));
    await ref.read(accountProvider(accountNumber).future);
  }

  Future<void> _close(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Close $accountNumber',
      lines: [
        'The balance has to be zero, so withdraw or transfer the rest first.',
        'Transaction history is kept, but the account can no longer move money.',
        'This cannot be undone.',
      ],
      confirmLabel: 'Close account',
      destructive: true,
    );
    if (!confirmed) return;

    try {
      await ref.read(accountActionProvider.notifier).close(accountNumber);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Account closed')));
    } on ApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAccount = ref.watch(accountProvider(accountNumber));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Details'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => _refresh(ref),
          ),
          if (asyncAccount.value?.status == 'ACTIVE')
            IconButton(
              tooltip: 'Close account',
              icon: const Icon(Icons.report_gmailerrorred_outlined),
              onPressed: () => _close(context, ref),
            ),
        ],
      ),
      body: asyncAccount.when(
        loading: () => const LoadingView(message: 'Loading account...'),
        error: (error, _) => ErrorView(
          message: 'Failed to load account:\n$error',
          onRetry: () => _refresh(ref),
        ),
        data: (account) {
          final usable = account.status == 'ACTIVE';

          return RefreshIndicator(
            onRefresh: () => _refresh(ref),
            child: ContentContainer(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                children: [
                  BalanceCard(totalBalance: account.balance),
                  const SizedBox(height: AppSpacing.md),
                  _InfoCard(
                    rows: {
                      'Account number': account.accountNumber,
                      'Type': humanizeEnum(account.accountType),
                      'Status': humanizeEnum(account.status),
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const SectionHeader(title: 'Actions'),
                  ResponsiveGrid(
                    children: [
                      QuickActionButton(
                        icon: Icons.south_west_rounded,
                        label: 'Deposit',
                        color: AppColors.positive,
                        onTap: usable
                            ? () => context.push(
                                '/transactions/new'
                                '?action=deposit'
                                '&account=${account.accountNumber}',
                              )
                            : () => _unavailable(context),
                      ),
                      QuickActionButton(
                        icon: Icons.north_east_rounded,
                        label: 'Withdraw',
                        color: AppColors.negative,
                        onTap: usable
                            ? () => context.push(
                                '/transactions/new'
                                '?action=withdraw'
                                '&account=${account.accountNumber}',
                              )
                            : () => _unavailable(context),
                      ),
                      QuickActionButton(
                        icon: Icons.swap_horiz_rounded,
                        label: 'Transfer',
                        color: AppColors.primary,
                        onTap: usable
                            ? () => context.push(
                                '/transactions/new'
                                '?action=transfer'
                                '&account=${account.accountNumber}',
                              )
                            : () => _unavailable(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SectionHeader(
                    title: 'Transaction history',
                    actionLabel: 'View all',
                    onAction: () => context.go('/transactions'),
                  ),
                  _AccountTransactions(accountNumber: accountNumber),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _unavailable(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This account is not active, so money cannot move.'),
      ),
    );
  }
}

class _AccountTransactions extends ConsumerWidget {
  final String accountNumber;

  const _AccountTransactions({required this.accountNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTransactions = ref.watch(
      accountTransactionsProvider(accountNumber),
    );

    return asyncTransactions.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => ErrorView(
        message: 'Failed to load transactions:\n$error',
        onRetry: () =>
            ref.invalidate(accountTransactionsProvider(accountNumber)),
      ),
      data: (transactions) {
        if (transactions.isEmpty) {
          return const EmptyView(
            icon: Icons.receipt_long_outlined,
            message: 'No transactions on this account yet.',
          );
        }

        const previewLimit = 10;
        final preview = transactions.take(previewLimit).toList(growable: false);

        return Column(
          children: [
            for (final transaction in preview)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
                child: TransactionTile(
                  transaction: transaction,
                  onTap: () => context.push(
                    '/transactions/${transaction.transactionReference}',
                  ),
                ),
              ),
            if (transactions.length > previewLimit)
              Text(
                'Showing $previewLimit of ${transactions.length} transactions.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Map<String, String> rows;

  const _InfoCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          children: [
            for (final entry in rows.entries)
              ListTile(
                title: Text(entry.key),
                trailing: Text(
                  entry.value,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
