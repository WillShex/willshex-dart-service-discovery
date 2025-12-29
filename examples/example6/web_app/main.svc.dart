// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of "main.dart";

// **************************************************************************
// RegistrarGenerator
// **************************************************************************

class Registrar {
  Registrar._();
  static Future<void> init({
    required LoggingService loggingService,
    void Function(Type type)? onChange,
  }) async {
    ServiceDiscovery.instance.register<LoggingService>(loggingService);
    await ServiceDiscovery.instance.init(
      onChange: onChange,
    );
  }
}
