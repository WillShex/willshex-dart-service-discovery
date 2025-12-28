import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";

abstract class SharedService extends BasicService {
  void doSharedThing();

  @override
  Future<void> onInit() async {
    print("SharedService initialized");
  }

  @override
  Future<void> onReset() async {}
}
