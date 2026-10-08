import 'package:flutter/material.dart';

/// SmartVan brand colours (from the logo) and card constants, shared by
/// the on-screen card and the PDF so both look the same.
class StudentCardStyle {
  StudentCardStyle._();

  static const navy = Color(0xFF26296B);
  static const blue = Color(0xFF2563AE);
  static const yellow = Color(0xFFFCD116);
  static const red = Color(0xFFE3101E);
  static const photoBg = Color(0xFFEEF3FB);

  /// Printed at the bottom of every card.
  static const url = 'app.smartvan.pk';
  static const tagline = 'Safe Ride, Every Side';
  static const returnNote = 'If found, please return to the school';

  /// ID-1 card size in millimetres.
  static const widthMm = 85.6;
  static const heightMm = 54.0;

  static const logoAsset = 'assets/images/logo.png';
}
