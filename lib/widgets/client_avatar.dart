import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// Round avatar showing the first character of a client's name.
class ClientAvatar extends StatelessWidget {
  final String name;
  final double size;

  const ClientAvatar({
    super.key,
    required this.name,
    this.size = 40,
  });

  const ClientAvatar.large({super.key, required this.name}) : size = 80;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name.characters.first : '؟';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTokens.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontFamily: 'Vazir',
          fontSize: size * 0.38,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}