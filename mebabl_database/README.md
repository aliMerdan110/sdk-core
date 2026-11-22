# Mebabl Database

`mebabl_database` is the Flutter SDK for the project-scoped, document-oriented database in Mebabl Platform.

Collections are addressed by a stable code such as `user_profiles`. The backend keeps Collection GUIDs internal and materializes a collection automatically as part of the first successful document write. Applications in the same Project share the Project Database, subject to the published Database Security Rules.

## Features

- Project-wide collections addressed by stable collection codes.
- Automatic collection materialization on the first successful write.
- JSON document storage and CRUD operations.
- Optimistic concurrency through document ETags and `If-Match`.
- Query filters, sorting, search, and cursor pagination.
- Atomic batch writes.
- Mebabl Core authentication integration.
- Server-side enforcement of published Database Security Rules.

## Installation

```yaml
dependencies:
  mebabl_database: ^1.1.0
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
- A configured Mebabl Project and Application.
- An authenticated Application User for SDK database operations.

## Initialization

Initialize Mebabl Core before creating the Database service.

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

A collection is identified by its code, not by an internal GUID. Do not create collections manually in the SDK.

```dart
final collections = await database.collections.list();

for (final collection in collections) {
  print('${collection.code}: ${collection.name}');
}
```

The SDK catalog returns materialized collections discoverable under the caller's published rules. A collection with owner-only access may be addressed by its known code but is not exposed in the global catalog.

A collection can be configured in Developer Console before the first document exists:

1. Define the collection code and its Database Security Rules in the Project Console.
2. Validate and publish the policy.
3. Write the first document from an Application.
4. The backend creates the internal collection record and persists the first document in the same transaction.

A draft policy does not grant SDK access. A missing or unpublished policy fails closed.

## Documents

Documents are JSON objects stored inside a collection. Each document has a backend-generated identifier, a caller-selected key, a version, and timestamps.

### Create

```dart
final document = await database.documents.create(
  collectionCode: 'products',
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

If `products` has a published policy allowing `create`, the backend materializes the collection automatically on this first successful write.

### Get

```dart
final document = await database.documents.get(
  collectionCode: 'products',
  documentId: documentId,
);

print(document.data);
```

### List

```dart
final documents = await database.documents.list(
  collectionCode: 'products',
);

for (final document in documents) {
  print(document.key);
}
```

Listing requires a published `list` grant. For large collections, use Query pagination instead of loading all documents.

### Update

Updates require the current document version to prevent overwriting a newer version.

```dart
await database.documents.update(
  collectionCode: 'products',
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

The SDK sends the expected version as a strong ETag in `If-Match`. A successful update advances the document version.

### Delete

```dart
await database.documents.delete(
  collectionCode: 'products',
  documentId: document.id,
  expectedVersion: document.version,
);
```

Document deletion is a soft delete and requires the current version.

## Query Engine

Queries are addressed by collection code. The code is carried in the route; the JSON request contains only query constraints.

```dart
final request = QueryRequest(
  collectionCode: 'products',
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

### Sorting and search

```dart
final request = QueryRequest(
  collectionCode: 'products',
  sorts: [
    QuerySort(
      field: 'createdAt',
      direction: QuerySortDirection.desc,
    ),
  ],
  search: 'product',
  limit: 25,
);
```

Search currently targets document keys. Supported sort fields include `createdAt`, `updatedAt`, `key`, and `version`.

## Pagination

The default ordering supports cursor pagination using an opaque page token. Custom sorts use the backend's offset continuation path.

```dart
final request = QueryRequest(
  collectionCode: 'products',
  limit: 25,
);

final firstPage = await database.query.execute(request);

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

`QueryPage` exposes `collectionCode`, `items`, `hasMore`, `nextPageToken`, and `nextOffset`. The maximum page size is 100 documents.

## Batch Writes

Batch writes execute multiple document mutations atomically. The backend commits all operations together or rolls back the transaction if any operation fails.

```dart
final result = await database.documents.batchWrite(
  collectionCode: 'products',
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

print(result.collectionCode);
```

Batch limitations:

- Maximum 500 operations.
- Maximum aggregate JSON payload of 1 MiB.
- A document can only be targeted once per batch.
- Each update and delete requires an expected version.
- Results are returned only after transaction commit.

## Security and Project Isolation

- `ProjectId` defines the database ownership and isolation boundary.
- Applications registered in the same Project share Project Database collections.
- Application identity authenticates the calling Application.
- User identity identifies the authenticated end user.
- Collection security policies determine permitted reads, queries, creates, updates, and deletes.
- A policy must be saved, validated, and published before it grants SDK access.
- Collection creation does not imply access; all operations are checked by the backend.
- Social, Chat, Media, Storage, and other platform services retain their own service-owned data models and do not duplicate their records in the generic Database.

The SDK never accepts a Collection GUID. It sends the stable collection code, and the backend resolves the internal Collection identifier using the authenticated Project context.

## Error Handling

Database operations can fail because of authentication, authorization, validation, concurrency conflicts, or network errors.

```dart
try {
  final document = await database.documents.get(
    collectionCode: 'products',
    documentId: documentId,
  );

  print(document.data);
} catch (error) {
  print('Database operation failed: $error');
}
```

## Related Packages

- `mebabl_core` — Core SDK infrastructure and Application authentication.
- `mebabl_auth` — User authentication services.
- `mebabl_database` — Project-scoped Database services.

## Repository

[https://github.com/aliMerdan110/Mebabl.Sdk](https://github.com/aliMerdan110/Mebabl.Sdk)

## License

This package is released under the MIT License.
