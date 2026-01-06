import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";
import "services/my_service.dart";
import "services/service_x.dart";

part "main.svc.dart";

@DiscoveryRegistrar(concrete: [
  C1Service,
  C2Service,
  ServiceX,
])
@DiscoveryProvider(concrete: [
  C1Service,
  C2Service,
  ServiceX,
])
class Trigger {}

void main() async {
  await Registrar.init();
}
