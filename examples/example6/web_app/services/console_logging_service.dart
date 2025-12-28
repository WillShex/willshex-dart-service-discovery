import "../../common/services/logging_service.dart";

/// Console-based logging implementation for web platforms.
///
/// Uses browser console.log for output.
class ConsoleLoggingService extends LoggingService {
  @override
  Future<void> onInit() async =>
      print("ConsoleLoggingService initialized (Web)");

  @override
  Future<void> onReset() async => print("ConsoleLoggingService reset");

  @override
  void log(String message) {
    print("[WEB LOG] $message");
  }
}
