import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbank/core/theme/app_theme.dart';
import 'package:smartbank/core/utils/validators.dart';
import 'package:smartbank/features/transactionpin/presentation/providers/transaction_pin_provider.dart';

/// Collects the transaction PIN that the backend now demands before it will
/// move money. Returns the six digits, or null if the user backed out.
Future<String?> showTransactionPinSheet(
  BuildContext context, {
  required String action,
  required String detail,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: _PinSheet(action: action, detail: detail),
    ),
  );
}

class _PinSheet extends ConsumerStatefulWidget {
  final String action;
  final String detail;

  const _PinSheet({required this.action, required this.detail});

  @override
  ConsumerState<_PinSheet> createState() => _PinSheetState();
}

class _PinSheetState extends ConsumerState<_PinSheet> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(pinStatusProvider).value;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Confirm with your transaction PIN',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${widget.action} ${widget.detail}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (status != null && !status.pinConfigured)
              _CreatePinPrompt()
            else ...[
              TextFormField(
                controller: _controller,
                autofocus: true,
                obscureText: true,
                maxLength: 6,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
                ),
                enableSuggestions: false,
                autocorrect: false,
                onFieldSubmitted: (_) => _submit(),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: const InputDecoration(
                  labelText: 'Transaction PIN',
                  counterText: '',
                  border: OutlineInputBorder(),
                ),
                validator: Validators.pin,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => context.push('/transaction-pin/reset'),
                child: const Text('Forgot PIN?'),
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton(
                onPressed: _submit,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Text('Confirm'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CreatePinPrompt extends StatelessWidget {
  const _CreatePinPrompt();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'No transaction PIN is set on this account yet, so the bank will not '
          'move any money. Create one first.',
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: () => context.push('/transaction-pin'),
          child: const Text('Create transaction PIN'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
