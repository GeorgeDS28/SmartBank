import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Small key/value store for device-local app preferences.
/// Reuses the secure storage plugin already used for the auth token so no
/// extra dependency is needed for settings.
class PreferencesStorage {
  static const _hideBalancesKey = 'pref_hide_balances';

  final FlutterSecureStorage _storage;

  PreferencesStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  Future<bool> getHideBalances() async {
    final value = await _storage.read(key: _hideBalancesKey);
    return value == 'true';
  }

  Future<void> setHideBalances(bool value) =>
      _storage.write(key: _hideBalancesKey, value: value.toString());
}
