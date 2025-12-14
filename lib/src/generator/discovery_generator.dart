import "dart:async";

import "package:analyzer/dart/element/element.dart";
import "package:analyzer/dart/element/type.dart";
import "package:build/build.dart";

import "package:source_gen/source_gen.dart";
import "package:willshex_dart_service_discovery/src/annotations/configure_discovery.dart";

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
    // contribute to the interface's ambiguity or singleton status (unless we want dual registration?)
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

    if (element is FunctionElement) {
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

    // Crawl imports starting from the annotated library
    final rootLibrary = annotatedElement.library;
    if (rootLibrary == null) return definitions;

    final visited = <LibraryElement>{};
    final queue = <LibraryElement>[rootLibrary];

    // We also need to explicitly scan 'lib' of the package because users might rely on
    // services being picked up from the package without explicit import in main?
    // User request: "confining itself to the annotated main function".
    // This implies explicit imports ONLY.
    // However, if we do strict import crawling, we might miss things if the user expects
    // "everything in my project" but "confined to my project".
    // But "confined to annotated main" strongly suggests reachability.

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (!visited.add(current)) continue;

      // Process classes in this library
      for (final cls in current.topLevelElements.whereType<ClassElement>()) {
        if (cls.isAbstract) continue;
        if (_inheritsFromService(cls)) {
          final interfaces = _findServiceInterfaces(cls);
          for (final interface in interfaces) {
            definitions.putIfAbsent(interface, () => []).add(cls);
          }
        }
      }

      // Enqueue imports and exports
      queue.addAll(current.importedLibraries);
      queue.addAll(current.exportedLibraries);
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
    buffer.writeln("class $className {");
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
    _generateInitBody(buffer, services, explicitConcreteTypes);
    buffer.writeln("}");
  }

  void _generateProviderClass(
      StringBuffer buffer,
      String className,
      Map<InterfaceType, List<ClassElement>> services,
      List<ClassElement> explicitConcreteTypes) {
    buffer.writeln("class $className {");
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
      ambiguousInterfaces
          .sort((a, b) => a.element.name.compareTo(b.element.name));
      for (final interface in ambiguousInterfaces) {
        final paramName = _toCamelCase(interface.element.name);
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
      explicitMap[concrete.name] = concrete;
    }

    final sortedInterfaces = allInterfaces.toList()
      ..sort((a, b) => a.element.name.compareTo(b.element.name));

    final sortedExplicit = explicitMap.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    // Desired: Getters for all interfaces (auto-discovered)
    for (final interface in sortedInterfaces) {
      final instanceName = _toCamelCase(interface.element.name);
      buffer.writeln(
          "  static ${interface.element.name} get $instanceName => ServiceDiscovery.instance.resolve<${interface.element.name}>();");
    }

    // AND Getters for explicit concrete types
    for (final concrete in sortedExplicit) {
      final instanceName = _toCamelCase(concrete.name);
      buffer.writeln(
          "  static ${concrete.name} get $instanceName => ServiceDiscovery.instance.resolve<${concrete.name}>();");
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
    final sortedInterfaces = services.keys.toList()
      ..sort((a, b) => a.element.name.compareTo(b.element.name));

    for (final interface in sortedInterfaces) {
      final implementations = services[interface]!;

      if (implementations.length == 1) {
        // Auto-register singleton
        final impl = implementations.first;
        buffer.writeln(
            "  ServiceDiscovery.instance.register<${interface.element.name}>(${impl.name}());");
      } else {
        // Ambiguous: registered via injected parameter
        final paramName = _toCamelCase(interface.element.name);
        buffer.writeln(
            "  ServiceDiscovery.instance.register<${interface.element.name}>($paramName);");
      }
    }

    // Register explicit concrete types
    final sortedExplicit = explicitConcreteTypes.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    for (final concrete in sortedExplicit) {
      buffer.writeln(
          "  ServiceDiscovery.instance.register<${concrete.name}>(${concrete.name}());");
    }
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
    return element.library?.source.uri
            .toString()
            .contains("willshex_dart_service_discovery") ??
        false;
  }

  String _toCamelCase(String str) {
    if (str.isEmpty) return str;
    return str[0].toLowerCase() + str.substring(1);
  }
}
