## 1.1.0

- Replaced public Collection GUID usage with stable Collection Codes.
- Removed manual Collection creation from the SDK. The backend materializes a collection on the first successful write.
- Moved document CRUD, query, and batch operations to the code-addressed API.
- Standardized document updates and deletes on ETag / If-Match optimistic concurrency.
- Updated collection catalog and query page models to return collectionCode without collection identifiers.
- Added tests for the code-first collection and query response contracts.

## 1.0.8



## 1.0.7


## 1.0.6

Updated database architecture to support project-scoped collections and documents.

Added cursor-based pagination with page tokens and next-page support.

Added atomic batch writes for creating, updating, and deleting documents.

Added optimistic concurrency support using document version numbers.

Improved query filtering, sorting, and pagination validation.

Enhanced JSON serialization and API response handling.

Improved input validation and error handling across database services.

Updated the SDK to align with Mebabl Platform Database V2.

Expanded test coverage for query models, pagination, and batch operations.

## 1.0.5



## 1.0.4

* Improved collection management with input validation.
* Improved document CRUD operations with input validation.
* Improved query filtering, sorting, pagination, and validation.
* Improved JSON serialization and response parsing.
* Improved security and application isolation handling.
* Added comprehensive SDK validation and test coverage.
* Removed unused `CollectionResponse` and `DocumentResponse` models.

## 1.0.0

* Initial release.
* Added collection management.
* Added document CRUD operations.
* Added database query support.
