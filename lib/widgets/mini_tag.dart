import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// Small colored pill for tags and metadata labels.
class MiniTag extends StatelessWidget {
  final String text;
  const MiniTag({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: AppTokens.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTokens.rSm),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Vazir',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTokens.onSurfaceVar,
        ),
      ),
    );
  }
}
