/// Form validators mirroring the backend Bean Validation rules so the user
/// sees the same rejection reasons the API would return.
class Validators {
  const Validators._();

  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _phone = RegExp(r'^[0-9]{10}$');

  /// Backend generates "SB" followed by exactly eight digits.
  static final RegExp _accountNumber = RegExp(r'^SB[0-9]{8}$');

  static String? required(String? value, {required String field}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? email(String? value) {
    final error = required(value, field: 'Email');
    if (error != null) return error;
    if (!_email.hasMatch(value!.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? phone(String? value) {
    final error = required(value, field: 'Phone');
    if (error != null) return error;
    if (!_phone.hasMatch(value!.trim())) {
      return 'Phone number must contain exactly 10 digits';
    }
    return null;
  }

  /// Backend requires at least 8 characters on registration.
  static String? newPassword(String? value) {
    final error = required(value, field: 'Password');
    if (error != null) return error;
    if (value!.length < 8) return 'Password must contain at least 8 characters';
    return null;
  }

  /// The backend compares the two password entries itself, so a typo is caught
  /// here rather than after the request goes out.
  static String? passwordConfirmation(
    String? value,
    String? original, {
    String field = 'Confirm password',
  }) {
    final error = newPassword(value);
    if (error != null) return error;
    if (value!.trim() != original?.trim()) return 'Passwords do not match';
    return null;
  }

  static String? amount(String? value, {String field = 'Amount'}) {
    final error = required(value, field: field);
    if (error != null) return error;
    final parsed = double.tryParse(value!.trim());
    if (parsed == null) return 'Enter a valid amount';
    if (parsed < 0.01) return '$field must be greater than zero';
    if (parsed > 99999999) return '$field is too large';
    return null;
  }

  /// Mirrors @Future on the goal target date.
  static String? futureDate(DateTime? value, {String field = 'Date'}) {
    if (value == null) return '$field is required';
    if (!value.isAfter(DateTime.now())) return '$field must be in the future';
    return null;
  }

  static String? accountNumber(String? value) {
    final error = required(value, field: 'Account number');
    if (error != null) return error;
    if (!_accountNumber.hasMatch(normalizeAccountNumber(value!))) {
      return 'Enter a valid SmartBank account number, e.g. SB12345678';
    }
    return null;
  }

  /// Account numbers are case-sensitive in the backend, so typing them in
  /// lower case is normalised before sending.
  static String normalizeAccountNumber(String value) =>
      value.trim().toUpperCase();

  /// Backend validates every transaction PIN field with ^[0-9]{6}$.
  static final RegExp _pin = RegExp(r'^[0-9]{6}$');

  static String? pin(String? value, {String field = 'PIN'}) {
    final error = required(value, field: field);
    if (error != null) return error;
    if (!_pin.hasMatch(value!.trim())) {
      return '$field must contain exactly 6 digits';
    }
    return null;
  }

  /// The backend compares the two entries itself, so the form says the same
  /// thing before the request goes out.
  static String? pinConfirmation(
    String? value,
    String? original, {
    String field = 'Confirm PIN',
  }) {
    final error = pin(value, field: field);
    if (error != null) return error;
    if (value!.trim() != original?.trim()) return 'PINs do not match';
    return null;
  }
}
