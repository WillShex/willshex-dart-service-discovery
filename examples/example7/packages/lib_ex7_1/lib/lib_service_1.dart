import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";

class LibService1 extends BasicService {
  @override
  Future<void> onInit() async {
    print("LibService1 initialized");
  }

  @override
  Future<void> onReset() async {}
}
