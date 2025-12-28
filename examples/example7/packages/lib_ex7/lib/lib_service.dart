import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";

class LibService extends BasicService {
  @override
  Future<void> onInit() async {
    print("LibService initialized");
  }

  @override
  Future<void> onReset() async {}
}
