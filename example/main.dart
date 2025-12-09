import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";
import "services/another_example_service.dart";
import "services/example_service.dart";

part "main.svc.dart";

@ConfigureDiscovery()
void main(List<String> args) async {
  await $configureDiscovery();
  print("Service Discovery Configured and Initialized");
}
