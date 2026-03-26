import 'package:flutter_riverpod/flutter_riverpod.dart';

final updateProvider = NotifierProvider<UpdateNotifier, bool>(UpdateNotifier.new);

class UpdateNotifier extends Notifier<bool> {
  @override
  bool build() {
    // Initial state: true means an update check needs to potentially show a popup. 
    // Usually, this is backed by an API checking the semver against remote.
    // For this demonstration, we flag it as an available update.
    return true;
  }

  void markUpdateDismissed() {
    state = false;
  }
}
