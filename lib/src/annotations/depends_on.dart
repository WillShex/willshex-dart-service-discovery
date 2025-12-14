/// Annotation to declare that a service depends on other services and should be
/// initialized after them.
class DependsOn {
  /// The list of service types that this service depends on.
  final List<Type> dependencies;

  const DependsOn(this.dependencies);
}
