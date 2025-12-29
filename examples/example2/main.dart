import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";

import "services/abstract_service.dart";
import "services/implementation_a.dart";

part "main.svc.dart";

@DiscoveryProvider()
abstract class Trigger {}

@DiscoveryRegistrar(
    // No explicit registration here.
    // This example demonstrates Ambiguity Resolution via Injection.
    )
void main() async {
  // AbstractService has 2 impls (A, B).
  // init() requires us to pass one.

  await Registrar.init(abstractService: ImplementationA());

  print(
      "Provider.abstractService: ${Provider.abstractService}"); // Should be ImplementationA
}
