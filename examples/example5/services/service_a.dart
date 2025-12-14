import "dart:async";

import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";
import "service_b.dart";

@DependsOn([ServiceB])
class ServiceA extends BasicService {
  @override
  FutureOr<void> onInit() {}
  @override
  FutureOr<void> onReset() {}
}
