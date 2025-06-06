import 'package:peliculas/src/utils/colors.dart';
import 'package:flutter/material.dart';

class RowPriceDetails extends StatelessWidget {
  final String title;
  final String price;
  final bool isDarkMode;
  final bool isBold;

  const RowPriceDetails({
    super.key,
    required this.title,
    required this.price,
    required this.isDarkMode,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isDarkMode ? AppColors.lightColor : AppColors.darkColor,
          ),
        ),
        Text(
          price,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isDarkMode ? AppColors.lightColor : AppColors.darkColor,
          ),
        ),
      ],
    );
  }
}
