import 'package:enotes/views/splash.dart';
import 'package:flutter/material.dart';
import 'package:enotes/theme_handler.dart';
import 'package:permission_handler/permission_handler.dart';

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
  late Future<PermissionStatus> _permissionStatus;

  @override
  void initState() {
    super.initState();
    initializeTheme();
    _permissionStatus = requestPermissions();
  }

  Future<PermissionStatus> requestPermissions() async {
    final status = await Permission.storage.request();
    return status;
  }

  Future<void> initializeTheme() async {
    _themeData = await ThemeHandler.getThemeData();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PermissionStatus>(
      future: _permissionStatus,
      builder:
          (BuildContext context, AsyncSnapshot<PermissionStatus> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(),
            ),
          );
        } else if (snapshot.data == PermissionStatus.granted) {
          return MaterialApp(
            home: SplashPage(),
            theme: _themeData,
          );
        } else {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Storage Permission Required',
                      style: TextStyle(fontSize: 20, fontFamily: 'Roboto'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        openAppSettings().then((opened) {
                          if (opened) {
                            setState(() {
                              _permissionStatus = requestPermissions();
                            });
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFCC4F4F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      ),
                      child: const Text('Go to Settings'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
