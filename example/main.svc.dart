// GENERATED CODE - DO NOT MODIFY BY HAND

part of "main.dart";

// **************************************************************************
// DiscoveryConfigGenerator
// **************************************************************************

Future<void> $configureDiscovery() async {
  ServiceDiscovery.instance
      .register<AnotherExampleService>(AnotherExampleService());
  ServiceDiscovery.instance.register<ExampleService>(ExampleService());
  await ServiceDiscovery.instance.init();
}
