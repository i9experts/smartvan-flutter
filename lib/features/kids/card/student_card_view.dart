import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'student_card_api.dart';
import 'student_card_style.dart';

/// On-screen student card. Laid out in "card millimetres" and scaled to the
/// available width, so it matches the printed PDF.
class StudentCardView extends StatelessWidget {
  final StudentCardData card;
  const StudentCardView({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final mm = c.maxWidth / StudentCardStyle.widthMm; // px per card-mm
      return SizedBox(
        width: c.maxWidth,
        height: StudentCardStyle.heightMm * mm,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3 * mm),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFD9DEEA), width: 0.25 * mm),
              borderRadius: BorderRadius.circular(3 * mm),
            ),
            child: Column(
              children: [
                _header(mm),
                Expanded(child: _body(mm)),
                _footer(mm),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _header(double mm) {
    return Container(
      height: 12 * mm,
      padding: EdgeInsets.symmetric(horizontal: 3 * mm),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [StudentCardStyle.navy, StudentCardStyle.blue]),
      ),
      child: Row(
        children: [
          Container(
            width: 9 * mm,
            height: 9 * mm,
            padding: EdgeInsets.all(0.4 * mm),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Image.asset(StudentCardStyle.logoAsset, fit: BoxFit.contain),
          ),
          SizedBox(width: 1.8 * mm),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SmartVan',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800, fontSize: 3.6 * mm, fontFamily: 'Poppins', height: 1)),
              SizedBox(height: 0.6 * mm),
              Text(StudentCardStyle.tagline,
                  style: TextStyle(
                      color: StudentCardStyle.yellow, fontSize: 1.9 * mm, fontWeight: FontWeight.w600, fontFamily: 'Poppins', height: 1)),
            ],
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2 * mm, vertical: 0.8 * mm),
            decoration: BoxDecoration(color: StudentCardStyle.yellow, borderRadius: BorderRadius.circular(5 * mm)),
            child: Text('STUDENT CARD',
                style: TextStyle(
                    color: StudentCardStyle.navy, fontSize: 1.9 * mm, fontWeight: FontWeight.w800, fontFamily: 'Poppins', letterSpacing: 0.2 * mm)),
          ),
        ],
      ),
    );
  }

  Widget _body(double mm) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 3 * mm, vertical: 2.2 * mm),
      child: Row(
        children: [
          _photo(mm),
          SizedBox(width: 2.5 * mm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(card.fullname,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: StudentCardStyle.navy, fontWeight: FontWeight.w800, fontSize: 3.4 * mm, fontFamily: 'Poppins', height: 1.15)),
                SizedBox(height: 0.8 * mm),
                if (card.grade.isNotEmpty) _field('Grade', card.grade, mm),
                if (card.vanNumber.isNotEmpty) _field('Van', card.vanNumber, mm),
                if (card.schoolName.isNotEmpty) _field('School', card.schoolName, mm, maxLines: 2),
              ],
            ),
          ),
          SizedBox(width: 2.5 * mm),
          _qr(mm),
        ],
      ),
    );
  }

  Widget _photo(double mm) {
    final placeholder = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.person, size: 10 * mm, color: StudentCardStyle.blue),
        Text('Affix photo\nhere',
            textAlign: TextAlign.center,
            style: TextStyle(color: StudentCardStyle.blue, fontSize: 1.7 * mm, fontWeight: FontWeight.w600, height: 1.1, fontFamily: 'Poppins')),
      ],
    );
    return Container(
      width: 19 * mm,
      height: 24 * mm,
      decoration: BoxDecoration(
        color: card.image == null ? StudentCardStyle.photoBg : Colors.white,
        borderRadius: BorderRadius.circular(2 * mm),
        border: Border.all(
          color: card.image == null ? StudentCardStyle.blue : StudentCardStyle.navy,
          width: (card.image == null ? 0.35 : 0.5) * mm,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: card.image == null
          ? placeholder
          : Image.network(card.image!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder),
    );
  }

  Widget _field(String label, String value, double mm, {int maxLines = 1}) {
    return Padding(
      padding: EdgeInsets.only(top: 0.5 * mm),
      child: Text.rich(
        TextSpan(children: [
          TextSpan(text: '$label: ', style: const TextStyle(color: StudentCardStyle.blue, fontWeight: FontWeight.w700)),
          TextSpan(text: value),
        ]),
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 2.2 * mm, color: const Color(0xFF344054), fontFamily: 'Poppins', height: 1.25),
      ),
    );
  }

  Widget _qr(double mm) {
    Widget corner(Alignment a, Color color) => Align(
          alignment: a,
          child: Container(
            width: 4 * mm,
            height: 4 * mm,
            decoration: BoxDecoration(
              border: Border(
                top: a.y < 0 ? BorderSide(color: color, width: 0.6 * mm) : BorderSide.none,
                bottom: a.y > 0 ? BorderSide(color: color, width: 0.6 * mm) : BorderSide.none,
                left: a.x < 0 ? BorderSide(color: color, width: 0.6 * mm) : BorderSide.none,
                right: a.x > 0 ? BorderSide(color: color, width: 0.6 * mm) : BorderSide.none,
              ),
            ),
          ),
        );
    return SizedBox(
      width: 24 * mm,
      height: 24 * mm,
      child: Stack(
        children: [
          corner(Alignment.topLeft, StudentCardStyle.yellow),
          corner(Alignment.topRight, StudentCardStyle.red),
          corner(Alignment.bottomLeft, StudentCardStyle.red),
          corner(Alignment.bottomRight, StudentCardStyle.yellow),
          Padding(
            padding: EdgeInsets.all(1.2 * mm),
            child: QrImageView(
              data: card.qrPayload,
              padding: EdgeInsets.zero,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: StudentCardStyle.navy),
              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: StudentCardStyle.navy),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer(double mm) {
    return Container(
      height: 5 * mm,
      color: StudentCardStyle.yellow,
      padding: EdgeInsets.symmetric(horizontal: 3 * mm),
      child: Row(
        children: [
          Text(StudentCardStyle.url,
              style: TextStyle(
                  color: StudentCardStyle.navy, fontSize: 2 * mm, fontWeight: FontWeight.w800, fontFamily: 'Poppins', letterSpacing: 0.15 * mm)),
          const Spacer(),
          Text(StudentCardStyle.returnNote,
              style: TextStyle(color: StudentCardStyle.navy, fontSize: 1.6 * mm, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
        ],
      ),
    );
  }
}
