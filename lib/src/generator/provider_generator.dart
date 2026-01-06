import "dart:async";
import "dart:io";
import "dart:isolate";

import "package:analyzer/dart/element/element.dart";
import "package:analyzer/dart/element/type.dart";
import "package:build/build.dart";
import "package:glob/glob.dart";
import "package:package_config/package_config.dart";
import "package:source_gen/source_gen.dart";
import "package:willshex_dart_service_discovery/src/annotations/discovery_provider.dart";
import "package:yaml/yaml.dart";

/// Generates provider methods for classes annotated with @Provider.
///
/// This generator creates static getters for all discovered services,
/// allowing the Provider class to be in a common/shared package while
/// the Registrar remains in platform-specific code.
class ProviderGenerator extends GeneratorForAnnotation<DiscoveryProvider> {
  const ProviderGenerator();

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        "@Provider can only be applied to classes",
        element: element,
      );
    }

    // Read the name parameter from the annotation (defaults to "Provider")
    final className = annotation.read("name").stringValue;

    // Read concrete parameter
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

    // Scan for all services in the package
    final interfaceToImplementations = await _scanForServices(buildStep);

    // Generate provider as a utility class with static getters
    final buffer = StringBuffer();
    buffer.writeln("// ignore_for_file: non_constant_identifier_names");
    buffer.writeln();
    buffer.writeln("abstract class $className {");
    buffer.writeln("  $className._();");
    buffer.writeln();
    _generateGetters(buffer, interfaceToImplementations, concreteTypes);
    buffer.writeln("}");

    return buffer.toString();
  }

  Future<Map<InterfaceType, List<ClassElement>>> _scanForServices(
      BuildStep buildStep) async {
    final definitions = <InterfaceType, List<ClassElement>>{};
    final processedClassNames = <String>{};
    final package = buildStep.inputId.package;

    // 1. Scan local assets (files in lib/)
    await _scanPackage(buildStep, package, definitions, processedClassNames,
        isLocal: true);

    // 2. Scan dependencies from pubspec.yaml
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
              // Skip sdk dependencies and some common non-service packages
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

    // 3. Scan reachable libraries (imports)
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
        if (uri == null) return;
        final config = await loadPackageConfigUri(uri);

        final pkg = config.packages.firstWhere(
          (p) => p.name == package,
          orElse: () => throw "Package $package not found",
        );

        final libPath = pkg.packageUriRoot.toFilePath();
        final libDir = Directory(libPath);
        if (!await libDir.exists()) return;

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
      } catch (e) {
        return;
      }
    }

    await for (final assetId in assetStream) {
      if (assetId.package != package) continue;

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

    if (interfaces.isEmpty) {
      interfaces.add(cls.thisType);
    }

    return interfaces;
  }

  void _generateGetters(
      StringBuffer buffer,
      Map<InterfaceType, List<ClassElement>> services,
      List<ClassElement> concreteTypes) {
    final allInterfaces = services.keys.toSet();
    final sortedInterfaces = allInterfaces.toList()
      ..sort((a, b) => (a.element.name ?? "").compareTo(b.element.name ?? ""));

    for (final interface in sortedInterfaces) {
      final implementations = services[interface] ?? [];
      final hasConcreteImplementation = implementations.any((impl) =>
          concreteTypes.any((c) =>
              c.name == impl.name &&
              c.library.identifier == impl.library.identifier));

      if (hasConcreteImplementation) {
        continue;
      }

      final instanceName = _toCamelCase(interface.element.name!);
      buffer.writeln(
          "  static ${interface.element.name!} get $instanceName => ServiceDiscovery.instance.resolve<${interface.element.name!}>();");
    }

    // Generate getters for explicit concrete types
    final sortedConcrete = concreteTypes.toList()
      ..sort((a, b) => (a.name ?? "").compareTo(b.name ?? ""));

    for (final concrete in sortedConcrete) {
      final instanceName = _toCamelCase(concrete.name!);
      buffer.writeln(
          "  static ${concrete.name!} get $instanceName => ServiceDiscovery.instance.resolve<${concrete.name!}>();");
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

      // Skip private classes
      if (cls.isPrivate) continue;

      if (_inheritsFromService(cls)) {
        processedClassNames.add(cls.name!);

        if (cls.isAbstract) {
          // For abstract services, we register them as keys so a getter is generated.
          // We don't add any implementations to the list.
          if (cls.name == "Service" || cls.name == "BasicService") {
            if (_isServiceLibrary(cls)) {
              continue;
            }
          }
          definitions.putIfAbsent(cls.thisType, () => []);
          continue;
        }

        final interfaces = _findServiceInterfaces(cls);
        for (final interface in interfaces) {
          definitions.putIfAbsent(interface, () => []).add(cls);
        }
      }
    }
  }
}
