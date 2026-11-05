import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbank/core/network/api_client.dart';
import 'package:smartbank/core/storage/preferences_storage.dart';
import 'package:smartbank/core/storage/token_storage.dart';

/// Single shared instances so no feature constructs its own Dio or touches
/// secure storage directly, which also keeps tests able to override them.
final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// Increments every time the signed-in identity changes.
///
/// Data repositories watch it so logging out, or logging in as somebody else,
/// throws away the previous session's accounts, transactions, goals and
/// analytics instead of showing them to the next user.
final sessionIdProvider = NotifierProvider<SessionIdNotifier, int>(
  SessionIdNotifier.new,
);

class SessionIdNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void next() => state = state + 1;
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(tokenStorage: ref.watch(tokenStorageProvider));
});

final preferencesStorageProvider = Provider<PreferencesStorage>((ref) {
  return PreferencesStorage();
});
