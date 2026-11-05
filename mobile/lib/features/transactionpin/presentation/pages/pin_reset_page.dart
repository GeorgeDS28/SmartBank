import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbank/core/network/api_exception.dart';
import 'package:smartbank/core/theme/app_theme.dart';
import 'package:smartbank/core/utils/validators.dart';
import 'package:smartbank/core/widgets/responsive.dart';
import 'package:smartbank/features/transactionpin/presentation/providers/transaction_pin_provider.dart';

/// Forgotten PIN. The backend only accepts a new PIN after the login password
/// is re-checked, and a successful reset also lifts the attempt lock.
class PinResetPage extends ConsumerStatefulWidget {
  const PinResetPage({super.key});

  @override
  ConsumerState<PinResetPage> createState() => _PinResetPageState();
}

class _PinResetPageState extends ConsumerState<PinResetPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final password = _passwordController.text;
    final newPin = _newController.text.trim();
    final confirm = _confirmController.text.trim();

    setState(() => _submitting = true);
    try {
      await ref
          .read(pinActionProvider.notifier)
          .reset(password: password, newPin: newPin, confirmNewPin: confirm);

      if (!mounted) return;
      _clearEntries();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Transaction PIN reset')));
      context.pop();
    } on ApiException catch (error) {
      if (mounted) {
        _clearEntries();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  bool _submitting = false;

  void _clearEntries() {
    _passwordController.clear();
    _newController.clear();
    _confirmController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset transaction PIN')),
      body: ContentContainer(
        maxWidth: 480,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            children: [
              const Text(
                'Confirm the password you use to sign in, then choose a new '
                'six-digit PIN.',
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Account password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    Validators.required(value, field: 'Password'),
              ),
              const SizedBox(height: AppSpacing.md),
              _PinField(
                label: 'New PIN',
                controller: _newController,
                validator: (value) => Validators.pin(value, field: 'New PIN'),
              ),
              const SizedBox(height: AppSpacing.md),
              _PinField(
                label: 'Confirm new PIN',
                controller: _confirmController,
                validator: (value) =>
                    Validators.pinConfirmation(value, _newController.text),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Reset PIN'),
                ),
              ),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final FormFieldValidator<String> validator;

  const _PinField({
    required this.label,
    required this.controller,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      maxLength: 6,
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
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
