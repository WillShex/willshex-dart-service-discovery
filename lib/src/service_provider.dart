import "service.dart";
import "service_discovery.dart";

/// A helper class to provide access to a service of type [T].
///
/// This class can be used to lazily retrieve a service from the
/// [ServiceDiscovery] instance.
class ServiceProvider<T extends Service> {
  /// Creates a [ServiceProvider] for the service of type [T].
  const ServiceProvider();

  /// The discovered service instance.
  ///
  /// Throws if not registered or invalid type.
  T get service => ServiceDiscovery.instance.resolve<T>();

  /// Returns `true` if the service is currently registered.
  bool get isRegistered => ServiceDiscovery.instance.isRegistered<T>();
}
