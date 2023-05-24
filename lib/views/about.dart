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
    const String description = 'A simple note-taking app.';

    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
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
              description,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 8),
                  const Text(
                    'This project is open source on GitHub',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
