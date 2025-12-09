import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";

part "example_service.svc.dart";

class ExampleService extends Service {
  @override
  Future<void> onInit() async {
    print("ExampleService initialized");
  }

  @override
  Future<void> onReset() async {
    print("ExampleService reset");
  }
}
