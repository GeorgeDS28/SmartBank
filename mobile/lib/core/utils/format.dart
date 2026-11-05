import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

String formatCurrency(num value) => _currency.format(value);

/// Signed form used by transaction lists: money leaving the account is
/// rendered as a debit, money arriving as a credit.
String formatSignedCurrency(num value, {required bool isCredit}) =>
    '${isCredit ? '+' : '-'}${_currency.format(value.abs())}';

String maskAccountNumber(String accountNumber) {
  if (accountNumber.length <= 4) return accountNumber;
  final visible = accountNumber.substring(accountNumber.length - 4);
  return '••••$visible';
}

String humanizeEnum(String value) {
  final words = value.toLowerCase().split('_');
  return words
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');
}
