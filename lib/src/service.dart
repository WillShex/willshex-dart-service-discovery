import "package:meta/meta.dart";

/// A base class for services that require initialization.
///
/// This class ensures that public methods are only called after [init]
/// has been called, and not after [reset] has been called (unless [init]
/// is called again).
abstract class Service {
  bool _isInitialized = false;

  /// Whether the service is currently initialized.
  bool get isInitialized => _isInitialized;

  /// Initializes the service.
  ///
  /// Calls [onInit] to perform the actual initialization logic.
  @mustCallSuper
  Future<void> init() async {
    if (_isInitialized) {
      return;
    }
    await onInit();
    _isInitialized = true;
  }

  /// Resets the service.
  ///
  /// Calls [onReset] to perform the actual reset/cleanup logic.
  @mustCallSuper
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
  Future<void> onInit();

  /// Called when the service is being reset.
  ///
  /// Subclasses should implement this method to perform reset/cleanup logic.
  @protected
  Future<void> onReset();
}
