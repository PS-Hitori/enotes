import 'package:enotes/views/splash.dart';
import 'package:flutter/material.dart';
import 'package:enotes/theme_handler.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: ThemeHandler.initializeTheme(), // Initialize the theme
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        // Check the theme initialization status
        if (snapshot.connectionState == ConnectionState.done) {
          return MaterialApp(
            theme: ThemeHandler.getThemeData(), // Get the theme data
            home: SplashPage(), // Splash widget
          );
        } else {
          // Show a loading indicator while initializing the theme
          return const CircularProgressIndicator();
        }
      },
    );
  }
}
