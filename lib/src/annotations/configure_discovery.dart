/// Annotation to mark the method that will trigger the generation of the
/// service discovery configuration.
class ConfigureDiscovery {
  final String? provider;
  final String? registrar;
  final List<Type> concrete;
  const ConfigureDiscovery({
    this.provider,
    this.registrar,
    this.concrete = const [],
  });
}
