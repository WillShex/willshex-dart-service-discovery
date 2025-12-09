import "package:mockito/mockito.dart";
import "package:test/test.dart";
import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";

import "mocks.mocks.dart";

class AnotherMockService extends MockService {}

void main() {
  group("ServiceDiscovery", () {
    late MockService mockService;
    setUp(() {
      ServiceDiscovery.instance.unregisterAll();
      mockService = MockService();
    });

    test("should register and resolve a service by Type", () {
      ServiceDiscovery.instance.register<MockService>(mockService);

      final resolved = ServiceDiscovery.instance.resolve<MockService>();
      expect(resolved, equals(mockService));
    });

    test("should throw if resolving unregistered service by Type", () {
      expect(
        () => ServiceDiscovery.instance.resolve<MockService>(),
        throwsException,
      );
    });

    test("should check registration by Type", () {
      expect(ServiceDiscovery.instance.isRegistered<MockService>(), isFalse);
      ServiceDiscovery.instance.register<MockService>(mockService);
      expect(ServiceDiscovery.instance.isRegistered<MockService>(), isTrue);
    });

    test("should unregister by Type", () {
      ServiceDiscovery.instance.register<MockService>(mockService);
      ServiceDiscovery.instance.unregister<MockService>();
      expect(ServiceDiscovery.instance.isRegistered<MockService>(), isFalse);
    });

    test("should initialize services in order", () async {
      final order = <String>[];
      final service1 = MockService();
      // Need a different type for service 2 to register both
      final service2 = AnotherMockService();

      when(service1.init()).thenAnswer((_) async => order.add("service1"));
      when(service2.init()).thenAnswer((_) async => order.add("service2"));

      ServiceDiscovery.instance.register<MockService>(service1);
      ServiceDiscovery.instance.register<AnotherMockService>(service2);

      await ServiceDiscovery.instance.init();

      verify(service1.init()).called(1);
      verify(service2.init()).called(1);
      expect(order, orderedEquals(["service1", "service2"]));
    });

    test("should report progress during initialization", () async {
      final service1 = MockService();
      final service2 = AnotherMockService();

      ServiceDiscovery.instance.register<MockService>(service1);
      ServiceDiscovery.instance.register<AnotherMockService>(service2);

      final progressTypes = <String>[];

      await ServiceDiscovery.instance.init(
        onProgress: (service, key) {
          progressTypes.add(key);
        },
      );

      expect(
          progressTypes, orderedEquals(["MockService", "AnotherMockService"]));
    });

    test("should stop initialization on failure", () async {
      final service1 = MockService();
      final service2 = AnotherMockService();

      when(service1.init()).thenThrow(Exception("init failed"));

      ServiceDiscovery.instance.register<MockService>(service1);
      ServiceDiscovery.instance.register<AnotherMockService>(service2);

      expect(() => ServiceDiscovery.instance.init(), throwsException);

      verify(service1.init()).called(1);
      verifyNever(service2.init());
    });

    test("should reset all services", () async {
      ServiceDiscovery.instance.register<MockService>(mockService);

      await ServiceDiscovery.instance.reset();

      verify(mockService.reset()).called(1);
    });
  });
}
