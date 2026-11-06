// lib/services/certificate_pdf.dart
//
// Draws the Certificate of Completion. The layout follows the supplied
// design (1536 x 1024 reference image): coordinates below are written in
// that image's pixel space and scaled down by [_k] when drawn.
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'certificate_service.dart';

const double _k = 0.5; // design px → PDF points
const double _designW = 1536;
const double _designH = 1024;
const double _pageW = _designW * _k; // 768
const double _pageH = _designH * _k; // 512

const String _instructorSignatureAsset =
    'assets/certificate/instructor_signature.png';

const List<String> _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String _formatDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

// ── Palette (sampled from the reference design) ─────────────────────────────
final PdfColor _navy = PdfColor.fromHex('#12305F');
final PdfColor _ink = PdfColor.fromHex('#1B2F5B');
final PdfColor _band = PdfColor.fromHex('#4A86D0');
final PdfColor _bandLight = PdfColor.fromHex('#6FA0DE');
final PdfColor _corner = PdfColor.fromHex('#1E3C72');
final PdfColor _gold = PdfColor.fromHex('#F4B63A');
final PdfColor _paper = PdfColor.fromHex('#FCFDFF');
final PdfColor _grey = PdfColor.fromHex('#5A6B85');

/// Page format used for the certificate (3:2 like the design).
const PdfPageFormat certificatePageFormat = PdfPageFormat(_pageW, _pageH);

// ── Small drawing helper: design-space (y down) → PDF-space (y up) ──────────
class _Pen {
  final PdfGraphics g;
  final double k;
  final double h;
  _Pen(this.g, this.k, this.h);

  double x(double v) => v * k;
  double y(double v) => h - v * k;

  void fill(PdfColor c) => g.setFillColor(c);

  void stroke(PdfColor c, double w) {
    g.setStrokeColor(c);
    g.setLineWidth(w * k);
    g.setLineCap(PdfLineCap.round);
    g.setLineJoin(PdfLineJoin.round);
  }

  void move(double a, double b) => g.moveTo(x(a), y(b));
  void line(double a, double b) => g.lineTo(x(a), y(b));
  void curve(double a, double b, double c, double d, double e, double f) =>
      g.curveTo(x(a), y(b), x(c), y(d), x(e), y(f));

  void poly(List<List<double>> pts) {
    move(pts.first[0], pts.first[1]);
    for (final p in pts.skip(1)) {
      line(p[0], p[1]);
    }
    g.closePath();
  }

  void circle(double cx, double cy, double r) =>
      g.drawEllipse(x(cx), y(cy), r * k, r * k);

  void ellipse(double cx, double cy, double rx, double ry) =>
      g.drawEllipse(x(cx), y(cy), rx * k, ry * k);

  void rrect(double l, double t, double w, double hh, double r) =>
      g.drawRRect(x(l), y(t + hh), w * k, hh * k, r * k, r * k);

  void fillIt() => g.fillPath();
  void strokeIt() => g.strokePath();
}

// ── Page decorations ─────────────────────────────────────────────────────────

