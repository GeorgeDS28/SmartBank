import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbank/core/theme/app_theme.dart';
import 'package:smartbank/core/widgets/responsive.dart';
import 'package:smartbank/core/widgets/section_header.dart';
import 'package:smartbank/features/user/presentation/providers/settings_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hideBalances = ref.watch(hideBalancesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ContentContainer(
        maxWidth: 640,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          children: [
            const SectionHeader(title: 'Privacy'),
            Card(
              child: SwitchListTile(
                title: const Text('Hide balances'),
                subtitle: const Text(
                  'Mask monetary amounts on the profile summary.',
                ),
                value: hideBalances,
                onChanged: (value) =>
                    ref.read(hideBalancesProvider.notifier).set(value),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: 'About'),
            Card(
              child: Column(
                children: const [
                  ListTile(
                    title: Text('Application'),
                    trailing: Text('SmartBank', style: _valueStyle),
                  ),
                  ListTile(
                    title: Text('Version'),
                    trailing: Text('1.0.0', style: _valueStyle),
                  ),
                  ListTile(
                    title: Text('Backend'),
                    subtitle: Text('Spring Boot REST API'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _valueStyle = TextStyle(fontWeight: FontWeight.w600);
