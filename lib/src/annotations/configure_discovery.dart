/// Annotation to mark the method that will trigger the generation of the
/// service discovery configuration.
class ConfigureDiscovery {
  final String? registrar;

  /// Concrete types to register by their concrete type.
  /// Use this when you want to access specific implementations directly.
  final List<Type> concrete;

  const ConfigureDiscovery({
    this.registrar = "Registrar",
    this.concrete = const [],
  });
}

/// Annotation to trigger generation of a provider class with service getters.
///
/// Use this in common/shared packages to generate a platform-agnostic provider.
/// The generated class will have static getters for all discovered services.
///
/// Example:
/// ```dart
/// @Discovery()  // Generates "Provider" class
/// abstract class Trigger {}
///
/// @Discovery(name: "ServiceProvider")  // Generates "ServiceProvider" class
/// abstract class Trigger {}
/// ```
class Discovery {
  /// Name of the generated provider class. Defaults to "Provider".
  final String name;

  /// Concrete types to generate getters for.
  /// Use this when you want to access specific implementations directly from the Provider.
  final List<Type> concrete;

  const Discovery({
    this.name = "Provider",
    this.concrete = const [],
  });
}
