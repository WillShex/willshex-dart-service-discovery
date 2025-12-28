import "dart:async";

import "package:analyzer/dart/element/element.dart";
import "package:analyzer/dart/element/type.dart";
import "package:build/build.dart";

import "package:source_gen/source_gen.dart";
import "package:willshex_dart_service_discovery/src/annotations/configure_discovery.dart";
import "package:glob/glob.dart";

/// Generates the configuration method to register all services.
class DiscoveryConfigGenerator
    extends GeneratorForAnnotation<ConfigureDiscovery> {
  const DiscoveryConfigGenerator();

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    // 1. Scan for Services
    final interfaceToImplementations =
        await _scanForServices(buildStep, element);

    // 2. Read Annotation
    final providerName = annotation.peek("provider")?.stringValue;
    final registrarName = annotation.peek("registrar")?.stringValue;

    // Read explicit concrete types
    final concreteTypes = <ClassElement>[];
    final concreteField = annotation.peek("concrete");
    if (concreteField != null && concreteField.isList) {
      for (final typeObj in concreteField.listValue) {
        final type = typeObj.toTypeValue();
        if (type != null && type.element is ClassElement) {
          concreteTypes.add(type.element as ClassElement);
        }
      }
    }

    // Filter out explicit concrete types from interface mappings
    // If an implementation is registered explicitly, it counts as "handled" and shouldn't
    // contribute to the interface's ambiguity or singleton status (unless we want dual registration?).
    // User request: "should NOT be generated ... valid if there was an ImplementationC...".
    // This implies we remove them from the interface's list.

    final filteredInterfaceToImplementations =
        <InterfaceType, List<ClassElement>>{};
    interfaceToImplementations.forEach((interface, impls) {
      final remaining = impls
          .where((impl) => !concreteTypes.any((c) => c.name == impl.name))
          .toList();
      if (remaining.isNotEmpty) {
        filteredInterfaceToImplementations[interface] = remaining;
      }
    });

    // 3. Generate Code
    final buffer = StringBuffer();

    if (element is ExecutableElement) {
      if (providerName != null &&
          registrarName != null &&
          providerName == registrarName) {
        // Unified Class
        _generateUnifiedClass(buffer, providerName,
            filteredInterfaceToImplementations, concreteTypes);
      } else {
        // Split or Individual Classes
        // Registrar: responsible for initialization/registration
        if (registrarName != null) {
          _generateRegistrarClass(buffer, registrarName,
              filteredInterfaceToImplementations, concreteTypes);
        }
        // Provider: responsible for access/getters
        if (providerName != null) {
          _generateProviderClass(buffer, providerName,
              filteredInterfaceToImplementations, concreteTypes);
        }

        if (providerName == null && registrarName == null) {
          _generateFunctionBody(
              buffer, filteredInterfaceToImplementations, concreteTypes);
        }
      }
    } else if (element is ClassElement) {
      // New Class/Extension support
      _generateClassExtension(
          buffer, element, filteredInterfaceToImplementations, concreteTypes);
    }

    return buffer.toString();
  }

  Future<Map<InterfaceType, List<ClassElement>>> _scanForServices(
      BuildStep buildStep, Element annotatedElement) async {
    final definitions = <InterfaceType, List<ClassElement>>{};

    // Scan all dart files in the package (lib, examples, etc.)
    // We restrict to the current package to avoid scanning dependencies
    final package = buildStep.inputId.package;
    final glob = Glob("**/*.dart");

    await for (final assetId in buildStep.findAssets(glob)) {
      // Only process files in the same package
      if (assetId.package != package) continue;

      // Skip generated files
      if (assetId.path.endsWith(".g.dart") ||
          assetId.path.endsWith(".svc.dart") ||
          assetId.path.endsWith(".freezed.dart")) {
        continue;
      }

      // Filter based on scope
      // If we are generating for an example, we only want to scan lib/ and that example
      final inputPath = buildStep.inputId.path;
      if (inputPath.startsWith("examples/")) {
        final pathSegments = inputPath.split("/");
        if (pathSegments.length >= 2) {
          final exampleRoot = "${pathSegments[0]}/${pathSegments[1]}";
          if (!assetId.path.startsWith("lib/") &&
              !assetId.path.startsWith(exampleRoot)) {
            continue;
          }
        }
      } else {
        // If generating for lib/ (or test/), generally only scan lib/
        // (Adjust if necessary for test support)
        if (!assetId.path.startsWith("lib/")) {
          continue;
        }
      }

      try {
        final library = await buildStep.resolver.libraryFor(assetId);

        for (final cls in library.classes) {
          // Skip abstract classes - they can't be instantiated
          if (cls.isAbstract) continue;

          if (_inheritsFromService(cls)) {
            final interfaces = _findServiceInterfaces(cls);
            for (final interface in interfaces) {
              definitions.putIfAbsent(interface, () => []).add(cls);
            }
          }
        }
      } catch (e) {
        // Ignore files that fail to resolve (e.g. part files without parent)
        continue;
      }
    }

    return definitions;
  }

  // Find all abstract supertypes extending Service
  List<InterfaceType> _findServiceInterfaces(ClassElement cls) {
    final interfaces = <InterfaceType>[];

    for (final supertype in cls.allSupertypes) {
      if (supertype.element.name == "Service" &&
          _isServiceLibrary(supertype.element)) {
        continue;
      }
      if (supertype.element.name == "BasicService" &&
          _isServiceLibrary(supertype.element)) {
        continue;
      }
      if (supertype.element.name == "ServiceRetryBase") {
        continue;
      }

      if (_inheritsFromService(supertype.element as ClassElement)) {
        if ((supertype.element as ClassElement).isAbstract) {
          interfaces.add(supertype);
        }
      }
    }

    // If no abstract parent service found, key by the class itself?
    // If we return empty, we handle that in scan.
    if (interfaces.isEmpty) {
      // Fallback to self logic? If self is concrete and extends Service (checked by caller),
      // usually we want to register it as itself?
      // Caller checks _inheritsFromService(cls).
      // If interfaces is empty, it means it inherits Service/BasicService directly but no other abstract intermediate.
      // So we return implicit self type.
      // But only if cls is not abstract (checked by caller).
      interfaces.add(cls.thisType);
    }

    return interfaces;
  }

  void _generateFunctionBody(
      StringBuffer buffer,
      Map<InterfaceType, List<ClassElement>> services,
      List<ClassElement> explicitConcreteTypes) {
    buffer.write("Future<void> \$configureDiscovery(");
    _generateInitParams(buffer, services);
    buffer.writeln(") async {");
    _generateRegistrationCalls(buffer, services, explicitConcreteTypes);
    buffer.writeln("  await ServiceDiscovery.instance.init();");
    buffer.writeln("}");
  }

  void _generateUnifiedClass(
      StringBuffer buffer,
      String className,
      Map<InterfaceType, List<ClassElement>> services,
      List<ClassElement> explicitConcreteTypes) {
    buffer.writeln("abstract class $className {");
    buffer.writeln("  $className._();");
    _generateInitBody(buffer, services, explicitConcreteTypes);
    _generateGettersBody(buffer, services, explicitConcreteTypes);
    buffer.writeln("}");
  }

  void _generateRegistrarClass(
      StringBuffer buffer,
      String className,
      Map<InterfaceType, List<ClassElement>> services,
      List<ClassElement> explicitConcreteTypes) {
    buffer.writeln("class $className {");
    buffer.writeln("  $className._();");
    _generateInitBody(buffer, services, explicitConcreteTypes);
    buffer.writeln("}");
  }

  void _generateProviderClass(
      StringBuffer buffer,
      String className,
      Map<InterfaceType, List<ClassElement>> services,
      List<ClassElement> explicitConcreteTypes) {
    buffer.writeln("class $className {");
    buffer.writeln("  $className._();");
    _generateGettersBody(buffer, services, explicitConcreteTypes);
    buffer.writeln("}");
  }

  void _generateInitBody(
      StringBuffer buffer,
      Map<InterfaceType, List<ClassElement>> services,
      List<ClassElement> explicitConcreteTypes) {
    buffer.write("  static Future<void> init(");
    _generateInitParams(buffer, services);
    buffer.writeln(") async {");
    _generateRegistrationCalls(buffer, services, explicitConcreteTypes);
    buffer.writeln("    await ServiceDiscovery.instance.init();");
    buffer.writeln("  }");
  }

  void _generateInitParams(
      StringBuffer buffer, Map<InterfaceType, List<ClassElement>> services) {
    final ambiguousInterfaces = <InterfaceType>[];

    // Identify interfaces with multiple implementations
    for (final entry in services.entries) {
      if (entry.value.length > 1) {
        ambiguousInterfaces.add(entry.key);
      }
    }

    // Add them as named parameters
    if (ambiguousInterfaces.isNotEmpty) {
      buffer.write("{");
      ambiguousInterfaces.sort(
          (a, b) => (a.element.name ?? "").compareTo(b.element.name ?? ""));
      for (final interface in ambiguousInterfaces) {
        final paramName = _toCamelCase(interface.element.name!);
        buffer.write("required ${interface.element.name} $paramName, ");
      }
      buffer.write("}");
    }
  }

  void _generateGettersBody(
      StringBuffer buffer,
      Map<InterfaceType, List<ClassElement>> services,
      List<ClassElement> explicitConcreteTypes) {
    final allInterfaces = services.keys.toSet();

    // Add explicit concrete types as if they are interfaces (they are their own interface)
    final explicitMap = <String, ClassElement>{};
    for (final concrete in explicitConcreteTypes) {
      explicitMap[concrete.name!] = concrete;
    }

    final sortedInterfaces = allInterfaces.toList()
      ..sort((a, b) => (a.element.name ?? "").compareTo(b.element.name ?? ""));

    final sortedExplicit = explicitMap.values.toList()
      ..sort((a, b) => (a.name ?? "").compareTo(b.name ?? ""));

    // Desired: Getters for all interfaces (auto-discovered)
    for (final interface in sortedInterfaces) {
      final instanceName = _toCamelCase(interface.element.name!);
      buffer.writeln(
          "  static ${interface.element.name!} get $instanceName => ServiceDiscovery.instance.resolve<${interface.element.name!}>();");
    }

    // AND Getters for explicit concrete types
    for (final concrete in sortedExplicit) {
      final instanceName = _toCamelCase(concrete.name!);
      buffer.writeln(
          "  static ${concrete.name!} get $instanceName => ServiceDiscovery.instance.resolve<${concrete.name!}>();");
    }
  }

  void _generateClassExtension(
      StringBuffer buffer,
      ClassElement cls,
      Map<InterfaceType, List<ClassElement>> services,
      List<ClassElement> explicitConcreteTypes) {
    buffer.writeln("extension ${cls.name}Discovery on ${cls.name} {");
    _generateInitBody(buffer, services, explicitConcreteTypes);
    _generateGettersBody(buffer, services, explicitConcreteTypes);
    buffer.writeln("}");
  }

  void _generateRegistrationCalls(
      StringBuffer buffer,
      Map<InterfaceType, List<ClassElement>> services,
      List<ClassElement> explicitConcreteTypes) {
    // 1. Build list of all "registration units"
    // A unit is either:
    // - A singleton implementation of an interface (Interface -> [Impl])
    // - An ambiguous interface requiring injection (Interface) -> treated as a node, but has no distinct class?
    //   Actually, injected services are passed in, so they are PRE-initialized. Their registration order matters less
    //   for THEIR init, but matters for services DEPENDING on them.
    // - An explicit concrete type (Impl)

    // We need to map: Type -> ClassElement (implementation) to check dependencies.
    // For ambiguous interfaces (provided via init param), the "implementation" is external.
    // However, if ServiceA depends on AbstractService, it expects AbstractService to be registered.

    // Key: The Type being registered (Interface or Concrete)
    // Value: The ClassElement representing the implementation (if known) or the InterfaceElement (if ambiguous/injected)
    final registrationNodes = <InterfaceType, Element>{};

    // Map of Dependency -> Dependents (Adjacency List)? Or Node -> Dependencies?
    // We want Topological Sort: register dependencies first.
    // Graph: Node -> List<Node> (Dependencies)

    // Populate Nodes
    final sortedInterfaces = services.keys.toList()
      ..sort((a, b) => (a.element.name ?? "").compareTo(b.element.name ?? ""));

    final ambiguousInterfaces = <InterfaceType>{};

    for (final interface in sortedInterfaces) {
      final implementations = services[interface]!;
      if (implementations.length == 1) {
        // Singleton
        registrationNodes[interface] = implementations.first;
      } else {
        // Ambiguous - Injected
        ambiguousInterfaces.add(interface);
        // For dependency resolution, we treat the Interface element as the "node"
        // because that's what others depend on.
        registrationNodes[interface] = interface.element;
      }
    }

    for (final concrete in explicitConcreteTypes) {
      // Explicit Concrete is its own interface
      registrationNodes[concrete.thisType] = concrete;
    }

    // 2. Build Graph
    // Node is InterfaceType (the type used in register<T>).
    // Dependencies are other InterfaceTypes.
    final dependencies = <InterfaceType, Set<InterfaceType>>{};

    for (final entry in registrationNodes.entries) {
      final nodeType = entry.key; // The registered type (e.g. MyService)
      final element = entry
          .value; // The class implementing it (e.g. MyServiceImpl) OR InterfaceElement

      dependencies[nodeType] = {};

      if (element is ClassElement) {
        // Read @DependsOn from the implementation class
        final deps = _getDependencies(element);
        for (final depType in deps) {
          // Find which registered node corresponds to this dependency type
          // The dependency `depType` might be a Concrete or an Interface.
          // We need to find if `depType` is a key in `registrationNodes`.
          // Note: Type equality can be tricky. compare element names?

          // Simple lookup:
          // 1. Is depType directly a registered interface?
          // 2. Is depType a supertype of a registered concrete? (Not supported yet, usually depends on Interface)

          final match = registrationNodes.keys.firstWhere(
              (k) =>
                  k.element.name == depType.element.name &&
                  k.element.library.identifier ==
                      depType.element.library.identifier,
              orElse: () => nodeType // Dummy, handled below
              );

          if (match != nodeType) {
            dependencies[nodeType]!.add(match);
          }
        }
      }
    }

    // 3. Topological Sort
    List<InterfaceType> sortedNodes;
    try {
      sortedNodes = _topologicalSort(registrationNodes.keys, dependencies);
    } catch (e) {
      // Propagate error (likely Circular Dependency)
      throw InvalidGenerationSourceError(e.toString());
    }

    // 4. Generate Registry Calls
    for (final node in sortedNodes) {
      if (ambiguousInterfaces.contains(node)) {
        // Ambiguous
        final paramName = _toCamelCase(node.element.name!);
        buffer.writeln(
            "  ServiceDiscovery.instance.register<${node.element.name!}>($paramName);");
      } else {
        // Singleton or Explicit
        // Only generate if NOT ambiguous (checked above) AND inside services map OR explicit list
        // logic: if it's in registrationNodes, it's one of them.
        // We need to know if it's a "singleton" (ClassName()) or Explicit (ClassName())

        final element = registrationNodes[node]!;
        if (element is ClassElement) {
          buffer.writeln(
              "  ServiceDiscovery.instance.register<${node.element.name!}>(${element.name}());");
        }
      }
    }
  }

  Set<InterfaceType> _getDependencies(ClassElement cls) {
    final deps = <InterfaceType>[];
    final typeChecker = TypeChecker.fromUrl(
        "package:willshex_dart_service_discovery/src/annotations/depends_on.dart#DependsOn");

    final annotation = typeChecker.firstAnnotationOf(cls);
    if (annotation != null) {
      final reader = ConstantReader(annotation);
      final list = reader.peek("dependencies")?.listValue;
      if (list != null) {
        for (final item in list) {
          final type = item.toTypeValue();
          if (type is InterfaceType) {
            deps.add(type);
          }
        }
      }
    }
    return deps.toSet();
  }

  List<InterfaceType> _topologicalSort(Iterable<InterfaceType> nodes,
      Map<InterfaceType, Set<InterfaceType>> dependencies) {
    final sorted = <InterfaceType>[];
    final visited = <InterfaceType>{};
    final visiting = <InterfaceType>{};

    void visit(InterfaceType node) {
      if (visiting.contains(node)) {
        throw "Circular dependency detected involving ${node.element.name}";
      }
      if (visited.contains(node)) {
        return;
      }

      visiting.add(node);

      final deps = dependencies[node] ?? {};
      for (final dep in deps) {
        visit(dep);
      }

      visiting.remove(node);
      visited.add(node);
      sorted.add(node);
    }

    for (final node in nodes) {
      visit(node);
    }

    return sorted;
  }

  bool _inheritsFromService(ClassElement? cls) {
    if (cls == null) return false;
    for (InterfaceType type in cls.allSupertypes) {
      if (type.element.name == "Service" && _isServiceLibrary(type.element)) {
        return true;
      }
    }
    return false;
  }

  bool _isServiceLibrary(Element element) {
    return element.library?.identifier
            .contains("willshex_dart_service_discovery") ??
        false;
  }

  String _toCamelCase(String str) {
    if (str.isEmpty) return str;
    return str[0].toLowerCase() + str.substring(1);
  }
}
