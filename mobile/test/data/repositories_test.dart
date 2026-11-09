import 'package:flutter_test/flutter_test.dart';
import 'package:smartbank/core/network/api_exception.dart';
import 'package:smartbank/features/account/data/repositories/account_repository_impl.dart';
import 'package:smartbank/features/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:smartbank/features/auth/data/models/login_request.dart';
import 'package:smartbank/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:smartbank/features/goal/data/repositories/goal_repository_impl.dart';
import 'package:smartbank/features/transaction/data/repositories/transaction_repository_impl.dart';
import 'package:smartbank/features/transactionpin/data/repositories/transaction_pin_repository_impl.dart';

import '../support/fakes.dart';

void main() {
  group('AccountRepositoryImpl', () {
    test('lists accounts', () async {
      final repository = AccountRepositoryImpl(
        buildFakeClient({
          'GET /api/accounts': const StubbedResponse.ok([
            {
              'accountNumber': 'SB1',
              'accountType': 'SAVINGS',
              'balance': 100,
              'status': 'ACTIVE',
            },
            {
              'accountNumber': 'SB2',
              'accountType': 'CURRENT',
              'balance': 250,
              'status': 'BLOCKED',
            },
          ]),
        }),
      );

      final accounts = await repository.getAccounts();

      expect(accounts, hasLength(2));
      expect(accounts.last.status, 'BLOCKED');
    });

    test('attaches the stored JWT to protected calls', () async {
      final client = buildFakeClient({
        'GET /api/accounts': const StubbedResponse.ok([]),
      });

      await AccountRepositoryImpl(client).getAccounts();

      final header = (client.dio.httpClientAdapter as FakeApiAdapter)
          .lastRequest!
          .headers['Authorization'];
      expect(header, 'Bearer test-jwt');
    });

    test('does not attach a JWT to auth endpoints', () async {
      final client = buildFakeClient({
        'POST /api/auth/login': const StubbedResponse.ok({'token': 'jwt'}),
      });

      await AuthRepositoryImpl(
        client,
      ).login(LoginRequest(email: 'john@example.com', password: 'Password123'));

      final headers =
          (client.dio.httpClientAdapter as FakeApiAdapter).lastRequest!.headers;
      expect(headers.containsKey('Authorization'), isFalse);
    });

    test('maps a 404 into an ApiException with the backend message', () async {
      final repository = AccountRepositoryImpl(
        buildFakeClient({
          'GET /api/accounts/NOPE': const StubbedResponse(404, {
            'message': 'Account not found',
            'error': 'Account Not Found',
          }),
        }),
      );

      expect(
        () => repository.getAccount('NOPE'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 404)
              .having((e) => e.message, 'message', 'Account not found'),
        ),
      );
    });

    test('a 5xx never leaks the backend trace into the message', () async {
      final repository = AccountRepositoryImpl(
        buildFakeClient({
          'GET /api/accounts/SB1': const StubbedResponse(500, {
            'message': 'could not execute statement [Duplicate entry ...] [insert into transactions (...)]',
          }),
        }),
      );

      expect(
        () => repository.getAccount('SB1'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having(
                (e) => e.message,
                'message',
                'SmartBank could not complete the request. Please try again.',
              ),
        ),
      );
    });

    test(
      'creates an account with the accountType field the backend expects',
      () async {
        final client = buildFakeClient({
          'POST /api/accounts': const StubbedResponse(201, {
            'accountNumber': 'SB9',
            'accountType': 'SAVINGS',
            'balance': 0,
            'status': 'ACTIVE',
          }),
        });

        final created = await AccountRepositoryImpl(client)
            .createAccount('SAVINGS');

        expect(created.accountNumber, 'SB9');
        expect(
          (client.dio.httpClientAdapter as FakeApiAdapter).lastRequest!.body,
          {'accountType': 'SAVINGS'},
        );
      },
    );

    test('closeAccount posts to the close path and maps CLOSED back', () async {
      final client = buildFakeClient({
        'POST /api/accounts/SB9/close': const StubbedResponse.ok({
          'accountNumber': 'SB9',
          'accountType': 'SAVINGS',
          'balance': 0,
          'status': 'CLOSED',
        }),
      });

      final closed = await AccountRepositoryImpl(client).closeAccount('SB9');

      expect(closed.status, 'CLOSED');
      expect(
        (client.dio.httpClientAdapter as FakeApiAdapter).lastRequest!.key,
        'POST /api/accounts/SB9/close',
      );
    });

    test('a funded account surfaces the backend reason for refusing', () async {
      final client = buildFakeClient({
        'POST /api/accounts/SB9/close': const StubbedResponse(400, {
          'message':
              'Withdraw the remaining balance before closing this account.',
        }),
      });

      await expectLater(
        AccountRepositoryImpl(client).closeAccount('SB9'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            'Withdraw the remaining balance before closing this account.',
          ),
        ),
      );
    });
  });

  group('TransactionRepositoryImpl', () {
    test('deposit posts only the amount, matching DepositRequest', () async {
      final client = buildFakeClient({
        'POST /api/accounts/SB1/deposit': const StubbedResponse.ok({
          'accountNumber': 'SB1',
          'depositedAmount': 500,
          'currentBalance': 500.00,
          'message': 'Deposit successful',
        }),
      });

      final repository = TransactionRepositoryImpl(
        client,
        AccountRepositoryImpl(client),
      );
      final result = await repository.deposit(
        accountNumber: 'SB1',
        amount: 500,
        pin: '246810',
      );

      expect(result.currentBalance, 500);
      final body =
          (client.dio.httpClientAdapter as FakeApiAdapter).lastRequest!.body
              as Map<String, dynamic>;
      expect(body.keys, ['amount', 'pin'], reason: 'the backend needs a PIN');
    });

    test('surfaces the insufficient-balance message from a 400', () async {
      final client = buildFakeClient({
        'POST /api/accounts/SB1/withdraw': const StubbedResponse(400, {
          'status': 400,
          'error': 'Insufficient Balance',
          'message': 'Insufficient balance',
          'validationErrors': null,
        }),
      });

      final repository = TransactionRepositoryImpl(
        client,
        AccountRepositoryImpl(client),
      );

      expect(
        () => repository.withdraw(
          accountNumber: 'SB1',
          amount: 999999,
          pin: '246810',
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Insufficient balance',
          ),
        ),
      );
    });

    test('transfer posts the description the backend does accept', () async {
      final client = buildFakeClient({
        'POST /api/accounts/transfer': const StubbedResponse.ok({
          'message': 'Transfer successful',
          'fromAccountNumber': 'SB1',
          'toAccountNumber': 'SB2',
          'amount': 50,
        }),
      });

      await TransactionRepositoryImpl(
        client,
        AccountRepositoryImpl(client),
      ).transfer(
        fromAccountNumber: 'SB1',
        toAccountNumber: 'SB2',
        amount: 50,
        pin: '246810',
        description: 'rent',
      );

      final body =
          (client.dio.httpClientAdapter as FakeApiAdapter).lastRequest!.body
              as Map<String, dynamic>;
      expect(body['description'], 'rent');
    });

    test('aggregates history across accounts, newest first', () async {
      final client = buildFakeClient({
        'GET /api/accounts': const StubbedResponse.ok([
          {
            'accountNumber': 'SB1',
            'accountType': 'SAVINGS',
            'balance': 100,
            'status': 'ACTIVE',
          },
          {
            'accountNumber': 'SB2',
            'accountType': 'CURRENT',
            'balance': 100,
            'status': 'ACTIVE',
          },
        ]),
        'GET /api/accounts/SB1/transactions': const StubbedResponse.ok([
          {
            'transactionReference': 'TXN_OLD',
            'transactionType': 'DEPOSIT',
            'amount': 10,
            'description': 'Cash Deposit',
            'createdAt': '2026-01-01T10:00:00',
          },
        ]),
        'GET /api/accounts/SB2/transactions': const StubbedResponse.ok([
          {
            'transactionReference': 'TXN_NEW',
            'transactionType': 'WITHDRAW',
            'amount': 5,
            'description': 'Cash Withdrawal',
            'createdAt': '2026-06-01T10:00:00',
          },
        ]),
      });

      final repository = TransactionRepositoryImpl(
        client,
        AccountRepositoryImpl(client),
      );
      final transactions = await repository.getTransactions();

      expect(transactions.map((t) => t.transactionReference), [
        'TXN_NEW',
        'TXN_OLD',
      ]);
      expect(transactions.first.accountNumber, 'SB2');
    });
  });

  group('GoalRepositoryImpl', () {
    test('serialises targetDate as yyyy-MM-dd for LocalDate', () async {
      final client = buildFakeClient({
        'POST /api/goals': const StubbedResponse(201, {
          'id': 4,
          'goalName': 'Laptop',
          'targetAmount': 1500,
          'currentAmount': 0,
          'progressPercentage': 0,
          'status': 'IN_PROGRESS',
          'targetDate': '2026-12-31',
          'createdAt': '2026-11-03T23:02:51.001104',
        }),
      });

      final goal = await GoalRepositoryImpl(client).createGoal(
        goalName: 'Laptop',
        targetAmount: 1500,
        targetDate: DateTime(2026, 12, 31),
      );

      expect(goal.id, 4);
      final body =
          (client.dio.httpClientAdapter as FakeApiAdapter).lastRequest!.body
              as Map<String, dynamic>;
      expect(body['targetDate'], '2026-12-31');
    });

    test('contribute posts only the amount', () async {
      final client = buildFakeClient({
        'POST /api/goals/4/contribute': const StubbedResponse.ok({
          'id': 4,
          'goalName': 'Laptop',
          'targetAmount': 1500.00,
          'currentAmount': 300.00,
          'progressPercentage': 20,
          'status': 'IN_PROGRESS',
          'targetDate': '2026-12-31',
          'createdAt': '2026-11-03T23:02:51.001104',
        }),
      });

      final goal = await GoalRepositoryImpl(client).contribute(4, 300);

      expect(goal.progressPercentage, 20);
      expect(
        (client.dio.httpClientAdapter as FakeApiAdapter).lastRequest!.key,
        'POST /api/goals/4/contribute',
      );
    });

    test('reports a missing goal as a 404 ApiException', () async {
      final repository = GoalRepositoryImpl(
        buildFakeClient({
          'POST /api/goals/999/contribute': const StubbedResponse(404, {
            'message': 'Goal not found',
            'status': 404,
          }),
        }),
      );

      expect(
        () => repository.contribute(999, 10),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });
  });

  group('AnalyticsRepositoryImpl', () {
    test('reads the financial summary', () async {
      final summary = await AnalyticsRepositoryImpl(
        buildFakeClient({
          'GET /api/analytics/financial-summary': const StubbedResponse.ok({
            'totalBalance': 24850.75,
            'totalDeposits': 5000,
            'totalWithdrawals': 206.45,
            'totalTransferredIn': 0,
            'totalTransferredOut': 500,
            'netCashFlow': 4293.55,
            'totalGoalSavings': 2300,
          }),
        }),
      ).getFinancialSummary();

      expect(summary.totalBalance, 24850.75);
      expect(summary.netCashFlow, 4293.55);
    });

    test('reads an empty monthly list without throwing', () async {
      final months = await AnalyticsRepositoryImpl(
        buildFakeClient({
          'GET /api/analytics/monthly': const StubbedResponse.ok([]),
        }),
      ).getMonthlyActivity();

      expect(months, isEmpty);
    });
  });

  group('AuthRepositoryImpl', () {
    test('login returns the token from LoginResponse', () async {
      final client = buildFakeClient({
        'POST /api/auth/login': const StubbedResponse.ok({'token': 'jwt-abc'}),
      });

      final response = await AuthRepositoryImpl(
        client,
      ).login(LoginRequest(email: 'john@example.com', password: 'Password123'));

      expect(response.token, 'jwt-abc');
    });

    test('invalid credentials surface the backend message', () async {
      final repository = AuthRepositoryImpl(
        buildFakeClient({
          'POST /api/auth/login': const StubbedResponse(401, {
            'message': 'Invalid email or password',
          }),
        }),
      );

      await expectLater(
        repository.login(
          LoginRequest(email: 'john@example.com', password: 'wrong'),
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'message', 'Invalid email or password')
              .having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });

    test(
      'changePassword posts the three names ChangePasswordRequest has',
      () async {
        final client = buildFakeClient({
          'PUT /api/auth/change-password': const StubbedResponse(200, {
            'message': 'Password changed successfully',
          }),
        });

        await AuthRepositoryImpl(client).changePassword(
          currentPassword: 'OldPass!23',
          newPassword: 'NewPass!23',
          confirmPassword: 'NewPass!23',
        );

        final request =
            (client.dio.httpClientAdapter as FakeApiAdapter).lastRequest!;
        expect(request.key, 'PUT /api/auth/change-password');
        expect(request.body, {
          'currentPassword': 'OldPass!23',
          'newPassword': 'NewPass!23',
          'confirmPassword': 'NewPass!23',
        });
      },
    );

    test('a refused password change surfaces the backend reason', () async {
      final repository = AuthRepositoryImpl(
        buildFakeClient({
          'PUT /api/auth/change-password': const StubbedResponse(401, {
            'message': 'Current password does not match',
          }),
        }),
      );

      await expectLater(
        repository.changePassword(
          currentPassword: 'wrong',
          newPassword: 'NewPass!23',
          confirmPassword: 'NewPass!23',
        ),
        throwsA(
          isA<ApiException>()
              .having(
                (e) => e.message,
                'message',
                'Current password does not match',
              )
              .having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });

    test('forgotPassword sends only the email and repeats the reply', () async {
      final client = buildFakeClient({
        'POST /api/auth/forgot-password': const StubbedResponse.ok({
          'message': 'If that email belongs to an account, a reset code has been sent.',
        }),
      });

      final message = await AuthRepositoryImpl(client)
          .forgotPassword(email: 'john@example.com');

      final request =
          (client.dio.httpClientAdapter as FakeApiAdapter).lastRequest!;
      expect(request.key, 'POST /api/auth/forgot-password');
      expect(request.body, {'email': 'john@example.com'});
      expect(
        message,
        'If that email belongs to an account, a reset code has been sent.',
      );
    });

    test('a server-side mail failure keeps the app-wide 5xx message', () async {
      final repository = AuthRepositoryImpl(
        buildFakeClient({
          'POST /api/auth/forgot-password': const StubbedResponse(503, {
            'message': 'Email delivery is not configured on this server',
          }),
        }),
      );

      await expectLater(
        repository.forgotPassword(email: 'john@example.com'),
        throwsA(
          isA<ApiException>()
              .having(
                (e) => e.message,
                'message',
                'SmartBank could not complete the request. Please try again.',
              )
              .having((e) => e.statusCode, 'statusCode', 503),
        ),
      );
    });

    test(
      'resetPassword posts the four names ResetPasswordRequest has',
      () async {
        final client = buildFakeClient({
          'POST /api/auth/reset-password': const StubbedResponse.ok({
            'message': 'Password reset successfully',
          }),
        });

        final message = await AuthRepositoryImpl(client).resetPassword(
          email: 'john@example.com',
          code: '246813',
          newPassword: 'Recovered!23',
          confirmPassword: 'Recovered!23',
        );

        final request =
            (client.dio.httpClientAdapter as FakeApiAdapter).lastRequest!;
        expect(request.key, 'POST /api/auth/reset-password');
        expect(request.body.keys, [
          'email',
          'code',
          'newPassword',
          'confirmPassword',
        ]);
        expect(request.body['code'], '246813');
        expect(message, 'Password reset successfully');
      },
    );
  });

  group('TransactionPinRepositoryImpl', () {
    test('reads the PIN status', () async {
      final repository = TransactionPinRepositoryImpl(
        buildFakeClient({
          'GET /api/transaction-pin/status': const StubbedResponse.ok({
            'pinConfigured': true,
            'message': 'Transaction PIN already configured',
          }),
        }),
      );

      final status = await repository.getStatus();

      expect(status.pinConfigured, isTrue);
      expect(status.message, 'Transaction PIN already configured');
    });

    test('posts both entries under the field names the DTO expects', () async {
      final client = buildFakeClient({
        'POST /api/transaction-pin/setup': const StubbedResponse(
          201,
          'Transaction PIN created successfully',
        ),
      });

      await TransactionPinRepositoryImpl(client)
          .setup(pin: '246810', confirmPin: '246810');

      final request =
          (client.dio.httpClientAdapter as FakeApiAdapter).lastRequest!;
      expect(request.key, 'POST /api/transaction-pin/setup');
      expect(request.body, {'pin': '246810', 'confirmPin': '246810'});
    });

    test('sends current, new and confirmation on change', () async {
      final client = buildFakeClient({
        'PUT /api/transaction-pin/change': const StubbedResponse(
          200,
          'Transaction PIN changed successfully',
        ),
      });

      await TransactionPinRepositoryImpl(
        client,
      ).change(currentPin: '246810', newPin: '135790', confirmNewPin: '135790');

      final request =
          (client.dio.httpClientAdapter as FakeApiAdapter).lastRequest!;
      expect(request.key, 'PUT /api/transaction-pin/change');
      expect(request.body, {
        'currentPin': '246810',
        'newPin': '135790',
        'confirmNewPin': '135790',
      });
    });

    test(
      'an incorrect PIN surfaces as a 403 with the backend reason',
      () async {
        final repository = TransactionPinRepositoryImpl(
          buildFakeClient({
            'PUT /api/transaction-pin/change': const StubbedResponse(403, {
              'status': 403,
              'error': 'Incorrect Transaction PIN',
              'message': 'Incorrect transaction PIN',
            }),
          }),
        );

        await expectLater(
          repository.change(
            currentPin: '000000',
            newPin: '135790',
            confirmNewPin: '135790',
          ),
          throwsA(
            isA<ApiException>()
                .having(
                  (e) => e.message,
                  'message',
                  'Incorrect transaction PIN',
                )
                .having((e) => e.statusCode, 'statusCode', 403),
          ),
        );
      },
    );

    test('a locked PIN is reported rather than swallowed', () async {
      final repository = TransactionPinRepositoryImpl(
        buildFakeClient({
          'PUT /api/transaction-pin/change': const StubbedResponse(423, {
            'status': 423,
            'error': 'Transaction PIN Locked',
            'message': 'Too many incorrect PIN attempts. Try again later.',
          }),
        }),
      );

      await expectLater(
        repository.change(
          currentPin: '111111',
          newPin: '135790',
          confirmNewPin: '135790',
        ),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 423),
        ),
      );
    });
  });
}