void _paintPage(PdfGraphics g, PdfPoint size) {
  final p = _Pen(g, _k, _pageH);

  // Paper
  p.fill(_paper);
  g.drawRect(0, 0, _pageW, _pageH);
  g.fillPath();

  // Double border
  p.stroke(_navy, 3);
  g.drawRect(p.x(42), p.y(985), (1495 - 42) * _k, (985 - 35) * _k);
  g.strokePath();
  p.stroke(_navy, 1.5);
  g.drawRect(p.x(52), p.y(975), (1485 - 52) * _k, (975 - 45) * _k);
  g.strokePath();

  // Corner bands (top-left, mirrored to bottom-right)
  List<List<double>> flip(List<List<double>> pts) =>
      pts.map((e) => [_designW - e[0], _designH - e[1]]).toList();

  final dark = [
    [0.0, 0.0],
    [172.0, 0.0],
    [0.0, 172.0],
  ];
  final band = [
    [188.0, 0.0],
    [252.0, 0.0],
    [0.0, 252.0],
    [0.0, 188.0],
  ];
  final thin = [
    [232.0, 58.0],
    [212.0, 58.0],
    [48.0, 208.0],
    [68.0, 208.0],
  ];

  p.fill(_band);
  p.poly(band);
  p.fillIt();
  p.poly(flip(band));
  p.fillIt();

  p.fill(_corner);
  p.poly(dark);
  p.fillIt();
  p.poly(flip(dark));
  p.fillIt();

  p.fill(_bandLight);
  p.poly(thin);
  p.fillIt();

  // "</>" header icon
  p.stroke(_navy, 2);
  p.move(512, 99);
  p.line(688, 99);
  p.strokeIt();
  p.move(846, 99);
  p.line(1022, 99);
  p.strokeIt();

  p.stroke(_navy, 6);
  p.move(750, 78);
  p.line(722, 99);
  p.line(750, 120);
  p.strokeIt();
  p.move(786, 78);
  p.line(814, 99);
  p.line(786, 120);
  p.strokeIt();
  p.move(779, 74);
  p.line(759, 126);
  p.strokeIt();

  // Name underline
  p.stroke(_navy, 2);
  p.move(268, 363);
  p.line(1270, 363);
  p.strokeIt();

  // Signature lines
  p.stroke(_navy, 1.5);
  p.move(193, 871);
  p.line(553, 871);
  p.strokeIt();
  p.move(982, 871);
  p.line(1338, 871);
  p.strokeIt();

  _paintSeal(p);
  _paintLaurel(p, mirror: false);
  _paintLaurel(p, mirror: true);
}

void _paintSeal(
  _Pen p, {
  double cx = 768,
  double cy = 840,
  PdfColor? outer,
  PdfColor? disc,
  PdfColor? ribbon,
}) {
  final outerC = outer ?? _gold;
  final discC = disc ?? _navy;
  final ribbonC = ribbon ?? _navy;
  final ox = cx - 768, oy = cy - 840;

  List<List<double>> shift(List<List<double>> pts) =>
      pts.map((e) => [e[0] + ox, e[1] + oy]).toList();

  // Ribbon tails
  p.fill(ribbonC);
  p.poly(shift([
    [732, 874],
    [776, 880],
    [764, 944],
    [745, 925],
    [716, 938],
  ]));
  p.fillIt();
  p.poly(shift([
    [804, 874],
    [760, 880],
    [772, 944],
    [791, 925],
    [820, 938],
  ]));
  p.fillIt();

  // Scalloped rosette
  p.fill(outerC);
  for (var i = 0; i < 16; i++) {
    final a = i * 2 * math.pi / 16;
    p.circle(cx + 50 * math.cos(a), cy + 50 * math.sin(a), 14);
    p.fillIt();
  }
  p.circle(cx, cy, 54);
  p.fillIt();

  // Disc with thin white ring
  p.fill(discC);
  p.circle(cx, cy, 46);
  p.fillIt();
  p.stroke(PdfColors.white, 3);
  p.circle(cx, cy, 39);
  p.strokeIt();

  // White star
  p.fill(PdfColors.white);
  for (var i = 0; i < 10; i++) {
    final r = i.isEven ? 25.0 : 10.5;
    final a = -math.pi / 2 + i * math.pi / 5;
    final px = cx + r * math.cos(a);
    final py = cy + r * math.sin(a);
    if (i == 0) {
      p.move(px, py);
    } else {
      p.line(px, py);
    }
  }
  p.g.closePath();
  p.fillIt();
}

void _paintLeaf(_Pen p, double x, double y, double a, double len, double wid) {
  double rx(double lx, double ly) => x + lx * math.cos(a) - ly * math.sin(a);
  double ry(double lx, double ly) => y + lx * math.sin(a) + ly * math.cos(a);
  p.move(rx(0, 0), ry(0, 0));
  p.curve(rx(len * .3, wid), ry(len * .3, wid), rx(len * .8, wid * .8),
      ry(len * .8, wid * .8), rx(len, 0), ry(len, 0));
  p.curve(rx(len * .8, -wid * .8), ry(len * .8, -wid * .8), rx(len * .3, -wid),
      ry(len * .3, -wid), rx(0, 0), ry(0, 0));
  p.g.closePath();
  p.fillIt();
}

