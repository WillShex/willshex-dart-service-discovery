// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of "main.dart";

// **************************************************************************
// RegistrarGenerator
// **************************************************************************

class Registrar {
  Registrar._();
  static Future<void> init({
    required AbstractService abstractService,
    void Function(Type type)? onChange,
  }) async {
    ServiceDiscovery.instance.register<AbstractService>(abstractService);
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

  static AbstractService get abstractService =>
      ServiceDiscovery.instance.resolve<AbstractService>();
}
