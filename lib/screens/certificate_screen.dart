import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import '../services/certificate_file_writer.dart';
import '../services/certificate_pdf.dart';
import '../services/certificate_service.dart';
import '../theme/app_theme.dart';

/// Shows the Certificate of Completion and lets the user download it as a PDF.
class CertificateScreen extends StatefulWidget {
  /// null = overall certificate; otherwise a single language (e.g. "Java").
  final String? language;
  const CertificateScreen({super.key, this.language});

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  CertificateInfo? _info;
  Uint8List? _bytes;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final info =
        await CertificateService.getCertificate(language: widget.language);
    final bytes = info == null ? null : await buildCertificatePdf(info);
    if (!mounted) return;
    setState(() {
      _info = info;
      _bytes = bytes;
      _loading = false;
    });
  }

  String get _fileName {
    final lang = widget.language;
    final prefix = lang == null
        ? 'Siklab_Certificate'
        : 'Siklab_${lang.replaceAll('#', 'Sharp')}_Certificate';
    return '${prefix}_${_info!.certificateId}.pdf';
  }

  void _toast(
    String message, {
    bool error = false,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: GoogleFonts.spaceGrotesk(fontSize: 13)),
      backgroundColor: error ? SiklabColors.error : null,
      duration: duration,
    ));
  }

  Future<void> _download() async {
    final bytes = _bytes;
    if (bytes == null || _saving) return;
    setState(() => _saving = true);
    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save your certificate',
        fileName: _fileName,
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        bytes: bytes,
      );
      if (!mounted) return;
      // null = the user closed the save dialog without saving.
      if (path == null) return;

      // file_picker's Windows save dialog selects a destination but does not
      // write the provided bytes there.
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
        await writeCertificateFile(path, bytes);
      }
      if (mounted) {
        _toast(
          'Certificate saved to $path',
          duration: const Duration(seconds: 6),
        );
      }
    } catch (e) {
      if (mounted) _toast('Could not save the certificate: $e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _print() async {
    final bytes = _bytes;
    if (bytes == null) return;
    try {
      await Printing.layoutPdf(
        name: _fileName,
        format: certificatePageFormat,
        onLayout: (_) async => bytes,
      );
    } catch (e) {
      if (mounted) _toast('Could not open the print dialog: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.clBg,
      appBar: AppBar(
        backgroundColor: context.clBgCard,
        foregroundColor: context.clTextPrimary,
        elevation: 0,
        title: Text(
            widget.language == null
                ? 'Certificate of Completion'
                : '${widget.language} Certificate',
            style: GoogleFonts.spaceGrotesk(
                color: context.clTextPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700)),
      ),
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_info == null || _bytes == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Finish all modules and practice questions to unlock your certificate.',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
                color: context.clTextSecondary, fontSize: 14),
          ),
        ),
      );
    }

    final bytes = _bytes!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Text(
            _info!.practiceLevel == null
                ? 'A timed performance level is available after every practice question has a recorded completion time.'
                : 'PERFORMANCE LEVEL  •  ${_info!.practiceLevel!.toUpperCase()}',
            textAlign: TextAlign.center,
            style: GoogleFonts.sourceCodePro(
              color: _info!.practiceLevel == null
                  ? context.clTextSecondary
                  : SiklabColors.cyan,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: PdfPreview(
            build: (_) async => bytes,
            initialPageFormat: certificatePageFormat,
            pdfFileName: _fileName,
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
            allowSharing: true,
            allowPrinting: true,
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Row(children: [
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onTap: _download,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [SiklabColors.cyan, SiklabColors.cyanDark]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.black),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.download_rounded,
                                    color: Colors.black, size: 20),
                                const SizedBox(width: 8),
                                Text('DOWNLOAD PDF',
                                    style: GoogleFonts.spaceGrotesk(
                                        color: Colors.black,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8)),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: _print,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: context.clBgElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.clBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.print_outlined,
                            color: context.clTextPrimary, size: 20),
                        const SizedBox(width: 8),
                        Text('PRINT',
                            style: GoogleFonts.spaceGrotesk(
                                color: context.clTextPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8)),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}