void _paintLaurel(
  _Pen p, {
  required bool mirror,
  double dx = 0,
  double dy = 0,
  PdfColor? color,
}) {
  final c = color ?? _navy;
  double sx(double v) => (mirror ? _designW - v : v) + dx;

  // Stem (left branch geometry, mirrored for the right one)
  p.stroke(c, 2.5);
  for (var i = 0; i <= 20; i++) {
    final t = i / 20;
    final x = 672 - 24 * t - 18 * math.sin(math.pi * t);
    final y = 918 - 118 * t + dy;
    if (i == 0) {
      p.move(sx(x), y);
    } else {
      p.line(sx(x), y);
    }
  }
  p.strokeIt();

  // Leaves on both sides of the stem
  p.fill(c);
  const leaves = 9;
  for (var i = 0; i < leaves; i++) {
    final t = 0.05 + i * (0.9 / (leaves - 1));
    final x = 672 - 24 * t - 18 * math.sin(math.pi * t);
    final y = 918 - 118 * t + dy;
    final ddx = -24 - 18 * math.pi * math.cos(math.pi * t);
    const ddy = -118.0;
    final a = math.atan2(ddy, ddx);
    for (final side in [-0.75, 0.75]) {
      final ang = a + side;
      _paintLeaf(p, sx(x), y, mirror ? math.pi - ang : ang, 26, 8);
    }
  }
}

// ── Language logos (simple vector marks drawn in a 100 x 100 box) ───────────

const double _logoSize = 64;

pw.Widget _logoBox(void Function(_Pen p) draw, {pw.Widget? overlay}) {
  return pw.SizedBox(
    width: _logoSize,
    height: _logoSize,
    child: pw.Stack(children: [
      pw.CustomPaint(
        size: const PdfPoint(_logoSize, _logoSize),
        painter: (PdfGraphics g, PdfPoint size) =>
            draw(_Pen(g, _logoSize / 100, _logoSize)),
      ),
      if (overlay != null) overlay,
    ]),
  );
}

pw.Widget _logoFor(String name) {
  switch (name.toLowerCase()) {
    case 'java':
      return _logoBox((p) {
        final red = PdfColor.fromHex('#E8412E');
        final blue = PdfColor.fromHex('#2A74B8');
        p.stroke(red, 6);
        p.move(50, 6);
        p.curve(36, 20, 64, 26, 50, 44);
        p.strokeIt();
        p.move(67, 18);
        p.curve(57, 28, 75, 32, 65, 44);
        p.strokeIt();
        p.stroke(blue, 5.5);
        p.move(26, 58);
        p.line(66, 58);
        p.strokeIt();
        p.move(32, 69);
        p.line(62, 69);
        p.strokeIt();
        p.move(38, 80);
        p.line(58, 80);
        p.strokeIt();
        p.move(68, 60);
        p.curve(90, 58, 90, 78, 64, 76);
        p.strokeIt();
        p.stroke(blue, 3.5);
        p.ellipse(48, 91, 36, 5);
        p.strokeIt();
      });
    case 'c#':
      return _logoBox(
        (p) {
          p.fill(PdfColor.fromHex('#1F6FB5'));
          for (var i = 0; i < 6; i++) {
            final a = -math.pi / 2 + i * math.pi / 3;
            final px = 50 + 46 * math.cos(a);
            final py = 50 + 46 * math.sin(a);
            if (i == 0) {
              p.move(px, py);
            } else {
              p.line(px, py);
            }
          }
          p.g.closePath();
          p.fillIt();
        },
        overlay: pw.Center(
          child: pw.Text('C#',
              style: pw.TextStyle(
                  font: pw.Font.helveticaBold(),
                  fontSize: 24,
                  color: PdfColors.white)),
        ),
      );
    case 'javascript':
      return _logoBox(
        (p) {
          p.fill(PdfColor.fromHex('#F5C518'));
          p.poly([
            [10, 6],
            [90, 6],
            [83, 80],
            [50, 94],
            [17, 80],
          ]);
          p.fillIt();
        },
        overlay: pw.Positioned(
          right: 11,
          bottom: 14,
          child: pw.Text('JS',
              style: pw.TextStyle(
                  font: pw.Font.helveticaBold(),
                  fontSize: 22,
                  color: PdfColor.fromHex('#3A3A3A'))),
        ),
      );
    case 'python':
      return _logoBox((p) {
        p.fill(PdfColor.fromHex('#3776AB'));
        p.rrect(10, 8, 52, 52, 18);
        p.fillIt();
        p.fill(PdfColor.fromHex('#FFD43B'));
        p.rrect(38, 40, 52, 52, 18);
        p.fillIt();
        p.fill(PdfColors.white);
        p.circle(28, 24, 4.5);
        p.fillIt();
        p.circle(72, 76, 4.5);
        p.fillIt();
      });
    case 'sql':
      return _logoBox((p) {
        final blue = PdfColor.fromHex('#2F7FC1');
        p.fill(blue);
        p.move(20, 24);
        p.line(20, 76);
        p.curve(20, 92, 80, 92, 80, 76);
        p.line(80, 24);
        p.g.closePath();
        p.fillIt();
        p.fill(PdfColor.fromHex('#F29111'));
        p.ellipse(50, 24, 30, 11);
        p.fillIt();
        p.stroke(PdfColors.white, 2.5);
        p.move(20, 42);
        p.curve(20, 54, 80, 54, 80, 42);
        p.strokeIt();
        p.move(20, 60);
        p.curve(20, 72, 80, 72, 80, 60);
        p.strokeIt();
      });
    default:
      final initials = name.isEmpty
          ? '?'
          : name.substring(0, math.min(2, name.length)).toUpperCase();
      return _logoBox(
        (p) {
          p.fill(_navy);
          p.rrect(10, 10, 80, 80, 16);
          p.fillIt();
        },
        overlay: pw.Center(
          child: pw.Text(initials,
              style: pw.TextStyle(
                  font: pw.Font.helveticaBold(),
                  fontSize: 22,
                  color: PdfColors.white)),
        ),
      );
  }
}

