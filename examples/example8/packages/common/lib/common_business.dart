import "package:common/provider.dart";

class CommonBusiness {
  static final CommonBusiness _instance = CommonBusiness._();

  static CommonBusiness get get => _instance;

  void doSomething() {
    Provider.sharedService.doSharedThing();
  }

  CommonBusiness._();
}
