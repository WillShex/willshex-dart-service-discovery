# willshex_dart_service_discovery

A generic service discovery registry for Dart applications.

## Getting Started

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  willshex_dart_service_discovery:
    path: packages/willshex_dart_service_discovery
```

## Usage

### 1. Define a Service

Implement the `Service` abstract class for your services.

```dart
import 'package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart';

class MyService extends Service {
  @override
  Future<void> onInit() async {
    // Initialization logic
  }

  @override
  Future<void> onReset() async {
    // Reset/Cleanup logic
  }

  void doSomething() {
    verifyInitialized();
    // Service logic
  }
}
```

### 2. Register Services

Register your service instances with the `ServiceDiscovery` singleton. You can register by type.

```dart
// Register usage
ServiceDiscovery.instance.register<MyService>(MyService());
```

### 3. Initialize Services

Initialize all registered services in order. This is typically done at app startup.

```dart
await ServiceDiscovery.instance.init(
  onProgress: (service, key) {
    print('Initializing $key...');
  },
);
```

### 4. Resolve Services

Retrieve your registered services anywhere in your application.

```dart
// Resolve by Type
final myService = ServiceDiscovery.instance.resolve<MyService>();

// Resolve by Name
final namedService = ServiceDiscovery.instance.resolve<MyService>(name: 'my_service_alias');
```

### 5. Use ServiceProvider (Helper)

Use the `ServiceProvider` class for easy access to services.

```dart
// Define a provider
const myServiceProvider = ServiceProvider<MyService>();

// Access the service
myServiceProvider.service.doSomething();
```

### 6. Reset Services

You can trigger a reset on all registered services, for example, during logout.

```dart
await ServiceDiscovery.instance.reset();
```



### 7. Code Generation (Optional)

You can maintain a simple registry of your services using `build_runner`.

#### 7.1 Setup

Add `build_runner` to your `dev_dependencies` and the package to `dependencies`.

#### 7.2 Usage

1.  **Define Services**: Create your services extending `Service`. To generate a `ServiceProvider` for easier access, add a `part` directive.

    ```dart
    // my_service.dart
    import 'package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart';

    part 'my_service.svc.dart';

    class MyService extends Service {
      // ...
    }
    ```

2.  **Configure Discovery**: In your entry point (e.g., `main.dart` or `config.dart`), add the `@ConfigureDiscovery` annotation and the `part` directive.

    ```dart
    import 'package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart';
    // Import your services so they can be referenced
    import 'services/my_service.dart'; 

    part 'main.svc.dart';

    @ConfigureDiscovery()
    void configure() => $configureDiscovery();

    void main() async {
      await configure();
      // ServiceDiscovery.instance.init() is called automatically by configure()
      // ...
    }
    ```

3.  **Run Builder**:

    ```bash
    dart run build_runner build
    ```

    *   `main.svc.dart` will be generated with the `$configureDiscovery` function registering and initializing all found services.
    *   `my_service.svc.dart` will be generated containing configuration `MyServiceProvider`.


