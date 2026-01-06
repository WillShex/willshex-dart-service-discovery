import "dart:async";

import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";
import "service_x.dart";

@DependsOn([ServiceX])
abstract class AbstractService extends Service {
  Future<void> doSomething();
}

class C1Service extends AbstractService {
  @override
  Future<void> doSomething() async {
    print("C1 doing something");
  }

  @override
  FutureOr<void> init() {
    print("C1 init");
  }

  @override
  FutureOr<void> reset() {
    print("C1 reset");
  }
}

class C2Service extends AbstractService {
  @override
  Future<void> init() async {
    print("C2 init");
  }

  @override
  Future<void> reset() async {
    print("C2 reset");
  }

  @override
  Future<void> doSomething() async {
    print("C2 doing something");
  }
}
