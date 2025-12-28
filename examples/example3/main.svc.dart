// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of "main.dart";

// **************************************************************************
// DiscoveryConfigGenerator
// **************************************************************************

class Registrar {
  Registrar._();
  static Future<void> init() async {
    ServiceDiscovery.instance.register<ImplementationA>(ImplementationA());
    ServiceDiscovery.instance.register<ImplementationB>(ImplementationB());
    await ServiceDiscovery.instance.init();
  }
}

// **************************************************************************
// DiscoveryProviderGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names

abstract class Provider {
  Provider._();

  static AbstractService get abstractService =>
      ServiceDiscovery.instance.resolve<AbstractService>();
  static ImplementationA get implementationA =>
      ServiceDiscovery.instance.resolve<ImplementationA>();
  static ImplementationB get implementationB =>
      ServiceDiscovery.instance.resolve<ImplementationB>();
}
