import '../../../core/network/api_errors.dart';
import '../../../core/network/api_service.dart';

/// Data for a child's SmartVan student card (GET /kid/:id/card).
class StudentCardData {
  final String kidId;
  final String fullname;
  final String grade;
  final String? image;
  final String vanNumber;
  final String schoolName;
  final String qrPayload;

  const StudentCardData({
    required this.kidId,
    required this.fullname,
    required this.grade,
    required this.image,
    required this.vanNumber,
    required this.schoolName,
    required this.qrPayload,
  });

  factory StudentCardData.fromJson(Map m) {
    final img = m['image']?.toString();
    return StudentCardData(
      kidId: m['kidId']?.toString() ?? '',
      fullname: m['fullname']?.toString() ?? '',
      grade: m['grade']?.toString() ?? '',
      image: img != null && img.isNotEmpty ? img : null,
      vanNumber: m['vanNumber']?.toString() ?? '',
      schoolName: m['schoolName']?.toString() ?? '',
      qrPayload: m['qrPayload']?.toString() ?? '',
    );
  }
}

class StudentCardApi {
  StudentCardApi._();

  static Future<StudentCardData> load(String kidId) async {
    final res = ApiErrors.ensureOk(await ApiService.get('/kid/$kidId/card'));
    final d = res.data is Map ? res.data['data'] : null;
    if (d is! Map) throw const ApiException('Could not load the card.');
    return StudentCardData.fromJson(d);
  }
}
