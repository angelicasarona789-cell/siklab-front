import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:siklab/services/certificate_file_writer.dart';

void main() {
  test('writes certificate bytes to the selected destination', () async {
    final directory =
        await Directory.systemTemp.createTemp('siklab-certificate-');
    addTearDown(() => directory.delete(recursive: true));

    final path = '${directory.path}${Platform.pathSeparator}certificate.pdf';
    final bytes = Uint8List.fromList([37, 80, 68, 70, 45, 49]);

    await writeCertificateFile(path, bytes);

    expect(await File(path).readAsBytes(), bytes);
  });
}
