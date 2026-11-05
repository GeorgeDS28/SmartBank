import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:smartbank/core/network/api_exception.dart';
import 'package:smartbank/core/theme/app_theme.dart';
import 'package:smartbank/core/utils/format.dart';
import 'package:smartbank/core/widgets/app_async_views.dart';
import 'package:smartbank/core/widgets/confirm_dialog.dart';
import 'package:smartbank/core/widgets/responsive.dart';
import 'package:smartbank/core/widgets/section_header.dart';
import 'package:smartbank/features/analytics/presentation/providers/spendable_balance_provider.dart';
import 'package:smartbank/features/goal/data/models/goal_model.dart';
import 'package:smartbank/features/goal/presentation/providers/goals_provider.dart';

class GoalDetailsPage extends ConsumerWidget {
  final int goalId;

  const GoalDetailsPage({super.key, required this.goalId});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(goalProvider(goalId));
    ref.invalidate(goalsProvider);
    await ref.read(goalProvider(goalId).future);
  }

  Future<void> _contribute(BuildContext context, WidgetRef ref) async {
    final amount = await _askAmount(context);
    if (amount == null || !context.mounted) return;

    // The backend refuses to reserve more than the accounts leave free, so the
    // app says the same thing before sending the request.
    final spendable = ref.read(spendableBalanceProvider).value;
    if (spendable != null && !spendable.covers(amount)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Only ${formatCurrency(spendable.spendable)} is free to reserve. '
            'Delete a goal from the list to free money up, or add less.',
          ),
        ),
      );
      return;
    }

    final confirmed = await showConfirmDialog(
      context,
      title: 'Add contribution',
      lines: ['Add ${formatCurrency(amount)} to this goal?'],
      confirmLabel: 'Contribute',
    );
    if (!confirmed) return;

    try {
      await ref.read(goalActionProvider.notifier).contribute(goalId, amount);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Contribution added')));
    } on ApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete goal',
      lines: [
        'This removes the goal and its saved amount.',
        'This cannot be undone.',
      ],
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) return;

    try {
      await ref.read(goalActionProvider.notifier).delete(goalId);
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Goal deleted')));
    } on ApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<double?> _askAmount(BuildContext context) async {
    final controller = TextEditingController();
    double? parsed;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Contribution amount'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount',
            prefixText: '\$ ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              parsed = double.tryParse(controller.text.trim());
              Navigator.pop(dialogContext);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    controller.dispose();
    return (parsed != null && parsed! > 0) ? parsed : null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncGoal = ref.watch(goalProvider(goalId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goal Details'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => _refresh(ref),
          ),
          IconButton(
            tooltip: 'Delete goal',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(context, ref),
          ),
        ],
      ),
      body: asyncGoal.when(
        loading: () => const LoadingView(message: 'Loading goal...'),
        error: (error, _) => ErrorView(
          message: 'Failed to load goal:\n$error',
          onRetry: () => _refresh(ref),
        ),
        data: (goal) => ContentContainer(
          maxWidth: AppSpacing.formMaxWidth * 1.6,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            children: [
              _GoalProgress(goal: goal),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'Details'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Goal name'),
                      trailing: Text(
                        goal.goalName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    ListTile(
                      title: const Text('Status'),
                      trailing: Text(
                        humanizeEnum(goal.status),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    ListTile(
                      title: const Text('Target amount'),
                      trailing: Text(
                        formatCurrency(goal.targetAmount),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    ListTile(
                      title: const Text('Saved so far'),
                      trailing: Text(
                        formatCurrency(goal.currentAmount),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    ListTile(
                      title: const Text('Remaining'),
                      trailing: Text(
                        formatCurrency(goal.remainingAmount),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    ListTile(
                      title: const Text('Target date'),
                      trailing: Text(
                        DateFormat('dd MMM yyyy').format(goal.targetDate),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    ListTile(
                      title: const Text('Created'),
                      trailing: Text(
                        DateFormat('dd MMM yyyy').format(goal.createdAt),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: goal.isCompleted
                    ? null
                    : () => _contribute(context, ref),
                icon: const Icon(Icons.savings_outlined),
                label: Text(goal.isCompleted ? 'Goal completed' : 'Add money'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalProgress extends StatelessWidget {
  final GoalModel goal;

  const _GoalProgress({required this.goal});

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
          Text(
            goal.goalName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${formatCurrency(goal.currentAmount)} of '
            '${formatCurrency(goal.targetAmount)}',
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: goal.progressRatio,
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation(
                goal.isCompleted ? AppColors.positive : Colors.white,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${goal.progressPercentage}% complete',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
