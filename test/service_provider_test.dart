import "package:test/test.dart";
import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";

import "mocks.mocks.dart";

void main() {
  group("ServiceProvider", () {
    late MockService mockService;

    setUp(() {
      ServiceDiscovery.instance.unregisterAll();
      mockService = MockService();

      ServiceDiscovery.instance.register<MockService>(mockService);
    });

    test("should provide service by Type", () {
      const provider = ServiceProvider<MockService>();
      expect(provider.service, equals(mockService));
    });

    test("should check registration status", () {
      const provider = ServiceProvider<MockService>();
      expect(provider.isRegistered, isTrue);

      ServiceDiscovery.instance.unregister<MockService>();
      expect(provider.isRegistered, isFalse);
    });
  });
}
