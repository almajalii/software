import 'package:flutter/material.dart';
import 'package:meditrack/style/colors.dart'; // your colors

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
    return TextFormField(
      controller: widget.controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: widget.labelText,
        fillColor: AppColors.lightGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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
      // validator: (value) {
      //   if (value == null || value.isEmpty) return '*';
      //   return null;
      // },
    );
  }
}
