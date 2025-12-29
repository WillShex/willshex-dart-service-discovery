import "package:meta/meta.dart";

import "service.dart";

/// A generic service discovery registry.
class ServiceDiscovery {
  // Use LinkedHashMap to preserve insertion order for initialization
  final Map<Object, Service> _services = <Object, Service>{};

  static ServiceDiscovery? _instance;
  static ServiceDiscovery get instance => _instance ??= ServiceDiscovery._();

  ServiceDiscovery._();

  /// Register a service instance.
  ///
  /// The type [T] is used as the key.
  ///
  /// If a service with the same type is already registered, it acts as an upsert/overwrite.
  void register<T extends Service>(T service) {
    _services[T] = service;
  }

  /// Resolve a registered service.
  ///
  /// Looks up by type [T].
  ///
  /// Throws [Exception] if service is not found or if the found service is not of type [T].
  T resolve<T extends Service>() {
    final key = T;
    final service = _services[key];
    if (service == null) {
      throw Exception("Service not registered for type: $T");
    }
    if (service is! T) {
      throw Exception(
          "Service registered for type: $T is not of type $T (found ${service.runtimeType})");
    }
    return service;
  }

  /// Checks if a service is registered.
  ///
  /// Checks by type [T].
  bool isRegistered<T extends Service>() {
    return _services.containsKey(T);
  }

  /// Unregisters a service.
  ///
  /// Unregisters by type [T].
  void unregister<T extends Service>() {
    _services.remove(T);
  }

  /// Reset all registered services.
  Future<void> reset() async {
    // Iterate in reverse order for reset? Usually safer, but standard iteration is fine for now unless dependency order matters strictly in reverse.
    // Existing projects didn't specify reverse reset, so adhering to iteration order.
    for (var service in _services.values) {
      await service.reset();
    }
  }

  /// Clears all registered services.
  ///
  /// Useful for testing.
  @visibleForTesting
  void unregisterAll() {
    _services.clear();
  }

  /// Initializes all registered services in order.
  ///
  /// [onProgress] is called before initializing each service.
  /// If a service fails to initialize (throws an exception), the process stops
  /// and the exception is rethrown.
  Future<void> init({
    void Function(Service service, String key)? onProgress,
    void Function(Type type)? onChange,
  }) async {
    for (final entry in _services.entries) {
      onProgress?.call(entry.value, entry.key.toString());
      if (entry.key is Type) {
        onChange?.call(entry.key as Type);
      }
      await entry.value.init();
    }
  }
}
