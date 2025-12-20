// GENERATED CODE - DO NOT MODIFY BY HAND

part of "main.dart";

// **************************************************************************
// DiscoveryConfigGenerator
// **************************************************************************

class Registrar {
  Registrar._();
  static Future<void> init({
    required AbstractService abstractService,
  }) async {
    ServiceDiscovery.instance.register<AbstractService>(abstractService);
    await ServiceDiscovery.instance.init();
  }
}

class Provider {
  Provider._();
  static AbstractService get abstractService =>
      ServiceDiscovery.instance.resolve<AbstractService>();
}
