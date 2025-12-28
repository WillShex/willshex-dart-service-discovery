import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";
import "services/service_a.dart";
import "services/service_b.dart";

part "main.svc.dart";

@ConfigureDiscovery(
  registrar: "Registrar",
)
void main() async {
  // Circular Dependency A <-> B
  // Should fail build.
  await Registrar.init();
}
