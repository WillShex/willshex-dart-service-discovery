import "dart:async";

import "package:analyzer/dart/element/element.dart";
import "package:build/build.dart";
import "package:source_gen/source_gen.dart";
import "package:willshex_dart_service_discovery/src/annotations/configure_discovery.dart";
import "package:glob/glob.dart";
import "package:analyzer/dart/element/type.dart";

/// Generates provider methods for classes annotated with @Discovery.
///
/// This generator creates static getters for all discovered services,
/// allowing the Provider class to be in a common/shared package while
/// the Registrar remains in platform-specific code.
class DiscoveryProviderGenerator extends GeneratorForAnnotation<Discovery> {
  const DiscoveryProviderGenerator();

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        "@Discovery can only be applied to classes",
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

    final package = buildStep.inputId.package;
    final glob = Glob("**/*.dart");

    await for (final assetId in buildStep.findAssets(glob)) {
      if (assetId.package != package) continue;

      // Skip generated files
      if (assetId.path.endsWith(".g.dart") ||
          assetId.path.endsWith(".svc.dart") ||
          assetId.path.endsWith(".freezed.dart")) {
        continue;
      }

      // Filter based on scope
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

      try {
        final library = await buildStep.resolver.libraryFor(assetId);

        for (final cls in library.classes) {
          if (cls.isAbstract) continue;

          if (_inheritsFromService(cls)) {
            final interfaces = _findServiceInterfaces(cls);
            for (final interface in interfaces) {
              definitions.putIfAbsent(interface, () => []).add(cls);
            }
          }
        }
      } catch (e) {
        continue;
      }
    }

    return definitions;
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
}
