import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/api_errors.dart';
import '../fees_api.dart';

/// Loads GET /fees/receipt/:paymentId and shows it, with WhatsApp sharing.
class ReceiptSheet extends StatefulWidget {
  final String paymentId;
  const ReceiptSheet({super.key, required this.paymentId});

  static Future<void> show(BuildContext context, String paymentId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ReceiptSheet(paymentId: paymentId),
    );
  }

  @override
  State<ReceiptSheet> createState() => _ReceiptSheetState();
}

class _ReceiptSheetState extends State<ReceiptSheet> {
  Map<String, dynamic>? _r;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await FeesApi.receipt(widget.paymentId);
      if (mounted) setState(() => _r = r);
    } catch (e) {
      if (mounted) setState(() => _error = ApiErrors.message(e, fallback: 'Could not load the receipt.'));
    }
  }

  static const _methodLabels = {
    'cash': 'Cash',
    'jazzcash': 'JazzCash',
    'easypaisa': 'Easypaisa',
    'raast': 'Raast',
    'bank_transfer': 'Bank transfer',
    'card': 'Card',
  };

  String _paidAt(dynamic v) {
    final d = DateTime.tryParse(v?.toString() ?? '');
    return d == null ? '—' : DateFormat('d MMM yyyy, h:mm a').format(d.toLocal());
  }

  String _month(dynamic v) {
    final d = DateTime.tryParse('${v ?? ''}-01');
    return d == null ? (v?.toString() ?? '—') : DateFormat('MMMM yyyy').format(d);
  }

  String _shareText(Map<String, dynamic> r) {
    return [
      '🧾 ${r['schoolName'] ?? 'SmartVan'} — Transport fee receipt',
      'Receipt #: ${r['receiptNumber'] ?? '—'}',
      'Student: ${r['studentName'] ?? '—'}',
      'Month: ${_month(r['month'])}',
      'Amount: ${r['currency'] ?? 'PKR'} ${r['amount']}',
      'Paid via: ${_methodLabels[r['paymentMethod']] ?? r['paymentMethod']}',
      'Date: ${_paidAt(r['paidAt'])}',
    ].join('\n');
  }

  Future<void> _share(Map<String, dynamic> r) async {
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(_shareText(r))}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final r = _r;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: _error != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, textAlign: TextAlign.center),
              )
            : r == null
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.receipt_long, color: Color(0xFF27AE60), size: 40),
                      const SizedBox(height: 6),
                      Text(r['schoolName']?.toString().isNotEmpty == true ? r['schoolName'] : 'Transport fee receipt',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                      Text('${r['currency'] ?? 'PKR'} ${r['amount']}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1B3B69), fontFamily: 'Poppins')),
                      const SizedBox(height: 12),
                      _row('Receipt #', r['receiptNumber']),
                      _row('Student', r['studentName']),
                      if ((r['grade'] ?? '').toString().isNotEmpty) _row('Grade', r['grade']),
                      _row('Month', _month(r['month'])),
                      _row('Paid via', _methodLabels[r['paymentMethod']] ?? r['paymentMethod']),
                      _row('Date', _paidAt(r['paidAt'])),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _share(r),
                        icon: const Icon(Icons.share),
                        label: const Text('Share on WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _row(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF8A94A6), fontFamily: 'Poppins')),
          const Spacer(),
          Flexible(
            child: Text(value?.toString() ?? '—',
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }
}
