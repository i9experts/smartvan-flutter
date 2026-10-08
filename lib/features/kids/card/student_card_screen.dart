import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../../core/network/api_errors.dart';
import 'student_card_api.dart';
import 'student_card_pdf.dart';
import 'student_card_view.dart';

/// Parent: view a child's SmartVan student card and save/print it as PDF.
class StudentCardScreen extends StatefulWidget {
  final String kidId;
  final String kidName;
  const StudentCardScreen({super.key, required this.kidId, required this.kidName});

  @override
  State<StudentCardScreen> createState() => _StudentCardScreenState();
}

class _StudentCardScreenState extends State<StudentCardScreen> {
  static const _navy = Color(0xFF1B2B6B);
  late Future<StudentCardData> _future = StudentCardApi.load(widget.kidId);
  bool _busy = false;

  String _fileName(StudentCardData c) =>
      'SmartVan-Card-${c.fullname.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')}.pdf';

  Future<void> _download(StudentCardData card) async {
    setState(() => _busy = true);
    try {
      final bytes = await StudentCardPdf.build(card);
      // Opens the share sheet: Save to Files / Drive, WhatsApp, email…
      await Printing.sharePdf(bytes: bytes, filename: _fileName(card));
    } catch (e) {
      _snack(ApiErrors.message(e, fallback: 'Could not create the PDF. Please try again.'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _print(StudentCardData card) async {
    setState(() => _busy = true);
    try {
      await Printing.layoutPdf(name: _fileName(card), onLayout: (_) => StudentCardPdf.build(card));
    } catch (e) {
      _snack(ApiErrors.message(e, fallback: 'Could not open printing. Please try again.'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F3FF),
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: const Text('Student Card', style: TextStyle(fontFamily: 'Poppins', fontSize: 18)),
      ),
      body: FutureBuilder<StudentCardData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: _navy));
          }
          if (snap.hasError || !snap.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(ApiErrors.message(snap.error ?? 'error', fallback: 'Could not load the card.'),
                      textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Poppins')),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => setState(() => _future = StudentCardApi.load(widget.kidId)),
                    child: const Text('Try again'),
                  ),
                ]),
              ),
            );
          }
          final card = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 16, offset: Offset(0, 6))],
                ),
                child: StudentCardView(card: card),
              ),
              const SizedBox(height: 16),
              const Text(
                'The driver scans this card when your child gets on and off the van. '
                'Print it in colour at actual size, cut it out and laminate it.',
                style: TextStyle(color: Color(0xFF667085), fontFamily: 'Poppins', fontSize: 13),
              ),
              if (card.image == null) ...[
                const SizedBox(height: 8),
                const Text(
                  'No photo on file — stick a passport-size photo in the box after printing, '
                  'or add a photo in Edit.',
                  style: TextStyle(color: Color(0xFF667085), fontFamily: 'Poppins', fontSize: 13),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _busy ? null : () => _download(card),
                  icon: _busy
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.picture_as_pdf),
                  label: const Text('Download PDF', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _navy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _print(card),
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('Print', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _navy,
                    side: const BorderSide(color: _navy),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
