import "dart:async";
import "dart:io";
import "dart:isolate";

import "package:analyzer/dart/element/element.dart";
import "package:analyzer/dart/element/type.dart";
import "package:build/build.dart";
import "package:glob/glob.dart";
import "package:package_config/package_config.dart";
import "package:source_gen/source_gen.dart";
import "package:willshex_dart_service_discovery/src/annotations/discovery_registrar.dart";
import "package:yaml/yaml.dart";

/// Generates the configuration method to register all services.
class RegistrarGenerator extends GeneratorForAnnotation<DiscoveryRegistrar> {
  const RegistrarGenerator();

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
    final registrarName = annotation.peek("name")?.stringValue ?? "Registrar";

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
    log.info(
        "Explicit concrete types: ${concreteTypes.map((e) => e.name).toList()}");

    // Filter out explicit concrete types from interface mappings
    final filteredInterfaceToImplementations =
        <InterfaceType, List<ClassElement>>{};
    interfaceToImplementations.forEach((interface, impls) {
      log.info(
          "Interface ${interface.element.name} has impls: ${impls.map((e) => e.name).toList()}");
      final remaining = impls
          .where((impl) => !concreteTypes.any((c) => c.name == impl.name))
          .toList();
      log.info(
          "Interface ${interface.element.name} remaining: ${remaining.map((e) => e.name).toList()}");
      if (remaining.isNotEmpty) {
        filteredInterfaceToImplementations[interface] = remaining;
      }
    });

    // 3. Generate Code
    final buffer = StringBuffer();

    // Registrar: responsible for initialization/registration
    _generateRegistrarClass(buffer, registrarName,
        filteredInterfaceToImplementations, concreteTypes);

