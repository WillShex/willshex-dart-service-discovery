import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";

import "services/another_example_service.dart";
import "services/example_service.dart";

part "main.svc.dart";

@Discovery()
abstract class Trigger {}

@ConfigureDiscovery()
void main(List<String> args) async {
  await Registrar.init();
  print("Service Discovery Configured and Initialized");

  print(Provider.exampleService);
}
