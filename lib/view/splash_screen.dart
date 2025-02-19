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

    // For testing, clear all stored preferences so the onboarding screen always appears.
    await prefs.clear();
    print("All preferences cleared for debugging.");

    final lang = prefs.getString('preferred_language');

    if (lang != null && lang.isNotEmpty) {
      // Navigate to HomeScreen with the selected language.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(language: lang)),
      );
    } else {
      // If no language is set, navigate to the OnboardingPage.
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
