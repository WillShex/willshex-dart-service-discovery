// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

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

// **************************************************************************
// DiscoveryProviderGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names

abstract class Provider {
  Provider._();

  static DependentService get dependentService =>
      ServiceDiscovery.instance.resolve<DependentService>();
  static PrincipalService get principalService =>
      ServiceDiscovery.instance.resolve<PrincipalService>();
}
