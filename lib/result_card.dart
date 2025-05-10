import 'package:flutter/material.dart';

class ResultCard extends StatelessWidget {
  final String resultText;
  final bool isError;

  const ResultCard({super.key, required this.resultText, this.isError = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isError ? Colors.red.shade300 : Colors.blue.shade100,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isError ? 'Error' : 'Result',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isError ? Colors.red : Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              resultText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isError ? Colors.red.shade700 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
