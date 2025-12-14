import "abstract_service.dart";

class ImplementationA extends AbstractService {
  @override
  Future<void> onInit() async => print("A init");

  @override
  Future<void> onReset() async => print("A reset");
}
