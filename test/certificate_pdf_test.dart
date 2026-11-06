import 'package:flutter_test/flutter_test.dart';
import 'package:siklab/services/certificate_pdf.dart';
import 'package:siklab/services/certificate_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final certificate = CertificateInfo(
    recipientName: 'Test Student',
    issuedOn: DateTime(2026, 10, 30),
    certificateId: 'SKL-000001-20261030',
    languages: ['Java'],
    totalModules: 1,
    totalExercises: 1,
    practiceLevel: 'Intermediate',
  );

  test('builds the overall certificate with the instructor signature asset',
      () async {
    final pdf = await buildCertificatePdf(certificate);

    expect(String.fromCharCodes(pdf.take(4)), '%PDF');
  });

  test('builds a language certificate with the instructor signature asset',
      () async {
    final pdf = await buildCertificatePdf(
      CertificateInfo(
        recipientName: 'Test Student',
        issuedOn: DateTime(2026, 10, 30),
        certificateId: 'SKL-JAVA-000001-20261030',
        languages: ['Java'],
        totalModules: 1,
        totalExercises: 1,
        language: 'Java',
        practiceLevel: 'Beginner',
      ),
    );

    expect(String.fromCharCodes(pdf.take(4)), '%PDF');
  });
}
