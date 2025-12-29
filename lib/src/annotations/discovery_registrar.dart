/// Annotation to mark the method that will trigger the generation of the
/// service discovery configuration (Registrar).
///
/// Example:
/// ```dart
/// @Registrar() // Generates "Registrar" class
/// abstract class Trigger {}
///
/// @Registrar("WebRegistrar") // Generates "WebRegistrar" class
/// abstract class Trigger {}
/// ```
class DiscoveryRegistrar {
  final String? name;

  /// Concrete types to register by their concrete type.
  /// Use this when you want to access specific implementations directly.
  final List<Type> concrete;

  const DiscoveryRegistrar({
    this.name = "Registrar",
    this.concrete = const [],
  });
}
