import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbank/core/network/providers.dart';

class HideBalancesNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    state = await ref.read(preferencesStorageProvider).getHideBalances();
  }

  Future<void> set(bool value) async {
    state = value;
    await ref.read(preferencesStorageProvider).setHideBalances(value);
  }
}

final hideBalancesProvider = NotifierProvider<HideBalancesNotifier, bool>(
  HideBalancesNotifier.new,
);
