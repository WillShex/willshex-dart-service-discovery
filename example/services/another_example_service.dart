import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";

part "another_example_service.svc.dart";

class AnotherExampleService extends Service {
  @override
  Future<void> onInit() async {
    print("AnotherExampleService initialized");
  }

  @override
  Future<void> onReset() async {
    print("AnotherExampleService reset");
  }
}
