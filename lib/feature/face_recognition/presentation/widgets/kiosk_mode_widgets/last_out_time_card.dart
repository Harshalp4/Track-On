import 'package:flutter/material.dart';

class LastOutTimeCard extends StatelessWidget {
  final String lastClockOutTime;

  const LastOutTimeCard({
    Key? key,
    required this.lastClockOutTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          const Text(
            'LAST OUT',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          Text(
            lastClockOutTime,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}