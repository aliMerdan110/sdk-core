# mebabl_storage

Binary file storage SDK for Mebabl applications.

## Features

- Upload files
- Get file URLs
- Download files
- Delete files
- Public/private files
- Application-isolated storage

## Usage

```dart
import 'dart:typed_data';

import 'package:mebabl_core/mebabl_core.dart';
import 'package:mebabl_storage/mebabl_storage.dart';

final core = await MebablCore.initialize();

final storage = MebablStorageService(
  core: core,
);

final file = await storage.upload(
  bytes: Uint8List.fromList([1, 2, 3]),
  fileName: 'example.bin',
  contentType: 'application/octet-stream',
);

final url = await storage.getUrl(file.id);

final bytes = await storage.download(file.id);

await storage.delete(file.id);