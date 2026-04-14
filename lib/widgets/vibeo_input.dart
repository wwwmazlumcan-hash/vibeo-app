import 'package:flutter/material.dart';

class VibeoInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText; // 'hint' değil 'hintText'
  final IconData? prefixIcon;
  final bool isPassword;
  final int maxLines; // BU SATIR ŞART

  const VibeoInput({
    super.key,
    required this.controller,
    required this.hintText,
    this.prefixIcon,
    this.isPassword = false,
    this.maxLines = 1, // Varsayılan 1
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      maxLines: maxLines, // Burada kullanılıyor
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: Colors.cyanAccent)
            : null,
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none),
      ),
    );
  }
}
