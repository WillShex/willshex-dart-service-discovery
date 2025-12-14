import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";

class AnotherExampleService extends BasicService {
  @override
  Future<void> onInit() async {
    print("AnotherExampleService initialized");
  }

  @override
  Future<void> onReset() async {
    print("AnotherExampleService reset");
  }
}
