import 'package:flutter/material.dart';

class TimeLog extends StatefulWidget {
  const TimeLog({super.key});

  @override
  State<TimeLog> createState() => _TimeLogState();
}

class _TimeLogState extends State<TimeLog> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Time log'),
        centerTitle: true,
      ),
    );
  }
}