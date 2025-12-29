/// Annotation to trigger generation of a provider class with service getters.
///
/// Use this in common/shared packages to generate a platform-agnostic provider.
/// The generated class will have static getters for all discovered services.
///
/// Example:
/// ```dart
/// @DiscoveryProvider()  // Generates "Provider" class
/// abstract class Trigger {}
///
/// @DiscoveryProvider(name: "ServiceProvider")  // Generates "ServiceProvider" class
/// abstract class Trigger {}
/// ```
class DiscoveryProvider {
  /// Name of the generated provider class. Defaults to "Provider".
  final String name;

  /// Concrete types to generate getters for.
  /// Use this when you want to access specific implementations directly from the Provider.
  final List<Type> concrete;

  const DiscoveryProvider({
    this.name = "Provider",
    this.concrete = const [],
  });
}
