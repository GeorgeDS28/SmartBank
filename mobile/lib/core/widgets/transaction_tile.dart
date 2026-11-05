import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:smartbank/core/theme/app_theme.dart';
import 'package:smartbank/core/utils/format.dart';
import 'package:smartbank/features/transaction/data/models/transaction_model.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;
  final bool showAccount;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.showAccount = false,
  });

  static bool isCredit(String type) =>
      type == 'DEPOSIT' || type == 'TRANSFER_IN';

  static (IconData, Color) _visual(String type) => switch (type) {
    'DEPOSIT' => (Icons.south_west_rounded, AppColors.positive),
    'WITHDRAW' => (Icons.north_east_rounded, AppColors.negative),
    'TRANSFER_IN' => (Icons.call_received_rounded, AppColors.positive),
    'TRANSFER_OUT' => (Icons.call_made_rounded, AppColors.negative),
    _ => (Icons.receipt_long_outlined, AppColors.navy),
  };

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _visual(transaction.transactionType);
    final credit = isCredit(transaction.transactionType);

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(
          humanizeEnum(transaction.transactionType),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          [
            DateFormat('dd MMM yyyy').format(transaction.createdAt),
            if (transaction.description.isNotEmpty) transaction.description,
            if (showAccount && transaction.accountNumber != null)
              maskAccountNumber(transaction.accountNumber!),
          ].join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          formatSignedCurrency(transaction.amount, isCredit: credit),
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
