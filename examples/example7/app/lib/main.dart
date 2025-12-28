import "package:lib_ex7/lib_service.dart";
import "package:lib_ex7_1/lib_service_1.dart";
import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";

part "main.svc.dart";

@Discovery()
abstract class Trigger {}

@ConfigureDiscovery()
void main() async {
  await Registrar.init();
  print(Provider.libService);
  print(Provider.libService1);
}
