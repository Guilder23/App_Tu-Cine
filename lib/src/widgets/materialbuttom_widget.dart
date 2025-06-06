import 'package:peliculas/src/utils/colors.dart';
import 'package:flutter/material.dart';

class MaterialButtomWidget extends StatelessWidget {
  final String title;
  final Color color;
  final VoidCallback onPressed;
  final double? width;
  final String? text;

  const MaterialButtomWidget(
      {Key? key,
      this.title = '',
      this.color = const Color(0xFFFF5722),
      required this.onPressed,
      this.width,
      this.text})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: width ?? double.infinity,
      child: MaterialButton(
        height: 50,
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        ),
        onPressed: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            text ?? title,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 18,
              fontFamily: "CB",
            ),
          ),
        ),
      ),
    );
  }
}
