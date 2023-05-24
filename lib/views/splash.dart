import 'package:enotes/views/home.dart';
import 'package:flutter/material.dart';

class SplashPage extends StatefulWidget {
  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _loadHomePage();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadHomePage() async {
    // Avoid multiple navigation attempts
    if (_isLoading) {
      return;
    }

    // Set the flag to indicate that the navigation is in progress
    setState(() {
      _isLoading = true;
    });

    // Simulate a delay for the splash screen
    await Future.delayed(const Duration(seconds: 5));

    // Start the loading animation
    _animationController.forward();

    // Navigate to the home screen after the animation completes
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Home()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white, // Set your desired background color
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Replace this widget with your app logo
              Image.asset(
                'assets/icons/icon.png',
                width: 150,
                height: 150,
              ),
              const SizedBox(height: 16),
              AnimatedBuilder(
                animation: _opacityAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _opacityAnimation.value,
                    child: const CircularProgressIndicator(
                      color: Color(0xFFCC4F4F),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
