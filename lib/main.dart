import 'package:enotes/views/splash.dart';
import 'package:flutter/material.dart';
import 'package:enotes/theme_handler.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late ThemeData _themeData;

  @override
  void initState() {
    super.initState();
    initializeTheme();
  }

  Future<void> initializeTheme() async {
    _themeData = await ThemeHandler.getThemeData();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ThemeData>(
      future: ThemeHandler.getThemeData(),
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return MaterialApp(
            home: SplashPage(),
            theme: _themeData,
          );
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }
}
