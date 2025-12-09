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

Register your service instances with the `ServiceDiscovery` singleton. You can register by type or with a specific name.

```dart
final myService = MyService();

// Register by Type
ServiceDiscovery.instance.register<MyService>(myService);

// Register by Name
ServiceDiscovery.instance.register<MyService>(myService, name: 'my_service_alias');
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
const namedServiceProvider = ServiceProvider<MyService>(name: 'my_service_alias');

// Access the service
myServiceProvider.service.doSomething();
namedServiceProvider.service.doSomething();
```

### 6. Reset Services

You can trigger a reset on all registered services, for example, during logout.

```dart
await ServiceDiscovery.instance.reset();
```


