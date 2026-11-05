import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbank/core/theme/app_theme.dart';
import 'package:smartbank/core/widgets/responsive.dart';
import 'package:smartbank/providers/auth_provider.dart';

class _Destination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;

  const _Destination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
  });

  static const destinations = <_Destination>[
    _Destination(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      route: '/dashboard',
    ),
    _Destination(
      label: 'Accounts',
      icon: Icons.account_balance_outlined,
      selectedIcon: Icons.account_balance,
      route: '/accounts',
    ),
    _Destination(
      label: 'Transactions',
      icon: Icons.swap_horiz_outlined,
      selectedIcon: Icons.swap_horiz,
      route: '/transactions',
    ),
    _Destination(
      label: 'Goals',
      icon: Icons.flag_outlined,
      selectedIcon: Icons.flag,
      route: '/goals',
    ),
    _Destination(
      label: 'Analytics',
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights,
      route: '/analytics',
    ),
    _Destination(
      label: 'Profile',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      route: '/profile',
    ),
  ];
}

class AppShell extends ConsumerStatefulWidget {
  final int selectedIndex;
  final Widget child;

  const AppShell({super.key, required this.selectedIndex, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  void _go(int index) {
    if (index == widget.selectedIndex) return;
    context.go(_Destination.destinations[index].route);
  }

  @override
  Widget build(BuildContext context) {
    final layout = layoutFor(context);
    final isWide = layout == LayoutKind.desktop;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (isWide) _Sidebar(index: widget.selectedIndex),
            Expanded(child: widget.child),
          ],
        ),
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: widget.selectedIndex,
              onDestinationSelected: _go,
              destinations: [
                for (final destination in _Destination.destinations)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: destination.label,
                  ),
              ],
            ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  final int index;

  const _Sidebar({required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 260,
      color: AppColors.navy,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.lg,
            ),
            child: Row(
              children: [
                Icon(Icons.account_balance, color: Colors.white),
                SizedBox(width: AppSpacing.sm + 4),
                Text(
                  'SmartBank',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              children: [
                for (var i = 0; i < _Destination.destinations.length; i++)
                  _SidebarItem(
                    destination: _Destination.destinations[i],
                    selected: i == index,
                    onTap: () => context.go(_Destination.destinations[i].route),
                  ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          ListTile(
            iconColor: Colors.white70,
            textColor: Colors.white70,
            leading: const Icon(Icons.logout),
            title: const Text('Log out'),
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: selected ? Colors.white.withValues(alpha: 0.10) : null,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        child: Row(
          children: [
            Icon(
              selected ? destination.selectedIcon : destination.icon,
              color: selected ? Colors.white : Colors.white70,
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              destination.label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
