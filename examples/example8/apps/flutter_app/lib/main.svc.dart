// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'main.dart';

// **************************************************************************
// RegistrarGenerator
// **************************************************************************

class Registrar {
  Registrar._();
  static Future<void> init({
    void Function(Type type)? onChange,
  }) async {
    ServiceDiscovery.instance.register<SharedService>(FlutterServiceImpl());
    await ServiceDiscovery.instance.init(
      onChange: onChange,
    );
  }
}
