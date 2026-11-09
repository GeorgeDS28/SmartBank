import 'package:flutter_test/flutter_test.dart';
import 'package:smartbank/core/utils/validators.dart';

void main() {
  group('Validators.amount', () {
    test('rejects empty, non-numeric and non-positive amounts', () {
      expect(Validators.amount(null, field: 'Amount'), 'Amount is required');
      expect(Validators.amount('', field: 'Amount'), 'Amount is required');
      expect(Validators.amount('abc', field: 'Amount'), 'Enter a valid amount');
      expect(
        Validators.amount('0', field: 'Amount'),
        'Amount must be greater than zero',
      );
      expect(
        Validators.amount('-5', field: 'Amount'),
        'Amount must be greater than zero',
      );
    });

    test('accepts the backend minimum of 0.01', () {
      expect(Validators.amount('0.01', field: 'Amount'), isNull);
      expect(Validators.amount('120.50', field: 'Amount'), isNull);
    });

    test('rejects implausibly large amounts', () {
      expect(
        Validators.amount('100000000', field: 'Amount'),
        'Amount is too large',
      );
    });
  });

  group('Validators.email', () {
    test('matches the backend @Email rule', () {
      expect(Validators.email('john@example.com'), isNull);
      expect(Validators.email('not-an-email'), 'Enter a valid email address');
      expect(Validators.email(''), 'Email is required');
    });
  });

  group('Validators.phone', () {
    test('requires exactly ten digits, as the backend does', () {
      expect(Validators.phone('9876543210'), isNull);
      expect(Validators.phone('987654321'), contains('10 digits'));
      expect(Validators.phone('98765432101'), contains('10 digits'));
      expect(Validators.phone('abcdefghij'), contains('10 digits'));
    });
  });

  group('Validators.newPassword', () {
    test('enforces the backend minimum of eight characters', () {
      expect(Validators.newPassword('short'), contains('at least 8'));
      expect(Validators.newPassword('longenough'), isNull);
    });
  });

  group('Validators.futureDate', () {
    test('mirrors the backend @Future constraint on goal target dates', () {
      expect(
        Validators.futureDate(DateTime.now().subtract(const Duration(days: 1))),
        'Date must be in the future',
      );
      expect(
        Validators.futureDate(DateTime.now().add(const Duration(days: 30))),
        isNull,
      );
      expect(Validators.futureDate(null), 'Date is required');
    });
  });

  group('Validators.accountNumber', () {
    test('accepts the SB plus eight digits format the backend generates', () {
      expect(Validators.accountNumber('SB12345678'), isNull);
      expect(Validators.accountNumber(' sb12345678 '), isNull);
    });

    test('rejects anything else', () {
      expect(Validators.accountNumber(''), contains('required'));
      expect(Validators.accountNumber(null), contains('required'));
      expect(Validators.accountNumber('SB1234567'), contains('SB12345678'));
      expect(Validators.accountNumber('SB123456789'), contains('SB12345678'));
      expect(Validators.accountNumber('XX12345678'), contains('SB12345678'));
      expect(Validators.accountNumber('SB1234567a'), contains('SB12345678'));
    });
  });

  group('Validators.pin', () {
    test('accepts exactly six digits, the backend pattern', () {
      expect(Validators.pin('246810'), isNull);
      expect(Validators.pin(' 246810 '), isNull);
    });

    test('rejects the cases @Pattern rejects', () {
      expect(Validators.pin('12345'), contains('exactly 6 digits'));
      expect(Validators.pin('1234567'), contains('exactly 6 digits'));
      expect(Validators.pin('12a456'), contains('exactly 6 digits'));
      expect(Validators.pin(''), contains('required'));
      expect(Validators.pin(null), contains('required'));
    });
  });

  group('Validators.pinConfirmation', () {
    test('accepts a matching pair', () {
      expect(Validators.pinConfirmation('246810', '246810'), isNull);
    });

    test('reports a mismatch only after both entries look valid', () {
      expect(
        Validators.pinConfirmation('12', '246810'),
        contains('exactly 6 digits'),
      );
      expect(
        Validators.pinConfirmation('246811', '246810'),
        'PINs do not match',
      );
    });
  });

  group('Validators.passwordConfirmation', () {
    test('accepts a matching pair that clears the registration length', () {
      expect(
        Validators.passwordConfirmation('NewPass!23', 'NewPass!23'),
        isNull,
      );
    });

    test('reports a mismatch only after the entry is long enough', () {
      expect(
        Validators.passwordConfirmation('abc', 'NewPass!23'),
        contains('at least 8 characters'),
      );
      expect(
        Validators.passwordConfirmation('NewPass!24', 'NewPass!23'),
        'Passwords do not match',
      );
      expect(
        Validators.passwordConfirmation('', 'NewPass!23'),
        contains('required'),
      );
    });
  });
}
