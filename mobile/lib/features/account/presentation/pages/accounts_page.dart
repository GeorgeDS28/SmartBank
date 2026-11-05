import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbank/core/network/api_exception.dart';
import 'package:smartbank/core/theme/app_theme.dart';
import 'package:smartbank/core/utils/format.dart';
import 'package:smartbank/core/widgets/account_card.dart';
import 'package:smartbank/core/widgets/app_async_views.dart';
import 'package:smartbank/core/widgets/confirm_dialog.dart';
import 'package:smartbank/core/widgets/responsive.dart';
import 'package:smartbank/core/widgets/section_header.dart';
import 'package:smartbank/features/account/presentation/providers/accounts_provider.dart';
import 'package:smartbank/features/analytics/presentation/providers/spendable_balance_provider.dart';
import 'package:smartbank/features/user/data/models/account_model.dart';

class AccountsPage extends ConsumerWidget {
  const AccountsPage({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(accountsProvider);
    await ref.read(accountsProvider.future);
  }

  Future<void> _createAccount(BuildContext context, WidgetRef ref) async {
    String selectedType = 'SAVINGS';

    final type = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Open a new account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(labelText: 'Account type'),
                items: const [
                  DropdownMenuItem(value: 'SAVINGS', child: Text('Savings')),
                  DropdownMenuItem(value: 'CURRENT', child: Text('Current')),
                ],
                onChanged: (value) =>
                    setState(() => selectedType = value ?? 'SAVINGS'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, selectedType),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );

    if (type == null || !context.mounted) return;

    final confirmed = await showConfirmDialog(
      context,
      title: 'Open ${type.toLowerCase()} account',
      lines: [
        'SmartBank will create a new ${type.toLowerCase()} account '
            'with a zero balance.',
      ],
      confirmLabel: 'Open account',
    );

    if (!confirmed) return;

    try {
      await ref.read(accountActionProvider.notifier).create(type);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${type.toLowerCase()} account opened successfully'),
        ),
      );
    } on ApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAccounts = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Accounts'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => _refresh(ref),
          ),
          IconButton(
            tooltip: 'Open account',
            icon: const Icon(Icons.add),
            onPressed: () => _createAccount(context, ref),
          ),
        ],
      ),
      body: asyncAccounts.when(
        loading: () => const LoadingView(message: 'Loading accounts...'),
        error: (error, _) => ErrorView(
          message: 'Failed to load accounts:\n$error',
          onRetry: () => _refresh(ref),
        ),
        data: (accounts) {
          if (accounts.isEmpty) {
            return EmptyView(
              message:
                  'You have no accounts yet. Open a savings or current '
                  'account to get started.',
              action: FilledButton(
                onPressed: () => _createAccount(context, ref),
                child: const Text('Open account'),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _refresh(ref),
            child: ContentContainer(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                children: [
                  _SummaryRow(
                    accounts: accounts,
                    spendable: ref.watch(spendableBalanceProvider).value,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const SectionHeader(title: 'Accounts'),
                  for (final account in accounts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: AccountCard(
                        account: account,
                        onTap: () =>
                            context.push('/accounts/${account.accountNumber}'),
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

class _SummaryRow extends StatelessWidget {
  final List<AccountModel> accounts;
  final SpendableBalance? spendable;

  const _SummaryRow({required this.accounts, required this.spendable});

  @override
  Widget build(BuildContext context) {
    final active = accounts.where((a) => a.status == 'ACTIVE').length;
    // Only the active accounts back a goal, which is what the backend reserves
    // against, so the closed ones are left out of the money figures.
    final total =
        spendable?.totalBalance ??
        accounts
            .where((a) => a.status == 'ACTIVE')
            .fold<double>(0, (sum, account) => sum + account.balance);

    return ResponsiveGrid(
      children: [
        StatCard(
          label: 'Total balance',
          value: formatCurrency(total),
          icon: Icons.account_balance_wallet_outlined,
          color: AppColors.primary,
        ),
        StatCard(
          label: 'Reserved in goals',
          value: spendable == null
              ? '—'
              : formatCurrency(spendable!.reservedInGoals),
          icon: Icons.savings_outlined,
          color: AppColors.amber,
        ),
        StatCard(
          label: 'Available to spend',
          value: spendable == null ? '—' : formatCurrency(spendable!.spendable),
          icon: Icons.credit_card_rounded,
          color: AppColors.positive,
          caption: (spendable?.isOverReserved ?? false)
              ? 'Your goals reserve more than the accounts hold. Delete a goal '
                    'to free money up.'
              : null,
        ),
        StatCard(
          label: 'Active accounts',
          value: '$active of ${accounts.length}',
          icon: Icons.verified_outlined,
          color: AppColors.violet,
        ),
      ],
    );
  }
}
