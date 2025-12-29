import "package:common/common_business.dart";
import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";

part "main.svc.dart";

@DiscoveryRegistrar()
void main() async {
  await Registrar.init();

  CommonBusiness.get.doSomething();

  print("Flutter App Configured");
}
