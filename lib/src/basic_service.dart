import "dart:async";

import "package:meta/meta.dart";
import "service.dart";

abstract class BasicService extends Service {
  bool _isInitialized = false;

  /// Whether the service is currently initialized.
  bool get isInitialized => _isInitialized;

  @override
  Future<void> init() async {
    if (_isInitialized) {
      return;
    }
    await onInit();
    _isInitialized = true;
  }

  @override
  Future<void> reset() async {
    await onReset();
    _isInitialized = false;
  }

  /// Verifies that the service is initialized.
  ///
  /// This method should be called at the beginning of every public method
  /// (except [init] and [reset]) to ensure the service is in a valid state.
  ///
  /// Throws a [StateError] if the service is not initialized.
  @protected
  void verifyInitialized() {
    if (!_isInitialized) {
      throw StateError(
          "Service $runtimeType is not initialized. Call init() first.");
    }
  }

  /// Called when the service is being initialized.
  ///
  /// Subclasses should implement this method to perform initialization logic.
  @protected
  FutureOr<void> onInit();

  /// Called when the service is being reset.
  ///
  /// Subclasses should implement this method to perform reset/cleanup logic.
  @protected
  FutureOr<void> onReset();
}
