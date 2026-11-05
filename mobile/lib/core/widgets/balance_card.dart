import 'package:flutter/material.dart';

import 'package:smartbank/core/theme/app_theme.dart';
import 'package:smartbank/core/utils/format.dart';

class BalanceCard extends StatelessWidget {
  final double totalBalance;
  final int numberOfAccounts;
  final int totalTransactions;
  final bool masked;

  const BalanceCard({
    super.key,
    required this.totalBalance,
    this.numberOfAccounts = 0,
    this.totalTransactions = 0,
    this.masked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        gradient: const LinearGradient(
          colors: [AppColors.navyDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Balance',
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: AppSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              masked ? '••••••••' : formatCurrency(totalBalance),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _Metric(label: 'Accounts', value: '$numberOfAccounts'),
              const SizedBox(width: AppSpacing.lg),
              _Metric(label: 'Transactions', value: '$totalTransactions'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}
