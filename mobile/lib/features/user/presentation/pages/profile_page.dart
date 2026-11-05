import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbank/core/theme/app_theme.dart';
import 'package:smartbank/core/utils/format.dart';
import 'package:smartbank/core/widgets/app_async_views.dart';
import 'package:smartbank/core/widgets/confirm_dialog.dart';
import 'package:smartbank/core/widgets/responsive.dart';
import 'package:smartbank/core/widgets/section_header.dart';
import 'package:smartbank/features/account/presentation/providers/accounts_provider.dart';
import 'package:smartbank/features/user/presentation/providers/dashboard_provider.dart';
import 'package:smartbank/features/user/presentation/providers/settings_provider.dart';
import 'package:smartbank/features/transactionpin/presentation/providers/transaction_pin_provider.dart';
import 'package:smartbank/providers/auth_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Log out',
      lines: ['You will need to sign in again to access your accounts.'],
      confirmLabel: 'Log out',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    await ref.read(authProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAccounts = ref.watch(accountsProvider);
    final hideBalances = ref.watch(hideBalancesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ContentContainer(
        maxWidth: 640,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          children: [
            const _IdentityCard(),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: 'Banking summary'),
            asyncAccounts.when(
              loading: () => const _InlineLoading(),
              error: (error, _) => ErrorView(
                message: 'Failed to load account summary:\n$error',
                onRetry: () => ref.invalidate(accountsProvider),
              ),
              data: (accounts) {
                final total = accounts.fold<double>(
                  0,
                  (sum, a) => sum + a.balance,
                );
                return ResponsiveGrid(
                  children: [
                    StatCard(
                      label: 'Accounts',
                      value: '${accounts.length}',
                      icon: Icons.account_balance_outlined,
                      color: AppColors.primary,
                    ),
                    StatCard(
                      label: 'Combined balance',
                      value: hideBalances ? '••••••' : formatCurrency(total),
                      icon: Icons.account_balance_wallet_outlined,
                      color: AppColors.positive,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: 'Account'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.security_outlined),
                    title: const Text('Session security'),
                    subtitle: const Text(
                      'Signed in with a JWT stored on this device',
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.pin_outlined),
                    title: const Text('Transaction PIN'),
                    subtitle: _PinStatusSummary(),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/transaction-pin'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Settings'),
                    subtitle: const Text('Balance privacy and app preferences'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/settings'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.negative,
                side: const BorderSide(color: AppColors.negative),
              ),
              onPressed: () => _logout(context, ref),
              icon: const Icon(Icons.logout),
              label: const Text('Log out'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reports what the backend says about the PIN, without assuming a state.
class _PinStatusSummary extends ConsumerWidget {
  const _PinStatusSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStatus = ref.watch(pinStatusProvider);

    return Text(
      asyncStatus.when(
        loading: () => 'Checking PIN status...',
        error: (error, _) => 'PIN status unavailable',
        data: (status) =>
            status.pinConfigured ? 'Configured' : 'Not configured yet',
      ),
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}

/// Shows the email carried by the signed-in token, which is the only identity
/// the backend makes available to the client - it exposes no profile endpoint
/// returning a name or date of birth.
class _IdentityCard extends ConsumerWidget {
  const _IdentityCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final asyncDashboard = ref.watch(dashboardProvider);
    final email = auth.email;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary,
              child: email == null
                  ? const Icon(
                      Icons.person_outline,
                      size: 30,
                      color: Colors.white,
                    )
                  : Text(
                      email.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    email ?? 'SmartBank account',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    auth.status == AuthStatus.authenticated
                        ? 'Your session is active.'
                        : 'Your session has ended.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (asyncDashboard.hasValue) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${asyncDashboard.value!.numberOfAccounts} accounts · '
                      '${asyncDashboard.value!.totalTransactions} transactions',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
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
