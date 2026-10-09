import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/api_errors.dart';
import '../fees_api.dart';

/// Pay one fee online: choose a method → complete the checkout.
/// Pops `true` when the payment succeeded.
class PayOnlineSheet extends StatefulWidget {
  final String paymentId;
  final String amountLabel;
  final List<PayMethod> methods;

  const PayOnlineSheet({
    super.key,
    required this.paymentId,
    required this.amountLabel,
    required this.methods,
  });

  static Future<bool?> show(BuildContext context,
      {required String paymentId, required String amountLabel, required List<PayMethod> methods}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => PayOnlineSheet(paymentId: paymentId, amountLabel: amountLabel, methods: methods),
    );
  }

  @override
  State<PayOnlineSheet> createState() => _PayOnlineSheetState();
}

class _PayOnlineSheetState extends State<PayOnlineSheet> {
  static const _navy = Color(0xFF1B3B69);
  static const _green = Color(0xFF27AE60);

  Checkout? _checkout;
  bool _busy = false;
  String? _error;
  Timer? _poll;

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _start(PayMethod m) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final c = await FeesApi.start(widget.paymentId, m.key);
      setState(() => _checkout = c);
      if (c.redirectUrl != null && c.redirectUrl!.isNotEmpty) {
        await launchUrl(Uri.parse(c.redirectUrl!), mode: LaunchMode.externalApplication);
      }
      if (!c.testMode) _startPolling();
    } catch (e) {
      setState(() => _error = ApiErrors.message(e, fallback: 'Could not start the payment.'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Live gateways confirm via webhook — check the status every few seconds.
  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _refresh());
  }

  Future<void> _refresh() async {
    final c = _checkout;
    if (c == null) return;
    try {
      final updated = await FeesApi.status(c.id);
      if (!mounted) return;
      setState(() => _checkout = updated);
      if (updated.status != 'pending') _poll?.cancel();
    } catch (_) {
      // try again on the next tick
    }
  }

  Future<void> _mock(bool success) async {
    final c = _checkout;
    if (c == null) return;
    setState(() => _busy = true);
    try {
      final updated = await FeesApi.mockConfirm(c.id, success: success);
      if (mounted) setState(() => _checkout = updated);
    } catch (e) {
      if (mounted) setState(() => _error = ApiErrors.message(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Pay ${widget.amountLabel}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
            const SizedBox(height: 12),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFE53935), fontFamily: 'Poppins')),
              ),
            if (_checkout == null) ..._methodList() else ..._checkoutView(_checkout!),
          ],
        ),
      ),
    );
  }

  List<Widget> _methodList() {
    return [
      const Text('Choose how to pay',
          style: TextStyle(color: Color(0xFF8A94A6), fontFamily: 'Poppins')),
      const SizedBox(height: 8),
      ...widget.methods.map((m) => Card(
            child: ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined, color: _navy),
              title: Text(m.label, style: const TextStyle(fontFamily: 'Poppins')),
              trailing: _busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.chevron_right),
              onTap: _busy ? null : () => _start(m),
            ),
          )),
    ];
  }

  List<Widget> _checkoutView(Checkout c) {
    if (c.status == 'succeeded') {
      return [
        const Icon(Icons.check_circle, color: _green, size: 56),
        const SizedBox(height: 8),
        const Text('Payment successful',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white),
          child: const Text('Done'),
        ),
      ];
    }
    if (c.status == 'failed' || c.status == 'expired') {
      return [
        const Icon(Icons.cancel, color: Color(0xFFE53935), size: 56),
        const SizedBox(height: 8),
        Text(c.status == 'failed' ? 'Payment failed' : 'Payment session expired',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => setState(() => _checkout = null),
          child: const Text('Try again'),
        ),
      ];
    }
    return [
      if (c.testMode)
        Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEC610).withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text('TEST MODE — no real money will be charged.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
        ),
      Text(c.instructions, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Poppins')),
      const SizedBox(height: 16),
      if (c.testMode) ...[
        ElevatedButton(
          onPressed: _busy ? null : () => _mock(true),
          style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white),
          child: const Text('Confirm test payment'),
        ),
        TextButton(
          onPressed: _busy ? null : () => _mock(false),
          child: const Text('Simulate a failed payment'),
        ),
      ] else ...[
        const Center(child: CircularProgressIndicator()),
        const SizedBox(height: 8),
        const Text('Waiting for confirmation…',
            textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Poppins')),
        TextButton(onPressed: _refresh, child: const Text('I have paid — check now')),
      ],
    ];
  }
}
