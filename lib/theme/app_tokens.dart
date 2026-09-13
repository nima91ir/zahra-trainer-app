import 'package:flutter/material.dart';

/// Design tokens for Work Tracker.
/// All colors, radii, and spacing come from here.
/// Never hardcode colors or radii elsewhere.
class AppTokens {
  AppTokens._();

  // ─── Colors ───
  static const Color primary        = Color(0xFF88A36B);
  static const Color primaryDark    = Color(0xFF6B8452);
  static const Color accent         = Color(0xFFD4AF37);
  static const Color surface        = Color(0xFFFAFBF4);
  static const Color surfaceVariant = Color(0xFFF2F4EE);
  static const Color background     = Color(0xFFEFF2EA);
  static const Color onSurface      = Color(0xFF1F2A1E);
  static const Color onSurfaceVar   = Color(0xFF6B7A6B);
  static const Color outline        = Color(0xFFC5D0C0);
  static const Color outlineVariant = Color(0xFFE0E6DD);
  static const Color success        = Color(0xFF4A6B4E);
  static const Color successSoft    = Color(0xFFE3F0E5);
  static const Color warning        = Color(0xFF8B6F3E);
  static const Color warningSoft    = Color(0xFFFFF3DE);
  static const Color error          = Color(0xFF8B4A3E);
  static const Color errorSoft      = Color(0xFFFCE5E0);

  // ─── Radii ───
  static const double rSm = 8.0;
  static const double rMd = 12.0;
  static const double rLg = 18.0;
  static const double rXl = 24.0;

  // ─── Spacing ───
  static const double s4  = 4.0;
  static const double s8  = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;

  // ─── Shadows ───
  static const List<BoxShadow> shadow1 = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
  ];
  static const List<BoxShadow> shadow2 = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 24, offset: Offset(0, 8)),
  ];
}