import "dart:async";

import "package:meta/meta.dart";

/// A base class for services that require initialization.
///
/// This class ensures that public methods are only called after [init]
/// has been called, and not after [reset] has been called (unless [init]
/// is called again).
abstract class Service {
  /// Initializes the service.
  ///
  /// Calls [onInit] to perform the actual initialization logic.
  FutureOr<void> init();

  /// Resets the service.
  ///
  /// Calls [onReset] to perform the actual reset/cleanup logic.
  @mustCallSuper
  FutureOr<void> reset();
}
