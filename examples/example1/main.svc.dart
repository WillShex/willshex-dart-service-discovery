// GENERATED CODE - DO NOT MODIFY BY HAND

part of "main.dart";

// **************************************************************************
// DiscoveryConfigGenerator
// **************************************************************************

class Registrar {
  Registrar._();
  static Future<void> init() async {
    ServiceDiscovery.instance
        .register<AnotherExampleService>(AnotherExampleService());
    ServiceDiscovery.instance.register<ExampleService>(ExampleService());
    await ServiceDiscovery.instance.init();
  }
}

class Provider {
  Provider._();
  static AnotherExampleService get anotherExampleService =>
      ServiceDiscovery.instance.resolve<AnotherExampleService>();
  static ExampleService get exampleService =>
      ServiceDiscovery.instance.resolve<ExampleService>();
}
