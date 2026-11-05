import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:smartbank/core/network/api_exception.dart';
import 'package:smartbank/core/theme/app_theme.dart';
import 'package:smartbank/core/utils/format.dart';
import 'package:smartbank/core/utils/validators.dart';
import 'package:smartbank/core/widgets/app_async_views.dart';
import 'package:smartbank/core/widgets/confirm_dialog.dart';
import 'package:smartbank/core/widgets/responsive.dart';
import 'package:smartbank/core/widgets/section_header.dart';
import 'package:smartbank/features/goal/data/models/goal_model.dart';
import 'package:smartbank/features/goal/presentation/providers/goals_provider.dart';

class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(goalsProvider);
    await ref.read(goalsProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncGoals = ref.watch(goalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Goals'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => _refresh(ref),
          ),
          IconButton(
            tooltip: 'New goal',
            icon: const Icon(Icons.add),
            onPressed: () => showCreateGoalSheet(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCreateGoalSheet(context, ref),
        icon: const Icon(Icons.flag),
        label: const Text('New goal'),
      ),
      body: asyncGoals.when(
        loading: () => const LoadingView(message: 'Loading goals...'),
        error: (error, _) => ErrorView(
          message: 'Failed to load goals:\n$error',
          onRetry: () => _refresh(ref),
        ),
        data: (goals) {
          if (goals.isEmpty) {
            return EmptyView(
              icon: Icons.flag_outlined,
              message: 'You have no savings goals yet. Set one to track your progress.',
              actionLabel: 'Create a goal',
              onAction: () => showCreateGoalSheet(context, ref),
            );
          }

          final totalSaved = goals.fold<double>(
            0,
            (sum, goal) => sum + goal.currentAmount,
          );
          final totalTarget = goals.fold<double>(
            0,
            (sum, goal) => sum + goal.targetAmount,
          );

          return RefreshIndicator(
            onRefresh: () => _refresh(ref),
            child: ContentContainer(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                children: [
                  ResponsiveGrid(
                    children: [
                      StatCard(
                        label: 'Goals',
                        value: '${goals.length}',
                        icon: Icons.flag_outlined,
                        color: AppColors.violet,
                      ),
                      StatCard(
                        label: 'Saved towards goals',
                        value: formatCurrency(totalSaved),
                        icon: Icons.savings_outlined,
                        color: AppColors.positive,
                        caption: 'of ${formatCurrency(totalTarget)} targeted',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const SectionHeader(title: 'Your goals'),
                  for (final goal in goals)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: GoalCard(goal: goal),
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

class GoalCard extends ConsumerWidget {
  final GoalModel goal;

  const GoalCard({super.key, required this.goal});

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete ${goal.goalName}',
      lines: [
        if (goal.currentAmount > 0)
          'This goal holds ${formatCurrency(goal.currentAmount)}, which becomes '
              'spendable again.',
        'This cannot be undone.',
      ],
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) return;

    try {
      await ref.read(goalActionProvider.notifier).delete(goal.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Goal deleted')));
    } on ApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = goal.isCompleted ? AppColors.positive : AppColors.primary;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        onTap: () => context.push('/goals/${goal.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      goal.goalName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _GoalStatusChip(goal: goal),
                  IconButton(
                    tooltip: 'Delete goal',
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _delete(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${formatCurrency(goal.currentAmount)} of '
                '${formatCurrency(goal.targetAmount)}',
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: goal.progressRatio,
                  minHeight: 8,
                  backgroundColor: color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${goal.progressPercentage}% complete'),
                  Text(
                    'Target ${DateFormat('dd MMM yyyy').format(goal.targetDate)}',
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

class _GoalStatusChip extends StatelessWidget {
  final GoalModel goal;

  const _GoalStatusChip({required this.goal});

  @override
  Widget build(BuildContext context) {
    final color = switch (goal.status) {
      'COMPLETED' => AppColors.positive,
      'CANCELLED' => AppColors.negative,
      _ => AppColors.amber,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        humanizeEnum(goal.status),
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

Future<void> showCreateGoalSheet(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _CreateGoalForm(),
  );
}

class _CreateGoalForm extends ConsumerStatefulWidget {
  const _CreateGoalForm();

  @override
  ConsumerState<_CreateGoalForm> createState() => _CreateGoalFormState();
}

class _CreateGoalFormState extends ConsumerState<_CreateGoalForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _targetDate = DateTime.now().add(const Duration(days: 90));
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(goalActionProvider.notifier)
          .create(
            goalName: _nameController.text.trim(),
            targetAmount: double.parse(_amountController.text.trim()),
            targetDate: _targetDate,
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Goal created')));
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Create a goal',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _nameController,
              enabled: !_saving,
              maxLength: 60,
              decoration: const InputDecoration(
                labelText: 'Goal name',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  Validators.required(value, field: 'Goal name'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _amountController,
              enabled: !_saving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Target amount',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
              validator: (value) => Validators.amount(value, field: 'Target'),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: _saving ? null : _pickDate,
              icon: const Icon(Icons.event_outlined),
              label: Text(
                'Target date: ${DateFormat('dd MMM yyyy').format(_targetDate)}',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create goal'),
            ),
          ],
        ),
      ),
    );
  }
}
