import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbank/core/theme/app_theme.dart';
import 'package:smartbank/core/widgets/app_async_views.dart';
import 'package:smartbank/core/widgets/responsive.dart';
import 'package:smartbank/core/widgets/transaction_tile.dart';
import 'package:smartbank/features/account/presentation/providers/accounts_provider.dart';
import 'package:smartbank/features/transaction/data/models/transaction_model.dart';
import 'package:smartbank/features/transaction/presentation/providers/transactions_provider.dart';
import 'package:smartbank/features/user/data/models/account_model.dart';

const _typeFilters = <String, List<String>>{
  'All': [],
  'Deposits': ['DEPOSIT'],
  'Withdrawals': ['WITHDRAW'],
  'Transfers': ['TRANSFER_IN', 'TRANSFER_OUT'],
};

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  String _typeFilter = 'All';
  String? _accountFilter;

  Future<void> _refresh() async {
    ref.invalidate(transactionsProvider);
    ref.invalidate(accountsProvider);
    await ref.read(transactionsProvider.future);
  }

  List<TransactionModel> _applyFilters(List<TransactionModel> source) {
    final allowedTypes = _typeFilters[_typeFilter]!;
    return source
        .where((tx) {
          final typeMatches =
              allowedTypes.isEmpty || allowedTypes.contains(tx.transactionType);
          final accountMatches =
              _accountFilter == null || tx.accountNumber == _accountFilter;
          return typeMatches && accountMatches;
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final asyncTransactions = ref.watch(transactionsProvider);
    final asyncAccounts = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
          IconButton(
            tooltip: 'New transaction',
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/transactions/new'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/transactions/new'),
        icon: const Icon(Icons.swap_horiz),
        label: const Text('New'),
      ),
      body: asyncTransactions.when(
        loading: () => const LoadingView(message: 'Loading transactions...'),
        error: (error, _) => ErrorView(
          message: 'Failed to load transactions:\n$error',
          onRetry: _refresh,
        ),
        data: (allTransactions) {
          final accounts = asyncAccounts.value ?? const [];
          final visible = _applyFilters(allTransactions);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ContentContainer(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                children: [
                  _FilterBar(
                    typeFilter: _typeFilter,
                    accountFilter: _accountFilter,
                    accounts: accounts,
                    onTypeChanged: (value) =>
                        setState(() => _typeFilter = value),
                    onAccountChanged: (value) =>
                        setState(() => _accountFilter = value),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (allTransactions.isEmpty)
                    EmptyView(
                      icon: Icons.receipt_long_outlined,
                      message:
                          'No transactions yet. Make a deposit to get started.',
                      actionLabel: 'New transaction',
                      onAction: () => context.push('/transactions/new'),
                    )
                  else if (visible.isEmpty)
                    EmptyView(
                      icon: Icons.filter_alt_off_outlined,
                      message: 'No transactions match the current filters.',
                      actionLabel: 'Clear filters',
                      onAction: () => setState(() {
                        _typeFilter = 'All';
                        _accountFilter = null;
                      }),
                    )
                  else
                    for (final transaction in visible)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.sm + 4,
                        ),
                        child: TransactionTile(
                          transaction: transaction,
                          showAccount: _accountFilter == null,
                          onTap: () => context.push(
                            '/transactions/${transaction.transactionReference}',
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

class _FilterBar extends StatelessWidget {
  final String typeFilter;
  final String? accountFilter;
  final List<AccountModel> accounts;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String?> onAccountChanged;

  const _FilterBar({
    required this.typeFilter,
    required this.accountFilter,
    required this.accounts,
    required this.onTypeChanged,
    required this.onAccountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final label in _typeFilters.keys)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: typeFilter == label,
                        onSelected: (_) => onTypeChanged(label),
                      ),
                    ),
                ],
              ),
            ),
            if (accounts.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: accountFilter,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Account',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All accounts'),
                  ),
                  for (final account in accounts)
                    DropdownMenuItem(
                      value: account.accountNumber,
                      child: Text(account.accountNumber),
                    ),
                ],
                onChanged: onAccountChanged,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