    return buffer.toString();
  }

  Future<Map<InterfaceType, List<ClassElement>>> _scanForServices(
      BuildStep buildStep, Element annotatedElement) async {
    final definitions = <InterfaceType, List<ClassElement>>{};
    final processedClassNames = <String>{};
    final package = buildStep.inputId.package;

    // 1. Scan local assets (files in lib/)
    await _scanPackage(buildStep, package, definitions, processedClassNames,
        isLocal: true);

    // 2. Scan dependencies from pubspec.yaml
    // We do this to find services in packages that might not be directly imported
    // in the library files but are available in the project.
    try {
      final pubspecId = AssetId(package, "pubspec.yaml");
      if (await buildStep.canRead(pubspecId)) {
        final pubspecContent = await buildStep.readAsString(pubspecId);
        final pubspec = loadYaml(pubspecContent);
        if (pubspec is YamlMap) {
          final dependencies = pubspec["dependencies"];
          if (dependencies is YamlMap) {
            for (final key in dependencies.keys) {
              final depName = key.toString();
              log.info("Found dependency: $depName");
              // Skip sdk dependencies and some common non-service packages to save time
              if (depName == "flutter" ||
                  depName == "flutter_test" ||
                  depName == "willshex_dart_service_discovery" ||
                  depName == "meta") {
                continue;
              }
              await _scanPackage(
                  buildStep, depName, definitions, processedClassNames);
            }
          }
        }
      }
    } catch (e) {
      log.warning("Failed to read or parse pubspec.yaml: $e");
    }

    // 3. Fallback: Scan reachable libraries (imports) to catch anything missed
    // (though pubspec scanning should cover most direct dependencies)
    try {
      if (await buildStep.resolver.isLibrary(buildStep.inputId)) {
        await for (final library in buildStep.resolver.libraries) {
          if (library.isInSdk) continue; // Skip dart: libraries

          final uri = Uri.parse(library.identifier);
          if (uri.scheme == "package" &&
              (uri.pathSegments.first == "flutter" ||
                  uri.pathSegments.first == "flutter_test" ||
                  uri.pathSegments.first == "dart_style" ||
                  uri.pathSegments.first == "build_runner" ||
                  uri.pathSegments.first == "source_gen")) {
            continue;
          }

          _processLibrary(library, definitions, processedClassNames);
        }
      }
    } catch (e) {
      // failed to resolve libraries
    }

    return definitions;
  }

  Future<void> _scanPackage(
    BuildStep buildStep,
    String package,
    Map<InterfaceType, List<ClassElement>> definitions,
    Set<String> processedClassNames, {
    bool isLocal = false,
  }) async {
    Stream<AssetId> assetStream;

    if (isLocal) {
      final glob = Glob("**/*.dart");
      assetStream = buildStep.findAssets(glob);
    } else {
      try {
        final uri = await Isolate.packageConfig;
        if (uri == null) {
          log.warning("Isolate.packageConfig is null");
          return;
        }
        final config = await loadPackageConfigUri(uri);

        final pkg = config.packages.firstWhere(
          (p) => p.name == package,
          orElse: () => throw "Package $package not found in config",
        );

        final libPath = pkg.packageUriRoot.toFilePath();
        final libDir = Directory(libPath);
        if (!await libDir.exists()) {
          log.warning("Lib directory not found: $libPath");
          return;
        }

        final files = libDir
            .list(recursive: true)
            .where((fs) => fs is File && fs.path.endsWith(".dart"));

        assetStream = files.asyncMap((fs) async {
          var basePath = libPath;
          if (!basePath.endsWith(Platform.pathSeparator)) {
            basePath += Platform.pathSeparator;
          }

          if (fs.path.startsWith(basePath)) {
            final relative = fs.path.substring(basePath.length);
            final assetPath =
                "lib/${relative.replaceAll(Platform.pathSeparator, '/')}";
            return AssetId(package, assetPath);
          }
          return AssetId(package, "lib/unknown.dart");
        }).cast<AssetId>();
      } catch (e, s) {
        log.warning("Failed to locate files for package $package: $e\n$s");
        return;
      }
    }

    await for (final assetId in assetStream) {
      if (assetId.package != package) continue;

      log.info("Found asset: ${assetId.path} in package ${assetId.package}");

      if (assetId.path.endsWith(".g.dart") ||
          assetId.path.endsWith(".svc.dart") ||
          assetId.path.endsWith(".freezed.dart")) {
        continue;
      }

      if (isLocal) {
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
          if (!assetId.path.startsWith("lib/")) {
            continue;
          }
        }
      }

      try {
        final library = await buildStep.resolver.libraryFor(assetId);
        _processLibrary(library, definitions, processedClassNames);
      } catch (e) {
        continue;
      }
    }
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

  void _generateInitBody(
      StringBuffer buffer,
      Map<InterfaceType, List<ClassElement>> services,
      List<ClassElement> explicitConcreteTypes) {
    buffer.write("  static Future<void> init({");
    _generateInitParams(buffer, services);
    buffer.writeln("void Function(Type type)? onChange,}) async {");
    _generateRegistrationCalls(buffer, services, explicitConcreteTypes);
    buffer.writeln("    await ServiceDiscovery.instance.init(");
    buffer.writeln("      onChange: onChange,");
    buffer.writeln("    );");
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
      ambiguousInterfaces.sort(
          (a, b) => (a.element.name ?? "").compareTo(b.element.name ?? ""));
      for (final interface in ambiguousInterfaces) {
        final paramName = _toCamelCase(interface.element.name!);
        buffer.write("required ${interface.element.name} $paramName, ");
      }
    }
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

    void checkElement(Element element) {
      final annotation = typeChecker.firstAnnotationOf(element);
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
    }

    checkElement(cls);
    for (final supertype in cls.allSupertypes) {
      if (supertype.element is ClassElement && !supertype.isDartCoreObject) {
        checkElement(supertype.element);
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

  void _processLibrary(
      LibraryElement library,
      Map<InterfaceType, List<ClassElement>> definitions,
      Set<String> processedClassNames) {
    for (final cls in library.classes) {
      if (cls.name == null) continue;
      if (processedClassNames.contains(cls.name!)) continue;

      // Skip abstract classes - they can't be instantiated
      if (cls.isAbstract) continue;

      // Skip private classes
      if (cls.isPrivate) continue;

      if (_inheritsFromService(cls)) {
        processedClassNames.add(cls.name!);
        final interfaces = _findServiceInterfaces(cls);
        for (final interface in interfaces) {
          definitions.putIfAbsent(interface, () => []).add(cls);
        }
      }
    }
  }
}
