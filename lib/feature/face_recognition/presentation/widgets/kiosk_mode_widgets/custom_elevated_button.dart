import 'package:flutter/material.dart';

class CustomElevatedButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData? icon;
  final double? width;

  const CustomElevatedButton({
    Key? key,
    required this.onPressed,
    required this.label,
    this.backgroundColor = Colors.transparent,
    this.foregroundColor = Colors.purple,
    this.icon,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      child: icon != null
          ? ElevatedButton.icon(
              icon: Icon(icon, color: Colors.green),
              label: Text(label),
              onPressed: onPressed,
              style: _buttonStyle(),
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: _buttonStyle(),
              child: Text(label),
            ),
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      side: BorderSide(color: foregroundColor, width: 2),
      padding: const EdgeInsets.symmetric(vertical: 13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
      textStyle: const TextStyle(
        fontFamily: 'GothicA1',
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      minimumSize: const Size(20, 40),
      elevation: 0, // Flat appearance
    );
  }
}