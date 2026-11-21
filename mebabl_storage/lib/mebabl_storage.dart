/// Project-scoped Storage SDK for Mebabl Platform.
///
/// The package uses the configured Core Dio client and authentication
/// infrastructure. Runtime access is always decided by published Storage
/// Security Rules on the server.
library;

export 'src/models/storage_content_stream.dart';
export 'src/models/storage_object.dart';
export 'src/models/storage_object_page.dart';
export 'src/models/stored_file.dart';
export 'src/services/storage_service.dart';
