import "package:build/build.dart";
import "package:source_gen/source_gen.dart";
import "package:willshex_dart_service_discovery/src/generator/discovery_generator.dart";

Builder discoveryBuilder(BuilderOptions options) => PartBuilder(
      [const DiscoveryConfigGenerator(), const ServiceProviderGenerator()],
      ".svc.dart",
    );
