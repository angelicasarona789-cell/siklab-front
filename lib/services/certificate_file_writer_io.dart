import 'dart:io';
import 'dart:typed_data';

Future<void> writeCertificateFile(String path, Uint8List bytes) async {
  final file = File(path);
  await file.writeAsBytes(bytes, flush: true);

  if (!await file.exists() || await file.length() != bytes.length) {
    throw FileSystemException('The certificate was not fully saved.', path);
  }
}