// ── Text helpers ─────────────────────────────────────────────────────────────

/// Full-width, horizontally centred text whose vertical centre is [centerY]
/// (PDF points from the top of the page).
pw.Widget _centered(
  String text,
  double centerY,
  pw.TextStyle style, {
  double lines = 1,
  double lineSpacing = 0,
}) {
  final boxH = (style.fontSize ?? 12) * 1.2 * lines + lineSpacing * (lines - 1);
  return pw.Positioned(
    left: 0,
    right: 0,
    top: centerY - boxH / 2,
    child: pw.Text(text, textAlign: pw.TextAlign.center, style: style),
  );
}

/// Text centred on horizontal position [cx] inside a box [width] wide.
pw.Widget _centeredAt(
  String text,
  double cx,
  double centerY,
  double width,
  pw.TextStyle style, {
  double lines = 1,
  double lineSpacing = 0,
}) {
  final boxH = (style.fontSize ?? 12) * 1.2 * lines + lineSpacing * (lines - 1);
  return pw.Positioned(
    left: cx - width / 2,
    top: centerY - boxH / 2,
    child: pw.SizedBox(
      width: width,
      child: pw.Text(text, textAlign: pw.TextAlign.center, style: style),
    ),
  );
}

Future<pw.MemoryImage> _loadInstructorSignature() async {
  final data = await rootBundle.load(_instructorSignatureAsset);
  return pw.MemoryImage(data.buffer.asUint8List());
}

