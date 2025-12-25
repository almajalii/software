import 'package:flutter/material.dart';
import 'package:meditrack/style/colors.dart';

class ExpiryDatePicker extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String dateFormat; // 'yyyy-mm-dd' or 'dd-mm-yyyy'
  final void Function(DateTime)? onDateChanged;

  const ExpiryDatePicker({
    Key? key,
    required this.controller,
    this.labelText = 'Expiry Date',
    this.dateFormat = 'yyyy-mm-dd',
    this.onDateChanged,
  }) : super(key: key);

  @override
  _ExpiryDatePickerState createState() => _ExpiryDatePickerState();
}

class _ExpiryDatePickerState extends State<ExpiryDatePicker> {
  DateTime? selectedDate;

  String formatDate(DateTime date) {
    switch (widget.dateFormat) {
      case 'dd-mm-yyyy':
        return "${date.day.toString().padLeft(2, '0')}-"
            "${date.month.toString().padLeft(2, '0')}-"
            "${date.year}";
      case 'yyyy-mm-dd':
      default:
        return "${date.year}-${date.month.toString().padLeft(2, '0')}-"
            "${date.day.toString().padLeft(2, '0')}";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: widget.controller,
      readOnly: true,
      style: TextStyle(
        color: isDarkMode ? Colors.white : Colors.black,
      ),
      decoration: InputDecoration(
        labelText: widget.labelText,
        labelStyle: TextStyle(
          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
        ),
        fillColor: isDarkMode ? Color(0xFF2C2C2C) : AppColors.lightGray,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDarkMode ? Color(0xFF3C3C3C) : Color(0xFFC8D1DC),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
      ),
      onTap: () async {
        FocusScope.of(context).requestFocus(FocusNode()); // Hide keyboard
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          setState(() {
            selectedDate = picked;
            widget.controller.text = formatDate(picked);
            if (widget.onDateChanged != null) {
              widget.onDateChanged!(picked);
            }
          });
        }
      },
    );
  }
}