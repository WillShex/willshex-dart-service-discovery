import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";
import "../common/services/logging_service.dart";
import "services/console_logging_service.dart";
import "../common/provider.dart";

part "main.svc.dart";

/// Jaspr/Web app entry point.
///
/// Uses ambiguity resolution to inject ConsoleLoggingService.
/// The Provider is imported from common code.
@ConfigureDiscovery()
void main() async {
  print("=== Jaspr Web App ===");
  await Registrar.init(loggingService: ConsoleLoggingService());

  // Use provider from common package (static access)
  final logger = Provider.loggingService;
  logger.log("Hello from Jaspr!");
}
