import 'package:flutter/material.dart';

import 'package:smartbank/core/theme/app_theme.dart';
import 'package:smartbank/core/utils/format.dart';
import 'package:smartbank/features/user/data/models/account_model.dart';

class AccountCard extends StatelessWidget {
  final AccountModel account;
  final VoidCallback? onTap;

  const AccountCard({super.key, required this.account, this.onTap});

  static (IconData, Color) _visual(String type) => switch (type) {
    'SAVINGS' => (Icons.savings_outlined, AppColors.positive),
    'CURRENT' => (Icons.credit_card_outlined, AppColors.primary),
    _ => (Icons.account_balance_outlined, AppColors.navy),
  };

  static Color _statusColor(String status) => switch (status) {
    'ACTIVE' => AppColors.positive,
    'BLOCKED' => AppColors.negative,
    'CLOSED' => AppColors.negative,
    _ => AppColors.amber,
  };

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _visual(account.accountType);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      humanizeEnum(account.accountType),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      maskAccountNumber(account.accountNumber),
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _StatusBadge(
                      label: humanizeEnum(account.status),
                      color: _statusColor(account.status),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency(account.balance),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (account.status != 'ACTIVE')
                    Text(
                      'unavailable',
                      style: TextStyle(fontSize: 12, color: AppColors.negative),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
