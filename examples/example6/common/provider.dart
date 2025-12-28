import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";
import "services/logging_service.dart";

part "provider.svc.dart";

/// Trigger for @Discovery annotation to generate Provider class.
///
/// The @Discovery annotation on this class triggers generation of a
/// Provider class in provider.svc.dart with static getters for all
/// discovered services.
///
/// This trigger class can have any name - the generator always creates
/// a class named "Provider".
@Discovery()
abstract class Trigger {
  Trigger._();
}
