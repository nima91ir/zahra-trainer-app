import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// Small colored pill for status labels.
///
/// Variants:
///   green   → success (active, present)
///   amber   → warning (frozen, expiring)
///   red     → danger  (expired, absent)
///   primary → info    (fresh)
///   neutral → gray    (default)
///   queued  → teal-ish (queued plans)
enum BadgeVariant { green, amber, red, primary, neutral, queued }

class StatusBadge extends StatelessWidget {
  final String text;
  final BadgeVariant variant;

  const StatusBadge({
    super.key,
    required this.text,
    this.variant = BadgeVariant.neutral,
  });

  Color get _bg {
    switch (variant) {
      case BadgeVariant.green:
        return AppTokens.successSoft;
      case BadgeVariant.amber:
        return AppTokens.warningSoft;
      case BadgeVariant.red:
        return AppTokens.errorSoft;
      case BadgeVariant.primary:
        return AppTokens.primary.withValues(alpha: 0.14);
      case BadgeVariant.queued:
        return AppTokens.primary.withValues(alpha: 0.20);
      case BadgeVariant.neutral:
        return AppTokens.surfaceVariant;
    }
  }

  Color get _fg {
    switch (variant) {
      case BadgeVariant.green:
        return AppTokens.success;
      case BadgeVariant.amber:
        return AppTokens.warning;
      case BadgeVariant.red:
        return AppTokens.error;
      case BadgeVariant.primary:
        return AppTokens.primary;
      case BadgeVariant.queued:
        return AppTokens.primaryDark;
      case BadgeVariant.neutral:
        return AppTokens.onSurfaceVar;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(AppTokens.rSm),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Vazir',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _fg,
        ),
      ),
    );
  }
}