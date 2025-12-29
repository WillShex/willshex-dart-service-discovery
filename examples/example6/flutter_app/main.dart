import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";
import "../common/services/logging_service.dart";
import "services/file_logging_service.dart";
import "../common/provider.dart";

part "main.svc.dart";

/// Flutter/Desktop app entry point.
///
/// Uses ambiguity resolution to inject FileLoggingService.
/// The Provider is imported from common code.
@DiscoveryRegistrar()
void main() async {
  print("=== Flutter App ===");
  await Registrar.init(loggingService: FileLoggingService());

  // Use provider from common package (static access)
  final logger = Provider.loggingService;
  logger.log("Hello from Flutter!");
}
