// GENERATED CODE - DO NOT MODIFY BY HAND

part of "main.dart";

// **************************************************************************
// DiscoveryConfigGenerator
// **************************************************************************

class Registrar {
  static Future<void> init({
    required AbstractService abstractService,
  }) async {
    ServiceDiscovery.instance.register<AbstractService>(abstractService);
    await ServiceDiscovery.instance.init();
  }
}

class Provider {
  static AbstractService get abstractService =>
      ServiceDiscovery.instance.resolve<AbstractService>();
}