/// Builds the Certificate of Completion PDF.
Future<Uint8List> buildCertificatePdf(CertificateInfo info) async {
  // Single-language certificates have their own themed designs.
  if (info.language != null) return _buildLanguageCertificate(info);

  final doc = pw.Document(
    title: 'Siklab Certificate of Completion',
    author: 'Siklab',
  );

  final regular = pw.Font.helvetica();
  final bold = pw.Font.helveticaBold();
  final instructorSignature = await _loadInstructorSignature();

  // Languages shown in the design's order, then any others.
  const preferred = ['Java', 'C#', 'JavaScript', 'Python', 'SQL'];
  final langs = <String>[
    ...preferred.where(info.languages.contains),
    ...info.languages.where((l) => !preferred.contains(l)),
  ];

  // Longer names get a smaller font so they always fit on one line.
  final nameLen = info.recipientName.length;
  final nameSize = nameLen <= 14 ? 42.0 : math.max(20.0, 42.0 * 14 / nameLen);

  final children = <pw.Widget>[
    pw.CustomPaint(
      size: const PdfPoint(_pageW, _pageH),
      painter: _paintPage,
    ),

    // Title block
    _centered(
      'CERTIFICATE OF COMPLETION',
      84,
      pw.TextStyle(font: bold, fontSize: 32, color: _navy),
    ),
    _centered(
      'THIS CERTIFIES THAT',
      119,
      pw.TextStyle(
          font: regular, fontSize: 12, letterSpacing: 3.5, color: _ink),
    ),
    _centered(
      info.recipientName,
      156,
      pw.TextStyle(font: bold, fontSize: nameSize, color: _navy),
    ),
    _centered(
      'has successfully completed the programming lesson app,\n'
      'covering the following programming languages:',
      212,
      pw.TextStyle(
          font: regular,
          fontSize: 14,
          letterSpacing: 0.6,
          lineSpacing: 6,
          color: _ink),
      lines: 2,
      lineSpacing: 6,
    ),
  ];

  if (info.practiceLevel != null) {
    children.add(_centered(
      'PERFORMANCE LEVEL: ${info.practiceLevel}',
      375,
      pw.TextStyle(font: bold, fontSize: 10, color: _navy),
    ));
  }

  // Language logos + labels, evenly spread between the design's end points.
  const firstX = 308.0 * _k, lastX = 1222.0 * _k;
  for (var i = 0; i < langs.length; i++) {
    final cx = langs.length == 1
        ? _pageW / 2
        : firstX + i * (lastX - firstX) / (langs.length - 1);
    children.add(pw.Positioned(
      left: cx - _logoSize / 2,
      top: 242,
      child: _logoFor(langs[i]),
    ));
    children.add(_centeredAt(
      langs[i],
      cx,
      321,
      120,
      pw.TextStyle(font: regular, fontSize: 13, color: _ink),
    ));
  }

  children.addAll([
    _centered(
      'This certificate is awarded for demonstrating dedication,\n'
      'progress, and completion of the programming lessons.',
      351,
      pw.TextStyle(
          font: regular,
          fontSize: 11.5,
          letterSpacing: 1.2,
          lineSpacing: 3.5,
          color: _ink),
      lines: 2,
      lineSpacing: 3.5,
    ),

    // Date (left)
    _centeredAt(
      _formatDate(info.issuedOn),
      373 * _k,
      425,
      200,
      pw.TextStyle(font: regular, fontSize: 13, color: _ink),
    ),
    _centeredAt(
      'DATE OF COMPLETION',
      373 * _k,
      447.5,
      200,
      pw.TextStyle(
          font: regular, fontSize: 8, letterSpacing: 2.2, color: _navy),
    ),

    // Instructor (right)
    pw.Positioned(
      left: 1160 * _k - 35,
      top: 382,
      child: pw.SizedBox(
        width: 70,
        height: 48,
        child: pw.Image(instructorSignature, fit: pw.BoxFit.contain),
      ),
    ),
    _centeredAt(
      'CHRISTOPHER C. VILLAHERMOSA',
      1160 * _k,
      449,
      220,
      pw.TextStyle(font: bold, fontSize: 8, color: _navy),
    ),
    _centeredAt(
      'BSIT - DEAN/PROGRAM HEAD',
      1160 * _k,
      462,
      220,
      pw.TextStyle(
          font: regular, fontSize: 7, letterSpacing: 0.4, color: _navy),
    ),

    // Certificate ID (small, bottom centre)
    _centered(
      'Certificate ID: ${info.certificateId}',
      484,
      pw.TextStyle(font: regular, fontSize: 7, color: _grey),
    ),
  ]);

  doc.addPage(
    pw.Page(
      pageFormat: certificatePageFormat,
      margin: pw.EdgeInsets.zero,
      build: (context) => pw.SizedBox(
        width: _pageW,
        height: _pageH,
        child: pw.Stack(children: children),
      ),
    ),
  );

  return doc.save();
}

// ═════════════════════════════════════════════════════════════════════════════
// Per-language certificates (Java, Python, C#, JavaScript, SQL)
// Same 3:2 page; colour theme, logo and wording follow each language's design.
// ═════════════════════════════════════════════════════════════════════════════

