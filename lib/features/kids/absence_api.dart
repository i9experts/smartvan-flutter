import '../../core/network/api_errors.dart';
import '../../core/network/api_service.dart';

class Absence {
  final String id;
  final String kidId;
  final String date; // YYYY-MM-DD
  final String tripType; // pick | drop | both
  final String? note;

  const Absence(this.id, this.kidId, this.date, this.tripType, this.note);

  factory Absence.fromJson(Map m) => Absence(
        m['absenceId']?.toString() ?? '',
        m['kidId']?.toString() ?? '',
        m['date']?.toString() ?? '',
        m['tripType']?.toString() ?? 'both',
        m['note']?.toString(),
      );
}

class AbsenceApi {
  AbsenceApi._();

  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Future<List<Absence>> list(String kidId) async {
    final res = ApiErrors.ensureOk(await ApiService.get('/kid/absence?kidId=$kidId'));
    final d = res.data is Map ? res.data['data'] : null;
    return d is List ? d.whereType<Map>().map(Absence.fromJson).toList() : [];
  }

  static Future<void> create({
    required String kidId,
    required DateTime date,
    required String tripType,
    String? note,
  }) async {
    ApiErrors.ensureOk(await ApiService.post('/kid/absence', {
      'kidId': kidId,
      'date': dateKey(date),
      'tripType': tripType,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    }));
  }

  static Future<void> cancel(String absenceId) async {
    ApiErrors.ensureOk(await ApiService.post('/kid/absence/$absenceId/cancel', {}));
  }
}
