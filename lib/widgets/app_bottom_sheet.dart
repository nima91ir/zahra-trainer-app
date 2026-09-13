import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// Standard modal bottom sheet.
///
/// Rounds top corners, adds a drag handle, and pads content.
/// Max height is 80% of the screen.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required Widget child,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTokens.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppTokens.rXl),
      ),
    ),
    builder: (ctx) {
      final screenHeight = MediaQuery.of(ctx).size.height;
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTokens.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: child,
              ),
            ),
          ],
        ),
      );
    },
  );
}