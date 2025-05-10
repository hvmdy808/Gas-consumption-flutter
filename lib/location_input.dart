import 'package:flutter/material.dart';

class LocationInput extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final bool enabled;
  final FocusNode? focusNode;
  final Function(String)? onChanged;

  const LocationInput({
    super.key,
    required this.hint,
    required this.controller,
    this.enabled = true,
    this.focusNode,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.location_on_outlined),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[200],
        ),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