class _LangTheme {
  final PdfColor title; // heading + name
  final PdfColor ink; // body text
  final PdfColor line; // thin rules
  final PdfColor corner; // dark corner triangles + outer border
  final PdfColor band; // diagonal stripe + inner border
  final PdfColor langName; // big coloured language name
  final PdfColor sealOuter; // scalloped rosette
  final PdfColor sealDisc;
  final PdfColor ribbon;
  final PdfColor laurel;
  final String? logoAsset; // null → vector hexagon (C#)
  final List<double> logoBox; // left, top, width, height (design px)
  _LangTheme({
    required this.title,
    required this.ink,
    required this.line,
    required this.corner,
    required this.band,
    required this.langName,
    required this.sealOuter,
    required this.sealDisc,
    required this.ribbon,
    required this.laurel,
    required this.logoAsset,
    required this.logoBox,
  });
}

_LangTheme _themeFor(String language) {
  PdfColor h(String hex) => PdfColor.fromHex(hex);
  switch (language.toLowerCase()) {
    case 'python':
      return _LangTheme(
        title: h('#0F2A5C'),
        ink: h('#1B2F5B'),
        line: h('#4A7DBA'),
        corner: h('#0E6B4E'),
        band: h('#1BA37A'),
        langName: h('#1E9E6B'),
        sealOuter: h('#1BA37A'),
        sealDisc: h('#12306A'),
        ribbon: h('#12306A'),
        laurel: h('#12306A'),
        logoAsset: 'assets/certificate/logo_python.png',
        logoBox: [96, 108, 264, 204],
      );
    case 'javascript':
      return _LangTheme(
        title: h('#0F2A5C'),
        ink: h('#1B2F5B'),
        line: h('#4A7DBA'),
        corner: h('#C98B0B'),
        band: h('#F2B81B'),
        langName: h('#E4A412'),
        sealOuter: h('#F2B81B'),
        sealDisc: h('#12306A'),
        ribbon: h('#12306A'),
        laurel: h('#12306A'),
        logoAsset: 'assets/certificate/logo_js.png',
        logoBox: [112, 112, 264, 214],
      );
    case 'sql':
      return _LangTheme(
        title: h('#0E2459'),
        ink: h('#1B2F5B'),
        line: h('#4A7DBA'),
        corner: h('#2A1A6B'),
        band: h('#6B4BC4'),
        langName: h('#3F2A94'),
        sealOuter: h('#5B3FB5'),
        sealDisc: h('#1B1450'),
        ribbon: h('#3A2490'),
        laurel: h('#2B1B6E'),
        logoAsset: 'assets/certificate/logo_mysql.png',
        logoBox: [96, 96, 328, 200],
      );
    case 'c#':
      return _LangTheme(
        title: h('#0F2A5C'),
        ink: h('#1B2F5B'),
        line: h('#3B73C4'),
        corner: h('#12306A'),
        band: h('#3F7FD0'),
        langName: h('#1E6FC0'),
        sealOuter: h('#12306A'),
        sealDisc: h('#12306A'),
        ribbon: h('#12306A'),
        laurel: h('#12306A'),
        logoAsset: null,
        logoBox: [112, 130, 200, 220],
      );
    case 'java':
    default:
      return _LangTheme(
        title: h('#0F2A5C'),
        ink: h('#1B2F5B'),
        line: h('#3B73C4'),
        corner: h('#12306A'),
        band: h('#3F7FD0'),
        langName: h('#1565C0'),
        sealOuter: h('#12306A'),
        sealDisc: h('#12306A'),
        ribbon: h('#12306A'),
        laurel: h('#12306A'),
        logoAsset: 'assets/certificate/logo_java.png',
        logoBox: [118, 62, 182, 306],
      );
  }
}

/// The SQL course is certified as MySQL (matches the supplied design).
String _displayName(String language) => language == 'SQL' ? 'MySQL' : language;

/// Border with concave notches at the top-right and bottom-left corners.
void _notchedBorder(_Pen p, double x1, double y1, double x2, double y2,
    double r, PdfColor c, double w) {
  const m = 0.5523;
  p.stroke(c, w);
  p.move(x1, y1);
  p.line(x2 - r, y1);
  p.curve(x2 - r, y1 + m * r, x2 - m * r, y1 + r, x2, y1 + r);
  p.line(x2, y2);
  p.line(x1 + r, y2);
  p.curve(x1 + r, y2 - m * r, x1 + m * r, y2 - r, x1, y2 - r);
  p.line(x1, y1);
  p.g.closePath();
  p.strokeIt();
}

