import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";
import "services/implementation_a.dart";
import "services/implementation_b.dart";

part "main.svc.dart";

@DiscoveryProvider(
  concrete: [
    ImplementationA,
    ImplementationB,
  ],
)
abstract class Trigger {}

@DiscoveryRegistrar(
  // Scenario 3: Multiple Concrete Registration
  // Register specific implementations by their concrete type
  // This allows direct access to ImplementationA and ImplementationB
  concrete: [
    ImplementationA,
    ImplementationB,
  ],
)
void main() async {
  await Registrar.init();

  // Access concrete implementations directly
  print("Provider.implementationA: ${Provider.implementationA}");
  print("Provider.implementationB: ${Provider.implementationB}");
}
