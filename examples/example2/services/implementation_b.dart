import "abstract_service.dart";

class ImplementationB extends AbstractService {
  @override
  Future<void> onInit() async => print("B init");

  @override
  Future<void> onReset() async => print("B reset");
}
