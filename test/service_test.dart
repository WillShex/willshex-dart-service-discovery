import 'package:test/test.dart';
import 'package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart';

class TestService extends Service {
  bool onInitCalled = false;
  bool onResetCalled = false;

  @override
  Future<void> onInit() async {
    onInitCalled = true;
  }

  @override
  Future<void> onReset() async {
    onResetCalled = true;
  }

  void testMethod() {
    verifyInitialized();
  }
}

void main() {
  group('Service', () {
    test('should initialize correctly', () async {
      final service = TestService();
      expect(service.isInitialized, isFalse);

      await service.init();
      expect(service.isInitialized, isTrue);
      expect(service.onInitCalled, isTrue);
    });

    test('should not call onInit if already initialized', () async {
      final service = TestService();
      await service.init();
      service.onInitCalled = false;

      await service.init();
      expect(service.onInitCalled, isFalse);
    });

    test('should reset correctly', () async {
      final service = TestService();
      await service.init();
      expect(service.isInitialized, isTrue);

      await service.reset();
      expect(service.isInitialized, isFalse);
      expect(service.onResetCalled, isTrue);
    });

    test('should throw StateError if method called before init', () {
      final service = TestService();
      expect(() => service.testMethod(), throwsStateError);
    });

    test('should allow method call after init', () async {
      final service = TestService();
      await service.init();
      expect(() => service.testMethod(), returnsNormally);
    });

    test('should throw StateError if method called after reset', () async {
      final service = TestService();
      await service.init();
      await service.reset();
      expect(() => service.testMethod(), throwsStateError);
    });
  });
}
