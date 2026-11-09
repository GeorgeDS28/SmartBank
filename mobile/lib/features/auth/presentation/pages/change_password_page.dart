import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbank/core/network/api_exception.dart';
import 'package:smartbank/core/theme/app_theme.dart';
import 'package:smartbank/core/utils/validators.dart';
import 'package:smartbank/core/widgets/responsive.dart';
import 'package:smartbank/providers/auth_provider.dart';

/// Voluntary password change from inside a session. The backend re-checks the
/// current password against its hash before it stores a new one, and the
/// existing token stays valid - signing out is the user's own choice.
class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _submitting = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final current = _currentController.text;
    final fresh = _newController.text;
    final confirm = _confirmController.text;

    setState(() => _submitting = true);
    try {
      await ref
          .read(authProvider.notifier)
          .changePassword(
            currentPassword: current,
            newPassword: fresh,
            confirmPassword: confirm,
          );

      if (!mounted) return;
      _clearEntries();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Password changed')));
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

  /// A changed credential must not linger in the field controllers, whether
  /// the update landed or was refused.
  void _clearEntries() {
    _currentController.clear();
    _newController.clear();
    _confirmController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change password')),
      body: ContentContainer(
        maxWidth: 480,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            children: [
              const Text(
                'Confirm the password you sign in with, then choose a new one. '
                'You stay signed in on this device.',
              ),
              const SizedBox(height: AppSpacing.lg),
              _PasswordField(
                label: 'Current password',
                controller: _currentController,
                validator: (value) =>
                    Validators.required(value, field: 'Current password'),
              ),
              const SizedBox(height: AppSpacing.md),
              _PasswordField(
                label: 'New password',
                controller: _newController,
                validator: Validators.newPassword,
              ),
              const SizedBox(height: AppSpacing.md),
              _PasswordField(
                label: 'Confirm new password',
                controller: _confirmController,
                validator: (value) => Validators.passwordConfirmation(
                  value,
                  _newController.text,
                  field: 'Confirm new password',
                ),
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
                      : const Text('Update password'),
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

class _PasswordField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final FormFieldValidator<String> validator;

  const _PasswordField({
    required this.label,
    required this.controller,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      enableSuggestions: false,
      autocorrect: false,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }
}
