import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:smartbank/core/widgets/app_async_views.dart';
import 'package:smartbank/features/transaction/presentation/providers/transactions_provider.dart';

class TransactionDetailsPage extends ConsumerWidget {
  final String transactionReference;

  const TransactionDetailsPage({super.key, required this.transactionReference});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTransactions = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Transaction Details')),
      body: asyncTransactions.when(
        loading: () => const LoadingView(message: 'Loading transaction...'),
        error: (error, _) =>
            ErrorView(message: 'Failed to load transaction:\n$error'),
        data: (list) {
          final transaction = list
              .where((t) => t.transactionReference == transactionReference)
              .firstOrNull;

          if (transaction == null) {
            return const EmptyView(
              message:
                  'Transaction not found. It may belong to an account '
                  'that is no longer accessible.',
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _DetailRow(
                label: 'Reference',
                value: transaction.transactionReference,
              ),
              _DetailRow(
                label: 'Type',
                value: transaction.transactionType.replaceAll('_', ' '),
              ),
              _DetailRow(
                label: 'Amount',
                value: NumberFormat.currency(symbol: '\$')
                    .format(transaction.amount),
              ),
              _DetailRow(
                label: 'Date',
                value: DateFormat('dd MMM yyyy, hh:mm a')
                    .format(transaction.createdAt),
              ),
              _DetailRow(label: 'Description', value: transaction.description),
              if (transaction.accountNumber != null)
                _DetailRow(label: 'Account', value: transaction.accountNumber!),
            ],
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