void _paintLanguagePage(PdfGraphics g, _LangTheme t) {
  final p = _Pen(g, _k, _pageH);

  // Paper
  p.fill(_paper);
  g.drawRect(0, 0, _pageW, _pageH);
  g.fillPath();

  // Double border
  _notchedBorder(p, 10, 14, 1524, 1010, 26, t.corner, 5);
  _notchedBorder(p, 26, 30, 1508, 994, 18, t.band, 2.5);

  // Corner ribbons (top-left, mirrored to bottom-right)
  List<List<double>> flip(List<List<double>> pts) =>
      pts.map((e) => [_designW - e[0], _designH - e[1]]).toList();
  final dark = [
    [0.0, 0.0],
    [172.0, 0.0],
    [0.0, 172.0],
  ];
  final stripe = [
    [184.0, 0.0],
    [236.0, 0.0],
    [0.0, 236.0],
    [0.0, 184.0],
  ];
  p.fill(t.band);
  p.poly(stripe);
  p.fillIt();
  p.poly(flip(stripe));
  p.fillIt();
  p.fill(t.corner);
  p.poly(dark);
  p.fillIt();
  p.poly(flip(dark));
  p.fillIt();

  // "This certifies that" side rules
  p.stroke(t.line, 2);
  p.move(487, 266);
  p.line(620, 266);
  p.strokeIt();
  p.move(1045, 266);
  p.line(1185, 266);
  p.strokeIt();

  // Name underline
  p.stroke(t.line, 2.5);
  p.move(290, 423);
  p.line(1320, 423);
  p.strokeIt();

  // Date + instructor lines
  p.stroke(t.line, 2);
  p.move(150, 855);
  p.line(548, 855);
  p.strokeIt();
  p.move(1015, 857);
  p.line(1378, 857);
  p.strokeIt();

  _paintSeal(p,
      cx: 785, cy: 825, outer: t.sealOuter, disc: t.sealDisc, ribbon: t.ribbon);
  _paintLaurel(p, mirror: false, dx: 17, dy: -15, color: t.laurel);
  _paintLaurel(p, mirror: true, dx: 17, dy: -15, color: t.laurel);
}

/// C# has no supplied logo, so it gets a blue hexagon mark in the C++ style.
void _paintHexLogo(PdfGraphics g) {
  final p = _Pen(g, _k, _pageH);
  const cx = 212.0, cy = 240.0, r = 112.0;
  p.fill(PdfColor.fromHex('#2F7DCB'));
  for (var i = 0; i < 6; i++) {
    final a = -math.pi / 2 + i * math.pi / 3;
    final px = cx + r * math.cos(a);
    final py = cy + r * math.sin(a);
    if (i == 0) {
      p.move(px, py);
    } else {
      p.line(px, py);
    }
  }
  p.g.closePath();
  p.fillIt();
  // darker lower-right half for a two-tone look
  p.fill(PdfColor.fromHex('#1D5DAA'));
  p.poly([
    [cx, cy],
    [cx + r * math.cos(-math.pi / 6), cy + r * math.sin(-math.pi / 6)],
    [cx + r * math.cos(math.pi / 6), cy + r * math.sin(math.pi / 6)],
    [cx, cy + r],
  ]);
  p.fillIt();
}

