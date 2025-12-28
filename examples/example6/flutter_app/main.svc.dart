// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of "main.dart";

// **************************************************************************
// DiscoveryConfigGenerator
// **************************************************************************

class Registrar {
  Registrar._();
  static Future<void> init({
    required LoggingService loggingService,
  }) async {
    ServiceDiscovery.instance.register<LoggingService>(loggingService);
    await ServiceDiscovery.instance.init();
  }
}
