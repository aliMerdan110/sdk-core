# Mebabl Database

A Flutter SDK for accessing Mebabl database services.

`mebabl_database` provides a simple API for working with:

* Collections
* Documents
* Create, read, update, and delete operations
* Application-isolated database data

## Installation

Add `mebabl_database` to your `pubspec.yaml`:

```yaml
dependencies:
  mebabl_database: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Requirements

This package requires:

* Flutter 3.32.0 or later
* Dart 3.8.1 or later
* A configured Mebabl application
* `mebabl_core`

## Initialization

Initialize `MebablCore` before creating the database service:

```dart
import 'package:mebabl_core/mebabl_core.dart';
import 'package:mebabl_database/mebabl_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await MebablCore.initialize();

  final database = MebablDatabaseService(
    core: MebablCore.instance,
  );
}
```

## Collections

### Create a collection

```dart
final collection = await database.collections.create(
  name: 'products',
  description: 'Application products',
);
```

### List collections

```dart
final collections = await database.collections.list();
```

### Get a collection

```dart
final collection = await database.collections.get(
  collectionId,
);
```

### Update a collection

```dart
final collection = await database.collections.update(
  collectionId: collectionId,
  name: 'products',
  description: 'Updated description',
);
```

### Delete a collection

```dart
await database.collections.delete(collectionId);
```

## Documents

### Create a document

```dart
final document = await database.documents.create(
  collectionId: collectionId,
  key: 'product-001',
  data: {
    'name': 'Product One',
    'price': 100,
    'active': true,
  },
);
```

### List documents

```dart
final documents = await database.documents.list(
  collectionId: collectionId,
);
```

### Get a document

```dart
final document = await database.documents.get(
  documentId,
);
```

### Update a document

```dart
final document = await database.documents.update(
  documentId: documentId,
  key: 'product-001',
  data: {
    'name': 'Updated Product',
    'price': 150,
    'active': true,
  },
);
```

### Delete a document

```dart
await database.documents.delete(documentId);
```

## Application Isolation

Database data is isolated by Mebabl Application.

Each application can access only its own collections and documents through the configured Mebabl application context.

## Error Handling

Mebabl SDK exceptions can be handled normally:

```dart
try {
  final document = await database.documents.get(documentId);
} catch (e) {
  print(e);
}
```

## Related Packages

* `mebabl_core` — Core Mebabl SDK functionality
* `mebabl_auth` — Authentication services
* `mebabl_database` — Database services

## Repository

Source code and issue tracking:

https://github.com/aliMerdan110/Mebabl.Sdk

## License

This package is released under the MIT License.
