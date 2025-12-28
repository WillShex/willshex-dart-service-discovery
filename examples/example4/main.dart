import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";
import "services/dependent_service.dart";
import "services/principal_service.dart";

part "main.svc.dart";

@Discovery()
abstract class Trigger {}

@ConfigureDiscovery()
void main() async {
  // PrincipalService depends on DependentService.
  // We expect DependentService to be registered/initialized FIRST.
  await Registrar.init();

  print("Provider.principalService: ${Provider.principalService}");
}
