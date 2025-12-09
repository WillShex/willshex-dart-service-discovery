import 'package:test/test.dart';
import 'package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart';

import 'mocks.mocks.dart';

void main() {
  group('ServiceProvider', () {
    late MockService mockService;
    late MockService namedService;

    setUp(() {
      ServiceDiscovery.instance.unregisterAll();
      mockService = MockService();
      namedService = MockService();

      ServiceDiscovery.instance.register<MockService>(mockService);
      ServiceDiscovery.instance
          .register<MockService>(namedService, name: 'named');
    });

    test('should provide service by Type', () {
      const provider = ServiceProvider<MockService>();
      expect(provider.service, equals(mockService));
    });

    test('should provide service by Name', () {
      const provider = ServiceProvider<MockService>(name: 'named');
      expect(provider.service, equals(namedService));
    });
  });
}
