import 'package:flutter/material.dart';
import 'package:meditrack/style/colors.dart';

class MyTextField {

  Widget buildTextField(
    String label,
    TextEditingController controller, {
    IconData? prefixIcon,
    String? Function(String?)? validator,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          fillColor: AppColors.lightGray,
          filled: true,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
