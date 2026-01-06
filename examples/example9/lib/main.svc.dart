// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of "main.dart";

// **************************************************************************
// RegistrarGenerator
// **************************************************************************

class Registrar {
  Registrar._();
  static Future<void> init({
    void Function(Type type)? onChange,
  }) async {
    ServiceDiscovery.instance.register<ServiceX>(ServiceX());
    ServiceDiscovery.instance.register<C1Service>(C1Service());
    ServiceDiscovery.instance.register<C2Service>(C2Service());
    await ServiceDiscovery.instance.init(
      onChange: onChange,
    );
  }
}

// **************************************************************************
// ProviderGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names

abstract class Provider {
  Provider._();

  static C1Service get c1Service =>
      ServiceDiscovery.instance.resolve<C1Service>();
  static C2Service get c2Service =>
      ServiceDiscovery.instance.resolve<C2Service>();
  static ServiceX get serviceX => ServiceDiscovery.instance.resolve<ServiceX>();
}
