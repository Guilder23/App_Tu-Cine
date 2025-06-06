import 'package:flutter/material.dart';
import 'package:peliculas/src/utils/colors.dart';

class InputDecorations {
  static InputDecoration authInputDecoration({
    required String hintText,
    required String labelText,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          color: AppColors.acentColor.withOpacity(0.5),
        ),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          color: AppColors.acentColor,
          width: 2,
        ),
      ),
      hintText: hintText,
      labelText: labelText,
      labelStyle: TextStyle(
        color: Colors.grey,
      ),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: AppColors.acentColor)
          : null,
      suffixIcon: suffixIcon,
    );
  }
}

// Clase para definir los tipos de SnackBar
enum SnackBarType {
  success,
  error,
  warning,
  info,
}
