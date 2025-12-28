// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of "main.dart";

// **************************************************************************
// DiscoveryConfigGenerator
// **************************************************************************

class Registrar {
  Registrar._();
  static Future<void> init() async {
    ServiceDiscovery.instance.register<SharedService>(WebServiceImpl());
    await ServiceDiscovery.instance.init();
  }
}
