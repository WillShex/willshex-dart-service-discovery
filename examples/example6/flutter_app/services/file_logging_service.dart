import "../../common/services/logging_service.dart";

/// File-based logging implementation for Flutter/Desktop platforms.
///
/// In a real app, this would write to a file. For demo purposes,
/// it just prints with a [FILE] prefix.
class FileLoggingService extends LoggingService {
  @override
  Future<void> onInit() async =>
      print("FileLoggingService initialized (Flutter)");

  @override
  Future<void> onReset() async => print("FileLoggingService reset");

  @override
  void log(String message) {
    // In a real implementation, this would write to a file
    print("[FILE LOG] $message");
  }
}
