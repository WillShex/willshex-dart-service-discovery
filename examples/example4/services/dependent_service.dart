import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";

class DependentService extends BasicService {
  @override
  Future<void> onInit() async => print("DependentService init");
  @override
  Future<void> onReset() async => print("DependentService reset");
}
