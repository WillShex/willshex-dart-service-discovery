import 'dart:collection';

import 'package:meta/meta.dart';

import 'service.dart';

/// A generic service discovery registry.
class ServiceDiscovery {
  // Use LinkedHashMap to preserve insertion order for initialization
  final Map<Object, Service> _services = LinkedHashMap<Object, Service>();

  static ServiceDiscovery? _instance;
  static ServiceDiscovery get instance => _instance ??= ServiceDiscovery._();

  ServiceDiscovery._();

  /// Register a service instance.
  ///
  /// If [name] is provided, it is used as the key.
  /// Otherwise, the type [T] is used.
  ///
  /// If a service with the same key is already registered, it acts as an upsert/overwrite.
  void register<T extends Service>(T service, {String? name}) {
    final key = name ?? T;
    _services[key] = service;
  }

  /// Resolve a registered service.
  ///
  /// If [name] is provided, looks up by name.
  /// Otherwise, looks up by type [T].
  ///
  /// Throws [Exception] if service is not found or if the found service is not of type [T].
  T resolve<T extends Service>({String? name}) {
    final key = name ?? T;
    final service = _services[key];
    if (service == null) {
      throw Exception('Service not registered for key: $key');
    }
    if (service is! T) {
      throw Exception(
          'Service registered for key: $key is not of type $T (found ${service.runtimeType})');
    }
    return service;
  }

  /// Checks if a service is registered.
  ///
  /// If [name] is provided, checks by name.
  /// Otherwise, checks by type [T].
  bool isRegistered<T extends Service>({String? name}) {
    final key = name ?? T;
    return _services.containsKey(key);
  }

  /// Unregisters a service.
  ///
  /// If [name] is provided, unregisters by name.
  /// Otherwise, unregisters by type [T].
  void unregister<T extends Service>({String? name}) {
    final key = name ?? T;
    _services.remove(key);
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
  }) async {
    for (final entry in _services.entries) {
      onProgress?.call(entry.value, entry.key.toString());
      await entry.value.init();
    }
  }
}
