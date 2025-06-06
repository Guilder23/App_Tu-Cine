// ignore_for_file: library_private_types_in_public_api

import 'package:peliculas/src/utils/colors.dart';
import 'package:peliculas/src/utils/dark_mode_extension.dart';
import 'package:flutter/material.dart';

class CircularProgressWidget extends StatelessWidget {
  final String text;

  const CircularProgressWidget({Key? key, required this.text})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = context.isDarkMode;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: isDarkMode ? AppColors.text : AppColors.darkColor,
          ),
          const SizedBox(height: 15),
          Text(
            text,
            style: TextStyle(
              fontFamily: "CB",
              fontSize: 16,
              color: isDarkMode ? AppColors.text : AppColors.darkColor,
            ),
          ),
        ],
      ),
    );
  }
}
