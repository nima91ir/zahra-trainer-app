import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// Standard button for the app. Full width by default.
enum AppButtonStyle { primary, outlined, ghost, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonStyle style;
  final bool small;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.style = AppButtonStyle.primary,
    this.small = false,
  });

  const AppButton.outlined({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.small = false,
  }) : style = AppButtonStyle.outlined;

  const AppButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.small = false,
  }) : style = AppButtonStyle.ghost;

  const AppButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.small = false,
  }) : style = AppButtonStyle.danger;

  double get _height => small ? 40 : 48;
  double get _fontSize => small ? 12.5 : 14;
  double get _iconSize => small ? 16 : 18;
  double get _radius => small ? AppTokens.rMd : AppTokens.rLg;

  Color get _bg {
    switch (style) {
      case AppButtonStyle.primary:
        return AppTokens.primary;
      case AppButtonStyle.ghost:
        return AppTokens.surfaceVariant;
      case AppButtonStyle.outlined:
      case AppButtonStyle.danger:
        return Colors.transparent;
    }
  }

  Color get _fg {
    switch (style) {
      case AppButtonStyle.primary:
        return Colors.white;
      case AppButtonStyle.outlined:
        return AppTokens.primary;
      case AppButtonStyle.ghost:
        return AppTokens.onSurface;
      case AppButtonStyle.danger:
        return AppTokens.error;
    }
  }

  Color get _border {
    switch (style) {
      case AppButtonStyle.primary:
        return AppTokens.primary;
      case AppButtonStyle.outlined:
        return AppTokens.primary;
      case AppButtonStyle.ghost:
        return AppTokens.outlineVariant;
      case AppButtonStyle.danger:
        return AppTokens.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: _iconSize, color: _fg),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Vazir',
            fontSize: _fontSize,
            fontWeight: FontWeight.w700,
            color: _fg,
          ),
        ),
      ],
    );

    return SizedBox(
      width: double.infinity,
      height: _height,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: _bg,
          foregroundColor: _fg,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
            side: BorderSide(
              color: _border,
              width: style == AppButtonStyle.primary ? 0 : 1.5,
            ),
          ),
        ),
        child: child,
      ),
    );
  }
}