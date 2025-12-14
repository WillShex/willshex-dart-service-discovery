import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";
import "services/implementation_a.dart";
import "services/implementation_b.dart";

part "main.svc.dart";

@ConfigureDiscovery(
  provider: "Provider",
  registrar: "Registrar",
  // Scenario 3: Multiple Concrete Registration
  // We want to register both A and B as themselves, avoiding ambiguity on the Interface
  concrete: [
    ImplementationA,
    ImplementationB,
  ],
)
void main() async {
  // abstractService is still ambiguous if considered alone, but because we explicitly register
  // A and B, we can access them directly.
  // The 'abstractService' ambiguity might still force an init param if the generator detects it as an interface.
  // BUT the user might not care about 'AbstractService' resolution if they only care about concrete access.
  // Let's see if the generator still requires 'abstractService' in init(). Yes it will if it detects it.
  // So we pass one, or if we don't need AbstractService resolution, maybe we shouldn't care?
  // But init() parameters are required. So we must pass something.

  await Registrar.init();

  print("Provider.implementationA: ${Provider.implementationA}");
  print("Provider.implementationB: ${Provider.implementationB}");
}
