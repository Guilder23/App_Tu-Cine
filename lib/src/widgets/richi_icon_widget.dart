import 'package:peliculas/src/utils/colors.dart';
import 'package:flutter/material.dart';

class RichiIconWidget extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const RichiIconWidget({
    super.key,
    required this.icon,
    required this.text,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.red, size: 16),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: color ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

class RichiIconTextWidget extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDarkMode;
  const RichiIconTextWidget({
    super.key,
    required this.icon,
    required this.isDarkMode,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          WidgetSpan(
            child: Icon(icon, color: AppColors.red),
          ),
          const TextSpan(text: '  '),
          TextSpan(
            text: text,
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? AppColors.lightColor : AppColors.darkColor,
              fontFamily: "CB",
            ),
          ),
        ],
      ),
    );
  }
}
