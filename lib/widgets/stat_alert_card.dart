import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// A single alert card shown on the dashboard (e.g. expired clients count).
class StatAlertCard extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color tint;
  final VoidCallback? onTap;

  const StatAlertCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.tint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isZero = value == 0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTokens.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTokens.outlineVariant),
          boxShadow: isZero ? null : AppTokens.shadow1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 19, color: tint),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppTokens.onSurfaceVar.withValues(alpha: 0.4),
                ),
              ],
            ),
            Text(
              value.toString(),
              textAlign: TextAlign.start,
              style: TextStyle(
                fontFamily: 'Vazir',
                fontSize: 28,
                fontWeight: FontWeight.w900,
                height: 1,
                color: isZero ? AppTokens.outline : AppTokens.onSurface,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.start,
              style: TextStyle(
                fontFamily: 'Vazir',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTokens.onSurfaceVar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
