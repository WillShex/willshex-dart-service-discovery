// GENERATED CODE - DO NOT MODIFY BY HAND

part of "main.dart";

// **************************************************************************
// DiscoveryConfigGenerator
// **************************************************************************

class Registrar {
  static Future<void> init() async {
    ServiceDiscovery.instance.register<ImplementationA>(ImplementationA());
    ServiceDiscovery.instance.register<ImplementationB>(ImplementationB());
    await ServiceDiscovery.instance.init();
  }
}

class Provider {
  static ImplementationA get implementationA =>
      ServiceDiscovery.instance.resolve<ImplementationA>();
  static ImplementationB get implementationB =>
      ServiceDiscovery.instance.resolve<ImplementationB>();
}
