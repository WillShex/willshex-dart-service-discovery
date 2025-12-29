# willshex_dart_service_discovery

A generic service discovery registry for Dart applications, supporting dependency injection, topological initialization reporting, and multi-platform shared providers.

## Getting Started

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  willshex_dart_service_discovery:
    path: packages/willshex_dart_service_discovery
  
dev_dependencies:
  build_runner: ^2.4.0
```

## Usage

### 1. Define Services

You have two options for defining services: extending `BasicService` (recommended) or implementing `Service` directly.

#### A. Extend `BasicService` (Recommended)

`BasicService` handles initialization state tracking (`isInitialized`) and provides a `verifyInitialized()` helper. You only need to implement `onInit` and `onReset`.

```dart
import 'package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart';

class MyService extends BasicService {
  @override
  Future<void> onInit() async {
    // Initialization logic
  }

  @override
  Future<void> onReset() async {
    // Reset/Cleanup logic
  }

  void doSomething() {
    verifyInitialized(); // Throws if not initialized
    // Service logic
  }
}
```

#### B. Implement `Service` (Advanced)

If you need full control over initialization logic or state, implement the `Service` interface directly. You must manage your own state.

```dart
class MyCustomService implements Service {
  @override
  Future<void> init() async {
    // Custom initialization
  }

  @override
  Future<void> reset() async {
    // Custom reset
  }
}
```

### 2. Configure Service Discovery

Use annotations to generate the service registry and provider accessors.

#### `@DiscoveryProvider`

Generates a `Provider` class with static getters for your services. This allows type-safe, easy access to registered services.

```dart
// provider.dart (or in main.dart)
import 'package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart';

part 'provider.svc.dart';

@DiscoveryProvider()
abstract class Trigger {} 
// Generates "class Provider { ... }"
```

#### `@DiscoveryRegistrar`

Generates a `Registrar` class responsible for initializing and registering services. It handles dependency resolution and topological sorting.

```dart
// main.dart
import 'package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart';

part 'main.svc.dart';

@DiscoveryRegistrar()
void main() async {
  // Initialize services
  await Registrar.init(
    onChange: (type) => print('Initializing $type...'),
  );

  // Access services
  final service = Provider.myService;
}
```

### 3. Run Build Runner

```bash
dart run build_runner build
```

---

## Examples

The `examples/` directory contains various scenarios demonstrating the capabilities of the package.

### Example 1: Basic Usage
Demonstrates the simplest setup: defining a service, triggering generation, and accessing it via `Provider`.

### Example 2: Ambiguity Resolution (Injection)
Shows how to handle interfaces with multiple implementations.
- `AbstractService` has `ImplementationA` and `ImplementationB`.
- `Registrar.init` generates named parameters to let you inject the desired implementation at runtime (e.g., `await Registrar.init(abstractService: ImplementationA())`).

### Example 3: Multiple Concrete Registration
Shows how to register multiple implementations of the same interface so they can be accessed distinctively.
- Uses `@DiscoveryRegistrar(concrete: [ImplementationA, ImplementationB])` to ensure both are available via `Provider.implementationA` and `Provider.implementationB`.

### Example 4: Dependency Injection & Ordering
Demonstrates automatic dependency resolution.
- `PrincipalService` depends on `DependentService` (via `@DependsOn`).
- The `Registrar` automatically initializes `DependentService` before `PrincipalService`.

### Example 5: Circular Dependency
Demonstrates that the generator detects circular dependencies (A->B->A) and fails the build with a descriptive error, preventing runtime deadlocks.

### Example 6: Multi-Platform (Flutter + Web)
A complete example of a monorepo structure sharing common business logic while using platform-specific service implementations.

**Structure:**
- **Common**: `LoggingService` interface and `@DiscoveryProvider` (generated `Provider`).
- **Flutter App**: `FileLoggingService` implementation and `@DiscoveryRegistrar`.
- **Web App**: `ConsoleLoggingService` implementation and `@DiscoveryRegistrar`.

**Key Concept**: The `Provider` is generated in the common package, allowing shared code to access `Provider.loggingService` without knowing if it's running on Flutter or Web. The platform-specific entry point registers the correct implementation.

### Example 7: Cross-Package Discovery
Demonstrates finding and registering services declared in imported packages (`lib_ex7`, `lib_ex7_1`). The generator scans dependencies to ensure all available services are discoverable.

### Example 8: Monorepo & Business Logic
Similar to Example 6 but focuses on sharing a complex `CommonBusiness` logic component that relies on the injected services.
