import '../../core/network/api_errors.dart';
import '../../core/network/api_service.dart';

class PayMethod {
  final String key;
  final String label;
  final bool enabled;
  const PayMethod(this.key, this.label, this.enabled);
}

class Checkout {
  final String id;
  final String method;
  final num amount;
  final String currency;
  final String status; // pending | succeeded | failed | expired
  final String instructions;
  final String? redirectUrl;
  final bool testMode;

  const Checkout({
    required this.id,
    required this.method,
    required this.amount,
    required this.currency,
    required this.status,
    required this.instructions,
    this.redirectUrl,
    this.testMode = false,
  });

  factory Checkout.fromJson(Map m) => Checkout(
        id: m['checkoutId']?.toString() ?? '',
        method: m['method']?.toString() ?? '',
        amount: (m['amount'] as num?) ?? 0,
        currency: m['currency']?.toString() ?? 'PKR',
        status: m['status']?.toString() ?? 'pending',
        instructions: m['instructions']?.toString() ?? '',
        redirectUrl: m['redirectUrl']?.toString(),
        testMode: m['testMode'] == true,
      );
}

class FeesApi {
  FeesApi._();

  static Map _data(dynamic body) => body is Map && body['data'] is Map ? body['data'] as Map : const {};

  /// Enabled online methods; empty when online payment is off.
  static Future<List<PayMethod>> methods() async {
    final res = ApiErrors.ensureOk(await ApiService.get('/fees/payment-methods'));
    final list = res.data is Map ? res.data['methods'] : null;
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((m) => PayMethod(m['key'].toString(), m['label'].toString(), m['enabled'] == true))
        .where((m) => m.enabled)
        .toList();
  }

  static Future<Checkout> start(String paymentId, String method) async {
    final res = ApiErrors.ensureOk(
        await ApiService.post('/fees/pay-online', {'paymentId': paymentId, 'method': method}));
    return Checkout.fromJson(_data(res.data));
  }

  static Future<Checkout> status(String checkoutId) async {
    final res = ApiErrors.ensureOk(await ApiService.get('/fees/pay-online/$checkoutId'));
    return Checkout.fromJson(_data(res.data));
  }

  static Future<Checkout> mockConfirm(String checkoutId, {bool success = true}) async {
    final res = ApiErrors.ensureOk(
        await ApiService.post('/fees/pay-online/$checkoutId/mock-confirm', {'success': success}));
    return Checkout.fromJson(_data(res.data));
  }

  static Future<Map<String, dynamic>> receipt(String paymentId) async {
    final res = ApiErrors.ensureOk(await ApiService.get('/fees/receipt/$paymentId'));
    return Map<String, dynamic>.from(_data(res.data));
  }
}
