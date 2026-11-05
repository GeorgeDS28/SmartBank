import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbank/core/network/api_exception.dart';
import 'package:smartbank/core/theme/app_theme.dart';
import 'package:smartbank/core/utils/validators.dart';
import 'package:smartbank/core/widgets/app_async_views.dart';
import 'package:smartbank/core/widgets/responsive.dart';
import 'package:smartbank/core/widgets/section_header.dart';
import 'package:smartbank/features/transactionpin/presentation/providers/transaction_pin_provider.dart';

class TransactionPinPage extends ConsumerWidget {
  const TransactionPinPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStatus = ref.watch(pinStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Transaction PIN')),
      body: asyncStatus.when(
        loading: () => const LoadingView(message: 'Checking your PIN...'),
        error: (error, _) => ErrorView(
          message: 'Failed to check your transaction PIN:\n$error',
          onRetry: () => ref.invalidate(pinStatusProvider),
        ),
        data: (status) => ContentContainer(
          maxWidth: 480,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            children: [
              _StatusCard(configured: status.pinConfigured),
              const SizedBox(height: AppSpacing.lg),
              SectionHeader(
                title: status.pinConfigured ? 'Change PIN' : 'Set up PIN',
              ),
              const SizedBox(height: AppSpacing.sm),
              // The key rebuilds the form, and clears the entered PIN, when
              // the backend status flips after a successful save.
              _PinForm(
                key: ValueKey(status.pinConfigured),
                configured: status.pinConfigured,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final bool configured;

  const _StatusCard({required this.configured});

  @override
  Widget build(BuildContext context) {
    final color = configured ? AppColors.positive : AppColors.amber;

    return Card(
      child: ListTile(
        leading: Icon(
          configured ? Icons.lock_outline : Icons.lock_open,
          color: color,
        ),
        title: Text(configured ? 'PIN configured' : 'No PIN yet'),
        subtitle: Text(
          configured ? 'SmartBank keeps only a hashed copy of your PIN.' : 'Create a six-digit PIN to add a second factor to this account.',
        ),
      ),
    );
  }
}

class _PinForm extends ConsumerStatefulWidget {
  final bool configured;

  const _PinForm({super.key, required this.configured});

  @override
  ConsumerState<_PinForm> createState() => _PinFormState();
}

class _PinFormState extends ConsumerState<_PinForm> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _revealed = false;

  bool get _configured => widget.configured;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final pin = _newController.text.trim();
    final confirm = _confirmController.text.trim();

    try {
      if (_configured) {
        await ref
            .read(pinActionProvider.notifier)
            .change(
              currentPin: _currentController.text.trim(),
              newPin: pin,
              confirmNewPin: confirm,
            );
      } else {
        await ref
            .read(pinActionProvider.notifier)
            .setup(pin: pin, confirmPin: confirm);
      }

      if (!mounted) return;
      _clearEntries();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _configured ? 'Transaction PIN changed' : 'Transaction PIN created',
          ),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) {
        // A rejected current PIN must not stay on screen.
        _clearEntries();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  void _clearEntries() {
    _currentController.clear();
    _newController.clear();
    _confirmController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(pinActionProvider).isLoading;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_configured) ...[
            _PinField(
              label: 'Current PIN',
              controller: _currentController,
              revealed: _revealed,
              enabled: !pending,
              validator: (value) => Validators.pin(value, field: 'Current PIN'),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          _PinField(
            label: _configured ? 'New PIN' : 'PIN',
            controller: _newController,
            revealed: _revealed,
            enabled: !pending,
            validator: (value) =>
                Validators.pin(value, field: _configured ? 'New PIN' : 'PIN'),
          ),
          const SizedBox(height: AppSpacing.md),
          _PinField(
            label: _configured ? 'Confirm new PIN' : 'Confirm PIN',
            controller: _confirmController,
            revealed: _revealed,
            enabled: !pending,
            validator: (value) => Validators.pinConfirmation(
              value,
              _newController.text,
              field: 'Confirm PIN',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _configured
                ? 'Six digits. An incorrect current PIN counts towards the '
                      'lock: five wrong attempts disable PIN changes for 15 '
                      'minutes.'
                : 'Six digits. The backend hashes the PIN and never stores it '
                      'in plain text.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: pending ? null : _submit,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: pending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_configured ? 'Change PIN' : 'Create PIN'),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _revealed = !_revealed),
            child: Text(_revealed ? 'Hide PINs' : 'Show PINs'),
          ),
          if (_configured)
            TextButton(
              onPressed: () => context.push('/transaction-pin/reset'),
              child: const Text('Forgot your PIN? Reset with your password'),
            ),
        ],
      ),
    );
  }
}

/// Obscured by default, digits only, capped at six characters, and never
/// echoed to a log or persisted on the device.
class _PinField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool revealed;
  final bool enabled;
  final FormFieldValidator<String> validator;

  const _PinField({
    required this.label,
    required this.controller,
    required this.revealed,
    required this.enabled,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: !revealed,
      maxLength: 6,
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      textInputAction: TextInputAction.next,
      enableSuggestions: false,
      autocorrect: false,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }
}
