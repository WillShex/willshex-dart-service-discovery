import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";
import "dependent_service.dart";

@DependsOn([DependentService])
class PrincipalService extends BasicService {
  @override
  Future<void> onInit() async => print("PrincipalService init");
  @override
  Future<void> onReset() async => print("PrincipalService reset");
}
