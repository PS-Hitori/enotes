import 'package:flutter/material.dart';
import 'package:enotes/theme_handler.dart';
import 'package:enotes/views/home.dart';

class SplashPage extends StatefulWidget {
  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHomePage();
  }

  Future<void> _loadHomePage() async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 5));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Home()),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = ThemeHandler.getBackgroundColor(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                'assets/icons/logo.png',
                width: 150,
                height: 150,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
