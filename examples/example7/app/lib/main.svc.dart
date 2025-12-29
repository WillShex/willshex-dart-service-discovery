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
    ServiceDiscovery.instance.register<LibService>(LibService());
    ServiceDiscovery.instance.register<LibService1>(LibService1());
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

  static LibService get libService =>
      ServiceDiscovery.instance.resolve<LibService>();
  static LibService1 get libService1 =>
      ServiceDiscovery.instance.resolve<LibService1>();
}
