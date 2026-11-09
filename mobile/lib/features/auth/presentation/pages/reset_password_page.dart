import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbank/core/network/api_exception.dart';
import 'package:smartbank/core/theme/app_theme.dart';
import 'package:smartbank/core/utils/validators.dart';
import 'package:smartbank/core/widgets/responsive.dart';
import 'package:smartbank/providers/auth_provider.dart';

/// Step two of recovery: trade the emailed code for a new password. Leaving
/// this screen only happens after the backend confirms the reset, and the
/// server then keeps the password only as a hash.
class ResetPasswordPage extends ConsumerStatefulWidget {
  final String email;

  const ResetPasswordPage({super.key, this.email = ''});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _codeController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final message = await ref
          .read(authProvider.notifier)
          .resetPassword(
            email: _emailController.text.trim(),
            code: _codeController.text.trim(),
            newPassword: _newController.text,
            confirmPassword: _confirmController.text,
          );

      if (!mounted) return;
      _clearSecrets();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message.isEmpty ? 'Password reset' : message)),
      );
      context.go('/login');
    } on ApiException catch (error) {
      if (mounted) {
        _clearSecrets();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _clearSecrets() {
    _codeController.clear();
    _newController.clear();
    _confirmController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set a new password')),
      body: ContentContainer(
        maxWidth: 480,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            children: [
              const Text(
                'Type the six-digit code that was emailed to your account, '
                'then choose the password you want to sign in with.',
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Registered email',
                  border: OutlineInputBorder(),
                ),
                validator: Validators.email,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _codeController,
                obscureText: true,
                maxLength: 6,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
                ),
                enableSuggestions: false,
                autocorrect: false,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: const InputDecoration(
                  labelText: 'Reset code',
                  counterText: '',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    Validators.pin(value, field: 'Reset code'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _newController,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'New password',
                  border: OutlineInputBorder(),
                ),
                validator: Validators.newPassword,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _confirmController,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Confirm new password',
                  border: OutlineInputBorder(),
                ),
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
                      : const Text('Reset password'),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Back to sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
