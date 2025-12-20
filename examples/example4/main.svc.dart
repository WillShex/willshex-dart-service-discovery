// GENERATED CODE - DO NOT MODIFY BY HAND

part of "main.dart";

// **************************************************************************
// DiscoveryConfigGenerator
// **************************************************************************

class Registrar {
  Registrar._();
  static Future<void> init() async {
    ServiceDiscovery.instance.register<DependentService>(DependentService());
    ServiceDiscovery.instance.register<PrincipalService>(PrincipalService());
    await ServiceDiscovery.instance.init();
  }
}

class Provider {
  Provider._();
  static DependentService get dependentService =>
      ServiceDiscovery.instance.resolve<DependentService>();
  static PrincipalService get principalService =>
      ServiceDiscovery.instance.resolve<PrincipalService>();
}
