import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbank/core/network/api_exception.dart';
import 'package:smartbank/core/utils/validators.dart';
import 'package:smartbank/core/widgets/app_async_views.dart';
import 'package:smartbank/features/account/presentation/providers/accounts_provider.dart';
import 'package:smartbank/features/analytics/presentation/providers/spendable_balance_provider.dart';
import 'package:smartbank/features/transaction/presentation/providers/transactions_provider.dart';
import 'package:smartbank/features/transactionpin/presentation/widgets/transaction_pin_sheet.dart';
import 'package:smartbank/features/user/data/models/account_model.dart';

enum MoneyAction { deposit, withdraw, transfer }

class NewTransactionPage extends ConsumerStatefulWidget {
  final String? initialAccountNumber;
  final MoneyAction? initialAction;

  const NewTransactionPage({
    super.key,
    this.initialAccountNumber,
    this.initialAction,
  });

  @override
  ConsumerState<NewTransactionPage> createState() => _NewTransactionPageState();
}

class _NewTransactionPageState extends ConsumerState<NewTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _destinationController = TextEditingController();

  MoneyAction _action = MoneyAction.deposit;
  String? _sourceAccount;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _action = widget.initialAction ?? MoneyAction.deposit;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _onAccountsLoaded(List<AccountModel> accounts) {
    if (_sourceAccount != null &&
        accounts.any((a) => a.accountNumber == _sourceAccount)) {
      return;
    }
    final preferred =
        widget.initialAccountNumber != null &&
            accounts.any((a) => a.accountNumber == widget.initialAccountNumber)
        ? widget.initialAccountNumber
        : accounts.firstOrNull?.accountNumber;
    if (preferred != null && preferred != _sourceAccount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _sourceAccount = preferred);
      });
    }
  }

  double? _parseAmount() => double.tryParse(_amountController.text.trim());

  String? _validateAmount(String? value) =>
      Validators.amount(value, field: 'Amount');

  String get _destinationAccount =>
      Validators.normalizeAccountNumber(_destinationController.text);

  String? _validateDestination(String? value) {
    final error = Validators.accountNumber(value);
    if (error != null) return error;
    if (Validators.normalizeAccountNumber(value!) == _sourceAccount) {
      return 'Choose a destination account other than the source';
    }
    return null;
  }

  Future<bool> _confirm(List<AccountModel> accounts) async {
    final source = accounts.firstWhere(
      (a) => a.accountNumber == _sourceAccount,
    );
    final amount = _parseAmount()!;
    final destination = _action == MoneyAction.transfer
        ? _destinationAccount
        : null;

    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(
              _action.name[0].toUpperCase() + _action.name.substring(1),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Amount: \$${amount.toStringAsFixed(2)}'),
                Text(
                  _action == MoneyAction.transfer
                      ? 'From ${source.accountNumber} to $destination'
                      : 'Account ${source.accountNumber}',
                ),
                const SizedBox(height: 8),
                Text(
                  'Balance: \$${source.balance.toStringAsFixed(2)}',
                  // The dialog's own context: this page can be deactivated
                  // while the dialog is still rebuilding.
                  style: Theme.of(dialogContext).textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _submit(List<AccountModel> accounts) async {
    if (!_formKey.currentState!.validate()) return;

    final amount = _parseAmount()!;

    if (_action != MoneyAction.deposit && amount > _balanceOf(accounts)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Insufficient balance: $_sourceAccount holds '
            '\$${_balanceOf(accounts).toStringAsFixed(2)}.',
          ),
        ),
      );
      return;
    }

    // Money leaving the bank - a withdrawal, or a transfer to somebody else -
    // has to fit inside what the goals leave free. Transfers between two of the
    // user's own accounts move nothing out, so they are not limited by it.
    if (_leavesTheBank(accounts)) {
      final spendable = ref.read(spendableBalanceProvider).value;
      if (spendable != null && !spendable.covers(amount)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Only \$${spendable.spendable.toStringAsFixed(2)} is spendable. '
              '\$${spendable.reservedInGoals.toStringAsFixed(2)} is reserved in '
              'your savings goals.',
            ),
          ),
        );
        return;
      }
    }

    if (!await _confirm(accounts)) return;
    if (!mounted) return;

    // The backend declines any money movement without a transaction PIN, so
    // it is collected here rather than assumed to be part of the session.
    final pin = await showTransactionPinSheet(
      context,
      action: _action.name[0].toUpperCase() + _action.name.substring(1),
      detail: '\$${amount.toStringAsFixed(2)}',
    );
    if (pin == null || !mounted) return;

    setState(() => _submitting = true);
    try {
      final notifier = ref.read(moneyActionProvider.notifier);
      final message = switch (_action) {
        MoneyAction.deposit => await notifier.deposit(
          accountNumber: _sourceAccount!,
          amount: amount,
          pin: pin,
        ),
        MoneyAction.withdraw => await notifier.withdraw(
          accountNumber: _sourceAccount!,
          amount: amount,
          pin: pin,
        ),
        MoneyAction.transfer => await notifier.transfer(
          fromAccountNumber: _sourceAccount!,
          toAccountNumber: _destinationAccount,
          amount: amount,
          pin: pin,
          description: _descriptionController.text.trim(),
        ),
      };

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      context.pop();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
        // 428 means no PIN exists on the account yet, so the only way forward
        // is to create one.
        if (error.statusCode == 428) {
          context.push('/transaction-pin');
        }
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  double _balanceOf(List<AccountModel> accounts) =>
      accounts.firstWhere((a) => a.accountNumber == _sourceAccount).balance;

  bool _leavesTheBank(List<AccountModel> accounts) =>
      _action == MoneyAction.withdraw ||
      (_action == MoneyAction.transfer &&
          !accounts.any((a) => a.accountNumber == _destinationAccount));

  @override
  Widget build(BuildContext context) {
    final asyncAccounts = ref.watch(accountsProvider);
    final spendable = ref.watch(spendableBalanceProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('New Transaction')),
      body: asyncAccounts.when(
        loading: () => const LoadingView(message: 'Loading accounts...'),
        error: (error, _) => ErrorView(
          message: 'Failed to load accounts:\n$error',
          onRetry: () => ref.invalidate(accountsProvider),
        ),
        data: (accounts) {
          if (accounts.isEmpty) {
            return const EmptyView(
              message: 'Open an account before making a transaction.',
            );
          }
          _onAccountsLoaded(accounts);

          final activeAccounts = accounts
              .where((a) => a.status == 'ACTIVE')
              .toList(growable: false);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SegmentedButton<MoneyAction>(
                        segments: const [
                          ButtonSegment(
                            value: MoneyAction.deposit,
                            label: Text('Deposit'),
                            icon: Icon(Icons.south_west),
                          ),
                          ButtonSegment(
                            value: MoneyAction.withdraw,
                            label: Text('Withdraw'),
                            icon: Icon(Icons.north_east),
                          ),
                          ButtonSegment(
                            value: MoneyAction.transfer,
                            label: Text('Transfer'),
                            icon: Icon(Icons.swap_horiz),
                          ),
                        ],
                        selected: {_action},
                        onSelectionChanged: _submitting
                            ? null
                            : (value) => setState(() => _action = value.first),
                      ),
                      const SizedBox(height: 24),
                      _AccountDropdown(
                        label: _action == MoneyAction.transfer
                            ? 'From account'
                            : 'Account',
                        accounts: activeAccounts,
                        value: _sourceAccount,
                        enabled: !_submitting,
                        onChanged: (value) =>
                            setState(() => _sourceAccount = value),
                      ),
                      if (_action == MoneyAction.transfer) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _destinationController,
                          enabled: !_submitting,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'To account number',
                            helperText: "Recipient's SmartBank account, e.g. SB12345678",
                            border: OutlineInputBorder(),
                          ),
                          validator: _validateDestination,
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        enabled: !_submitting,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          prefixText: '\$ ',
                          border: OutlineInputBorder(),
                        ),
                        validator: _validateAmount,
                      ),
                      if (_action != MoneyAction.deposit && spendable != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'Available to spend: '
                            '\$${spendable.spendable.toStringAsFixed(2)} of '
                            '\$${spendable.totalBalance.toStringAsFixed(2)} total'
                            '${spendable.reservedInGoals > 0 ? ' · \$${spendable.reservedInGoals.toStringAsFixed(2)} reserved in goals' : ''}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      if (_action == MoneyAction.transfer) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          enabled: !_submitting,
                          maxLength: 100,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            hintText: 'Optional',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      if (_action != MoneyAction.transfer)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'SmartBank records deposits and withdrawals with a '
                            'fixed description; custom notes are only supported '
                            'for transfers.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _submitting || _sourceAccount == null
                            ? null
                            : () => _submit(accounts),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: _submitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _action == MoneyAction.deposit
                                      ? 'Deposit'
                                      : _action == MoneyAction.withdraw
                                      ? 'Withdraw'
                                      : 'Transfer',
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AccountDropdown extends StatelessWidget {
  final String label;
  final List<AccountModel> accounts;
  final String? value;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  const _AccountDropdown({
    required this.label,
    required this.accounts,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: accounts.any((a) => a.accountNumber == value)
          ? value
          : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final account in accounts)
          DropdownMenuItem(
            value: account.accountNumber,
            child: Text(
              '${account.accountNumber}  ·  \$${account.balance.toStringAsFixed(2)}',
            ),
          ),
      ],
      onChanged: enabled ? onChanged : null,
    );
  }
}
