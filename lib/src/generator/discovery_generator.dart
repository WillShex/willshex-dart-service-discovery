import "dart:async";

import "package:analyzer/dart/element/element.dart";
import "package:analyzer/dart/element/type.dart";
import "package:build/build.dart";
import "package:glob/glob.dart";
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
    final services = <ClassElement>[];

    // Scan all dart files in the package (lib/** and example/**)
    final assets = buildStep.findAssets(Glob("{lib,example}/**.dart"));

    await for (final asset in assets) {
      try {
        if (!await buildStep.resolver.isLibrary(asset)) continue;

        final lib = await buildStep.resolver.libraryFor(asset);

        for (final cls in lib.topLevelElements.whereType<ClassElement>()) {
          if (cls.isAbstract) continue;
          if (_inheritsFromService(cls)) {
            services.add(cls);
          }
        }
      } catch (e) {
        // Ignore files that fail to resolve
      }
    }

    // Sort by name for deterministic output
    services.sort((a, b) => (a.name).compareTo(b.name));

    final buffer = StringBuffer();
    // Use double quotes for generated code
    buffer.writeln("Future<void> \$configureDiscovery() async {");
    for (final service in services) {
      buffer.writeln(
          "  ServiceDiscovery.instance.register<${service.name}>(${service.name}());");
    }
    buffer.writeln("  await ServiceDiscovery.instance.init();");
    buffer.writeln("}");

    return buffer.toString();
  }
}

/// Generates ServiceProvider classes for each Service.
class ServiceProviderGenerator extends Generator {
  const ServiceProviderGenerator();

  @override
  Future<String> generate(LibraryReader library, BuildStep buildStep) async {
    final buffer = StringBuffer();

    for (final cls in library.classes) {
      if (cls.isAbstract) continue;
      if (_inheritsFromService(cls)) {
        final name = cls.name;
        // Check if we already generated this (unlikely in same build step but good practice not to duplicate if multiple classes in file)

        buffer
            .writeln("class ${name}Provider extends ServiceProvider<$name> {");
        buffer.writeln("  const ${name}Provider();");
        buffer.writeln("  static const instance = ${name}Provider();");
        buffer.writeln("}");
        buffer.writeln();
      }
    }

    return buffer.toString();
  }
}

bool _inheritsFromService(ClassElement? cls) {
  if (cls == null) return false;

  for (InterfaceType type in cls.allSupertypes) {
    if (type.element.name == "Service" &&
        type.element.library.source.uri
            .toString()
            .contains("willshex_dart_service_discovery")) {
      return true;
    }
  }
  return false;
}
