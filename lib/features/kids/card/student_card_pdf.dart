import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'student_card_api.dart';
import 'student_card_style.dart';

/// Builds a print-ready PDF of a student card (vector QR and text, so it
/// stays sharp at any size):
///  - page 1: A4 with the card at actual ID-1 size and a dashed cut line,
///  - page 2: a page exactly the size of the card, for print shops.
class StudentCardPdf {
  StudentCardPdf._();

  static const double _mm = PdfPageFormat.mm;
  static final _navy = PdfColor.fromInt(StudentCardStyle.navy.toARGB32());
  static final _blue = PdfColor.fromInt(StudentCardStyle.blue.toARGB32());
  static final _yellow = PdfColor.fromInt(StudentCardStyle.yellow.toARGB32());
  static final _red = PdfColor.fromInt(StudentCardStyle.red.toARGB32());
  static final _photoBg = PdfColor.fromInt(StudentCardStyle.photoBg.toARGB32());
  static const _text = PdfColor.fromInt(0xFF344054);

  static Future<Uint8List> build(StudentCardData card) async {
    final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/Poppins-Regular.ttf'));
    final semiBold = pw.Font.ttf(await rootBundle.load('assets/fonts/Poppins-SemiBold.ttf'));
    final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Poppins-Bold.ttf'));
    final logo = pw.MemoryImage((await rootBundle.load(StudentCardStyle.logoAsset)).buffer.asUint8List());

    pw.ImageProvider? photo;
    if (card.image != null) {
      try {
        photo = await networkImage(card.image!);
      } catch (_) {
        photo = null; // falls back to the "affix photo" box
      }
    }

    final theme = pw.ThemeData.withFont(base: regular, bold: bold);
    final doc = pw.Document(title: 'SmartVan student card — ${card.fullname}', author: 'SmartVan', theme: theme);
    final face = _card(card, logo, photo, semiBold, bold);

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(18 * _mm),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text('SmartVan Student Card', style: pw.TextStyle(font: bold, fontSize: 16, color: _navy)),
          pw.SizedBox(height: 4),
          pw.Text(card.fullname, style: pw.TextStyle(font: semiBold, fontSize: 11, color: _text)),
          pw.SizedBox(height: 14 * _mm),
          // Dashed cut line 1.5 mm outside the card.
          pw.Container(
            padding: const pw.EdgeInsets.all(1.5 * _mm),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey500, width: 0.5, style: pw.BorderStyle.dashed),
            ),
            child: face,
          ),
          pw.SizedBox(height: 10 * _mm),
          pw.Text(
            'Print in colour at 100% / "Actual size" (do not "fit to page").\n'
            'Cut along the dashed line and laminate.'
            '${card.image == null ? '\nStick a passport-size photo in the photo box.' : ''}',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700, lineSpacing: 2),
          ),
        ],
      ),
    ));

    doc.addPage(pw.Page(
      pageFormat: const PdfPageFormat(StudentCardStyle.widthMm * _mm, StudentCardStyle.heightMm * _mm),
      margin: pw.EdgeInsets.zero,
      build: (_) => face,
    ));

    return doc.save();
  }

  static pw.Widget _card(StudentCardData card, pw.ImageProvider logo, pw.ImageProvider? photo, pw.Font semiBold, pw.Font bold) {
    return pw.Container(
      width: StudentCardStyle.widthMm * _mm,
      height: StudentCardStyle.heightMm * _mm,
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3 * _mm)),
        border: pw.Border.all(color: PdfColor.fromInt(0xFFD9DEEA), width: 0.25 * _mm),
      ),
      child: pw.ClipRRect(
        horizontalRadius: 3 * _mm,
        verticalRadius: 3 * _mm,
        child: pw.Column(children: [
          // Header
          pw.Container(
            height: 12 * _mm,
            padding: const pw.EdgeInsets.symmetric(horizontal: 3 * _mm),
            decoration: pw.BoxDecoration(gradient: pw.LinearGradient(colors: [_navy, _blue])),
            child: pw.Row(children: [
              pw.Container(
                width: 9 * _mm,
                height: 9 * _mm,
                padding: const pw.EdgeInsets.all(0.4 * _mm),
                decoration: const pw.BoxDecoration(color: PdfColors.white, shape: pw.BoxShape.circle),
                child: pw.Image(logo, fit: pw.BoxFit.contain),
              ),
              pw.SizedBox(width: 1.8 * _mm),
              pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('SmartVan', style: pw.TextStyle(font: bold, fontSize: 3.6 * _mm, color: PdfColors.white)),
                  pw.Text(StudentCardStyle.tagline, style: pw.TextStyle(font: semiBold, fontSize: 1.9 * _mm, color: _yellow)),
                ],
              ),
              pw.Spacer(),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 2 * _mm, vertical: 0.8 * _mm),
                decoration: pw.BoxDecoration(color: _yellow, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5 * _mm))),
                child: pw.Text('STUDENT CARD', style: pw.TextStyle(font: bold, fontSize: 1.9 * _mm, color: _navy, letterSpacing: 0.2 * _mm)),
              ),
            ]),
          ),
          // Body
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 3 * _mm, vertical: 2.2 * _mm),
              child: pw.Row(children: [
                _photo(photo, semiBold),
                pw.SizedBox(width: 2.5 * _mm),
                pw.Expanded(
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(card.fullname, maxLines: 2, style: pw.TextStyle(font: bold, fontSize: 3.4 * _mm, color: _navy)),
                      pw.SizedBox(height: 0.8 * _mm),
                      if (card.grade.isNotEmpty) _field('Grade', card.grade, bold),
                      if (card.vanNumber.isNotEmpty) _field('Van', card.vanNumber, bold),
                      if (card.schoolName.isNotEmpty) _field('School', card.schoolName, bold, maxLines: 2),
                    ],
                  ),
                ),
                pw.SizedBox(width: 2.5 * _mm),
                _qr(card.qrPayload),
              ]),
            ),
          ),
          // Footer
          pw.Container(
            height: 5 * _mm,
            color: _yellow,
            padding: const pw.EdgeInsets.symmetric(horizontal: 3 * _mm),
            child: pw.Row(children: [
              pw.Text(StudentCardStyle.url, style: pw.TextStyle(font: bold, fontSize: 2 * _mm, color: _navy, letterSpacing: 0.15 * _mm)),
              pw.Spacer(),
              pw.Text(StudentCardStyle.returnNote, style: pw.TextStyle(font: semiBold, fontSize: 1.6 * _mm, color: _navy)),
            ]),
          ),
        ]),
      ),
    );
  }

  static pw.Widget _photo(pw.ImageProvider? photo, pw.Font semiBold) {
    if (photo != null) {
      return pw.Container(
        width: 19 * _mm,
        height: 24 * _mm,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _navy, width: 0.5 * _mm),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2 * _mm)),
        ),
        child: pw.ClipRRect(
          horizontalRadius: 1.6 * _mm,
          verticalRadius: 1.6 * _mm,
          child: pw.Image(photo, fit: pw.BoxFit.cover),
        ),
      );
    }
    // "Affix photo here" box with a simple person drawing.
    return pw.Container(
      width: 19 * _mm,
      height: 24 * _mm,
      decoration: pw.BoxDecoration(
        color: _photoBg,
        border: pw.Border.all(color: _blue, width: 0.35 * _mm, style: pw.BorderStyle.dashed),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2 * _mm)),
      ),
      child: pw.Column(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
        pw.CustomPaint(
          size: const PdfPoint(10 * _mm, 10 * _mm),
          painter: (canvas, size) {
            canvas
              ..setFillColor(_blue)
              ..drawEllipse(size.x / 2, size.y * 0.66, size.x * 0.18, size.x * 0.18)
              ..fillPath()
              ..drawEllipse(size.x / 2, size.y * 0.2, size.x * 0.36, size.y * 0.2)
              ..fillPath();
          },
        ),
        pw.SizedBox(height: 0.6 * _mm),
        pw.Text('Affix photo\nhere',
            textAlign: pw.TextAlign.center, style: pw.TextStyle(font: semiBold, fontSize: 1.7 * _mm, color: _blue)),
      ]),
    );
  }

  static pw.Widget _field(String label, String value, pw.Font bold, {int maxLines = 1}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 0.5 * _mm),
      child: pw.RichText(
        maxLines: maxLines,
        text: pw.TextSpan(
          style: pw.TextStyle(fontSize: 2.2 * _mm, color: _text),
          children: [
            pw.TextSpan(text: '$label: ', style: pw.TextStyle(font: bold, color: _blue)),
            pw.TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  static pw.Widget _qr(String payload) {
    pw.Widget corner(pw.Alignment a, PdfColor color) => pw.Align(
          alignment: a,
          child: pw.Container(
            width: 4 * _mm,
            height: 4 * _mm,
            decoration: pw.BoxDecoration(
              border: pw.Border(
                top: a.y > 0 ? pw.BorderSide(color: color, width: 0.6 * _mm) : pw.BorderSide.none,
                bottom: a.y < 0 ? pw.BorderSide(color: color, width: 0.6 * _mm) : pw.BorderSide.none,
                left: a.x < 0 ? pw.BorderSide(color: color, width: 0.6 * _mm) : pw.BorderSide.none,
                right: a.x > 0 ? pw.BorderSide(color: color, width: 0.6 * _mm) : pw.BorderSide.none,
              ),
            ),
          ),
        );
    return pw.SizedBox(
      width: 24 * _mm,
      height: 24 * _mm,
      child: pw.Stack(children: [
        corner(pw.Alignment.topLeft, _yellow),
        corner(pw.Alignment.topRight, _red),
        corner(pw.Alignment.bottomLeft, _red),
        corner(pw.Alignment.bottomRight, _yellow),
        pw.Padding(
          padding: const pw.EdgeInsets.all(1.2 * _mm),
          child: pw.BarcodeWidget(
            barcode: pw.Barcode.qrCode(errorCorrectLevel: pw.BarcodeQRCorrectionLevel.medium),
            data: payload,
            color: _navy,
            drawText: false,
          ),
        ),
      ]),
    );
  }
}
