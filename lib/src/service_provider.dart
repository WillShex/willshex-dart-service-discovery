import 'service.dart';
import 'service_discovery.dart';

/// A helper class to provide access to a service of type [T].
///
/// This class can be used to lazily retrieve a service from the
/// [ServiceDiscovery] instance.
class ServiceProvider<T extends Service> {
  final String? name;

  /// Creates a [ServiceProvider] for the service of type [T].
  ///
  /// If [name] is provided, it will resolve the service registered with that name.
  const ServiceProvider({this.name});

  /// Retrieves the service instance from [ServiceDiscovery].
  T get service => ServiceDiscovery.instance.resolve<T>(name: name);
}
