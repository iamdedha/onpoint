import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/view/onboarding.dart';
import 'home.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Future<void> _checkLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    // Check if onboarding has been completed.
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    if (onboardingCompleted) {
      // If onboarding is done, get the language or default to 'en'
      final lang = prefs.getString('preferred_language') ?? 'en';
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(language: lang)),
      );
    } else {
      // On first launch, show the onboarding screen.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingPage()),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _checkLanguagePreference();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
