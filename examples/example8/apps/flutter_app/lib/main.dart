import "package:common/common_business.dart";
import "package:common/shared_service.dart";
import "package:flutter_dep/flutter_impl.dart";
import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";

part "main.svc.dart";

@ConfigureDiscovery()
void main() async {
  await Registrar.init();

  CommonBusiness.get.doSomething();

  print("Flutter App Configured");
}