Future<Uint8List> _buildLanguageCertificate(CertificateInfo info) async {
  final language = info.language!;
  final t = _themeFor(language);
  final shown = _displayName(language);
  final instructorSignature = await _loadInstructorSignature();

  final doc = pw.Document(
    title: 'Siklab $shown Certificate of Completion',
    author: 'Siklab',
  );
  final regular = pw.Font.helvetica();
  final bold = pw.Font.helveticaBold();

  pw.MemoryImage? logo;
  if (t.logoAsset != null) {
    try {
      final data = await rootBundle.load(t.logoAsset!);
      logo = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      logo = null; // falls back to the language name only
    }
  }

  final nameLen = info.recipientName.length;
  final nameSize = nameLen <= 14 ? 46.0 : math.max(22.0, 46.0 * 14 / nameLen);

  const k = _k;
  final children = <pw.Widget>[
    pw.CustomPaint(
      size: const PdfPoint(_pageW, _pageH),
      painter: (g, size) {
        _paintLanguagePage(g, t);
        if (t.logoAsset == null) _paintHexLogo(g);
      },
    ),
  ];

  // Logo
  if (logo != null) {
    children.add(pw.Positioned(
      left: t.logoBox[0] * k,
      top: t.logoBox[1] * k,
      child: pw.Image(logo,
          width: t.logoBox[2] * k,
          height: t.logoBox[3] * k,
          fit: pw.BoxFit.contain),
    ));
  } else if (t.logoAsset == null) {
    children.add(_centeredAt(
      'C#',
      212 * k,
      240 * k,
      160,
      pw.TextStyle(font: bold, fontSize: 46, color: PdfColors.white),
    ));
  }

  children.addAll([
    _centeredAt(
      'CERTIFICATE OF COMPLETION',
      868 * k,
      170 * k,
      640,
      pw.TextStyle(font: bold, fontSize: 34, color: t.title),
    ),
    _centeredAt(
      'This certifies that',
      831 * k,
      265 * k,
      260,
      pw.TextStyle(
          font: regular, fontSize: 14, letterSpacing: 2.5, color: t.ink),
    ),
    _centeredAt(
      info.recipientName,
      822 * k,
      352 * k,
      640,
      pw.TextStyle(font: bold, fontSize: nameSize, color: t.title),
    ),
    _centeredAt(
      'has successfully completed the programming lesson app,\n'
      'covering the following language:',
      805 * k,
      488.5 * k,
      560,
      pw.TextStyle(
          font: regular,
          fontSize: 14,
          letterSpacing: 0.6,
          lineSpacing: 5,
          color: t.ink),
      lines: 2,
      lineSpacing: 5,
    ),
    _centeredAt(
      shown,
      800 * k,
      572 * k,
      560,
      pw.TextStyle(font: bold, fontSize: 36, color: t.langName),
    ),
    _centeredAt(
      'and has demonstrated a solid understanding of\n'
      'the fundamentals, syntax, and core concepts of $shown.',
      805 * k,
      657.5 * k,
      560,
      pw.TextStyle(
          font: regular,
          fontSize: 13.5,
          letterSpacing: 0.6,
          lineSpacing: 5,
          color: t.ink),
      lines: 2,
      lineSpacing: 5,
    ),

    // Date (left)
    _centeredAt(
      _formatDate(info.issuedOn),
      350 * k,
      823 * k,
      230,
      pw.TextStyle(font: regular, fontSize: 14, color: t.title),
    ),
    _centeredAt(
      'DATE OF COMPLETION',
      350 * k,
      880 * k,
      230,
      pw.TextStyle(
          font: regular, fontSize: 8, letterSpacing: 2.2, color: t.title),
    ),

    // Program instructor (right)
    pw.Positioned(
      left: 1197 * k - 35,
      top: 377,
      child: pw.SizedBox(
        width: 70,
        height: 48,
        child: pw.Image(instructorSignature, fit: pw.BoxFit.contain),
      ),
    ),
    _centeredAt(
      'CHRISTOPHER C. VILLAHERMOSA',
      1197 * k,
      447,
      240,
      pw.TextStyle(font: bold, fontSize: 8, color: t.title),
    ),
    _centeredAt(
      'BSIT - DEAN/PROGRAM HEAD',
      1197 * k,
      462,
      240,
      pw.TextStyle(
          font: regular, fontSize: 7, letterSpacing: 0.4, color: t.title),
    ),

    // Certificate ID (small, bottom centre)
    _centeredAt(
      'Certificate ID: ${info.certificateId}',
      768 * k,
      972 * k,
      300,
      pw.TextStyle(font: regular, fontSize: 7, color: _grey),
    ),
  ]);

  if (info.practiceLevel != null) {
    children.add(_centeredAt(
      'Performance level: ${info.practiceLevel}',
      805 * k,
      728 * k,
      560,
      pw.TextStyle(font: bold, fontSize: 14, color: t.title),
    ));
  }

  doc.addPage(
    pw.Page(
      pageFormat: certificatePageFormat,
      margin: pw.EdgeInsets.zero,
      build: (context) => pw.SizedBox(
        width: _pageW,
        height: _pageH,
        child: pw.Stack(children: children),
      ),
    ),
  );

  return doc.save();
}
