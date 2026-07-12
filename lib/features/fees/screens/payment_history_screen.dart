import 'package:flutter/material.dart';
import '../../../core/network/api_service.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  List<dynamic> _payments = [];
  bool _isLoading = true;
  String _error = '';
  String _filterStatus = 'all';

  static const Color _navy = Color(0xFF1B2B6B);
  static const Color _yellow = Color(0xFFFFB800);

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() { _isLoading = true; _error = ''; });
    try {
      final response = await ApiService.get('/fees/parent-payments');
      if (response.statusCode == 200) {
        final data = response.data;
        setState(() {
          _payments = data is List ? data : (data['data'] ?? []);
        });
      }
    } catch (e) {
      setState(() => _error = 'Failed to load payment history');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(dynamic amount, String currency) {
    final symbols = {'PKR': 'Rs.', 'SAR': 'SAR', 'AED': 'AED', 'QAR': 'QAR', 'USD': '\$'};
    final symbol = symbols[currency] ?? currency;
    return '$symbol ${(amount ?? 0).toStringAsFixed(0)}';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '—';
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (_) { return '—'; }
  }

  String _formatMonth(String? month) {
    if (month == null) return '—';
    try {
      final parts = month.split('-');
      if (parts.length == 2) {
        final months = ['','January','February','March','April','May','June',
                        'July','August','September','October','November','December'];
        final m = int.tryParse(parts[1]) ?? 0;
        return '${months[m]} ${parts[0]}';
      }
    } catch (_) {}
    return month;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid': return const Color(0xFF27AE60);
      case 'pending': return const Color(0xFFFFB800);
      case 'overdue': return const Color(0xFFE74C3C);
      default: return const Color(0xFF8A94A6);
    }
  }

  Color _statusBgColor(String status) {
    switch (status) {
      case 'paid': return const Color(0xFF27AE60).withOpacity(0.08);
      case 'pending': return const Color(0xFFFFB800).withOpacity(0.08);
      case 'overdue': return const Color(0xFFE74C3C).withOpacity(0.08);
      default: return const Color(0xFF8A94A6).withOpacity(0.08);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'paid': return Icons.check_circle_outline;
      case 'pending': return Icons.schedule;
      case 'overdue': return Icons.warning_amber_outlined;
      default: return Icons.info_outline;
    }
  }

  String _serviceTypeLabel(String? type) {
    switch (type) {
      case 'pick_only': return 'Pick Only';
      case 'drop_only': return 'Drop Only';
      case 'both': return 'Pick & Drop';
      default: return 'Transport';
    }
  }

  String _paymentMethodLabel(String? method) {
    switch (method) {
      case 'cash': return 'Cash';
      case 'jazzcash': return 'JazzCash';
      case 'easypaisa': return 'EasyPaisa';
      case 'bank_transfer': return 'Bank Transfer';
      case 'card': return 'Card';
      default: return 'Other';
    }
  }

  List<dynamic> get _filteredPayments {
    if (_filterStatus == 'all') return _payments;
    return _payments.where((p) => p['status'] == _filterStatus).toList();
  }

  Map<String, dynamic> get _summary {
    int paid = 0, pending = 0, overdue = 0;
    double totalPaid = 0;
    for (final p in _payments) {
      switch (p['status']) {
        case 'paid': paid++; totalPaid += (p['amount'] ?? 0).toDouble(); break;
        case 'pending': pending++; break;
        case 'overdue': overdue++; break;
      }
    }
    return {'paid': paid, 'pending': pending, 'overdue': overdue, 'totalPaid': totalPaid};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Payment History',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
        actions: [
          IconButton(onPressed: _loadPayments, icon: const Icon(Icons.refresh, color: Colors.white)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _navy))
          : _error.isNotEmpty ? _buildError() : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Color(0xFF8A94A6)),
          const SizedBox(height: 16),
          Text(_error, style: const TextStyle(color: Color(0xFF8A94A6), fontFamily: 'Poppins')),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadPayments,
            style: ElevatedButton.styleFrom(backgroundColor: _navy, foregroundColor: Colors.white),
            child: const Text('Retry', style: TextStyle(fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final summary = _summary;
    final currency = _payments.isNotEmpty ? (_payments.first['currency'] ?? 'PKR') : 'PKR';
    return RefreshIndicator(
      onRefresh: _loadPayments,
      color: _navy,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildSummaryCard('Paid', summary['paid'].toString(), const Color(0xFF27AE60), Icons.check_circle_outline),
                const SizedBox(width: 10),
                _buildSummaryCard('Pending', summary['pending'].toString(), _yellow, Icons.schedule),
                const SizedBox(width: 10),
                _buildSummaryCard('Overdue', summary['overdue'].toString(), const Color(0xFFE74C3C), Icons.warning_amber_outlined),
              ],
            ),
            const SizedBox(height: 12),
            if ((summary['totalPaid'] as double) > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_navy, Color(0xFF2D4099)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Paid', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Poppins')),
                        Text(_formatCurrency(summary['totalPaid'], currency),
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            const Text('Transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E), fontFamily: 'Poppins')),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['all', 'paid', 'pending', 'overdue'].map((status) {
                  final isSelected = _filterStatus == status;
                  return GestureDetector(
                    onTap: () => setState(() => _filterStatus = status),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? _navy : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? _navy : const Color(0xFFE5E7EB)),
                      ),
                      child: Text(
                        status == 'all' ? 'All' : status[0].toUpperCase() + status.substring(1),
                        style: TextStyle(
                          fontSize: 13, fontFamily: 'Poppins',
                          color: isSelected ? Colors.white : const Color(0xFF8A94A6),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            if (_filteredPayments.isEmpty)
              _buildEmptyState()
            else
              ..._filteredPayments.map((p) => _buildPaymentCard(p, currency)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color, fontFamily: 'Poppins')),
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF8A94A6), fontFamily: 'Poppins')),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(dynamic payment, String currency) {
    final status = payment['status'] ?? 'pending';
    final month = _formatMonth(payment['month']);
    final paidAt = _formatDate(payment['paidAt']);
    final amount = _formatCurrency(payment['amount'], payment['currency'] ?? currency);
    final method = _paymentMethodLabel(payment['paymentMethod']);
    final serviceType = _serviceTypeLabel(payment['serviceType']);
    final receiptNumber = payment['receiptNumber'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _statusBgColor(status),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                  child: Icon(_statusIcon(status), color: _statusColor(status), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Transport Fee — $month',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E), fontFamily: 'Poppins')),
                      const SizedBox(height: 2),
                      Text(serviceType, style: const TextStyle(fontSize: 11, color: Color(0xFF8A94A6), fontFamily: 'Poppins')),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(amount, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _statusColor(status), fontFamily: 'Poppins')),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: _statusColor(status), borderRadius: BorderRadius.circular(8)),
                      child: Text(status[0].toUpperCase() + status.substring(1),
                          style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                if (status == 'paid') ...[
                  _buildDetailRow(Icons.calendar_today_outlined, 'Paid On', paidAt),
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.payment_outlined, 'Payment Method', method),
                  const SizedBox(height: 8),
                ],
                if (receiptNumber.isNotEmpty)
                  _buildDetailRow(Icons.receipt_outlined, 'Receipt No.', receiptNumber),
                if (status == 'pending')
                  _buildInfoBanner('Please pay your transport fee to the van driver or school admin.', _yellow),
                if (status == 'overdue')
                  _buildInfoBanner('This payment is overdue. Please contact the school immediately.', const Color(0xFFE74C3C)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF8A94A6)),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontSize: 12, color: Color(0xFF8A94A6), fontFamily: 'Poppins')),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E), fontFamily: 'Poppins'),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _buildInfoBanner(String message, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(message,
              style: const TextStyle(fontSize: 11, color: Color(0xFF1A1A2E), fontFamily: 'Poppins'))),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: _navy.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.receipt_long_outlined, color: _navy, size: 40),
          ),
          const SizedBox(height: 16),
          const Text('No Payments Found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E), fontFamily: 'Poppins')),
          const SizedBox(height: 8),
          const Text('Your payment history will appear here\nonce fees are generated by your school.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF8A94A6), fontFamily: 'Poppins')),
        ],
      ),
    );
  }
}
