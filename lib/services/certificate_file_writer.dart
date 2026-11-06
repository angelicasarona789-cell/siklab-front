import 'dart:typed_data';

import 'certificate_file_writer_stub.dart'
    if (dart.library.io) 'certificate_file_writer_io.dart' as implementation;

Future<void> writeCertificateFile(String path, Uint8List bytes) =>
    implementation.writeCertificateFile(path, bytes);
