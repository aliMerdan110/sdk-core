# Mebabl Database

**Mebabl Database Flutter SDK** provides a project-scoped database service for Flutter applications built with the Mebabl Platform.

It provides a simple and consistent API for managing collections, documents, queries, pagination, and atomic batch writes.

## Features

- Project-scoped database architecture.
- Collections management.
- Documents CRUD operations.
- JSON document storage.
- Optimistic concurrency using document versions.
- Query filters and sorting.
- Cursor-based pagination.
- Offset pagination for custom sorting.
- Atomic Batch Writes.
- Integration with Mebabl Core authentication.
- Server-side security policy enforcement.

## Installation

Add `mebabl_database` to your `pubspec.yaml`:

```yaml
dependencies:
  mebabl_database: ^1.0.5
  mebabl_core: ^1.2.0
```

Then run:

```bash
flutter pub get
```

## Requirements

- Flutter 3.32.0 or later.
- Dart 3.8.1 or later.
- `mebabl_core`.
- A configured Mebabl project and application.
- An authenticated application user for user-facing database operations.

## Initialization

Initialize Mebabl Core before creating the database service.

```dart
import 'package:flutter/widgets.dart';
import 'package:mebabl_core/mebabl_core.dart';
import 'package:mebabl_database/mebabl_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await MebablCore.initialize();

  final database = MebablDatabaseService(
    core: MebablCore.instance,
  );

  runApp(MyApp(database: database));
}
```

## Collections

Collections are project-owned database resources. Applications registered within the same project share these resources, subject to database security policies.

### Create a collection

```dart
final collection = await database.collections.create(
  name: 'products',
  description: 'Product catalog',
);
```

### List collections

```dart
final collections = await database.collections.list();

for (final collection in collections) {
  print(collection.name);
}
```

### Get a collection

```dart
final collection = await database.collections.get(
  collectionId: collectionId,
);
```

### Update a collection

```dart
final collection = await database.collections.update(
  collectionId: collectionId,
  name: 'products',
  description: 'Updated product catalog',
);
```

### Delete a collection

```dart
await database.collections.delete(
  collectionId: collectionId,
);
```

## Documents

Documents contain JSON objects and are stored inside collections.

Every document has a unique identifier, key, data, version, and timestamps.

### Create a document

```dart
final document = await database.documents.create(
  collectionId: collection.id,
  key: 'product-001',
  data: {
    'name': 'Product One',
    'price': 100,
    'active': true,
  },
);

print(document.id);
print(document.version);
```

### Get a document

```dart
final document = await database.documents.get(
  collectionId: collection.id,
  documentId: documentId,
);
```

### List documents

```dart
final documents = await database.documents.list(
  collectionId: collection.id,
);
```

For large collections, use Query and pagination instead of loading all documents.

### Update a document

Updates require the current document version to prevent overwriting newer data.

```dart
await database.documents.update(
  collectionId: collection.id,
  documentId: document.id,
  key: document.key,
  data: {
    'name': 'Updated Product',
    'price': 150,
    'active': true,
  },
  expectedVersion: document.version,
);
```

### Delete a document

```dart
await database.documents.delete(
  collectionId: collection.id,
  documentId: document.id,
  expectedVersion: document.version,
);
```

Document deletion is performed as a soft delete.

## Query Engine

The Query service supports filtering, sorting, search, and pagination.

### Query filters

```dart
final request = QueryRequest(
  collectionId: collection.id,
  filters: [
    QueryFilter(
      field: 'active',
      operator: QueryOperator.equal,
      value: true,
    ),
    QueryFilter(
      field: 'price',
      operator: QueryOperator.greaterThan,
      value: 50,
    ),
  ],
  limit: 25,
);

final page = await database.query.execute(request);

for (final document in page.items) {
  print(document.data);
}
```

### Supported operators

- `equal`
- `notEqual`
- `greaterThan`
- `greaterThanOrEqual`
- `lessThan`
- `lessThanOrEqual`
- `contains`
- `startsWith`
- `endsWith`

### Sorting

```dart
final request = QueryRequest(
  collectionId: collection.id,
  sorts: [
    QuerySort(
      field: 'createdAt',
      direction: QuerySortDirection.desc,
    ),
  ],
);
```

Supported fields include `createdAt`, `updatedAt`, `key`, and `version`.

### Search

```dart
final request = QueryRequest(
  collectionId: collection.id,
  search: 'product',
  limit: 25,
);
```

The current backend search targets document keys.

## Pagination

The Query API supports cursor pagination using an opaque page token.

```dart
final request = QueryRequest(
  collectionId: collection.id,
  limit: 25,
);

final firstPage = await database.query.execute(request);

for (final document in firstPage.items) {
  print(document.key);
}

if (firstPage.hasMore) {
  final nextPage = await database.query.executeNext(
    request: request,
    previousPage: firstPage,
  );

  for (final document in nextPage.items) {
    print(document.key);
  }
}
```

The `QueryPage` response provides:

- `items`
- `hasMore`
- `nextPageToken`
- `nextOffset`
- `collectionId`

The SDK uses cursor pagination with the default ordering. Custom sorting currently uses offset pagination.

The maximum page size is 100 documents.

## Batch Writes

Batch Writes execute multiple document mutations as one atomic operation.

The server commits all operations together or rolls back the entire transaction if any operation fails.

### Create, update, and delete in one batch

```dart
final result = await database.documents.batchWrite(
  collectionId: collection.id,
  operations: [
    BatchWriteDocumentOperation.create(
      key: 'product-003',
      data: {
        'name': 'Product Three',
        'price': 300,
      },
    ),

    BatchWriteDocumentOperation.update(
      documentId: existingDocument.id,
      key: existingDocument.key,
      data: {
        'name': 'Updated Product',
        'price': 200,
      },
      expectedVersion: existingDocument.version,
    ),

    BatchWriteDocumentOperation.delete(
      documentId: oldDocument.id,
      expectedVersion: oldDocument.version,
    ),
  ],
);
```

### Read batch results

```dart
for (final operation in result.results) {
  print('Document ID: ${operation.documentId}');
  print('Version: ${operation.version}');
  print('Operation: ${operation.type}');
  print('Deleted: ${operation.isDeleted}');
}
```

Batch limitations:

- Maximum 500 operations.
- Maximum aggregate JSON payload of 1 MiB.
- A document can only be targeted once per batch.
- Every update and delete requires an expected version.
- Results are returned only after successful transaction commit.

## Security and Project Isolation

Mebabl Database follows a project-scoped architecture.

- `ProjectId` defines the database ownership and isolation boundary.
- Applications within the same project share project database resources.
- Application identity authenticates the calling application.
- User identity identifies the authenticated end user.
- Collection security policies determine permitted database operations.

Database access is enforced by the backend. The SDK does not provide a mechanism to bypass security policies.

Collections without an active published security policy remain inaccessible to end users.

## Error Handling

Database operations can fail due to authentication, authorization, validation, concurrency conflicts, or network errors.

Handle errors using normal Dart exception handling:

```dart
try {
  final document = await database.documents.get(
    collectionId: collection.id,
    documentId: documentId,
  );

  print(document.data);
} catch (error) {
  print('Database operation failed: $error');
}
```

## Related Packages

- `mebabl_core` — Core SDK infrastructure and application authentication.
- `mebabl_auth` — User authentication services.
- `mebabl_database` — Project-scoped database services.

## Repository

Source code and issue tracking:

[https://github.com/aliMerdan110/Mebabl.Sdk](https://github.com/aliMerdan110/Mebabl.Sdk)

## License

This package is released under the MIT License.
