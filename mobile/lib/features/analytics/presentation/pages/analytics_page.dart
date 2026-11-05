import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbank/core/theme/app_theme.dart';
import 'package:smartbank/core/utils/format.dart';
import 'package:smartbank/core/widgets/app_async_views.dart';
import 'package:smartbank/core/widgets/charts.dart';
import 'package:smartbank/core/widgets/responsive.dart';
import 'package:smartbank/core/widgets/section_header.dart';
import 'package:smartbank/features/analytics/data/models/analytics_models.dart';
import 'package:smartbank/features/analytics/presentation/providers/analytics_provider.dart';

class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(financialSummaryProvider);
    ref.invalidate(monthlyActivityProvider);
    ref.invalidate(goalAnalyticsProvider);
    ref.invalidate(transferAnalyticsProvider);
    await ref.read(financialSummaryProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(financialSummaryProvider);
    final monthly = ref.watch(monthlyActivityProvider);
    final goals = ref.watch(goalAnalyticsProvider);
    final transfers = ref.watch(transferAnalyticsProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Analytics'),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: () => _refresh(ref),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Monthly activity'),
              Tab(text: 'Goals & transfers'),
            ],
          ),
        ),
        body: summary.when(
          loading: () => const LoadingView(message: 'Loading analytics...'),
          error: (error, _) => ErrorView(
            message: 'Failed to load analytics:\n$error',
            onRetry: () => _refresh(ref),
          ),
          data: (data) => TabBarView(
            children: [
              _OverviewTab(summary: data),
              _MonthlyTab(monthly: monthly),
              _GoalsAndTransfersTab(goals: goals, transfers: transfers),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final FinancialSummaryModel summary;

  const _OverviewTab({required this.summary});

  @override
  Widget build(BuildContext context) {
    return ContentContainer(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          const SectionHeader(title: 'Balance movement'),
          ResponsiveGrid(
            children: [
              StatCard(
                label: 'Total balance',
                value: formatCurrency(summary.totalBalance),
                icon: Icons.account_balance_wallet_outlined,
                color: AppColors.primary,
              ),
              StatCard(
                label: 'Net cash flow',
                value: formatCurrency(summary.netCashFlow),
                icon: Icons.trending_up,
                color: summary.netCashFlow >= 0
                    ? AppColors.positive
                    : AppColors.negative,
                caption: 'Inflow minus outflow',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Money in versus money out'),
          DonutChart(
            centerLabel: 'inflow',
            centerValue: formatCurrency(summary.totalInflow),
            slices: [
              DonutSlice(
                label: 'Deposits',
                value: summary.totalDeposits,
                color: AppColors.positive,
              ),
              DonutSlice(
                label: 'Transferred in',
                value: summary.totalTransferredIn,
                color: AppColors.violet,
              ),
              DonutSlice(
                label: 'Withdrawals',
                value: summary.totalWithdrawals,
                color: AppColors.negative,
              ),
              DonutSlice(
                label: 'Transferred out',
                value: summary.totalTransferredOut,
                color: AppColors.amber,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Totals'),
          Card(
            child: Column(
              children: [
                _AmountRow(
                  'Deposits',
                  summary.totalDeposits,
                  AppColors.positive,
                ),
                _AmountRow(
                  'Withdrawals',
                  summary.totalWithdrawals,
                  AppColors.negative,
                ),
                _AmountRow(
                  'Transferred in',
                  summary.totalTransferredIn,
                  AppColors.violet,
                ),
                _AmountRow(
                  'Transferred out',
                  summary.totalTransferredOut,
                  AppColors.amber,
                ),
                _AmountRow(
                  'Saved in goals',
                  summary.totalGoalSavings,
                  AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _AmountRow(this.label, this.amount, this.color);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm + 4),
          Text(label),
        ],
      ),
      trailing: Text(
        formatCurrency(amount),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _MonthlyTab extends ConsumerWidget {
  final AsyncValue<List<MonthlyActivityModel>> monthly;

  const _MonthlyTab({required this.monthly});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return monthly.when(
      loading: () => const LoadingView(message: 'Loading monthly activity...'),
      error: (error, _) => ErrorView(
        message: 'Failed to load monthly activity:\n$error',
        onRetry: () => ref.invalidate(monthlyActivityProvider),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return const EmptyView(
            icon: Icons.bar_chart_outlined,
            message: 'No monthly activity yet. Transactions will appear here.',
          );
        }

        const recent = 6;
        final window = entries.length <= recent
            ? entries
            : entries.sublist(entries.length - recent);

        return ContentContainer(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            children: [
              const SectionHeader(title: 'Inflow versus outflow'),
              GroupedBarChart(
                series: const [
                  ChartSeries(label: 'Inflow', color: AppColors.positive),
                  ChartSeries(label: 'Outflow', color: AppColors.negative),
                ],
                groups: [
                  for (final entry in window)
                    BarGroup(
                      label: entry.month.length > 3
                          ? entry.month.substring(0, 3)
                          : entry.month,
                      values: [entry.inflow, entry.outflow],
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'By month'),
              Card(
                child: Column(
                  children: [
                    for (final entry in entries.reversed)
                      ListTile(
                        title: Text(entry.month),
                        subtitle: Text(
                          'Deposits ${formatCurrency(entry.deposits)} · '
                          'Withdrawals ${formatCurrency(entry.withdrawals)}',
                        ),
                        trailing: Text(
                          formatSignedCurrency(
                            entry.inflow - entry.outflow,
                            isCredit: entry.inflow - entry.outflow >= 0,
                          ),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: entry.inflow >= entry.outflow
                                ? AppColors.positive
                                : AppColors.negative,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GoalsAndTransfersTab extends ConsumerWidget {
  final AsyncValue<GoalAnalyticsModel> goals;
  final AsyncValue<TransferAnalyticsModel> transfers;

  const _GoalsAndTransfersTab({required this.goals, required this.transfers});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ContentContainer(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          const SectionHeader(title: 'Goals'),
          goals.when(
            loading: () => const _InlineLoading(),
            error: (error, _) => ErrorView(
              message: 'Failed to load goal analytics:\n$error',
              onRetry: () => ref.invalidate(goalAnalyticsProvider),
            ),
            data: (data) => ResponsiveGrid(
              children: [
                StatCard(
                  label: 'Active goals',
                  value: '${data.activeGoals} of ${data.totalGoals}',
                  icon: Icons.flag_outlined,
                  color: AppColors.violet,
                  caption: '${data.completedGoals} completed',
                ),
                StatCard(
                  label: 'Overall progress',
                  value: '${data.overallProgress.toStringAsFixed(0)}%',
                  icon: Icons.trending_up,
                  color: AppColors.primary,
                  caption:
                      '${formatCurrency(data.totalSavedAmount)} of '
                      '${formatCurrency(data.totalTargetAmount)}',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Transfers'),
          transfers.when(
            loading: () => const _InlineLoading(),
            error: (error, _) => ErrorView(
              message: 'Failed to load transfer analytics:\n$error',
              onRetry: () => ref.invalidate(transferAnalyticsProvider),
            ),
            data: (data) => ResponsiveGrid(
              children: [
                StatCard(
                  label: 'Transfers',
                  value: '${data.totalTransfers}',
                  icon: Icons.swap_horiz,
                  color: AppColors.primary,
                ),
                StatCard(
                  label: 'Net transfer',
                  value: formatCurrency(data.netTransferAmount),
                  icon: Icons.balance_outlined,
                  color: data.netTransferAmount >= 0
                      ? AppColors.positive
                      : AppColors.negative,
                  caption:
                      '${formatCurrency(data.totalTransferredIn)} in · '
                      '${formatCurrency(data.totalTransferredOut)} out',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineLoading extends StatelessWidget {
  const _InlineLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
