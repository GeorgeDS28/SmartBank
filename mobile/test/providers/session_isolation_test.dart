import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbank/core/network/api_client.dart';
import 'package:smartbank/core/network/providers.dart';
import 'package:smartbank/features/account/presentation/providers/accounts_provider.dart';
import 'package:smartbank/features/auth/data/models/login_request.dart';
import 'package:smartbank/providers/auth_provider.dart';

import '../support/fakes.dart';

void main() {
  const george = {
    'accountNumber': 'SB11111111',
    'accountType': 'SAVINGS',
    'balance': 100.0,
    'status': 'ACTIVE',
  };
  const rohan = {
    'accountNumber': 'SB22222222',
    'accountType': 'SAVINGS',
    'balance': 200.0,
    'status': 'ACTIVE',
  };

  late Map<String, StubbedResponse> stubs;
  late FakeApiAdapter adapter;
  late FakeTokenStorage tokens;
  late ProviderContainer container;

  setUp(() {
    stubs = {
      'POST /api/auth/login': const StubbedResponse.ok({'token': 'unused'}),
      'GET /api/accounts': const StubbedResponse.ok([george]),
    };
    adapter = FakeApiAdapter(stubs);
    tokens = FakeTokenStorage(token: null);
    container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(
          ApiClient(tokenStorage: FakeTokenStorage(token: null))
            ..dio.httpClientAdapter = adapter,
        ),
        tokenStorageProvider.overrideWithValue(tokens),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<void> signIn(String email) async {
    stubs['POST /api/auth/login'] = StubbedResponse.ok({
      'token': tokenFor(email),
    });
    await container
        .read(authProvider.notifier)
        .login(LoginRequest(email: email, password: 'password1'));
  }

  Iterable<RequestLog> accountReads() =>
      adapter.log.where((request) => request.key == 'GET /api/accounts');

  group('session isolation', () {
    test(
      'a second login refetches accounts instead of reusing the cache',
      () async {
        await signIn('george@gmail.com');
        expect(
          (await container.read(accountsProvider.future)).single.accountNumber,
          'SB11111111',
        );

        stubs['GET /api/accounts'] = const StubbedResponse.ok([rohan]);

        await signIn('abc@gmail.com');
        final accounts = await container.read(accountsProvider.future);

        expect(accounts.single.accountNumber, 'SB22222222');
        expect(
          accountReads(),
          hasLength(2),
          reason: 'every session has to read its own accounts from the backend',
        );
      },
    );

    test('logout clears the token and the displayed identity', () async {
      await signIn('george@gmail.com');
      expect(container.read(authProvider).email, 'george@gmail.com');

      await container.read(authProvider.notifier).logout();

      expect(tokens.token, isNull);
      expect(container.read(authProvider).status, AuthStatus.unauthenticated);
      expect(container.read(authProvider).email, isNull);
    });

    test(
      'a returning session reads accounts again rather than trusting the cache',
      () async {
        await signIn('george@gmail.com');
        await container.read(accountsProvider.future);

        await container.read(authProvider.notifier).logout();

        stubs['GET /api/accounts'] = const StubbedResponse.ok([george, rohan]);
        await signIn('george@gmail.com');
        final accounts = await container.read(accountsProvider.future);

        expect(accounts, hasLength(2));
        expect(accountReads(), hasLength(2));
      },
    );
  });

  test('the signed-in email is read back from the stored token', () async {
    tokens.token = tokenFor('george@gmail.com');

    container.read(authProvider);
    await Future.delayed(Duration.zero);

    final state = container.read(authProvider);
    expect(state.status, AuthStatus.authenticated);
    expect(state.email, 'george@gmail.com');
  });
}
