import "package:build/build.dart";
import "package:source_gen/source_gen.dart";
import "package:willshex_dart_service_discovery/src/generator/provider_generator.dart";
import "package:willshex_dart_service_discovery/src/generator/registrar_generator.dart";

Builder discoveryBuilder(BuilderOptions options) => PartBuilder(
    [const RegistrarGenerator(), const ProviderGenerator()], ".svc.dart");
