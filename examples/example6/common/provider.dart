import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";
import "services/logging_service.dart";

part "provider.svc.dart";

/// Trigger for @DiscoveryProvider annotation to generate Provider class.
///
/// The @DiscoveryProvider annotation on this class triggers generation of a
/// Provider class in provider.svc.dart with static getters for all
/// discovered services.
///
/// This trigger class can have any name - the generator always creates
/// a class named "Provider".
@DiscoveryProvider()
abstract class Trigger {
  Trigger._();
}
