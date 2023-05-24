import 'package:flutter/material.dart';
import 'package:enotes/theme_handler.dart';

class About extends StatelessWidget {
  const About({Key? key}) : super(key: key);

  void initState() {
    ThemeHandler.getThemeData();
  }

  @override
  Widget build(BuildContext context) {
    const String appName = 'eNotes';
    const List<String> groupMembers = [
      'Radam, Aron Jake S.',
      'Ramones, Dwight Patrick G.',
      'San Buenaventura III, Edwin J.',
      'Lofranco. Kevin Christian A.',
      'Constantino, John David B.',
      'Campo, Charlie M.'
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/logo.png',
              width: 128,
              height: 128,
            ),
            const SizedBox(height: 8),
            const Text(
              appName,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Group Members:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (var member in groupMembers)
              Text(
                member,
                style: const TextStyle(fontSize: 16),
              ),
          ],
        ),
      ),
    );
  }
}
